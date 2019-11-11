import risc8_pkg::*;
import alu_pkg::*;


module datapath8(
		input logic clk, rst, interrupt,
		risc8_cdi.datapath cdi,
		input  word com_rd,
		input  wire [23:0] imm,
		output word com_wr, com_addr,
		input  [15:0] mem_rd,
		output [15:0] mem_wr,
		output reg [15:0] pc,
		output reg [23:0] mem_addr
);
	
	word r1, r2, reg_wr;

	reg_file reg0(.clk(clk), .rst(rst), 
			.rd_addr1(cdi.a1),
			.rd_addr2(cdi.a2),
			.rd_data1(r1),
			.rd_data2(r2),
			.wr_addr(cdi.a3),
			.wr_data(reg_wr),
			.wr_en(cdi.rw_en)
	);

	word srcA, srcB, alu_rlo, alu_rhi, alu_rhit;
	logic cout, cin, alu_eq, alu_gt, alu_zero, alu_sign;
	assign cdi.alu_comp = {alu_eq, alu_gt, alu_zero};
	assign alu_sign = 0;
	always_ff@(posedge clk) begin
			if(rst) begin
					cin <= '0;
					alu_rhi <= '0;
			end else begin

			if((cdi.alu_op == ALU_ADD)||(cdi.alu_op == ALU_SUB))
					cin <= cout;
			if((cdi.alu_op == ALU_MUL)||(cdi.alu_op == ALU_DIV))
					alu_rhi <= alu_rhit;
			end
	end

	alu#(.WORD(8)) alu0(
		.a(srcA),
		.b(srcB),
		.op(cdi.alu_op),
		.r(alu_rlo),
		.r_high(alu_rhit),
		.zero(alu_zero),
		.eq(alu_eq),
		.gt(alu_gt),
		.cin(cin), .cout(cout),
		.sign(alu_sign)
		// TODO: missing overflow
	);

	// ======================== //
	// 		Program Counter 	//
	// ======================== //

	logic bconst; // Use immediate to branch
	word pc_off; // Program counter offset
	reg [15:0] pcn, pca; // Program Counter Previous, to add
	always_ff@(posedge clk) begin
			if(rst) pc <= '0; 
			else pc <= pcn;
	end
	
	always_comb begin
		bconst = 0;  // FIXME: temporary
		case(cdi.pcop)
			PC_NONE: pca = pc;
			PC_MEM : pca = mem_rd;
			PC_IMM : pca = {imm[7:0], imm[15:8]};
			PC_IMM2: pca = {imm[15:8], imm[23:16]};
			default: pca = pc;
		endcase
		//pca = (bconst) ? {imm[7:0], imm[15:8]} : pc;
		pc_off = { 
			5'b0000_0, 
			cdi.isize[0]&cdi.isize[1], 
			cdi.isize[0]^cdi.isize[1], 
			(~cdi.isize[1]&~cdi.isize[0])|(cdi.isize[1]&~cdi.isize[0])
		}; // Adding 1 to 2bit value.
		pcn = pca + pc_off;
	end
	
	word interrupt_flag;
	always_ff@(posedge clk) begin
		if(rst) interrupt_flag <= 0;
		else if(interrupt) interrupt_flag <= com_rd;
	end
	
	
	// ======================== //
	// 			Stack 			//
	// ======================== //

	logic [15:0] sp, sp_add, sp_next, st_wr;  // Stack pointer 
	word st_reg, st_rd;  // Stack data low byte reg
	logic [23:0] sp_addr;
	always_comb begin
		sp_add = (cdi.stackop == ST_ADD) ? 'h0002 : 'hfffe;
		sp_next = sp + sp_add;
		sp_addr = {9'b1111_1111_1, (cdi.stackop == ST_ADD) ? sp_next[15:1] : sp[15:1]};
		st_rd = {mem_rd[7:0]};
		st_wr = (cdi.pcop == PC_IMM) ? pc : {8'h00, r1};
		//if(sp[0]) begin
			//st_wr = {'h00, r1};
			//st_rd = {mem_rd[7:0]};
		//end else begin
			//st_wr = {st_reg, r1};
			//st_rd = {mem_rd[15:8]};
		//end
	end
	
	always_ff@(posedge clk) begin
			if(rst)	sp <= 'hffff;
			else begin
				if(cdi.stackop != ST_SKIP) sp <= sp_next;
				if(sp[0]) st_reg <= r1; 
			end
	end

	// ======================== //
	// 			Memory 			//
	// ======================== //

	word mem_wr_hi; // High byte of memory store
	always_ff@(posedge clk) begin
			if(rst) mem_wr_hi <= '0; 
			else if(cdi.selo == SO_MEMH) mem_wr_hi <= r1;
	end
	
	assign mem_wr = (cdi.stackop == ST_SUB) ? st_wr : {mem_wr_hi, r1};
	assign mem_addr = (cdi.stackop != ST_SKIP) ? sp_addr : {imm[7:0], imm[15:8], imm[23:16]};

	// COM Write
	assign com_wr = (cdi.selo == SO_COM) ? r1 : '0;
	assign com_addr = imm[7:0];

	assign srcA = r1;
	always_comb begin
		case(cdi.selb)
			SB_REG : srcB = r2;
			SB_0   : srcB = 8'h00;
			SB_1   : srcB = 8'h01;
			SB_IMM : srcB = imm[7:0];
			default: srcB = r2;
		endcase

		case(cdi.selr)
			SR_REG : reg_wr = r2;
			SR_MEML: reg_wr = (cdi.stackop == ST_ADD) ? st_rd : mem_rd[7:0];
			SR_MEMH: reg_wr = mem_rd[15:8];
			SR_ALUL: reg_wr = alu_rlo;
			SR_ALUH: reg_wr = alu_rhi;
			SR_IMM : reg_wr = imm[7:0];
			SR_COM : reg_wr = com_rd;
			SR_INTR: reg_wr = interrupt_flag;
			default: reg_wr = alu_rlo;
		endcase
	end

endmodule

//module datapath(clk, rst, rd, rs, imm, alu_op, alu_ex, reg_wr, pc_src, 
//		rimm, alu_src, mem_to_reg, pc, alu_out, mem_data, alu_zero, 
//		mem_wr_data, sp_wr, mem_sp);
//
//
//	input logic clk, rst, reg_wr, pc_src, rimm, mem_to_reg, alu_src;
//	input e_reg rd, rs;
//	input e_alu_op alu_op;
//	input e_alu_ext_op alu_ex;
//	input word imm, mem_data;
//	input logic sp_wr, mem_sp;
//	output word pc, alu_out, mem_wr_data;
//	output logic alu_zero;
//	
//	word sp, sp_next;
//	// Reg File
//	word reg_rd_d1, reg_rd_d2, reg_wr_d;
//	e_reg reg_rd_a1, reg_rd_a2, reg_wr_a;
//	assign reg_rd_a1 = rd;
//	assign reg_rd_a2 = rs;
//	assign reg_wr_a = rd;
//	assign reg_wr_d = (mem_to_reg) ? mem_data : alu_out;
//	reg_file RFILE(clk, rst, reg_rd_a1, reg_rd_a2, reg_rd_d1, reg_rd_d2, reg_wr_a, reg_wr_d, reg_wr);
//
//	// Mem output data
//	assign mem_wr_data = reg_rd_d1;
//
//	// ALU
//	word alu_srcA, alu_srcB;
//	word alu_result;
//	assign alu_srcA = reg_rd_d1;
//	assign alu_srcB = alu_src ? imm : reg_rd_d2;
//	word sp_sel;
//	assign sp_sel = (mem_sp) ? sp_next : sp;
//	assign alu_out = (sp_wr) ? sp_sel : alu_result;
//	alu#(.WORD(8)) alu0(
//		.a(alu_srcA),
//		.b(alu_srcB),
//		.op(alu_op),
//		.r(alu_result),
//		.zero(alu_zero)
//	);
//	
//	// Program counter
//	word pcn; 	// PC next
//	word pcj;   // PC jump, +2 if imm used otherwise +1
//	logic [0:1]pcadd;
//	assign pcadd = (rimm) ? 2 : 1;
//	assign pcj =  pc + pcadd;
//	//assign pcj = pc + 1;
//	assign pcn = (pc_src) ? imm : pcj;
//	always_ff@(posedge clk) begin
//	  	if (rst) pc <= 0;
//		else pc <= pcn;
//	end
//	
//	always_ff@(posedge clk) begin
//		if (rst) sp <= 8'hff;
//		if (sp_wr) sp <= sp_next;
//	end
//	// Optimise this
//	assign sp_next = (mem_sp) ? sp + 1 : sp - 1;
//endmodule
//
//module datapath_tb;
//	logic clk, rst, reg_wr, pc_src, rimm, mem_to_reg, alu_zero;
//	e_reg rs, rt;
//	e_alu_op alu_op;
//	word imm, mem_data, pc, alu_out;
//	datapath DPATH(clk, rst, rs, rt, imm, alu_op, reg_wr, pc_src, rimm, mem_to_reg, pc, alu_out, mem_data, alu_zero);
//
//	initial begin
//		clk = 0;
//		forever #5ns clk = ~clk;
//	end
//
//	initial begin
//		rst = 1;
//		reg_wr = 0;
//		pc_src = 0;
//		rimm = 0;
//		mem_to_reg = 0;
//		rs = ra;
//		rt = ra;
//		//alu_op = ALU_CPY;
//		imm = 8'h00;
//		mem_data = 8'h00;
//		#10ns;
//		rst = 0;
//		reg_wr = 1;
//		mem_to_reg = 1;
//		mem_data = 8'h7A;
//		#10ns;
//		rs = rb;
//		mem_data = 8'h8A;
//		#10ns;
//		rs = rc;
//		mem_data = 8'h9A;
//		#10ns;
//		rs = re;
//		mem_data = 8'hFD;
//		#10ns;
//		rs = ra;
//		#10ns;
//		$stop;
//	end
//
//
//endmodule

import risc8_pkg::*;
import alu_pkg::*;


module datapath8(
		input logic clk, rst, interrupt,
		risc8_cdi.datapath cdi,
		input  word imm, com_rd,
		output word com_wr, com_addr,
		input  [15:0] mem_rd,
		output [15:0] mem_wr
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

	word srcA, srcB, alu_rlo, alu_rhi;
	logic cout, cin, alu_eq, alu_gt, alu_zero;
	assign cdi.alu_comp = {alu_eq, alu_gt, alu_zero};

	alu#(.WORD(8)) alu0(
		.a(alu_srcA),
		.b(alu_srcB),
		.op(e_alu_op'(alu_op)),
		.r(alu_rlo),
		.r_high(alu_rhi),
		.zero(alu_zero),
		.eq(alu_eq),
		.gt(alu_gt),
		.cin(cin), .cout(cout),
		.sign(cdi.sign)
		// TODO: missing overflow
	);
	
	word interrupt_flag;
	always_ff@(posedge clk) begin
		if(rst) interrupt_flag <= 0;
		else if(interrupt) interrupt_flag <= com_rd;
	end
	
	assign srcA = r1;
	always_comb begin
		case(cdi.selb)
			SB_REG : srcB = r2;
			SB_0   : srcB = 8'h00;
			SB_1   : srcB = 8'h01;
			SB_IMM : srcB = imm;
			default: srcB = r2;
		endcase

		case(cdi.selr)
			SR_MEML: reg_wr = mem_rd[7:0];
			SR_MEMH: reg_wr = mem_rd[15:8];
			SR_ALUL: reg_wr = alu_rlo;
			SR_ALUH: reg_wr = alu_rhi;
			SR_IMM : reg_wr = imm;
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

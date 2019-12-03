import risc8_pkg::*;
import alu_pkg::*;


module datapath8(
		input logic clk, rst, interrupt,
		risc8_cdi.datapath cdi,
		input  word com_rd,
		input  wire [23:0] immr,
		output word com_wr, com_addr,
		input  [15:0] mem_rd,
		output [15:0] mem_wr,
		output reg [15:0] pc,
		output reg [23:0] mem_addr
);	
	// regiser file outputs
	word r1, r2;
	
	// immidate overrride
	word imo0, imo1, imo2;
	reg imo0_en, imo1_en, imo2_en, imo_en;
	
	reg [23:0] imm;
	always_comb begin
		imm[7:0] = (imo_en & imo2_en) ? imo2 : immr[7:0];
		imm[15:8] = (imo_en & imo1_en) ? imo1 : immr[15:8];
		imm[23:16] = (imo_en & imo0_en) ? imo0 : immr[23:16];
	end

	always_ff@(posedge clk) begin
		if(imo_en | rst) begin
			imo0_en <= 0;
			imo1_en <= 0;
			imo2_en <= 0;
			imo_en <= 0;
		end else case(cdi.imoctl)
			IMO_0: begin
				imo0 <= r1;
				imo0_en <= 1;
				imo_en <= 1;
			end
			IMO_1: begin
				imo1 <= r1;
				imo1_en <= 1;
			end
			IMO_2: begin
				imo2 <= r1;
				imo2_en <= 1;
			end
		endcase
	end

	// ======================== //
	// 			ALU			 	//
	// ======================== //

	word srcA, srcB, alu_rlo, alu_rhi, alu_rhit;
	logic cout, cinr, cin, alu_eq, alu_gt, alu_zero, alu_sign;
	assign cdi.alu_comp = {alu_eq, alu_gt, alu_zero};
	assign alu_sign = 0;
	assign cin = (cdi.aluf[0]) ? cinr : 0;  // Enable carry in
	always_ff@(posedge clk) begin
			if(rst) begin
					cinr <= '0;
					alu_rhi <= '0;
			end else begin

			if((cdi.alu_op == ALU_ADD)||(cdi.alu_op == ALU_SUB))
					cinr <= cout;
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

	logic bconst, pc_halted, pchf; // Use immediate to branch
	word pc_off; // Program counter offset
	reg [15:0] pcn, pca, pcx, pch, pcp, pcn0; // Program Counter Previous, to add
	assign pchf = (cdi.pcop == PC_MEM) & ~pc_halted;
	always_ff@(posedge clk) begin
			if(rst) begin 
				pcx <= 0;
				pc_halted <= 0;
			end else begin
				pcx <= pcn;
				pch <= pcn;
				if (pchf) pc_halted <= 1;
				else pc_halted <= 0;
			end
	end
	assign pcp = (pchf) ? pch : pcn;
	assign pc = (rst) ? 0 : pcp;
	
	always_comb begin
		bconst = 0;  // FIXME: temporary
		pc_off = { 
			5'b0000_0, 
			cdi.isize[0]&cdi.isize[1], 
			cdi.isize[0]^cdi.isize[1], 
			(~cdi.isize[1]&~cdi.isize[0])|(cdi.isize[1]&~cdi.isize[0])
		}; // Adding 1 to 2bit value.
		case(cdi.pcop)
			PC_NONE: pcn0 = pcx;
			PC_MEM : pcn0 = mem_rd;
			PC_IMM : pcn0 = {imm[7:0], imm[15:8]};
			PC_IMM2: pcn0 = {imm[15:8], imm[23:16]};
			default: pcn0 = pcx;
		endcase
		pcn = (cdi.pcop == PC_IMM | cdi.pcop == PC_IMM2) ? pcn0 : pcn0 + pc_off;
		//pca = (bconst) ? {imm[7:0], imm[15:8]} : pc;
		//pcn = pca + pc_off;
	end
	
	// ======================== //
	// 		  Interrupt	 		//
	// ======================== //

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
		sp_add = (cdi.stackop == ST_ADD) ? 'h0001 : 'hffff;
		sp_next = sp + sp_add;
		sp_addr = {9'b1111_1111_1, (cdi.stackop == ST_ADD) ? sp_next[15:0] : sp[15:0]};
		st_rd = {mem_rd[7:0]};
		st_wr = (cdi.pcop == PC_IMM) ? pcx : {8'h00, r1};
		//if(sp[0]) begin
			//st_wr = {'h00, r1};
			//st_rd = {mem_rd[7:0]};
		//end else begin
			//st_wr = {st_reg, r1};
			//st_rd = {mem_rd[15:8]};
		//end
	end
	
	always_ff@(posedge clk) begin
			if(rst)	sp <= 'h0fff;  // Highest memory address
			else begin
				if(cdi.stackop != ST_SKIP & ~pc_halted) sp <= sp_next;
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
	assign com_addr = (cdi.selo == SO_COM) ? imm[7:0] : '0;
	//assign com_addr = 8'h06;
	//assign com_wr = pc[7:0];

	assign srcA = r1;
	always_comb begin
		case(cdi.selb)
			SB_REG : srcB = r2;
			SB_0   : srcB = 8'h00;
			SB_1   : srcB = 8'h01;
			SB_IMM : srcB = imm[7:0];
			default: srcB = r2;
		endcase

	end

	// ======================== //
	// 		Register File 	 	//
	// ======================== //
	
	word reg_wr, reg_wr1, reg_wr2, reg_wra;
	reg reg_wr_en1; 
	reg [1:0]reg_wr_mem;
	
	always_ff@(posedge clk) begin
		if(rst) begin
			reg_wr1 	<= 0;
			reg_wr_en1 	<= 0;
			reg_wr_mem 	<= 0;
		end else begin
			reg_wr1 	<= reg_wr;
			reg_wr_en1 	<= cdi.rw_en;
			reg_wra 	<= cdi.a3;
			reg_wr_mem 	<= {cdi.selr == SR_MEML, cdi.selr == SR_MEMH};
		end
	end	

	always_comb begin
		case(cdi.selr)
			SR_REG : reg_wr = r2;
			//SR_MEML: reg_wr = (cdi.stackop == ST_ADD) ? st_rd : mem_rd[7:0];
			//SR_MEMH: reg_wr = mem_rd[15:8];
			SR_ALUL: reg_wr = alu_rlo;
			SR_ALUH: reg_wr = alu_rhi;
			SR_IMM : reg_wr = imm[7:0];
			SR_COM : reg_wr = com_rd;
			SR_INTR: reg_wr = interrupt_flag;
			default: reg_wr = alu_rlo;
		endcase
	end
	
	always_comb begin
		case(reg_wr_mem)
			2'b10: 		reg_wr2 = mem_rd[7:0];
			2'b01: 		reg_wr2 = mem_rd[15:8];
			default: 	reg_wr2 = reg_wr1;
		endcase
	end

	reg_file reg0(.clk(clk), .rst(rst), 
			.rd_addr1(cdi.a1),
			.rd_addr2(cdi.a2),
			.rd_data1(r1),
			.rd_data2(r2),
			.wr_addr(reg_wra),
			.wr_data(reg_wr2),
			.wr_en(reg_wr_en1)
	);

endmodule


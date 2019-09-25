import project_pkg::*;

module cpu(clk, rst, in_data, out_data);
	input logic clk, rst;
	input logic  [7:0]in_data;
	output logic [7:0]out_data;
	
	// ==================
	// Program counter
	// ==================
	word  pc;			// Program counter
	word  pcn; 			// Next PC

	always_ff@(posedge clk, negedge rst) begin
		if (!rst) pc <= '0;
		else pc <= pcn;
	end
	
	// ==================
	// Instruction memory
	// ==================
	word	instr, imm;
	e_instr instr_op;
	regAddr rs, rt;
	
	instr_mem #(8) IMEM(clk, pc, instr, imm);
	// Instruction decoding
	assign instr_op 	= instr[7:4];
	assign rs 			= instr[3:2];
	assign rt 			= instr[1:0];
	
	// =====================
	// ALU
	// =====================
	e_alu_op	alu_op;
	word		alu_result;
	word		alu_srcA;
	word		alu_srcB;
	logic		alu_zero;
	alu ALU(alu_op, alu_srcA, alu_srcB, alu_result, alu_zero);
	
	// =====================
	// Register File
	// =====================
	logic		reg_wr_en;
	regAddr	reg_wr_addr;
	word		reg_wr_data;
	regAddr	reg_rd_addr_1;
	regAddr	reg_rd_addr_2;
	word		reg_rd_data_1;
	word		reg_rd_data_2;
	reg_file #(8,2) RFILE(clk, reg_rd_addr_1, reg_rd_addr_2, reg_rd_data_1, reg_rd_data_2, reg_wr_addr, reg_wr_data, reg_wr_en);
	
	// =====================
	// System memory
	// =====================
	logic 	mem_wr_en;
	word		mem_rd_data;
	memory RAM(clk, alu_result, mem_rd_data, reg_rd_data_2, mem_wr_en);
	
	// =====================
	// Control unit
	// =====================
	logic reg_dst;
	logic alu_src;
	logic mem_to_reg;
	
	assign alu_srcA 	 = reg_rd_data_1;
	assign alu_src     = (instr_op == ADDI);
	assign alu_srcB    = (alu_src)    ? reg_rd_data_2 : imm;
	assign reg_wr_data = (mem_to_reg) ? mem_rd_data   : alu_result;
	
	assign reg_wr_addr   = rs;
	assign reg_rd_addr_1 = rs;
	assign reg_rd_addr_2 = rt;
	
	always_comb begin
	case(instr)
		ADD:  	alu_op = ALU_ADD;
		ADDI: 	alu_op = ALU_ADD;
		SUB:  	alu_op = ALU_SUB;
		AND:  	alu_op = ALU_AND;
		OR:   	alu_op = ALU_OR;
		NOT:  	alu_op = ALU_NOT;
		JEQ:  	alu_op = ALU_SUB;
		default: alu_op = ALU_NOP;
	endcase
	end
	
	assign mem_wr_en = instr == SW;
	assign mem_to_reg = instr == LW;
	assign pcn = (alu_zero && instr == JEQ) ? imm : pc + 1;
	
endmodule

module cpu_tb;

endmodule

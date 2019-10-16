import project_pkg::*;

module controller(instr, zero, alu_op, mem_wr, reg_wr, pc_src, rimm, alu_src, mem_to_reg, instr_op, rd, rs);
	input word instr;
	input logic zero; // That's from ALU for J instructions
	output e_alu_op alu_op;
	output logic mem_wr, reg_wr, rimm, mem_to_reg, pc_src, alu_src;
	output e_instr instr_op;
	output e_reg rs, rd;
	// Instruction decoding
	assign instr_op 	= e_instr'(instr[7:4]);
	assign rd 			= e_reg'(instr[3:2]);
	assign rs 			= e_reg'(instr[1:0]);
	
	e_alu_op alu_subsel;
	assign alu_subsel = (instr_op == JEQ) ? ALU_SUB : ALU_CPY;
	assign alu_op = instr_op[3] ? alu_subsel : e_alu_op'(instr_op[2:0]);
	assign reg_wr = ~instr_op[3] | instr_op == LW; 
	
	assign mem_wr = instr_op == SW;
	assign mem_to_reg = instr_op == LW;
	assign pc_src = (zero && instr_op == JEQ) | instr_op == JMP;
	
	assign alu_src = (instr_op == CPY & rd == rs);	
	assign rimm = (alu_src) | instr_op == JEQ;	

endmodule

module controller_tb;
	word instr;
	logic zero, mem_wr, reg_wr, alu_src, mem_to_reg, pc_src;
	e_alu_op alu_op;

	controller CTR(instr, zero, alu_op, mem_wr, reg_wr, pc_src, alu_src, mem_to_reg);

	initial begin
		instr = 8'h00;
		zero = 1;
		#5ns;
		//assert(alu_op == ALU_NOP);
		assert(mem_wr == 0);
		assert(reg_wr == 0);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'h10;
		#5ns;
		assert(alu_op == ALU_ADD);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'h20;
		#5ns;
		assert(alu_op == ALU_ADD);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 1);
		assert(mem_to_reg == 0);
		instr = 8'h30;
		#5ns;
		assert(alu_op == ALU_SUB);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'h40;
		#5ns;
		assert(alu_op == ALU_AND);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'h50;
		#5ns;
		assert(alu_op == ALU_OR);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'h60;
		#5ns;
		//assert(alu_op == ALU_NOT);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'h70;
		#5ns;
		//assert(alu_op == ALU_NOP);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 1);
		instr = 8'h80;
		#5ns;
		//assert(alu_op == ALU_NOP);
		assert(mem_wr == 1);
		assert(reg_wr == 0);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'hB0;
		#5ns;
		//assert(alu_op == ALU_NOP);
		assert(mem_wr == 0);
		assert(reg_wr == 1);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		instr = 8'hC0;
		#5ns;
		assert(alu_op == ALU_SUB);
		assert(mem_wr == 0);
		assert(reg_wr == 0);
		assert(pc_src == 1);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);
		zero = 0;
		#5ns;
		assert(alu_op == ALU_SUB);
		assert(mem_wr == 0);
		assert(reg_wr == 0);
		assert(pc_src == 0);
		assert(alu_src == 0);
		assert(mem_to_reg == 0);

		$stop;
	end
endmodule


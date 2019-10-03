import project_pkg::*;

module cpu(clk, rst, instr, imm, pc, mem_addr, mem_wr_en, mem_wr_data, mem_rd_data);
	input logic clk, rst;
	input word instr, imm, mem_rd_data;
	output logic mem_wr_en;
	output word pc, mem_addr, mem_wr_data;

	// Controller
	logic alu_zero, pc_src, reg_wr, alu_src, mem_to_reg;
	e_instr instr_op;
	e_reg rs, rt;
	e_alu_op alu_op;
	
	controller CTRL(instr, alu_zero, alu_op, mem_wr_en, reg_wr, pc_src, alu_src, mem_to_reg, instr_op, rs, rt);

	// Datapath
	datapath DPATH(clk, rst, rs, rt, imm, alu_op, reg_wr, pc_src, alu_src, mem_to_reg, pc, mem_addr, mem_rd_data, alu_zero, mem_wr_data);	
endmodule

module cpu_tb;
	logic clk, rst, mem_wr; 
	word pc, instr, imm, mem_addr, mem_data, mem_rd_data;	
	cpu CPU(clk, rst, instr, imm, pc, mem_addr, mem_wr, mem_data, mem_rd_data);
	// Instruction memory
	instr_mem #("/home/min/devel/fpga/ucl_project_y3/memory/rom_test.mem") IMEM(pc, instr, imm);
	// System memory
	memory RAM(clk, mem_addr, mem_data, mem_rd_data, mem_wr);	
	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end

	initial begin
		rst = 1;
		#10ns;
		rst = 0;
		#100ns;
		$stop;
	end
endmodule

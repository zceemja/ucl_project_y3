`timescale 1ns / 1ps
import project_pkg::*;

module cpu(clk, rst, instr, imm, pc, mem_addr, mem_wr_en, mem_wr_data, mem_rd_data);
	input logic clk, rst;
	input word instr, imm, mem_rd_data;
	output logic mem_wr_en;
	output word pc, mem_addr, mem_wr_data;

	// Controller
	logic alu_zero, pc_src, reg_wr, rimm, alu_src, mem_to_reg, sp_wr, mem_sp;
	e_instr instr_op;
	e_reg rd, rs;
	e_alu_op alu_op;
	e_alu_ext_op alu_ex;

	controller CTRL(instr, alu_zero, alu_op, alu_ex, mem_wr_en, reg_wr, pc_src, rimm, alu_src, mem_to_reg, instr_op, rd, rs, sp_wr, mem_sp);

	// Datapath
	datapath DPATH(clk, rst, rd, rs, imm, alu_op, alu_ex, reg_wr, pc_src, rimm, alu_src, mem_to_reg, pc, mem_addr, mem_rd_data, alu_zero, mem_wr_data, sp_wr, mem_sp);	
endmodule

module cpu_tb;
	logic clk, rst, mem_wr; 
	word pc, instr, imm, mem_addr, mem_data, mem_rd_data;	
	cpu CPU(clk, rst, instr, imm, pc, mem_addr, mem_wr, mem_data, mem_rd_data);
	// Instruction memory
	instr_mem #("/home/min/devel/fpga/ucl_project_y3/memory/test.mem") IMEM(pc, instr, imm);
	// System memory
	memory RAM(clk, mem_wr, mem_addr, mem_data, mem_rd_data);
	word outvalue;
	always_ff@(posedge clk) begin
			if(mem_wr & mem_addr == 8'hFF) outvalue <= mem_data;
			else outvalue <= 0; 
	end

	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end

	initial begin
		rst = 1;
		#10ns;
		rst = 0;
	end
endmodule

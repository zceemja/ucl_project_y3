`include "risc.sv"
`include "controller.sv"
`include "datapath.sv"

import risc8_pkg::*;
import alu_pkg::*;

//module risc8_cpu(clk, rst, instr, imm, pc, mem_addr, mem_wr_en, mem_wr_data, mem_rd_data);
//	input logic clk, rst;
//	input word instr, imm, mem_rd_data;
//	output logic mem_wr_en;
//	output word pc, mem_addr, mem_wr_data;
//	
//
//
//	//controller CTRL(instr, alu_zero, alu_op, alu_ex, mem_wr_en, reg_wr, pc_src, rimm, alu_src, mem_to_reg, instr_op, rd, rs, sp_wr, mem_sp);
//
//	// Datapath
//	//datapath DPATH(clk, rst, rd, rs, imm, alu_op, alu_ex, reg_wr, pc_src, rimm, alu_src, mem_to_reg, pc, mem_addr, mem_rd_data, alu_zero, mem_wr_data, sp_wr, mem_sp);	
//endmodule

module risc8_cpu(processor_port port);
	reg [31:0] instr; // Fetching 4x8bit instruction
	reg [15:0] pc; // Instruction memory is 16bit in length
	
	rom#("../../memory/build/risc8.text") rom_block0(pc[11:0],  port.clk, instr);	

	risc8_cdi cdi0();
	controller8 ctrl0(
			.instr(instr[7:0]),
			.cdi(cdi0),
			.mem_wr(port.ram_wr_en),
			.mem_rd(port.ram_rd_en)
	);
	datapath8 dpath0(
			.clk(port.clk),
			.rst(port.rst),
			.cdi(cdi0),
			.immr(instr[31:8]),
			.mem_rd(port.ram_rd_data),
			.mem_wr(port.ram_wr_data),
			.mem_addr(port.ram_addr),
			.com_addr(port.com_addr),
			.com_rd(port.com_rd),
			.com_wr(port.com_wr),
			.pc(pc),
			.interrupt(port.com_interrupt)
	);

endmodule

`timescale 1ns / 1ns
module risc8_cpu_tb;

	logic clk, rst;
	logic [23:0] ram_addr;
	logic [15:0] ram_wr;
	logic [15:0] ram_rd;
	logic ram_wr_en;
	logic ram_rd_en;

	word com_addr, com_wr, com_rd;

	processor_port port0(
		.clk(clk),
		.rst(rst),
		.ram_addr(ram_addr),
		.ram_wr_data(ram_wr),
		.ram_rd_data(ram_rd),
		.ram_wr_en(ram_wr_en),
		.ram_rd_en(ram_rd_en),
		.com_addr(com_addr),
		.com_wr(com_wr),
		.com_rd(com_rd)
	);

	always_comb begin
		if(com_addr != 'h00) begin
			com_rd = com_addr^com_wr;
		end else com_rd = 'h00;
	end
	
	risc8_cpu #(.PROGRAM("../../memory/risc8_test.mem")) cpu0(port0);
	
	memory #(
			.WIDTH(16),
			.LENGTH(2**24)
	) ram0 (
			clk,
			ram_wr_en,
			ram_rd_en,
			ram_addr,
			ram_wr,
			ram_rd
	);

	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end

	initial begin
		rst = 1;
		#10ns;
		rst = 0;
		if (cpu0.instr === 'x) $stop;
	end
endmodule

module cpu_tb;
	risc8_cpu_tb cpu_tb0();
endmodule


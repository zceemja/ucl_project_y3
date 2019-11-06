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
	//logic clk, rst, mem_wr; 
	//word pc, instr, imm, mem_addr, mem_data, mem_rd_data;
	
	//assign port.ram_wr_en = mem_wr;
	//assign port.ram_rd_en = ~mem_wr;

	//instr_mem #("/home/min/devel/fpga/ucl_project_y3/memory/test.mem") imem0(pc, instr, imm);
	
	//risc8_cpu cpu0(port.clk, port.rst, instr, imm, pc,
	//		port.ram_addr, mem_wr, port.ram_wr_data, port.ram_rd_data);
	
	word instr, imm0, imm1, imm2;
	assign imm0 = 8'h00;
	assign instr = 8'h00;

	risc8_cdi cdi0();
	controller8 ctrl0(
			.instr(instr),
			.cdi(cdi0),
			.mem_wr(port.ram_wr_en),
			.mem_rd(port.ram_rd_en)
	);
	datapath8 dpath0(
			.clk(port.clk),
			.rst(port.rst),
			.cdi(cdi0),
			.imm(imm0),
			.mem_rd(port.ram_rd_data),
			.mem_wr(port.ram_wr_data)
	);

endmodule

`timescale 1ns / 1ns
module risc8_cpu_tb;
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

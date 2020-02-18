`ifndef DEFINED
`define DEFINED
`include "oisc.sv"
`include "../const.sv"
`endif

import oisc8_pkg::*;

module pc_block(IBus.port bus, IBus.iport port);
	parameter PROGRAM = "";

	wire[`SAWIDTH+`DAWIDTH:0] instr;

	assign port.imm = instr[`DAWIDTH+`SAWIDTH];
	assign port.instr_dst = e_iaddr_dst'(instr[`DAWIDTH+`SAWIDTH-1:`SAWIDTH]);
	assign port.instr_src = e_iaddr_src'(port.imm ? `SAWIDTH'd0 : instr[`SAWIDTH-1:0]);
	
	reg write_null;	
	always_comb write_null = (bus.instr_src == `SAWIDTH'd0) & ~port.imm;
	data_buf dbus0(bus, `DWIDTH'd0, write_null);	
	data_buf dbus1(bus, instr[`DWIDTH-1:0], port.imm);	
	
	wire[15:0] pcn;
	reg[15:0] pc, pcr; // Program counter
	reg[15:0] pointer;  // Instruction pointer accumulator
	reg[7:0] comp_acc;  // Compare accumulator
	reg comp_zero, pc0;

	/* ====================
	*       ROM BLOCK
	   ==================== */
	wire [26:0] instrBlock;
	wire [12:0] instrA, instrB;
	`ifdef SYNTHESIS
	m9k_rom#(.PROGRAM({PROGRAM, "_0.mif"}),.NAME("rom0"),.WIDTH(9),.NUMWORDS(1024))
		rom0(pc[10:1], bus.clk, instrBlock[26:18]);
	m9k_rom#(.PROGRAM({PROGRAM, "_1.mif"}),.NAME("rom1"),.WIDTH(9),.NUMWORDS(1024))
		rom1(pc[10:1], bus.clk, instrBlock[17:9]);
	m9k_rom#(.PROGRAM({PROGRAM, "_2.mif"}),.NAME("rom2"),.WIDTH(9),.NUMWORDS(1024))
		rom2(pc[10:1], bus.clk, instrBlock[8:0]);
	`else
	pseudo_rom#(.PROGRAM({PROGRAM, "_0.mem"}),.WIDTH(9),.NUMWORDS(1024),.BINARY(1)) 
		rom0(pc[10:1], bus.clk, instrBlock[26:18]);
	pseudo_rom#(.PROGRAM({PROGRAM, "_1.mem"}),.WIDTH(9),.NUMWORDS(1024),.BINARY(1)) 
		rom1(pc[10:1], bus.clk, instrBlock[17:9]);
	pseudo_rom#(.PROGRAM({PROGRAM, "_2.mem"}),.WIDTH(9),.NUMWORDS(1024),.BINARY(1)) 
		rom2(pc[10:1], bus.clk, instrBlock[8:0]);
	`endif
	assign instrA = instrBlock[26:14];
	assign instrB = instrBlock[13:1];
	assign instr = pc0 ? instrA : instrB;

	`ifdef DEBUG
	reg [15:0] pcp;  // Current program counter for debugging
	always_ff@(posedge bus.clk) pcp <= pc;
	sys_sp#("PC", 16) sys_pc(pcp);
	sys_sp#("INST", 13) sys_instr(instr);
	sys_sp#("BRPT", 16) sys_brpt(pointer);
	sys_sp#("DATA", 16) sys_data(port.data);
	`endif
	

	always_comb comp_zero = comp_acc == `DWIDTH'd0;
	//assign pcn = comp_zero|bus.rst ? pointer : pc + 1;
	assign pcn = pc + 1;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) begin 
			pcr <= 16'd0;
			pc0 <= 1'b0;
		end else begin 
			pcr <= pcn;
			pc0 <= pc[0];
		end
	end
	always_comb casez({comp_zero,bus.rst})
		2'b00: pc = pcr;
		2'b10: pc = pointer;
		2'b?1: pc = 16'd0;
	endcase

	PortReg#(.ADDR_SRC(BRPT0R), .ADDR_DST(BRPT0)) p_brpt0(
			.bus(bus),.register(pointer[7:0]),.wr(),.rd()
	);
	PortReg#(.ADDR_SRC(BRPT1R), .ADDR_DST(BRPT1)) p_brpt1(
			.bus(bus),.register(pointer[15:8]),.wr(),.rd()
	);
	PortInput#(.ADDR(BRZ), .DEFAULT(`DWIDTH'hFF)) p_brz(
			.bus(bus),.data_from_bus(comp_acc),.wr()
	);
	PortOutput#(.ADDR(PC0)) p_pc0(.bus(bus),.data_to_bus(pcn[7:0]),.rd());
	PortOutput#(.ADDR(PC1)) p_pc1(.bus(bus),.data_to_bus(pcn[15:8]),.rd());
endmodule

`timescale 100ps/100ps
module pc_block_tb;
	reg clk, rst;

	IBus bus0(clk, rst);
	pc_block#(.PROGRAM("../../memory/oisc8.text")) pc0(bus0.port, bus0.iport);

	initial forever#500ns clk = ~clk;
	initial begin
		clk = 0;
		rst = 1;
		#1100ns;
		rst = 0;
	end
	
endmodule

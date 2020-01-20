package oisc8_pkg;

	// Instruction address bus width
	parameter ASIZE = 8;

	typedef enum logic [ASIZE-1:0] {
		NONE   =8'd0,
		// ALU BLOCK
		ACC    =8'd1,
		ACCI   =8'd2,
		ADD    =8'd3,
		ADDI   =8'd4,
		SUB    =8'd5,
		SUBI   =8'd6,
		ANDOR  =8'd7,
		ANDORI =8'd8,
		NXOR   =8'd9,	
		NXORI  =8'd10,	
		SHF    =8'd11,	
		SHFI   =8'd12,	
		MUL    =8'd13,	
		MULI   =8'd14,	
		DIV    =8'd15,	
		DIVI   =8'd16,
		// PC BLOCK
		BRPT0  =8'd17,
		BRPT1  =8'd18,
		BRZ    =8'd19
		
	} e_iaddr;  // destination enum

	typedef enum logic [ASIZE-1:0] {
		NULL_   =8'd0,
		// ALU BLOCK
		ACC0_S  =8'd1,
		ACC1_S  =8'd2,
		ADD_S   =8'd3,
		ADDC_S  =8'd4,
		SUB_S   =8'd5,
		SUBC_S  =8'd6,
		AND_S   =8'd7,
		OR_S    =8'd8,
		XOR_S   =8'd9,	
		NOT_S   =8'd10,	
		SLL_S   =8'd11,	
		SRL_S   =8'd12,	
		MULLO_S =8'd13,	
		MULHI_S =8'd14,	
		DIV_S   =8'd15,	
		MOD_S   =8'd16
		// PC BLOCK
		
	} e_iaddr_src;  // source enum

endpackage

interface IBus(
	input logic clk, rst,
	inout wire[7:0] data,
	input wire[8*2-1:0] instr  // FIXME, replace 8 with ASIZE
	);
	import oisc8_pkg::*;

	e_iaddr instr_dst;
	e_iaddr_src instr_src;
	assign instr_dst = e_iaddr'(instr[15:8]); // FIXME: Use ASIZE
	assign instr_src = e_iaddr_src'(instr[7:0]);

endinterface

module Port(
		IBus bus,
		output reg[7:0] data_from_bus,
		input  reg[7:0] data_to_bus
	);
	parameter ADDR = 8'd0;

	reg rd, wr;
	assign rd = bus.instr_dst == ADDR;
	assign wr = bus.instr_src == ADDR;
	assign bus.data = wr ? data_to_bus : 'bZ;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) 
			data_from_bus <= 0;
		else 
			data_from_bus <= rd ? bus.data : data_from_bus;
	end
endmodule

module PortImm(
		IBus bus,
		output reg[7:0] data_from_bus,
		input  reg[7:0] data_to_bus
);
	parameter ADDR = 8'd0;

	reg rd, wr;
	assign rd = bus.instr_dst == ADDR;
	assign wr = bus.instr_src == ADDR;
	
	assign bus.data = wr ? data_to_bus : 'bZ;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) 
			data_from_bus <= 0;
		else 
			data_from_bus <= rd ? bus.data : bus.instr_src;	
	end
endmodule

module PortComb(
		IBus bus,
		output reg[7:0] data_from_bus,
		input  reg[7:0] data_to_bus
);
	parameter ADDR = 8'd0;
	parameter ADDRI = 8'd0;
	

	reg rd, wr;
	assign rd = bus.instr_dst == ADDR;
	assign rdi = bus.instr_dst == ADDRI;
	assign wr = bus.instr_src == ADDR;
	assign wri = bus.instr_src == ADDRI;
	
	assign bus.data = (wr|wri) ? data_to_bus : 'bZ;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) 
			data_from_bus = 0;
		else begin
			if(rd) data_from_bus <= bus.data;
			else if(rdi) data_from_bus <= bus.instr_src;
			else data_from_bus <= data_from_bus; // keep previous value
		end
	end
endmodule

module PortCombDual(
		IBus bus,
		output reg[7:0] data_from_bus,
		input  reg[7:0] data_to_bus,   // When ADDR
		input  reg[7:0] data_to_bus_i  // When ADDRI
);
	parameter ADDR = 8'd0;
	parameter ADDRI = 8'd0;
	
	reg rd, wr;
	assign rd = bus.instr_dst == ADDR;
	assign rdi = bus.instr_dst == ADDRI;
	assign wr = bus.instr_src == ADDR;
	assign wri = bus.instr_src == ADDRI;
	
	assign bus.data = wr ? data_to_bus : 'bz;
	assign bus.data = wri & !wr ? data_to_bus_i : 'bz; // with protection.

	always_ff@(posedge bus.clk) begin
		if(bus.rst) 
			data_from_bus <= 0;
		else begin
			if(rd) data_from_bus <= bus.data;
			else if(rdi) data_from_bus <= bus.instr_src;
			else data_from_bus <= data_from_bus; // keep previous value
		end
	end
endmodule

module PortInput(
		IBus bus,
		output reg[7:0] data_from_bus,
		input reg reset
	);
	parameter ADDR = 8'd0;
	parameter DEFAULT = 8'd0;

	reg rd;
	assign rd = bus.instr_dst == ADDR;
	always_ff@(posedge bus.clk) begin
		if(bus.rst|reset) 
			data_from_bus <= DEFAULT;
		else 
			data_from_bus <= rd ? bus.data : data_from_bus;
	end
endmodule

module PortOutput(
		IBus bus,
		input  reg[7:0] data_to_bus
	);
	parameter ADDR = 8'd0;

	reg wr;
	assign wr = bus.instr_src == ADDR;
	assign bus.data = wr ? data_to_bus : 'bZ;
endmodule

`define DWIDTH  8 // Data bus width
`define DAWIDTH 4 // Dest. address width
`define SAWIDTH 8 // Src. address width

package oisc8_pkg;

	typedef enum logic [`DAWIDTH-1:0] {
		ALUACC0 ='d0,
		ALUACC1 ='d1,
		BRPT0   ='d2,
		BRPT1   ='d3,
		BRZ     ='d4,
		STACK   ='d5,
		MEMPT0  ='d6,
		MEMPT1  ='d7,
		MEMPT2  ='d8,
		MEMSWHI ='d9,
		MEMSWLO ='d10,
		COMA    ='d11,
		COMD    ='d12
	} e_iaddr_dst;  // destination enum

	typedef enum logic [`SAWIDTH-1:0] {
		NULL    ='d0,
		// ALU BLOCK
		ALUACC0R='d1,
		ALUACC1R='d2,
		ADD     ='d3,
		ADDC    ='d4,
		SUB     ='d5,
		SUBC    ='d6,
		AND     ='d7,
		OR      ='d8,
		XOR     ='d9,	
		SLL     ='d11,	
		SRL     ='d12,	
		EQ     	='d13,	
		GT     	='d14,	
		GE    	='d15,	
		MULLO   ='d16,	
		MULHI   ='d17,	
		DIV     ='d18,	
		MOD     ='d19,
		// Program Counter
		BRPT0R  ='d20,
		BRPT1R  ='d21,
		// Memory
		MEMPT0R ='d22,
		MEMPT1R ='d23,
		MEMPT2R ='d24,
		MEMLWHI ='d25,
		MEMLWLO ='d26,
		STACKR	='d27,
		STPT0R  ='d28,
		STPT1R  ='d29,
		// COM
		COMAR   ='d30,
		COMDR   ='d31		
	} e_iaddr_src;  // source enum

endpackage

interface IBus(clk, rst, data, instr);
	import oisc8_pkg::*;
	
	input logic clk, rst;
	inout wire[`DWIDTH-1:0] data;
	input wire[`SAWIDTH+`DAWIDTH:0] instr;

	logic imm;
	e_iaddr_dst instr_dst;
	e_iaddr_src instr_src;
	assign imm = instr[`DAWIDTH+`SAWIDTH];
	assign instr_dst = e_iaddr_dst'(instr[`DAWIDTH+`SAWIDTH-1:`SAWIDTH]);
	assign instr_src = e_iaddr_src'(instr[`SAWIDTH-1:0]);

endinterface

module PortReg(bus, data_from_bus, data_to_bus, rd, wr);
	import oisc8_pkg::*;

	IBus bus;
	output logic[`DWIDTH-1:0] data_from_bus;
	input  logic[`SAWIDTH-1:0] data_to_bus;
	output reg rd, wr;

	parameter ADDR_SRC = e_iaddr_src'(0);
	parameter ADDR_DST = e_iaddr_dst'(0);
	parameter DEFAULT = `DWIDTH'd0;

	reg [`SAWIDTH-1:0] data;
	always_comb casez({bus.imm,bus.rst})
		2'b00: data = bus.data[`SAWIDTH-1:0];
		2'b10: data = bus.instr_src;
		2'b?1: data = DEFAULT;
	endcase

	assign wr = bus.instr_dst == ADDR_DST;
	assign rd = bus.instr_src == ADDR_SRC;
	assign bus.data = rd ? data_to_bus : 'bZ;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) data_from_bus <= DEFAULT;
		else if(wr) data_from_bus <= data;
	end
endmodule

module PortRegSeq(bus, data_from_bus, data_to_bus, rd, wr);
	import oisc8_pkg::*;

	IBus bus;
	output logic[`DWIDTH-1:0] data_from_bus;
	input  logic[`SAWIDTH-1:0] data_to_bus;
	output reg rd, wr;

	parameter ADDR_SRC = e_iaddr_src'(0);
	parameter ADDR_DST = e_iaddr_dst'(0);
	parameter DEFAULT = `DWIDTH'd0;

	reg [`SAWIDTH-1:0] data, latch;
	always_comb casez({bus.imm,bus.rst})
		2'b00: data = bus.data[`SAWIDTH-1:0];
		2'b10: data = bus.instr_src;
		2'b?1: data = DEFAULT;
	endcase

	assign wr = bus.instr_dst == ADDR_DST;
	assign rd = bus.instr_src == ADDR_SRC;
	assign bus.data = rd ? data_to_bus : 'bZ;
	assign data_from_bus = wr ? data : latch;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) latch <= DEFAULT;
		else if(wr) latch <= data;
	end
endmodule

module PortInput(bus, data_from_bus, wr, rst);
	import oisc8_pkg::*;

	IBus bus;
	output reg[`DWIDTH-1:0] data_from_bus;
	output reg wr;
	input reg rst;

	parameter ADDR = e_iaddr_dst'(0);
	parameter DEFAULT = `DWIDTH'd0;

	reg [`SAWIDTH-1:0] data;
	assign data = bus.imm ? bus.instr_src : bus.data[`SAWIDTH-1:0];

	assign wr = bus.instr_dst == ADDR;
	always_ff@(posedge bus.clk) begin
		if(bus.rst|rst) 
			data_from_bus <= DEFAULT;
		else 
			data_from_bus <= wr ? data : data_from_bus;
	end
endmodule

module PortInputSeq(bus, data_from_bus, wr);
	import oisc8_pkg::*;

	IBus bus;
	output reg[`DWIDTH-1:0] data_from_bus;
	output reg wr;

	parameter ADDR = e_iaddr_dst'(0);
	parameter DEFAULT = `DWIDTH'd0;

	reg [`SAWIDTH-1:0] data;
	assign data = bus.imm ? bus.instr_src : bus.data[`SAWIDTH-1:0];
	assign wr = bus.instr_dst == ADDR;
	assign data_from_bus = wr ? data : DEFAULT;
endmodule


module PortOutput(bus, data_to_bus, rd);
	import oisc8_pkg::*;

	IBus bus;
	input  reg[`SAWIDTH-1:0] data_to_bus;
	output reg rd;

	parameter ADDR = e_iaddr_src'(0);

	assign rd = bus.instr_src == ADDR;
	assign bus.data = rd ? data_to_bus : 'bZ;
endmodule

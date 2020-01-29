`define DWIDTH  8 // Data bus width
`define DAWIDTH 4 // Dest. address width
`define SAWIDTH 8 // Src. address width

package oisc8_pkg;

	typedef enum logic [`DAWIDTH-1:0] {
		ALUACC0 =`DAWIDTH'd0,
		ALUACC1 =`DAWIDTH'd1,
		BRPT0   =`DAWIDTH'd2,
		BRPT1   =`DAWIDTH'd3,
		BRZ     =`DAWIDTH'd4,
		STACK   =`DAWIDTH'd5,
		MEMPT0  =`DAWIDTH'd6,
		MEMPT1  =`DAWIDTH'd7,
		MEMPT2  =`DAWIDTH'd8,
		MEMSWHI =`DAWIDTH'd9,
		MEMSWLO =`DAWIDTH'd10,
		COMA    =`DAWIDTH'd11,
		COMD    =`DAWIDTH'd12,
		REG0    =`DAWIDTH'd13,
		REG1    =`DAWIDTH'd14
	} e_iaddr_dst;  // destination enum

	typedef enum logic [`SAWIDTH-1:0] {
		NULL    =`SAWIDTH'd0,
		// ALU BLOCK
		ALUACC0R=`SAWIDTH'd1,
		ALUACC1R=`SAWIDTH'd2,
		ADD     =`SAWIDTH'd3,
		ADDC    =`SAWIDTH'd4,
		SUB     =`SAWIDTH'd5,
		SUBC    =`SAWIDTH'd6,
		AND     =`SAWIDTH'd7,
		OR      =`SAWIDTH'd8,
		XOR     =`SAWIDTH'd9,	
		SLL     =`SAWIDTH'd10,	
		SRL     =`SAWIDTH'd11,	
		EQ     	=`SAWIDTH'd12,	
		GT     	=`SAWIDTH'd13,	
		GE    	=`SAWIDTH'd14,	
		NE     	=`SAWIDTH'd15,	
		LT     	=`SAWIDTH'd16,	
		LE    	=`SAWIDTH'd17,
		MULLO   =`SAWIDTH'd18,	
		MULHI   =`SAWIDTH'd19,	
		DIV     =`SAWIDTH'd20,	
		MOD     =`SAWIDTH'd21,
		// Program Counter
		BRPT0R  =`SAWIDTH'd22,
		BRPT1R  =`SAWIDTH'd23,
		// Memory
		MEMPT0R =`SAWIDTH'd24,
		MEMPT1R =`SAWIDTH'd25,
		MEMPT2R =`SAWIDTH'd26,
		MEMLWHI =`SAWIDTH'd27,
		MEMLWLO =`SAWIDTH'd28,
		STACKR	=`SAWIDTH'd29,
		STPT0R  =`SAWIDTH'd30,
		STPT1R  =`SAWIDTH'd31,
		// COM
		COMAR   =`SAWIDTH'd32,
		COMDR   =`SAWIDTH'd33,
		// GP_REG
		REG0R   =`SAWIDTH'd34,
		REG1R   =`SAWIDTH'd35
	} e_iaddr_src;  // source enum

endpackage

interface IBus(clk, rst, instr);
	import oisc8_pkg::*;
	
	input wire clk, rst;	
	input wire[`SAWIDTH+`DAWIDTH:0] instr;

	wire[`DWIDTH-1:0] data;

	logic imm;
	e_iaddr_dst instr_dst;
	e_iaddr_src instr_src;
	assign imm = instr[`DAWIDTH+`SAWIDTH];
	assign instr_dst = e_iaddr_dst'(instr[`DAWIDTH+`SAWIDTH-1:`SAWIDTH]);
	assign instr_src = e_iaddr_src'(instr[`SAWIDTH-1:0]);
	
	modport port(
		input clk, rst, imm, instr_dst, instr_src,
		inout data
	);
	//modport host(output clk, rst);
endinterface

//module PortReg(bus, data_from_bus, data_to_bus, rd, wr);
//	import oisc8_pkg::*;
//
//	IBus bus;
//	output logic[`DWIDTH-1:0] data_from_bus;
//	input  logic[`SAWIDTH-1:0] data_to_bus;
//	output reg rd, wr;
//
//	parameter ADDR_SRC = e_iaddr_src'(0);
//	parameter ADDR_DST = e_iaddr_dst'(0);
//	parameter DEFAULT = `DWIDTH'd0;
//
//	reg [`SAWIDTH-1:0] data;
//	always_comb begin
//		 casez({bus.imm,bus.rst})
//			2'b00: data = bus.data[`SAWIDTH-1:0];
//			2'b10: data = bus.instr_src;
//			2'b?1: data = DEFAULT;
//		endcase
//
//		wr = (bus.instr_dst == ADDR_DST);
//		rd = (bus.instr_src == ADDR_SRC);
//	end
//	
//	genvar i;
//	generate 
//		for(i=0;i<`DWIDTH;i=i+1) begin : generate_data_buf
//			bufif1(bus.data[i], data_to_bus[i], rd);
//		end 
//	endgenerate
//	
//	always_ff@(posedge bus.clk) begin
//		if(bus.rst) data_from_bus <= DEFAULT;
//		else if(wr) data_from_bus <= data;
//	end
//endmodule

//module PortReg(bus, data_from_bus, data_to_bus, rd, wr);
//	import oisc8_pkg::*;
//
//	IBus bus;
//	output logic[`DWIDTH-1:0] data_from_bus;
//	input  logic[`SAWIDTH-1:0] data_to_bus;
//	output reg rd, wr;
//
//	parameter ADDR_SRC = e_iaddr_src'(0);
//	parameter ADDR_DST = e_iaddr_dst'(0);
//	parameter DEFAULT = `DWIDTH'd0;
//
//	reg [`SAWIDTH-1:0] datain, latch, dataout;
//	always_comb begin
//		casez({bus.imm,bus.rst})
//			2'b00: datain = bus.data[`SAWIDTH-1:0];
//			2'b10: datain = bus.instr_src;
//			2'b?1: datain = DEFAULT;
//		endcase
//
//		wr = (bus.instr_dst == ADDR_DST);
//		rd = (bus.instr_src == ADDR_SRC);
//		data_from_bus = wr ? datain : latch;
//
//	end
//	
//	always_latch begin
//		if(bus.rst) latch <= DEFAULT;
//		else if(wr) latch <= data;
//	end
//	
//	always_ff@(posedge bus.clk) begin
//		if(bus.rst) dataout <= `DWIDTH'd0;
//		else dataout <= data_from_bus;
//	end
//
//	genvar i;
//	generate 
//		for(i=0;i<`DWIDTH;i=i+1) begin : generate_data_buf
//			bufif1(bus.data[i], dataout[i], rd);
//		end 
//	endgenerate
//
//endmodule

module PortReg(bus, register, wr, rd);
	import oisc8_pkg::*;
	
	parameter ADDR_DST = e_iaddr_dst'(0);
	parameter ADDR_SRC = e_iaddr_src'(0);
	parameter DEFAULT = `DWIDTH'd0;

	IBus bus;
	output reg [`DWIDTH-1:0] register;
	output reg wr, rd;
	PortLatch#(ADDR_DST, DEFAULT) p_in(bus, register, wr);
	PortOutputFF#(ADDR_SRC, DEFAULT) p_out(bus, register, rd);
endmodule

module PortInputFF(bus, data_from_bus, wr, rst);
	import oisc8_pkg::*;

	IBus bus;
	output reg[`DWIDTH-1:0] data_from_bus;
	output reg wr;
	input reg rst;

	parameter ADDR = e_iaddr_dst'(0);
	parameter DEFAULT = `DWIDTH'd0;

	reg [`SAWIDTH-1:0] data;

	always_comb begin
		data = bus.imm ? bus.instr_src : bus.data[`SAWIDTH-1:0];
		wr = (bus.instr_dst == ADDR);
	end

	always_ff@(posedge bus.clk) begin
		if(bus.rst|rst) 
			data_from_bus <= DEFAULT;
		else 
			data_from_bus <= wr ? data : data_from_bus;
	end
endmodule

module PortInput(bus, data_from_bus, wr);
	import oisc8_pkg::*;

	IBus bus;
	output reg[`DWIDTH-1:0] data_from_bus;
	output reg wr;

	parameter ADDR = e_iaddr_dst'(0);
	parameter DEFAULT = `DWIDTH'd0;

	reg [`SAWIDTH-1:0] data;
	always_comb begin
		data = bus.imm ? bus.instr_src : bus.data[`SAWIDTH-1:0];
		wr = (bus.instr_dst == ADDR);
		data_from_bus = wr ? data : DEFAULT;
	end
endmodule

module PortOutputFF(bus, data_to_bus, rd);
	import oisc8_pkg::*;
	IBus bus;
	input reg [`DWIDTH-1:0] data_to_bus;
	output reg rd;

	parameter ADDR = e_iaddr_src'(0);
	parameter DEFAULT = `DWIDTH'd0;
	
	reg[`DWIDTH-1:0] register;
	always_comb rd = (bus.instr_src == ADDR);
	always_ff@(posedge bus.clk) begin
		if(bus.rst) register <= DEFAULT;
		else register <= data_to_bus;
	end

	genvar i;
	generate 
		for(i=0;i<`DWIDTH;i=i+1) begin : generate_data_buf
			`ifdef SYNTHESIS
			bufif1(bus.data[i], data_to_bus[i], rd);
			`else
			bufif1(bus.data[i], data_to_bus[i], rd&~bus.imm);
			`endif
		end 
	endgenerate

endmodule

module PortLatch(bus, latched, wr);
	import oisc8_pkg::*;
	IBus bus;
	output reg[`DWIDTH-1:0] latched;
	output reg wr;
	
	parameter ADDR = e_iaddr_dst'(0);
	parameter DEFAULT = `DWIDTH'd0;

	reg[`DWIDTH-1:0] data, register;
	always_comb begin
		wr = (bus.instr_dst == ADDR);
		data = bus.imm ? bus.instr_src : bus.data[`SAWIDTH-1:0];
		latched = wr ? data : register;
	end

	always_ff@(posedge bus.clk) begin
		if(bus.rst) register <= DEFAULT;
		else if(wr) register <= data;
	end
	//always_latch begin
	//	if(bus.rst) latched <= DEFAULT;
	//	else if(wr) latched <= data; 
	//end

endmodule

module PortOutput(bus, data_to_bus, rd);
	import oisc8_pkg::*;

	IBus bus;
	input  reg[`SAWIDTH-1:0] data_to_bus;
	output reg rd;

	//parameter ADDR = e_iaddr_src'(`SAWIDTH'd0);
	parameter ADDR = `SAWIDTH'd0;

	always_comb rd = bus.instr_src == ADDR;

	genvar i;
	generate 
		for(i=0;i<`DWIDTH;i=i+1) begin : generate_data_buf
			`ifdef SYNTHESIS
			bufif1(bus.data[i], data_to_bus[i], rd);
			`else
			bufif1(bus.data[i], data_to_bus[i], rd&~bus.imm);
			`endif
		end 
	endgenerate

endmodule

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
		COMD    =`DAWIDTH'd12
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
		SLL     =`SAWIDTH'd11,	
		SRL     =`SAWIDTH'd12,	
		EQ     	=`SAWIDTH'd13,	
		GT     	=`SAWIDTH'd14,	
		GE    	=`SAWIDTH'd15,	
		MULLO   =`SAWIDTH'd16,	
		MULHI   =`SAWIDTH'd17,	
		DIV     =`SAWIDTH'd18,	
		MOD     =`SAWIDTH'd19,
		// Program Counter
		BRPT0R  =`SAWIDTH'd20,
		BRPT1R  =`SAWIDTH'd21,
		// Memory
		MEMPT0R =`SAWIDTH'd22,
		MEMPT1R =`SAWIDTH'd23,
		MEMPT2R =`SAWIDTH'd24,
		MEMLWHI =`SAWIDTH'd25,
		MEMLWLO =`SAWIDTH'd26,
		STACKR	=`SAWIDTH'd27,
		STPT0R  =`SAWIDTH'd28,
		STPT1R  =`SAWIDTH'd29,
		// COM
		COMAR   =`SAWIDTH'd30,
		COMDR   =`SAWIDTH'd31		
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
	always_comb begin
		 casez({bus.imm,bus.rst})
			2'b00: data = bus.data[`SAWIDTH-1:0];
			2'b10: data = bus.instr_src;
			2'b?1: data = DEFAULT;
		endcase

		wr = (bus.instr_dst == ADDR_DST);
		rd = (bus.instr_src == ADDR_SRC);
	end
	
	genvar i;
	generate 
		for(i=0;i<`DWIDTH;i=i+1) begin : generate_data_buf
			bufif1(bus.data[i], data_to_bus[i], rd);
		end 
	endgenerate

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
	always_comb begin 
		casez({bus.imm,bus.rst})
			2'b00: data = bus.data[`SAWIDTH-1:0];
			2'b10: data = bus.instr_src;
			2'b?1: data = DEFAULT;
		endcase

		wr = (bus.instr_dst == ADDR_DST);
		rd = (bus.instr_src == ADDR_SRC);
		data_from_bus = wr ? data : latch;

	end

	always_ff@(posedge bus.clk) begin
		if(bus.rst) latch <= DEFAULT;
		else if(wr) latch <= data;
	end

	genvar i;
	generate 
		for(i=0;i<`DWIDTH;i=i+1) begin : generate_data_buf
			bufif1(bus.data[i], data_to_bus[i], rd);
		end 
	endgenerate

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

module PortInputSeq(bus, data_from_bus, wr);
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


module PortOutput(bus, data_to_bus, rd);
	import oisc8_pkg::*;

	IBus bus;
	input  reg[`SAWIDTH-1:0] data_to_bus;
	output reg rd;

	//parameter ADDR = e_iaddr_src'(`SAWIDTH'd0);
	parameter ADDR = `SAWIDTH'd0;

	always_comb rd = (bus.instr_src == ADDR);

	genvar i;
	generate 
		for(i=0;i<`DWIDTH;i=i+1) begin : generate_data_buf
			bufif1(bus.data[i], data_to_bus[i], rd);
		end 
	endgenerate

endmodule

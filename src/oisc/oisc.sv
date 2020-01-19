package oisc8_pkg;

	// Instruction address bus width
	parameter ASIZE = 8;

	typedef enum logic [ASIZE-1:0] {
		NONE=8'd0,
		ACC =8'd1,
		ACCI=8'd2,
		ADD =8'd3,
		ADDI=8'd4,
		SUB =8'd5,
		SUBI=8'd6
	} e_iaddr;

endpackage

interface IBus(
	input logic clk, rst,
	inout wire[7:0] data,
	input wire[8*2-1:0] instr  // FIXME, replace 8 with ASIZE
	);
endinterface

module Port(
		IBus bus,
		output reg[7:0] data_from_bus,
		input  reg[7:0] data_to_bus
	);
	

	localparam ASIZE = 8;  // FIXME: take from oisc8_pkg
	parameter ADDR = 8'd0;
	parameter IMMIDATE = 0;

	reg rd, wr;
	assign rd = bus.instr[ASIZE-1:0] == ADDR;
	assign wr = bus.instr[ASIZE*2-1:ASIZE] == ADDR;
	assign bus.data = wr ? data_to_bus : 'bZ;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) begin
			data_from_bus <= 0;
		end else begin
			if(IMMIDATE == 0)
				data_from_bus <= rd ? bus.data : data_from_bus;
			else 
				data_from_bus <= rd ? bus.data : bus.instr[ASIZE*2-1:ASIZE];
		end
	end

endmodule

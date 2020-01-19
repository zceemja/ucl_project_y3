`include "oisc.sv"
import oisc8_pkg::*;

module oisc8_cpu(processor_port port);
	
	wire [7:0] data_bus;
	wire [8*2-1:0] inst_bus;  // FIXME: replace 8 with ASIZE
	
	IBus bus0(
			.clk(port.clk),
			.rst(port.rst),
			.instr(instr_bus),
			.data(data_bus)
	);

	pc_block#(.PROGRAM("../../memory/oisc8.text")) pc0(bus0);
	alu_block alu0(bus0);

endmodule

module pc_block(IBus bus);
	parameter PROGRAM = "";
	reg[15:0] pc, pcn; // Program counter

	`ifdef SYNTHESIS
	m9k_rom#(
			.PROGRAM({PROGRAM, ".mif"}), 
			.NAME("rom0"),
			.WIDTH(16),
			.NUMWORDS(2048)
	)
	`else
	pseudo_rom#(
			.PROGRAM({PROGRAM, ".mem"}), 
			.WIDTH(16),
			.NUMWORDS(2048)
	) 
	`endif
		rom0(pcn[11:0], bus.clk, bus.instr);

	assign pcn = pc + 1;  // Next pc 
	always_ff@(posedge bus.clk) begin
		if(bus.rst) pc <= 0;
		else pc <= pcn;
	end

endmodule

module alu_block(IBus bus);
	reg[7:0] acc;
	logic add_carry, sub_carry;
	Port #(.ADDR(ACCI), .IMMIDATE(1)) p_acc0(
			.bus(bus),
			.data_from_bus(acc),
			.data_to_bus(acc)
	);
	
	reg[7:0] add_input;
	reg[7:0] add_output;
	assign {add_carry,add_output} = add_input + acc;
	Port #(.ADDR(ADDI), .IMMIDATE(1)) p_add0(
			.bus(bus),
			.data_from_bus(add_input),
			.data_to_bus(add_output)
	);
	
	reg[7:0] sub_input;
	reg[7:0] sub_output;
	assign {sub_carry,sub_output} = sub_input - acc;
	Port #(.ADDR(SUB)) p_sub0(
			.bus(bus),
			.data_from_bus(sub_input),
			.data_to_bus(sub_output)
	);	

endmodule
	

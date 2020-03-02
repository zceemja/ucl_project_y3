`include "../const.sv"

module m9k_ram (
	address,
	clock,
	data,
	wren,
	q);
	
	parameter PROGRAM = "";
	parameter NAME="";
	parameter DEPTH=`RAM_SIZE;
	
	input	[$clog2(DEPTH)-1:0]  address;
	input	  clock;
	input	[15:0]  data;
	input	  wren;
	output	[15:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [15:0] sub_wire0;
	wire [15:0] q = sub_wire0[15:0];

	initial $display({"Initialising RAM Memory: ", PROGRAM, ".mif"});

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = {PROGRAM, ".mif"},
		altsyncram_component.intended_device_family = "Cyclone IV E",
		altsyncram_component.lpm_hint = {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=", NAME},
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = DEPTH,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M9K",
		altsyncram_component.read_during_write_mode_port_a = "DONT_CARE",
		altsyncram_component.widthad_a = $clog2(DEPTH),
		altsyncram_component.width_a = 16,
		altsyncram_component.width_byteena_a = 1;
endmodule

module pseudo_ram(addr, clk, data, wren, rden, q);
	
	parameter PROGRAM = "";
	parameter DEPTH=`RAM_SIZE;

	input [$clog2(DEPTH)-1:0] addr;
	input clk, wren, rden;
	input [15:0] data;
	output reg [15:0] q;
	
	reg [15:0] memory [DEPTH-1:0];
	initial if(PROGRAM != "") begin
			$readmemh({PROGRAM, ".mem"}, memory);
			$display({"Initialising RAM Memory: ", PROGRAM, ".mem"});
	end

	always_ff@(posedge clk) begin
		if(wren) memory[addr] <= data;
		if (rden) q <= memory[addr];
		else q <= 'x;
	end
	
endmodule


module ram(address, clk, data, wren, rden, q);
	parameter PROGRAM = "";
	parameter DEPTH=`RAM_SIZE;

	input [$clog2(DEPTH)-1:0] address;
	input clk, wren, rden;
	input [15:0] data;
	output [15:0] q;
	
	`ifdef SYNTHESIS
		m9k_ram#(PROGRAM, "ram0", DEPTH) ram0(address, clk, data, wren, q);
	`else
		pseudo_ram#(PROGRAM, DEPTH) ram0(address, clk, data, wren, rden, q);
	`endif

endmodule


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on


module m9k_rom (
	address,
	clock,
	q);

	parameter PROGRAM="";
	parameter NAME="";
	parameter WIDTH=8;
	parameter NUMWORDS=1024;
	localparam AWIDTH=$clog2(NUMWORDS);

	input	[AWIDTH-1:0]  address;
	input	  clock;
	output	[WIDTH-1:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [WIDTH-1:0] sub_wire0;
	wire [WIDTH-1:0] q = sub_wire0[WIDTH-1:0];
	
	initial $display("Initialising ROM Memory: %s", PROGRAM);

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
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
				.data_a ({WIDTH{1'b1}}),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_a (1'b0),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = PROGRAM,
		altsyncram_component.intended_device_family = "Cyclone IV E",
		altsyncram_component.lpm_hint = {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=", NAME},
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = NUMWORDS,
		altsyncram_component.operation_mode = "ROM",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.ram_block_type = "M9K",
		altsyncram_component.widthad_a = AWIDTH,
		altsyncram_component.width_a = WIDTH,
		altsyncram_component.width_byteena_a = 1;

endmodule 

module pseudo_rom(addr, clk, q);
	parameter PROGRAM="";
	parameter WIDTH=8;
	parameter NUMWORDS=1024;
	parameter BINARY=1;
	localparam AWIDTH=$clog2(NUMWORDS);
	
	input  reg 	clk;
	input  wire [AWIDTH-1:0] addr;
	output reg [WIDTH-1:0] q;
	
	initial begin
		$display("Initialising ROM Memory: %s", PROGRAM);
		if (BINARY==1) $readmemb(PROGRAM, rom);
		else $readmemh(PROGRAM, rom);
	end
	
	reg [AWIDTH-1:0] addr0;
	logic [WIDTH-1:0] rom [NUMWORDS:0];
	always_ff@(posedge clk) addr0 <= addr; 	
	assign q = rom[addr0];

endmodule

module rom (
	address,
	clock,
	q);
	parameter PROGRAM="";

	input	reg [11:0]  address;
	input	clock;
	output	reg [31:0]  q;
	
	reg [31:0]  qn;
	
	reg [9:0] addr0, addr1, addr2, addr3;
	reg [11:0] a3, a2, a1;
	reg [7:0] q0, q1, q2, q3;
	reg [1:0] ar;
	always_ff@(posedge clock) ar <= address[1:0];

	always_comb begin
		a3 = address + 3;
		a2 = address + 2;
		a1 = address + 1;
		// Dividing by 4
		addr0 = a3[11:2];
		addr1 = a2[11:2];
		addr2 = a1[11:2];
		addr3 = address[11:2];
		
		case(ar)
			2'b00: qn = {q3, q2, q1, q0};
			2'b01: qn = {q0, q3, q2, q1};
			2'b10: qn = {q1, q0, q3, q2};
			2'b11: qn = {q2, q1, q0, q3};
		endcase
		q = qn;
	end
	//always_ff@(posedge clock) q <= qn;

	`ifdef SYNTHESIS
	m9k_rom#({PROGRAM, ".0.mif"}, "rom0") rom0(addr0, clock, q0);
	m9k_rom#({PROGRAM, ".1.mif"}, "rom1") rom1(addr1, clock, q1);
	m9k_rom#({PROGRAM, ".2.mif"}, "rom2") rom2(addr2, clock, q2);
	m9k_rom#({PROGRAM, ".3.mif"}, "rom3") rom3(addr3, clock, q3);
	`else
		pseudo_rom#({PROGRAM, ".0.mem"}) rom0(addr0, clock, q0);
		pseudo_rom#({PROGRAM, ".1.mem"}) rom1(addr1, clock, q1);
		pseudo_rom#({PROGRAM, ".2.mem"}) rom2(addr2, clock, q2);
		pseudo_rom#({PROGRAM, ".3.mem"}) rom3(addr3, clock, q3);
		// Currently read address (for debugging)
		reg [11:0] ff_addr;
		always_ff@(posedge clock) ff_addr <= address;
	`endif

endmodule



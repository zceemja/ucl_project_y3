/*
 * This is top level entity file.
 * It includes all cpu external modules like UART
 * and SDRAM controller. 
*/

// Compile OISC?
`define OISC

`ifdef OISC
`include "oisc/cpu.sv"
`elsif
`include "risc/cpu.sv"
`endif

module top(
	input  			CLK50,		// Clock 50MHz

	// Board connections
	input  [3:0]	SWITCH,		// 4 Dip switches
	input  [1:0]	KEY,		// 2 Keys
	output [7:0]	LED,		// 8 LEDs

	// UART
	input  			RX,			// UART Receive
	output 			TX,			// UART Transmit

	// SDRAM
	inout  [15:0]	DRAM_DQ,	// Data
	output [12:0] 	DRAM_ADDR,	// Address
	output [1:0]	DRAM_DQM,	// Byte Data Mask
	output			DRAM_CLK,	// Clock
	output			DRAM_CKE,	// Clock Enable
	output			DRAM_WE_N,	// Write Enable
	output			DRAM_CAS_N, // Column Address Strobe
	output			DRAM_RAS_N, // Row Address Strobe
	output			DRAM_CS_N,	// Chip Select
	output [1:0] 	DRAM_BA		// Bank Address
	);
	
	`ifdef SYNTHESIS
		initial $display("Assuming this is synthesis");
	`else
		initial $display("Assuming this is simulation");
	`endif

	assign rst = ~KEY[0];
	
	/* Clocks */
	wire mclk; // Master clock 		1MHz 		(for cpu)
	wire fclk; // Fast clock 		100MHz 		(for sdram)
	wire aclk; // Auxiliary clock 	32,768kHz 	(for timers)
	
	pll_clk pll_clk0 (
			.inclk0(CLK50),
			.areset(0),
			.c0(fclk),
			.c1(mclk),
			.c2(aclk)
	);

	//clk_dive#(28'd50) clk_div_mclk(CLK50, mclk);
	//assign mclk = ~KEY[1];	
	//assign mclk = CLK50;	

	wire [23:0]	ram_addr;
    wire [15:0] ram_wr_data;
    wire [15:0] ram_rd_data;
    wire 		ram_wr_en;
    wire		ram_rd_en;
    wire  		ram_busy;
	wire  		ram_rd_ready;
	wire  		ram_rd_ack;
	
	ram#("../../memory/risc8.data") ram_block0(ram_addr[11:0], mclk, ram_wr_data, ram_wr_en, ram_rd_en, ram_rd_data);
	
	//sdram_block sdram0(
	//	.mclk(mclk), 
	//	.fclk(fclk), 
	//	.rst_n(~rst), 
	//	.ram_addr(racm_addr),
	//	.ram_wr_data(ram_wr_data),
	//	.ram_rd_data(ram_rd_data),
	//	.ram_wr_en(ram_wr_en),
	//	.ram_rd_en(ram_rd_en),
	//	.ram_busy(ram_busy),
	//	.ram_rd_ready(ram_rd_ready),
	//	.ram_rd_ack(ram_rd_ack),
	//	.DRAM_DQ(DRAM_DQ),	
	//	.DRAM_ADDR(DRAM_ADDR),	
	//	.DRAM_DQM(DRAM_DQM),	
	//	.DRAM_CLK(DRAM_CLK),	
	//	.DRAM_CKE(DRAM_CKE),	
	//	.DRAM_WE_N(DRAM_WE_N),	
	//	.DRAM_CAS_N(DRAM_CAS_N),
	//	.DRAM_RAS_N(DRAM_RAS_N),
	//	.DRAM_CS_N(DRAM_CS_N),	
	//	.DRAM_BA(DRAM_BA)	
	//);

	//Communication block
	wire [7:0] com0_addr, com0_wr, com0_rd;
	wire com0_interrupt;

	com_block com0 (
		.clk(mclk),
		.rst(rst),
		.addr(com0_addr),
		.in_data(com0_wr),
		.out_data(com0_rd),
		.interrupt(com0_interrupt),
		.leds(LED),
		.switches(SWITCH),
		.uart0_rx(RX),
		.uart0_tx(TX),
		.key1(KEY[1])
	);

	// Processor
	processor_port port0 (
		.clk(mclk),
		.rst(rst),
		.ram_addr(ram_addr),
        .ram_wr_data(ram_wr_data),
        .ram_rd_data(ram_rd_data),
        .ram_wr_en(ram_wr_en),
        .ram_rd_en(ram_rd_en),
        .ram_busy(ram_busy),
		.ram_rd_ready(ram_rd_ready),
		.ram_rd_ack(ram_rd_ack),
		.com_addr(com0_addr),
		.com_wr(com0_wr),
		.com_rd(com0_rd),
		.com_interrupt(com0_interrupt)
	);
	
	`ifdef OISC
	oisc8_cpu cpu_block0(port0);
	`elsif
	risc8_cpu cpu_block0(port0);
	`endif

endmodule


module clk_dive(clock_in,clock_out);
input clock_in; // input clock on FPGA
output clock_out; // output clock after dividing the input clock by divisor
reg[27:0] counter=28'd0;
parameter DIVISOR = 28'd2;
always @(posedge clock_in)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;
end
assign clock_out = (counter<DIVISOR/2)?1'b0:1'b1;
endmodule

`timescale 1ns/1ns
module top_tb;

	logic 		 CLK50;		// Clock 50MHz
	logic [3:0]	 SWITCH;		// 4 Dip switches
	logic [1:0]	 KEY;		// 2 Keys
	wire  [7:0]	 LED;		// 8 LEDs
	logic 		 RX;			// UART Receive
	logic 		 TX;			// UART Transmit
	wire  [15:0] DRAM_DQ;	// Data
	logic [12:0] DRAM_ADDR;	// Address
	logic [1:0]	 DRAM_DQM;	// Byte Data Mask
	logic  		 DRAM_CLK;	// Clock
	logic  		 DRAM_CKE;	// Clock Enable
	logic  		 DRAM_WE_N;	// Write Enable
	logic  		 DRAM_CAS_N; // Column Address Strobe
	logic  		 DRAM_RAS_N; // Row Address Strobe
	logic  		 DRAM_CS_N;	// Chip Select
	logic [1:0]  DRAM_BA;		// Bank Address

	top top0(
				CLK50,		
				SWITCH,	
				KEY,		
				LED,		
				RX,		
				TX,		
				DRAM_DQ,	
				DRAM_ADDR,	
				DRAM_DQM,	
				DRAM_CLK,	
				DRAM_CKE,	
				DRAM_WE_N,	
				DRAM_CAS_N,
				DRAM_RAS_N,
				DRAM_CS_N,	
				DRAM_BA	
				);

	initial if(top0.com0_addr == 8'h05) $display("%t UART0 send: %s", $time, top0.com0_wr); 


	initial begin
			CLK50 = 0;
			KEY[0] = 0;
			KEY[1] = 1;
			SWITCH = 4'b0110;
			RX = 0;

			#1100ns;
			KEY[0] = 1;
			//#20us;
			//KEY[1] = 0;
			//#5us;
			//KEY[1] = 1;
			#300us;
			$stop;
	end
	initial forever #10ns CLK50 = ~CLK50;
	

endmodule

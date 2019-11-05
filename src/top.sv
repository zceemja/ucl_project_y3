/*
 * This is top level entity file.
 * It includes all cpu external modules like UART
 * and SDRAM controller. 
*/
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
	
	assign rst = ~KEY[0];
	
	/* Clocks */
	wire mclk; // Master clock 		1MHz 		(for cpu)
	wire fclk; // Fast clock 		100MHz 		(for sdram)
	wire aclk; // Auxiliary clock 	32,768kHz 	(for timers)
	
	pll_clk pll_clk0 (
			.inclk0(CLK50),
			.areset(rst),
			.c0(fclk),
			.c1(mclk),
			.c2(aclk)
	);

	wire [23:0]	ram_addr;
    wire [15:0] ram_wr_data;
    wire [15:0] ram_rd_data;
    wire 		ram_wr_en;
    wire		ram_rd_en;
    wire  		ram_busy;
	wire  		ram_rd_ready;
	wire  		ram_rd_ack;

	sdram_block sdram0(
		.mclk(mclk), 
		.fclk(fclk), 
		.rst(rst), 
		.ram_addr(ram_addr),
		.ram_wr_data(ram_wr_data),
		.ram_rd_data(ram_rd_data),
		.ram_wr_en(ram_wr_en),
		.ram_rd_en(ram_rd_en),
		.ram_busy(ram_busy),
		.ram_rd_ready(ram_rd_ready),
		.ram_rd_ack(ram_rd_ack),
		.DRAM_DQ(DRAM_DQ),	
		.DRAM_ADDR(DRAM_ADDR),	
		.DRAM_DQM(DRAM_DQM),	
		.DRAM_CLK(DRAM_CLK),	
		.DRAM_CKE(DRAM_CKE),	
		.DRAM_WE_N(DRAM_WE_N),	
		.DRAM_CAS_N(DRAM_CAS_N),
		.DRAM_RAS_N(DRAM_RAS_N),
		.DRAM_CS_N(DRAM_CS_N),	
		.DRAM_BA(DRAM_BA)	
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

	risc8_cpu cpu_block0(port0);

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
		.key1(~KEY[1])
	);

endmodule


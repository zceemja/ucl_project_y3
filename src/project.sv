interface processor_port(
	input clk, rst,

	// RAM
	output [23:0]	ram_addr,
	output [15:0] 	ram_wr_data,
	input  [15:0] 	ram_rd_data,
	output 			ram_wr_en,
	output			ram_rd_en,
	input			ram_busy,
	input			ram_rd_ready,
	input			ram_rd_ack,

	// COM
	output [7:0]	com_addr,
	output [7:0]	com_wr,
	input  [7:0]	com_rd,
	input  			com_interrupt
	);

endinterface

module com_block(
	input clk, rst,
	// Communication to processor
	input  wire [7:0]	addr,
	input  reg  [7:0]	in_data,
	output reg  [7:0]	out_data,
	output wire			interrupt,

	// IO
	output reg  [7:0]	leds,
	input  wire  [3:0]	switches,
	output wire			uart0_tx,
	input  wire			uart0_rx,
	input  wire			key1
);

	/* UART */
	reg [2:0] uart0_reg;
	reg uart0_transmit;
	reg [7:0] tx_byte, rx_byte;
	// Clock divide = 1e6 / (9600 * 4)
	uart#(.CLOCK_DIVIDE(26)) uart0(
			.clk(clk), 
			.rst(rst), 
			.rx(uart0_rx),
			.tx(uart0_tx),
			.tx_byte(tx_byte),
			.rx_byte(rx_byte),
			.received(uart0_reg[0]),
			.is_receiving(uart0_reg[1]),
			.is_transmitting(uart0_reg[2]),
			.transmit(uart0_transmit)
	);

	always_ff@(posedge clk) begin
		if(addr == 8'h06) leds <= in_data;
	end

	always_comb begin
		uart0_transmit = (addr == 8'h05) ? 1 : 0;
		tx_byte = in_data;
		case(addr)
			8'h04: out_data = {5'b0, uart0_reg};
			8'h05: out_data = {5'b0, uart0_reg};
			8'h07: out_data = {4'b0, switches};
			default: out_data = 0;
		endcase
	end
endmodule

module sdram_block(
	input mclk, fclk, rst,

	// SDRAM Control
	input [23:0]	ram_addr,
	input [15:0] 	ram_wr_data,
	output  [15:0] 	ram_rd_data,
	input 			ram_wr_en,
	input			ram_rd_en,
	output			ram_busy,
	output			ram_rd_ready,
	output			ram_rd_ack,
	

	// SDRAM I/O
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
	/* SDRAM */

	// 1 MHz side wires
	wire [39:0] wr_fifo;// Address 24-bit and 16-bit Data
	wire wr_enable;		// wr_enable ] <-> [ wr 	: wr_enable to push fifo
	wire wr_full;		// wr_full   ] <-> [ full 	: signal that we are full
	wire rd_enable;		// rd_enable - wr 			: rd_enable to push rd addr to fifo
	wire rdaddr_full;	// rdaddr_full - full 		: signal we cannot read more
	wire [15:0] rddo_fifo;
	wire ctrl_rd_ready;	// wr - rd_ready 			: push data from dram to fifo

	// 100MHz side wires
	wire [39:0] wro_fifo;
	wire ctrl_busy;       	// rd ] <-> [ busy 		: pop fifo when ctrl not busy
	wire ctrl_wr_enable;  	// empty_n - wr_enable 	: signal ctrl data is ready
	wire [23:0] rdao_fifo;
	wire ctrl_rd_enable;	// empty_n - rd_enable 	: signal ctrl addr ready
	wire [15:0] rddata_fifo;
	wire rd_ready;   		// rd_ready - empty_n 	: signal interface data ready
	wire rd_ack;     		// rd_ack - rd     		: pop fifo after data read

	wire busy;				// RAM is busy because RW FIFO is full
	assign busy = wr_full | rdaddr_full;


	fifo #(.BUS_WIDTH(40)) dram_wr_fifo (
	    .wr_clk        (mclk),
	    .rd_clk        (fclk),
	    .wr_data       (wr_fifo),
	    .rd_data       (wro_fifo),
	    .rd            (ctrl_busy),
	    .wr            (wr_enable),
	    .full          (wr_full),
	    .empty_n       (ctrl_wr_enable),
	    .rst_n         (rst)
	);
	
	fifo #(.BUS_WIDTH(24)) dram_rd_addr_fifo (
	    .wr_clk        (mclk),
	    .rd_clk        (fclk),
	    .wr_data       (wr_fifo[39:16]),
	    .rd_data       (rdao_fifo),
	    .rd            (ctrl_busy),
	    .wr            (rd_enable),
	    .full          (rdaddr_full),
	    .empty_n       (ctrl_rd_enable),
	    .rst_n         (rst)
	);
	
	fifo #(.BUS_WIDTH(16)) dram_rd_data_fifo (
	    .wr_clk        (fclk),
	    .rd_clk        (mclk),
	    .wr_data       (rddo_fifo),
	    .rd_data       (rddata_fifo),
	    .rd            (rd_ack),
	    .wr            (ctrl_rd_ready),
	    .empty_n       (rd_ready),
	    .rst_n         (rst)
	);
	
	// Setting SDRAM clock to 100MHz
	assign DRAM_CLK = fclk;

	sdram_controller sdram_control0 (
	    // HOST INTERFACE
	    .wr_addr       (wro_fifo[39:16]),
	    .wr_data       (wro_fifo[15:0]),
	    .wr_enable     (ctrl_wr_enable), 
	
	    .rd_addr       (rdao_fifo), 
	    .rd_data       (rddo_fifo),
	    .rd_ready      (ctrl_rd_ready),
	    .rd_enable     (ctrl_rd_enable),
	    
	    .busy          (ctrl_busy),
	    .rst_n         (rst),
	    .clk           (fclk),
	
	    // SDRAM SIDE
	    .addr          (DRAM_ADDR),
	    .bank_addr     (DRAM_BA),
	    .data          (DRAM_DQ),
	    .clock_enable  (DRAM_CKE),
	    .cs_n          (DRAM_CS_N),
	    .ras_n         (DRAM_RAS_N),
	    .cas_n         (DRAM_CAS_N),
	    .we_n          (DRAM_WE_N),
		.data_mask_low (DRAM_DQM[0]),
		.data_mask_high(DRAM_DQM[1])
	);

	// Assign inputs	
	assign wr_fifo[39:16] 	= ram_addr;
    assign wr_fifo[15:0] 	= ram_wr_data;
	assign wr_enable 		= ram_wr_en;
	assign rd_enable 		= ram_rd_en;
	
	// Assign outputs
	assign ram_rd_data 		= rddata_fifo;
 	assign ram_busy 		= busy;
	assign ram_rd_ready 	= rd_ready;
	assign ram_rd_ack 		= rd_ack;
 		
endmodule

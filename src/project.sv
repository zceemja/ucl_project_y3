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
	output reg			interrupt,

	// IO
	output reg  [7:0]	leds,
	input  wire [3:0]	switches,
	output wire			uart0_tx,
	input  wire			uart0_rx,
	input  wire			key1
);

	/* UART */
	reg [2:0] uart0_reg;
	reg uart0_recv;
	reg uart0_transmit;
	reg [7:0] tx_byte, rx_byte;
	// Clock divide = 1e6 / (9600 * 4)
	//uart#(.CLOCK_DIVIDE(1302)) uart0(
	uart#(.CLOCK_DIVIDE(26)) uart0(
			.clk(clk), 
			.rst(0), 
			.rx(uart0_rx),
			.tx(uart0_tx),
			.tx_byte(tx_byte),
			.rx_byte(rx_byte),
			.received(uart0_recv),
			`ifdef SYNTHESIS
			.is_receiving(uart0_reg[0]),
			.is_transmitting(uart0_reg[1]),
			`endif
			.transmit(uart0_transmit)
	);
	
	initial uart0_reg[1:0] = 2'b00;
	//reg [7:0] reset_str [7];
	//reg [2:0] reset_seq;
	//always_comb begin
	//		reset_str[0] = 8'h72;
	//		reset_str[1] = 8'h65;
	//		reset_str[2] = 8'h73;
	//		reset_str[3] = 8'h65;
	//		reset_str[4] = 8'h74;
	//		reset_str[5] = 8'h2e;
	//		reset_str[6] = 8'h10;
	//end
	
	reg interrupt_reg;
	assign interrupt = (key1 & interrupt_reg);
	always_ff@(posedge clk) begin
		if(rst) begin 
			//reset_seq <= 0;
			uart0_reg[2] <= 0;
			//interrupt <= 0;
			interrupt_reg <= 0;
			leds <= 'b0000_0000;
		end
		//else if(~uart0_reg[2] && reset_seq != 7) reset_seq <= reset_seq + 1;
		else begin
			case(addr)
				8'h03: uart0_reg[2] <= in_data[2]; 
				//8'h06: leds <= in_data;
			endcase
			if(~key1) interrupt_reg <= 1;
			if(interrupt) interrupt_reg <= 0;
			leds <= {5'b0, uart0_reg};
		end
	end

	always_comb begin
		//tx_byte = 8'h23;
		//uart0_transmit = 1;
		uart0_transmit = (addr == 8'h05) || (uart0_recv && uart0_reg[2]);
		tx_byte = (uart0_recv && uart0_reg[2]) ? rx_byte : in_data;
		//tx_byte = in_data;
		case(addr)
			8'h03: out_data = in_data; 				// Set uart0 flags
			8'h04: out_data = {5'b0, uart0_reg};  	// Read uart0 flags
			8'h05: out_data = in_data;  			// Write to uart0
			8'h07: out_data = leds;					// Read current LEDs
			8'h08: out_data = {4'b0, switches};		// Read DIP
			default: out_data = 0;
		endcase
	end
endmodule


module sdram_block(
	input mclk, fclk, rst_n,

	// SDRAM Control
	input [23:0]	ram_addr,
	input [15:0] 	ram_wr_data,
	output reg [15:0] 	ram_rd_data,
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
	//wire [39:0] wr_fifo;// Address 24-bit and 16-bit Data
	//wire wr_enable;		// wr_enable ] <-> [ wr 	: wr_enable to push fifo
	//wire wr_full;		// wr_full   ] <-> [ full 	: signal that we are full
	//wire rd_enable;		// rd_enable - wr 			: rd_enable to push rd addr to fifo
	//wire rdaddr_full;	// rdaddr_full - full 		: signal we cannot read more
	//wire [15:0] rddo_fifo;
	//wire ctrl_rd_ready;	// wr - rd_ready 			: push data from dram to fifo

	//// 100MHz side wires
	//wire [39:0] wro_fifo;
	//wire ctrl_busy;       	// rd ] <-> [ busy 		: pop fifo when ctrl not busy
	//wire ctrl_wr_enable;  	// empty_n - wr_enable 	: signal ctrl data is ready
	//wire [23:0] rdao_fifo;
	//wire ctrl_rd_enable;	// empty_n - rd_enable 	: signal ctrl addr ready
	//wire [15:0] rddata_fifo;
	//wire rd_ready;   		// rd_ready - empty_n 	: signal interface data ready
	//wire rd_ack;     		// rd_ack - rd     		: pop fifo after data read

	//wire busy;				// RAM is busy because RW FIFO is full
	//assign busy = wr_full | rdaddr_full;


	//fifo #(.BUS_WIDTH(40)) dram_wr_fifo (
	//    .wr_clk        (mclk),
	//    .rd_clk        (fclk),
	//    .wr_data       (wr_fifo),
	//    .rd_data       (wro_fifo),
	//    .rd            (ctrl_busy),
	//    .wr            (wr_enable),
	//    .full          (wr_full),
	//    .empty_n       (ctrl_wr_enable),
	//    .rst_n         (rst_n)
	//);
	//
	//fifo #(.BUS_WIDTH(24)) dram_rd_addr_fifo (
	//    .wr_clk        (mclk),
	//    .rd_clk        (fclk),
	//    .wr_data       (wr_fifo[39:16]),
	//    .rd_data       (rdao_fifo),
	//    .rd            (ctrl_busy),
	//    .wr            (rd_enable),
	//    .full          (rdaddr_full),
	//    .empty_n       (ctrl_rd_enable),
	//    .rst_n         (rst_n)
	//);
	//
	//fifo #(.BUS_WIDTH(16)) dram_rd_data_fifo (
	//    .wr_clk        (fclk),
	//    .rd_clk        (mclk),
	//    .wr_data       (rddo_fifo),
	//    .rd_data       (rddata_fifo),
	//    .rd            (rd_ack),
	//    .wr            (ctrl_rd_ready),
	//    .empty_n       (rd_ready),
	//    .rst_n         (rst_n)
	//);
	
	reg busy, rd_ready, rd_en, wr_en;
	reg [1:0] state;
	reg [15:0] wr_data, rd_data, rd_data_reg;
	always_ff@(posedge fclk) begin
		if(~rst_n) begin
			state <= 0;
			wr_en <= 0;
			rd_en <= 0;
		end
		else begin
			if(rd_ready) ram_rd_data <= rd_data;
			if(mclk & (state == 0)) state <= 1; 
			//if(rd_ready) rd_data_reg <= rd_data;
			else if(state == 1 && ~busy) begin
				wr_data <= ram_wr_data;
				wr_en <= ram_wr_en;
				rd_en <= ram_rd_en;
				state <= (ram_wr_en | ram_rd_en) ? 2 : 1;
			end else if (state == 2) begin
				wr_en <= 0;
				rd_en <= 0;
				state <= 3;
			end
			if(~mclk & (state == 3))  state <= 0;
		end

	end
	
	//always_ff@(posedge mclk) begin
		//state <= 0;
		//ram_rd_data <= rd_data_reg;
	//end

	//assign ram_rd_data = rd_data_reg;

	// Setting SDRAM clock to 100MHz
	assign DRAM_CLK = fclk;
	
	`ifdef SYNTHESIS
	sdram_controller sdram_control0 (
	    // HOST INTERFACE
	    .wr_addr       (ram_addr),
	    .wr_data       (wr_data),
	    .wr_enable     (wr_en), 
	
	    .rd_addr       (ram_addr), 
	    .rd_data       (rd_data),
	    .rd_ready      (rd_ready),
	    .rd_enable     (rd_en),
	    
	    .busy          (busy),
	    .rst_n         (rst_n),
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
	`else
	reg [15:0] rd_data0;
	memory#(.WIDTH(16), .LENGTH(2**8)) mock_sdram0(
		.clk(fclk),
		.wr_en(wr_en),
		.rd_en(rd_en),
		.wd(wr_data),
		.rd(rd_data0),
		.addr(ram_addr[7:0])
	);
	always_ff@(posedge fclk) begin
		if(~rst_n) busy <= 0;
		else begin
			rd_data <= rd_data0;
			rd_ready <= rd_en;
			busy <= rd_en | wr_en;
		end
	end
	`endif
	//// Assign inputs	
	//assign wr_fifo[39:16] 	= ram_addr;
    //assign wr_fifo[15:0] 	= ram_wr_data;
	//assign wr_enable 		= ram_wr_en;
	//assign rd_enable 		= ram_rd_en;
	//
	//// Assign outputs
	//assign ram_rd_data 		= rddata_fifo;
 	//assign ram_busy 		= busy;
	//assign ram_rd_ready 	= rd_ready;
	//assign ram_rd_ack 		= rd_ack;
 		
endmodule

/**
 * Testbench for sdram_controller modules, simulates:
 *  - Iinit
 *  - Write
 *  - Read
 */
module sdram_controller_tb();

    //vlog_tb_utils vlog_tb_utils0();

    /* HOST CONTROLLS */
    reg [23:0]  haddr;
    reg [15:0]  data_input;
    wire [15:0] data_output;
    wire busy; 
    reg rd_enable, wr_enable, rst_n, clk;

    /* SDRAM SIDE */
    wire [12:0] addr;
    wire [1:0] bank_addr;
    wire [15:0] data; 
    wire clock_enable, cs_n, ras_n, cas_n, we_n, data_mask_low, data_mask_high;

    reg [15:0] data_r;

    assign data = data_r;


    initial 
    begin
        haddr = 24'd0;
        data_input = 16'd0;
        rd_enable = 1'b0;
        wr_enable = 1'b0;
        rst_n = 1'b1;
        clk = 1'b0;
        data_r = 16'hzzzz;
    end

    always
        #1 clk <= ~clk;
      
    initial
    begin
      #3 rst_n = 1'b0;
      #3 rst_n = 1'b1;
      
      #120 haddr = 24'hfedbed;
      data_input = 16'd3333;
      
      #3 wr_enable = 1'b1;
      #6 wr_enable = 1'b0;
      haddr = 24'd0;
      data_input = 16'd0;  
      
      #120 haddr = 24'hbedfed;
      #3 rd_enable = 1'b1;
      #6 rd_enable = 1'b0;
      haddr = 24'd0;
      
      #8 data_r = 16'hbbbb;
      #2 data_r = 16'hzzzz;
      
      #1000 $finish;
    end


sdram_controller sdram_controlleri (
    /* HOST INTERFACE */
    .wr_addr(haddr), 
    .wr_data(data_input),
    .rd_data(data_output),
    .busy(busy), .rd_enable(rd_enable), .wr_enable(wr_enable), .rst_n(rst_n), .clk(clk),

    /* SDRAM SIDE */
    .addr(addr), .bank_addr(bank_addr), .data(data), .clock_enable(clock_enable), .cs_n(cs_n), .ras_n(ras_n), .cas_n(cas_n), .we_n(we_n), .data_mask_low(data_mask_low), .data_mask_high(data_mask_high)
);

endmodule

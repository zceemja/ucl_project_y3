import project_pkg::word;

module io_unit(
	input  logic clk, rx,
	input  logic [3:0]switches,
	input  logic [1:0]keys,
	output logic tx,
	output logic [7:0]leds
	);
	
	logic transmit, received, is_receiving, is_transmitting, recv_error;
	logic [7:0] tx_byte, rx_byte;
	assign leds[0] = received;
	assign leds[1] = is_receiving;
	assign leds[2] = is_transmitting;
	//assign leds[3] = recv_error;
	//assign leds[6] = rx;
	//assign leds[7] = tx;
	logic clk_slow;

	clk_div clk_div12(clk, rst, clk_slow);	
	assign rst = ~keys[0];
	//assign transmit = keys[1];
	//assign tx_byte = rx_byte;

	uart uart0(clk, rst, rx, tx, transmit, tx_byte, received, rx_byte, is_receiving, is_transmitting, );

	//assign clk = keys[1];
	logic mem_wr;
	word pc, instr, imm, mem_addr, mem_data, mem_rd_data;
	word ext_rd_data, rd_data;
	cpu CPU(clk_slow, rst, instr, imm, pc, mem_addr, mem_wr, mem_data, rd_data);
	// Instruction memory
	instr_mem #("/home/min/devel/fpga/ucl_project_y3/memory/test.mem") IMEM(pc, instr, imm);
	// System memory
	memory RAM(clk, mem_wr, mem_addr, mem_data, mem_rd_data);
	
	assign ext_rd_data = '{0,0,0,0, 0,0,0,is_transmitting};
	assign rd_data = (mem_addr == 8'hFF) ? ext_rd_data : mem_rd_data;

	always_ff@(posedge clk_slow) begin
			if(mem_wr & mem_addr == 8'hFF) begin
				tx_byte <= mem_data;
				transmit <= 1; 
			end
			else begin
				transmit <= 0; 
			end
	end

endmodule

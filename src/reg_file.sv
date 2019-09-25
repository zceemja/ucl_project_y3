module reg_file(clk, rd_addr1, rd_addr2, rd_data1, rd_data2, wr_addr, wr_data, wr_en);
	parameter    WORD		  = 8;
	parameter    REG_SIZE  = 4;
	localparam   ADDR_SIZE = $clog2(REG_SIZE);
	
	input logic  clk, wr_en;
	input 		 [ADDR_SIZE-1:0] rd_addr1;
	input 		 [ADDR_SIZE-1:0] rd_addr2;
	input 		 [ADDR_SIZE-1:0] wr_addr;
	input 		 [WORD-1:0]		  wr_data;
	output logic [WORD-1:0]      rd_data1;
	output logic [WORD-1:0]      rd_data2;
	
	logic        [WORD-1:0]	registry [ADDR_SIZE-1:0];
	
	always_ff@(posedge clk) begin
		rd_data1 <= registry[rd_addr1];
		rd_data2 <= registry[rd_addr2];
		if(wr_en) registry[wr_addr] <= wr_data;
	end
	
endmodule


module reg_file_tb;
	logic clk, wr_en;
	logic [1:0]rd_addr1;
	logic [1:0]rd_addr2;
	logic [7:0]rd_data1;
	logic [7:0]rd_data2;
	logic [1:0]wr_addr;
	logic [7:0]wr_data;
	
	reg_file test_reg_file(clk, rd_addr1, rd_addr2, rd_data1, rd_data2, wr_addr, wr_data, wr_en);
	
	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end
	
	initial begin
		rd_addr1 = 2'b00;
		rd_addr2 = 2'b01;
		wr_addr	= 2'b00;
		wr_en 	= 0;
		wr_data	= 8'hFF;
		#10ns wr_en = 1;
		#5ns wr_en = 0;
	end
	
endmodule


module reg_file(clk, rd_addr1, rd_addr2, rd_data1, rd_data2, wr_addr, wr_data, wr_en);
	input logic  clk, wr_en;
	input regAddr 	rd_addr1;
	input regAddr 	rd_addr2;
	input regAddr 	wr_addr;
	input regAddr 	wr_data;
	output word 	rd_data1;
	output word 	rd_data2;
	
	logic [word_size-1:0] registry [reg_size-1:0];
	
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
		#10ns wr_addr =  2'b01;
		#10ns wr_en = 0;
	end
	
endmodule

module reg_file(clk, rst, rd_addr1, rd_addr2, rd_data1, rd_data2, wr_addr, wr_data, wr_en);
	parameter WIDTH=8, LENGTH=4;
	localparam ADDR_WIDTH = $clog2(LENGTH);

	input  clk, rst, wr_en;
	input  [ADDR_WIDTH-1:0] rd_addr1, rd_addr2, wr_addr;
	input  [WIDTH-1:0] wr_data;
	output [WIDTH-1:0] rd_data1;
	output [WIDTH-1:0] rd_data2;

	
	
	logic [WIDTH-1:0] registry [LENGTH-1:0];
	
	always_ff@(posedge clk) begin
	  	if(rst) for(int i=0;i<LENGTH;i++) registry[i] <= '0;
		else if(wr_en) registry[wr_addr] <= wr_data;
	end
	
	assign rd_data1 = registry[rd_addr1];
	assign rd_data2 = registry[rd_addr2];
	
endmodule

module reg_file_tb;
	logic clk, rst, wr_en;
	logic [1:0]rd_addr1;
	logic [1:0]rd_addr2;
	logic [1:0]wr_addr;
	logic [7:0]rd_data1;
	logic [7:0]rd_data2;
	logic [7:0]wr_data;
	
	reg_file test_reg_file(clk, rst, rd_addr1, rd_addr2, rd_data1, rd_data2, wr_addr, wr_data, wr_en);
	
	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end
	
	initial begin
		rd_addr1 = 2'b00;
		rd_addr2 = 2'b00;
		wr_addr	= 0;
		rst = 1;
		wr_en = 1;
		wr_data = 8'hAA;
		#10ns 
		rst=0;
		wr_data = 8'hBB;
		wr_addr = 1;
		#10ns
		wr_data = 8'hCC;
		wr_addr = 2;
		#10ns
		wr_data = 8'hDD;
		wr_addr = 3;
		#10ns
		wr_en = 0;
		wr_data = 0;
		rd_addr1 = 3;
		rd_addr2 = 0;
		#10ns
		assert(rd_data1==8'hDD);
		assert(rd_data2==8'hAA);
		rd_addr1 = 2;
		rd_addr2 = 1;
		#10ns
		assert(rd_data1==8'hCC);
		assert(rd_data2==8'hBB);
		$stop;
	end
	
endmodule



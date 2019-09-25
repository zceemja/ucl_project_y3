module reg_file(clk, rd_addr1, rd_addr2, rd_data1, rd_data2, wr_addr, wr_data, wr_en);
	parameter    WORD		  = 8;
	parameter    ADDR_SIZE = 2;
	
	typedef logic [WORD-1:0] word;
	typedef logic [ADDR_SIZE-1:0] regAddr;
	
	input logic  clk, wr_en;
	input regAddr 	rd_addr1;
	input regAddr 	rd_addr2;
	input regAddr 	wr_addr;
	input regAddr 	wr_data;
	output word 	rd_data1;
	output word 	rd_data2;
	
	logic        [WORD-1:0]	registry [ADDR_SIZE-1:0];
	
	always_ff@(posedge clk) begin
		rd_data1 <= registry[rd_addr1];
		rd_data2 <= registry[rd_addr2];
		if(wr_en) registry[wr_addr] <= wr_data;
	end
	
endmodule

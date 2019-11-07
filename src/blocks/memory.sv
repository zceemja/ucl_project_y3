module memory(clk, wr_en, rd_en, addr, wd, rd);

	parameter WIDTH=8, LENGTH=256;	
	parameter ADDR_WIDTH=$clog2(LENGTH);
	
	input  	logic clk, wr_en, rd_en;
	input 	[WIDTH-1:0]	wd;
	input 	[ADDR_WIDTH-1:0] addr;
	output 	[WIDTH-1:0]	rd;
	
	logic [WIDTH-1:0]memory[LENGTH-1:0];
	assign rd = (rd_en) ? memory[addr] : 'x;
	always_ff@(posedge clk) if(wr_en) memory[addr] <= wd;
	
endmodule

module memory_tb;
	logic clk, wr_en, rd_en;
	logic [7:0] addr, wr_data, rd_data;
	memory MEM(clk, wr_en, rd_en, addr, wr_data, rd_data);
	localparam csize = 10;

	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end
	
	initial begin
		addr = '0;
		wr_en = 1;
		rd_en = 0;
		for(int i=0;i<csize;i++) begin
			wr_data = i;
			addr = i;
			#10ns;
		end
		wr_en = 0;
		rd_en = 1;
		wr_data = '0;
		for(int i=0;i<csize;i++) begin
			#10ns;
			addr = i;
			assert(rd_data == i);
		end
		$stop;
	end

endmodule


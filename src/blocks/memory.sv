module memory(clk, we, a, wd, rd);

	parameter WIDTH=8, LENGTH=256;	
	localparam ADDR_WIDTH = $clog2(LENGTH);
	
	input  	clk, we;
	input 	[WIDTH-1:0]	wd;
	input 	[ADDR_WIDTH-1:0] a;
	output 	[WIDTH-1:0]	rd;
	
	logic [WIDTH-1:0]memory[LENGTH-1:0];
	assign rd = memory[a];
	
	always_ff@(posedge clk) if(we) memory[a] <= wd;
	
	
endmodule

module memory_tb;
	logic clk, wr_en;
	word addr, wr_data, rd_data;
	memory MEM(clk, wr_en, addr, wr_data, rd_data);
	localparam csize = 10;

	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end
	
	initial begin
		addr = 0;
		wr_en = 1;
		for(int i=0;i<csize;i++) begin
			wr_data = i;
			addr = i;
			#10ns;
		end
		wr_en = 0;
		wr_data = 0;
		for(int i=0;i<csize;i++) begin
			#10ns;
			addr = i;
			assert(rd_data == i);
		end
		$stop;
	end

endmodule


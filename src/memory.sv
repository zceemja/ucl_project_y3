module memory(clk, addr, rd_data, wr_data, wr_en);
	parameter WORD=8, MEM_SIZE=2**WORD;
	input clk, wr_en;
	input [WORD-1:0]addr;
	input [WORD-1:0]wr_data;
	output logic [WORD-1:0]rd_data;
	
	logic [WORD-1:0]memory[MEM_SIZE-1:0];
	
	always_ff@(posedge clk) begin
		if(wr_en) memory[addr] <= wr_data;
		else rd_data <= memory[addr];
	end
	
endmodule

//import project_pkg::*;

module memory(clk, addr, rd_data, wr_data, wr_en);
	parameter WORD=8, SIZE=2**WORD;
	
	typedef logic [WORD-1:0] word;
	input clk, wr_en;
	input word addr;
	input word wr_data;
	output word rd_data;
	
	logic [WORD-1:0]memory[SIZE-1:0];
	
	always_ff@(posedge clk) begin
		if(wr_en) memory[addr] <= wr_data;
		else rd_data <= memory[addr];
	end
	
endmodule

//module instr_rom_wr(clk, addr, instr, wr_en, wr_data);
module rom(addr, q);
	parameter PROGRAM="";
	parameter WIDTH=8, SIZE=1024;
	parameter ADDR_WIDTH = $clog2(SIZE);
	
	//input  reg 	clk, wr_en;
	//input reg [WIDTH-1:0] wr_data;
	input  wire [ADDR_WIDTH-1:0]   addr;
	output  reg  [WIDTH-1:0] q;
	
	logic [WIDTH-1:0] rom [ADDR_WIDTH-1:0];
	initial $readmemh(PROGRAM, rom);
	//always_ff@(posedge clk) if(wr) rom[addr] <= instr; 	

	always_comb q[WIDTH-1:0] = rom[addr];
endmodule


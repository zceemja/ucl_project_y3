import cpu_pkg::*;

module instr_mem(clk, addr, instr, imm);
	parameter WORD=8, SIZE=2**WORD;
	input clk;
	input  word 	addr;
	output word		imm;
	output e_instr instr;
	
	logic [WORD-1:0] rom [SIZE-1:0];
	
	always_comb begin
		rom[0] = {NOP, RegA, RegA};  // Do nothing
		rom[1] = {ADDI, RegA, RegA}; // Set $ra = 0xFF
		rom[2] = 8'hFF;
		rom[3] = {WO, RegA, RegA};   // Show $ra
	end
	
	always_ff @(posedge clk) begin
		instr <= e_instr'(rom[addr]);
		imm <= rom[addr + 1];
	end

endmodule

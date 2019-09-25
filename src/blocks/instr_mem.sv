//import cpu_pkg::*;
import project_pkg::*;

module instr_mem(addr, instr, imm);
	input  word addr;
	output word	imm;
	output word	instr;
	
	logic [word_length-1:0] rom [rom_length-1:0];
	
	always_comb begin
		rom[0] = {NOP, RegA, RegA};  // Do nothing
		rom[1] = {ADDI, RegA, RegA}; // Set $ra = 0xFF
		rom[2] = 8'hFF;
		rom[3] = {WO, RegA, RegA};   // Show $ra
	end
	
	always_comb begin
		instr = rom[addr];
		imm = rom[addr + 1];
	end

endmodule

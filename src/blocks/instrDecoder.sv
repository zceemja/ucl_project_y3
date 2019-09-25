//import project_pkg::*;

module instDecoder(instr, opcode, rs, rt);
	input  logic [7:0]instr;
	output logic [2:0]opcode;
	output logic [1:0]rs;
	output logic [1:0]rt;
	
	assign opcode = instr[7:4];
	assign rs = instr[3:2];
	assign rt = instr[1:0];
	
endmodule
	
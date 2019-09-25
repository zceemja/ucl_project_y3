package alu_pkg;

	typedef enum logic [2:0] { 
		ALU_ADD=3'b000,
		ALU_SUB=3'b001,
		ALU_AND=3'b010,
		ALU_OR =3'b011,
		ALU_SLT=3'b100,
		ALU_NOT=3'b101,
		ALU___0=3'b110,
		ALU_NOP=3'b111
	} e_alu_op;
	
endpackage

module alu(op, srcA, srcB, result, zero);	
	input  e_alu_op 	op;
	input  word 		srcA;
	input  word			srcB;
	output word			result;
	output logic		zero;
	
	
	always_comb begin
	case(op)
		ALU_ADD: result = srcA + srcB;
		ALU_SUB: result = srcA - srcB;
		ALU_AND: result = srcA & srcB;
		ALU_OR : result = srcA | srcB;
//		ALU_SLT: result = srcA < srcB; // Not in use
		ALU_NOT: result = ~srcB;
		ALU_NOP: result = srcA;
		default: result = '0;
	endcase
	
	zero = result == '0;
	end
	
endmodule

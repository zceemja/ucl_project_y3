import project_pkg::*;

module alu(op, srcA, srcB, result, zero);	
	
	input  e_alu_op 	op;
	input  word			srcA;
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

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
		ALU_SLT: result = srcA > srcB;
		ALU_NOT: result = ~srcB;
		ALU_NOP: result = srcA;
		default: result = 0;
	endcase
	end
	assign zero = result == 0;
	
endmodule

module alu_tb;
	e_alu_op op;
	word srcA, srcB, result;
	logic zero;
	
	alu ALU(op, srcA, srcB, result, zero);
	
	initial begin
		op = ALU_NOP;
		srcA = 120;
		srcB = 100;
		#5ns;
		assert(result == srcA);
		op = ALU_ADD;
		#5ns;
		assert(result == 220);
		op = ALU_SUB;
		#5ns;
		assert(result == 20);
		op = ALU_AND;
		// 01100100 & 01111000 = 01100000
		#5ns;
		assert(result == 96);
		op = ALU_OR;
		// 01100100 | 01111000 = 01111100
		#5ns;
		assert(result == 124);
		op = ALU_SLT;
		#5ns;
		assert(result == 1);
		srcB = 140;
		#5ns;
		assert(result == 0);
		assert(zero == 1);
		$stop;
	end

endmodule

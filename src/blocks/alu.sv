import project_pkg::*;

module alu(op, srcA, srcB, result, zero);	
	
	input  e_alu_op 	op;
	input  word			srcA;
	input  word			srcB;
	output word			result;
	output logic		zero;
	
	logic [2:0]xop;
	logic [2:0]shamt;
	
	always_comb begin
	xop = srcB[7:5];
	shamt = srcB[2:0];
	case(op)
		ALU_CPY: result = srcB;
		ALU_ADD: result = srcA + srcB;
		ALU_SUB: result = srcA - srcB;
		ALU_AND: result = srcA & srcB;
		ALU_OR : result = srcA | srcB;
		ALU_XOR: result = srcA ^ srcB;
		ALU_GT : result = srcA > srcB;
		ALU_EXT: begin
				case(xop)
						3'b000: result = srcA << shamt;
						3'b001: result = srcA >> shamt;
						3'b010: result = srcA >>> shamt;
						default: result = srcA;
				endcase
		end
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
		op = ALU_CPY;
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
		
		op = ALU_XOR;
		#5ns;
		assert(result == 28);
		
		op = ALU_GT;
		#5ns;
		assert(result == 1);
		
		srcB = 140;
		#5ns;
		assert(result == 0);
		assert(zero == 1);
		
		op = ALU_EXT;
		srcB = 8'b000xx000;
		#5ns;
		assert(result == srcA);
		
		srcB = 8'b000xx001;
		#5ns;
		assert(result == 240);
		
		srcB = 8'b001xx001;
		#5ns;
		assert(result == 60);
		
		srcB = 8'b001xx010;
		#5ns;
		assert(result == 30);
		
		srcB = 8'b010xx100;
		#5ns;
		// 01111000 >>> 4 = 10000111
		assert(result == 71);
		$stop;
	end

endmodule

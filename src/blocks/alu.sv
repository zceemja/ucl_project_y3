package alu_pkg;

	typedef enum logic [3:0] {
		 ALU_ADD = 4'd0, 
		 ALU_SUB = 4'd1,
		 ALU_AND = 4'd2,
		 ALU_OR  = 4'd3,
		 ALU_XOR = 4'd4,
		 ALU_NAND= 4'd5,
		 ALU_NOR = 4'd6,
		 ALU_XNOR= 4'd7,
		 ALU_SL  = 4'd8,
		 ALU_SR  = 4'd9,
		 ALU_ROR = 4'd10,
		 ALU_ROL = 4'd11,
		 ALU_MUL = 4'd12,
		 ALU_DIV = 4'd13,
		 ALU_MOD = 4'd14
	} e_alu_op;
	

endpackage

import alu_pkg::*;

module alu(
	srcA, srcB, result, op, cin, sign, zero, cout, gt, equal, overflow
);
	parameter WORD=8;
	localparam WSIZE=$clog2(WORD);

	input e_alu_op 			op;
	input logic 			cin, sign;
	input logic [WORD-1:0] 	srcA, srcB;
	
	output logic 			zero, cout, gt, equal, overflow;
	output logic [WORD-1:0] result;
	
	logic [WSIZE-1:0] shmt;
	assign shmt = srcB[WSIZE-1:0];
	
	// FIXME: Seems like there's a bug with ModelSim or Verilog
	// Object must be signed to do arithmetic shift right
	// casting $signed does not work. Tho folloing passes:
 	// assert(8'sb1000_0100 >>> 2 == 8'sb1110_0001);
	reg signed [WORD-1:0] signedA, sr;
	assign signedA = srcA;
	assign sr = signedA >>> shmt;

	always_comb begin
	case(op)
		ALU_ADD: {cout, result} = (srcA + cin) + srcB;
		ALU_SUB: {cout, result} = (srcA + cin) - srcB;
		ALU_AND: result = srcA & srcB;
		ALU_OR : result = srcA | srcB;
		ALU_XOR: result = srcA ^ srcB;
		ALU_NAND: result = ~(srcA & srcB);
		ALU_NOR : result = ~(srcA | srcB);
		ALU_XNOR: result = ~(srcA ^ srcB);
		ALU_SL: result = srcA << shmt;
		ALU_SR: result = (sign) ? sr : srcA >> shmt;
		ALU_ROL: result = {srcA[0], srcA[WORD-1:1]};
		ALU_ROR: result = {srcA[WORD-2:0], srcA[WORD-1]};
		ALU_MUL: result = srcA * srcB;
		ALU_DIV: result = srcA / srcB;
		ALU_MOD: result = srcA % srcB;
		default: result = 0;
	endcase
	end

	assign zero = result == 0;
	assign equal = srcA == srcB;
	assign gt = srcA > srcB;

endmodule

module alu_tb;
	e_alu_op op;
	logic [7:0]srcA, srcB, result;
	logic overflow, zero, cin, cout, gt, equal, sign;
	
	alu test_alu(
		.op(op),
		.srcA(srcA), 
		.srcB(srcB),
		.result(result),
		.zero(zero),
		.cin(cin),
		.cout(cout),
		.gt(gt),
		.equal(equal),
		.sign(sign),
		.overflow(overflow)
	);

	task test;
		input e_alu_op t_op;
		input [7:0] t_a, t_b, t_e;
		begin
			op = t_op;
			srcA = t_a;
			srcB = t_b;
			#1
			$write("ALU Test: %d %8s %d = %d ", 
				(sign) ? $signed(t_a) : t_a,
				op.name, 
				(sign) ? $signed(t_b) : t_b,
				(sign) ? $signed(result) : result
			);
			if (result == t_e) $display("(correct)");
			else $display("(expected %d)", t_e); 
			assert(result == t_e);	
		end		
	endtask
	
	task testb;
		input e_alu_op t_op;
		input [7:0] t_a, t_b, t_e;
		begin
			op = t_op;
			srcA = t_a;
			srcB = t_b;
			#1
			$write("ALU Test: %b %8s %b = %b ", t_a, op.name, t_b, result);
			if (result == t_e) $display("(correct)");
			else $display("(expected %b)", t_e); 
			assert(result == t_e);	
		end		
	endtask

	initial begin
		sign = 0;
		cin = 0;
		test(ALU_ADD, 120, 100, 220);
		test(ALU_SUB, 120, 100, 20);
		testb(ALU_AND, 120, 100, 96);
		testb(ALU_NAND, 100, 120, -97);
		testb(ALU_OR, 100, 120, 124);
		testb(ALU_NOR, 100, 120, -125);
		testb(ALU_XOR, 100, 120, 28);
		testb(ALU_XNOR, 100, 120, -29);
		testb(ALU_SL, 8'b1111_0111, 2, 8'b1101_1100);
		testb(ALU_SR, 8'b1110_1111, 2, 8'b0011_1011);
		sign = 1;
		$display("ALU Settings: sign = 1");
		
		testb(ALU_SR, 8'b1000_0100, 2, 8'b1110_0001);
		testb(ALU_SR, 8'b0000_0100, 2, 8'b0000_0001);
		test(ALU_ADD, -10, 20, 10);
		test(ALU_SUB, -10, -20, 10);
		
		testb(ALU_ROR, 8'b1100_0000, 0, 8'b1000_0001);
		testb(ALU_ROL, 8'b0000_0011, 0, 8'b1000_0001);
		test(ALU_MUL, 5, 8, 40);
		test(ALU_DIV, 64, 4, 16);
		test(ALU_DIV, 65, 4, 16);
		test(ALU_MOD, 66, 4, 2);
		test(ALU_MOD, 65, 4, 1);
		test(ALU_MOD, 64, 4, 0);
		$stop;
	end

endmodule

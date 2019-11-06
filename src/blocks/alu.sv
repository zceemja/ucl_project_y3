package alu_pkg;

	typedef enum logic [3:0] {
		 ALU_NONE= 4'bxxxx, 
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
		 ALU_RA  = 4'd10,
		 ALU_RAS = 4'd11,
		 ALU_MUL = 4'd12,
		 ALU_DIV = 4'd13,
		 ALU_MOD = 4'd14
	} e_alu_op;
	

endpackage

import alu_pkg::*;

module alu(
	a, b, r, r_high, op, cin, sign, zero, cout, gt, eq, overflow, r_high_en
);
	parameter WORD=8;
	localparam WSIZE=$clog2(WORD);

	input e_alu_op 			op;
	input logic 			cin, sign;
	input logic [WORD-1:0] 	a, b;
	
	output logic 			zero, cout, gt, eq, overflow, r_high_en;
	output logic [WORD-1:0] r, r_high;
	
	logic [WSIZE-1:0] shmt;
	assign shmt = b[WSIZE-1:0];
	
	// FIXME: Seems like there's a bug with ModelSim or Verilog
	// Object must be signed to do arithmetic shift right
	// casting $signed does not work. Tho folloing passes:
 	// assert(8'sb1000_0100 >>> 2 == 8'sb1110_0001);
	reg signed [WORD-1:0] signedA, sr;
	assign signedA = a;
	assign sr = signedA >>> shmt;
	
	logic arithmeticOp, coutF;
	assign arithmeticOp = (op == ALU_ADD || op == ALU_SUB || op == ALU_MUL || op == ALU_DIV);

	// Overflow/Underflow flag	
	logic [1:0] overLSB;
	logic overFlag;
	//assign overLSB = {a[WORD-1:WORD-1], b[WORD-1:WORD-1], r[WORD-1:WORD-1]};	
	assign overFlag = (overLSB == 3'b110 || overLSB == 3'b001) ? 1 : 0;
	assign overflow = sign && arithmeticOp ? overFlag : 0;	
	
	// Carry out flag
	logic cout0, cout1;
	assign cout = (op == ALU_ADD || op == ALU_SUB) && ~sign ? coutF : 0;
	assign coutF = (op == ALU_ADD) ? cout0 : cout1;

	logic [WORD-1:0] radd, rsub, r_low;
	logic [WORD*2-1:0] rmul, rdiv;
	assign {radd,cout0} = a + b + cin;
	assign {rsub,cout1} = a - b - cin;
	assign rmul = a * b;
	assign rdiv = {a/b,a%b};
  	assign r_high = (op == ALU_MUL) ? rmul[15:8] : rdiv[15:8];
	assign r_high_en = (op == ALU_MUL || op == ALU_DIV);

	always_comb begin
	case(op)
		ALU_ADD:  r = radd;
		ALU_SUB:  r = rsub;
		ALU_AND:  r = a & b;
		ALU_OR :  r = a | b;
		ALU_XOR:  r = a ^ b;
		ALU_NAND: r = ~(a & b);
		ALU_NOR : r = ~(a | b);
		ALU_XNOR: r = ~(a ^ b);
		ALU_SL:   r = a << shmt;
		ALU_SR:   r = (sign) ? sr : a >> shmt;
		ALU_RA:   r = {a[0], a[WORD-1:1]};
		ALU_RAS:  r = {a[WORD-2:0], a[WORD-1]};
		ALU_MUL:  r = rmul[WORD*2-1:WORD];
		ALU_DIV:  r = rdiv[WORD*2-1:WORD];
		ALU_MOD:  r = rdiv[WORD-1:0];
		default:  r = 0;
	endcase
	end

	assign zero = r == 0;
	assign eq = a == b;
	assign gt = a > b;

endmodule

`timescale 1ns / 1ns
module alu_tb;
	e_alu_op op;
	reg [7:0]a, b, r;
	logic overflow, zero, cin, cout, gt, eq, sign;
	
	
	alu test_alu(
		.op(op),
		.a(a), 
		.b(b),
		.r(r),
		.zero(zero),
		.cin(cin),
		.cout(cout),
		.gt(gt),
		.eq(eq),
		.sign(sign),
		.overflow(overflow)
	);

	// Test & print result
	task testprint;
		input e_alu_op t_op;
		input [7:0] t_a, t_b, t_e;
		input e_c, e_o, binary;
		begin
			reg signed [7:0]t_sa, t_sb, t_sr, t_se;
			string s_a, s_b, s_r, s_e;
			op = t_op;
			a = t_a;
			b = t_b;	
			#1
			t_sa = $signed(t_a);		
			t_sb = $signed(t_b);		
			t_sr = $signed(r);		
			t_se = $signed(t_e);
			if(binary) begin
			$sformat(s_a,"%b", t_sa);
			$sformat(s_b,"%b", t_sb);
			$sformat(s_r,"%b", t_sr);
			$sformat(s_e,"%b", t_se);
			end 
			else if (sign) begin
			$sformat(s_a,"%d", t_sa);
			$sformat(s_b,"%d", t_sb);
			$sformat(s_r,"%d", t_sr);
			$sformat(s_e,"%d", t_se);
			end 
			else begin
			$sformat(s_a,"%d", t_a);
			$sformat(s_b,"%d", t_b);
			$sformat(s_r,"%d", r);
			$sformat(s_e,"%d", t_e);
			end
			
			$display("ALU Test %4t00ps: %s %8s %s=%s C=%b O=%b", 
				$time, s_a, "unknown op", s_b, s_r, cout, overflow);
			if (r != t_e || cout != e_c || overflow != e_o) begin 
				$error("Incorrect: expected R=%s C=%b O=%b", s_e, e_c, e_o);
			end
		end		
	endtask
	
	task test;
		input e_alu_op t_op;
		input [7:0] t_a, t_b, t_e;
		input e_c, e_o;
		testprint(t_op, t_a, t_b, t_e, e_c, e_o, 0);
	endtask

	task testb;
		input e_alu_op t_op;
		input [7:0] t_a, t_b, t_e;
		input e_c, e_o;
		testprint(t_op, t_a, t_b, t_e, e_c, e_o, 1);
	endtask

	initial begin
		sign = 0;
		cin = 0;
		test(ALU_ADD, 120, 100, 220, 0, 0);
		test(ALU_ADD, 255, 255, 254, 1, 0);
		test(ALU_SUB, 120, 100, 20, 0, 0);
		test(ALU_SUB, 0, 100, -100, 1, 0); // FIXME: When unsigned probably want underflow flag on.
		testb(ALU_AND, 120, 100, 96, 0, 0);
		testb(ALU_NAND, 100, 120, -97, 0, 0);
		testb(ALU_OR, 100, 120, 124, 0, 0);
		testb(ALU_NOR, 100, 120, -125, 0, 0);
		testb(ALU_XOR, 100, 120, 28, 0, 0);
		testb(ALU_XNOR, 100, 120, -29, 0, 0);
		testb(ALU_SL, 8'b1111_0111, 2, 8'b1101_1100, 0, 0);
		testb(ALU_SR, 8'b1110_1111, 2, 8'b0011_1011, 0, 0);
		sign = 1;
		$display("ALU Settings: sign = 1");
		
		testb(ALU_SR, 8'b1000_0100, 2, 8'b1110_0001, 0, 0);
		testb(ALU_SR, 8'b0000_0100, 2, 8'b0000_0001, 0, 0);
		test(ALU_ADD, -10, 20, 10, 0, 0);
		test(ALU_ADD, -10, -20, -30, 0, 0);
		test(ALU_SUB, -10, -20, 10, 0, 0);
		test(ALU_SUB, -10, 20, -30, 0, 0);
		testb(ALU_SUB, -10, 20, -30, 0, 0);
		
		testb(ALU_RA, 8'b1100_0000, 0, 8'b1000_0001, 0, 0);
		testb(ALU_RAS, 8'b0000_0011, 0, 8'b1000_0001, 0, 0);
		test(ALU_MUL, 5, 8, 40, 0, 0);
		testb(ALU_MUL, -5, 8, -40, 0, 0);
		test(ALU_DIV, 64, 4, 16, 0, 0);
		test(ALU_DIV, 64, -4, -16, 0, 0);
		test(ALU_DIV, 65, 4, 16, 0, 0);
		test(ALU_MOD, 66, 4, 2, 0, 0);
		test(ALU_MOD, 65, 4, 1, 0, 0);
		test(ALU_MOD, 64, 4, 0, 0, 0);
		#10
		$stop;
	end

endmodule

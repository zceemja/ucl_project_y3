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
	a, b, r, r_high, op, cin, sign, zero, cout, cout_en, gt, eq, overflow, r_high_en
);
	parameter WORD=8;
	localparam WSIZE=$clog2(WORD);

	input e_alu_op 			op;
	input wire 			cin, sign;
	input logic [WORD-1:0] 	a, b;
	
	output logic 			zero, cout, gt, eq, overflow, r_high_en, cout_en;
	output logic [WORD-1:0] r, r_high;
	
	logic signed [WORD-1:0] signedA, signedB;
	assign signedA = $signed(a);
	assign signedB = $signed(b);

	logic [WSIZE-1:0] shmt;
	assign shmt = b[WSIZE-1:0];
	//
	//// FIXME: Seems like there's a bug with ModelSim or Verilog
	//// Object must be signed to do arithmetic shift right
	//// casting $signed does not work. Tho folloing passes:
 	//// assert(8'sb1000_0100 >>> 2 == 8'sb1110_0001);
	reg signed [WORD-1:0] sr;
	assign sr = signedA >>> shmt;
	

	logic isAddSub;
	logic cout0, cout1, gtu, overflow0;
	logic [2:0] overflowCK;
	logic [WORD*2-1:0] rmul, rdiv;
	logic [WORD-1:0] radd, rsub;
	
	logic [WORD-1:0] w_sllc, w_sll, w_srl, w_srlc;
	always_comb case(shmt)
		3'd0:    {w_sllc,w_sll} = {8'd0,a};
		3'd1:    {w_sllc,w_sll} = {7'd0,a,1'd0};
		3'd2:    {w_sllc,w_sll} = {6'd0,a,2'd0};
		3'd3:    {w_sllc,w_sll} = {5'd0,a,3'd0};
		3'd4:    {w_sllc,w_sll} = {4'd0,a,4'd0};
		3'd5:    {w_sllc,w_sll} = {3'd0,a,5'd0};
		3'd6:    {w_sllc,w_sll} = {2'd0,a,6'd0};
		3'd7:    {w_sllc,w_sll} = {1'd0,a,7'd0};
		default: {w_sllc,w_sll} =      {a,8'd0};
	endcase
	
	always_comb case(shmt)
		3'd0:    {w_srl,w_srlc} =      {a,8'd0};
		3'd1:    {w_srl,w_srlc} = {1'd0,a,7'd0};
		3'd2:    {w_srl,w_srlc} = {2'd0,a,6'd0};
		3'd3:    {w_srl,w_srlc} = {3'd0,a,5'd0};
		3'd4:    {w_srl,w_srlc} = {4'd0,a,4'd0};
		3'd5:    {w_srl,w_srlc} = {5'd0,a,3'd0};
		3'd6:    {w_srl,w_srlc} = {6'd0,a,2'd0};
		3'd7:    {w_srl,w_srlc} = {6'd0,a,1'd0};
		default: {w_srl,w_srlc} = {8'd0,a};
	endcase

	always_comb begin
		// Flags
		isAddSub = (op == ALU_ADD)|(op == ALU_SUB);

		// Addition/Subtraction
		{cout0,radd} = a + b + cin;
		{cout1,rsub} = a - b - cin;
		
		cout_en = isAddSub & !sign;
		cout = (op == ALU_ADD) ? cout0 : cout1;

		// Multiplication/Dividion
		if(sign) begin
			rmul = signedA * signedB;
			rdiv = {signedA/signedB,signedA%signedB};
		end else begin
			rmul = a * b;
			rdiv = {a/b,a%b};
		end
  		
		case(op)
			ALU_MUL: r_high = rmul[WORD*2-1:WORD];
			ALU_DIV: r_high = rdiv[WORD*2-1:WORD];
			ALU_SL:  r_high = w_sllc;
			ALU_SR:  r_high = w_srlc;
			default: r_high = 'd0;
		endcase
		//r_high = (op == ALU_MUL) ? rmul[WORD*2-1:WORD] : rdiv[WORD-1:0];
		r_high_en = (op == ALU_MUL)|(op == ALU_DIV)|(op == ALU_SL)|(op == ALU_SR);

		// Overflow/Underflow
		overflowCK = {a[WORD-1], b[WORD-1], r[WORD-1]};	
		overflow = sign&isAddSub&((op==ALU_SUB)^((overflowCK==3'b110)|(overflowCK==3'b001)));

		// Output flags
		zero = r == 0;
		eq = a == b;
		gtu = a > b;
		gt = (sign&(a[WORD-1]^b[WORD-1])) ? ~gtu : gtu;	
	end

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
		ALU_SL:   r = w_sll;
		ALU_SR:   r = w_srl;
		ALU_RA:   r = {a[0], a[WORD-1:1]};
		ALU_RAS:  r = {a[WORD-2:0], a[WORD-1]};
		ALU_MUL:  r = rmul[WORD-1:0];
		ALU_DIV:  r = rdiv[WORD*2-1:WORD];
		ALU_MOD:  r = rdiv[WORD-1:0];
		default:  r = 0;
	endcase
	end


endmodule

`timescale 1ns / 100ps
module alu_tb;
	e_alu_op op;
	reg [7:0]a, b, r, rh;
	logic overflow, zero, cin, cout, gt, eq, sign, rhe, ce;
	
	
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
		.overflow(overflow),
		.r_high(rh),
		.r_high_en(rhe),
		.cout_en(ce)
	);

	// Test & print result
	task testprint;
		input e_alu_op t_op;
		input [7:0] t_a, t_b;
		input [15:0] t_e;
		input reg [6:0]oFlags;
		input binary;
		begin
			reg signed [7:0]t_sa, t_sb, t_sr;
			reg signed [7:0] t_se;
			string s_a, s_b, s_r, s_e;
			reg useh;
			reg [6:0] rFlags;
			string fnames [6:0];
			fnames = {"zero", "eq", "gt", "overflow", "cout", "ce", "rhe"};
			op = t_op;
			a = t_a;
			b = t_b;	
			#500ps;
			t_sa = $signed(t_a);		
			t_sb = $signed(t_b);		
			t_sr = $signed(r);		
			t_se = $signed(t_e[7:0]);
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
			$sformat(s_e,"%d", t_e[7:0]);
			end
			
			rFlags = {zero, eq, gt, overflow, cout, ce, rhe};
			if (op == ALU_MUL) begin
				$display("ALU Test %4t: %s %8s %s=%d", $time, s_a, t_op.name(), s_b, {rh, r});
				if({rh, r} !== t_e) $error("Incorrect mul result: %d != %d [%b_%b != %b_%b]", {rh, r}, t_e, rh, r, t_e[15:8], t_e[7:0]);
			end else if (op == ALU_DIV) begin
				$display("ALU Test %4t: %s %8s %s= [%d %d]", $time, s_a, t_op.name(), s_b, rh, r);
				if({rh, r} !== t_e) $error("Incorrect div result: %d %d != %d %d  [%b_%b != %b_%b]", rh, r, t_e[15:8], t_e[7:0], rh, r, t_e[15:8], t_e[7:0]);
			end else begin
				$display("ALU Test %4t: %s %8s %s=%d", $time, s_a, t_op.name(), s_b, s_r);
				if (r !== t_e[7:0]) $error("Incorrect result: %s != %s", s_r, s_e);
			end
			for (int i=0; i<6; i++) if(rFlags[i] === 'x || rFlags[i] != oFlags[i]) $error("Incorrect %s flag: %z != %z", fnames[i], rFlags[i], oFlags[i]);
			#500ps;
		end		
	endtask
	
	task test;
		input e_alu_op t_op;
		input [7:0] t_a, t_b;
		input [15:0] t_e;
		input [6:0] f_e;
		testprint(t_op, t_a, t_b, t_e, f_e, 0);
	endtask

	task testb;
		input e_alu_op t_op;
		input [7:0] t_a, t_b;
		input [15:0] t_e;
		input [6:0] f_e;
		testprint(t_op, t_a, t_b, t_e, f_e, 1);
	endtask

	initial begin
		// eFlags:
		//   6 | 5| 4|  3  |  2 |  1  | 0 
		// zero|eq|gt|oflow|cout|coute|rhe
		
		sign = 0;
		cin = 0;
		$display("\nALU Settings: sign = %b, carry in = %b\n\n", sign, cin);

		// Testing arithmetic unsigned
		test(ALU_ADD,	120,	100,	220,	'b0010010);
		test(ALU_SUB,	110,	110,	0,		'b1100010); // testing flags
		test(ALU_ADD,	255,	255,	254,	'b0100110); // testing carryout
		test(ALU_SUB,	120,	100,	20,		'b0010010);
		test(ALU_SUB,	0,		100,	-100,	'b0000110);

		cin = 1;
		$display("\nALU Settings: sign = %b, carry in = %b\n\n", sign, cin);
		test(ALU_ADD,	255,	255,	255,	'b0100110);
		test(ALU_SUB,	120,	100,	19,		'b0010010);
		
		cin = 0;
		$display("\nALU Settings: sign = %b, carry in = %b\n\n", sign, cin);

		test(ALU_MUL, 	5, 		8, 		40, 	'b0000?01);
		test(ALU_MUL, 	20,		20,		400, 	'b0100?01);
		test(ALU_DIV, 	64, 	4, 		{8'd0, 8'd16}, 	'b0010?01);
		test(ALU_DIV, 	65, 	4, 		{8'd1, 8'd16}, 	'b0010?01);
		
		// Testing logic
		testb(ALU_AND,	120,	100,	96,		'b0??0?00);
		testb(ALU_NAND,	100,	120,	-97,	'b0??0?00);
		testb(ALU_OR,	100,	120,	124,	'b0??0?00);
		testb(ALU_NOR,	100,	120,	-125,	'b0??0?00);
		testb(ALU_XOR,	100,	120,	28,		'b0??0?00);
		testb(ALU_XNOR,	100,	120,	-29,	'b0??0?00);


		testb(ALU_SL, 	'b1111_0111, 2, 'b1101_1100, 'b???0?00);
		testb(ALU_SR, 	'b1110_1111, 2, 'b0011_1011, 'b???0?00);
		testb(ALU_SR, 	'b1000_0100, 2, 'b0010_0001, 'b???0?00);
		testb(ALU_SR, 	'b0000_0100, 2, 'b0000_0001, 'b???0?00);

		sign = 1;
		$display("\nALU Settings: sign = %b, carry in = %b\n\n", sign, cin);
		testb(ALU_SR, 	'b1000_0100, 2, 'b1110_0001, 'b???0?00);
		test(ALU_ADD,	100,	-50,	50,			'b0010?00);
		test(ALU_ADD,	100,	50,		150,		'b0011?00);
		test(ALU_ADD,	-100,	-100,	56,			'b0101?00);
		test(ALU_ADD,	50,		-100,	-50,		'b0010?00);
		test(ALU_SUB,	100,	120,	-20,		'b0000?00);
		test(ALU_SUB,	-100,	100,	56,			'b0001?00);
		test(ALU_ADD,	-10,	-10,	-20,		'b0100?00);
		test(ALU_ADD,	-10,	10,		0,			'b1000?00);
		test(ALU_SUB,	-10,	-20,	10,			'b0010?00);
		test(ALU_MUL, 	-5, 	8, 		-40, 		'b0000?01);
		test(ALU_DIV, 	64, 	-4, 	{8'd0,8'hF0}, 'b0010?01);
		test(ALU_DIV, 	65, 	-4, 	{8'd1,8'hF0}, 'b0010?01);
		test(ALU_DIV, 	66, 	-4, 	{8'd2,8'hF0}, 'b0010?01);
		test(ALU_DIV, 	67, 	-4, 	{8'd3,8'hF0}, 'b0010?01);
		
		//test(ALU_ADD, -10, 20, 10, 0, 0);
		//test(ALU_ADD, -10, -20, -30, 0, 0);
		//test(ALU_SUB, -10, -20, 10, 0, 0);
		//test(ALU_SUB, -10, 20, -30, 0, 0);
		//testb(ALU_SUB, -10, 20, -30, 0, 0);
		
		//testb(ALU_RA, 8'b1100_0000, 0, 8'b1000_0001, 0, 0);
		//testb(ALU_RAS, 8'b0000_0011, 0, 8'b1000_0001, 0, 0);
		#10
		$finish;
	end

endmodule

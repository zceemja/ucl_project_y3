module empty(a, b);
	input logic a;
	output logic b;
	always_comb b = ~a;
endmodule

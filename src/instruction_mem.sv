module instruction_mem(addr, data);
parameter WORD=8;
input [WORD-1:0] addr;
output logic [WORD-1:0] data;

always_comb begin
	case(addr)
		0: data <= 8'b1000_0000;
		1: data <= 8'b0100_0000;
		2: data <= 8'b0010_0000;
		3: data <= 8'b0001_0000;
		4: data <= 8'b0000_1000;
		5: data <= 8'b0000_0100;
		6: data <= 8'b0000_0010;
		7: data <= 8'b0000_0001;
	-	8: data <= 8'hFF;
		default: data = 0;
	endcase
end
 
endmodule

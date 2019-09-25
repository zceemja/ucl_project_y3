
module io_unit(switches, keys, leds);
	input  logic [3:0]switches;
	input  logic [1:0]keys;
	output logic [7:0]leds;
	
	assign rst = keys[0];
	assign clk = keys[1];
	cpu CPU(clk, rst);
	
endmodule

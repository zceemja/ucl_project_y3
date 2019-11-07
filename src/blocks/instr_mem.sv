module instr_rom(addr, instr);
	parameter FILE = "";	
	parameter WIDTH=8, LENGTH=256, OUTMUL=2;
	parameter ADDR_WIDTH = $clog2(LENGTH);

	input  wire [ADDR_WIDTH-1:0]   addr;
	output reg  [WIDTH*OUTMUL-1:0] instr;
	
	initial $display("Instruction ROM %0dx%0dbit, size of %0dB loaded from %s ...", WIDTH, ADDR_WIDTH, LENGTH*WIDTH/8, FILE);
	logic [WIDTH-1:0] rom [LENGTH-1:0];
	initial if(FILE != "") $readmemh(FILE, rom);
	initial begin
		 $display("Instruction ROM dump");
		 for (int i=0; i < LENGTH; i+=32) begin
			$write("%h:", i);
			for(int j=0; j<32 && j+i < LENGTH; j++)
		 		$write(" %h", rom[i+j]);
			$display(" :%h", i);
		end
	end
 
	always_comb begin
		for (int i=0; i<OUTMUL;i++) 
				instr[WIDTH*i+:WIDTH] = (addr+i >= LENGTH) ? '0 : rom[addr + i];
	end
endmodule

`timescale 1ns / 1ns
module instr_rom_tb;
	reg [15:0] addr;
	reg [15:0] instr;

	instr_rom #("../../memory/rom_test.mem", 8, 256, 2, 16) rom0(addr, instr);

	initial begin
		addr = 'h0000;
		#10ns;
		assert(instr == 'h0100);
		addr = 'h0001;
		#10ns;
		assert(instr == 'h0201);
		addr = 'h0002;
		#10ns;
		assert(instr == 'h0302);
		addr = 'h0003;
		#10ns;
		assert(instr == 'h0403);
		addr = 'h00ff;
		#10ns;
		assert(instr == 'h00ff);
		addr = 'haaff;
		#10ns;
		assert(instr == 'h0000);
	end

endmodule

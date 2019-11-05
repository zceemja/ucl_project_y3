module instr_mem(addr, instr, imm);
	parameter IMEM_FILE = "";
	parameter WIDTH=8, LENGTH=256;
	localparam ADDR_WIDTH = $clog2(LENGTH);

	input  [ADDR_WIDTH-1:0] addr;
	output [WIDTH-1:0]	imm;
	output [WIDTH-1:0]	instr;
	
	logic [WIDTH-1:0] rom [LENGTH-1:0];
	initial $readmemh(IMEM_FILE, rom);
	initial begin
		 $display("Instruction ROM dump");
		 for (int i=0; i < LENGTH; i+=16) begin
			$write("%h:", i);
			for(int j=0; j<16 && j+i < LENGTH; j++)
		 		$write(" %h", rom[i+j]);
			$display(" :%h", i);
		end
	end
 
	always_comb begin
		instr = rom[addr];
		imm = rom[addr + 1];
	end

endmodule

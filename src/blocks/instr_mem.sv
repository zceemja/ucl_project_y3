import project_pkg::*;

module instr_mem(addr, instr, imm);
	parameter IMEM_FILE = "";
	input  word addr;
	output word	imm;
	output word	instr;
	
	logic [word_size-1:0] rom [rom_size-1:0];
	initial $readmemh(IMEM_FILE, rom);
	initial begin
		 $display("Instruction ROM dump");
		 for (int i=0; i < rom_size; i+=16) begin
			$write("%h:", i);
			for(int j=0; j<16 && j+i < rom_size; j++)
		 		$write(" %h", rom[i+j]);
			$display(" :%h", i);
		end
	end
 
	always_comb begin
		instr = rom[addr];
		imm = rom[addr + 1];
	end

endmodule

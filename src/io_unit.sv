import project_pkg::word;

module io_unit(switches, keys, leds);
	input  logic [3:0]switches;
	input  logic [1:0]keys;
	output logic [7:0]leds;
	
	assign rst = keys[0];
	assign clk = keys[1];
	logic mem_wr;
	word pc, instr, imm, mem_addr, mem_data, mem_rd_data;	
	cpu CPU(clk, rst, instr, imm, pc, mem_addr, mem_wr, mem_data, mem_rd_data);
	// Instruction memory
	instr_mem #("/home/min/devel/fpga/ucl_project_y3/memory/test.mem") IMEM(pc, instr, imm);
	// System memory
	memory RAM(clk, mem_wr, mem_addr, mem_data, mem_rd_data);	

endmodule

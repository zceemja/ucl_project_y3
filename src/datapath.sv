import project_pkg::*;

module datapath(clk, rst, rs, rt, imm, alu_op, reg_wr, pc_src, alu_src, mem_to_reg, pc, alu_out, mem_data, alu_zero, mem_wr_data);
	input logic clk, rst, reg_wr, pc_src, alu_src, mem_to_reg;
	input e_reg rs, rt;
	input e_alu_op alu_op;
	input word imm, mem_data;
	output word pc, alu_out, mem_wr_data;
	output logic alu_zero;
	
	// Reg File
	word reg_rd_d1, reg_rd_d2, reg_wr_d;
	e_reg reg_rd_a1, reg_rd_a2, reg_wr_a;
	assign reg_rd_a1 = rs;
	assign reg_rd_a2 = rt;
	assign reg_wr_a = rs;
	assign reg_wr_d = (mem_to_reg) ? mem_data : alu_out;
	reg_file RFILE(clk, rst, reg_rd_a1, reg_rd_a2, reg_rd_d1, reg_rd_d2, reg_wr_a, reg_wr_d, reg_wr);

	// Mem output data
	assign mem_wr_data = reg_rd_a2;

	// ALU
	word alu_srcA, alu_srcB;
	assign alu_srcA = reg_rd_d1;
	assign alu_srcB = (alu_src) ? imm : reg_rd_d2;
	alu ALU(alu_op, alu_srcA, alu_srcB, alu_out, alu_zero);
	
	// Program counter
	word pcn; 	// PC next
	word pcj;   // PC jump, +2 if imm used otherwise +1
	assign pcj = (alu_src) ? pc + 2 : pc + 1;
	//assign pcj = pc + 1;
	assign pcn = (pc_src) ? imm : pcj;
	always_ff@(posedge clk) begin
	  	if (rst) pc <= 0;
		else pc <= pcn;
	end
endmodule

module datapath_tb;
	logic clk, rst, reg_wr, pc_src, alu_src, mem_to_reg, alu_zero;
	e_reg rs, rt;
	e_alu_op alu_op;
	word imm, mem_data, pc, alu_out;
	datapath DPATH(clk, rst, rs, rt, imm, alu_op, reg_wr, pc_src, alu_src, mem_to_reg, pc, alu_out, mem_data, alu_zero);

	initial begin
		clk = 0;
		forever #5ns clk = ~clk;
	end

	initial begin
		rst = 1;
		reg_wr = 0;
		pc_src = 0;
		alu_src = 0;
		mem_to_reg = 0;
		rs = RegA;
		rt = RegA;
		alu_op = ALU_NOP;
		imm = 8'h00;
		mem_data = 8'h00;
		#10ns;
		rst = 0;
		reg_wr = 1;
		mem_to_reg = 1;
		mem_data = 8'h7A;
		#10ns;
		rs = RegB;
		mem_data = 8'h8A;
		#10ns;
		rs = RegC;
		mem_data = 8'h9A;
		#10ns;
		rs = RegD;
		mem_data = 8'hFD;
		#10ns;
		rs = RegA;
		#10ns;
		$stop;
	end


endmodule

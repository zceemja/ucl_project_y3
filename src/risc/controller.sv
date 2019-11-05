import risc8_pkg::*;
import alu_pkg::*;

module controller8(
		input word instr,
		risc8_cdi.control cdi,
		output mem_wr, mem_rd	
);
	// Instruction decoding
	assign instr_op 	= e_instr'(instr[7:4]);
	assign cdi.a1		= e_reg_addr'(instr[3:2]);
	assign cdi.a2		= e_reg_addr'(instr[1:0]);
	assign cdi.a3 		= cdi.a1; // Assuming destination always first operand

	// generated table
    always_comb begin
    casez(instr_op)
        MOVE   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1;
            cdi.selr   = SR_COM;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CPY0   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_IMM;
            cdi.rw_en  = 1;
            cdi.selr   = SR_IMM;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CPY1   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_IMM;
            cdi.rw_en  = 1;
            cdi.selr   = SR_IMM;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CPY2   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_IMM;
            cdi.rw_en  = 1;
            cdi.selr   = SR_IMM;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CPY3   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_IMM;
            cdi.rw_en  = 1;
            cdi.selr   = SR_IMM;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        ADD    : begin
            cdi.alu_op = ALU_ADD;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SUB    : begin
            cdi.alu_op = ALU_SUB;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        AND    : begin
            cdi.alu_op = ALU_AND;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        OR     : begin
            cdi.alu_op = ALU_OR;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        XOR    : begin
            cdi.alu_op = ALU_XOR;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        MUL    : begin
            cdi.alu_op = ALU_MUL;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        DIV    : begin
            cdi.alu_op = ALU_DIV;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        BR     : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SLL    : begin
            cdi.alu_op = ALU_SL;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SRL    : begin
            cdi.alu_op = ALU_SR;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SRA    : begin
            cdi.alu_op = ALU_RA;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SRAS   : begin
            cdi.alu_op = ALU_RAS;
            cdi.selb   = SB_REG;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        LWHI   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1;
            cdi.selr   = SR_MEMH;
            mem_rd     = 0;
            mem_wr     = 1;
        end
        SWHI   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 0;
            cdi.selr   = SR_NONE;
            mem_rd     = 1;
            mem_wr     = 0;
        end
        LWLO   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1;
            cdi.selr   = SR_MEML;
            mem_rd     = 0;
            mem_wr     = 1;
        end
        SWLO   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 0;
            cdi.selr   = SR_NONE;
            mem_rd     = 1;
            mem_wr     = 0;
        end
        INC    : begin
            cdi.alu_op = ALU_ADD;
            cdi.selb   = SB_1;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        DEC    : begin
            cdi.alu_op = ALU_SUB;
            cdi.selb   = SB_1;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUL;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        GETAH  : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1;
            cdi.selr   = SR_ALUH;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        GETIF  : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1;
            cdi.selr   = SR_INTR;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        PUSH   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        POP    : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        COM    : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CALL   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        RET    : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        JUMP   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        RETI   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CLC    : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SETC   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CLS    : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SETS   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SSETS  : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        CLN    : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SETN   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        SSETN  : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        RJUMP  : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        RBWI   : begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
        default: begin
            cdi.alu_op = ALU_NONE;
            cdi.selb   = SB_NONE;
            cdi.rw_en  = 1'bx;
            cdi.selr   = SR_NONE;
            mem_rd     = 0;
            mem_wr     = 0;
        end
    endcase
    end
	// generated table end

endmodule

//module controller(instr, zero, alu_op, alu_ex, mem_wr, reg_wr, 
//		pc_src, rimm, alu_src, mem_to_reg, instr_op, rd, rs, sp_wr, mem_sp);
//	input word instr;
//	input logic zero; // That's from ALU for J instructions
//	output e_alu_op alu_op;
//	output e_alu_ext_op alu_ex;
//	output logic mem_wr, reg_wr, rimm, mem_to_reg, pc_src, alu_src;
//	output e_instr instr_op;
//	output e_reg rs, rd;
//	output logic sp_wr, mem_sp;
//
//	// Instruction decoding
//	assign instr_op 	= e_instr'(instr[7:4]);
//	assign rd 			= e_reg'(instr[3:2]);
//	assign rs 			= e_reg'(instr[1:0]);
//	
//	e_alu_op alu_subsel;
//	//assign alu_subsel = (instr_op == JEQ) ? ALU_SUB : ALU_CPY;
//	assign alu_subsel = (instr_op == JEQ) ? ALU_SUB: ALU_ADD;
//	assign alu_op = instr_op[3] ? alu_subsel : e_alu_op'(instr_op[2:0]);
//	assign reg_wr = ~instr_op[3] | instr_op == LW | instr_op == POP; 
//	
//	assign mem_wr = instr_op == SW | instr_op == PUSH;
//	assign mem_to_reg = instr_op == LW | instr_op == POP;
//	assign pc_src = (zero && instr_op == JEQ) | instr_op == JMP;
//	
//	assign alu_src = (instr_op == CPY & rd == rs);	
//	assign rimm = (alu_src) | instr_op == JEQ;	
//	assign alu_ex = e_alu_ext_op'(rs);
//
//	// Stack instructions
//	assign mem_sp = instr_op[0];
//	assign sp_wr = instr_op == PUSH | instr_op == POP;
//endmodule
//
//module controller_tb;
//	word instr;
//	logic zero, mem_wr, reg_wr, alu_src, mem_to_reg, pc_src;
//	e_alu_op alu_op;
//
//	controller CTR(instr, zero, alu_op, mem_wr, reg_wr, pc_src, alu_src, mem_to_reg);
//
//	initial begin
//		instr = 8'h00;
//		zero = 1;
//		#5ns;
//		//assert(alu_op == ALU_NOP);
//		assert(mem_wr == 0);
//		assert(reg_wr == 0);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'h10;
//		#5ns;
//		assert(alu_op == ALU_ADD);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'h20;
//		#5ns;
//		assert(alu_op == ALU_ADD);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 1);
//		assert(mem_to_reg == 0);
//		instr = 8'h30;
//		#5ns;
//		assert(alu_op == ALU_SUB);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'h40;
//		#5ns;
//		assert(alu_op == ALU_AND);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'h50;
//		#5ns;
//		assert(alu_op == ALU_OR);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'h60;
//		#5ns;
//		//assert(alu_op == ALU_NOT);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'h70;
//		#5ns;
//		//assert(alu_op == ALU_NOP);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 1);
//		instr = 8'h80;
//		#5ns;
//		//assert(alu_op == ALU_NOP);
//		assert(mem_wr == 1);
//		assert(reg_wr == 0);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'hB0;
//		#5ns;
//		//assert(alu_op == ALU_NOP);
//		assert(mem_wr == 0);
//		assert(reg_wr == 1);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		instr = 8'hC0;
//		#5ns;
//		assert(alu_op == ALU_SUB);
//		assert(mem_wr == 0);
//		assert(reg_wr == 0);
//		assert(pc_src == 1);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//		zero = 0;
//		#5ns;
//		assert(alu_op == ALU_SUB);
//		assert(mem_wr == 0);
//		assert(reg_wr == 0);
//		assert(pc_src == 0);
//		assert(alu_src == 0);
//		assert(mem_to_reg == 0);
//
//		$stop;
//	end
//endmodule


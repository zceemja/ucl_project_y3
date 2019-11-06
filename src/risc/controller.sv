import risc8_pkg::*;
import alu_pkg::*;

module controller8(
		input word instr,
		risc8_cdi.control cdi,
		output reg mem_wr, mem_rd	
);
	// Instruction decoding
	assign cdi.a1		= e_reg_addr'(instr[3:2]);
	assign cdi.a2		= e_reg_addr'(instr[1:0]);
	assign cdi.a3 		= cdi.a1; // Assuming destination always first operand
	
	e_instr op;

	// generated table
    always_comb begin
    casez(instr)
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

`timescale 1ns / 1ns
module controller8_tb;
	word instr;
	risc8_cdi cdi();
	logic mem_wr, mem_rd;
	controller8 c0(instr, cdi, mem_wr, mem_rd);

	initial begin
		instr = 8'b0000_0000;
		cdi.alu_comp = 3'b000;
		#10ns;
		instr = 8'b0000_0100;
		#10ns;
		instr = 8'b0001_0001;
		#10ns;
		instr = 8'b0010_0001;
		#10ns;
		instr = 8'b1111_1111;
		#10ns;
	end

endmodule


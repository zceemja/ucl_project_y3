`ifndef SYNTHESIS
	`define ADDOP
`endif

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
	
	`ifdef ADDOP
		initial $display("Control adding 'op' reg");
		e_instr op;
	`endif


	// generated table
    always_comb begin
    casez(instr)
        CPY0   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_IMM;
            cdi.rw_en   = 1;
            cdi.selr    = SR_IMM;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 1;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = CPY0;
            `endif
        end
        CPY1   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_IMM;
            cdi.rw_en   = 1;
            cdi.selr    = SR_IMM;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 1;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = CPY1;
            `endif
        end
        CPY2   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_IMM;
            cdi.rw_en   = 1;
            cdi.selr    = SR_IMM;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 1;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = CPY2;
            `endif
        end
        CPY3   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_IMM;
            cdi.rw_en   = 1;
            cdi.selr    = SR_IMM;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 1;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = CPY3;
            `endif
        end
        MOVE   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 1;
            cdi.selr    = SR_REG;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = MOVE;
            `endif
        end
        ADD    : begin
            cdi.alu_op  = ALU_ADD;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = ADD;
            `endif
        end
        SUB    : begin
            cdi.alu_op  = ALU_SUB;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SUB;
            `endif
        end
        AND    : begin
            cdi.alu_op  = ALU_AND;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = AND;
            `endif
        end
        OR     : begin
            cdi.alu_op  = ALU_OR;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = OR;
            `endif
        end
        XOR    : begin
            cdi.alu_op  = ALU_XOR;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = XOR;
            `endif
        end
        MUL    : begin
            cdi.alu_op  = ALU_MUL;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = MUL;
            `endif
        end
        DIV    : begin
            cdi.alu_op  = ALU_DIV;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = DIV;
            `endif
        end
        BR     : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 2;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = BR;
            `endif
        end
        SLL    : begin
            cdi.alu_op  = ALU_SL;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SLL;
            `endif
        end
        SRL    : begin
            cdi.alu_op  = ALU_SR;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SRL;
            `endif
        end
        SRA    : begin
            cdi.alu_op  = ALU_RA;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SRA;
            `endif
        end
        SRAS   : begin
            cdi.alu_op  = ALU_RAS;
            cdi.selb    = SB_REG;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SRAS;
            `endif
        end
        LWHI   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 1;
            cdi.selr    = SR_MEMH;
            mem_rd      = 1;
            mem_wr      = 0;
            cdi.isize   = 3;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = LWHI;
            `endif
        end
        SWHI   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEMH;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SWHI;
            `endif
        end
        LWLO   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 1;
            cdi.selr    = SR_MEML;
            mem_rd      = 1;
            mem_wr      = 0;
            cdi.isize   = 3;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = LWLO;
            `endif
        end
        SWLO   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 1;
            cdi.isize   = 3;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SWLO;
            `endif
        end
        INC    : begin
            cdi.alu_op  = ALU_ADD;
            cdi.selb    = SB_1;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = INC;
            `endif
        end
        DEC    : begin
            cdi.alu_op  = ALU_SUB;
            cdi.selb    = SB_1;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUL;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = DEC;
            `endif
        end
        GETAH  : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 1;
            cdi.selr    = SR_ALUH;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = GETAH;
            `endif
        end
        GETIF  : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 1;
            cdi.selr    = SR_INTR;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = GETIF;
            `endif
        end
        PUSH   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 1;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SUB;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = PUSH;
            `endif
        end
        POP    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 1;
            cdi.selr    = SR_MEML;
            mem_rd      = 1;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_ADD;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = POP;
            `endif
        end
        COM    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 1;
            cdi.selr    = SR_COM;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 1;
            cdi.selo    = SO_COM;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = COM;
            `endif
        end
        SETI   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SETI;
            `endif
        end
        BEQ    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_IMM;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = (cdi.alu_comp[2:1] == 'b10)?1:3;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = (cdi.alu_comp[2:1] == 'b10)?PC_IMM2:PC_NONE;
            `ifdef ADDOP
            op = BEQ;
            `endif
        end
        BGT    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_IMM;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = (cdi.alu_comp[2:1] == 'b01)?1:3;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = (cdi.alu_comp[2:1] == 'b01)?PC_IMM2:PC_NONE;
            `ifdef ADDOP
            op = BGT;
            `endif
        end
        BGE    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_IMM;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = (cdi.alu_comp[2]|cdi.alu_comp[1])?1:3;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = (cdi.alu_comp[2]|cdi.alu_comp[1])?PC_IMM2:PC_NONE;
            `ifdef ADDOP
            op = BGE;
            `endif
        end
        BZ     : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = BZ;
            `endif
        end
        CALL   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 1;
            cdi.isize   = 2;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SUB;
            cdi.pcop    = PC_IMM;
            `ifdef ADDOP
            op = CALL;
            `endif
        end
        RET    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 1;
            mem_wr      = 0;
            cdi.isize   = 2;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_ADD;
            cdi.pcop    = PC_MEM;
            `ifdef ADDOP
            op = RET;
            `endif
        end
        JUMP   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 3;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_NONE;
            cdi.pcop    = PC_IMM;
            `ifdef ADDOP
            op = JUMP;
            `endif
        end
        RETI   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 1;
            mem_wr      = 0;
            cdi.isize   = 2;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SUB;
            cdi.pcop    = PC_MEM;
            `ifdef ADDOP
            op = RETI;
            `endif
        end
        CLC    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = CLC;
            `endif
        end
        SETC   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SETC;
            `endif
        end
        CLS    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = CLS;
            `endif
        end
        SETS   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SETS;
            `endif
        end
        SSETS  : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SSETS;
            `endif
        end
        CLN    : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = CLN;
            `endif
        end
        SETN   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SETN;
            `endif
        end
        SSETN  : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = SSETN;
            `endif
        end
        RJUMP  : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 2;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = RJUMP;
            `endif
        end
        RBWI   : begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 1;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
            `ifdef ADDOP
            op = RBWI;
            `endif
        end
        default: begin
            cdi.alu_op  = ALU_NONE;
            cdi.selb    = SB_NONE;
            cdi.rw_en   = 0;
            cdi.selr    = SR_NONE;
            mem_rd      = 0;
            mem_wr      = 0;
            cdi.isize   = 0;
            cdi.selo    = SO_MEML;
            cdi.stackop = ST_SKIP;
            cdi.pcop    = PC_NONE;
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


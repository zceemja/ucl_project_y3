package risc8_pkg;

	localparam word_size = 8;
	localparam reg_size = 4;

	localparam reg_addr_size = $clog2(reg_size);
	typedef logic [word_size-1:0] word;
	typedef logic [reg_addr_size-1:0] reg_addr;

	typedef enum logic [7:0] { 
		// [ xxxx xx xx ] => [ inst rd rs ]
		// mp: Memory page
		// cp: Co-processor, 0x00 = RAM, 0x01 = ROM, 0x02 = FPU, 0x03 = GPIO
		MOVE =8'b0000_????,  // i0 &rd = &rs
		CPY0 =8'b0000_0000,  // i0 &rd = imm
		CPY1 =8'b0000_0101,  // i0 &rd = imm
		CPY2 =8'b0000_1010,  // i0 &rd = imm
		CPY3 =8'b0000_1111,  // i0 &rd = imm

		ADD  =8'b0001_????,  // i1 &rd = &rd + &rs
		SUB  =8'b0010_????,  // i2 &rd = &rd - &rs
		AND  =8'b0011_????,  // i3 &rd = &rd & &rsgt
		OR   =8'b0100_????,  // i4 &rd = &rd | &rs
		XOR  =8'b0101_????,  // i5 &rd = &rd ^ &rs
		MUL  =8'b0110_????,  // i6 {&ah,  &rd} = &rd * &rs
		DIV  =8'b0111_????,  // i7 &rd = &rd / &rs, &ah = &rd % &rs

		CI0  =8'b1000_??00,  // i8-0
		CI1  =8'b1000_??01,  // i8-1
		CI2  =8'b1000_??10,  // i8-2
		ADDC =8'b1000_??11,  // i8-3 
		
		SLL  =8'b1001_??00,  // i9-0 shift left logical
		SRL  =8'b1001_??01,  // i9-1 shift right logical
		SRA  =8'b1001_??10,  // i9-2 shift right arithmetic
		SUBC =8'b1001_??11,  // i9-3 Low value from instruction mem

		LWHI =8'b1010_??00,  // i10-0 
		SWHI =8'b1010_??01,  // i10-1 
		LWLO =8'b1010_??10,  // i10-2 
		SWLO =8'b1010_??11,  // i10-3 
		
		INC  =8'b1011_??00,  // i11-0 
		DEC  =8'b1011_??01,  // i11-1 
		GETAH=8'b1011_??10,  // i11-2 
		GETIF=8'b1011_??11,  // i11-3 
		
		PUSH =8'b1100_??00,  // i12-0
        POP  =8'b1100_??01,  // i12-1 
        COM  =8'b1100_??10,  // i12-2
		XORI =8'b1100_??11,  // i12-3 Set next immidate
		
		BEQ  =8'b1101_??00,  // i13-0 Branch to imm[24:8] if imm[7:0] == rd
		BGT  =8'b1101_??01,  // i13-1 Branch greater than
		BGE  =8'b1101_??10,  // i13-2 Branch greater equal than
		BZ   =8'b1101_??11,  // i13-3 Branch to imm[15:0] if rd == zero

		ADDI =8'b1110_??00,  // i14-0 
		SUBI =8'b1110_??01,  // i14-1 
		ANDI =8'b1110_??10,  // i14-2 
		ORI  =8'b1110_0011,  // i14-3 
		
		CALL =8'b1111_0000,  // i15-0
        RET  =8'b1111_0001,  // i15-1
        JUMP =8'b1111_0010,  // i15-2
        RETI =8'b1111_0011,  // i15-3
        CLC  =8'b1111_0100,  // i15-4
        SETC =8'b1111_0101,  // i15-5
        CLS  =8'b1111_0110,  // i15-6
        SETS =8'b1111_0111,  // i15-7
        SSETS=8'b1111_1000,  // i15-8
        CLN  =8'b1111_1001,  // i15-9
        SETN =8'b1111_1010,  // i15-10
        SSETN=8'b1111_1011,  // i15-11
        RJUMP=8'b1111_1100,  // i15-12
        RBWI =8'b1111_1101,  // i15-13 Replace ALU src B with immediate
        INTRE=8'b1111_1110,  // i15-14 Interrupt entry
        i255 =8'b1111_1111   // i15-15
		
	} e_instr;               

	typedef enum logic [1:0] {
		SB_NONE= 2'bxx,
		SB_REG = 2'b00,
		SB_0   = 2'b01,
		SB_1   = 2'b10,
		SB_IMM = 2'b11
	} e_selb;

	typedef enum logic [1:0] {
		SO_NONE= 2'bxx,
		SO_COM = 2'b00,
		SO_MEMH= 2'b01,
		SO_MEML= 2'b10
		//SO_= 2'b11
	} e_selo;

	typedef enum logic [2:0] {
		SR_NONE= 3'bxxx,
		SR_REG = 3'b000,
		SR_MEML= 3'b001,
		SR_MEMH= 3'b010,
		SR_ALUL= 3'b011,
		SR_ALUH= 3'b100,
		SR_IMM = 3'b101,
		SR_COM = 3'b110,
		SR_INTR= 3'b111
	} e_selr;

	typedef enum logic [1:0] {
		REG0  = 2'b00,
		REG1  = 2'b01,
		REG2  = 2'b10,
		REG3  = 2'b11
	} e_reg_addr;

	typedef enum logic [1:0] {
		ST_NONE= 2'bxx,
		ST_SKIP= 2'b00,
		ST_ADD = 2'b01,
		ST_SUB = 2'b10,
		ST_3   = 2'b11
	} e_stackop;

	typedef enum logic [2:0] {
		PC_NONE= 3'b000,
		PC_MEM = 3'b001,
		PC_IMM = 3'b010,
		PC_IMM2= 3'b011,
		PC_MEMI= 3'b100   // TODO: Maybe Memory + interrupt flag?

	} e_pcop;
	
	typedef enum logic [1:0] {
		IMO_NONE = 2'b00,
		IMO_0  	 = 2'b01,
		IMO_1  	 = 2'b10,
		IMO_2 	 = 2'b11
	} e_imo_ctl;

	typedef enum logic [1:0] {
		INTR_NONE = 2'b0?,
		INTR_WE   = 2'b10,
		INTR_RE	  = 2'b11
	} e_intr_ctl;

endpackage

interface risc8_cdi;  // Control Datapath interface	
	import risc8_pkg::*;
	import alu_pkg::*;

	// ALU
	e_alu_op alu_op;
	logic sign, alu_not;
	e_selb selb;
	e_selo selo;
	e_stackop stackop;
	e_pcop pcop;
	e_intr_ctl intr_ctl;
	logic [2:0] alu_comp;
	logic [1:0] aluf;
	
	// Register
	reg_addr a1, a2, a3;
	e_imo_ctl imoctl;
	logic rw_en, mem_h, pc_halt;
	e_selr selr;
	logic [1:0] isize; // instruction size between 1 and 4
	
	modport datapath(
		input alu_op, selb, sign, alu_not, selo, stackop, pcop,
		output alu_comp,
		input a1, a2, a3, rw_en, selr, mem_h, isize, pc_halt, imoctl, aluf,
		intr_ctl
	);
	
	modport control(
		output alu_op, selb, sign, alu_not, selo, stackop, pcop,
		input alu_comp,
		output a1, a2, a3, rw_en, selr, mem_h, isize, pc_halt, imoctl, aluf,
		intr_ctl
	);

endinterface

package risc8x_pkg;
		
	localparam word_size = 8;
	localparam reg_size = 4;

	localparam reg_addr_size = $clog2(reg_size);
	typedef logic [word_size-1:0] word;
	typedef logic [reg_addr_size-1:0] regAddr;
	
	typedef enum logic [1:0] {
		ra = 2'b00,
		rb = 2'b01,
		rc = 2'b10,
		re = 2'b11
	} e_reg;
	
	typedef enum logic [5:0] { 
		// [ xxxxxx xx xx xxxxxx ] => [ inst rd rs arg ]
		// [ xxxxxx xx xxxxxxx 	 ] => [ inst rd imm    ]
		
		// Arithmetic
		ADD  = 6'b0000_00,  // 0
		ADDI = 6'b0000_01,  // 1
		ADDU = 6'b0000_10,  // 2
		ADDUI= 6'b0000_11,  // 3
		SUB  = 6'b0001_00,  // 4
		SUBI = 6'b0001_01,  // 5
		SUBU = 6'b0001_10,  // 6
		SUBUI= 6'b0001_11,  // 7
		INC  = 6'b0010_00,  // 8
		DEC  = 6'b0010_01,  // 9
		MUL  = 6'b0010_10,  // 10
		MULI = 6'b0010_11,  // 11
		DIV  = 6'b0011_00,  // 12
		DIVI = 6'b0011_01,  // 13
		MOD  = 6'b0011_10,  // 14
		MODI = 6'b0011_11,  // 15
		
		// Logic
		AND  = 6'b0100_00,  // 16
		ANDI = 6'b0100_01,  // 17
		OR   = 6'b0100_10,  // 18
		ORI  = 6'b0100_11,  // 19
		XOR  = 6'b0101_00,  // 20
		XORI = 6'b0101_01,  // 21
		SLL  = 6'b0101_10,  // 22
		_I23 = 6'b0101_11,  // 23
		SRL  = 6'b0110_00,  // 24
		_I25 = 6'b0110_01,  // 25
		SRA  = 6'b0110_10,  // 26
		_I26 = 6'b0110_11,  // 27

		// Branching
		BGT  = 6'b0111_00,  // 28
		BGE  = 6'b0111_01,  // 29
		BEQ  = 6'b0111_10,  // 30
		BLT  = 6'b0111_11,  // 31	
		BLE  = 6'b1000_00,  // 32
		BNE  = 6'b1000_01,  // 33
		BGTZ = 6'b1000_10,  // 34
		BGEZ = 6'b1000_11,  // 35
		BEQZ = 6'b1001_00,  // 36
		BLTZ = 6'b1001_01,  // 37
		BLEZ = 6'b1001_10,  // 38
		BNEZ = 6'b1001_11,  // 39
		BGTI = 6'b1010_00,  // 40
		BGEI = 6'b1010_01,  // 41
		BEQI = 6'b1010_10,  // 42
		BLTI = 6'b1010_11,  // 43
		BLEI = 6'b1011_00,  // 44
		BNEI = 6'b1011_01,  // 45
		JMP  = 6'b1011_10,  // 46
		RJMP = 6'b1011_11,  // 47
		
		// Data move
		SWLO = 6'b1100_00,  // 48
		SWHI = 6'b1100_01,  // 49
		LWLO = 6'b1100_10,  // 50
		LWHI = 6'b1100_11,  // 51
		PUSH = 6'b1101_00,  // 52
		POP  = 6'b1101_01,  // 53
		CALL = 6'b1101_10,  // 54
		RET  = 6'b1101_11,  // 55
		
		RETI = 6'b1110_00,  // 56
		MOV  = 6'b1110_01,  // 57
		COM  = 6'b1110_10,  // 58
		COMI = 6'b1110_11,  // 59	
		IFLAG= 6'b1111_00,  // 60

		// Special
		HALT = 6'b1111_01,  // 61
		_I62 = 6'b1111_10,  // 62
		_I63 = 6'b1111_11  // 63

	} e_instr;

endpackage


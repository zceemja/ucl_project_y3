package risc_pkg;
		
	localparam word_size = 8;
	localparam mem_size = 256;
	localparam rom_size = 256;
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
	
	typedef enum logic [3:0] { 
		// [ xxxx xx xx ] => [ inst rd rs ]
		// mp: Memory page
		// cp: Co-processor, 0x00 = RAM, 0x01 = ROM, 0x02 = FPU, 0x03 = GPIO
		CPY =4'b0000,  // $rd = imm if rd == rs else $rd = $rs
		ADD =4'b0001,  // $rd = $rd + $rs
		SUB =4'b0010,  // $rd = $rd - $rs
		AND =4'b0011,  // $rd = $rd & $rsgt
		OR  =4'b0100,  // $rd = $rd | $rs
		XOR =4'b0101,  // $rd = $rd ^ $rs
		GT  =4'b0110,  // $rd = $rd > $rs
		EXT =4'b0111,  // rs 00: shift left; 01: shift right; 10: rotate right; 
		LW  =4'b1000,  // $rd = mem[$mp + $rs]
		SW  =4'b1001,  // mem[$mp + $rs] = $rd
		JEQ =4'b1010,  // Jump to imm if $rd == $rs
		JMP =4'b1011,  // Jump to case rs 00: $rd  01: imm 10: $rd+imm 11: ??
		SET =4'b1100,  // Set memory page $mp = $rd
		SCO =4'b1101,  // Set co-processor $cp = $rs
		PUSH=4'b1110,  // Push $rd to top of stack
		POP =4'b1111   // Pop stack to $rd
	} e_instr;

	typedef enum logic [1:0] {
		AEX_SHFL = 2'b00,
		AEX_SHFR = 2'b01,
		AEX_ROTR = 2'b10,
		AEX_3	 = 2'b11
	} e_alu_ext_op;
	
endpackage

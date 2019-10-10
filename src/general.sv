package project_pkg;
		
	localparam word_size = 8;
	localparam mem_size = 8;
	localparam rom_size = 256;
	localparam reg_size = 4;

	localparam reg_addr_size = $clog2(reg_size);
	typedef logic [word_size-1:0] word;
	typedef logic [reg_addr_size-1:0] regAddr;
	
	typedef enum logic [1:0] {
		RegA = 2'b00,
		RegB = 2'b01,
		RegC = 2'b10,
		RegD = 2'b11
	} e_reg;
	
	typedef enum logic [3:0] { 
		NOP =4'h0,	// No operation
		ADD =4'h1,  // $rs = $rs + $rt
		ADDI=4'h2,  // $rs = $rs + $imm
		SUB =4'h3,  // $rs = $rs - $rt
		AND =4'h4,  // $rs = $rs & $rt
		OR  =4'h5,  // $rs = $rs | $rt
		NOT =4'h6,  // $rs = ~$rt
		LW  =4'h7,  // Load word from $rt to $rs
		SW  =4'h8,  // Save word from $rt to $rs
		WO  =4'h9,  // Write $rs to output
		RO  =4'hA,  // Read output to $rs
		COPY=4'hB,  // $rs = $rt
		JEQ =4'hC,  // Jump to $imm if $rs == $rt
		ZERO=4'hD,  // $rs = 0x00
		__0 =4'hE,  //
		__1 =4'hF   //		
	} e_instr;
	
	typedef enum logic [2:0] { 
		ALU_ADD=3'b000,
		ALU_SUB=3'b001,
		ALU_AND=3'b010,
		ALU_OR =3'b011,
		ALU_SLT=3'b100,
		ALU_NOT=3'b101,
		ALU___0=3'b110,
		ALU_NOP=3'b111
	} e_alu_op;
	
	
endpackage

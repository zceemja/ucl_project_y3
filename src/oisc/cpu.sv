`include "oisc.sv"
`include "../const.sv"
import oisc8_pkg::*;


module oisc8_cpu(processor_port port);
	
	IBus bus0(port.clk, port.rst);
	//assign bus.clk = port.clk;
	//assign bus.rst = port.rst;
	//oconn oc(port, bus0.host);	
	// NULL block always return 0 and ignores input.
	//Port #() p_null0(
	//		.bus(bus0),
	//		.data_to_bus(8'd0)
	//);
	//Port #(.ADDR)
	//PortOutput p_null(.bus(bus0.port),.data_to_bus(`DWIDTH'd0));
	PortReg#(.ADDR_SRC(REG0R), .ADDR_DST(REG0)) p_reg0(.bus(bus0.port));
	PortReg#(.ADDR_SRC(REG1R), .ADDR_DST(REG1)) p_reg1(.bus(bus0.port));
	pc_block#(.PROGRAM("../../memory/oisc8.text")) pc0(bus0.port, bus0.iport);
	alu_block alu0(bus0.port);
	mem_block ram0(bus0.port, port);
	oisc_com_block com0(bus0.port, port);

endmodule

module pc_block(IBus.port bus, IBus.iport port);

	wire[`SAWIDTH+`DAWIDTH:0] instr;

	assign port.imm = instr[`DAWIDTH+`SAWIDTH];
	assign port.instr_dst = e_iaddr_dst'(instr[`DAWIDTH+`SAWIDTH-1:`SAWIDTH]);
	assign port.instr_src = e_iaddr_src'(port.imm ? `SAWIDTH'd0 : instr[`SAWIDTH-1:0]);
	
	reg write_null;	
	always_comb write_null = (bus.instr_src == `SAWIDTH'd0) & ~port.imm;
	data_buf dbus0(bus, 0, write_null);	
	data_buf dbus1(bus, instr[`DWIDTH-1:0], port.imm);	
	//genvar i;
	//generate 
	//	for(i=0;i<`DWIDTH;i=i+1) begin : generate_imm_to_data
	//		bufif1(bus.data[i], instr[i], port.imm);
	//	end 
	//endgenerate
	
	//generate 
	//	for(i=0;i<`DWIDTH;i=i+1) begin : generate_null_to_data
	//		bufif1(bus.data[i], 0, write_null);
	//	end 
	//endgenerate
	
	parameter PROGRAM = "";
	reg[15:0] pc, pcn, pcr; // Program counter
	reg[15:0] pointer;  // Instruction pointer accumulator
	reg[7:0] comp_acc;  // Compare accumulator
	reg comp_zero;

	/* ====================
	*       ROM BLOCK
	   ==================== */
	`ifdef SYNTHESIS
	m9k_rom#(
			.PROGRAM({PROGRAM, ".mif"}), 
			.NAME("rom0"),
			.WIDTH(16),
			.NUMWORDS(2048)
	)
	`else
	pseudo_rom#(
			.PROGRAM({PROGRAM, ".mem"}), 
			.WIDTH(16),
	 		.NUMWORDS(2048)
	) 
	`endif
		rom0(pc[12:0], bus.clk, instr[12:0]);


	`ifndef SYNTHESIS
	reg [15:0] pcp;  // Current program counter for debugging
	`endif 

	always_comb comp_zero = comp_acc == `DWIDTH'd0;
	//assign pcn = comp_zero|bus.rst ? pointer : pc + 1;
	assign pcn = pc + 1;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) begin 
			pcr <= 0;
		end
		else begin 
			`ifndef SYNTHESIS
			pcp <= pc;
			`endif 
			pcr <= pcn;
		end
	end
	assign pc = ~comp_zero|bus.rst ? pcr: pointer; 	
	PortReg#(.ADDR_SRC(BRPT0R), .ADDR_DST(BRPT0)) p_brpt0(
			.bus(bus),.register(pointer[7:0]),.wr(),.rd()
	);
	PortReg#(.ADDR_SRC(BRPT1R), .ADDR_DST(BRPT1)) p_brpt1(
			.bus(bus),.register(pointer[15:8]),.wr(),.rd()
	);
	PortInput#(.ADDR(BRZ), .DEFAULT(`DWIDTH'hFF)) p_brz(
			.bus(bus),.data_from_bus(comp_acc)
	);
	PortOutput#(.ADDR(PC0)) p_pc0(.bus(bus),.data_to_bus(pcn[7:0]));
	PortOutput#(.ADDR(PC1)) p_pc1(.bus(bus),.data_to_bus(pcn[15:8]));

endmodule

module oisc_com_block(IBus.port bus, processor_port port);
	
	// ========================
	// 		COMMUNICATIONS
	// ========================

	reg [7:0] addr;
	reg wr,rd;
	assign port.com_addr = wr|rd ? addr : 8'd0;
	//PortReg#(.ADDR_SRC(COMAR), .ADDR_DST(COMA)) p_coma(
	//		.bus(bus),.register(addr),.wr(),.rd()
	//);
	PortInputFF#(.ADDR(COMA)) p_coma(.bus(bus),.data_from_bus(addr));
	PortInput#(.ADDR(COMD)) p_comd(
			.bus(bus),.data_from_bus(port.com_wr),.wr(wr)
	);
	PortOutput#(.ADDR(COMDR)) p_comdr(
			.bus(bus),.data_to_bus(port.com_rd),.rd(rd)
	);
endmodule

module mem_block(IBus.port bus, processor_port port);
	reg w0,w1,w2,wd0,wd1;
	reg [15:0] data, cached, cached0;
	reg [23:0] pointer;

	PortReg#(.ADDR_SRC(MEMPT0R), .ADDR_DST(MEMPT0)) p_mempt0(
			.bus(bus),
			.register(pointer[7:0]),
			.wr(w0)
	);
	PortReg#(.ADDR_SRC(MEMPT1R), .ADDR_DST(MEMPT1)) p_mempt1(
			.bus(bus),
			.register(pointer[15:8]),
			.wr(w1)
	);
	PortReg#(.ADDR_SRC(MEMPT2R), .ADDR_DST(MEMPT2)) p_mempt2(
			.bus(bus),
			.register(pointer[23:16]),
			.wr(w2)
	);
	
	PortInput#(.ADDR(MEMSWLO)) p_mem0sw(.bus(bus),.data_from_bus(data[7:0]),.wr(wd0));	
	PortInput#(.ADDR(MEMSWHI)) p_mem1sw(.bus(bus),.data_from_bus(data[15:8]),.wr(wd1));
    
	PortOutput#(.ADDR(MEMLWLO)) p_mem0lw(.bus(bus),.data_to_bus(cached[7:0]));
	PortOutput#(.ADDR(MEMLWHI)) p_mem1lw(.bus(bus),.data_to_bus(cached[15:8]));

	// ========================
	// 			STACK
	// ========================
	reg st_push_en, st_pop_en, st_pop_en0, st_pop_en1;
	reg[`DWIDTH-1:0] st_push, st_cache, st_cache0;
	reg[15:0] stp, stpp, stpp2;  // stack pointer

	assign stpp = stp + (st_pop_en ? 16'h0001 : 16'hFFFF);
	assign stpp2 = stp + 16'h0002;
	assign st_cache = ~st_pop_en1|bus.rst ? st_cache0 : port.ram_rd_data;
	assign st_pop_en = st_pop_en0 & ~bus.imm;	

	always_ff@(posedge bus.clk) begin
		if(bus.rst) begin
			st_cache0 <= 16'd0;
			stp <= 16'd`RAM_SIZE-1;
		end else begin
			st_pop_en1 <= st_pop_en; // Delayed by 1
				 if(st_push_en) st_cache0 <= st_push;
			else if(st_pop_en1) st_cache0 <= port.ram_rd_data;
			if(st_push_en|st_pop_en) stp <= stpp;
		end
	end

	PortInput#(.ADDR(STACK)) p_push(
		.bus(bus),
		.data_from_bus(st_push),
		.wr(st_push_en)
	);
	PortOutput#(.ADDR(STACKR)) p_pop(
		.bus(bus),
		.data_to_bus(st_cache),
		.rd(st_pop_en0)
	);
  	reg rd_en0;

	always_comb begin
		cached = (rd_en0) ? port.ram_rd_data : cached0;
		//port.ram_wr_data = ram_wr_data;
		//cachedLo = (rd_en0) ? port.ram_rd_data[7:0] : cached0[7:0];
		//cachedHi = (rd_en0) ? port.ram_rd_data[15:8] : cached0[15:8];

		`ifdef SYNTHESIS
		port.ram_rd_en = w0|w1|w2|st_pop_en;
		port.ram_wr_en = wd0|wd1|st_push_en;
		casez({wd0,wd1,st_push_en})
    		3'b100: port.ram_wr_data = {cached[15:8],data[7:0]};
    		3'b?10: port.ram_wr_data = {data[15:8],cached[7:0]};
    		3'b??1: port.ram_wr_data = {8'd0,st_push};
			default: port.ram_wr_data = 16'bx;
		endcase
		casez({st_push_en,st_pop_en})
			2'b00: port.ram_addr = pointer;
			2'b10: port.ram_addr = {8'hFF, stp};
			2'b?1: port.ram_addr = {8'hFF, stpp2};
			default: port.ram_addr = 24'bx;
		endcase
		`else
		force port.ram_rd_en = w0|w1|w2|st_pop_en;
		force port.ram_wr_en = wd0|wd1|st_push_en;
		casez({wd0,wd1,st_push_en})
    		3'b100: force port.ram_wr_data = {cached[15:8],data[7:0]};
    		3'b?10: force port.ram_wr_data = {data[15:8],cached[7:0]};
    		3'b??1: force port.ram_wr_data = {8'd0,st_push};
			default: force port.ram_wr_data = 16'bx;
		endcase
		casez({st_push_en,st_pop_en})
			2'b00: force port.ram_addr = pointer;
			2'b10: force port.ram_addr = {8'hFF, stp};
			2'b?1: force port.ram_addr = {8'hFF, stpp2};
			default: force port.ram_addr = 24'bx;
		endcase
		`endif
	end

	//assign port.ram_wr_data = st_push_en ? {8'd0,st_push} : cached0;
	//assign port.ram_addr = 
	//	st_push_en ? {8'hFF, stp} :
	//	(st_pop_en ? {8'hFF, stpp2} : pointer);
	
	always_ff@(posedge bus.clk) begin
		if(bus.rst) begin
			cached0 <= 16'd0;
			rd_en0 <= 1'b0;
		end else begin
			casez({wd0,wd1,rd_en0})
				3'b1?0: cached0[7:0] <= data[7:0];
				3'b?10: cached0[15:8] <= data[15:8];
				3'b001: cached0 <= port.ram_rd_data;
				3'b101: cached0 <= {port.ram_rd_data[15:8],data[7:0]};
				3'b011: cached0 <= {data[15:8],port.ram_rd_data[7:0]};
				3'b11?: cached0 <= data;
			endcase
			rd_en0 <= w0|w1|w2; 
		end
	end
endmodule

module alu_block(IBus.port bus);
	logic [`DWIDTH-1:0] acc0, acc1;	
	//PortReg#(.ADDR_SRC(ALUACC0R), .ADDR_DST(ALUACC0)) p_aluacc0(
	//		.bus(bus),.data_from_bus(acc0),.data_to_bus(acc0),.wr(),.rd());
	//PortReg#(.ADDR_SRC(ALUACC1R), .ADDR_DST(ALUACC1)) p_aluacc1(
	//		.bus(bus),.data_from_bus(acc1),.data_to_bus(acc1),.wr(),.rd());
	PortNReg#(ALUACC0, ALUACC0R) p_aluacc0(.bus(bus),.register(acc0));
	PortNReg#(ALUACC1, ALUACC1R) p_aluacc1(.bus(bus),.register(acc1));

	//carry_lookahead_adder#(.WIDTH(`DWIDTH)) alu_adder0(acc0,acc1,reg_add);
	wire [`DWIDTH-1:0] reg_add;
	wire reg_addc, add_rd;
	assign {reg_addc,reg_add} = acc0 + acc1;
	PortOutputFF#(.ADDR(ADD)) p_add(.bus(bus),.data_to_bus(reg_add),.rd(add_rd));
	PortOutput#(.ADDR(ADDC)) p_addc(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},reg_addc}));

	reg reg_adcc, reg_adcc0, adc_rd;
	wire [`DWIDTH-1:0] reg_adc;
	assign {reg_adcc0, reg_adc} = acc0 + acc1 + reg_adcc;
	PortOutput#(.ADDR(ADC)) p_adc(.bus(bus),.data_to_bus(reg_adc),.rd(adc_rd));
	always_ff@(posedge bus.clk) begin
			if(add_rd) reg_adcc <= reg_addc;
			else if(adc_rd) reg_adcc <= reg_adcc0;
	end

	wire [`DWIDTH-1:0] reg_sub;
	wire reg_subc;
	assign {reg_subc,reg_sub} = acc0 - acc1;
	PortOutputFF#(.ADDR(SUB)) p_sub(.bus(bus),.data_to_bus(reg_sub),.rd(sub_rd));
	PortOutput#(.ADDR(SUBC)) p_subc(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},reg_subc}));
	
	reg reg_sbcc, reg_sbcc0, sbc_rd;
	wire [`DWIDTH-1:0] reg_sbc;
	assign {reg_sbcc0, reg_sbc} = acc0 - acc1 - reg_sbcc;
	PortOutput#(.ADDR(SBC)) p_sbc(.bus(bus),.data_to_bus(reg_sbc),.rd(sbc_rd));
	always_ff@(posedge bus.clk) begin
			if(sub_rd) reg_sbcc <= reg_subc;
			else if(sbc_rd) reg_sbcc <= reg_sbcc0;
	end

	wire [`DWIDTH-1:0] reg_and, reg_or, reg_xor; 
	assign reg_and = acc0 & acc1;
	assign reg_or  = acc0 | acc1;
	assign reg_xor = acc0 ^ acc1;
	PortOutputFF#(.ADDR(AND)) p_and(.bus(bus),.data_to_bus(reg_and));
	PortOutputFF#(.ADDR(OR)) p_or(.bus(bus),.data_to_bus(reg_or));
	PortOutputFF#(.ADDR(XOR)) p_xor(.bus(bus),.data_to_bus(reg_xor));

	wire [`DWIDTH-1:0] reg_sll, reg_srl; 
	assign reg_sll = acc0 << acc1[$clog2(`DWIDTH)-1:0];
	assign reg_srl = acc0 >> acc1[$clog2(`DWIDTH)-1:0];
	PortOutputFF#(.ADDR(SLL)) p_sll(.bus(bus),.data_to_bus(reg_sll));
	PortOutputFF#(.ADDR(SRL)) p_srl(.bus(bus),.data_to_bus(reg_srl));
	
	PortOutputFF#(.ADDR(EQ)) p_eq(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},acc0==acc1}));
	PortOutputFF#(.ADDR(GT)) p_gt(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},acc0> acc1}));
	PortOutputFF#(.ADDR(GE)) p_ge(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},acc0>=acc1}));
	
	PortOutputFF#(.ADDR(NE)) p_ne(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},acc0!=acc1}));
	PortOutputFF#(.ADDR(LT)) p_lt(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},acc0< acc1}));
	PortOutputFF#(.ADDR(LE)) p_le(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},acc0<=acc1}));
	
	wire [`DWIDTH*2-1:0] reg_mul;
	assign reg_mul = acc0 * acc1;
	PortOutputFF#(.ADDR(MULLO)) p_mul0(.bus(bus),.data_to_bus(reg_mul[`DWIDTH-1:0]));
	PortOutputFF#(.ADDR(MULHI)) p_mul1(.bus(bus),.data_to_bus(reg_mul[`DWIDTH*2-1:`DWIDTH]));
	

	wire [`DWIDTH-1:0] reg_div, reg_mod; 
	assign reg_div = acc0 / acc1;
	assign reg_mod = acc0 % acc1;
	PortOutputFF#(.ADDR(DIV)) p_div(.bus(bus),.data_to_bus(reg_div));
	PortOutputFF#(.ADDR(MOD)) p_mod(.bus(bus),.data_to_bus(reg_mod));

endmodule


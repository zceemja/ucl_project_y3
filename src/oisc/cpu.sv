`ifndef DEFINED
`define DEFINED
`include "oisc.sv"
`include "../const.sv"
`endif
`include "romblock.sv"

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
	reg [`DWIDTH-1:0] reg0, reg1;
	PortReg#(.ADDR_SRC(REG0R), .ADDR_DST(REG0)) p_reg0(.bus(bus0.port),.register(reg0));
	PortReg#(.ADDR_SRC(REG1R), .ADDR_DST(REG1)) p_reg1(.bus(bus0.port),.register(reg1));
	
	`ifdef DEBUG
	sys_sp#("REG0", `DWIDTH) sys_reg0(reg0);
	sys_sp#("REG1", `DWIDTH) sys_reg1(reg1);
	`endif

	pc_block#(.PROGRAM({`ROMDIR, "oisc8.text"})) pc0(bus0.port, bus0.iport);
	alu_block alu0(bus0.port);
	mem_block ram0(bus0.port, port);
	oisc_com_block com0(bus0.port, port);

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
	
	`ifdef DEBUG
	sys_sp#("COMA", 8) sys_coma(addr);
	sys_sp#("COMW", 8) sys_comw(port.com_wr);
	sys_sp#("COMR", 8) sys_comd(port.com_rd);
	`endif
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
	
	`ifdef DEBUG
	sys_sp#("MEMP", 24) sys_memp(pointer);
	sys_sp#("MEMC", 16) sys_memc(cached);
	`endif
	
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
	
	`ifdef DEBUG
	sys_sp#("STP", 16) sys_stp(stp);
	`endif

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

	`ifdef DEBUG
	sys_sp#("ALU0", `DWIDTH) sys_alu0(acc0);
	sys_sp#("ALU1", `DWIDTH) sys_alu1(acc1);
	`endif

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

	// ==================
	// Shifts and rotates
	// ==================
	reg [`DWIDTH-1:0] w_sll, w_srl, w_sllc, w_srlc, w_rol, w_ror, w_rolc, w_rorc, rolr, rorr;
	reg [`DWIDTH-1:0] reg_sllc,reg_srlc; 
	wire [1:0] sll_en, srl_en;
	always_ff@(posedge bus.clk) begin
			if(bus.rst) begin
				reg_sllc <= 1'b0;
				reg_srlc <= 1'b0;
			end else begin
				if(sll_en[0]) reg_sllc <= w_sllc;
				//if(sll_en[0]|sll_en[1]) reg_sllc <= w_sllc;
				//if(~sll_en[0]|sll_en[1]) reg_sllc <= w_rolc;
				if(srl_en[0]) reg_srlc <= w_srlc;
				//if(srl_en[0]|srl_en[1]) reg_srlc <= w_srlc;
				//if(~srl_en[0]|srl_en[1]) reg_srlc <= w_rorc;
			end
	end

	always_comb case(acc1[$clog2(`DWIDTH)-1:0])
		3'd0: {w_sllc,w_sll} = {8'd0,acc0};
		3'd1: {w_sllc,w_sll} = {7'd0,acc0,1'd0};
		3'd2: {w_sllc,w_sll} = {6'd0,acc0,2'd0};
		3'd3: {w_sllc,w_sll} = {5'd0,acc0,3'd0};
		3'd4: {w_sllc,w_sll} = {4'd0,acc0,4'd0};
		3'd5: {w_sllc,w_sll} = {3'd0,acc0,5'd0};
		3'd6: {w_sllc,w_sll} = {2'd0,acc0,6'd0};
		3'd7: {w_sllc,w_sll} = {1'd0,acc0,7'd0};
		default: {w_sllc,w_sll} = {acc0,8'd0};
	endcase
	
	always_comb case(acc1[$clog2(`DWIDTH)-1:0])
		3'd0: {w_srl,w_srlc} = {acc0,8'd0};
		3'd1: {w_srl,w_srlc} = {1'd0,acc0,7'd0};
		3'd2: {w_srl,w_srlc} = {2'd0,acc0,6'd0};
		3'd3: {w_srl,w_srlc} = {3'd0,acc0,5'd0};
		3'd4: {w_srl,w_srlc} = {4'd0,acc0,4'd0};
		3'd5: {w_srl,w_srlc} = {5'd0,acc0,3'd0};
		3'd6: {w_srl,w_srlc} = {6'd0,acc0,2'd0};
		3'd7: {w_srl,w_srlc} = {6'd0,acc0,1'd0};
		default: {w_srl,w_srlc} = {8'd0,acc0};
	endcase
	//assign {w_sllc,w_sll} = acc0 << acc1[$clog2(`DWIDTH)-1:0];
	//assign {w_srl,w_srlc} = acc0 >> acc1[$clog2(`DWIDTH)-1:0];
    
	//reg [`DWIDTH-1:0] mask_r, mask_l;

	//// FIXME: write generator
	//always_comb case(acc1[$clog2(`DWIDTH)-1:0])
	//	3'd1: mask_l = 8'b11111111;
	//	3'd0: mask_l = 8'b11111110;
	//	3'd1: mask_l = 8'b11111100;
	//	3'd3: mask_l = 8'b11111000;
	//	3'd4: mask_l = 8'b11110000;
	//	3'd5: mask_l = 8'b11100000;
	//	3'd6: mask_l = 8'b11000000;
	//	3'd7: mask_l = 8'b10000000;
	//	default: mask_l = 8'd0;
	//endcase	
	//always_comb case(acc1[$clog2(`DWIDTH)-1:0])
	//	3'd1: mask_r = 8'b11111111;
	//	3'd0: mask_r = 8'b01111111; 
	//	3'd1: mask_r = 8'b00111111; 
	//	3'd3: mask_r = 8'b00011111; 
	//	3'd4: mask_r = 8'b00001111; 
	//	3'd5: mask_r = 8'b00000111; 
	//	3'd6: mask_r = 8'b00000011; 
	//	3'd7: mask_r = 8'b00000001; 
	//	default: mask_r = 8'd0;
	//endcase	
    //genvar i;
    //generate
	//	always_comb case(acc1[$clog2(`DWIDTH)])
	//	for (i=0; i < `DWIDTH-1; i++) begin : generate_mask_r
	//		 i: mask_r = 2**i-1;
	//	end
	//	endcase
    //endgenerate

	//assign {w_rolc,w_rol} = acc0 << acc1[$clog2(`DWIDTH)-1:0];
	//assign {w_ror,w_rorc} = acc0 >> acc1[$clog2(`DWIDTH)-1:0];

	//assign rolr = (w_sll&mask_l)|(sll_en[0]|sll_en[1]?w_sllc:reg_sllc);	
	//assign rorr = (w_srl&mask_r)|(srl_en[0]|srl_en[1]?w_srlc:reg_srlc);	

	PortOutputFF#(.ADDR(SLL)) p_sll(.bus(bus),.data_to_bus(w_sll),.rd(sll_en[0]));
	PortOutputFF#(.ADDR(SRL)) p_srl(.bus(bus),.data_to_bus(w_srl),.rd(srl_en[0]));
	PortOutput#(.ADDR(ROL)) p_rol(.bus(bus),.data_to_bus(reg_sllc));
	PortOutput#(.ADDR(ROR)) p_ror(.bus(bus),.data_to_bus(reg_srlc));
	
	//PortOutputFF#(.ADDR(ROL)) p_rol(.bus(bus),.data_to_bus(rolr),.rd(sll_en[1]));
	//PortOutputFF#(.ADDR(ROR)) p_ror(.bus(bus),.data_to_bus(rorr),.rd(srl_en[1]));
	
	// =================
	// Compare registers
	// =================
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


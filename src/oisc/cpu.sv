`include "oisc.sv"
`include "../const.sv"
import oisc8_pkg::*;


module oisc8_cpu(processor_port port);
	
	wire[`SAWIDTH+`DAWIDTH:0] instr0;
	IBus bus0(port.clk, port.rst, instr0);
	//assign bus.clk = port.clk;
	//assign bus.rst = port.rst;
	//oconn oc(port, bus0.host);	
	// NULL block always return 0 and ignores input.
	//Port #() p_null0(
	//		.bus(bus0),
	//		.data_to_bus(8'd0)
	//);
	//Port #(.ADDR)
	PortOutput p_null(.bus(bus0.port),.data_to_bus(`DWIDTH'd0));
	pc_block#(.PROGRAM("../../memory/oisc8.text")) pc0(bus0.port, instr0);
	alu_block alu0(bus0.port);
	mem_block ram0(bus0.port, port);
	oisc_com_block com0(bus0.port, port);

endmodule

module pc_block(
		IBus.port bus, 
		output wire[`SAWIDTH+`DAWIDTH:0] instr
	);

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

	assign comp_zero = comp_acc == 0;
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
	assign pc = (comp_zero) ? pointer : pcr; 	

	PortReg#(.ADDR_SRC(BRPT0R), .ADDR_DST(BRPT0)) p_brpt0(
			.bus(bus),.data_from_bus(pointer[7:0]),.data_to_bus(pointer[7:0]),.wr(),.rd()
	);
	PortReg#(.ADDR_SRC(BRPT1R), .ADDR_DST(BRPT1)) p_brpt1(
			.bus(bus),.data_from_bus(pointer[15:8]),.data_to_bus(pointer[15:8]),.wr(),.rd()
	);
	PortInputSeq#(.ADDR(BRZ), .DEFAULT(`DWIDTH'hFF)) p_brz(
			.bus(bus),.data_from_bus(comp_acc)
	);

endmodule

module oisc_com_block(IBus.port bus, processor_port port);
	reg [7:0] addr;
	reg wr,rd;
	assign port.com_addr = wr|rd ? addr : 8'd0;
	PortReg#(.ADDR_SRC(COMAR), .ADDR_DST(COMA)) p_coma(
			.bus(bus),.data_from_bus(addr),.data_to_bus(addr),.wr(),.rd()
	);
	PortInputSeq#(.ADDR(COMD)) p_comd(
			.bus(bus),.data_from_bus(port.com_wr),.wr(wr)
	);
	PortOutput#(.ADDR(COMDR)) p_comdr(
			.bus(bus),.data_to_bus(port.com_rd),.rd(rd)
	);
endmodule

module mem_block(IBus.port bus, processor_port port);
	reg w0,w1,w2,wd0,wd1;
	reg [15:0] data, cached;
	reg [23:0] pointer;
	always_ff@(posedge bus.clk) begin 
		if(port.ram_rd_en) cached <= port.ram_rd_data;
		else if(port.ram_wr_en) cached <= data;
	end

	PortRegSeq#(.ADDR_SRC(MEMPT0R), .ADDR_DST(MEMPT0)) p_mempt0(
			.bus(bus),
			.data_from_bus(pointer[7:0]),
			.data_to_bus(pointer[7:0]),
			.wr(w0)
	);
	PortRegSeq#(.ADDR_SRC(MEMPT1R), .ADDR_DST(MEMPT1)) p_mempt1(
			.bus(bus),
			.data_from_bus(pointer[15:8]),
			.data_to_bus(pointer[15:8]),
			.wr(w1)
	);
	PortRegSeq#(.ADDR_SRC(MEMPT2R), .ADDR_DST(MEMPT2)) p_mempt2(
			.bus(bus),
			.data_from_bus(pointer[23:16]),
			.data_to_bus(pointer[23:16]),
			.wr(w2)
	);
	
	PortRegSeq#(.ADDR_SRC(MEMLWLO), .ADDR_DST(MEMSWLO)) p_mem0(
			.bus(bus),
			.data_from_bus(data[7:0]),
			.data_to_bus(cached[7:0]),
			.wr(wd0)
	);
	PortRegSeq#(.ADDR_SRC(MEMLWHI), .ADDR_DST(MEMSWHI)) p_mem1(
			.bus(bus),
			.data_from_bus(data[15:8]),
			.data_to_bus(cached[15:8]),
			.wr(wr1)
	);

	// ========================
	// 			STACK
	// ========================
	reg st_push_en, st_pop_en, st_pop_en0;
	reg[`DWIDTH-1:0] st_push, st_cache;
	reg[15:0] stp, stpp, stpp2;  // stack pointer
	assign stpp = stp + (st_pop_en ? 16'h0001 : 16'hFFFF);
	assign stpp2 = stp + 16'h0002;
	always_latch begin
		if(bus.rst) st_cache <= 16'd0;
		else if(st_push_en) st_cache <= st_push;
		else if(st_pop_en0) st_cache <= port.ram_rd_data;
	end
	always_ff@(posedge bus.clk) begin
		if(bus.rst) begin 
			stp <= 16'd`RAM_SIZE-1;
		end else begin
			st_pop_en0 <= st_pop_en; // Delayed by 1
			if(st_push_en|st_pop_en) stp <= stpp;
		end
	end
	PortInputSeq#(.ADDR(STACK)) p_push(
		.bus(bus),
		.data_from_bus(st_push),
		.wr(st_push_en)
	);
	PortOutput#(.ADDR(STACKR)) p_pop(
		.bus(bus),
		.data_to_bus(st_cache),
		.rd(st_pop_en)
	);

	assign port.ram_rd_en = w0|w1|w2|st_pop_en;
	assign port.ram_wr_en = wd0|st_push_en;
	assign port.ram_wr_data = st_push_en ? {8'd0,st_push} : data;
	assign port.ram_addr = 
		st_push_en ? {8'hFF, stp} :
		(st_pop_en ? {8'hFF, stpp2} : pointer);

		//if(st_push_en) port.ram_addr = {8'hFF, stp};	 
		//if(st_pop_en)  port.ram_addr = {8'hFF, stpp};
		//case({st_push_en,st_pop_en})
		//	2'b00: port.ram_addr = pointer;
		//	//2'b10: port.ram_addr = {8'hFF, stp};	
		//	//2'b?1: port.ram_addr = {8'hFF, stpp};	
		//endcase
	//end
endmodule

module alu_block(IBus.port bus);
	logic [`DWIDTH-1:0] acc0, acc1;	
	
	PortReg#(.ADDR_SRC(ALUACC0R), .ADDR_DST(ALUACC0)) p_aluacc0(
			.bus(bus),.data_from_bus(acc0),.data_to_bus(acc0),.wr(),.rd());
	PortReg#(.ADDR_SRC(ALUACC1R), .ADDR_DST(ALUACC1)) p_aluacc1(
			.bus(bus),.data_from_bus(acc1),.data_to_bus(acc1),.wr(),.rd());

	logic [`DWIDTH:0] reg_add;
	//carry_lookahead_adder#(.WIDTH(`DWIDTH)) alu_adder0(acc0,acc1,reg_add);
	assign reg_add = acc0 + acc1;
	PortOutput#(.ADDR(ADD)) p_add(.bus(bus),.data_to_bus(reg_add[`DWIDTH-1:0]));
	PortOutput#(.ADDR(ADDC)) p_addc(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},reg_add[`DWIDTH]}));

	logic [`DWIDTH-1:0] reg_sub;
	logic reg_sub_c;
	assign {reg_sub_c,reg_sub} = acc0 - acc1;
	PortOutput#(.ADDR(SUB)) p_sub(.bus(bus),.data_to_bus(reg_sub));
	PortOutput#(.ADDR(SUBC)) p_subc(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},reg_sub_c}));

	logic [`DWIDTH-1:0] reg_and, reg_or, reg_xor; 
	assign reg_and = acc0 & acc1;
	assign reg_or  = acc0 | acc1;
	assign reg_xor = acc0 ^ acc1;
	PortOutput#(.ADDR(AND)) p_and(.bus(bus),.data_to_bus(reg_and));
	PortOutput#(.ADDR(OR)) p_or(.bus(bus),.data_to_bus(reg_or));
	PortOutput#(.ADDR(XOR)) p_xor(.bus(bus),.data_to_bus(reg_xor));

	logic [`DWIDTH-1:0] reg_sll, reg_srl; 
	assign reg_sll = acc0 << acc1[$clog2(`DWIDTH)-1:0];
	assign reg_srl = acc0 >> acc1[$clog2(`DWIDTH)-1:0];
	PortOutput#(.ADDR(SLL)) p_sll(.bus(bus),.data_to_bus(reg_sll));
	PortOutput#(.ADDR(SRL)) p_srl(.bus(bus),.data_to_bus(reg_srl));
	
	logic reg_eq, reg_gt, reg_ge;
	assign reg_eq = acc0 == acc1;
	assign reg_gt = acc0 >  acc1;
	assign reg_ge = acc0 >= acc1;
	PortOutput#(.ADDR(EQ)) p_eq(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},reg_eq}));
	PortOutput#(.ADDR(GT)) p_gt(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},reg_gt}));
	PortOutput#(.ADDR(GE)) p_ge(.bus(bus),.data_to_bus({{`DWIDTH-1{1'b0}},reg_ge}));
	
	logic [`DWIDTH*2-1:0] reg_mul;
	assign reg_mul = acc0 * acc1;
	PortOutput#(.ADDR(MULLO)) p_mul0(.bus(bus),.data_to_bus(reg_mul[`DWIDTH-1:0]));
	PortOutput#(.ADDR(MULHI)) p_mul1(.bus(bus),.data_to_bus(reg_mul[`DWIDTH*2-1:`DWIDTH]));
	

	logic [`DWIDTH-1:0] reg_div, reg_mod; 
	assign reg_div = acc0 / acc1;
	assign reg_mod = acc0 % acc1;
	PortOutput#(.ADDR(DIV)) p_div(.bus(bus),.data_to_bus(reg_div));
	PortOutput#(.ADDR(MOD)) p_mod(.bus(bus),.data_to_bus(reg_mod));

endmodule


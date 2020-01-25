
module pc_block(IBus bus);
	parameter PROGRAM = "";
	reg[15:0] pc, pcn; // Program counter

	reg[15:0] pointer;  // Instruction pointer accumulator
	reg[7:0] comp_acc;  // Compare accumulator
	reg comp_acc_rst, comp_zero;
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
		rom0(pcn[11:0], bus.clk, bus.instr);
	
	assign comp_zero = comp_acc == 0;
	assign pcn = comp_zero ? pointer : pc + 1;
	always_ff@(posedge bus.clk) begin
		if(bus.rst) begin 
			pc <= 0;
			comp_acc_rst <= 0;
		end
		else begin 
			pc <= pcn;
			comp_acc_rst <= comp_zero;
		end
	end
	/* ====================
	*      BRANCH PART
	   ==================== */
		
	PortInput #(.ADDR(BRPT0)) p_brpt0_0(
			.bus(bus),
			.data_from_bus(pointer[7:0])
	);
	PortInput #(.ADDR(BRPT1)) p_brpt1_0(
			.bus(bus),
			.data_from_bus(pointer[15:8])
	);	
	PortInput #(.ADDR(BRZ), .DEFAULT(8'hFF)) p_brz_0(
			.bus(bus),
			.data_from_bus(comp_acc),
			.reset(comp_acc_rst)
	);

endmodule

module alu_block(IBus bus);
	reg[7:0] acc0, acc1;
	logic add_carry, sub_carry;
	PortComb #(.ADDR(ACC), .ADDRI(ACCI)) p_acc0(
			.bus(bus),
			.data_from_bus(acc),
			.data_to_bus(acc)
	);
	/* ====================
	*     ADD / SUBTRACT
	   ==================== */
	reg[7:0] add_input;
	reg[7:0] add_output;
	assign {add_carry,add_output} = add_input + acc;
	PortCombDual #(.ADDR(ADD), .ADDRI(ADDI)) p_add0(
			.bus(bus),
			.data_from_bus(add_input),
			.data_to_bus(add_output),
			.data_to_bus_i({7'd0, add_carry})
	);
	
	reg[7:0] sub_input;
	reg[7:0] sub_output;
	assign {sub_carry,sub_output} = sub_input - acc;
	PortCombDual #(.ADDR(SUB), .ADDRI(SUBI)) p_sub0(
			.bus(bus),
			.data_from_bus(sub_input),
			.data_to_bus(sub_output),
			.data_to_bus_i({7'd0, sub_carry})
	);

	/* ====================
	*        AND / OR
	   ==================== */

	reg[7:0] andor_input;
	reg[7:0] and_output;
	reg[7:0] or_output;
	assign and_output = andor_input & acc;
	assign or_output = andor_input & acc;
	PortCombDual #(.ADDR(ANDOR), .ADDRI(ANDORI)) p_andor0(
			.bus(bus),
			.data_from_bus(andor_input),
			.data_to_bus(and_output),
			.data_to_bus_i(or_output)
	);

	/* ====================
	*        NOT / XOR
	   ==================== */

	reg[7:0] nxor_input;
	reg[7:0] not_output;
	reg[7:0] xor_output;
	assign xor_output = nxor_input ^ acc;
	assign not_output = ~nxor_input;
	PortCombDual #(.ADDR(NXOR), .ADDRI(NXORI)) p_nxor0(
			.bus(bus),
			.data_from_bus(nxor_input),
			.data_to_bus(xor_output),
			.data_to_bus_i(not_output)
	);

	/* ====================
	*        SLL / SRL
	   ==================== */

	reg[7:0] shf_input;
	reg[7:0] sll_output;
	reg[7:0] srl_output;
	assign sll_output = acc << shf_input[2:0];
	assign srl_output = acc >> shf_input[2:0];
	PortCombDual #(.ADDR(SHF), .ADDRI(SHFI)) p_shf0(
			.bus(bus),
			.data_from_bus(shf_input),
			.data_to_bus(sll_output),
			.data_to_bus_i(srl_output)
	);

	/* ====================
	*    		MUL
	   ==================== */

	reg[7:0] mul_input;
	reg[7:0] mul_output0;
	reg[7:0] mul_output1;
	assign {mul_output1, mul_output0} = mul_input * acc;
	PortCombDual #(.ADDR(NXOR), .ADDRI(NXORI)) p_mul0(
			.bus(bus),
			.data_from_bus(mul_input),
			.data_to_bus(mul_output0),
			.data_to_bus_i(mul_output1)
	);

	/* ====================
	*    	DIV / MOD
	   ==================== */

	reg[7:0] div_input;
	reg[7:0] div_output;
	reg[7:0] mod_output;
	assign div_output = acc / div_input;
	assign mod_output = acc % div_input;
	PortCombDual #(.ADDR(NXOR), .ADDRI(NXORI)) p_div0(
			.bus(bus),
			.data_from_bus(div_input),
			.data_to_bus(div_output),
			.data_to_bus_i(mod_output)
	);

	/* ====================
	*   	GT / GE 
	   ==================== */

	reg[7:0] gtge_input;
	reg[7:0] gt_output;
	reg[7:0] ge_output;
	assign gt_output = acc > gtge_input;
	assign ge_output = acc >= gtge_input;
	PortCombDual #(.ADDR(GTGE), .ADDRI(GTGEI)) p_gtge0(
			.bus(bus),
			.data_from_bus(gtge_input),
			.data_to_bus({7'd0, gt_output}),
			.data_to_bus_i({7'd0, ge_output})
	);
endmodule
	

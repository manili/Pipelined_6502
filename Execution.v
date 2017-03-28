`include "Global_Macros.v"

module Execution(
			clk_i,
			rst_i,
			gbl_stl_i,
			wait_to_fill_pipe_i,
			a_i,
			x_i,
			y_i,
			control_signal_i,
			operand_i,
			eff_adr_i,
			mem_stl_i,
			p_o,
			control_signal_o,
			forwd_o,
			result_o,
			eff_adr_o

`ifdef	DEBUG
			,debug_o
`endif
);

	//Input signals :
	input	wire			clk_i;
	input	wire			rst_i;
	input	wire			gbl_stl_i;
	input	wire			wait_to_fill_pipe_i;
	input	wire	[7:0]	a_i;
	input	wire	[7:0]	x_i;
	input	wire	[7:0]	y_i;
	input	wire	[`rddata_cntrl_o_width - 1:0]	control_signal_i;
	input	wire	[15:0]	operand_i;
	input	wire	[15:0]	eff_adr_i;
	input	wire			mem_stl_i;
	
	//Output signals :
	output	wire	[7:0]	p_o;
	output	reg		[`execut_cntrl_o_width - 1:0]	control_signal_o;
	output	wire	[15:0]	forwd_o;
	output	reg		[15:0]	result_o;
	output	reg		[15:0]	eff_adr_o;
	
`ifdef	DEBUG
	output	wire	[`EXE_DBG_WIDTH - 1:0]	debug_o;
`endif
	
	//Internal wires :
	wire			[7:0]	alu_flags_o;
	wire			[15:0]	op1;
	wire			[15:0]	op2;
	wire			[15:0]	alu_result_o;
	
	//Internal registers :
	reg				[7:0]	p_reg;
	reg				[15:0]	result_tmp_reg;
	
	//Assignments :
	assign p_o = p_reg;
	assign forwd_o = alu_result_o;

`ifdef	DEBUG
	assign debug_o = alu_result_o;
`endif
	
	//Instantiations :
	MUX2x1 #(16) mux2x1_1(op1, `cntrl_exe_op1_src, operand_i, op2);
	MUX8x1 #(16) mux8x1_1(op2, `cntrl_exe_op2_src, {8'h0, a_i}, {8'h0, x_i}, {8'h0, y_i}, {8'h0, alu_flags_o}, eff_adr_i, 16'h0, 16'h0, result_tmp_reg);
	
	ALU					alu
	(
			.operation_i			(`cntrl_exe_op),
			.status_i				(p_reg),	
			.operand1_i				(op1),
			.operand2_i				(op2),
			.status_o				(alu_flags_o),
			.result_o				(alu_result_o)
	);
	
	//Blocks
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			control_signal_o	<=	`execut_cntrl_o_width'h0;
			p_reg				<=	`INIT_STATUS_REG;
		end
		else if(gbl_stl_i == 1'h1 || mem_stl_i == 1'h1)
		begin
			
		end
		else if(wait_to_fill_pipe_i == 1'h1)
		begin
			
		end
		else
		begin
			control_signal_o	<=	control_signal_i[`execut_cntrl_o_width - 1:0];
			eff_adr_o 			<=	eff_adr_i;
			result_o 			<=	alu_result_o;
			result_tmp_reg 		<=	(	`cntrl_wb_ra_ld		==	1'h1	||
										`cntrl_wb_rx_ld		==	1'h1	||
										`cntrl_wb_ry_ld		==	1'h1	||
										`cntrl_wb_mem_wr	==	1'h1	)	?	alu_result_o	:	result_tmp_reg;
			p_reg				<=	(	`cntrl_exe_rp_ld	==	1'h1	)	?	alu_flags_o		:	p_reg;
		end
	end
endmodule
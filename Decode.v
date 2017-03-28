`include "Global_Macros.v"

`define	history_flag_1		history_inst_flag[0]	//Pre Instruction
`define	history_flag_2		history_inst_flag[1]	//Pre Pre Instruction
`define	history_flag_3		history_inst_flag[2]	//Pre Pre Pre Instruction
`define	nef_flags			1'h0					//Wont effect flags
`define	wef_flags			1'h1					//Will effect flags

`define	history_dest_1		history_inst_dest[1:0]	//Pre Instruction
`define	history_dest_2		history_inst_dest[3:2]	//Pre Pre Instruction
`define	history_dest_3		history_inst_dest[5:4]	//Pre Pre Pre Instruction
`define	wb_dest_impld		2'h0					//Implied
`define	wb_dest_memry		2'h0					//Memory
`define	wb_dest_none		2'h0					//None
`define	wb_dest_reg_a		2'h1					//Accumulator
`define	wb_dest_reg_x		2'h2					//X  Register
`define	wb_dest_reg_y		2'h3					//Y  Register

`define	cur_inst			inst_temp_reg[7:0]
`define	inst_temp_1			inst_temp_reg[7:0]
`define	inst_temp_2			inst_temp_reg[15:8]
`define	inst_temp_3			inst_temp_reg[23:16]

module Decode(
				clk_i,
				rst_i,
				gbl_stl_i,
				jmp_rqst_i,
				wait_to_fill_pipe_i,
				wait_sig_i,
				p_i,
				pc_i,
				fetched_ops_i,
				mem_stl_i,
				wait_sig_o,
				pc_o,
				operand_o,
				control_signal_o

`ifdef	DEBUG
				,debug_o
`endif
);

	//Input signals :
	input	wire			clk_i;
	input	wire			rst_i;
	input	wire			gbl_stl_i;
	input	wire			jmp_rqst_i;
	input	wire			wait_to_fill_pipe_i;
	input	wire	[1:0]	wait_sig_i;
	input	wire	[7:0]	p_i;
	input	wire	[15:0]	pc_i;
	input	wire	[23:0]	fetched_ops_i;
	input	wire			mem_stl_i;
	
	//Output signals :
	output	wire	[1:0]	wait_sig_o;
	output	wire	[15:0]	pc_o;
	output	wire	[15:0]	operand_o;
	output	wire	[`decode_cntrl_o_width - 1:0]	control_signal_o;
	
`ifdef	DEBUG
	output	wire	[`DEC_DBG_WIDTH - 1:0]	debug_o;
`endif
	
	//Internal registers:
	reg				[1:0]	wait_sig_reg;
	reg				[1:0]	used_byte_cnt_reg;
	reg				[15:0]	pc_reg;
	reg				[15:0]	operand_reg;
	reg				[`decode_cntrl_o_width - 1:0]	control_signal_reg;
	
	reg				[2:0]	history_inst_flag;
	reg				[5:0]	history_inst_dest;
	reg				[23:0]	inst_temp_reg;
			
	//Assignments :
	assign wait_sig_o = wait_sig_reg;
	assign pc_o = pc_reg;
	assign operand_o = operand_reg;
	assign control_signal_o = control_signal_reg;
	
`ifdef	DEBUG
	assign debug_o = inst_temp_reg;
`endif
	
	//Blocks :
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			wait_sig_reg <= 2'h0;
			operand_reg <= 16'h0;
			used_byte_cnt_reg <= 2'h0;
			control_signal_reg <= `decode_cntrl_o_width'h0;
			inst_temp_reg <= {3{`NOTHING}};
			history_inst_flag <= {3{`nef_flags}};
			history_inst_dest <= {3{`wb_dest_none}};
		end
		else if(gbl_stl_i == 1'h1 || mem_stl_i == 1'h1)
		begin
			
		end
		else if(wait_sig_i - 2'h1 != 2'h3)
		begin
			used_byte_cnt_reg <= 2'h0;
			history_inst_flag <= {`nef_flags, `history_flag_2, `history_flag_1};
			history_inst_dest <= {`wb_dest_none, `history_dest_2, `history_dest_1};
		end
		else if(wait_sig_reg != 2'h0)
		begin
			wait_sig_reg <= wait_sig_reg - 2'h1;
			used_byte_cnt_reg <= 2'h0;
			history_inst_flag <= {`history_flag_2, `nef_flags, `history_flag_1};
			history_inst_dest <= {`history_dest_2, `wb_dest_none, `history_dest_1};
		end
		else if(wait_to_fill_pipe_i == 1'h1 || jmp_rqst_i == 1'h1)
		begin
			inst_temp_reg <= fetched_ops_i;
		end
		else
		begin
			case(`cur_inst)
				//Decode instructions ... :
				
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          ADC                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////

				`ADC_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ADC_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ADC_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ADC_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ADC_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ADC_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ADC_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ADC_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ADD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          AND                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////

				`AND_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`AND_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`AND_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`AND_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`AND_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`AND_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`AND_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`AND_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_AND;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          ASL                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`ASL_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ASL_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ASL_ACU	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_SHL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ASL_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ASL_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                     BRANCHES                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`BCC		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`C] == 1'h0)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BCS		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`C] == 1'h1)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BEQ		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`Z] == 1'h1)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BIT_ABS	:	begin
									
								end
				`BIT_ZP		:	begin
									
								end
				`BMI		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`N] == 1'h1)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BNE		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`Z] == 1'h0)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BPL		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`N] == 1'h0)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BRK		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`V_ADR_IRQ_H, `V_ADR_IRQ_L};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= {3{`NOTHING}};
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_P_PC_PUSH;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_BRK;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `THR;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BVC		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`V] == 1'h0)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`BVS		:	begin
									if(`history_flag_1 == `wef_flags)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else if(`history_flag_2 == `wef_flags)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										used_byte_cnt_reg <= 2'h0;
										inst_temp_reg <= inst_temp_reg;
									end
									else
									begin
										if(p_i[`V] == 1'h1)
										begin
											if(inst_temp_reg[15] == 1'h1)
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, (8'd128 - {1'h0, inst_temp_reg[14:8]})};
											end
											else
											begin
												operand_reg <= (pc_i - 16'h6 + used_byte_cnt_reg) - {8'h0, `inst_temp_2};
											end
											
											used_byte_cnt_reg <= 2'h3;
											inst_temp_reg <= {3{`NOTHING}};
											`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
										end
										else
										begin
											used_byte_cnt_reg <= 2'h2;
											inst_temp_reg <= inst_temp_reg >> 6'h10;
											inst_temp_reg[23:8] <= fetched_ops_i[15:0];
											`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
										end
									end
									
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                  FLAGS CLEAR                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`CLC		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_CLC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CLD		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_CLD;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CLI		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_CLI;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CLV		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_CLV;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          CMP                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`CMP_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CMP_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CMP_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CMP_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CMP_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CMP_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CMP_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CMP_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          CPX                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`CPX_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CPX_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CPX_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          CPY                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`CPY_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CPY_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`CPY_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_CMP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                       DECRIMENT                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`DEC_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_DEC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`DEC_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_DEC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`DEC_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_DEC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`DEC_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_DEC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`DEX		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_DEC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`DEY		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_DEC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          XOR                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`EOR_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`EOR_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`EOR_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`EOR_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`EOR_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`EOR_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`EOR_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`EOR_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_XOR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                       INCREMENT                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`INC_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_INC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`INC_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_INC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`INC_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_INC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`INC_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_INC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`INX		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_INC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`INY		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_INC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          JMP                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`JMP_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= {3{`NOTHING}};
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`JMP_I		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= {3{`NOTHING}};
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          JSR                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`JSR		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= {3{`NOTHING}};
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_PC_PUSH;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `TWO;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          LDA                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`LDA_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDA_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDA_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDA_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDA_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDA_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDA_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDA_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          LDX                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`LDX_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDX_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDX_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDX_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDX_ZP_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          LDY                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`LDY_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDY_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDY_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDY_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LDY_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          LSR                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`LSR_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LSR_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LSR_ACU	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_SHR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LSR_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`LSR_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SHR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          NOP                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`NOP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          ORA                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`ORA_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ORA_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ORA_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ORA_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ORA_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ORA_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ORA_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ORA_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ORA;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                    PUSH, POP                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`PHA		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `SP_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_PUSH;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`PHP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `SP_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_PUSH;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_P;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`PLA		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `SP_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_POP;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`PLP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `SP_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_POP;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITF;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          ROL                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`ROL_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROL_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROL_ACU	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ROL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROL_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROL_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROL;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          ROR                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`ROR_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROR_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROR_ACU	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ROR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROR_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`ROR_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ROR;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                    RETURN ORIENTED                                   //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`RTI		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= {3{`NOTHING}};
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `SP_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_P_PC_POP;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITF;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`RTS		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= {3{`NOTHING}};
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `JUMP_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `SP_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_PC_POP;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          SBC                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`SBC_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SBC_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SBC_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SBC_IME	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IME;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SBC_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SBC_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SBC_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SBC_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_SUB;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DAT;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                    FLAGS SET                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`SEC		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_SEC;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SED		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_SED;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`SEI		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_SEI;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          STA                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`STA_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STA_ABS_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STA_ABS_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STA_I_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STA_I_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_2_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_adr_mod_reg <= `MOD_INDIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STA_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STA_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          STX                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`STX_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STX_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STX_ZP_Y	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_y)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_y)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_Y;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                          STY                                         //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`STY_ABS	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`inst_temp_3, `inst_temp_2};
									used_byte_cnt_reg <= 2'h3;
									inst_temp_reg <= inst_temp_reg >> 6'h18;
									inst_temp_reg[23:0] <= fetched_ops_i[23:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STY_ZP		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`STY_ZP_X	:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {8'h0, `inst_temp_2};
									used_byte_cnt_reg <= 2'h2;
									inst_temp_reg <= inst_temp_reg >> 6'h10;
									inst_temp_reg[23:8] <= fetched_ops_i[15:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_FORWD;
									end
									else
									begin
										`cntrl_ea_off_1_reg <= `ADR_OFF_X;
									end
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_DIR;
									`cntrl_ea_adr_src_reg <= `EA_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_ADR;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `ONE;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_memry};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
								
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                TRANSFERRING RESGISTERS                               //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////
								
				`TAX		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`TAY		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_a)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_A;
									end
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `ACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_y};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`TSX		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `SP_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_S;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `ACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_x};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`TXA		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_X;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				`TXS		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									if(`history_dest_1 == `wb_dest_reg_x)
									begin
										//Insert 2 bubbles
										wait_sig_reg <= 2'h2;
										`cntrl_ea_stack_op_reg <= `STACK_OP_FORWD;
									end
									else if(`history_dest_2 == `wb_dest_reg_x)
									begin
										//Insert 1 bubble
										wait_sig_reg <= 2'h1;
										`cntrl_ea_stack_op_reg <= `STACK_OP_FORWD;
									end
									else if(`history_dest_3 == `wb_dest_reg_x)
									begin
										`cntrl_ea_stack_op_reg <= `STACK_OP_FORWD;
									end
									else
									begin
										`cntrl_ea_stack_op_reg <= `STACK_OP_X;
									end
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_NOP;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_DC;
									`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_DC;
									`cntrl_wb_ra_ld_reg <= `DEACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_impld};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
				`TYA		:	begin
									//Step 1, Update Registers :
									pc_reg <= pc_i - 16'h6 + used_byte_cnt_reg + 16'h1;
									operand_reg <= {`NOP, `NOP};
									used_byte_cnt_reg <= 2'h1;
									inst_temp_reg <= inst_temp_reg >> 6'h8;
									inst_temp_reg[23:16] <= fetched_ops_i[7:0];
									
									//Step 2, Generate Control Signals :
									`cntrl_ea_pc_jmp_reg <= `NEXT_INST;
									`cntrl_ea_off_1_reg <= `ADR_OFF_NA;
									`cntrl_ea_off_2_reg <= `ADR_OFF_NA;
									`cntrl_ea_adr_mod_reg <= `MOD_NON;
									`cntrl_ea_adr_src_reg <= `NO_ADR;
									`cntrl_ea_stack_op_reg <= `STACK_OP_NONE;
									`cntrl_rd_src_reg <= `TYPE_IMP;
									`cntrl_exe_op_reg <= `ALU_ITO;
									`cntrl_exe_op1_src_reg <= `ALU_OP1_SRC_OP2;
									if(`history_dest_1 == `wb_dest_reg_y)
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_FORWD;
									end
									else
									begin
										`cntrl_exe_op2_src_reg <= `ALU_OP2_SRC_Y;
									end
									`cntrl_wb_ra_ld_reg <= `ACTIVE;
									`cntrl_wb_rx_ld_reg <= `DEACTIVE;
									`cntrl_wb_ry_ld_reg <= `DEACTIVE;
									`cntrl_exe_rp_ld_reg <= `ACTIVE;
									`cntrl_wb_mem_wr_reg <= `DEACTIVE;
									`cntrl_wb_mem_wr_cnt_reg <= `NON;
									
									//Step 3, Update Wire Back Destination History :
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_reg_a};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `wef_flags};
								end
				default		:	begin
									control_signal_reg <= `decode_cntrl_o_width'h0;
									used_byte_cnt_reg <= 2'h0;
									history_inst_dest <= {`history_dest_2, `history_dest_1, `wb_dest_none};
									history_inst_flag <= {`history_flag_2, `history_flag_1, `nef_flags};
								end
			endcase
		end
	end
endmodule
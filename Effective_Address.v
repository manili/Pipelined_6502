`include "Global_Macros.v"

`define	history_cnt_1			history_cnt_wr_byt[1:0]
`define	history_cnt_2			history_cnt_wr_byt[3:2]
`define	history_cnt_3			history_cnt_wr_byt[5:4]

`define	history_adr_1			history_dst_wr_adr[15:0]
`define	history_vld_1			history_dst_wr_adr[16]
`define	history_adr_2			history_dst_wr_adr[32:17]
`define	history_vld_2			history_dst_wr_adr[33]
`define	history_adr_3			history_dst_wr_adr[49:34]
`define	history_vld_3			history_dst_wr_adr[50]

module Effective_Address(
				clk_i,
				rst_i,
				gbl_stl_i,
				wait_to_fill_pipe_i,
				wait_sig_i,
				x_i,
				y_i,
				pc_i,
				forwd_i,
				operand_i,
				control_signal_i,
				mem_stl_i,
				mem_ea_dat_i,
				refill_pipe_o,
				wait_sig_o,
				control_signal_o,
				dat_o,
				jmp_adr_o,
				eff_adr_o,
				mem_ea_adr_o

`ifdef	DEBUG
				,debug_o
`endif
);

	//Input signals :
	input	wire			clk_i;
	input	wire			rst_i;
	input	wire			gbl_stl_i;
	input	wire			wait_to_fill_pipe_i;
	input	wire	[1:0]	wait_sig_i;
	input	wire	[7:0]	x_i;
	input	wire	[7:0]	y_i;
	input	wire	[15:0]	pc_i;
	input	wire	[15:0]	forwd_i;
	input	wire	[15:0]	operand_i;
	input	wire	[`decode_cntrl_o_width - 1:0]	control_signal_i;
	input	wire			mem_stl_i;
	input	wire	[15:0]	mem_ea_dat_i;
	
	//Output signals :
	output	reg				refill_pipe_o;
	output	reg		[1:0]	wait_sig_o;
	output	reg		[`effadr_cntrl_o_width - 1:0]	control_signal_o;
	output	reg		[15:0]	dat_o;
	output	reg		[15:0]	jmp_adr_o;
	output	reg		[15:0]	eff_adr_o;
	output	wire	[15:0]	mem_ea_adr_o;
	
`ifdef	DEBUG
	output	wire	[`EAD_DBG_WIDTH - 1:0]	debug_o;
`endif
	
	//Internal wires :
	wire			[7:0]	mux4x1_1_o;
	wire			[7:0]	mux4x1_2_o;
	wire			[15:0]	mux2x1_1_o;
	wire			[15:0]	offset1_o;
	wire			[15:0]	offset2_o;
	wire			[15:0]	final_mem_ea_adr;
	wire			[15:0]	final_mem_ea_dat;
	wire			[15:0]	final_eff_adr;
	
	//Internal registers :
	reg				[`effadr_cntrl_o_width - 1:0]	control_signal_reg;
	
	reg				[1:0]	wait_tmp;
	reg				[1:0]	mem_ea_dat_lo_need_forwd;
	reg				[1:0]	mem_ea_dat_hi_need_forwd;
	reg				[5:0]	history_cnt_wr_byt;
	reg				[7:0]	sp_reg;
	reg				[50:0]	history_dst_wr_adr;
	
	//Assignments :
	assign mem_ea_adr_o = final_mem_ea_adr;
	
	assign offset1_o = operand_i + {8'h0, mux4x1_1_o};
	assign offset2_o = mux2x1_1_o + {8'h0, mux4x1_2_o};
	
	assign final_mem_ea_adr	=	(`cntrl_ea_adr_src	==	`EA_ADR)	?	offset1_o :
					  			(`cntrl_ea_stack_op	==	`STACK_OP_POP)	?	{8'h1, sp_reg + 8'h1} : 
								(`cntrl_ea_stack_op	==	`STACK_OP_PC_POP)	?	{8'h1, sp_reg + 8'h1} : 
								(`cntrl_ea_stack_op	==	`STACK_OP_P_PC_POP)		?	{8'h1, sp_reg + 8'h1} : {8'h1, sp_reg};
	assign final_eff_adr	=	(`cntrl_ea_adr_src	==	`EA_ADR)	?	offset2_o :
					  			(`cntrl_ea_stack_op	==	`STACK_OP_POP)	?	{8'h1, sp_reg + 8'h1} : 
								(`cntrl_ea_stack_op	==	`STACK_OP_PC_POP)	?	{8'h1, sp_reg + 8'h1} : 
								(`cntrl_ea_stack_op	==	`STACK_OP_P_PC_POP)		?	{8'h1, sp_reg + 8'h3} : {8'h1, sp_reg};
	
`ifdef	DEBUG
	assign debug_o = mem_ea_adr_o;
`endif
	
	//Instantiations :
	MUX4x1 mux4x1_1(mux4x1_1_o, `cntrl_ea_off_1, forwd_i[7:0], x_i, y_i, 8'h0);
	MUX4x1 mux4x1_2(mux4x1_2_o, `cntrl_ea_off_2, forwd_i[7:0], x_i, y_i, 8'h0);
	MUX4x1 mux4x1_dat_lo(final_mem_ea_dat[07:00], mem_ea_dat_lo_need_forwd, mem_ea_dat_i[07:00], forwd_i[7:0], forwd_i[15:08], 8'h0);
	MUX4x1 mux4x1_dat_hi(final_mem_ea_dat[15:08], mem_ea_dat_hi_need_forwd, mem_ea_dat_i[15:08], forwd_i[7:0], forwd_i[15:08], 8'h0);
	MUX2x1 #(16) mux2x1_1(mux2x1_1_o, `cntrl_ea_adr_mod, offset1_o, final_mem_ea_dat);
	
	//Blocks :
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			sp_reg <= `S_P_START;
		end
		else if(gbl_stl_i == 1'h1 || mem_stl_i == 1'h1)
		begin
		
		end
		else if(wait_to_fill_pipe_i == 1'h1)
		begin
		
		end
		else if(wait_sig_o != 2'h0)
		begin
		
		end
		else if(wait_sig_i - 2'h1 != 2'h3)
		begin
		
		end
		else
		begin
			case(`cntrl_ea_stack_op)
				`STACK_OP_NONE		:	sp_reg <= sp_reg;
				`STACK_OP_PUSH		:	sp_reg <= sp_reg - 8'h1;
				`STACK_OP_PC_PUSH	:	sp_reg <= sp_reg - 8'h2;
				`STACK_OP_P_PC_PUSH	:	sp_reg <= sp_reg - 8'h3;
				`STACK_OP_POP		:	sp_reg <= sp_reg + 8'h1;
				`STACK_OP_PC_POP	:	sp_reg <= sp_reg + 8'h2;
				`STACK_OP_P_PC_POP	:	sp_reg <= sp_reg + 8'h3;
				`STACK_OP_X			:	sp_reg <= x_i;
				`STACK_OP_FORWD		:	sp_reg <= forwd_i[7:0];
				default				:	sp_reg <= sp_reg;
			endcase
		end
	end
	
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			control_signal_o <= `effadr_cntrl_o_width'h0;
			jmp_adr_o <= `P_C_START;
			refill_pipe_o <= 1'h0;
			
			mem_ea_dat_lo_need_forwd <= 1'h0;
			mem_ea_dat_hi_need_forwd <= 1'h0;
			`history_vld_1 <= 1'h0;
			`history_vld_2 <= 1'h0;
			`history_vld_3 <= 1'h0;
		end
		else if(gbl_stl_i == 1'h1 || mem_stl_i == 1'h1)
		begin
			
		end
		else if(wait_to_fill_pipe_i == 1'h1)
		begin
			refill_pipe_o <= 1'h0;
		end
		else if(wait_sig_o != 2'h0)
		begin
			wait_tmp <= wait_sig_o - 2'h1;
			control_signal_o <= `effadr_cntrl_o_width'h0;
			
			history_dst_wr_adr <= history_dst_wr_adr << 5'h11;
		end
		else if(wait_sig_i - 2'h1 != 2'h3)
		begin
			control_signal_o <= `effadr_cntrl_o_width'h0;
			
			history_dst_wr_adr <= history_dst_wr_adr << 5'h11;
		end
		else
		begin
			if(`cntrl_wb_mem_wr == 1'h1)
			begin
				history_cnt_wr_byt <= history_cnt_wr_byt << 2'h2;
				history_dst_wr_adr <= history_dst_wr_adr << 5'h11;
				
				`history_cnt_1 <= `cntrl_wb_mem_wr_cnt;
				`history_adr_1 <= (`cntrl_ea_stack_op == `STACK_OP_PUSH) ? {8'h1, sp_reg} : 
						 		  (`cntrl_ea_stack_op == `STACK_OP_PC_PUSH) ? {8'h1, sp_reg - 8'h1} : 
								  (`cntrl_ea_stack_op == `STACK_OP_P_PC_PUSH) ? {8'h1, sp_reg - 8'h2} : final_eff_adr;
				`history_vld_1 <= 1'h1;
			end
			else
			begin
				history_cnt_wr_byt <= history_cnt_wr_byt << 2'h2;
				history_dst_wr_adr <= history_dst_wr_adr << 5'h11;
			end
			dat_o <= (`cntrl_ea_stack_op == `STACK_OP_PC_PUSH || `cntrl_ea_stack_op == `STACK_OP_P_PC_PUSH) ? pc_i + 16'h2 : operand_i;
			jmp_adr_o <= (`cntrl_ea_stack_op == `STACK_OP_PC_POP || `cntrl_ea_stack_op == `STACK_OP_P_PC_POP) ? mem_ea_dat_i : final_eff_adr;
			eff_adr_o <= (`cntrl_ea_stack_op == `STACK_OP_PUSH) ? {8'h1, sp_reg} : 
						 (`cntrl_ea_stack_op == `STACK_OP_PC_PUSH) ? {8'h1, sp_reg - 8'h1} : 
						 (`cntrl_ea_stack_op == `STACK_OP_P_PC_PUSH) ? {8'h1, sp_reg - 8'h2} : final_eff_adr;
			refill_pipe_o <= (`cntrl_ea_pc_jmp == 1'h1) ? 1'h1 : 1'h0;
			control_signal_o <= control_signal_reg;
		end
	end
		
	always @(*)
	begin		
		if(rst_i == 1'h1)
		begin
			wait_sig_o = 2'h0;
		end
		else if(wait_sig_o != 2'h0)
		begin
			wait_sig_o = wait_tmp;
		end
		else if(`cntrl_ea_adr_mod == `MOD_INDIR)
		begin

		
	//////////////////////////////////////////////////////////////////////////////////////
	//                                                                                  //
	//                   Start checking for data hazard of addresses                    //
	//                                                                                  //
	//////////////////////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////////////////////
	//                                                                                  //
	//                     Start checking for post-offset1 hazards                      //
	//                                                                                  //
	//////////////////////////////////////////////////////////////////////////////////////
			
			//This is a logic to handle EA unit related hazards.
			//So [INDIR(ADR + Off1)/+1] will be checked here.
			//Also we need a history to keep the number of bytes to write per each access.
			
			if(wait_sig_o == 2'h0 && `history_vld_1 == 1'h1)
			begin
				case(`history_cnt_1)
					`ONE	:	begin
									if(
										`history_adr_1 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_1 + `ONE == final_mem_ea_adr + 16'h1
									  )
									begin
										//Insert 1 bubbles till exe unit forwarding
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`TWO	:	begin
									if(
										`history_adr_1 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_1 + `ONE == final_mem_ea_adr + 16'h1
										||
										`history_adr_1 + `TWO == final_mem_ea_adr
										|| 
										`history_adr_1 + `TWO == final_mem_ea_adr + 16'h1
									  )
									begin
										//Insert 1 bubbles till exe unit forwarding
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`THR	:	begin
									if(
										`history_adr_1 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_1 + `ONE == final_mem_ea_adr + 16'h1
										||
										`history_adr_1 + `TWO == final_mem_ea_adr
										|| 
										`history_adr_1 + `TWO == final_mem_ea_adr + 16'h1
										||
										`history_adr_1 + `THR == final_mem_ea_adr
										|| 
										`history_adr_1 + `THR == final_mem_ea_adr + 16'h1
									  )
									begin
										//Insert 1 bubbles till exe unit forwarding
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					default	:	begin
									//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
		
			if(wait_sig_o == 2'h0 && `history_vld_3 == 1'h1)
			begin
				case(`history_cnt_3)
					`ONE	:	begin
									if(
										`history_adr_3 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_3 + `ONE == final_mem_ea_adr + 16'h1
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`TWO	:	begin
									if(
										`history_adr_3 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_3 + `ONE == final_mem_ea_adr + 16'h1
										||
										`history_adr_3 + `TWO == final_mem_ea_adr
										|| 
										`history_adr_3 + `TWO == final_mem_ea_adr + 16'h1
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`THR	:	begin
									if(
										`history_adr_3 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_3 + `ONE == final_mem_ea_adr + 16'h1
										||
										`history_adr_3 + `TWO == final_mem_ea_adr
										|| 
										`history_adr_3 + `TWO == final_mem_ea_adr + 16'h1
										||
										`history_adr_3 + `THR == final_mem_ea_adr
										|| 
										`history_adr_3 + `THR == final_mem_ea_adr + 16'h1
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					default	:	begin
										//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
		
			if(wait_sig_o == 2'h0 && `history_vld_2 == 1'h1)
			begin
				case(`history_cnt_2)
					`ONE	:	begin
									if(
										`history_adr_2 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_2 + `ONE == final_mem_ea_adr + 16'h1
									  )
									begin
										//TODO: Use result of forwarding of exe unit by
										//mem_ea_dat_lo_need_forwd and mem_ea_dat_hi_need_forwd flags
										wait_sig_o = 2'h1;
									end
									else
									begin
										//No data hazard till end of Offset1
									end
								end
					`TWO	:	begin
									if(
										`history_adr_2 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_2 + `ONE == final_mem_ea_adr + 16'h1
										||
										`history_adr_2 + `TWO == final_mem_ea_adr
										|| 
										`history_adr_2 + `TWO == final_mem_ea_adr + 16'h1
									  )
									begin
										//TODO: Use result of forwarding of exe unit by
										//mem_ea_dat_lo_need_forwd and mem_ea_dat_hi_need_forwd flags
										wait_sig_o = 2'h1;
									end
									else
									begin
										//No data hazard till end of Offset1
									end
								end
					`THR	:	begin
									if(
										`history_adr_2 + `ONE == final_mem_ea_adr
										|| 
										`history_adr_2 + `ONE == final_mem_ea_adr + 16'h1
										||
										`history_adr_2 + `TWO == final_mem_ea_adr
										|| 
										`history_adr_2 + `TWO == final_mem_ea_adr + 16'h1
										||
										`history_adr_2 + `THR == final_mem_ea_adr
										|| 
										`history_adr_2 + `THR == final_mem_ea_adr + 16'h1
									  )
									begin
										//TODO: Use result of forwarding of exe unit by
										//mem_ea_dat_lo_need_forwd and mem_ea_dat_hi_need_forwd flags
										wait_sig_o = 2'h1;
									end
									else
									begin
										//No data hazard till end of Offset1
									end
								end
					default	:	begin
									//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
			
			
    //////////////////////////////////////////////////////////////////////////////////////
    //			                                                                        //
    //				            No data hazard till end of Offset1                      //
    //				                                                                    //
    //////////////////////////////////////////////////////////////////////////////////////
				
	//////////////////////////////////////////////////////////////////////////////////////
	//                                                                                  //
	//                      Start checking for pre-offset2 hazards                      //
	//                                                                                  //
	//////////////////////////////////////////////////////////////////////////////////////
	
			//This is a logic to handle EA unit related hazards.
			//So (MEM RETURNED ADR) will be checked here.
			//Also we need a history to keep the number of bytes to write per each access.
			
			if(wait_sig_o == 2'h0 && `history_vld_1 == 1'h1)
			begin
				case(`history_cnt_1)
					`ONE	:	begin
									if(
										`history_adr_1 + `ONE == mem_ea_dat_i
									  )
									begin
										//Insert 1 bubbles till exe unit forwarding
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`TWO	:	begin
									if(
										`history_adr_1 + `ONE == mem_ea_dat_i
										||
										`history_adr_1 + `TWO == mem_ea_dat_i
									  )
									begin
										//Insert 1 bubbles till exe unit forwarding
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`THR	:	begin
									if(
										`history_adr_1 + `ONE == mem_ea_dat_i
										||
										`history_adr_1 + `TWO == mem_ea_dat_i
										||
										`history_adr_1 + `THR == mem_ea_dat_i
									  )
									begin
										//Insert 1 bubbles till exe unit forwarding
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					default	:	begin
									//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
	
			if(wait_sig_o == 2'h0 && `history_vld_3 == 1'h1)
			begin
				case(`history_cnt_3)
					`ONE	:	begin
									if(
										`history_adr_3 + `ONE == mem_ea_dat_i
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`TWO	:	begin
									if(
										`history_adr_3 + `ONE == mem_ea_dat_i
										||
										`history_adr_3 + `TWO == mem_ea_dat_i
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`THR	:	begin
									if(
										`history_adr_3 + `ONE == mem_ea_dat_i
										||
										`history_adr_3 + `TWO == mem_ea_dat_i
										||
										`history_adr_3 + `THR == mem_ea_dat_i
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					default	:	begin
										//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
	
			if(wait_sig_o == 2'h0 && `history_vld_2 == 1'h1)
			begin
				case(`history_cnt_2)
					`ONE	:	begin
									if(
										`history_adr_2 + `ONE == mem_ea_dat_i
									  )
									begin
										//TODO: Use result of forwarding of exe unit by
										//mem_ea_dat_lo_need_forwd and mem_ea_dat_hi_need_forwd flags
										wait_sig_o = 2'h1;
									end
									else
									begin
										//No data hazard until Offset2
									end
								end
					`TWO	:	begin
									if(
										`history_adr_2 + `ONE == mem_ea_dat_i
										||
										`history_adr_2 + `TWO == mem_ea_dat_i
									  )
									begin
										//TODO: Use result of forwarding of exe unit by
										//mem_ea_dat_lo_need_forwd and mem_ea_dat_hi_need_forwd flags
										wait_sig_o = 2'h1;
									end
									else
									begin
										//No data hazard until Offset2
									end
								end
					`THR	:	begin
									if(
										`history_adr_2 + `ONE == mem_ea_dat_i
										||
										`history_adr_2 + `TWO == mem_ea_dat_i
										||
										`history_adr_2 + `THR == mem_ea_dat_i
									  )
									begin
										//TODO: Use result of forwarding of exe unit by
										//mem_ea_dat_lo_need_forwd and mem_ea_dat_hi_need_forwd flags
										wait_sig_o = 2'h1;
									end
									else
									begin
										//No data hazard until Offset2
									end
								end
					default	:	begin
									//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
		end
		else
		begin
			//Do Nothing!
		end
		
	//////////////////////////////////////////////////////////////////////////////////////
	//			                                                                        //
	//				            No data hazard till end of Offset2                      //
	//				                                                                    //
	//////////////////////////////////////////////////////////////////////////////////////
		
	//////////////////////////////////////////////////////////////////////////////////////
	//                                                                                  //
	//                     Start checking for post-offset2 hazards                      //
	//                                                                                  //
	//////////////////////////////////////////////////////////////////////////////////////
	
		//This is a logic to handle RD unit related hazards.
		//So after all calculations the result will be checked here.
		//DIR(ADR) or DIR(ADR + X) or DIR(ADR + Y) or DIR([CACHE RETURNED ADR] + Y)
		//Also we need a history to keep the number of bytes to write per each access.
		
		if(rst_i == 1'h1)
		begin
			control_signal_reg = `effadr_cntrl_o_width'h0;
		end
		else if(`cntrl_rd_src == `TYPE_ADR)
		begin
			if(wait_sig_o == 2'h0 && `history_vld_2 == 1'h1)
			begin
				case(`history_cnt_2)
					`ONE	:	begin
									if(
										`history_adr_2 + `ONE == final_mem_ea_adr
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`TWO	:	begin
									if(
										`history_adr_2 + `ONE == final_eff_adr
										||
										`history_adr_2 + `TWO == final_eff_adr
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`THR	:	begin
									if(
										`history_adr_2 + `ONE == final_eff_adr
										||
										`history_adr_2 + `TWO == final_eff_adr
										||
										`history_adr_2 + `THR == final_eff_adr
									  )
									begin
										//Insert 2 bubbles till wb unit finish the job
										wait_sig_o = 2'h2;
									end
									else
									begin
										//Do Nothing!
									end
								end
					default	:	begin
									//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
		
			if(wait_sig_o == 2'h0 && `history_vld_3 == 1'h1)
			begin
				case(`history_cnt_3)
					`ONE	:	begin
									if(
										`history_adr_3 + `ONE == final_eff_adr
									  )
									begin
										//Insert 1 bubble till wb unit finish the job
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`TWO	:	begin
									if(
										`history_adr_3 + `ONE == final_eff_adr
										||
										`history_adr_3 + `TWO == final_eff_adr
									  )
									begin
										//Insert 1 bubble till wb unit finish the job
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					`THR	:	begin
									if(
										`history_adr_3 + `ONE == final_eff_adr
										||
										`history_adr_3 + `TWO == final_eff_adr
										||
										`history_adr_3 + `THR == final_eff_adr
									  )
									begin
										//Insert 1 bubble till wb unit finish the job
										wait_sig_o = 2'h1;
									end
									else
									begin
										//Do Nothing!
									end
								end
					default	:	begin
										//Do Nothing!
								end
				endcase
			end
			else
			begin
				//Do Nothing!
			end
		
			if(wait_sig_o == 2'h0 && `history_vld_1 == 1'h1)
			begin
				case(`history_cnt_1)
					`ONE	:	begin
									if(
										`history_adr_1 + `ONE == final_eff_adr
									  )
									begin
										//Forwarding of exe unit
										control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
										`cntrl_rd_src_reg = `TYPE_FORWD;
									end
									else
									begin
										//No data hazard
										control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
									end
								end
					`TWO	:	begin
									if(
										`history_adr_1 + `ONE == final_eff_adr
										||
										`history_adr_1 + `TWO == final_eff_adr
									  )
									begin
										//Forwarding of exe unit
										control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
										`cntrl_rd_src_reg = `TYPE_FORWD;
									end
									else
									begin
										//No data hazard
										control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
									end
								end
					`THR	:	begin
									if(
										`history_adr_1 + `ONE == final_eff_adr
										||
										`history_adr_1 + `TWO == final_eff_adr
										||
										`history_adr_1 + `THR == final_eff_adr
									  )
									begin
										//Forwarding of exe unit
										control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
										`cntrl_rd_src_reg = `TYPE_FORWD;
									end
									else
									begin
										//No data hazard
										control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
									end
								end
					default	:	begin
									//Do Nothing!
								end
				endcase
			end
			else if(wait_sig_o == 2'h0)
			begin
				//No data hazard
				control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
			end
			else
			begin
				//Do Nothing!
			end
		end
		else
		begin
			//No data hazard
			control_signal_reg = control_signal_i[`effadr_cntrl_o_width - 1:0];
		end
	end
endmodule
`define	decode_cntrl_o_width	29
`define	effadr_cntrl_o_width	18
`define	rddata_cntrl_o_width	16
`define	execut_cntrl_o_width	6

//////////////////////////////////////////////////////////////////////////////////////////

//E.A. Stage :
`define	cntrl_ea_pc_jmp_reg		control_signal_reg[28]
`define	cntrl_ea_off_1_reg		control_signal_reg[27:26]
`define	cntrl_ea_off_2_reg		control_signal_reg[25:24]
`define	cntrl_ea_adr_mod_reg	control_signal_reg[23]
`define	cntrl_ea_adr_src_reg	control_signal_reg[22]
`define	cntrl_ea_stack_op_reg	control_signal_reg[21:18]

//READ Stage :
`define	cntrl_rd_src_reg		control_signal_reg[17:16]

//EXEC Stage :
`define	cntrl_exe_op_reg		control_signal_reg[15:11]
`define	cntrl_exe_op1_src_reg	control_signal_reg[10]
`define	cntrl_exe_op2_src_reg	control_signal_reg[9:7]
`define	cntrl_exe_rp_ld_reg		control_signal_reg[6]

//W.B. Stage :
`define	cntrl_wb_ra_ld_reg		control_signal_reg[5]
`define cntrl_wb_rx_ld_reg		control_signal_reg[4]
`define cntrl_wb_ry_ld_reg		control_signal_reg[3]
`define	cntrl_wb_mem_wr_reg		control_signal_reg[2]
`define	cntrl_wb_mem_wr_cnt_reg	control_signal_reg[1:0]

//////////////////////////////////////////////////////////////////////////////////////////

//E.A. Stage :
`define	cntrl_ea_pc_jmp			control_signal_i[28]
`define	cntrl_ea_off_1			control_signal_i[27:26]
`define	cntrl_ea_off_2			control_signal_i[25:24]
`define	cntrl_ea_adr_mod		control_signal_i[23]
`define	cntrl_ea_adr_src		control_signal_i[22]
`define	cntrl_ea_stack_op		control_signal_i[21:18]

//READ Stage :
`define	cntrl_rd_src			control_signal_i[17:16]

//EXEC Stage :
`define	cntrl_exe_op			control_signal_i[15:11]
`define	cntrl_exe_op1_src		control_signal_i[10]
`define	cntrl_exe_op2_src		control_signal_i[9:7]
`define	cntrl_exe_rp_ld			control_signal_i[6]

//W.B. Stage :
`define	cntrl_wb_ra_ld			control_signal_i[5]
`define cntrl_wb_rx_ld			control_signal_i[4]
`define cntrl_wb_ry_ld			control_signal_i[3]
`define	cntrl_wb_mem_wr			control_signal_i[2]
`define	cntrl_wb_mem_wr_cnt		control_signal_i[1:0]
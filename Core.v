`include "Global_Macros.v"

module Core(
			clk_i,
			rst_i,
			irq_i,
			nmi_i,
			rdy_i,
			stl_i,
    		if_dat_i,
    		ea_dat_i,
    		rd_dat_i,
    		inst_i,
			we_o,
    		if_cnt_o,
    		w_cnt_o,
    		w_dat_o,
    		w_adr_o,
    		inst_adr_o,
    		if_adr_o,
    		ea_adr_o,
    		rd_adr_o
			
`ifdef	DEBUG
			,a_o,
			x_o,
			y_o,
			pf_u_dbg_o,
			dec_u_dbg_o,
			ea_u_dbg_o,
			rd_u_dbg_o,
			exe_u_dbg_o,
			wb_u_dbg_o
`endif
);

	//Input signals :
	input	wire			clk_i;
	input	wire			rst_i;
	input	wire			irq_i;
	input	wire			nmi_i;
	input	wire			rdy_i;
	input	wire			stl_i;
	input	wire	[23:0]	if_dat_i;
	input	wire	[15:0]	ea_dat_i;
	input	wire	[7:0]	rd_dat_i;
	input	wire	[7:0]	inst_i;
	
	//Output signals :
	output	wire			we_o;
	output	wire	[1:0]	if_cnt_o;
	output	wire	[1:0]	w_cnt_o;
	output	wire	[23:0]	w_dat_o;
	output	wire	[15:0]	w_adr_o;
	output	wire	[15:0]	inst_adr_o;
	output	wire	[15:0]	if_adr_o;
	output	wire	[15:0]	ea_adr_o;
	output	wire	[15:0]	rd_adr_o;
	
`ifdef	DEBUG
	output	wire	[7:0]	a_o;
	output	wire	[7:0]	x_o;
	output	wire	[7:0]	y_o;
	output	wire	[`PRF_DBG_WIDTH - 1:0]	pf_u_dbg_o;
	output	wire	[`DEC_DBG_WIDTH - 1:0]	dec_u_dbg_o;
	output	wire	[`EAD_DBG_WIDTH - 1:0]	ea_u_dbg_o;
	output	wire	[`RDA_DBG_WIDTH - 1:0]	rd_u_dbg_o;
	output	wire	[`EXE_DBG_WIDTH - 1:0]	exe_u_dbg_o;
	output	wire	[`WRB_DBG_WIDTH - 1:0]	wb_u_dbg_o;
`endif
	
	//Internal wires :
	wire					gbl_stl;
	wire			[2:0]	total_wait_sig;
	
	wire					pf_u_wait_to_fill_pipe_o;
	wire			[15:0]	pf_u_pc_o;
	wire			[23:0]	pf_u_fetched_ops_o;
	wire					pf_u_mem_enb_o;
	wire			[1:0]	pf_u_mem_if_cnt_o;
	wire			[15:0]	pf_u_mem_if_adr_o;
	wire			[15:0]	pf_u_mem_inst_adr_o;
	wire			[1:0]	dec_u_wait_sig_o;
	wire			[15:0]	dec_u_pc_o;
	wire			[15:0]	dec_u_operand_o;
	wire			[`decode_cntrl_o_width - 1:0]	dec_u_control_signal_o;
	wire					ea_u_refill_pipe_o;
	wire			[1:0]	ea_u_wait_sig_o;
	wire			[`effadr_cntrl_o_width - 1:0]	ea_u_control_signal_o;
	wire			[15:0]	ea_u_dat_o;
	wire			[15:0]	ea_u_jmp_adr_o;
	wire			[15:0]	ea_u_eff_adr_o;
	wire			[15:0]	ea_u_mem_ea_adr_o;
	wire			[`rddata_cntrl_o_width - 1:0]	rd_u_control_signal_o;
	wire			[15:0]	rd_u_dat_o;
	wire			[15:0]	rd_u_eff_adr_o;
	wire			[15:0]	rd_u_mem_rd_adr_o;
	wire			[7:0]	exe_u_p_o;
	wire			[`execut_cntrl_o_width - 1:0]	exe_u_control_signal_o;
	wire			[15:0]	exe_u_forwd_o;
	wire			[15:0]	exe_u_result_o;
	wire			[15:0]	exe_u_eff_adr_o;
	wire			[7:0]	wb_u_a_o;
	wire			[7:0]	wb_u_x_o;
	wire			[7:0]	wb_u_y_o;
	wire					wb_u_mem_w_enb_o;
	wire			[1:0]	wb_u_mem_w_cnt_o;
	wire			[15:0]	wb_u_mem_w_adr_o;
	wire			[23:0]	wb_u_mem_w_dat_o;
	
	//Internal registers :
	reg						jmp_rqst;
	
	//Assignments :
	assign gbl_stl = 1'h0;
	assign total_wait_sig = dec_u_wait_sig_o + ea_u_wait_sig_o;
	
	assign we_o = wb_u_mem_w_enb_o;
	assign if_cnt_o = pf_u_mem_if_cnt_o;
	assign w_cnt_o = wb_u_mem_w_cnt_o;
	assign w_dat_o = wb_u_mem_w_dat_o;
	assign w_adr_o = wb_u_mem_w_adr_o;
	assign inst_adr_o = pf_u_mem_inst_adr_o;
	assign if_adr_o = pf_u_mem_if_adr_o;
	assign ea_adr_o = ea_u_mem_ea_adr_o;
	assign rd_adr_o = rd_u_mem_rd_adr_o;
	
`ifdef	DEBUG
	assign a_o = wb_u_a_o;
	assign x_o = wb_u_x_o;
	assign y_o = wb_u_y_o;
`endif
	
	//Instantiation :
	Prefetch			pf_u
	(	
			.clk_i					(clk_i),
			.rst_i					(rst_i),					
			.gbl_stl_i				(gbl_stl),
			.irq_i					(irq_i),
			.nmi_i					(nmi_i),
			.rdy_i					(rdy_i),
			.int_dis_i				(exe_u_p_o[`I]),
			.wait_sig_i				(total_wait_sig),
			.refill_pipe_i			(ea_u_refill_pipe_o),
			.refill_start_adr_i		(ea_u_jmp_adr_o),
			.mem_stl_i				(stl_i),
			.mem_inst_i				(inst_i),
			.mem_dat_i				(if_dat_i),
			.wait_to_fill_pipe_o	(pf_u_wait_to_fill_pipe_o),
			.pc_o					(pf_u_pc_o),
			.fetched_ops_o			(pf_u_fetched_ops_o),
			.mem_if_cnt_o			(pf_u_mem_if_cnt_o),	
			.mem_if_adr_o			(pf_u_mem_if_adr_o),
			.mem_inst_adr_o			(pf_u_mem_inst_adr_o)
			
`ifdef	DEBUG
    		,.debug_o				(pf_u_dbg_o)
`endif	
	);
	
	Decode				dec_u
	(
			.clk_i					(clk_i),
			.rst_i					(rst_i),
			.gbl_stl_i				(gbl_stl),
			.jmp_rqst_i				(jmp_rqst),
			.wait_to_fill_pipe_i	(pf_u_wait_to_fill_pipe_o),
			.wait_sig_i				(ea_u_wait_sig_o),
			.p_i					(exe_u_p_o),
			.pc_i					(pf_u_pc_o),
			.mem_stl_i				(stl_i),
			.fetched_ops_i			(pf_u_fetched_ops_o),
			.wait_sig_o				(dec_u_wait_sig_o),
			.pc_o					(dec_u_pc_o),
			.operand_o				(dec_u_operand_o),
			.control_signal_o		(dec_u_control_signal_o)
			
`ifdef	DEBUG
    		,.debug_o				(dec_u_dbg_o)
`endif
	);
	
	Effective_Address	ea_u
	(
			.clk_i					(clk_i),
			.rst_i					(rst_i),
			.gbl_stl_i				(gbl_stl),
			.wait_to_fill_pipe_i	(pf_u_wait_to_fill_pipe_o),
			.wait_sig_i				(dec_u_wait_sig_o),
			.x_i					(wb_u_x_o),
			.y_i					(wb_u_y_o),
			.pc_i					(dec_u_pc_o),
			.forwd_i				(exe_u_result_o),
			.operand_i				(dec_u_operand_o),
			.control_signal_i		(dec_u_control_signal_o),
			.mem_stl_i				(stl_i),
			.mem_ea_dat_i			(ea_dat_i),
			.refill_pipe_o			(ea_u_refill_pipe_o),
			.wait_sig_o				(ea_u_wait_sig_o),
			.control_signal_o		(ea_u_control_signal_o),
			.dat_o					(ea_u_dat_o),
			.jmp_adr_o				(ea_u_jmp_adr_o),
			.eff_adr_o				(ea_u_eff_adr_o),
			.mem_ea_adr_o			(ea_u_mem_ea_adr_o)
			
`ifdef	DEBUG
    		,.debug_o				(ea_u_dbg_o)
`endif
	);
	
	Read_Data			rd_u
	(
			.clk_i					(clk_i),
			.rst_i					(rst_i),
			.gbl_stl_i				(gbl_stl),
			.wait_to_fill_pipe_i	(pf_u_wait_to_fill_pipe_o),
			.dat_i					(ea_u_dat_o),
			.forwd_i				(exe_u_forwd_o),
			.eff_adr_i				(ea_u_eff_adr_o),
			.control_signal_i		(ea_u_control_signal_o),
			.mem_stl_i				(stl_i),
			.mem_rd_dat_i			(rd_dat_i),
			.control_signal_o		(rd_u_control_signal_o),
			.dat_o					(rd_u_dat_o),
			.eff_adr_o				(rd_u_eff_adr_o),
			.mem_rd_adr_o			(rd_u_mem_rd_adr_o)
			
`ifdef	DEBUG
    		,.debug_o				(rd_u_dbg_o)
`endif
	);
	
	Execution			exe_u
	(
			.clk_i					(clk_i),
			.rst_i					(rst_i),
			.gbl_stl_i				(gbl_stl),
			.wait_to_fill_pipe_i	(pf_u_wait_to_fill_pipe_o),
			.a_i					(wb_u_a_o),
			.x_i					(wb_u_x_o),
			.y_i					(wb_u_y_o),
			.control_signal_i		(rd_u_control_signal_o),
			.operand_i				(rd_u_dat_o),
			.eff_adr_i				(rd_u_eff_adr_o),
			.mem_stl_i				(stl_i),
			.p_o					(exe_u_p_o),
			.control_signal_o		(exe_u_control_signal_o),
			.forwd_o				(exe_u_forwd_o),
			.result_o				(exe_u_result_o),
			.eff_adr_o				(exe_u_eff_adr_o)
			
`ifdef	DEBUG
    		,.debug_o				(exe_u_dbg_o)
`endif
	);
	
	Write_Back			wb_u
	(
			.clk_i					(clk_i),
			.rst_i					(rst_i),
			.gbl_stl_i				(gbl_stl),
			.wait_to_fill_pipe_i	(pf_u_wait_to_fill_pipe_o),
			.control_signal_i		(exe_u_control_signal_o),
			.p_i					(exe_u_p_o),
			.dat_i					(exe_u_result_o),
			.eff_adr_i				(exe_u_eff_adr_o),
			.mem_stl_i				(stl_i),
			.a_o					(wb_u_a_o),
			.x_o					(wb_u_x_o),
			.y_o					(wb_u_y_o),
			.mem_w_enb_o			(wb_u_mem_w_enb_o),
			.mem_w_cnt_o			(wb_u_mem_w_cnt_o),
			.mem_w_adr_o			(wb_u_mem_w_adr_o),
			.mem_w_dat_o			(wb_u_mem_w_dat_o)
			
`ifdef	DEBUG
    		,.debug_o				(wb_u_dbg_o)
`endif
	);
	
	//Blocks :
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1 || nmi_i == 1'h1 || (~exe_u_p_o[`I] && irq_i) == 1'h1)
		begin
			jmp_rqst <= 1'h1;
		end
		else
		begin
			jmp_rqst <= 1'h0;
		end
	end
endmodule
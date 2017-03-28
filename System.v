`include "Global_Macros.v"

module System(
	clk_i,
	rst_i,
	irq_i,
	nmi_i,
	rdy_i,
	mem_u_stl_o,
	mem_u_if_dat_o,
	mem_u_ea_dat_o,
	mem_u_rd_dat_o,
	mem_u_inst_o,
	core_u_we_o,
	core_u_if_cnt_o,
	core_u_w_cnt_o,
	core_u_w_dat_o,
	core_u_w_adr_o,
	core_u_inst_adr_o,
	core_u_if_adr_o,
	core_u_ea_adr_o,
	core_u_rd_adr_o
	
`ifdef	DEBUG
	,core_u_a_o,
	core_u_x_o,
	core_u_y_o,
	mem_u_dbg_o,
	core_u_pf_u_dbg_o,
	core_u_dec_u_dbg_o,
	core_u_ea_u_dbg_o,
	core_u_rd_u_dbg_o,
	core_u_exe_u_dbg_o,
	core_u_wb_u_dbg_o
`endif
);
	
	//Input signals :
	input	wire			clk_i;
	input	wire			rst_i;
	input	wire			irq_i;
	input	wire			nmi_i;
	input	wire			rdy_i;
	
	//Output signals :
	output	wire			mem_u_stl_o;
	output	wire			[23:0]	mem_u_if_dat_o;
	output	wire			[15:0]	mem_u_ea_dat_o;
	output	wire			[7:0]	mem_u_rd_dat_o;
	output	wire			[7:0]	mem_u_inst_o;
	output	wire			core_u_we_o;
	output	wire			[1:0]	core_u_if_cnt_o;
	output	wire			[1:0]	core_u_w_cnt_o;
	output	wire			[23:0]	core_u_w_dat_o;
	output	wire			[15:0]	core_u_w_adr_o;
	output	wire			[15:0]	core_u_inst_adr_o;
	output	wire			[15:0]	core_u_if_adr_o;
	output	wire			[15:0]	core_u_ea_adr_o;
	output	wire			[15:0]	core_u_rd_adr_o;
	
`ifdef	DEBUG
	output	wire			[7:0]	core_u_a_o;
	output	wire			[7:0]	core_u_x_o;
	output	wire			[7:0]	core_u_y_o;
	output	wire			[`MEM_DBG_WIDTH - 1:0]	mem_u_dbg_o;
	output	wire			[`PRF_DBG_WIDTH - 1:0]	core_u_pf_u_dbg_o;
	output	wire			[`DEC_DBG_WIDTH - 1:0]	core_u_dec_u_dbg_o;
	output	wire			[`EAD_DBG_WIDTH - 1:0]	core_u_ea_u_dbg_o;
	output	wire			[`RDA_DBG_WIDTH - 1:0]	core_u_rd_u_dbg_o;
	output	wire			[`EXE_DBG_WIDTH - 1:0]	core_u_exe_u_dbg_o;
	output	wire			[`WRB_DBG_WIDTH - 1:0]	core_u_wb_u_dbg_o;
`endif
	
	//Instantiations :
	Memory				mem_u
	(
			.clk_i					(clk_i),
    		.we_i					(core_u_we_o),
    		.if_cnt_i				(core_u_if_cnt_o),
    		.w_cnt_i				(core_u_w_cnt_o),
    		.w_dat_i				(core_u_w_dat_o),
    		.w_adr_i				(core_u_w_adr_o),
    		.inst_adr_i				(core_u_inst_adr_o),
    		.if_adr_i				(core_u_if_adr_o),
    		.ea_adr_i				(core_u_ea_adr_o),
    		.rd_adr_i				(core_u_rd_adr_o),
    		.stl_o					(mem_u_stl_o),
    		.if_dat_o				(mem_u_if_dat_o),
    		.ea_dat_o				(mem_u_ea_dat_o),
    		.rd_dat_o				(mem_u_rd_dat_o),
    		.inst_o					(mem_u_inst_o)
    		
`ifdef	DEBUG
    		,.debug_o				(mem_u_dbg_o)
`endif
	);
	
	Core				core_u
	(
			.clk_i					(clk_i),
			.rst_i					(rst_i),
			.irq_i					(irq_i),
			.nmi_i					(nmi_i),
			.rdy_i					(rdy_i),
			.stl_i					(mem_u_stl_o),
    		.if_dat_i				(mem_u_if_dat_o),
    		.ea_dat_i				(mem_u_ea_dat_o),
    		.rd_dat_i				(mem_u_rd_dat_o),
    		.inst_i					(mem_u_inst_o),
			.we_o					(core_u_we_o),
    		.if_cnt_o				(core_u_if_cnt_o),
    		.w_cnt_o				(core_u_w_cnt_o),
    		.w_dat_o				(core_u_w_dat_o),
    		.w_adr_o				(core_u_w_adr_o),
    		.inst_adr_o				(core_u_inst_adr_o),
    		.if_adr_o				(core_u_if_adr_o),
    		.ea_adr_o				(core_u_ea_adr_o),
    		.rd_adr_o				(core_u_rd_adr_o)
			
`ifdef	DEBUG
			,.a_o					(core_u_a_o),
			.x_o					(core_u_x_o),
			.y_o					(core_u_y_o),
			.pf_u_dbg_o				(core_u_pf_u_dbg_o),
			.dec_u_dbg_o			(core_u_dec_u_dbg_o),
			.ea_u_dbg_o				(core_u_ea_u_dbg_o),
			.rd_u_dbg_o				(core_u_rd_u_dbg_o),
			.exe_u_dbg_o			(core_u_exe_u_dbg_o),
			.wb_u_dbg_o				(core_u_wb_u_dbg_o)
`endif
	);
endmodule
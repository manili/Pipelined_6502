`include "Global_Macros.v"

module DUT;
	
	//Internal wires :
	wire			mem_u_stl_o;
	wire			[23:0]	mem_u_if_dat_o;
	wire			[15:0]	mem_u_ea_dat_o;
	wire			[7:0]	mem_u_rd_dat_o;
	wire			[7:0]	mem_u_inst_o;
	wire			core_u_we_o;
	wire			[1:0]	core_u_if_cnt_o;
	wire			[1:0]	core_u_w_cnt_o;
	wire			[23:0]	core_u_w_dat_o;
	wire			[15:0]	core_u_w_adr_o;
	wire			[15:0]	core_u_inst_adr_o;
	wire			[15:0]	core_u_if_adr_o;
	wire			[15:0]	core_u_ea_adr_o;
	wire			[15:0]	core_u_rd_adr_o;
	
`ifdef	DEBUG
	wire			[7:0]	core_u_a_o;
	wire			[7:0]	core_u_x_o;
	wire			[7:0]	core_u_y_o;
	wire			[`MEM_DBG_WIDTH - 1:0]	mem_u_dbg_o;
	wire			[`PRF_DBG_WIDTH - 1:0]	core_u_pf_u_dbg_o;
	wire			[`DEC_DBG_WIDTH - 1:0]	core_u_dec_u_dbg_o;
	wire			[`EAD_DBG_WIDTH - 1:0]	core_u_ea_u_dbg_o;
	wire			[`RDA_DBG_WIDTH - 1:0]	core_u_rd_u_dbg_o;
	wire			[`EXE_DBG_WIDTH - 1:0]	core_u_exe_u_dbg_o;
	wire			[`WRB_DBG_WIDTH - 1:0]	core_u_wb_u_dbg_o;
`endif
	
	//Internal registers :
	reg						clk;
	reg						rst;
	
	//Instantiations :
	System				sys_u
	(
			.clk_i					(clk),
			.rst_i					(rst),
			.irq_i					(1'h0),
			.nmi_i					(1'h0),
			.rdy_i					(1'h1),
			.mem_u_stl_o			(mem_u_stl_o),
			.mem_u_if_dat_o			(mem_u_if_dat_o),
			.mem_u_ea_dat_o			(mem_u_ea_dat_o),
			.mem_u_rd_dat_o			(mem_u_rd_dat_o),
			.mem_u_inst_o			(mem_u_inst_o),
			.core_u_we_o			(core_u_we_o),
			.core_u_if_cnt_o		(core_u_if_cnt_o),
			.core_u_w_cnt_o			(core_u_w_cnt_o),
			.core_u_w_dat_o			(core_u_w_dat_o),
			.core_u_w_adr_o			(core_u_w_adr_o),
			.core_u_inst_adr_o		(core_u_inst_adr_o),
			.core_u_if_adr_o		(core_u_if_adr_o),
			.core_u_ea_adr_o		(core_u_ea_adr_o),
			.core_u_rd_adr_o		(core_u_rd_adr_o)
	
`ifdef	DEBUG
			,.core_u_a_o			(core_u_a_o),
			.core_u_x_o				(core_u_x_o),
			.core_u_y_o				(core_u_y_o),
			.mem_u_dbg_o			(mem_u_dbg_o),
			.core_u_pf_u_dbg_o		(core_u_pf_u_dbg_o),
			.core_u_dec_u_dbg_o		(core_u_dec_u_dbg_o),
			.core_u_ea_u_dbg_o		(core_u_ea_u_dbg_o),
			.core_u_rd_u_dbg_o		(core_u_rd_u_dbg_o),
			.core_u_exe_u_dbg_o		(core_u_exe_u_dbg_o),
			.core_u_wb_u_dbg_o		(core_u_wb_u_dbg_o)
`endif
	);
	
	//Blocks :
	initial
	begin
		//Program stop time block:
		#15000;
		$stop;
	end
	
	initial
	begin
		//Reset signal controller block:
		rst <= 1'h0;
		#125;
		rst <= 1'h1;
		#25;
		rst <= 1'h1;
		#25;
		rst <= 1'h0;
	end

	initial
	begin
		//Clock initial block:
		clk <= 1'h0;
	end
	
	always
	begin
		//Clock signal controller block:
		#50;
		clk <= ~clk;
	end
endmodule
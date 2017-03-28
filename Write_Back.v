`include "Global_Macros.v"

module Write_Back(
					clk_i,
					rst_i,
					gbl_stl_i,
					wait_to_fill_pipe_i,
					control_signal_i,
					p_i,
					dat_i,
					eff_adr_i,
					mem_stl_i,
					a_o,
					x_o,
					y_o,
					mem_w_enb_o,
					mem_w_cnt_o,
					mem_w_adr_o,
					mem_w_dat_o

`ifdef	DEBUG
					,debug_o
`endif
);
	
	//Input signals :
	input	wire			clk_i;
	input	wire			rst_i;
	input	wire			gbl_stl_i;
	input	wire			wait_to_fill_pipe_i;
	input	wire	[`execut_cntrl_o_width - 1:0]	control_signal_i;
	input	wire	[7:0]	p_i;
	input	wire	[15:0]	dat_i;
	input	wire	[15:0]	eff_adr_i;
	input	wire			mem_stl_i;
	
	//Output signals :
	output	wire	[7:0]	a_o;
	output	wire	[7:0]	x_o;
	output	wire	[7:0]	y_o;
	output	reg				mem_w_enb_o;
	output	reg		[1:0]	mem_w_cnt_o;
	output	reg		[15:0]	mem_w_adr_o;
	output	reg		[23:0]	mem_w_dat_o;

`ifdef	DEBUG
	output	wire	[`WRB_DBG_WIDTH - 1:0]	debug_o;
`endif
	
	//Internal registers :
	reg				[7:0]	a_reg;
	reg				[7:0]	x_reg;
	reg				[7:0]	y_reg;
	
	//Assignments :
	assign a_o = a_reg;
	assign x_o = x_reg;
	assign y_o = y_reg;
	
`ifdef	DEBUG
	assign debug_o = mem_w_adr_o;
`endif
	
	//Blocks :
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			mem_w_enb_o <= 1'h0;
			mem_w_cnt_o <= `ONE;
		end
		else if(gbl_stl_i == 1'h1 || mem_stl_i == 1'h1)
		begin
			mem_w_enb_o <= 1'h0;
		end
		else if(wait_to_fill_pipe_i == 1'h1)
		begin
			mem_w_enb_o <= 1'h0;
		end
		else
		begin
			mem_w_enb_o	<=		`cntrl_wb_mem_wr;
			mem_w_cnt_o	<=	(	`cntrl_wb_mem_wr_cnt == `ONE	)	?	2'h0		:
							(	`cntrl_wb_mem_wr_cnt == `TWO	)	?	2'h1		:	2'h2;
			mem_w_dat_o	<=	{p_i, dat_i};
			mem_w_adr_o	<=	eff_adr_i;
		end
	end
	
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			a_reg	<=	8'h0;
			x_reg	<=	8'h0;
			y_reg	<=	8'h0;
		end
		else if(gbl_stl_i == 1'h1 || mem_stl_i == 1'h1)
		begin
			
		end
		else if(wait_to_fill_pipe_i == 1'h1)
		begin
			
		end
		else
		begin
			a_reg	<=	(`cntrl_wb_ra_ld == 1'h1)	?	dat_i[7:0]	:	a_reg;
			x_reg	<=	(`cntrl_wb_rx_ld == 1'h1)	?	dat_i[7:0]	:	x_reg;
			y_reg	<=	(`cntrl_wb_ry_ld == 1'h1)	?	dat_i[7:0]	:	y_reg;
		end
	end
endmodule
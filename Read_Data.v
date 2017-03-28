`include "Global_Macros.v"

module Read_Data(
				clk_i,
				rst_i,
				gbl_stl_i,
				wait_to_fill_pipe_i,
				dat_i,
				forwd_i,
				eff_adr_i,
				control_signal_i,
				mem_stl_i,
				mem_rd_dat_i,
				control_signal_o,
				dat_o,
				eff_adr_o,
				mem_rd_adr_o

`ifdef	DEBUG
				,debug_o
`endif
);

	//Input signals :
	input	wire			clk_i;
	input	wire			rst_i;
	input	wire			gbl_stl_i;
	input	wire			wait_to_fill_pipe_i;
	input	wire	[15:0]	dat_i;
	input	wire	[15:0]	forwd_i;
	input	wire	[15:0]	eff_adr_i;
	input	wire	[`effadr_cntrl_o_width - 1:0]	control_signal_i;
	input	wire			mem_stl_i;
	input	wire	[7:0]	mem_rd_dat_i;
	
	//Output signals :
	output	reg		[`rddata_cntrl_o_width - 1:0]	control_signal_o;
	output	reg		[15:0]	dat_o;
	output	reg		[15:0]	eff_adr_o;
	output	wire	[15:0]	mem_rd_adr_o;

`ifdef	DEBUG
	output	wire	[`RDA_DBG_WIDTH - 1:0]	debug_o;
`endif
	
	//Internal wires :
	wire			[15:0]	mux4x1_o;
	
	//Internal registers :
	
	//Assignments :
	assign mem_rd_adr_o = eff_adr_i;
	
`ifdef	DEBUG
	assign debug_o = eff_adr_i;
`endif
	
	//Instantiations :
	MUX4x1 #(16) mux4x1_1(mux4x1_o, `cntrl_rd_src, 16'h0, dat_i, {8'h0, mem_rd_dat_i}, forwd_i);
	
	//Blocks :
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			control_signal_o <= `rddata_cntrl_o_width'h0;
		end
		else if(gbl_stl_i == 1'h1 || mem_stl_i == 1'h1)
		begin
			
		end
		else if(wait_to_fill_pipe_i == 1'h1)
		begin
			
		end
		else
		begin
			dat_o <= mux4x1_o;
			control_signal_o <= control_signal_i[`rddata_cntrl_o_width - 1:0];
			eff_adr_o <= eff_adr_i;
		end
	end
endmodule
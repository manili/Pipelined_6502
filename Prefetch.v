`include "Global_Macros.v"

module Prefetch(	
			clk_i,
			rst_i,
			gbl_stl_i,
			irq_i,
			nmi_i,
			rdy_i,
			int_dis_i,
			wait_sig_i,
			refill_pipe_i,
			refill_start_adr_i,
			mem_stl_i,
			mem_inst_i,
			mem_dat_i,
			wait_to_fill_pipe_o,
			pc_o,
			fetched_ops_o,
			mem_if_cnt_o,
			mem_if_adr_o,
			mem_inst_adr_o

`ifdef	DEBUG
			,debug_o
`endif
);
	
	//Input signals :
	input 	wire			clk_i;
	input 	wire	 		rst_i;
	input	wire			gbl_stl_i;
	input	wire			irq_i;
	input	wire			nmi_i;
	input	wire			rdy_i;
	input	wire			int_dis_i;
	input	wire	[2:0]	wait_sig_i;
	input	wire			refill_pipe_i;
	input	wire	[15:0]	refill_start_adr_i;
	input	wire			mem_stl_i;
	input	wire	[7:0]	mem_inst_i;
	input 	wire	[23:0]	mem_dat_i;
	
	//Output signals :
	output	wire			wait_to_fill_pipe_o;
	output	wire	[15:0]	pc_o;
	output	reg		[23:0]	fetched_ops_o;
	output	wire	[1:0]	mem_if_cnt_o;
	output	wire	[15:0]	mem_if_adr_o;
	output	wire	[15:0]	mem_inst_adr_o;
	
`ifdef	DEBUG
	output	wire	[`PRF_DBG_WIDTH - 1:0]	debug_o;
`endif
	
	//Internal wires:
	wire			[1:0]	used_byte_cnt;
	
	//Internal registers :
	reg						wait_to_fill_pipe_reg;
	reg						flag_reg;
	reg				[1:0]	used_byte_cnt_reg;
	reg				[7:0]	refill_op_reg;
	reg				[15:0]	next_inst_adr;
	reg				[15:0]	pc_reg;
	
	//Assignments :
	assign pc_o = pc_reg;
	assign wait_to_fill_pipe_o = (refill_pipe_i == 1'h1) ? 1'h1 : wait_to_fill_pipe_reg;
	assign mem_if_cnt_o = used_byte_cnt;
	assign mem_if_adr_o = (refill_pipe_i == 1'h1) ? refill_start_adr_i : pc_reg;
	assign mem_inst_adr_o = next_inst_adr;
	
	assign used_byte_cnt = (wait_to_fill_pipe_o == 1'h1) ? 2'h3 : used_byte_cnt_reg;
	
`ifdef	DEBUG
	assign debug_o = fetched_ops_o;
`endif
	
	//Blocks :
	always @(*)
	begin
		case(mem_inst_i)
			`ASL_ACU,
			`BRK,
			`CLC,
			`CLD,
			`CLI,
			`CLV,
			`DEX,
			`DEY,
			`INX,
			`INY,
			`LSR_ACU,
			`NOP,
			`PHA,
			`PHP,
			`PLA,
			`PLP,
			`ROL_ACU,
			`ROR_ACU,
			`RTI,
			`RTS,
			`SEC,
			`SED,
			`SEI,
			`TAX,
			`TAY,
			`TSX,
			`TXA,
			`TXS,
			`TYA		:	used_byte_cnt_reg = 2'h1;
			
			`ADC_IME,
			`ADC_I_X,
			`ADC_I_Y,
			`ADC_ZP,
			`ADC_ZP_X,
			`AND_IME,
			`AND_I_X,
			`AND_I_Y,
			`AND_ZP,
			`AND_ZP_X,
			`ASL_ZP,
			`ASL_ZP_X,
			`BCC,
			`BCS,
			`BEQ,
			`BIT_ZP,
			`BMI,
			`BNE,
			`BPL,
			`BVC,
			`BVS,
			`CMP_IME,
			`CMP_I_X,
			`CMP_I_Y,
			`CMP_ZP,
			`CMP_ZP_X,
			`CPX_IME,
			`CPX_ZP,
			`CPY_IME,
			`CPY_ZP,
			`DEC_ZP,
			`DEC_ZP_X,
			`EOR_IME,
			`EOR_I_X,
			`EOR_I_Y,
			`EOR_ZP,
			`EOR_ZP_X,
			`INC_ZP,
			`INC_ZP_X,
			`LDA_IME,
			`LDA_I_X,
			`LDA_I_Y,
			`LDA_ZP,
			`LDA_ZP_X,
			`LDX_IME,
			`LDX_ZP,
			`LDX_ZP_Y,
			`LDY_IME,
			`LDY_ZP,
			`LDY_ZP_X,
			`LSR_ZP,
			`LSR_ZP_X,
			`ORA_IME,
			`ORA_I_X,
			`ORA_I_Y,
			`ORA_ZP,
			`ORA_ZP_X,
			`ROL_ZP,
			`ROL_ZP_X,
			`ROR_ZP,
			`ROR_ZP_X,
			`SBC_IME,
			`SBC_I_X,
			`SBC_I_Y,
			`SBC_ZP,
			`SBC_ZP_X,
			`STA_I_X,
			`STA_I_Y,
			`STA_ZP,
			`STA_ZP_X,
			`STX_ZP,
			`STX_ZP_Y,
			`STY_ZP,
			`STY_ZP_X	:	used_byte_cnt_reg = 2'h2;
			
			`ADC_ABS,
			`ADC_ABS_X,
			`ADC_ABS_Y,
			`AND_ABS,
			`AND_ABS_X,
			`AND_ABS_Y,
			`ASL_ABS,
			`ASL_ABS_X,
			`BIT_ABS,
			`CMP_ABS,
			`CMP_ABS_X,
			`CMP_ABS_Y,
			`CPX_ABS,
			`CPY_ABS,
			`DEC_ABS,
			`DEC_ABS_X,
			`EOR_ABS,
			`EOR_ABS_X,
			`EOR_ABS_Y,
			`INC_ABS,
			`INC_ABS_X,
			`JMP_ABS,
			`JMP_I,
			`JSR,
			`LDA_ABS,
			`LDA_ABS_X,
			`LDA_ABS_Y,
			`LDX_ABS,
			`LDX_ABS_Y,
			`LDY_ABS,
			`LDY_ABS_X,
			`LSR_ABS,
			`LSR_ABS_X,
			`ORA_ABS,
			`ORA_ABS_X,
			`ORA_ABS_Y,
			`ROL_ABS,
			`ROL_ABS_X,
			`ROR_ABS,
			`ROR_ABS_X,
			`SBC_ABS,
			`SBC_ABS_X,
			`SBC_ABS_Y,
			`STA_ABS,
			`STA_ABS_X,
			`STA_ABS_Y,
			`STX_ABS,
			`STY_ABS	:	used_byte_cnt_reg = 2'h3;
			
			default		:	used_byte_cnt_reg = 2'h0;
		endcase
	end
	
	always @(posedge clk_i)
	begin
		if(rst_i == 1'h1)
		begin
			next_inst_adr = `P_C_START;
		end
		else if(gbl_stl_i == 1'h1 || rdy_i == 1'h0 || mem_stl_i == 1'h1 || wait_sig_i - 3'h1 != 3'h7)
		begin
			
		end
		else if(wait_to_fill_pipe_o == 1'h1)
		begin
			next_inst_adr = refill_start_adr_i;
		end
		else
		begin
			case(mem_inst_i)
				`ASL_ACU,
				`BRK,
				`CLC,
				`CLD,
				`CLI,
				`CLV,
				`DEX,
				`DEY,
				`INX,
				`INY,
				`LSR_ACU,
				`NOP,
				`PHA,
				`PHP,
				`PLA,
				`PLP,
				`ROL_ACU,
				`ROR_ACU,
				`RTI,
				`RTS,
				`SEC,
				`SED,
				`SEI,
				`TAX,
				`TAY,
				`TSX,
				`TXA,
				`TXS,
				`TYA		:	next_inst_adr = next_inst_adr + 2'h1;
				
				`ADC_IME,
				`ADC_I_X,
				`ADC_I_Y,
				`ADC_ZP,
				`ADC_ZP_X,
				`AND_IME,
				`AND_I_X,
				`AND_I_Y,
				`AND_ZP,
				`AND_ZP_X,
				`ASL_ZP,
				`ASL_ZP_X,
				`BCC,
				`BCS,
				`BEQ,
				`BIT_ZP,
				`BMI,
				`BNE,
				`BPL,
				`BVC,
				`BVS,
				`CMP_IME,
				`CMP_I_X,
				`CMP_I_Y,
				`CMP_ZP,
				`CMP_ZP_X,
				`CPX_IME,
				`CPX_ZP,
				`CPY_IME,
				`CPY_ZP,
				`DEC_ZP,
				`DEC_ZP_X,
				`EOR_IME,
				`EOR_I_X,
				`EOR_I_Y,
				`EOR_ZP,
				`EOR_ZP_X,
				`INC_ZP,
				`INC_ZP_X,
				`LDA_IME,
				`LDA_I_X,
				`LDA_I_Y,
				`LDA_ZP,
				`LDA_ZP_X,
				`LDX_IME,
				`LDX_ZP,
				`LDX_ZP_Y,
				`LDY_IME,
				`LDY_ZP,
				`LDY_ZP_X,
				`LSR_ZP,
				`LSR_ZP_X,
				`ORA_IME,
				`ORA_I_X,
				`ORA_I_Y,
				`ORA_ZP,
				`ORA_ZP_X,
				`ROL_ZP,
				`ROL_ZP_X,
				`ROR_ZP,
				`ROR_ZP_X,
				`SBC_IME,
				`SBC_I_X,
				`SBC_I_Y,
				`SBC_ZP,
				`SBC_ZP_X,
				`STA_I_X,
				`STA_I_Y,
				`STA_ZP,
				`STA_ZP_X,
				`STX_ZP,
				`STX_ZP_Y,
				`STY_ZP,
				`STY_ZP_X	:	next_inst_adr = next_inst_adr + 2'h2;
				
				`ADC_ABS,
				`ADC_ABS_X,
				`ADC_ABS_Y,
				`AND_ABS,
				`AND_ABS_X,
				`AND_ABS_Y,
				`ASL_ABS,
				`ASL_ABS_X,
				`BIT_ABS,
				`CMP_ABS,
				`CMP_ABS_X,
				`CMP_ABS_Y,
				`CPX_ABS,
				`CPY_ABS,
				`DEC_ABS,
				`DEC_ABS_X,
				`EOR_ABS,
				`EOR_ABS_X,
				`EOR_ABS_Y,
				`INC_ABS,
				`INC_ABS_X,
				`JMP_ABS,
				`JMP_I,
				`JSR,
				`LDA_ABS,
				`LDA_ABS_X,
				`LDA_ABS_Y,
				`LDX_ABS,
				`LDX_ABS_Y,
				`LDY_ABS,
				`LDY_ABS_X,
				`LSR_ABS,
				`LSR_ABS_X,
				`ORA_ABS,
				`ORA_ABS_X,
				`ORA_ABS_Y,
				`ROL_ABS,
				`ROL_ABS_X,
				`ROR_ABS,
				`ROR_ABS_X,
				`SBC_ABS,
				`SBC_ABS_X,
				`SBC_ABS_Y,
				`STA_ABS,
				`STA_ABS_X,
				`STA_ABS_Y,
				`STX_ABS,
				`STY_ABS	:	next_inst_adr = next_inst_adr + 2'h3;
				
				default		:	next_inst_adr = next_inst_adr + 2'h0;
			endcase
		end
	end
	
	always @(posedge clk_i)
	begin
		//TODO: Don't forget forwarded I flag needs to be
		//checked before the EXE stage
		if(rst_i == 1'h1 || nmi_i == 1'h1 || (~int_dis_i && irq_i) == 1'h1)
		begin
			flag_reg <= 2'h0;
			wait_to_fill_pipe_reg <= 1'h0;
			pc_reg <= `P_C_START;
		end
		else if(gbl_stl_i == 1'h1 || rdy_i == 1'h0 || mem_stl_i == 1'h1 || wait_sig_i - 3'h1 != 3'h7)
		begin
			
		end
		else if(wait_to_fill_pipe_o == 1'h1)
		begin
			if(flag_reg == 2'h0)
			begin
				flag_reg <= 2'h1;
				refill_op_reg <= mem_dat_i[7:0];
				wait_to_fill_pipe_reg <= 1'h1;
				pc_reg <= refill_start_adr_i + 4'h3;
			end
			else
			begin
				flag_reg <= 2'h0;
				wait_to_fill_pipe_reg <= 1'h0;
				pc_reg <= refill_start_adr_i + 4'h6;
			end
		end
		else
		begin
			refill_op_reg <= `NOTHING;
			pc_reg <= pc_reg + used_byte_cnt;
		end
	end
	
	always @(posedge clk_i)
	begin
		if(rdy_i == 1'h0)
		begin
		
		end
		else if(rst_i == 1'h1)
		begin
			fetched_ops_o <= {8'hFF, 8'hFC, `JMP_I};
		end
		else if(nmi_i == 1'h1)
		begin
			fetched_ops_o <= {8'hFF, 8'hFA, `JMP_I};
		end
		//TODO: Don't forget forwarded I flag needs to be
		//checked before the EXE stage
		else if((~int_dis_i && irq_i) == 1'h1)
		begin
			fetched_ops_o <= {8'hFF, 8'hFE, `JMP_I};
		end
		else if(wait_sig_i - 3'h1 == 3'h7)
		begin
			case(used_byte_cnt)
				2'h0	:	fetched_ops_o <= fetched_ops_o;
				2'h1	:	fetched_ops_o <= {mem_dat_i[7:0], fetched_ops_o[23:8]};
				2'h2	:	fetched_ops_o <= {mem_dat_i[15:0], fetched_ops_o[23:16]};
				2'h3	:	fetched_ops_o <= mem_dat_i;
			endcase
		end
		else
		begin
			fetched_ops_o <= fetched_ops_o;
		end
	end
endmodule
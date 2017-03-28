`timescale 1 ns/1 ps
`include "Control_Macros.v"

//////////////////////////////////////////////////////////////////////////////////////////
//Decode Unit Macros                                                                    //
//////////////////////////////////////////////////////////////////////////////////////////

//DEC: Op-Codes Macros :

`define	BRK					8'h00
`define	ORA_I_X				8'h01
//`define	F_E				8'h02
//`define	F_E				8'h03
//`define	F_E				8'h04
`define	ORA_ZP				8'h05
`define	ASL_ZP				8'h06
//`define	F_E				8'h07
`define	PHP					8'h08
`define	ORA_IME				8'h09
`define	ASL_ACU				8'h0A
//`define	F_E				8'h0B
//`define	F_E				8'h0C
`define	ORA_ABS				8'h0D
`define	ASL_ABS				8'h0E
//`define	F_E				8'h0F
`define	BPL					8'h10
`define	ORA_I_Y				8'h11
//`define	F_E				8'h12
//`define	F_E				8'h13
//`define	F_E				8'h14
`define	ORA_ZP_X			8'h15
`define	ASL_ZP_X			8'h16
//`define	F_E				8'h17
`define	CLC					8'h18
`define	ORA_ABS_Y			8'h19
//`define	F_E				8'h1A
//`define	F_E				8'h1B
//`define	F_E				8'h1C
`define	ORA_ABS_X			8'h1D
`define	ASL_ABS_X			8'h1E
//`define	F_E				8'h1F
`define	JSR					8'h20
`define	AND_I_X				8'h21
//`define	F_E				8'h22
//`define	F_E				8'h23
`define	BIT_ZP				8'h24
`define	AND_ZP				8'h25
`define	ROL_ZP				8'h26
//`define	F_E				8'h27
`define	PLP					8'h28
`define	AND_IME				8'h29
`define	ROL_ACU				8'h2A
//`define	F_E				8'h2B
`define	BIT_ABS				8'h2C
`define	AND_ABS				8'h2D
`define	ROL_ABS				8'h2E
//`define	F_E				8'h2F
`define	BMI					8'h30
`define	AND_I_Y				8'h31
//`define	F_E				8'h32
//`define	F_E				8'h33
//`define	F_E				8'h34
`define	AND_ZP_X			8'h35
`define	ROL_ZP_X			8'h36
//`define	F_E				8'h37
`define	SEC					8'h38
`define	AND_ABS_Y			8'h39
//`define	F_E				8'h3A
//`define	F_E				8'h3B
//`define	F_E				8'h3C
`define	AND_ABS_X			8'h3D
`define	ROL_ABS_X			8'h3E
//`define	F_E				8'h3F
`define	RTI					8'h40
`define	EOR_I_X				8'h41
//`define	F_E				8'h42
//`define	F_E				8'h43
//`define	F_E				8'h44
`define	EOR_ZP				8'h45
`define	LSR_ZP				8'h46
//`define	F_E				8'h47
`define	PHA					8'h48
`define	EOR_IME				8'h49
`define	LSR_ACU				8'h4A
//`define	F_E				8'h4B
`define	JMP_ABS				8'h4C
`define	EOR_ABS				8'h4D
`define	LSR_ABS				8'h4E
//`define	F_E				8'h4F
`define	BVC					8'h50
`define	EOR_I_Y				8'h51
//`define	F_E				8'h52
//`define	F_E				8'h53
//`define	F_E				8'h54
`define	EOR_ZP_X			8'h55
`define	LSR_ZP_X			8'h56
//`define	F_E				8'h57
`define	CLI					8'h58
`define	EOR_ABS_Y			8'h59
//`define	F_E				8'h5A
//`define	F_E				8'h5B
//`define	F_E				8'h5C
`define	EOR_ABS_X			8'h5D
`define	LSR_ABS_X			8'h5E
//`define	F_E				8'h5F
`define	RTS					8'h60
`define	ADC_I_X				8'h61
//`define	F_E				8'h62
//`define	F_E				8'h63
//`define	F_E				8'h64
`define	ADC_ZP				8'h65
`define	ROR_ZP				8'h66
//`define	F_E				8'h67
`define	PLA					8'h68
`define	ADC_IME				8'h69
`define	ROR_ACU				8'h6A
//`define	F_E				8'h6B
`define	JMP_I				8'h6C
`define	ADC_ABS				8'h6D
`define	ROR_ABS				8'h6E
//`define	F_E				8'h6F
`define	BVS					8'h70
`define	ADC_I_Y				8'h71
//`define	F_E				8'h72
//`define	F_E				8'h73
//`define	F_E				8'h74
`define	ADC_ZP_X			8'h75
`define	ROR_ZP_X			8'h76
//`define	F_E				8'h77
`define	SEI					8'h78
`define	ADC_ABS_Y			8'h79
//`define	F_E				8'h7A
//`define	F_E				8'h7B
//`define	F_E				8'h7C
`define	ADC_ABS_X			8'h7D
`define	ROR_ABS_X			8'h7E
//`define	F_E				8'h7F
//`define	F_E				8'h80
`define	STA_I_X				8'h81
//`define	F_E				8'h82
//`define	F_E				8'h83
`define	STY_ZP				8'h84
`define	STA_ZP				8'h85
`define	STX_ZP				8'h86
//`define	F_E				8'h87
`define	DEY					8'h88
//`define	F_E				8'h89
`define	TXA					8'h8A
//`define	F_E				8'h8B
`define	STY_ABS				8'h8C
`define	STA_ABS				8'h8D
`define	STX_ABS				8'h8E
//`define	F_E				8'h8F
`define	BCC					8'h90
`define	STA_I_Y				8'h91
//`define	F_E				8'h92
//`define	F_E				8'h93
`define	STY_ZP_X			8'h94
`define	STA_ZP_X			8'h95
`define	STX_ZP_Y			8'h96
//`define	F_E				8'h97
`define	TYA					8'h98
`define	STA_ABS_Y			8'h99
`define	TXS					8'h9A
//`define	F_E				8'h9B
//`define	F_E				8'h9C
`define	STA_ABS_X			8'h9D
//`define	F_E				8'h9E
//`define	F_E				8'h9F
`define	LDY_IME				8'hA0
`define	LDA_I_X				8'hA1
`define	LDX_IME				8'hA2
//`define	F_E				8'hA3
`define	LDY_ZP				8'hA4
`define	LDA_ZP				8'hA5
`define	LDX_ZP				8'hA6
//`define	F_E				8'hA7
`define	TAY					8'hA8
`define	LDA_IME				8'hA9
`define	TAX					8'hAA
//`define	F_E				8'hAB
`define	LDY_ABS				8'hAC
`define	LDA_ABS				8'hAD
`define	LDX_ABS				8'hAE
//`define	F_E				8'hAF
`define	BCS					8'hB0
`define	LDA_I_Y				8'hB1
//`define	F_E				8'hB2
//`define	F_E				8'hB3
`define	LDY_ZP_X			8'hB4
`define	LDA_ZP_X			8'hB5
`define	LDX_ZP_Y			8'hB6
//`define	F_E				8'hB7
`define	CLV					8'hB8
`define	LDA_ABS_Y			8'hB9
`define	TSX					8'hBA
//`define	F_E				8'hBB
`define	LDY_ABS_X			8'hBC
`define	LDA_ABS_X			8'hBD
`define	LDX_ABS_Y			8'hBE
//`define	F_E				8'hBF
`define	CPY_IME				8'hC0
`define	CMP_I_X				8'hC1
//`define	F_E				8'hC2
//`define	F_E				8'hC3
`define	CPY_ZP				8'hC4
`define	CMP_ZP				8'hC5
`define	DEC_ZP				8'hC6
//`define	F_E				8'hC7
`define	INY					8'hC8
`define	CMP_IME				8'hC9
`define	DEX					8'hCA
//`define	F_E				8'hCB
`define	CPY_ABS				8'hCC
`define	CMP_ABS				8'hCD
`define	DEC_ABS				8'hCE
//`define	F_E				8'hCF
`define	BNE					8'hD0
`define	CMP_I_Y				8'hD1
//`define	F_E				8'hD2
//`define	F_E				8'hD3
//`define	F_E				8'hD4
`define	CMP_ZP_X			8'hD5
`define	DEC_ZP_X			8'hD6
//`define	F_E				8'hD7
`define	CLD					8'hD8
`define	CMP_ABS_Y			8'hD9
//`define	F_E				8'hDA
//`define	F_E				8'hDB
//`define	F_E				8'hDC
`define	CMP_ABS_X			8'hDD
`define	DEC_ABS_X			8'hDE
//`define	F_E				8'hDF
`define	CPX_IME				8'hE0
`define	SBC_I_X				8'hE1
//`define	F_E				8'hE2
//`define	F_E				8'hE3
`define	CPX_ZP				8'hE4
`define	SBC_ZP				8'hE5
`define	INC_ZP				8'hE6
//`define	F_E				8'hE7
`define	INX					8'hE8
`define	SBC_IME				8'hE9
`define	NOP					8'hEA
//`define	F_E				8'hEB
`define	CPX_ABS				8'hEC
`define	SBC_ABS				8'hED
`define	INC_ABS				8'hEE
//`define	F_E				8'hEF
`define	BEQ					8'hF0
`define	SBC_I_Y				8'hF1
//`define	F_E				8'hF2
//`define	F_E				8'hF3
//`define	F_E				8'hF4
`define	SBC_ZP_X			8'hF5
`define	INC_ZP_X			8'hF6
//`define	F_E				8'hF7
`define	SED					8'hF8
`define	SBC_ABS_Y			8'hF9
//`define	F_E				8'hFA
//`define	F_E				8'hFB
//`define	F_E				8'hFC
`define	SBC_ABS_X			8'hFD
`define	INC_ABS_X			8'hFE
`define	NOTHING				8'hFF

//////////////////////////////////////////////////////////////////////////////////////////
//Effective Address Unit Macros                                                         //
//////////////////////////////////////////////////////////////////////////////////////////

//EA: Stack Operation Macros :

`define	STACK_OP_NONE		4'h0
`define	STACK_OP_PUSH		4'h1
`define	STACK_OP_PC_PUSH	4'h2
`define	STACK_OP_P_PC_PUSH	4'h3
`define	STACK_OP_POP		4'h4
`define	STACK_OP_PC_POP		4'h5
`define	STACK_OP_P_PC_POP	4'h6
`define STACK_OP_X			4'h7
`define	STACK_OP_FORWD		4'h8

//EA: Address Offset Sources Macros :

`define	ADR_OFF_FORWD		2'h0
`define	ADR_OFF_X			2'h1	
`define	ADR_OFF_Y			2'h2
`define	ADR_OFF_NA			2'h3

//EA: Jump Mode Macros :

`define	NEXT_INST			1'h0
`define	JUMP_INST			1'h1

//EA: Address Source Macros :

`define	NO_ADR				1'h0
`define	EA_ADR				1'h0
`define	SP_ADR				1'h1

//EA: Addressing Mode Macros :

`define	MOD_NON				1'h0
`define	MOD_DIR				1'h0
`define	MOD_INDIR			1'h1
`define	MOD_STACK			1'h1

//////////////////////////////////////////////////////////////////////////////////////////
//Read Data Unit Macros                                                                 //
//////////////////////////////////////////////////////////////////////////////////////////

//RD: Source Macros :

`define	TYPE_IMP			2'h0
`define	TYPE_IME			2'h1
`define	TYPE_ADR			2'h2
`define	TYPE_FORWD			2'h3

//////////////////////////////////////////////////////////////////////////////////////////
//Execution Unit Macros                                                                 //
//////////////////////////////////////////////////////////////////////////////////////////

//EXE: ALU Operations Macros :

`define	ALU_ADD				5'h00
`define	ALU_AND				5'h01
`define	ALU_BRK				5'h02
`define	ALU_CLC				5'h03
`define	ALU_CLD				5'h04
`define	ALU_CLI				5'h05
`define	ALU_CLV				5'h06
`define	ALU_CMP				5'h07
`define	ALU_DEC				5'h08
`define	ALU_INC				5'h09
`define	ALU_ITO				5'h0A			//Input1 to Output
`define	ALU_ITF				5'h0B			//Input1 to Flag Register
`define	ALU_ORA				5'h0C
`define	ALU_ROL				5'h0D
`define	ALU_ROR				5'h0E
`define	ALU_SEC				5'h0F
`define	ALU_SED				5'h10
`define	ALU_SEI				5'h11
`define	ALU_SHL				5'h12
`define	ALU_SHR				5'h13
`define	ALU_SUB				5'h14
`define ALU_XOR				5'h15

`define	ALU_NOP				5'h1F

//EXE: ALU Operators Select Macros :

`define	ALU_OP1_SRC_DC		1'h0			//Don't Care
`define	ALU_OP1_SRC_DAT		1'h0
`define	ALU_OP1_SRC_OP2		1'h1

`define	ALU_OP2_SRC_DC		3'h0			//Don't Care
`define	ALU_OP2_SRC_A		3'h0
`define	ALU_OP2_SRC_X		3'h1
`define	ALU_OP2_SRC_Y		3'h2
`define	ALU_OP2_SRC_P		3'h3
`define	ALU_OP2_SRC_S		3'h4
`define	ALU_OP2_SRC_RESERVED1	3'h5
`define	ALU_OP2_SRC_RESERVED2	3'h6
`define	ALU_OP2_SRC_FORWD	3'h7

//EXE: Status Register Bits Macros :

`define	C					0
`define	Z					1
`define	I					2
`define	D					3
`define	B					4
`define	P					5
`define	V					6
`define	N					7

//////////////////////////////////////////////////////////////////////////////////////////
//Write Back Unit Macros                                                                //
//////////////////////////////////////////////////////////////////////////////////////////

//WB: Bytes Count Macros :

`define	NON					2'h0
`define	ONE					2'h0
`define	TWO					2'h1
`define	THR					2'h2

//////////////////////////////////////////////////////////////////////////////////////////
//Other Macros                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////

//Other Macros :

`define	DEACTIVE			1'h0
`define	ACTIVE				1'h1

//////////////////////////////////////////////////////////////////////////////////////////
//Configuration Macros                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////

//Memory Mapping Macros :

`define	RAM_START			16'h0000
`define	RAM_END				16'h3FFF

`define	I_O_START			16'h4000
`define	I_O_END				16'h7FFF

`define	ROM_START			16'h8000
`define	ROM_END				16'hFFF9

//Vector Addresses Macros :

`define	V_ADR_NMI_L			16'hFFFA
`define	V_ADR_NMI_H			16'hFFFB
`define	V_ADR_RST_L			16'hFFFC
`define	V_ADR_RST_H			16'hFFFD
`define	V_ADR_IRQ_L			16'hFFFE
`define	V_ADR_IRQ_H			16'hFFFF

//Processor Configuration Macros :

`define	MEMORY_SIZE			65536

`define	P_C_START			16'h8000

`define	S_P_START			8'hFF			//Stack grows downward from page 1
`define	S_P_END				8'h00			//Stack grows downward from page 1

`define INIT_STATUS_REG		8'b00000110		//Ints are ignored during reset

//////////////////////////////////////////////////////////////////////////////////////////
//Debug Macros                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////

`define	MEM_DBG_WIDTH		16
`define	PRF_DBG_WIDTH		24
`define	DEC_DBG_WIDTH		24
`define	EAD_DBG_WIDTH		16
`define	RDA_DBG_WIDTH		16
`define	EXE_DBG_WIDTH		16
`define	WRB_DBG_WIDTH		16



module MUX2x1(
				out,
				sel,
				in0,
				in1
);

	parameter width = 8;
	
	output	wire	[width - 1 : 0]	out;
	input	wire					sel;
	input	wire	[width - 1 : 0]	in0;
	input	wire	[width - 1 : 0]	in1;
	
	assign	out	=	(sel == 2'h0)	?	in0	:	in1;
	
endmodule




module MUX4x1(
				out,
				sel,
				in0,
				in1,
				in2,
				in3
);

	parameter width = 8;
	
	output	wire	[width - 1 : 0]	out;
	input	wire	[1:0]			sel;
	input	wire	[width - 1 : 0]	in0;
	input	wire	[width - 1 : 0]	in1;
	input	wire	[width - 1 : 0]	in2;
	input	wire	[width - 1 : 0]	in3;
	
	assign	out	=	(sel == 2'h0)	?	in0	:
					(sel == 2'h1)	?	in1	:
					(sel == 2'h2)	?	in2	:	in3;
					
endmodule




module MUX8x1(
				out,
				sel,
				in0,
				in1,
				in2,
				in3,
				in4,
				in5,
				in6,
				in7
);

	parameter width = 8;
	
	output	wire	[width - 1 : 0]	out;
	input	wire	[2:0]			sel;
	input	wire	[width - 1 : 0]	in0;
	input	wire	[width - 1 : 0]	in1;
	input	wire	[width - 1 : 0]	in2;
	input	wire	[width - 1 : 0]	in3;
	input	wire	[width - 1 : 0]	in4;
	input	wire	[width - 1 : 0]	in5;
	input	wire	[width - 1 : 0]	in6;
	input	wire	[width - 1 : 0]	in7;
	
	assign	out	=	(sel == 3'h0)	?	in0	:
					(sel == 3'h1)	?	in1	:
					(sel == 3'h2)	?	in2	:
					(sel == 3'h3)	?	in3	:	
					(sel == 3'h4)	?	in4	:	
					(sel == 3'h5)	?	in5	:	
					(sel == 3'h6)	?	in6	:	in7;
					
endmodule
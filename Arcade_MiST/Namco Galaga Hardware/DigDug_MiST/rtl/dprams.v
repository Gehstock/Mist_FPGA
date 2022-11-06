//--------------------------------------------
// Dualport RAM modules for FPGA DigDug
//
//					Copyright (c) 2017 MiSTer-X
//--------------------------------------------
module DPR2KV
(
	input					CL0,
	input	[10:0]		AD0,
	input					EN0,
	input					WR0,
	input  [7:0]		DI0,
	output [7:0]		DO0,
	
	input					CL1,
	input	[10:0]		AD1,
	output [7:0]		DO1
);

DPR2K ram(
	CL0, AD0,  EN0,  WR0,  DI0, DO0,
	CL1, AD1, 1'b1, 1'b0, 8'h0, DO1
);

endmodule


module DPR2K
(
	input					CL0,
	input	[10:0]		AD0,
	input					EN0,
	input					WR0,
	input  [7:0]		DI0,
	output reg [7:0]	DO0,
	
	input					CL1,
	input	[10:0]		AD1,
	input					EN1,
	input					WR1,
	input  [7:0]		DI1,
	output reg [7:0]	DO1
);

reg [7:0] mram[0:2047];

always @( posedge CL0 ) begin
	if (EN0) begin
		DO0 <= mram[AD0];
		if (WR0) mram[AD0] <= DI0;
	end
end

always @( posedge CL1 ) begin
	if (EN1) begin
		DO1 <= mram[AD1];
		if (WR1) mram[AD1] <= DI1;
	end
end

endmodule


module LBUF1K
(
	input				CL0,
	input	 [9:0]	AD0,
	input				WR0,
	input  [7:0]	DI0,
	
	input				CL1,
	input	 [9:0]	AD1,
	input				WR1,
	input  [7:0]	DI1,
	output [7:0]	DO1
);

wire [7:0] non;

LINEBUF lbuf(
	AD0,AD1,
	CL0,CL1,
	DI0,DI1,
	WR0,WR1,
	non,DO1
);

endmodule


module DLROM #(parameter AW,parameter DW)
(
	input							CL0,
	input [(AW-1):0]			AD0,
	output reg [(DW-1):0]	DO0,

	input							CL1,
	input [(AW-1):0]			AD1,
	input	[(DW-1):0]			DI1,
	input							WE1
);

reg [DW:0] core[0:((2**AW)-1)];

always @(posedge CL0) DO0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= DI1;

endmodule


module DLROMe #(parameter AW,parameter DW)
(
	input							RE0,
	input							CL0,
	input [(AW-1):0]			AD0,
	output reg [(DW-1):0]	DO0,

	input							CL1,
	input [(AW-1):0]			AD1,
	input	[(DW-1):0]			DI1,
	input							WE1
);

reg [DW:0] core[0:((2**AW)-1)];

always @(posedge CL0) if (RE0) DO0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= DI1;

endmodule


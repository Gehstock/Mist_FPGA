// Copyright (c) 2019 MiSTer-X

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

reg [(DW-1):0] core[0:((2**AW)-1)];

always @(posedge CL0) DO0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= DI1;

endmodule


module NJFGROM
(
	input				CL,
	input  [12:0]	AD,
	output [31:0]	DT,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire ROME  = ROMEN & (ROMAD[16:15]==2'b00);
wire ROME0 = ROME  & ~ROMAD[13];
wire ROME1 = ROME  &  ROMAD[13];

DLROM #(13,8) R0(CL,AD,DT[ 7: 0], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME0 & ~ROMAD[0]);
DLROM #(13,8) R1(CL,AD,DT[15: 8], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME1 & ~ROMAD[0]);
DLROM #(13,8) R2(CL,AD,DT[23:16], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME0 &  ROMAD[0]);
DLROM #(13,8) R3(CL,AD,DT[31:24], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME1 &  ROMAD[0]);

endmodule


module NJBGROM
(
	input				CL,
	input  [12:0]	AD,
	output [31:0]	DT,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire ROME  = ROMEN & (ROMAD[16:15]==2'b01);
wire ROME0 = ROME  & ~ROMAD[13];
wire ROME1 = ROME  &  ROMAD[13];

DLROM #(13,8) R0(CL,AD,DT[ 7: 0], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME0 & ~ROMAD[0]);
DLROM #(13,8) R1(CL,AD,DT[15: 8], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME1 & ~ROMAD[0]);
DLROM #(13,8) R2(CL,AD,DT[23:16], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME0 &  ROMAD[0]);
DLROM #(13,8) R3(CL,AD,DT[31:24], ROMCL,{ROMAD[14],ROMAD[12:1]},ROMDT,ROME1 &  ROMAD[0]);

endmodule


module NJC0ROM
(
	input				CL,
	input  [14:0]	AD,
	output  [7:0]	DT,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

DLROM #(15,8) r(CL,AD,DT,ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:15]==2'b10));

endmodule


module NJC1ROM
(
	input				CL,
	input  [14:0]	AD,
	output  [7:0]	DT,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

DLROM #(15,8) r(CL,AD,DT,ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:15]==2'b11));

endmodule


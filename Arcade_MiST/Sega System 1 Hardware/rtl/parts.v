// Copyright (c) 2017,19 MiSTer-X

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


//----------------------------------
//  2K SRAM
//----------------------------------
module SRAM_2048( CL, ADRS, OUT, WR, IN );

input				CL;
input  [10:0]	ADRS;
output [7:0]	OUT;
input				WR;
input  [7:0]	IN;


reg [7:0] ramcore [0:2047];
reg [7:0] OUT;

always @( posedge CL ) begin
	if (WR) ramcore[ADRS] <= IN;
	else OUT <= ramcore[ADRS];
end


endmodule


//----------------------------------
//  4K SRAM
//----------------------------------
module SRAM_4096(
	input					clk,
	input	    [11:0]	adrs,
	output reg [7:0]	out,
	input					wr,
	input		  [7:0]	in
);

reg [7:0] ramcore [0:4095];

always @( posedge clk ) begin
	if (wr) ramcore[adrs] <= in;
	else out <= ramcore[adrs];
end

endmodule 


//----------------------------------
//  DualPort RAM
//----------------------------------
module DPRAM2048
(
	input					clk0,
	input [10:0]		adr0,
	input  [7:0]		dat0,
	input					wen0,

	input					clk1,
	input [10:0]		adr1,
	output reg [7:0]	dat1,

	output reg [7:0]	dtr0
);

reg [7:0] core [0:2047];

always @( posedge clk0 ) begin
	if (wen0) core[adr0] <= dat0;
	else dtr0 <= core[adr0];
end

always @( posedge clk1 ) begin
	dat1 <= core[adr1];
end

endmodule


module DPRAM1024
(
	input					clk0,
	input  [9:0]		adr0,
	input  [7:0]		dat0,
	input					wen0,

	input					clk1,
	input  [9:0]		adr1,
	output reg [7:0]	dat1,

	output reg [7:0]	dtr0
);

reg [7:0] core [0:1023];

always @( posedge clk0 ) begin
	if (wen0) core[adr0] <= dat0;
	else dtr0 <= core[adr0];
end

always @( posedge clk1 ) begin
	dat1 <= core[adr1];
end

endmodule


module DPRAM2048_8_16
(
	input					clk0,
	input  [10:0]		adr0,
	input   [7:0]		dat0,
	input					wen0,

	input					clk1,
	input   [9:0]		adr1,
	output [15:0]		dat1,

	output  [7:0]		dtr0
);

wire [7:0] do0, do1;
wire [7:0] doH, doL;

DPRAM1024 core0( clk0, adr0[10:1], dat0, wen0 & (~adr0[0]), clk1, adr1, doL, do0 );
DPRAM1024 core1( clk0, adr0[10:1], dat0, wen0 &   adr0[0],  clk1, adr1, doH, do1 );

assign dtr0 = adr0[0] ? do1 : do0;
assign dat1 = { doH, doL };

endmodule


//----------------------------------
//  VRAM
//----------------------------------
module VRAMs
(
	input              clk,
	input      [12:0]  adr0,
	output reg  [7:0]  dat0,
	input       [7:0]  dtw0,
	input              wen0,

	input      [12:0]  adr1,
	output reg  [7:0]  dat1,

	input      [12:0]  adr2,
	output reg  [7:0]  dat2
);

reg   [7:0] core ['h2000];

reg         sel;
reg  [12:0] adr;
reg   [7:0] dat;

always @( posedge clk ) begin
	if (wen0) core[adr0] <= dtw0;
	dat0 <= core[adr0];

	adr <= sel ? adr1 : adr2;
	dat <= core[adr];
end

always @( posedge clk ) begin
	sel <= ~sel;
	if (sel) dat1 <= dat; else dat2 <= dat;
end

endmodule

module VRAM
(
	input            clk,
	input    [13:0]  adr0,
	output    [7:0]  dat0,
	input     [7:0]  dtw0,
	input            wen0,

	input    [12:0]  adr1,
	output   [15:0]  dat1,
	input    [12:0]  adr2,
	output   [15:0]  dat2
);

wire even = ~adr0[0];
wire  odd =  adr0[0];

wire [7:0] do00, do01, do10, do11, do20, do21;
VRAMs ram0(clk, adr0[13:1], do00, dtw0, wen0 & even,
           adr1, do10, adr2, do20);
VRAMs ram1(clk, adr0[13:1], do01, dtw0, wen0 &  odd,
           adr1, do11, adr2, do21);

assign dat0 = odd ? do01 : do00;
assign dat1 = { do11, do10 };
assign dat2 = { do21, do20 };

endmodule


//----------------------------------
//  ScanLine Buffer
//----------------------------------
module LineBuf
(
	input				clkr,
	input	  [9:0]	radr,
	input				clre,
	output [10:0]	rdat,
	
	input				clkw,
	input	  [9:0]	wadr,
	input	 [10:0]	wdat,
	input				we,
	output [10:0]	rdat1
);

DPRAM1024_11B core (
	radr,wadr,
	clkr,clkw,
	16'h0,{5'h0,wdat},
	clre,we,
	rdat,rdat1
);

endmodule



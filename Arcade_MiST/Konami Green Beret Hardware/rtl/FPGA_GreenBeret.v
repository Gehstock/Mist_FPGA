/*******************************************************
   FPGA Implimentation of "Green Beret" (Top Module)
********************************************************/
// Copyright (c) 2013,19 MiSTer-X
// Converted to single clock with clock enables and SDRAM
// external ROM storage by (c) 2019 Slingshot

module FPGA_GreenBeret
(
	input				clk48M,
	input				reset,

	input	  [5:0]	INP0,			// Control Panel
	input	  [5:0]	INP1,
	input	  [2:0]	INP2,

	input	  [7:0]	DSW0,			// DipSWs
	input	  [7:0]	DSW1,
	input	  [7:0]	DSW2,
	
	
	input   [8:0] PH,         // PIXEL H
	input   [8:0] PV,         // PIXEL V
	output        PCLK,       // PIXEL CLOCK (to VGA encoder)
	output        PCLK_EN,
	output [11:0]	POUT, 	   // PIXEL OUT

	output  [7:0]	SND,			// Sound Out

	output [15:0] CPU_ROMA,
	input   [7:0] CPU_ROMDT,

	output [15:1] SP_ROMA,
	input  [15:0] SP_ROMD,

	input				ROMCL,		// Downloaded ROM image
	input  [17:0]  ROMAD,
	input   [7:0]	ROMDT,
	input				ROMEN
);

// Clocks
wire clk6M, clk3M_en, clk6M_en;
CLKGEN clks( clk48M, clk6M, clk3M_en, clk6M_en );

wire   VCLKx8 = clk48M;
wire	   VCLK = clk6M;

wire   CPUCLK_EN = clk3M_en;
wire     VCLK_EN = clk6M_en;

// Main
wire			CPUMX, CPUWR, VIDDV;
wire  [7:0]	CPUWD, VIDRD;
wire [15:0]	CPUAD;


MAIN cpu
(
	clk48M, CPUCLK_EN, reset,
	PH,PV,
	INP0,INP1,INP2,
	DSW0,DSW1,DSW2,
	
	CPUMX, CPUAD,
	CPUWR, CPUWD,
	VIDDV, VIDRD,

	CPU_ROMA, CPU_ROMDT,
	ROMCL,ROMAD,ROMDT,ROMEN
);


// Video
VIDEO vid
(
	VCLKx8, VCLK, VCLK_EN,
	PH, PV, 1'b0, 1'b0,
	PCLK, PCLK_EN, POUT,

	CPUMX, CPUAD,
	CPUWR, CPUWD,
	VIDDV, VIDRD,

	SP_ROMA, SP_ROMD,
	ROMCL,ROMAD,ROMDT,ROMEN
);


// Sound
SOUND snd
(
	clk48M, reset,
	SND,

	CPUMX, CPUAD,
	CPUWR, CPUWD
);

endmodule


//----------------------------------
//  Clock Generator
//----------------------------------
module CLKGEN
(
	input		clk48M,

	output	clk6M,
	output  clk3M_en,
	output  clk6M_en
);
	
reg [3:0] clkdiv;
always @( posedge clk48M ) clkdiv <= clkdiv+4'd1;

assign clk6M  = clkdiv[2];
assign clk3M_en = clkdiv[3:0] == 4'b0111;
assign clk6M_en = clkdiv[2:0] == 4'b011;

endmodule



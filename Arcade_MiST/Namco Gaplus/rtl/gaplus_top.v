/*********************************************************
    FPGA Gaplus port to MiSTer

						Copyright (c) 2007,2019 MiSTer-X
**********************************************************/
module gaplus_top
(
	input				RESET,	// RESET
	input				MCLK,		// MasterClock: 49.125MHz

	input	  [8:0]	PH,		// Screen H
	input	  [8:0]	PV,		// Screen V
	output			PCLK,		// Pixel Clock
	output [11:0]	POUT,		// Pixel Color

	output  [7:0]  SOUT,		// Sound Out

									// Sticks and Buttons (Active Logic)
	input	  [4:0]	INP0,			// 1P {B1,L,D,R,U} 
	input	  [4:0]	INP1,			// 2P {B1,L,D,R,U}
	input   [2:0]  INP2,			// {Coin,Start2P,Start1P}
										
	input	  [7:0]	DSW0,		// DIPSWs (Active Logic)
	input	  [7:0]	DSW1,
	input	  [7:0] 	DSW2,
	output  [14:0] main_cpu_addr,
	input    [7:0] main_cpu_do,
	output  [14:0] sub_cpu_addr,
	input    [7:0] sub_cpu_do
);

//----------------------------------------
//  Input port connection
//----------------------------------------
wire				CIN1 = INP2[2];
wire				ST1P = INP2[0];
wire				ST2P = INP2[1];

wire				TRG1 = INP0[4];
wire				TRG2 = INP1[4];

wire  [3:0]		P1   = INP0[3:0];							// {L,D,R,U}
wire  [3:0]		P2   = INP1[3:0];
wire  [3:0]		BUTS = { ST2P, ST1P, TRG2, TRG1 };
wire  [3:0]		CINS = { 1'b0, 1'b0, 1'b0, CIN1 }; 	// {Service,none,Coin2,Coin1}

wire [31:0]		INTF0 = { 16'h0, BUTS, P2, P1, CINS };
wire [31:0]		INTF1 = {{DSW0[3:0],DSW1[7:4],DSW1[3:0],DSW0[7:4]},{DSW0[3:0],DSW1[7:4],DSW1[3:0],DSW0[7:4]}};
wire  [3:0]		INTF2 = { DSW2[1:0], 2'b11 };			// {Serv.Mode(Gal3),Cabinet,2'b11}

						
//----------------------------------------
//  Clock Generator
//----------------------------------------
reg [4:0] CLKS;
always @( posedge MCLK ) CLKS <= CLKS+1;

wire		CLK50M   = MCLK;
wire		CLK25M   = CLKS[0];
wire		CLK12M5  = CLKS[1];
wire		CLK6M25  = CLKS[2];
wire		CLK3M125 = CLKS[3];
wire		CLK1M60  = CLKS[4];

wire		VCLK_x4  = CLK25M;
wire		VCLK_x2  = CLK12M5;
wire		VCLK_x1  = CLK6M25;

wire	VCLKx2   = VCLK_x2;

wire		CPUCLKx4 = CLK6M25;
wire		CPUCLKx2 = CLK3M125;
wire		CPUCLK   = CLK1M60;

wire		MCPU_CLK =  CPUCLKx2;
wire		SCPU_CLK = ~CPUCLKx2;


assign PCLK = VCLK_x1;


//----------------------------------------
//  Share Memory Module
//----------------------------------------
wire [15:0] mcpu_ma;
wire	[7:0]	mcpu_mr;
wire  [7:0] mcpu_do;
wire			mcpu_we;

wire [15:0] scpu_ma;
wire  [7:0] scpu_mr;
wire  [7:0] scpu_do;
wire        scpu_we;

wire [10:0] vram_a;
wire [15:0] vram_d;

wire [ 6:0] spra_a;
wire [23:0] spra_d;


gaplus_sharemem smem
(
	CPUCLKx4,
	CLK50M,
	MCPU_CLK,
	mcpu_ma, mcpu_mr, mcpu_do, mcpu_we,
	scpu_ma, scpu_mr, scpu_do, scpu_we,
	vram_a, vram_d,
	spra_a, spra_d
);


//----------------------------------------
//  Video Module
//----------------------------------------
wire mcpu_star_cs;
wire oVB;

gaplus_video video
(
	.CLK50M(CLK50M),
	.VCLKx4(VCLK_x4),
	.VCLKx2(VCLK_x2),
	.VCLK(VCLK_x1),
	.RESET(RESET),

	.PH(PH),.PV(PV),
	.POUT(POUT),.VB(oVB),

	.VRAM_A(vram_a), .VRAM_D(vram_d),
	.SPRA_A(spra_a), .SPRA_D(spra_d),

	.STAR_AD(mcpu_ma[1:0]),
	.STAR_DT(mcpu_do),
	.STAR_WE(mcpu_star_cs)
);


//----------------------------------------
//  MAIN CPU
//----------------------------------------
wire 			SUB_RESET;
wire			kick_explode;
wire  [7:0] snd_rd;
wire        snd_we;

gaplus_main main
(
	MCPU_CLK, RESET, oVB,
	INTF0, INTF1, INTF2,
	mcpu_ma, mcpu_we, mcpu_do, mcpu_mr,
	snd_we, snd_rd,
	mcpu_star_cs, 
	SUB_RESET, kick_explode,
	main_cpu_addr, main_cpu_do
//	ROMCL,ROMAD,ROMDT,ROMEN
);


//----------------------------------------
//  Sub CPU
//----------------------------------------
gaplus_sub sub
(
	SCPU_CLK, SUB_RESET, oVB,
	scpu_mr,
	scpu_ma, scpu_we, scpu_do,
	sub_cpu_addr, sub_cpu_do
);


//----------------------------------------
//  Sound Module
//----------------------------------------
gaplus_sound sound
(
	SUB_RESET,
	MCPU_CLK,
	VCLK_x4,
	oVB,
	CLK50M, { 1'b0, mcpu_ma[9:0] }, mcpu_do, snd_rd, snd_we,
	kick_explode,
	SOUT,
	~SUB_RESET
);


endmodule 
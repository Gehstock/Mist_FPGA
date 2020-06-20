/*******************************************
	Video Module for "FPGA Gaplus"

			Copyright (c) 2007,2019 MiSTer-X
********************************************/
module gaplus_video
(
	input				CLK50M,		// 50.0MHz
	input				VCLKx4,		// 25.0MHz
	input				VCLKx2,		// 12.5MHz
	input				VCLK,			// 6.25MHz

	input				RESET,

	input   [8:0]  PH,
	input   [8:0]  PV,
	output [11:0]	POUT,
	output         VB,

	output [10:0]	VRAM_A,
	input	 [15:0]	VRAM_D,

	output  [6:0]	SPRA_A,
	input	 [23:0]	SPRA_D,

	input   [1:0]	STAR_AD,
	input   [7:0]	STAR_DT,
	input				STAR_WE
);


wire [8:0] HPOS = PH-16;
wire [8:0] VPOS = PV;

assign VB = (PV == 224) & (PH < 32);
wire  oHB = (PH >= 290);


//----------------------------------------
//  ROMs
//----------------------------------------
wire	 [7:0]	PALT_A;
wire   [7:0]	PALT_R, PALT_G, PALT_B;
wire	[11:0]	PALT_D;
pal_r pal_r(
	.clk(CLK50M),
	.addr(PALT_A),
	.data(PALT_R)
);

pal_g pal_g(
	.clk(CLK50M),
	.addr(PALT_A),
	.data(PALT_G)
);

pal_b pal_b(
	.clk(CLK50M),
	.addr(PALT_A),
	.data(PALT_B)
);
assign PALT_D = {PALT_B[3:0],PALT_G[3:0],PALT_R[3:0]};

wire 	 [7:0]	CLT0_A;
wire	 [7:0]	CLT0_D;
pal_c pal_c(
	.clk(CLK50M),
	.addr(CLT0_A),
	.data(CLT0_D)
);

wire 	 [9:0]	CLT1_A;
wire	 [7:0]	CLT1_D;
pal_sl pal_sl(
	.clk(CLK50M),
	.addr(CLT1_A[8:0]),
	.data(CLT1_D[3:0])
);

pal_sh pal_sh(
	.clk(CLK50M),
	.addr(CLT1_A[8:0]),
	.data(CLT1_D[7:4])
);

wire	[13:0]	BGCH_A;
wire	 [7:0]	BGCH_D;
gaplus_bg gaplus_bg(
	.clk(CLK50M),
	.ad(BGCH_A),
	.dt(BGCH_D)
);

wire	[14:0]	SPCH_A;
wire	[15:0]	SPCH_D;
gaplus_sp gaplus_sp(
   .clk(CLK50M),
   .ad(SPCH_A),
   .dt(SPCH_D)
);

//----------------------------------------
//  BG Scanline Generator
//----------------------------------------
reg	 [7:0] BGPN;
reg 			 BGHI;

wire	 [5:0] COL  = HPOS[8:3];
wire	 [5:0] ROW  = VPOS[8:3] + 6'h02;

wire	 [8:0] CHRC = { VRAM_D[15], VRAM_D[7:0] };
wire	 [5:0] BGPL = VRAM_D[13:8];
wire			 PRIO = VRAM_D[14];

wire	 [8:0] HP   = HPOS;
wire	 [8:0] VP   = VPOS;

wire	 [7:0] CHRO = BGCH_D;

wire	 [1:0] p0 = { 1'b1, ~HP[0] };
wire	 [1:0] p1 = { 1'b0, ~HP[0] };

always @ ( posedge VCLK ) begin
	BGPN <= { BGPL, CHRO[p0[1]], CHRO[p1[1]] };
	BGHI <= PRIO;
end

gaplus_busdriver vramadrs( 1'b1, COL[5], { COL[4:0], ROW[4:0] }, { ROW[4:0], COL[4:0] }, VRAM_A );

assign BGCH_A = { CHRC, ~HP[2], HP[1], VP[2:0] };
assign CLT0_A = BGPN;

wire [7:0] BGCOL = { 4'hF, CLT0_D[3:0] };
wire       BGOPQ = (CLT0_D[3:0]!=4'hF);


//----------------------------------------
//  Sprite Engine
//----------------------------------------
wire [7:0] SPCOL =  CLT1_D;
wire       SPOPQ = (CLT1_D!=8'hFF);
wire       oVB;
gaplus_sprite sprite
(
	VCLKx4,
	VCLK,
	HPOS, VPOS,
	oHB,  oVB,
	SPCH_A, SPCH_D,
	SPRA_A, SPRA_D,
	CLT1_A
);


//----------------------------------------
//  StarField Generator
//----------------------------------------
reg  [7:0] starreg0;
reg  [4:0] starreg1;
reg  [4:0] starreg2;
reg  [4:0] starreg3;

always @ ( posedge VCLKx4 or posedge RESET ) begin
	if ( RESET ) begin
		starreg0 <= 0;
		starreg1 <= 0;
		starreg2 <= 0;
		starreg3 <= 0;
	end
	else begin
		if ( STAR_WE ) begin
			case ( STAR_AD )
			2'h0: starreg0 <= STAR_DT;
			2'h1: starreg1 <= stargen_com(STAR_DT);
			2'h2: starreg2 <= stargen_com(STAR_DT);
			2'h3: starreg3 <= stargen_com(STAR_DT);
			default: begin end
			endcase
		end
	end
end

wire [7:0] _oSTAR;
wire [7:0]  oSTAR = _oSTAR & { 8{starreg0[0]} };

function [4:0] stargen_com;
input [7:0] com;

	case (com)

	8'h86: stargen_com = { 1'b0, 1'b0, 3'h1 };
	8'h85: stargen_com = { 1'b0, 1'b0, 3'h2 };
	8'h06: stargen_com = { 1'b0, 1'b0, 3'h3 };

	8'h80: stargen_com = { 1'b0, 1'b1, 3'h1 };
	8'h82: stargen_com = { 1'b0, 1'b1, 3'h2 };
	8'h81: stargen_com = { 1'b0, 1'b1, 3'h3 };

	8'h9F: stargen_com = { 1'b1, 1'b0, 3'h3 };
	8'hAF: stargen_com = { 1'b1, 1'b0, 3'h2 };

	default: stargen_com = 0;

	endcase

endfunction


gaplus_stargen stargen(
	VCLK,
	RESET,
	VB,
	starreg1,
	starreg2,
	starreg3,
	_oSTAR
);

//----------------------------------------
//  Color mixer & Pixel output
//----------------------------------------
wire BGHIOPQ = BGHI & BGOPQ;
wire SPTRNSP = ~SPOPQ;

dataselector2 colormixer(
	PALT_A,
	BGHIOPQ | ( SPTRNSP & BGOPQ ), BGCOL,
	SPOPQ, SPCOL,
	oSTAR
);

assign POUT = { PALT_D[11:8],PALT_D[7:4],PALT_D[3:0]}; 

endmodule 
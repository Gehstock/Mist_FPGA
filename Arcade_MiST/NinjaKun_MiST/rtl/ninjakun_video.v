// Copyright (c) 2011,19 MiSTer-X

module ninjakun_video
(
	input					RESET,
	input					VCLKx4,
	input					VCLK,
	input   [8:0]		PH,
	input   [8:0]		PV,

	output  [8:0]		PALAD,	// Pixel Output (Palet Index)

	output  [9:0]		FGVAD,	// FG
	input  [15:0]		FGVDT,

	output  [9:0]		BGVAD,	// BG
	input  [15:0]		BGVDT,
	input   [7:0]		BGSCX,
	input   [7:0]		BGSCY,

	output [10:0]		SPAAD,	// Sprite
	input   [7:0]		SPADT,

	output				VBLK,
	input					DBGPD,	// Palet Display (for Debug)
//	output [12:0]		sp_rom_addr,
//	input  [31:0]		sp_rom_data,
//	output [12:0]		fg_rom_addr,
//	input  [31:0]		fg_rom_data,
	output [12:0]		bg_rom_addr,
	input  [31:0]		bg_rom_data
);

assign VBLK = (PV>=193);

// ROMs
wire			SPCFT = 1'b1;
wire [12:0]	SPCAD;
wire [31:0]	SPCDT;

wire [12:0]	FGCAD;
wire [31:0]	FGCDT;

wire [12:0] BGCAD;
wire [31:0] BGCDT;

//NJFGROM sprom(~VCLKx4, SPCAD, SPCDT, ROMCL, ROMAD, ROMDT, ROMEN);
//NJFGROM fgrom(  ~VCLK, FGCAD, FGCDT, ROMCL, ROMAD, ROMDT, ROMEN);
//NJBGROM bgrom(  ~VCLK, BGCAD, BGCDT, ROMCL, ROMAD, ROMDT, ROMEN);
//assign sp_rom_addr = SPCAD;
//assign SPCDT = sp_rom_data;
//assign fg_rom_addr = FGCAD;
//assign FGCDT = fg_rom_data;
/*
static GFXDECODE_START( gfx_ninjakun )
	GFXDECODE_ENTRY( "gfx1", 0, layout16x16, 0x200, 16 )    // sprites
	GFXDECODE_ENTRY( "gfx1", 0, layout8x8,   0x000, 16 )    // fg tiles
	GFXDECODE_ENTRY( "gfx2", 0, layout8x8,   0x100, 16 )    // bg tiles
GFXDECODE_END*/

assign bg_rom_addr = BGCAD;
assign BGCDT = bg_rom_data;

fg1_rom fg1_rom (
	.clk(~VCLKx4),//if sprite ? ~VCLKx4 : ~VCLK
	.addr(SPCAD),//if sprite ? SPCAD : FGCAD
	.data(SPCDT[7:0])//if sprite ? SPCDT[7:0] : FGCDT[7:0]
);

fg2_rom fg2_rom (
	.clk(~VCLKx4),
	.addr(SPCAD),
	.data(SPCDT[15:8])
);

fg3_rom fg3_rom (
	.clk(~VCLKx4),
	.addr(SPCAD),
	.data(SPCDT[23:16])
);

fg4_rom fg4_rom (
	.clk(~VCLKx4),
	.addr(SPCAD),
	.data(SPCDT[31:24])
);/*

fg1_rom fg1_rom (
	.clk(~VCLK),//if sprite ? ~VCLKx4 : ~VCLK
	.addr(FGCAD),//if sprite ? SPCAD : FGCAD
	.data(FGCDT[7:0])//if sprite ? SPCDT[7:0] : FGCDT[7:0]
);

fg2_rom fg2_rom (
	.clk(~VCLK),
	.addr(FGCAD),
	.data(FGCDT[15:8])
);

fg3_rom fg3_rom (
	.clk(~VCLK),
	.addr(FGCAD),
	.data(FGCDT[23:16])
);

fg4_rom fg4_rom (
	.clk(~VCLK),
	.addr(FGCAD),
	.data(FGCDT[31:24])
);*/

// Fore-Ground Scanline Generator
wire		  FGPRI;
wire [8:0] FGOUT;
ninjakun_fg fg(
	VCLK,
	PH, PV,
	FGVAD, FGVDT,
	FGCAD, FGCDT,
  {FGPRI, FGOUT}
);
wire FGOPQ =(FGOUT[3:0]!=0);
wire FGPPQ = FGOPQ & (~FGPRI);

// Back-Ground Scanline Generator
wire [8:0] BGOUT;
ninjakun_bg bg(
	VCLK,
	PH, PV,
	BGSCX, BGSCY,
	BGVAD, BGVDT,
	BGCAD, BGCDT,
	BGOUT
);

// Sprite Scanline Generator
wire [8:0] SPOUT;
ninjakun_sp sp(
	VCLKx4, VCLK,
	PH, PV,
	SPAAD, SPADT,
	SPCAD, SPCDT, SPCFT,
	SPOUT
);
wire SPOPQ = (SPOUT[3:0]!=0);

// Palet Display (for Debug)
wire [8:0] PDOUT = (PV[7]|PV[8]) ? 0 : {PV[6:2],PH[7:4]};

// Color Mixer
dataselector_4D_9B dataselector_4D_9B(
	.OUT(PALAD),
	.EN1(DBGPD),
	.IN1(PDOUT),
	.EN2(FGPPQ),
	.IN2(FGOUT),
	.EN3(SPOPQ),
	.IN3(SPOUT),
	.EN4(FGOPQ),
	.IN4(FGOUT),
	.IND(BGOUT)
);

endmodule 
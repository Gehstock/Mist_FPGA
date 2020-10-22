/********************************************************************
        FPGA Implimentation of SEGA System 1,2 (Top Module)

											Copyright (c) 2017,19 MiSTer-X
*********************************************************************/
module SEGASYSTEM1
(
	input         clk48M,
	input         reset,

	input   [7:0]	INP0,
	input   [7:0]	INP1,
	input   [7:0]	INP2,

	input   [7:0]	DSW0,
	input   [7:0]	DSW1,
	
	input   [8:0] PH,        // PIXEL H
	input   [8:0] PV,        // PIXEL V
	output        PCLK_EN,
	output  [7:0]	POUT, 	   // PIXEL OUT

	output [15:0] SOUT,      // Sound Out (PCM)

	output [15:0] cpu_rom_addr,
	input   [7:0] cpu_rom_do,
	output [12:0] snd_rom_addr,
	input   [7:0] snd_rom_do,
	output [13:0] tile_rom_addr,
	input  [31:0] tile_rom_do,
	output [17:0] spr_rom_addr,
	input   [7:0] spr_rom_do,

	input         ROMCL, // Downloaded ROM image
	input  [24:0] ROMAD,
	input   [7:0] ROMDT,
	input         ROMEN
);

// CPU
wire [15:0] CPUAD;
wire  [7:0] CPUDO,VIDDO,SNDNO,VIDMD;
wire			CPUWR,VIDCS,VBLK;
wire			SNDRQ;

SEGASYS1_MAIN Main (
	.RESET(reset),
	.INP0(INP0),.INP1(INP1),.INP2(INP2),
	.DSW0(DSW0),.DSW1(DSW1),
	.CLK48M(clk48M),
	.CPUAD(CPUAD),.CPUDO(CPUDO),.CPUWR(CPUWR),
	.VBLK(VBLK),.VIDCS(VIDCS),.VIDDO(VIDDO),
	.SNDRQ(SNDRQ),.SNDNO(SNDNO),
	.VIDMD(VIDMD),

	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_do),
	
	.ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN)
);

// Video
wire [7:0] OPIX;
SEGASYS1_VIDEO Video (
	.RESET(reset),.VCLKx8(clk48M),
	.PH(PH),.PV(PV),.VFLP(VIDMD[7]),
	.VBLK(VBLK),.PCLK_EN(PCLK_EN),.RGB8(OPIX),.PALDSW(1'b0),

	.cpu_ad(CPUAD),.cpu_wr(CPUWR),.cpu_dw(CPUDO),
	.cpu_rd(VIDCS),.cpu_dr(VIDDO),
	.tile_rom_addr(tile_rom_addr), .tile_rom_do(tile_rom_do),
	.spr_rom_addr(spr_rom_addr), .spr_rom_do(spr_rom_do),

	.ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN)
);
assign POUT = VIDMD[4] ? 8'd0 : OPIX;

// Sound

SEGASYS1_SOUND Sound(
	clk48M, reset, SNDNO, SNDRQ, SOUT,
	snd_rom_addr, snd_rom_do
);

endmodule


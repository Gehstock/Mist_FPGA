// Copyright (c) 2011,19 MiSTer-X

module ninjakun_io_video
(
	input				SHCLK,
	input				CLK3M,
	input				RESET,
	input				VRCLK,
	input				VCLKx4,
	input				VCLK,
	input	  [8:0]	PH,
	input	  [8:0]	PV,
	input  [15:0]	CPADR,
	input   [7:0]	CPODT,
	output  [7:0]	CPIDT,
	input    		CPRED,
	input    		CPWRT,
	input   [7:0]  DSW1,
	input   [7:0]  DSW2,
	output			VBLK,
	output  [7:0]	POUT,
	output [15:0]	SNDOUT,
//	output [12:0]	sp_rom_addr,
//	input  [31:0]	sp_rom_data,
//	output [12:0]	fg_rom_addr,
//	input  [31:0]	fg_rom_data,
	output [12:0]	bg_rom_addr,
	input  [31:0]	bg_rom_data
);

wire  [9:0]	FGVAD;
wire [15:0]	FGVDT;
wire  [9:0]	BGVAD;
wire [15:0]	BGVDT;
wire [10:0]	SPAAD;
wire  [7:0]	SPADT;
wire  [7:0]	SCRPX, SCRPY;
wire  [8:0]	PALET;
ninjakun_video video (
	.RESET(RESET),
	.VCLKx4(VCLKx4),
	.VCLK(VCLK),
	.PH(PH),
	.PV(PV),
	.PALAD(PALET),	// Pixel Output (Palet Index)
	.FGVAD(FGVAD),	// FG
	.FGVDT(FGVDT),
	.BGVAD(BGVAD),	// BG
	.BGVDT(BGVDT),
	.BGSCX(SCRPX),
	.BGSCY(SCRPY),
	.SPAAD(SPAAD),	// Sprite
	.SPADT(SPADT),
	.VBLK(VBLK),
	.DBGPD(1'b0),	// Palet Display (for Debug)
//	.sp_rom_addr(sp_rom_addr),
//	.sp_rom_data(sp_rom_data),
//	.fg_rom_addr(fg_rom_addr),
//	.fg_rom_data(fg_rom_data),
	.bg_rom_addr(bg_rom_addr),
	.bg_rom_data(bg_rom_data)
);

wire CS_PSG, CS_FGV, CS_BGV, CS_SPA, CS_PAL;
ninjakun_sadec sadec(
	.CPADR(CPADR),
	.CS_PSG(CS_PSG),
	.CS_FGV(CS_FGV),
	.CS_BGV(CS_BGV),
	.CS_SPA(CS_SPA),
	.CS_PAL(CS_PAL)
);

wire  [7:0] PSDAT, FGDAT, BGDAT, SPDAT, PLDAT;

wire  [9:0] BGOFS =  CPADR[9:0]+{SCRPY[7:3],SCRPX[7:3]};
wire [10:0] BGADR = {CPADR[10],BGOFS};

VDPRAM400x2	fgv( SHCLK, CPADR[10:0], CS_FGV & CPWRT, CPODT, FGDAT, VRCLK, FGVAD, FGVDT );
VDPRAM400x2	bgv( SHCLK, BGADR      , CS_BGV & CPWRT, CPODT, BGDAT, VRCLK, BGVAD, BGVDT );
DPRAM800		spa( SHCLK, CPADR[10:0], CS_SPA & CPWRT, CPODT, SPDAT, VRCLK, SPAAD, 1'b0, 8'h0, SPADT );
DPRAM200		pal( SHCLK, CPADR[ 8:0], CS_PAL & CPWRT, CPODT, PLDAT,  VCLK, PALET, 1'b0, 8'h0, POUT  );

dataselector_5D_8B cpxdsel(
	.out(CPIDT),
	.en0(CS_PSG),
	.dt0(PSDAT),
	.en1(CS_FGV),
	.dt1(FGDAT),
	.en2(CS_BGV),
	.dt2(BGDAT),
	.en3(CS_SPA),
	.dt3(SPDAT),
	.en4(CS_PAL),
	.dt4(PLDAT)
);

ninjakun_psg psg(
	.AXSCLK(SHCLK),
	.CLK(CLK3M),
	.ADR(CPADR[1:0]),
	.CS(CS_PSG),
	.WR(CPWRT),
	.ID(CPODT),
	.OD(PSDAT),
	.RESET(RESET),
	.RD(CPRED),
	.DSW1(DSW1),
	.DSW2(DSW2),
	.SCRPX(SCRPX),
	.SCRPY(SCRPY),
	.SNDO(SNDOUT)
);

endmodule 
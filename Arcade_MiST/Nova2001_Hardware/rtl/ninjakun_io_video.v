// Copyright (c) 2011,19 MiSTer-X

module ninjakun_io_video
(
	input         MCLK,
	input   [1:0] HWTYPE,
	input         PCLK_EN,
	input         RESET,
	input   [8:0] PH,
	input   [8:0] PV,
	input  [15:0] CPADR,
	input   [7:0] CPODT,
	output  [7:0] CPIDT,
	input         CPRED,
	input         CPWRT,
	input         CPSEL,
	input   [7:0] DSW1,
	input   [7:0] DSW2,
	input   [7:0] CTR1,
	input   [7:0] CTR2,
	output        VBLK,
	output  [7:0] POUT,
	output [15:0] SNDOUT,
	output [13:0] sp_rom_addr,
	input  [31:0] sp_rom_data,
	input         sp_rdy,
	output [12:0] fg_rom_addr,
	input  [31:0] fg_rom_data,
	output [13:0] bg_rom_addr,
	input  [31:0] bg_rom_data,
	input   [4:0] PALADR,
	input         PALWR,
	input   [7:0] PALDAT
);

`include "rtl/defs.v"

wire  [9:0]	FGVAD;
wire [15:0]	FGVDT;
wire  [9:0]	BGVAD;
wire [15:0]	BGVDT;
wire [10:0]	SPAAD;
wire  [7:0]	SPADT;
wire            RAIDERS5 = HWTYPE == `HW_RAIDERS5;
wire  [7:0]	SCRPX = RAIDERS5 ? SCRPX_CPU : SCRPX_PSG, SCRPY = RAIDERS5 ? SCRPY_CPU : SCRPY_PSG;
wire  [7:0]	SCRPX_PSG, SCRPY_PSG;
reg   [7:0] SCRPX_CPU, SCRPY_CPU;
wire  [8:0]	PALET;

NINJAKUN_VIDEO video (
	.RESET(RESET),
	.MCLK(MCLK),
	.PCLK_EN(PCLK_EN),
	.HWTYPE(HWTYPE),
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
	.sp_rom_addr(sp_rom_addr),
	.sp_rom_data(sp_rom_data),
	.sp_rdy(sp_rdy),
	.fg_rom_addr(fg_rom_addr),
	.fg_rom_data(fg_rom_data),
	.bg_rom_addr(bg_rom_addr),
	.bg_rom_data(bg_rom_data)
);

wire CS_SCRX, CS_SCRY, CS_PSG, CS_FGV, CS_BGV, CS_SPA, CS_PAL;
ninjakun_sadec sadec(
	.HWTYPE(HWTYPE),
	.CPADR(CPADR),
	.CPSEL(CPSEL),
	.CS_SCRX(CS_SCRX),
	.CS_SCRY(CS_SCRY),
	.CS_PSG(CS_PSG),
	.CS_FGV(CS_FGV),
	.CS_BGV(CS_BGV),
	.CS_SPA(CS_SPA),
	.CS_PAL(CS_PAL)
);
always @(posedge MCLK) begin
	if (RESET) begin
		SCRPX_CPU <= 0;
		SCRPY_CPU <= 0;
	end else begin
		if (CS_SCRX) SCRPX_CPU <= CPODT;
		if (CS_SCRY) SCRPY_CPU <= CPODT;
	end
end

wire  [7:0] PSDAT, FGDAT = CPADR[10] ? FGDAT16[15:8] : FGDAT16[7:0], BGDAT = CPADR[10] ? BGDAT16[15:8] : BGDAT16[7:0], SPDAT, PLDAT;
wire [15:0] FGDAT16, BGDAT16;
wire  [9:0] BGOFS =  CPADR[9:0]+{SCRPY[7:3],SCRPX[7:3]};
wire [10:0] BGADR = HWTYPE[1] ? CPADR[10:0] : {CPADR[10],BGOFS};

dpram #(8,10) fgv_lo(MCLK, CS_FGV & CPWRT & ~CPADR[10], CPADR[9:0], CPODT, FGDAT16[ 7:0], MCLK, 1'b0, FGVAD, 8'd0, FGVDT[ 7:0]);
dpram #(8,10) fgv_hi(MCLK, CS_FGV & CPWRT &  CPADR[10], CPADR[9:0], CPODT, FGDAT16[15:8], MCLK, 1'b0, FGVAD, 8'd0, FGVDT[15:8]);
dpram #(8,10) bgv_lo(MCLK, CS_BGV & CPWRT & ~BGADR[10], BGADR[9:0], CPODT, BGDAT16[ 7:0], MCLK, 1'b0, BGVAD, 8'd0, BGVDT[ 7:0]);
dpram #(8,10) bgv_hi(MCLK, CS_BGV & CPWRT &  BGADR[10], BGADR[9:0], CPODT, BGDAT16[15:8], MCLK, 1'b0, BGVAD, 8'd0, BGVDT[15:8]);
dpram #(8,11) spa   (MCLK, CS_SPA & CPWRT, CPADR[10:0], CPODT, SPDAT, ~MCLK, 1'b0, SPAAD, 8'h0, SPADT);
dpram #(8,9)  pal   (MCLK, CS_PAL & CPWRT, CPADR[8:0], CPODT, PLDAT,  MCLK, PALWR, PALWR ? PALADR : PALET, PALDAT, POUT);

assign CPIDT = CS_PSG ? PSDAT :
               CS_FGV ? FGDAT :
               CS_BGV ? BGDAT :
               CS_SPA ? SPDAT :
               CS_PAL ? PLDAT :
               8'hFF;

ninjakun_psg psg(
	.MCLK(MCLK),
	.HWTYPE(HWTYPE),
	.ADR(CPADR[1:0]),
	.CS(CS_PSG),
	.WR(CPWRT),
	.ID(CPODT),
	.OD(PSDAT),
	.RESET(RESET),
	.RD(CPRED),
	.DSW1(DSW1),
	.DSW2(DSW2),
	.CTR1(CTR1),
	.CTR2(CTR2),
	.VBLK(VBLK),
	.SCRPX(SCRPX_PSG),
	.SCRPY(SCRPY_PSG),
	.SNDO(SNDOUT)
);

endmodule

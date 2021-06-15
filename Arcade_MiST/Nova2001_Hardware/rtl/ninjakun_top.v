/***********************************************
    "FPGA NinjaKun" for MiSTer

					Copyright (c) 2011,19 MiSTer-X
		
  Converted to SDRAM, single clock and
	  clock-enables for MiST
************************************************/

module ninjakun_top
(
	input         RESET,      // RESET
	input         MCLK,       // Master Clock (48.0MHz)
	input   [1:0] HWTYPE,
	input   [7:0] CTR1,       // Control Panel
	input   [7:0] CTR2,
	input   [7:0] CTR3,
	input   [7:0] DSW1,       // DipSW
	input   [7:0] DSW2,
	input   [8:0] PH,         // PIXEL H
	input   [8:0] PV,         // PIXEL V
	output        PCLK_EN,    // PIXEL CLOCK ENABLE
	output  [7:0] POUT,       // PIXEL OUT
	output [15:0] SNDOUT,     // Sound Output (LPCM unsigned 16bits)
	output [15:0] CPU1ADDR,
	input  [7:0]  CPU1DT,
	output [14:0] CPU2ADDR,
	input  [7:0]  CPU2DT,
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

reg [3:0] CLKDIV;
always @( posedge MCLK ) CLKDIV <= CLKDIV+1'b1;

assign PCLK_EN = CLKDIV[2:0] == 3'b111;

wire [15:0] CPADR;
wire  [7:0] CPODT, CPIDT;
wire        CPSEL;
wire        CPRED, CPWRT, VBLK;

ninjakun_main ninjakun_main(
	.RESET(RESET),
	.MCLK(MCLK),
	.HWTYPE(HWTYPE),
	.VBLK(VBLK),
	.CTR1(CTR1),
	.CTR2(CTR2),
	.CTR3(CTR3),
	.CPADR(CPADR),
	.CPODT(CPODT),
	.CPIDT(CPIDT),
	.CPRED(CPRED),
	.CPWRT(CPWRT),
	.CPSEL(CPSEL),
	.CPU1ADDR(CPU1ADDR),
	.CPU1DT(CPU1DT),
	.CPU2ADDR(CPU2ADDR),
	.CPU2DT(CPU2DT)
);


wire  [9:0] FGVAD, BGVAD;
wire [15:0] FGVDT, BGVDT;
wire [10:0] SPAAD;
wire  [7:0] SPADT;
wire  [8:0] PALET;
wire  [7:0] SCRPX, SCRPY;
ninjakun_io_video ninjakun_io_video(
	.MCLK(MCLK),
	.HWTYPE(HWTYPE),
	.PCLK_EN(PCLK_EN),
	.RESET(RESET),
	.PH(PH),
	.PV(PV),
	.CPADR(CPADR),
	.CPODT(CPODT),
	.CPIDT(CPIDT),
	.CPRED(CPRED),
	.CPWRT(CPWRT),
	.CPSEL(CPSEL),
	.DSW1(DSW1),
	.DSW2(DSW2),
	.CTR1(CTR1),
	.CTR2(CTR2),
	.VBLK(VBLK),
	.POUT(POUT),
	.SNDOUT(SNDOUT),
	.sp_rom_addr(sp_rom_addr),
	.sp_rom_data(sp_rom_data),
	.sp_rdy(sp_rdy),
	.fg_rom_addr(fg_rom_addr),
	.fg_rom_data(fg_rom_data),
	.bg_rom_addr(bg_rom_addr),
	.bg_rom_data(bg_rom_data),
	.PALADR(PALADR),
	.PALWR(PALWR),
	.PALDAT(PALDAT)
);

endmodule 
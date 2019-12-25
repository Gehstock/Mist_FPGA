/***********************************************
    "FPGA NinjaKun" for MiSTer

					Copyright (c) 2011,19 MiSTer-X
************************************************/
/*
ROM_START( ninjakun )
	ROM_REGION( 0x8000, "maincpu", 0 )
	ROM_LOAD( "ninja-1.7a",  0x0000, 0x02000, CRC(1c1dc141) SHA1(423d3ed35e73a8d5bfce075a889b0322b207bd0d) )
	ROM_LOAD( "ninja-2.7b",  0x2000, 0x02000, CRC(39cc7d37) SHA1(7f0d0e1e92cb6a57f15eb7fc51a67112f1c5fc8e) )
	ROM_LOAD( "ninja-3.7d",  0x4000, 0x02000, CRC(d542bfe3) SHA1(3814d8f5b1acda21438fff4f71670fa653dc7b30) )
	ROM_LOAD( "ninja-4.7e",  0x6000, 0x02000, CRC(a57385c6) SHA1(77925a281e64889bfe967c3d42a388529aaf7eb6) )

	ROM_REGION( 0x2000, "sub", 0 )
	ROM_LOAD( "ninja-5.7h",  0x0000, 0x02000, CRC(164a42c4) SHA1(16b434b33b76b878514f67c23315d4c6da7bfc9e) )

	ROM_REGION( 0x08000, "gfx1", 0 )
	ROM_LOAD16_BYTE( "ninja-6.7n",  0x0000, 0x02000, CRC(a74c4297) SHA1(87184d14c67331f2c8a2412e28f31427eddae799) )
	ROM_LOAD16_BYTE( "ninja-7.7p",  0x0001, 0x02000, CRC(53a72039) SHA1(d77d608ce9388a8956831369badd88a8eda8e102) )
	ROM_LOAD16_BYTE( "ninja-8.7s",  0x4000, 0x02000, CRC(4a99d857) SHA1(6aadb6a5c721a161a5c1bef5569c1e323e380cff) )
	ROM_LOAD16_BYTE( "ninja-9.7t",  0x4001, 0x02000, CRC(dede49e4) SHA1(8ce4bc02ec583b3885ca63fb5e2d5dad185fe192) )

	ROM_REGION( 0x08000, "gfx2", 0 )
	ROM_LOAD16_BYTE( "ninja-10.2c", 0x0000, 0x02000, CRC(0d55664a) SHA1(955a607b4401ce9f3f807d53833a766152b0ef9b) )
	ROM_LOAD16_BYTE( "ninja-11.2d", 0x0001, 0x02000, CRC(12ff9597) SHA1(10b572844ab32e3ae54abe3600fecc1a811ac713) )
	ROM_LOAD16_BYTE( "ninja-12.4c", 0x4000, 0x02000, CRC(e9b75807) SHA1(cf4c8ac962f785e9de5502df58eab9b3725aaa28) )
	ROM_LOAD16_BYTE( "ninja-13.4d", 0x4001, 0x02000, CRC(1760ed2c) SHA1(ee4c8efcce483c8051873714856824a1a1e14b61) )
ROM_END*/

module ninjakun_top
(
	input          RESET,      // RESET
	input          MCLK,       // Master Clock (48.0MHz)
	input	  [7:0]	CTR1,			// Control Panel
	input	  [7:0]	CTR2,
	input	  [7:0]	DSW1,			// DipSW
	input	  [7:0]	DSW2,
	input   [8:0]  PH,         // PIXEL H
	input   [8:0]  PV,         // PIXEL V
	output         PCLK,       // PIXEL CLOCK
	output  [7:0]  POUT,       // PIXEL OUT
	output [15:0]  SNDOUT,		// Sound Output (LPCM unsigned 16bits)
	output [14:0]	CPU1ADDR,
	input  [7:0]	CPU1DT,
	output [14:0]	CPU2ADDR,
	input  [7:0]	CPU2DT,
//	output [12:0]	sp_rom_addr,
//	input  [31:0]	sp_rom_data,
//	output [12:0]	fg_rom_addr,
//	input  [31:0]	fg_rom_data,
	output [12:0]	bg_rom_addr,
	input  [31:0]	bg_rom_data
);

wire			VCLKx4, VCLK;
wire			VRAMCL, CLK24M, CLK12M, CLK6M, CLK3M;
ninjakun_clkgen ninjakun_clkgen(
	.MCLK(MCLK),		// 48MHz
	.VCLKx4(VCLKx4),
	.VCLK(VCLK),
	.VRAMCL(VRAMCL),
	.PCLK(PCLK),
	.CLK24M(CLK24M),
	.CLK12M(CLK12M),
	.CLK6M(CLK6M),
	.CLK3M(CLK3M)
);

wire [15:0] CPADR;
wire  [7:0] CPODT, CPIDT;
wire        CPRED, CPWRT, VBLK;
ninjakun_main ninjakun_main(
	.RESET(RESET),
	.CLK24M(CLK24M),
	.CLK3M(CLK3M),
	.VBLK(VBLK),
	.CTR1(CTR1),
	.CTR2(CTR2),
	.CPADR(CPADR),
	.CPODT(CPODT),
	.CPIDT(CPIDT),
	.CPRED(CPRED),
	.CPWRT(CPWRT),
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
	.SHCLK(CLK24M),
	.CLK3M(CLK3M),
	.RESET(RESET),
	.VRCLK(VRAMCL),
	.VCLKx4(VCLKx4),
	.VCLK(VCLK),
	.PH(PH),
	.PV(PV),
	.CPADR(CPADR),
	.CPODT(CPODT),
	.CPIDT(CPIDT),
	.CPRED(CPRED),
	.CPWRT(CPWRT),
	.DSW1(DSW1),
	.DSW2(DSW2),
	.VBLK(VBLK),
	.POUT(POUT),
	.SNDOUT(SNDOUT),
//	.sp_rom_addr(sp_rom_addr),
//	.sp_rom_data(sp_rom_data),
//	.fg_rom_addr(fg_rom_addr),
//	.fg_rom_data(fg_rom_data),
	.bg_rom_addr(bg_rom_addr),
	.bg_rom_data(bg_rom_data)
);

endmodule 
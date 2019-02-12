
//============================================================================
//  Arcade: Pooyan
//
//  Version for MiST
//  Copyright (C) 2018 DAR
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module Pooyan_MiST
(
	output        LED,						
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        AUDIO_L,
	output        AUDIO_R,	
	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         CONF_DATA0,
	input         CLOCK_27,
	output [12:0] SDRAM_A,
   inout  [15:0] SDRAM_DQ,
   output        SDRAM_DQML,
   output        SDRAM_DQMH,
   output        SDRAM_nWE,
   output        SDRAM_nCAS,
   output        SDRAM_nRAS,
   output        SDRAM_nCS,
   output  [1:0] SDRAM_BA,
   output        SDRAM_CLK,
   output        SDRAM_CKE
);

`include "rtl\build_id.v"

localparam CONF_STR = {
	"Pooyan;;",
	"O2,Joystick Control,Upright,Normal;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_24, clk_14, clk_12, clk_48, clk_6;
wire pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_24),
	.c1(clk_14),
	.c2(clk_12),
	.c3(SDRAM_CLK),
	.c4(clk_48),
	.locked(pll_locked)
);


wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire [10:0] audio;
assign LED = 1;
wire blankn = ~(hb | vb);
wire hb, vb;
wire hs, vs;
wire [2:0] r,g,b;

video_mixer #(.LINE_LENGTH(384), .HALF_DEPTH(0)) video_mixer(
	.clk_sys(clk_24),
	.ce_pix(clk_6),
	.ce_pix_actual(clk_6),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r}),
	.G({g,g}),
	.B({b,b}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io(
	.clk_sys        (clk_24        ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr          (ypbpr          ),
	.ps2_kbd_clk    (ps2_kbd_clk    ),
	.ps2_kbd_data   (ps2_kbd_data   ),
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

keyboard keyboard(
	.clk(clk_24),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);
	
wire m_up     = status[2] ? kbjoy[6] | joystick_0[1] | joystick_1[1] : kbjoy[4] | joystick_0[3] | joystick_1[3];
wire m_down   = status[2] ? kbjoy[7] | joystick_0[0] | joystick_1[0] : kbjoy[5] | joystick_0[2] | joystick_1[2];
wire m_left   = status[2] ? kbjoy[5] | joystick_0[2] | joystick_1[2] : kbjoy[6] | joystick_0[1] | joystick_1[1];
wire m_right  = status[2] ? kbjoy[4] | joystick_0[3] | joystick_1[3] : kbjoy[7] | joystick_0[0] | joystick_1[0];

wire m_fire   = kbjoy[0] | joystick_0[4] | joystick_1[4];
wire m_start1 = kbjoy[1];
wire m_start2 = kbjoy[2];
wire m_coin   = kbjoy[3];

pooyan pooyan(
	.clock_12(clk_12),
	.clock_14(clk_14),
	.reset(status[0] | status[6] | buttons[1]),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_clk(clk_6),
	.video_vblank(vb),
	.video_hblank(hb),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),
	
	.wram_addr(wram_addr),
	.wram_we(wram_we),
	.wram_di(wram_di),
	.wram_do(wram_do),
	.dip_switch_1('hFF),
	.dip_switch_2('h4B),
	.start2(1'b0),
	.start1(1'b0),
	.coin1(1'b0),
	.fire1(1'b0),
	.right1(1'b0),
	.left1(1'b0),
	.down1(1'b0),
	.up1(1'b0),
	.fire2(1'b0),
	.right2(1'b0),
	.left2(1'b0),
	.down2(1'b0),
	.up2(1'b0),
	.sw(8'b0),
	.dbg_cpu_addr()
	);

dac #(
	.C_bits(10))
dac(	
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;
wire [11:0] wram_addr;
wire  [7:0] wram_di;
wire  [7:0] wram_do;
wire 			wram_we;
dpSDRAM256Mb #(
	.freq_g(24))
mram (
	.clock_i(clk_24),
	.reset_i(status[0] | status[6] | buttons[1]),
	.refresh_i(1'b1),
	.port0_cs_i(1'b1),
	.port0_oe_i(1'b1 | ~wram_we),
	.port0_we_i(wram_we),
	.port0_addr_i({"0000000000000",wram_addr}),
	.port0_data_i(wram_di),
	.port0_data_o(wram_do),
	.port1_cs_i(1'b0),
	.port1_oe_i(1'b0),
	.port1_we_i(1'b0),
	.port1_addr_i(),
	.port1_data_i(),
	.port1_data_o(),

	.mem_cke_o(SDRAM_CKE),
	.mem_cs_n_o(SDRAM_nCS),
	.mem_ras_n_o(SDRAM_nRAS),
	.mem_cas_n_o(SDRAM_nCAS),
	.mem_we_n_o(SDRAM_nWE),
	.mem_udq_o(SDRAM_DQMH),
	.mem_ldq_o(SDRAM_DQML),
	.mem_ba_o(SDRAM_BA),
	.mem_addr_o(SDRAM_A),
	.mem_data_io(SDRAM_DQ)
	);

endmodule

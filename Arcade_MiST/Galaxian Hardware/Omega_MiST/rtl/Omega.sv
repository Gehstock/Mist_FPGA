//============================================================================
//  Arcade: Omega
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
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

module Omega
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
	input         CLOCK_27
);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"Omega;;",
	"O2,Joystick Control,Upright,Normal;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;

assign LED = 1;

wire clk_18, clk_12, clk_6, clk_4p5;
wire pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_18),
	.c1(clk_12),
	.c2(clk_6),
	.c3(clk_4p5)//for now, needs a fix
);

wire m_up     = status[2] ? kbjoy[7] | joystick_0[0] | joystick_1[0] : kbjoy[4] | joystick_0[3] | joystick_1[3];
wire m_down   = status[2] ? kbjoy[6] | joystick_0[1] | joystick_1[1] : kbjoy[5] | joystick_0[2] | joystick_1[2];
wire m_left   = status[2] ? kbjoy[4] | joystick_0[3] | joystick_1[3] : kbjoy[6] | joystick_0[1] | joystick_1[1];
wire m_right  = status[2] ? kbjoy[5] | joystick_0[2] | joystick_1[2] : kbjoy[7] | joystick_0[0] | joystick_1[0];

wire m_fire   = kbjoy[0] | joystick_0[4] | joystick_1[4];
wire m_start1 = kbjoy[1];
wire m_start2 = kbjoy[2];
wire m_coin   = kbjoy[3];

galaxian omega
(
	.W_CLK_18M(clk_18),
	.W_CLK_12M(clk_12),
	.W_CLK_6M(clk_6),
	.I_RESET(status[0] | status[6] | buttons[1]),
	.P1_CSJUDLR({m_coin,m_start1,m_fire,m_up,m_down,m_left,m_right}),
	.P2_CSJUDLR({1'b0,  m_start2,m_fire,m_up,m_down,m_left,m_right}),
	.W_R(r),
	.W_G(g),
	.W_B(b),
	.W_H_SYNC(hs),
	.W_V_SYNC(vs),
	.HBLANK(hblank),
	.VBLANK(vblank),
	.W_SDAT_A(audio_a),
	.W_SDAT_B(audio_b)
);

wire [7:0] audio_a, audio_b;
wire [10:0] audio = {1'b0, audio_b, 2'b0} + {3'b0, audio_a};

dac dac (
	.clk_i(clk_18),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

wire hs, vs;
wire [2:0] r, g, b;
wire hblank, vblank;
wire blankn = ~(hblank | vblank);
video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_18),
	.ce_pix(clk_4p5),
	.ce_pix_actual(clk_4p5),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn?r:"000"),
	.G(blankn?g:"000"),
	.B(blankn?b:"000"),
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

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_18   	  ),
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
	.clk(clk_18),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule

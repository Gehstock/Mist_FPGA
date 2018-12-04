//============================================================================
//  Arcade: Arkanoid
//
//  Port to MiST
//  Copyright (C) 2018 Gehstock
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

module Arkanoid_Mist
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
	"Arkanoid;;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T7,Reset;",
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

wire clk_50, clk_25, clk_6p25;

pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_50),
	.c1(clk_25),
	.c3(clk_6p25)
);
	
arkanoid arkanoid(
	.CLOCK(clk_50),
	.CLOCKVGA(clk_25),
	.RESET(~(status[0] | status[7] | buttons[1])),
	.K_LEFT(kbjoy[6] | joystick_0[1]  | joystick_1[1]),
	.K_RIGHT(kbjoy[7] | joystick_0[0]  | joystick_1[0]),
	.K_PAUSE(kbjoy[3] | joystick_0[5]  | joystick_1[5]),
	.K_START(kbjoy[0] | joystick_0[4]  | joystick_1[4]),
	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),
	.VGA_HS(hs),
	.VGA_VS(vs),
	.audio(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

wire hs, vs;
wire [3:0] r, g, b;

video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_25),
	.ce_pix(clk_6p25),
	.ce_pix_actual(clk_6p25),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r[1:0]}),
	.G({g,g[1:0]}),
	.B({b,b[1:0]}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1'b1),//scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 2'b11, status[4:3] == 2'b10, status[4:3] == 2'b01}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_25   	     ),
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
	.clk(clk_25),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule

//============================================================================
//  Arcade: Birdiy
//
//  Version for MiSTer
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

module Birdiy
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
	"Birdiy;;",
	"O1,Rack Test,off,on;",
	"O2,Joystick Control,Upright,Normal;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_snd;
wire pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
);


reg ce_6m;
always @(posedge clk_sys) begin
	reg [1:0] div;
	
	div <= div + 1'd1;
	ce_6m <= !div;
end

reg ce_1m79;
always @(posedge clk_sys) begin
	reg [3:0] div;
	
	div <= div + 1'd1;
	if(div == 12) div <= 0;
	ce_1m79 <= !div;
end

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire [9:0] audio;
assign LED = 1;
wire blankn = ~(hblank | vblank);
wire hblank, vblank;
wire hs, vs;
wire [2:0] r,g;
wire [1:0] b;

video_mixer #(.LINE_LENGTH(340), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_sys),
	.ce_pix(ce_6m),
	.ce_pix_actual(ce_6m),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r}),
	.G({g,g}),
	.B({b,b,b}),
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
	.clk_sys        (clk_sys        ),
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
	.clk(clk_sys),
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
wire m_bomb   = kbjoy[8];
wire m_Serv   = kbjoy[9];

pacmant pacmant
(
    .O_VIDEO_R(r),
    .O_VIDEO_G(g),
    .O_VIDEO_B(b),
    .O_HSYNC(hs),
    .O_VSYNC(vs),
    .O_HBLANK(hblank),
    .O_VBLANK(vblank),

    .O_AUDIO(audio),

	 .I_JOYSTICK_A(~{m_fire,m_right,m_left,m_down,m_up}),
	 .I_JOYSTICK_B(~{m_fire,m_right,m_left,m_down,m_up}),
	 
    .I_SW({status[1], m_start2, m_coin, m_Serv, m_start1}),
    .RESET(status[0] | status[6] | buttons[1]),
	 .CLK(clk_sys),
    .ENA_6(ce_6m)
);

dac dac
(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

//TODO
/*
VIDEO_START_MEMBER(pacman_state,birdiy)
{
	VIDEO_START_CALL_MEMBER( pacman );
	m_xoffsethack = 0;
	m_inv_spr = 1; // sprites are mirrored in X-axis compared to normal behaviour
}

void pacman_state::pacman_map(address_map &map)
{
	//A lot of games don't have an a15 at the cpu.  Generally only games with a cpu daughter board can access the full 32k of romspace.
	map(0x0000, 0x3fff).mirror(0x8000).rom();
	map(0x4000, 0x43ff).mirror(0xa000).ram().w(FUNC(pacman_state::pacman_videoram_w)).share("videoram");
	map(0x4400, 0x47ff).mirror(0xa000).ram().w(FUNC(pacman_state::pacman_colorram_w)).share("colorram");
	map(0x4800, 0x4bff).mirror(0xa000).r(FUNC(pacman_state::pacman_read_nop)).nopw();
	map(0x4c00, 0x4fef).mirror(0xa000).ram();
	map(0x4ff0, 0x4fff).mirror(0xa000).ram().share("spriteram");
	map(0x5000, 0x5007).mirror(0xaf38).w(m_mainlatch, FUNC(addressable_latch_device::write_d0));
	map(0x5040, 0x505f).mirror(0xaf00).w(m_namco_sound, FUNC(namco_device::pacman_sound_w));
	map(0x5060, 0x506f).mirror(0xaf00).writeonly().share("spriteram2");
	map(0x5070, 0x507f).mirror(0xaf00).nopw();
	map(0x5080, 0x5080).mirror(0xaf3f).nopw();
	map(0x50c0, 0x50c0).mirror(0xaf3f).w(m_watchdog, FUNC(watchdog_timer_device::reset_w));
	map(0x5000, 0x5000).mirror(0xaf3f).portr("IN0");
	map(0x5040, 0x5040).mirror(0xaf3f).portr("IN1");
	map(0x5080, 0x5080).mirror(0xaf3f).portr("DSW1");
	map(0x50c0, 0x50c0).mirror(0xaf3f).portr("DSW2");
}

void pacman_state::birdiy_map(address_map &map)
{
	map(0x0000, 0x3fff).mirror(0x8000).rom();
	map(0x4000, 0x43ff).mirror(0xa000).ram().w(FUNC(pacman_state::pacman_videoram_w)).share("videoram");
	map(0x4400, 0x47ff).mirror(0xa000).ram().w(FUNC(pacman_state::pacman_colorram_w)).share("colorram");
//  AM_RANGE(0x4800, 0x4bff) AM_MIRROR(0xa000) AM_READ(pacman_read_nop) AM_WRITENOP
	map(0x4c00, 0x4fef).mirror(0xa000).ram();
	map(0x4ff0, 0x4fff).mirror(0xa000).ram().share("spriteram");
	map(0x5000, 0x5007).mirror(0xaf38).w(m_mainlatch, FUNC(ls259_device::write_d0));
	map(0x5080, 0x509f).mirror(0xaf00).w(m_namco_sound, FUNC(namco_device::pacman_sound_w));
	map(0x50a0, 0x50af).mirror(0xaf00).writeonly().share("spriteram2");
//  AM_RANGE(0x5070, 0x507f) AM_MIRROR(0xaf00) AM_WRITENOP
//  AM_RANGE(0x5080, 0x5080) AM_MIRROR(0xaf3f) AM_WRITENOP
	map(0x50c0, 0x50c0).mirror(0xaf3f).w(m_watchdog, FUNC(watchdog_timer_device::reset_w));
	map(0x5000, 0x5000).mirror(0xaf3f).portr("IN0");
	map(0x5040, 0x5040).mirror(0xaf3f).portr("IN1");
	map(0x5080, 0x5080).mirror(0xaf3f).portr("DSW1");
	map(0x50c0, 0x50c0).mirror(0xaf3f).portr("DSW2");
}*/

endmodule

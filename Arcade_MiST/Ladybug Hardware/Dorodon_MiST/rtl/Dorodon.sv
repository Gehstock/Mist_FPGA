//============================================================================
//  Arcade: Dorodon
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

module Dorodon
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
	"Dorodon;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T6,Reset;",
	"V,v1.10.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [10:0] ps2_key;
reg	[7:0] audio;
wire 			hb, vb;
wire        blankn = ~(hb | vb);
wire 			ce_vid;
wire 			hs, vs;
wire  [1:0] r,g,b;

ladybugt dorodon(
	.CLK_IN(clk_sys),
	.I_RESET(status[0] | status[6] | buttons[1]),
	.O_PIXCE(ce_vid),
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_VSYNC(vs),
	.O_HSYNC(hs),
	.O_VBLANK(vb),
	.O_HBLANK(hb),
	.O_AUDIO(audio),	
	.but_coin_s(~{1'b0,btn_coin}),
	.but_fire_s(~{1'b0,m_fire}),
	.but_bomb_s(~{1'b0,m_bomb}),
	.but_tilt_s(~{1'b0,1'b0}),
	.but_select_s(~{btn_two_players, btn_one_player}),
	.but_up_s(~{1'b0,m_up}),
	.but_down_s(~{1'b0,m_down}),
	.but_left_s(~{1'b0,m_left}),
	.but_right_s(~{1'b0,m_right})
	);
	
video_mixer video_mixer(
	.clk_sys(clk_sys),
	.ce_pix(ce_vid),
	.ce_pix_actual(ce_vid),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? {r,r[1]} : "000"),
	.G(blankn ? {g,g[1]} : "000"),
	.B(blankn ? {b,b[1]} : "000"),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b0,status[2]}),
	.scandoublerD(scandoublerD),
	.scanlines(scandoublerD ? 2'b00 : status[4:3]),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(
	.STRLEN(($size(CONF_STR)>>3)))
mist_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoublerD	 (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.ps2_key			 (ps2_key        ),
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({~audio[7], audio[6:0], 8'b00000000}),
	.dac_o(AUDIO_L)
	);
	
wire m_up     = ~status[2] ? btn_right | joystick_0[0] | joystick_1[0] : btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = ~status[2] ? btn_left | joystick_0[1] | joystick_1[1] : btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = ~status[2] ? btn_up | joystick_0[3] | joystick_1[3] : btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = ~status[2] ? btn_down | joystick_0[2] | joystick_1[2] : btn_right | joystick_0[0] | joystick_1[0];

wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];
wire m_bomb   = btn_fire2 | joystick_0[5] | joystick_1[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_fire3 = 0;
reg btn_coin  = 0;
wire       pressed = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];	

always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		case(code)
			'h75: btn_up         	<= pressed; // up
			'h72: btn_down        	<= pressed; // down
			'h6B: btn_left      		<= pressed; // left
			'h74: btn_right       	<= pressed; // right
			'h76: btn_coin				<= pressed; // ESC
			'h05: btn_one_player   	<= pressed; // F1
			'h06: btn_two_players  	<= pressed; // F2
			'h14: btn_fire3 			<= pressed; // ctrl
			'h11: btn_fire2 			<= pressed; // alt
			'h29: btn_fire1   		<= pressed; // Space
		endcase
	end
end

endmodule 
//============================================================================
//  Arcade: Moon War
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

module MoonWar_Mist
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
	"Moon War;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
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

reg ce_6p, ce_6n, ce_12, ce_1p79;
always @(negedge clk_sys) begin
reg [1:0] div = 0;
reg [3:0] div179 = 0;
	div <= div + 1'd1;
	ce_12 <= div[0];
	ce_6p <= div[0] & ~div[1];
	ce_6n <= div[0] &  div[1];	
   ce_1p79 <= 0;
   div179 <= div179 - 1'd1;
   if(!div179) begin
		div179 <= 13;
		ce_1p79 <= 1;
   end
end

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [10:0] ps2_key;
wire [9:0] audio;
wire hs, vs;
wire blankn = ~(hb | vb);
wire hb, vb;
wire [3:0] r,b,g;

scramble_top scramble (
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
   .O_HBLANK(hb),
   .O_VBLANK(vb),
	.O_AUDIO(audio),
	.ip_dip_switch({1'b1,2'b00,1'b0,1'b0}),//coin, coin, cabinet, Lives, Lives
	.ip_1p(~{btn_one_player, m_fire14, m_fire13, m_fire12, m_fire11, m_left1, m_right1}),
   .ip_2p(~{btn_two_players, m_fire24, m_fire23, m_fire22, m_fire21, m_left2, m_right2}),
   .ip_service(1'b1),
   .ip_coin1(~btn_coin),
   .ip_coin2(1'b1),
	.RESET(status[0] | status[6] | buttons[1]),
	.clk(clk_sys),
	.ena_12(ce_12),
	.ena_6(ce_6p),
	.ena_6b(ce_6n),
	.ena_1_79(ce_1p79)
	);

mist_video #(.COLOR_DEPTH(4),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b1,status[2]}),
	.ce_divider(1'b1),
	.blend(status[5]),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.ypbpr(ypbpr)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(10)dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
//											Rotated														Normal
//wire m_up1     = ~status[2] ? btn_left | joystick_0[1] : btn_up | joystick_0[3];
//wire m_down1   = ~status[2] ? btn_right | joystick_0[0] : btn_down | joystick_0[2];
wire m_left1   = btn_left | joystick_0[1];
wire m_right1  = btn_right | joystick_0[0];

wire m_fire11   = btn_fire1 | joystick_0[4];
wire m_fire12   = btn_fire2 | joystick_0[5];
wire m_fire13   = btn_fire3 | joystick_0[6];
wire m_fire14   = btn_fire4 | joystick_0[7];

//wire m_up2     = ~status[2] ? joystick_1[1] : joystick_1[3];
//wire m_down2   = ~status[2] ? joystick_1[0] : joystick_1[2];
wire m_left2   = ~status[2] ? joystick_1[2] : joystick_1[1];
wire m_right2  = ~status[2] ? joystick_1[3] : joystick_1[0];

wire m_fire21  = joystick_1[4];
wire m_fire22  = joystick_1[5];
wire m_fire23  = joystick_1[6];
wire m_fire24  = joystick_1[7];


reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_fire3 = 0;
reg btn_fire4 = 0;
reg btn_coin  = 0;
wire       key_pressed;
wire [7:0] key_code;
wire       key_strobe;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up          <= key_pressed; // up
			'h72: btn_down        <= key_pressed; // down
			'h6B: btn_left        <= key_pressed; // left
			'h74: btn_right       <= key_pressed; // right
			'h76: btn_coin        <= key_pressed; // ESC
			'h05: btn_one_player  <= key_pressed; // F1
			'h06: btn_two_players <= key_pressed; // F2
			'h12: btn_fire3       <= key_pressed; // shift l
			'h14: btn_fire3       <= key_pressed; // ctrl
			'h11: btn_fire2       <= key_pressed; // alt
			'h29: btn_fire1       <= key_pressed; // Space
		endcase
	end
end

endmodule 
//============================================================================
//  Arcade: Galaxian
//
//  Port to MiST
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

module Galaxian_MiST(
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

// Choose one for name/built-in ROMset/features
`define NAME "GALAXIAN"
//`define NAME "MOONCR"
//`define NAME "AZURIAN"
//`define NAME "BLACKHOLE"
//`define NAME "CATACOMB"
//`define NAME "CHEWINGG"
//`define NAME "DEVILFSH"
//`define NAME "KINGBAL"
//`define NAME "MRDONIGH"
//`define NAME "OMEGA"
//`define NAME "ORBITRON"
//`define NAME "PISCES"
//`define NAME "UNIWARS"
//`define NAME "VICTORY"
//`define NAME "WAROFBUG"
//`define NAME "ZIGZAG" -- doesn't work, video gen issues
//`define NAME "TRIPLEDR"

reg rotate_dir;

always @(*) begin
	if (`NAME == "MOONCR" ||
	    `NAME == "DEVILFSH" ||
			`NAME == "KINGBAL" ||
			`NAME == "OMEGA" ||
			`NAME == "ORBITRON" ||
			`NAME == "VICTORY")
	begin
		rotate_dir = 1'b0;
	end else begin
		rotate_dir = 1'b1;
	end
end

localparam CONF_STR = {
	`NAME,";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"T0,Reset;",
	"V,v2.00.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_24, clk_12, clk_6;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_24),
	.c2(clk_12),
	.c3(clk_6)
	);
	
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire  [7:0] audio_a, audio_b, audio_c;
wire [10:0] audio = {1'b0, audio_b, 2'b0} + {3'b0, audio_a} + {2'b00, audio_c, 1'b0};
wire 			hs, vs;
wire 			hb, vb;
wire        blankn = ~(hb | vb);
wire  [2:0] r,g,b;

galaxian #(.name(`NAME)) galaxian
(
	.W_CLK_12M(clk_12),
	.W_CLK_6M(clk_6),
	.I_RESET(status[0] | buttons[1]),
	.P1_CSJUDLR({btn_coin,btn_one_player,m_fire,m_up,m_down,m_left,m_right}),
	.P2_CSJUDLR({1'b0,btn_two_players,m_fire,m_up,m_down,m_left,m_right}),
	.W_R(r),
	.W_G(g),
	.W_B(b),
	.W_H_SYNC(hs),
	.W_V_SYNC(vs),
	.HBLANK(hb),
	.VBLANK(vb),
	.W_SDAT_A(audio_a),
	.W_SDAT_B(audio_b),
	.W_SDAT_C(audio_c)
);

mist_video #(.COLOR_DEPTH(3),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_24),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b1),
	.rotate({rotate_dir,status[2]}),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.blend(status[5]),
	.ypbpr(ypbpr)
	);
	
user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_12         ),
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

dac #(11)
dac(
	.clk_i(clk_12),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
	
//                                                         Rotated                                                                                        Normal
wire m_up     = ~status[2] ? (rotate_dir ? btn_left  | joystick_0[1] | joystick_1[1] : btn_right | joystick_0[0] | joystick_1[0] ) : btn_up    | joystick_0[3] | joystick_1[3];
wire m_down   = ~status[2] ? (rotate_dir ? btn_right | joystick_0[0] | joystick_1[0] : btn_left  | joystick_0[1] | joystick_1[1] ) : btn_down  | joystick_0[2] | joystick_1[2];
wire m_left   = ~status[2] ? (rotate_dir ? btn_down  | joystick_0[2] | joystick_1[2] : btn_up    | joystick_0[3] | joystick_1[3] ) : btn_left  | joystick_0[1] | joystick_1[1];
wire m_right  = ~status[2] ? (rotate_dir ? btn_up    | joystick_0[3] | joystick_1[3] : btn_down  | joystick_0[2] | joystick_1[2] ) : btn_right | joystick_0[0] | joystick_1[0];
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
wire       key_strobe;
wire       key_pressed;
wire [7:0] key_code;	

always @(posedge clk_12) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        	<= key_pressed; // down
			'h6B: btn_left      		<= key_pressed; // left
			'h74: btn_right       	<= key_pressed; // right
			'h76: btn_coin				<= key_pressed; // ESC
			'h05: btn_one_player   	<= key_pressed; // F1
			'h06: btn_two_players  	<= key_pressed; // F2
			'h14: btn_fire3 			<= key_pressed; // ctrl
			'h11: btn_fire2 			<= key_pressed; // alt
			'h29: btn_fire1   		<= key_pressed; // Space
		endcase
	end
end

endmodule 	

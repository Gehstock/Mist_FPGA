//============================================================================
//  Arcade: Centipede
//
//  Port to MiST 2018 Gehstock
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

module Centipede_MiST
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
	"CENTIPED;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O7,Test,Off,On;",
	"DIP;",
	"R64,Save highscores;",
	"T0,Reset;",
	"V,v1.50.",`BUILD_DATE
};

wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       service   = status[7];

wire       milliped  = core_mod[0];

wire [23:0] dipsw;
assign dipsw[ 7:0] = status[15:8];
assign dipsw[23:8] = status[31:16];

assign LED = ~(ioctl_downl | ioctl_upl);
assign AUDIO_R = AUDIO_L;

wire clk_24, clk_12;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_24),
	.c2(clk_12)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire  [7:0] core_mod;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [7:0] RGB;
wire        hs, vs, vb, hb;
wire        blankn = ~(hb | vb);
wire  [5:0] audio;

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io data_io(
	.clk_sys       ( clk_12       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   ),
	.ioctl_din     ( ioctl_din    )
);

reg reset;
always @(posedge clk_12) reset <= status[0] | buttons[1] | ioctl_downl;

centipede centipede(
	.clk_12mhz(clk_12),
	.reset(reset),
	.milli(milliped),
	.playerinput_i(~{ 1'b0, 1'b0, m_coin1, service, 1'b0, 1'b0, m_two_players, m_one_player, m_fireB, m_fireA }),
	.trakball_i(),
	.joystick_i(~{m_right , m_left, m_down, m_up, m_right , m_left, m_down, m_up}),
	.sw1_i(dipsw[7:0]),
	.sw2_i(dipsw[23:8]),
	.rgb_o(RGB),
	.hsync_o(hs),
	.vsync_o(vs),
	.hblank_o(hb),
	.vblank_o(vb),
	.audio_o(audio),
   // ROM download
	.dl_addr(ioctl_addr[14:0]),
	.dl_data(ioctl_dout),
	.dl_we(ioctl_wr && ioctl_index == 0),
   // High score table save-load
	.hsram_addr(ioctl_addr[5:0]),
	.hsram_dout(ioctl_din),
	.hsram_din(ioctl_dout),
	.hsram_we(ioctl_wr && ioctl_index == 8'hff)
	);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_24           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              (blankn ? RGB[2:0] : 0),
	.G              (blankn ? RGB[5:3] : 0),
	.B              (blankn ? RGB[7:6] : 0),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scanlines      ( scanlines        ),
	.rotate         ( { 1'b0, rotate } ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	.scandoubler_disable(scandoublerD  ),
	.no_csync       ( no_csync         ),
	.ypbpr          ( ypbpr            )
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
	.scandoubler_disable (scandoublerD ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
   .core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.C_bits(12))
dac (
	.clk_i(clk_12),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_12      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b01       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

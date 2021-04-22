//============================================================================
//  Arcade: Time Pilot
//
//  Port to MiST
//  Copyright (C) 2017 Gehstock
//
// Time pilot by Dar (darfpga@aol.fr) (29/10/2017)
// http://darfpga.blogspot.fr
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

module TimePilot_MiST(
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
	"TIMEPLT;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];

wire       psurge = core_mod[0];
wire [7:0] sw1 = status[15:8];
wire [7:0] sw2 = status[23:16];

assign LED = 1;
assign AUDIO_R = AUDIO_L;
assign SDRAM_CLK = clock_48;

wire clock_48, clock_12, clock_6, clock_14, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_48),//24,57600000
	.c1(clock_12),//12.28800000
	.c2(clock_14),//14.31800000
	.c3(clock_6),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;
wire  [6:0] core_mod;

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clock_12       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         ),
	.core_mod       (core_mod       )
	);

wire [14:0] rom_addr;
wire [15:0] rom_do;
wire        rom_rd;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clock_48      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

sdram rom(
	.*,
	.init          ( ~pll_locked  ),
	.clk           ( clock_48      ),
	.wtbt          ( 2'b00        ),
	.dout          ( rom_do     ),
	.din           ( {ioctl_dout, ioctl_dout} ),
	.addr          ( ioctl_downl ? ioctl_addr : rom_addr ),
	.we            ( ioctl_downl & ioctl_wr ),
	.rd            ( !ioctl_downl & rom_rd),
	.ready()
);

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_12) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

reg	 [10:0] audio;
wire        hs, vs;
wire  [4:0] r,g,b;

time_pilot time_pilot(
	.clock_6(clock_6),
	.clock_12(clock_12),
	.clock_14(clock_14),
	.reset(reset),
	.psurge(psurge),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio), 
	.roms_addr(rom_addr),
	.roms_do(rom_do[7:0]),
	.roms_rd(rom_rd),
	.dip_switch_1(sw1),
	.dip_switch_2(sw2),
	.start2(m_two_players),
	.start1(m_one_player),
	.coin1(m_coin1),
	.fire1(m_fireA),
	.right1(m_right),
	.left1(m_left),
	.down1(m_down),
	.up1(m_up),
	.fire2(m_fire2A),
	.right2(m_right2),
	.left2(m_left2),
	.down2(m_down2),
	.up2(m_up2),
	.dl_clk(clock_48),
	.dl_addr(ioctl_addr[15:0]),
	.dl_wr(ioctl_wr),
	.dl_data(ioctl_dout)
);

mist_video #(.COLOR_DEPTH(5), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b0             ),
	.rotate         ( { ~psurge, rotate } ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

dac #(.C_bits(11))dac(
	.clk_i(clock_14),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

// Arcade inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
        
arcade_inputs inputs (
	.clk         ( clock_12    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {~psurge, 1'b1} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
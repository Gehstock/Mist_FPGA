//============================================================================
//  Toaplan Hardware v1 HW top-level for MiST
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

module ToaplanV1(
	output        LED,
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        AUDIO_L,
	output        AUDIO_R,
	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         SPI_SS4,
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

`include "build_id.v"
//		CoreMod 		Game
//		0				Demons World
//		1				Rally Bike
//		2				Vimana
//		3				Same! Same! Same!
//		4				Zerowing
//		5				Truxton
//		6				Out Zone
//		7				Out Zone Conversation
//		8				HellFire

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_72;
assign SDRAM_CKE = 1;

localparam CONF_STR = {
	"ToaplanV1", ";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        joyswap   = status[6];

wire  [7:0] dsw1 = status[23:16];
wire  [7:0] dsw2 = status[31:24];
wire  [7:0] dsw3 = status[39:32];
wire        flipped;
wire        key_service;// = m_fire1[4];
wire        key_test;// = m_fire1[3];
wire        key_tilt;


wire clk_72;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_72),
	.locked(pll_locked)
	);

// reset generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_72) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded | ioctl_downl;
end

// ARM connection
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;
wire  [6:0] core_mod;

user_io #(
	.STRLEN($size(CONF_STR)>>3),
	.ROM_DIRECT_UPLOAD(1))
user_io(
	.clk_sys        (clk_72         ),
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

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io #(.ROM_DIRECT_UPLOAD(1)) data_io(
	.clk_sys       ( clk_72       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [15:0] laudio, raudio;
wire        hs, vs;
wire        blankn = ~(hb | vb);
wire        hb, vb;
wire  [4:0] r,b,g;

ToaplanV1_Top ToaplanV1_Top(
	.pll_locked   	( pll_locked 	),
	.clk_sys      	( clk_72     	),
	.reset        	( reset      	),
	.p1_in			( {m_fire1[3:0],m_right1,m_left1,m_down1,m_up1} ),
	.p2_in			( {m_fire2[3:0],m_right2,m_left2,m_down2,m_up2} ),
	.sw0				( dsw1 			),
	.sw1				( dsw2 			),
	.sw2				( dsw3 			),
	.start			( {m_two_players,m_one_player} ),
	.coin				( {m_coin2,m_coin1} ),
	.b_pause			( 0 				),
	.service			( key_test 		),
	.key_tilt		( key_tilt 		),
	.key_service	( key_service 	),

	
	.core_mod		( core_mod 		),
	.turbo_68k		( 0 				),
	.pause_cpu		( 0 				),
	.scrollDBG		( 0 				),
	
	.hblank			( hb         	),
	.vblank			( vb         	),
	.hsync			( hs         	),
	.vsync			( vs         	),
	.r            	( r          	),
	.g            	( g          	),
	.b            	( b          	),
	.hs_offset		( 0				),
	.vs_offset		( 0				),
	.hs_width		( 0				),
	.vs_width		( 0				),
	.refresh_mod	( 0				),

	.ntsc				( 0				),
	.opl2_level		( 2'b00			),


	.audio_l      	( laudio     	),
	.audio_r      	( raudio     	),

	.ioctl_download( ioctl_downl	),
	.ioctl_index	( ioctl_index	),
	.ioctl_addr   	( ioctl_addr - 2'd2 ),//check
	.ioctl_wr     	( ioctl_wr   	),
	.ioctl_dout   	( ioctl_dout 	),

	.SDRAM_A      	( SDRAM_A    	),
	.SDRAM_BA     	( SDRAM_BA   	),
	.SDRAM_DQ     	( SDRAM_DQ   	),
	.SDRAM_DQML   	( SDRAM_DQML 	),
	.SDRAM_DQMH   	( SDRAM_DQMH 	),
	.SDRAM_nCS    	( SDRAM_nCS  	),
	.SDRAM_nCAS   	( SDRAM_nCAS 	),
	.SDRAM_nRAS   	( SDRAM_nRAS 	),
	.SDRAM_nWE    	( SDRAM_nWE  	)
);

mist_video #(.COLOR_DEPTH(5),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_72),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 5'd0),
	.G(blankn ? g : 5'd0),
	.B(blankn ? b : 5'd0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.no_csync(no_csync),
	.rotate({~flipped,rotate}),
	.ce_divider(3'd5), // pix clock = 72/6
	.blend(blend),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ypbpr(ypbpr)
	);

dac #(16) dacl(
	.clk_i(clk_72),
	.res_n_i(1),
	.dac_i({~laudio[15], laudio[14:0]}),
	.dac_o(AUDIO_L)
	);

dac #(16) dacr(
	.clk_i(clk_72),
	.res_n_i(1),
	.dac_i({~raudio[15], raudio[14:0]}),
	.dac_o(AUDIO_R)
	);

// Common inputs
wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_up4B, m_down4B, m_left4B, m_right4B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2, m_fire3, m_fire4;

arcade_inputs inputs (
	.clk         ( clk_72      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {~flipped, 1'b0} ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, m_fire3, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, m_fire4, m_up4, m_down4, m_left4, m_right4} )
);

endmodule

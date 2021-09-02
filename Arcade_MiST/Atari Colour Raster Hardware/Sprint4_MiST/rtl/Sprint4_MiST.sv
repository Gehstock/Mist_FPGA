//FPGA implementation of Sprint4 arcade game released by Kee Games in 1978
//james10952001
module Sprint4_MiST(
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

`include "rtl\build_id.sv" 

localparam CONF_STR = {
	"Sprint4;;",
	"O1,Test Mode,Off,On;",
	"T2,Next Track;",
// 	"O6,Blend,Off,On;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"O56,Language,German,French,Spanish,English;",
	"O7,Game Cost,2 Coins/Player,1 Coin/Player;",
	"O8,Late Entry,Permitted,Not Permitted;",
	"T0,Reset;",
	"V,v1.10.",`BUILD_DATE
};

//TODO
//Wrong Colors
//Screen Fipped
//No Controls (seems Game Resets after 5sec)

// Configuration DIP switches, these can be brought out to external switches if desired
// See Sprint 4 manual page 6 for complete information. Active low (0 = On, 1 = Off)
//    1 	2	3	4							Game Length		(0111 - 60sec, 1011 - 90sec, 1101 - 120sec, 1110 - 150sec, 1111 - 150sec)
//   					5						Late Entry		(0 - Permitted, 1 - Not Permitted)
//							6					Game Cost		(0 - 2 Coins/Player, 1 - 1 Coin/Player) 
//								7	8			Language			(11 - English, 01 - French, 10 - Spanish, 00 - German)

assign LED = 1'b1;
wire clk_24, clk_12, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.locked(locked)
	);


wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire [31:0] joystick_2;
wire [31:0] joystick_3;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [6:0]	audio1, audio2;
wire 			r, g, b;

wire hs, vs, cs, hb, vb;
wire blankn = ~(hb | vb);
wire compositesync;//todo

sprint4 sprint4(		
	.clk_12(clk_12),
	.Reset_I(~(status[0] | buttons[1])),
	.Hsync(hs),
	.Vsync(vs),
	.Hblank(hb),
	.Vblank(vb),
	.VideoR_O(r),
	.VideoG_O(g),
	.VideoB_O(b),
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(~m_coin1),
	.Coin2_I(~m_coin2),
	.Coin3_I(~m_coin3),
	.Coin4_I(~m_coin4),
	.Start1_I(~m_one_player),
	.Start2_I(~m_two_players),
	.Start3_I(~m_three_players),
	.Start4_I(~m_four_players),
	.Gas1_I(~m_fireA),
	.Gas2_I(~m_fire2A),
	.Gas3_I(~m_fire3A),
	.Gas4_I(~m_fire4A),
	.c_gearup1(m_fireB),
	.c_geardown1(m_fireC),
	.c_left1(m_right),//?
	.c_right1(m_left),//?
	
	.c_gearup2(m_fire2B),
	.c_geardown2(m_fire2C),
	.c_left2(m_right2),//?
	.c_right2(m_left2),//?
	
	.c_gearup3(m_fire3B),
	.c_geardown3(m_fire3C),
	.c_left3(m_right3),//?
	.c_right3(m_left3),//?
	
	.c_gearup4(m_fire4B),
	.c_geardown4(m_fire4C),
	.c_left4(m_right4),//?
	.c_right4(m_left4),//?
	.TrackSel_I(status[2]),
	.Test_I(~status[1]),
	.DIP({~status[6:5],~status[7],~status[8],4'b1111})
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_24         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.joystick_2  	 (joystick_2  	  ),
	.joystick_3  	 (joystick_3  	  ),
	.status         (status         )
	);
	
mist_video #(
	.COLOR_DEPTH(1), 
	.SD_HCNT_WIDTH(9)) 
mist_video(
	.clk_sys        ( clk_24           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R					 (blankn ? r : 0	  ),
	.G					 (blankn ? g : 0	  ),
	.B					 (blankn ? b : 0	  ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scanlines      ( status[4:3]      ),
	.blend          ( status[6]        ),
	.scandoubler_disable(scandoublerD  ),
	.no_csync       ( no_csync         ),
	.ypbpr          ( ypbpr            )
	);

dac #(
	.C_bits(7))
dac_l(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio1),
	.dac_o(AUDIO_L)
	);
	
dac #(
	.C_bits(7))
dac_r(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio2),
	.dac_o(AUDIO_R)
	);	

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_24      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joystick_2  ( joystick_2  ),
	.joystick_3  ( joystick_3  ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 
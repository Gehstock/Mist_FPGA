module sprint2_mist(
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
	"Sprint2;;",
	"O1,Test Mode,Off,On;",
	"T2,Next Track;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T0,Reset;",
	"V,v1.25.",`BUILD_DATE
};

assign LED = 1;

wire clk_24, clk_12;
wire locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.locked(locked)
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0, joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire        no_csync;
wire  [6:0] audio1, audio2;
wire	[7:0] vid;
wire 			vb, hb;
wire 			blankn = ~(hb | vb);
wire 			hs, vs;

sprint2 sprint2(
	.clk_12(clk_12),
	.Reset_n(~(status[0] | buttons[1])),			
	.Hs(hs),
	.Vs(vs),
	.Vb(vb),		
	.Hb(hb),
	.VID(vid),			
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(~m_coin1),
	.Coin2_I(~m_coin2),
	.Start1_I(~m_one_player),
	.Start2_I(~m_two_players),
	.Trak_Sel_I(~status[2]),
	.Gas1_I(~m_fireA),
	.Gas2_I(~m_fire2A),
	.c_gearup(m_fireB),
	.c_geardown(m_fireC),
	.c_left(m_right),//?
	.c_right(m_left),//?
	.c_gearup2(m_fire2B),
	.c_geardown2(m_fire2C),
	.c_left2(m_right2),//?
	.c_right2(m_left2),//?
	.Test_I(~status[1]),
	.Lamp1_O(),
	.Lamp2_O()
	);
	
mist_video #(
	.COLOR_DEPTH(6), 
	.SD_HCNT_WIDTH(9)) 
mist_video(
	.clk_sys        ( clk_24           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R					(blankn ? {vid[7:2]} : 0),
	.G					(blankn ? {vid[7:2]} : 0),
	.B					(blankn ? {vid[7:2]} : 0),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scanlines      (scandoublerD ? 2'b00 : status[4:3]),
//	.rotate         ( { 1'b1, rotate } ),
//	.ce_divider     ( 1'b1             ),
	.blend          ( status[6]        ),
	.scandoubler_disable(scandoublerD  ),
	.no_csync       ( no_csync         ),
	.ypbpr          ( ypbpr            )
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
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
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
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_24      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
//	.rotate      ( rotate      ),
//	.orientation ( 2'b11       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
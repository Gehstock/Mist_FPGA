//FPGA implementation of Subs arcade game released by Kee Games in 1978
//james10952001
module Subs_MiST(
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
	"Subs;;",
	"O1,Test Mode,Off,On;",
	"O2,Monitor ,1,2;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1'b1;
wire clk_24, clk_12, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.locked(locked)
	);

// See Subs manual for complete information. Active low (0 = On, 1 = Off)  * indicates Default
//    1 								Ping in attract mode [*(0-On) (1-Off)]
//	      2							Time/Cred				[*(0-Each coin buys time) (1-1 Coin/Player fixed)]
//   			3	4					Language					[*(00-English) (10-French) (01-Spanish) (11-German)]
//						5				Free play				[*(0-Coin per play) (1-Free Play)]
//							6	7	8	Time						[(000-0:30) (100-1:00) *(010-1:30) (110-2:00) (001-2:30) (101-3:00) (011-3:30) (111-4:00)]
									
wire  [7:0] DIP_Sw = 8'b10000000;		
		
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire [31:0] joystick_0, joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [7:0]	audio_l, audio_r;
wire	 		Display_1, Display_2;
wire vid = status[2] ? Display_2 : Display_1;

wire hs, vs, cs, hb, vb;
wire blankn = ~(hb | vb);
wire compositesync;//todo
wire Steer_1A, Steer_1B;

subs_core subs_core(		
	.clk12(clk_12),
	.Clk_50_I(),
	.Reset_I(~(status[0] | buttons[1])),
	.Vid1_O(Display_1),
	.Vid2_O(Display_2),
	.CompSync_O(),
	.CompBlank_O(),
	.HBlank(hb),
	.VBlank(vb),
	.HSync(hs),
	.VSync(vs),
	.Coin1_I(~m_coin1),
	.Coin2_I(1'b1),//On player only, we have only one Video Output
	.Start1_I(~m_one_player),
	.Start2_I(1'b1),//On player only, we have only one Video Output
	.Fire1_I(~m_fireA),
	.Fire2_I(1'b1),//On player only, we have only one Video Output
	.Steer_1A_I(Steer_1A),
	.Steer_1B_I(Steer_1B),
	.Steer_2A_I(),//On player only, we have only one Video Output
	.Steer_2B_I(),//On player only, we have only one Video Output
	.Test_I(~status[1]),
	.DiagStep_I(1'b1),
	.DiagHold_I(1'b1),
	.Slam_I(~m_tilt),
	.DIP_Sw(DIP_Sw),
	.P1_audio(audio_l),
	.P2_audio(audio_r),
	.LED1_O(),
	.LED2_O(),
	.CCounter_O()
	);
	
joy2quad joy2quad(
	.CLK(clk_12),
	.clkdiv(45000),	
	.c_right(m_right),
	.c_left(m_left),
	.steerA(Steer_1A),
	.steerB(Steer_1B)
);	

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        ( clk_24         	),
	.conf_str       ( CONF_STR       	),
	.SPI_CLK        ( SPI_SCK        	),
	.SPI_SS_IO      ( CONF_DATA0     	),
	.SPI_MISO       ( SPI_DO         	),
	.SPI_MOSI       ( SPI_DI         	),
	.buttons        ( buttons        	),
	.switches       ( switches       	),
	.scandoubler_disable (scandoublerD	),
	.ypbpr          ( ypbpr          	),
	.no_csync       ( no_csync       	),
	.key_strobe     ( key_strobe     	),
	.key_pressed    ( key_pressed    	),
	.key_code       ( key_code       	),
	.joystick_0     ( joystick_0     	),
	.joystick_1     ( joystick_1     	),
	.status         ( status         	)
	);
	
mist_video #(
	.COLOR_DEPTH(1), 
	.SD_HCNT_WIDTH(9)) 
mist_video(
	.clk_sys        ( clk_24           	),
	.SPI_SCK        ( SPI_SCK          	),
	.SPI_SS3        ( SPI_SS3          	),
	.SPI_DI         ( SPI_DI           	),
	.R					 ( blankn ? vid : 0	),
	.G					 ( blankn ? vid : 0	),
	.B					 ( blankn ? vid : 0	),
	.HSync          ( hs               	),
	.VSync          ( vs               	),
	.VGA_R          ( VGA_R           	),
	.VGA_G          ( VGA_G            	),
	.VGA_B          ( VGA_B            	),
	.VGA_VS         ( VGA_VS           	),
	.VGA_HS         ( VGA_HS           	),
	.scanlines      ( status[4:3]      	),
//	.rotate         ( { 1'b1, rotate } 	),
//	.ce_divider     ( 1'b1             	),
//	.blend          ( status[6]        	),
	.scandoubler_disable(scandoublerD  	),
	.no_csync       ( no_csync         	),
	.ypbpr          ( ypbpr            	)
	);

dac #(
	.C_bits(8))
dac_l(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);
	
dac #(
	.C_bits(8))
dac_r(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio_r),
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
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
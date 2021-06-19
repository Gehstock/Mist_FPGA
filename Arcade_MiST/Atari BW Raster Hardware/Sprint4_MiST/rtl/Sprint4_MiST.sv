//FPGA implementation of Sprint 4 arcade game released by Kee Games in 1978
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

//	PORT_START("DIP")
//	PORT_DIPNAME( 0x03, 0x03, DEF_STR( Language ) ) PORT_DIPLOCATION("DIP:8,7")
//	PORT_DIPSETTING(    0x00, DEF_STR( German ) )
//	PORT_DIPSETTING(    0x01, DEF_STR( French ) )
//	PORT_DIPSETTING(    0x02, DEF_STR( Spanish ) )
//	PORT_DIPSETTING(    0x03, DEF_STR( English ) )
//	PORT_DIPNAME( 0x04, 0x04, DEF_STR( Coinage ) ) PORT_DIPLOCATION("DIP:6")
//	PORT_DIPSETTING(    0x00, DEF_STR( 2C_1C ) )
//	PORT_DIPSETTING(    0x04, DEF_STR( 1C_1C ) )
//	PORT_DIPNAME( 0x08, 0x08, "Allow Late Entry" ) PORT_DIPLOCATION("DIP:5")
//	PORT_DIPSETTING(    0x08, DEF_STR( No ) )
//	PORT_DIPSETTING(    0x00, DEF_STR( Yes ) )
//	PORT_DIPNAME( 0xf0, 0xb0, "Play Time" ) PORT_DIPLOCATION("DIP:4,3,2,1")
//	PORT_DIPSETTING(    0x70, "60 seconds" )
//	PORT_DIPSETTING(    0xb0, "90 seconds" )
//	PORT_DIPSETTING(    0xd0, "120 seconds" )
//	PORT_DIPSETTING(    0xe0, "150 seconds" )								
//wire  [7:0] DIP_Sw = 8'b10000000;		
		
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire [31:0] joystick_0, joystick_1, joystick_2, joystick_3;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [6:0]	audio_l, audio_r;
wire	 		r, g, b;

wire hs, vs, cs, hb, vb;
wire blankn = ~(hb | vb);
wire compositesync;//todo
wire Steer_1A, Steer_1B, Steer_2A, Steer_2B, Steer_3A, Steer_3B, Steer_4A, Steer_4B;
wire Gear1_1, Gear2_1, Gear3_1, Gear1_2, Gear2_2, Gear3_2, Gear1_3, Gear2_3, Gear3_3, Gear1_4, Gear2_4, Gear3_4;
wire reset = (status[0] | buttons[1]);
sprint4 sprint4(		
	.Clk_50_I(),
	.Clk_12(clk_12),
	.Reset_I(~reset),
	.Video1_O(),
	.Video2_O(),
	.Vsync(vs),
	.Hsync(hs),
	.Hblank(hb),
	.Vblank(vb),
	.VideoR_O(r),
	.VideoG_O(g),
	.VideoB_O(b),
	.P1_2audio(audio_l),
	.P3_4audio(audio_r),
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
	.Gear1_1_I(Gear1_1),
	.Gear2_1_I(Gear2_1),
	.Gear3_1_I(Gear3_1),	
	.Gear1_2_I(Gear1_2),
	.Gear2_2_I(Gear2_2),
	.Gear3_2_I(Gear3_2),	
	.Gear1_3_I(Gear1_3),
	.Gear2_3_I(Gear2_3),
	.Gear3_3_I(Gear3_3),
	.Gear1_4_I(Gear1_4),
	.Gear2_4_I(Gear2_4),
	.Gear3_4_I(Gear3_4),
	.Steer_1A_I(Steer_1A),
	.Steer_1B_I(Steer_1B),
	.Steer_2A_I(Steer_2A),	
	.Steer_2B_I(Steer_2B),
	.Steer_3A_I(Steer_3A),	
	.Steer_3B_I(Steer_3B),
	.Steer_4A_I(Steer_4A),	
	.Steer_4B_I(Steer_4B),
	.TrackSel_I(~status[2]),
	.Test_I(~status[1]),
	.StartLamp_O()
	);
	
joy2quad steer1(
	.CLK(clk_12),
	.clkdiv(45000),	
	.c_right(m_right),
	.c_left(m_left),
	.steerA(Steer_1A),
	.steerB(Steer_1B)
);	

joy2quad steer2(
	.CLK(clk_12),
	.clkdiv(45000),	
	.c_right(m_right2),
	.c_left(m_left2),
	.steerA(Steer_2A),
	.steerB(Steer_2B)
);	

joy2quad steer3(
	.CLK(clk_12),
	.clkdiv(45000),	
	.c_right(m_right3),
	.c_left(m_left3),
	.steerA(Steer_3A),
	.steerB(Steer_3B)
);	

joy2quad steer4(
	.CLK(clk_12),
	.clkdiv(45000),	
	.c_right(m_right4),
	.c_left(m_left4),
	.steerA(Steer_4A),
	.steerB(Steer_4B)
);	

gearshift gear1(   
	.Clk(clk_12),
	.reset(reset),
	.gearup(m_fireB),
	.geardown(m_fireC),
	.gearout(),
	.gear1(Gear1_1),
	.gear2(Gear2_1),
	.gear3(Gear3_1)
);

gearshift gear2(   
	.Clk(clk_12),
	.reset(reset),
	.gearup(m_fire2B),
	.geardown(m_fire2C),
	.gearout(),
	.gear1(Gear1_2),
	.gear2(Gear2_2),
	.gear3(Gear3_2)
);

gearshift gear3(   
	.Clk(clk_12),
	.reset(reset),
	.gearup(m_fire3B),
	.geardown(m_fire3C),
	.gearout(),
	.gear1(Gear1_3),
	.gear2(Gear2_3),
	.gear3(Gear3_3)
);

gearshift gear4(   
	.Clk(clk_12),
	.reset(reset),
	.gearup(m_fire4B),
	.geardown(m_fire4C),
	.gearout(),
	.gear1(Gear1_4),
	.gear2(Gear2_4),
	.gear3(Gear3_4)
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
	.joystick_2     ( joystick_2     	),
	.joystick_3     ( joystick_3     	),	
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
	.R					 ( blankn ? r : 0	),
	.G					 ( blankn ? g : 0	),
	.B					 ( blankn ? b : 0	),
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
	.C_bits(7))
dac_l(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);
	
dac #(
	.C_bits(7))
dac_r(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio_r),
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
//	.rotate      ( rotate      ),
//	.orientation ( 2'b11       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 
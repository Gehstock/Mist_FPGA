module D280ZZZAP_mist(
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
	"280ZZZAP;;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Overlay, On, Off;",
	"T0,Reset;",
	"V,v0.00.",`BUILD_DATE
};

wire  [1:0] scanlines = status[4:3];
wire        rotate    = status[2];
wire        overlay   = status[5];

assign LED = 1;

wire clk_core, clk_vid, clk_aud;
wire pll_locked;
pll pll
(
	.inclk0(CLOCK_27),
	.areset(),
	.c0(clk_core),
	.c1(clk_vid),
	.c2(clk_aud)
);
wire        reset = status[0] | buttons[1];

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0,joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_core       ),
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

wire signed [7:0] steering;
wire signed [7:0] steering_adj = -(steering + 8'h10); // range adjust and negate: 30-b0 -> 40-c0
wire [7:0] pedal;

spy_hunter_control controls (
	.clock_40(clk_core),
	.reset(reset),
	.vsync(vs),
	.gas_plus(m_up),
	.gas_minus(m_down),
	.steering_plus(m_right),
	.steering_minus(m_left),
	.steering(steering),
	.gas(pedal)
);

wire       gear;
input_toggle gear_sw(
	.clk(clk_core),
	.reset(reset),
	.btn(m_fireA),
	.state(gear)
);

wire 			hsync,vsync;
wire 			hs, vs;
wire 			r,g,b;

wire [15:0]RAB;
wire [15:0]AD;
wire [7:0]RDB;
wire [7:0]RWD;
wire [7:0]IB;
wire [5:0]SoundCtrl3;
wire [5:0]SoundCtrl5;
wire Rst_n_s;
wire RWE_n;
wire Video;
wire HSync;
wire VSync;
wire  [7:0] audio;

/*
Dip Switch:E3
1		2		3		4		5		6		7		8		Function	Option
Coinage
On		On	 	 	 	 	 	 								1 Coin/1 Credit*
Off	On	 	 	 	 	 	 								1 Coin/2 Credits
On		Off	 	 	 	 	 	 							2 Coins/1 Credit
Off	Off	 	 	 	 	 	 							2 Coins/3 Credits
Game Time
				Off	On	 	 	 	 						Test Mode
When Extended Time At not set to None
				Off	Off	 	 	 	 					60 seconds + 30 extended
				On		On	 	 	 	 						80 seconds + 40 extended*
				On		Off	 	 	 	 					99 seconds + 50 extended
When Extended Time At set to None
				Off	Off	 	 	 	 					60 seconds
				On		On	 	 	 	 						80 seconds*
				On		Off	 	 	 	 					99 seconds
Extended Time At				
								Off	On	 	 				2.00
								On		On	 	 				2.50*
								Off	Off	 	 			None
								On		Off	 	 			None
Language								
												On		On		English*
												On		Off	French
												Off	On		German
												Off	Off	Spanish
*/
wire  [8:1] dip = 8'b00111100;

invaderst invaderst(
	.Rst_n(~reset),
	.Clk(clk_core),
	.ENA(),
	.Coin(m_coin1 | m_coin2),
	.Sel1Player(m_one_player),
	.Sel2Player(m_two_players),
	.Fire(gear),
	.Pedal(pedal[7:4]),
	.Steering(steering_adj),
	.DIP(dip),
	.RDB(RDB),
	.IB(IB),
	.RWD(RWD),
	.RAB(RAB),
	.AD(AD),
	.SoundCtrl3(SoundCtrl3),
	.SoundCtrl5(SoundCtrl5),
	.Rst_n_s(Rst_n_s),
	.RWE_n(RWE_n),
	.Video(Video),
	.HSync(HSync),
	.VSync(VSync)
	);

D280ZZZAP_memory D280ZZZAP_memory (
	.Clock(clk_core),
	.RW_n(RWE_n),
	.Addr(AD),
	.Ram_Addr(RAB),
	.Ram_out(RDB),
	.Ram_in(RWD),
	.Rom_out(IB)
	);

D280ZZZAP_Overlay D280ZZZAP_Overlay (
	.Video(Video),
	.Overlay(~overlay),
	.CLK(clk_core),
	.Rst_n_s(Rst_n_s),
	.HSync(HSync),
	.VSync(VSync),
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs)
	);

mist_video #(.COLOR_DEPTH(1)) mist_video(
	.clk_sys(clk_vid),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(r),
	.G(g),
	.B(b),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ce_divider(0),
	.ypbpr(ypbpr),
	.no_csync(no_csync)
	);
/*
 --* Port 3:
 --* bit 0= sound freq
 --* bit 1= sound freq
 --* bit 2= sound freq
 --* bit 3= sound freq
 --* bit 4= HI SHIFT MODIFIER
 --* bit 5= LO SHIFT MODIFIER
 --* bit 6= NC
 --* bit 7= NC
 --*
 --* Port 5:
 --* bit 0= BOOM sound
 --* bit 1= ENGINE sound
 --* bit 2= Screeching Sound
 --* bit 3= after car blows up, before it appears again
 --* bit 4= NC
 --* bit 5= coin counter
 --* bit 6= NC
 --* bit 7= NC
*/
audio audio_inst (
	.Clk_5(clk_aud),
	.Motor1_n(SoundCtrl5[1]),
	.Skid1(SoundCtrl5[2]),
	.Crash_n(~SoundCtrl5[0]),
	.NoiseReset_n(1'b1),
	.motorspeed(SoundCtrl3[3:0]),
	.Audio1(audio)
);

assign AUDIO_R = AUDIO_L;

dac dac (
	.clk_i(clk_aud),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_core    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b00       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

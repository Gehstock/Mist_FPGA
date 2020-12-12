module Soundboard(
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
	"SND;;",
//	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign 		LED = 1;
assign 		AUDIO_R = AUDIO_L;

wire clk3p58, clk24;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk24),
	.c1(clk3p58)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire			ypbpr;
wire			scandoublerD;
wire  [7:0] audio;
wire        hs, vs;
wire [2:0] 	r, g, b;
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire 	[5:0] snd_ctl;
always @(clk24, key_pressed)
	if (key_pressed == 0) 
		snd_ctl <= key_code[5:0]; 
	else snd_ctl[5:0] <= 6'b111111;
	
Gottlieb_snd Gottlieb_snd ( 	
	.clk_358(clk3p58),//	:	in std_logic; -- 3.58 MHz clock
	.reset_l(~(status[0] | buttons[1])),//	:	in std_logic; -- reset input, active low
	.S1(snd_ctl[0]),// 		:	in std_logic; -- Sound control input lines (active low)
	.S2(snd_ctl[1]),//			: 	in std_logic; 
	.S4(snd_ctl[2]),// 		:  in std_logic;
	.S8(snd_ctl[3]),//			:  in std_logic;
	.S16(snd_ctl[4]),//		:	in std_logic;
	.S32(snd_ctl[5]),//		:	in std_logic;	
	.switches(6'b111111),//	: 	in	std_logic_vector(5 downto 0); -- DIP switches used for testing with some ROMs
	.test(1'b1),//		:	in	std_logic; -- Test button on the sound board, active low
	.audio_dat(audio)//: 	out std_logic_vector(7 downto 0)
	);
	
mist_video #(.COLOR_DEPTH(3),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk24),
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
	//.rotate({1'b1,status[2]}),
	.ce_divider(1'b0),
	//.blend(status[5]),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.ypbpr(ypbpr)
	);
	
user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk24       ),
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

dac #(
	.C_bits(8))
dac(
	.clk_i(clk24),
	.res_n_i(1'b1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);	
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk24    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	//.rotate      ( rotate      ),
	//.orientation ( orientation ),
	//.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0   		),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);		

endmodule 
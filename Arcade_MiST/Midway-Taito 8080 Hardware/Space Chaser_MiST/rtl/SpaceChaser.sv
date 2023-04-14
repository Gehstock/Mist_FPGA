module SpaceChaser(
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
	"SpaceChaser;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O6,Joystick Swap,Off,On;",
	"OGJ,CRT H-Sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"OKN,CRT V-Sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire  [1:0] scanlines = status[4:3];
wire        rotate    = status[2];
wire        joyswap   = status[6];

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_vid;
wire pll_locked;
pll pll
(
	.inclk0(CLOCK_27),
	.areset(),
	.c0(clk_sys),
	.c1(clk_vid)
);

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
wire  [7:0] audio;
wire 			hsync,vsync;
wire 			hs, vs, vb, hb;
wire blankn = ~(hb | vb);
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

invaderst invaderst(
	.Rst_n(~(status[0] | buttons[1])),
	.Clk(clk_sys),
	.ENA(),
	.GDB0({1'b0,2'b00,m_fire2A, m_right2, m_down2, m_left2, m_up2}),
	.GDB1({m_coin1,m_one_player, m_two_players, m_fireA, m_right, m_down, m_left, m_up}),
	.GDB2(),
	.RDB(RDB),
	.IB(IB),
	.RWD(RWD),
	.RAB(RAB),
	.AD(AD),
	.SoundCtrl3(SoundCtrl3),
	.SoundCtrl5(SoundCtrl5),
	.Rst_n_s(Rst_n_s),
	.RWE_n(RWE_n),
	.RED(r),
	.GREEN(g),
	.BLUE(b),
	.HSync(hs),
	.VSync(vs),
	.VBlank(vb),
	.HBlank(hb),
	.HShift(status[19:16]),
	.VShift(status[23:20])
//	.HShift(4'b1100),
//	.VShift()
	);
		
invaders_memory invaders_memory (
	.Clock(clk_sys),
	.RW_n(RWE_n),
	.Addr(AD),
	.Ram_Addr(RAB),
	.Ram_out(RDB),
	.Ram_in(RWD),
	.Rom_out(IB)
	);
		
invaders_audio invaders_audio (
	.Clk(clk_sys),
	.S1(SoundCtrl3),
	.S2(SoundCtrl5),
	.Aud(audio)
	);

mist_video #(.COLOR_DEPTH(1)) mist_video(
	.clk_sys(clk_vid),
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
	.rotate({1'b0,rotate}),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ce_divider(1'b0),
	.ypbpr(ypbpr),
	.no_csync(no_csync)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_sys       ),
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


dac dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b01       ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

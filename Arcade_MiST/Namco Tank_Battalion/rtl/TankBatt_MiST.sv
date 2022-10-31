
module TankBatt_MiST
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

//Todo Sound 

localparam CONF_STR = {
	"CENTIPED;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
//	"T7,Service Swap,Off,On;",	
//	"O8,Test Mode,Off,On;",
	
	"O9,Lives,3,2;",
	"OCD,Coinage,1 Coin/1 Credit,2 Coins/1 Credit,1 Coin/2 Credits,Freeplay;",
	"OAB,Bonus,20000,10000,None,15000;",
	"OE,Cabinet,Upright,Cocktail;",
	
	"T0,Reset;",
	"V,v1.50.",`BUILD_DATE
};

wire        rotate = status[2];
wire [1:0] 	scanlines = status[4:3];
wire        blend = status[5];
wire       	joyswap   = status[6];


wire        service  = status[8];
wire        cabinet  = status[14];
wire [1:0] 	coinage = status[13:12];
wire        lives  = status[9];
wire [1:0] 	bonus = status[13:12];

wire [1:0] orientation = 2'b11;

assign LED = 1'b1;
assign AUDIO_R = AUDIO_L;

wire clk_6, clk_18, clk_36;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_36),//36.864
	.c1(clk_18),//18.432
	.c2(clk_6)//6.144
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [31:0] joystick_0;
wire  [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  		r, g, b;
wire        hs, vs, vb, hb;
wire        blankn = ~(hb | vb);
wire  [15:0] audio;
wire  [5:0] motor;
wire resetn = ~(status[0] | buttons[1]);

Tankb_fpga Tankb_fpga(
	.CLK_18M(clk_18),
	.CLK_6M(clk_6),
	.RESET_n(resetn),
	.vid_r(r),
	.vid_g(g),
	.vid_b(b),
	.vid_hs(hs),
	.vid_vs(vs),
	.vid_hb(hb),
	.vid_vb(vb),
	.P1(~{1'b0,m_coin2,m_coin1,m_fireA,m_right,m_down,m_left,m_up}),//service
	.P2(~{1'b0,m_two_players,m_one_player,m_fire2A,m_right2,m_down2,m_left2,m_up2}),//testogg
	.DSW(~{2'b00,lives,bonus,coinage,cabinet}),
	.audio(audio)
);

mist_video #(.COLOR_DEPTH(1), .SD_HCNT_WIDTH(9)) mist_video(
	.clk_sys        ( clk_36           	),
	.SPI_SCK        ( SPI_SCK          	),
	.SPI_SS3        ( SPI_SS3          	),
	.SPI_DI         ( SPI_DI           	),
	.R              ( blankn ? r : 0		),
	.G              ( blankn ? g : 0		),
	.B              ( blankn ? b : 0		),
	.HSync          ( ~hs               ),
	.VSync          ( ~vs               ),
	.VGA_R          ( VGA_R            	),
	.VGA_G          ( VGA_G            	),
	.VGA_B          ( VGA_B            	),
	.VGA_VS         ( VGA_VS           	),
	.VGA_HS         ( VGA_HS           	),
	.scanlines      ( scanlines        	),
	.rotate         ( {orientation[1],rotate} ),
	.ce_divider     ( 1'b0             	),
	.blend          ( blend            	),
	.scandoubler_disable(scandoublerD  	),
	.no_csync       ( no_csync         	),
	.ypbpr          ( ypbpr            	)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_18         ),
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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.C_bits(16))
dac (
	.clk_i(clk_18),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_18      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation 		),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

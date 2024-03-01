module mpatrol(
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

`include "rtl/build_id.v" 

`define CORE_NAME "MPATROL"

localparam CONF_STR = {
	"MPATROL;;",
	"O1,Video Timing,Original,Pal 50Hz;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O56,Bonus Life,10/30/50K,20/40/60K,10K,Never;",
	"O7,Demo mode,Off,On;",
//	"O9,Service,Off,On;",
	"OA,Blending,Off,On;",
	"OBC,Lives,5,3,2,1;",
	"OD,Invulnerability,Off,On;",
	"OE,Coin Mode,Free Play,1C_4P;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire [1:0] scanlines = status[4:3];
wire       blend = status[10];
wire       pal = status[1];
wire		service = status[9];
assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_aud, clk_vid;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_vid),//36
	.c1(clk_sys),//6
	.c2(clk_aud),//3.75	0.895000
	.locked(pll_locked)
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [15:0] joystick_0;
wire  [15:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_vid        ),
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

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io (
	.clk_sys       ( clk_vid      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [11:0] audio;
wire        hs, vs, hb, vb;
wire        blankn = ~(hb | vb);
wire  [3:0] r, g, b;

mpatrol_top mpatrol_top(
	.clk_sys						( clk_sys ),
	.clk_vid						( clk_vid ),
	.clk_aud						( clk_aud ),
	.reset						( status[0] | buttons[1] ),
   .AUDIO						( audio ),
	.IN0							({4'b1111, ~m_coin1, ~service, ~m_two_players, ~m_one_player}),
	.IN1							({~m_fireA, 1'b1, ~m_fireB, 3'b111, ~m_left, ~m_right}),
	.IN2							({~m_fire2A, 1'b1, ~m_fire2B, 3'b111, ~m_left2, ~m_right2}),
	.DIP1							({4'b1111, ~status[6], ~status[5], ~status[12], ~status[11]}),
	.DIP2							({1'b1, ~status[13], 3'b111, ~status[14], 1'b1, 1'b1}),//cheat, nu, nu, nu, coinmode, cab, flip 
   .VBLANK						( vb ),
   .HBLANK						( hb ),
	.VSYNC						( vs ),
	.HSYNC						( hs ),
   .R								( r ),
   .G								( g ),
   .B								( b ),
	.PAL							( pal )
  );

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_vid          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         ),
	.ce_divider     ( 1'b0             ),
	.blend          ( blend            )
	);

dac #(
	.C_bits(12))
dac(
	.clk_i(clk_vid),
	.res_n_i(1'b1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_vid     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

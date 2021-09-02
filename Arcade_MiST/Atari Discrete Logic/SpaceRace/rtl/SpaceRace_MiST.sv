module SpaceRace_MiST(
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
	"SpaceRace;;",
//	"O2,Rotate Controls,Off,On;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
//	"O5,Blend,Off,On;",
	"O6,Coinage,1CREDIT/1COIN,2CREDITS/1COIN;",	
	"O7a,Playtime,0%, 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%, 100%;",	
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        COINAGE  = status[6];
wire [3:0]  PLAYTIME = status[10:7];

assign 		LED = CREDIT_LIGHT_N;
assign 		AUDIO_R = AUDIO_L;

wire clk_sys, clk_aud, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_sys),//57.272 MHz
	.c1(clk_aud),//24.576 MHz
	.locked(pll_locked)
);

reg clk_src;
always @(posedge clk_sys) begin
  reg [1:0]  div;
  div <= div + 2'd1;
  clk_src <= div[1];
end

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [15:0] audio;
wire        hs, vs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
// Monochrome video
wire VIDEO, SCORE;
wire [3:0]  vid = VIDEO ? 4'hF : SCORE ? 4'hB: 4'h0;

wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;


//// Holding down COIN_SW longer than necessary will corrupt or freeze
//// the screen, so limit COIN_SW period to the minimum necessary.
wire coin_sw_raw = m_fireA | m_fire2A;
reg  coin_sw_raw_q;
wire coin_sw_rise = coin_sw_raw & ~coin_sw_raw_q;
always_ff @(posedge clk_sys) coin_sw_raw_q <= coin_sw_raw;

localparam COIN_SW_CNT   = 600000; // 0.0105 s (shoud be longer than 0.01 s)
localparam COIN_SW_CNT_W = $clog2(COIN_SW_CNT);
reg [COIN_SW_CNT_W-1:0] coin_sw_counter = 0;
reg COIN_SW = 1'b0;
always_ff @(posedge clk_sys) begin
  // COIN_SW will corrupt the screen while playing,
  // so disable it if there is credit left.
  if (coin_sw_rise && CREDIT_LIGHT_N) begin
    coin_sw_counter = 0;
    COIN_SW = 1'b1;
  end else if (coin_sw_counter == COIN_SW_CNT - 1) begin
    COIN_SW = 1'b0;
  end else begin
    coin_sw_counter = coin_sw_counter + 1'd1;
  end
end

wire CREDIT_LIGHT_N;
space_race_top space_race_top(
	.CLK_DRV(clk_sys), //57.272 MHz
	.CLK_SRC(clk_src), //14.318 MHz
	.CLK_AUDIO(clk_aud),//24.576 MHz
	.RESET(status[0] | buttons[1]),
	.COINAGE(COINAGE),  // 0: 1CREDIT/1COIN, 1: 2CREDITS/1COIN
	.PLAYTIME(PLAYTIME), // 0: 0%,  1: 10%, 2: 20%, 3: 30%, 4: 40%, 5: 50%,
                       // 6: 60%, 7: 70%, 8: 80%, 9: 90%, 10: 100%
	.COIN_SW(COIN_SW),
	.START_GAME(m_fireB | m_fire2B),
	.UP1_N(~m_up), 
	.DOWN1_N(~m_down),
	.UP2_N(~m_up2), 
	.DOWN2_N(~m_down2),
	.CLK_VIDEO(),
	.VIDEO(VIDEO),
	.SCORE(SCORE),
	.HSYNC(hs), 
	.VSYNC(vs),
	.HBLANK(hb), 
	.VBLANK(vb),
	.SOUND(audio),
	.CREDIT_LIGHT_N(CREDIT_LIGHT_N)
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(9)) mist_video(
	.clk_sys        ( clk_aud          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? vid : 0 ),
	.G              ( blankn ? vid : 0 ),
	.B              ( blankn ? vid : 0 ),
	.HSync          ( ~hs              ),
	.VSync          ( ~vs              ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider		 (	0					  ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clk_aud        ),
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

dac #(.C_bits(16))dac(
	.clk_i(clk_aud),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_aud     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b10       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

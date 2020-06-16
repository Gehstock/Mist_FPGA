module CrazyBalloon_mist (
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
	"CBalloon;;",
	"O2,Rotate Controls,On,Off;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Ram Test,On,Off;",
	"OOR,CRT H adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
   "OSV,CRT V adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"T0,Reset;",
	"V,v1.21.",`BUILD_DATE
};

//		<dip bits="1" 	  name="Cabinet" ids="Cocktail,Upright"/>
//		<dip bits="2,3"   name="Lives" ids="2,3,4,5"/>
//		<dip bits="4"     name="Bonus life" ids="5000,10000"/>
//		<dip bits="5,6,7" name="Coinage" ids="4c/1cr,3c/1cr,2c/1cr,1c/1cr,1c/2cr,1c/3cr,1c/4cr,Disable"/>

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_vid, clk_sys;
reg  [1:0] clk_div = 2'd0;
wire cpu_clk = clk_div[1];		// 2.49675 Mhz
wire pix_clk = clk_div[0];		// 4.9935  Mhz
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_vid),// 39.948 Mhz
	.c1(clk_sys)//   9.987 Mhz
	);
	
// Divider for other clocks (7474 and 74161 on PCB)
always @(posedge clk_sys) begin
	clk_div <= clk_div + 1;
end

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire [15:0] audio;
wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
wire [1:0] r, g, b;
wire [ 3:0] hoffset, voffset;
assign { voffset, hoffset } = status[31:24];
wire [7:0] sw = {3'b111,1'b0,1'b0,1'b0,1'b1,status[6]};

CRAZYBALLOON CRAZYBALLOON(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_HBLANK(hb),
	.O_VBLANK(vb),
	.I_H_OFFSET(hoffset),
	.I_V_OFFSET(voffset),
	.O_AUDIO(audio),
	.dipsw1(sw),
	.in0({~m_right2,~m_left2,~m_down2,~m_up2,~m_right,~m_left,~m_down,~m_up}),
	.in1({1'b0,m_coin1,~m_two_players,~m_one_player,1'b1,1'b1,1'b1,1'b1}),
	.dn_addr(),
	.dn_data(),
	.dn_wr(),
	.dn_ld(),
	.RESET(status[0] | buttons[1]),
	.PIX_CLK(pix_clk),
	.CPU_CLK(cpu_clk),
	.CLK(clk_sys)
);

mist_video #(.COLOR_DEPTH(2), .SD_HCNT_WIDTH(10)) mist_video(
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
	.ce_divider(1'b0),
	.rotate({1'b0,rotate}),
	.blend(blend),
	.scanlines(scanlines),
	.scandoubler_disable(scandoublerD),
	.ypbpr(ypbpr)
	);

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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.C_bits(16))
dac(
	.clk_i(clk_vid),
	.res_n_i(1),
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
        .rotate      ( rotate      ),
        .orientation ( 2'b10       ),
        .joyswap     ( 1'b0        ),
        .oneplayer   ( 1'b1        ),
        .controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
        .player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
        .player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

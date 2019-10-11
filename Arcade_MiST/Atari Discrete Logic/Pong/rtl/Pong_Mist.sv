
module Pong_Mist(
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
	"Pong;;",
	"T1,Coin;",
	"O2,Max Points,11,15;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clock_50, clock_7p159;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(status[0] | status[6] | buttons[1]),
	.c0(clock_50),
	.c1(clock_7p159),
	.locked(pll_locked)
	);


wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [15:0] joystick_analog_0;
wire [15:0] joystick_analog_1;
wire        scandoublerD;
wire        ypbpr;
wire  		audio;
wire 			hs, vs;
wire 			blankn = ~(hb | vb);
wire 			hb, vb;
wire  [3:0] r,b,g;

wire  [7:0] paddle1_vpos;
assign paddle1_vpos = joystick_analog_0[15:8] + 8'h80;
wire  [7:0] paddle2_vpos;
assign paddle2_vpos = joystick_analog_1[15:8] + 8'h80;


pong pong(
	.mclk(clock_50),
	.clk7_159(clock_7p159),
	.coin_sw(status[1]),
	.dip_sw({"0000000",status[2]}),
	.paddle1_vpos(paddle1_vpos),
	.paddle2_vpos(paddle2_vpos),
	.r(r),
	.g(g),
	.b(b),
	.hsync(hs),
	.vsync(vs),
	.hblank(hb),
	.vblank(vb),
	.sound_out(audio)
);

mist_video #(.COLOR_DEPTH(4)) mist_video(
	.clk_sys(clock_50),
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
	.ce_divider(1),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.ypbpr(ypbpr)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clock_50        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD),
	.ypbpr          (ypbpr          ),
	.joystick_analog_0(joystick_analog_0),
	.joystick_analog_1(joystick_analog_1),
	.status         (status         )
	);

dac #(4)dac(
	.clk_i(clock_50),
	.res_n_i({4{audio}}),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);


endmodule 

module Laser310_MiST
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

localparam CONF_STR = {
	"Laser310;;",
	"O1,Turbo,Off,On;",
	"O2,Dos Rom,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,SHRG,Off,On;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_50, clk_25, clk_10, clk_6p25;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_50),
	.c1(clk_25),
	.c2(clk_10),
	.c3(clk_6p25)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire       		key_pressed;
wire 		[7:0] key_code;
wire       		key_strobe;
reg  [1:0] audio;
wire  [7:0] audio_s;
wire 			ce_pix;
wire 			hs, vs;
wire  [7:0] r,g,b;

LASER310_TOP LASER310_TOP(
	.CLK50MHZ(clk_50),
	.CLK25MHZ(clk_25),
	.CLK10MHZ(clk_10),
	.RESET(~(status[0] | status[6] | buttons[1])),
	.VGA_RED(r),
	.VGA_GREEN(g),
	.VGA_BLUE(b),
	.VGA_HS(hs),
	.VGA_VS(vs),
	.AUD_ADCDAT(audio),
//	.VIDEO_MODE(1'b0),
	.audio_s(audio_s),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.SWITCH({"00000",~status[5],~status[2],~status[1]}),
	.UART_RXD(),
	.UART_TXD()
	);
	
mist_video #(.COLOR_DEPTH(6)) mist_video(
	.clk_sys(clk_25),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(r[5:0]),
	.G(g[5:0]),
	.B(b[5:0]),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1'b1),//scandoublerD),
	.scanlines(status[4:3]),
	.ypbpr(ypbpr)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_25         ),
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
	.status         (status         )
	);

dac #(
	.C_bits(15))
dac(
	.clk_i(clk_25),
	.res_n_i(1),
//	.dac_i({~audio_s[7],audio_s[6:0],{4{audio}}}),
	.dac_i({8{audio}}),
	.dac_o(AUDIO_L)
	);

endmodule 
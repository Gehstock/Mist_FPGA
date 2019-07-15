module Galaksija_MiST(
   input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,
   output        LED,
   input         UART_RXD,
   output        UART_TXD,
   output        AUDIO_L,
   output        AUDIO_R,
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
   input         CONF_DATA0
	);

`include "build_id.v"
localparam CONF_STR = {
	"Galaksija;;",
	"O23,Scanlines,Off,25%,50%,75%;",
	"T9,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1'b1;
assign AUDIO_R = AUDIO_L;	

wire 				clk_1p7, clk_25, clk_6p25;
pll pll (
	 .inclk0 ( CLOCK_27   ),
	 .c0     ( clk_1p7  ),
	 .c1     ( clk_25  ),
	 .c2     ( clk_6p25 )
	);
	
wire 		[7:0] video;
wire 				hs, vs, blank;
wire  	[1:0] buttons, switches;
wire				ypbpr;
wire        	scandoublerD;
wire 	  [31:0] status;
wire 		[7:0] audio;
wire       		key_pressed;
wire 		[7:0] key_code;
wire       		key_strobe;


galaksija_top galaksija_top (
   .vidclk(clk_25),
	.cpuclk(clk_6p25),
	.audclk(clk_1p7),
   .reset_in(~(status[0] | status[9] | buttons[1])),
   .key_code(key_code),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.audio(audio),
	.cass_in(UART_RXD),
	.cass_out(UART_TXD),
   .video_dat(video),
   .video_hs(hs),
   .video_vs(vs),
	.video_blank(blank)
);	

mist_video #(.COLOR_DEPTH(6)) mist_video(
	.clk_sys(clk_25),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blank ? 0 :video[5:0]),
	.G(blank ? 0 :video[5:0]),
	.B(blank ? 0 :video[5:0]),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1'b1),//scandoublerD),
	.scanlines(scandoublerD ? 2'b00 : {status[3:2] == 3, status[3:2] == 2}),
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
   .C_bits(7))
dac (
   .clk_i(clk_25),
   .res_n_i(1'b1),
   .dac_i(audio),
   .dac_o(AUDIO_L)
  );
endmodule

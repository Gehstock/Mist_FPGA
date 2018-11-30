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
//	"F,GAL,Load Program;",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T9,Reset;",
	"V,v1.00.",`BUILD_DATE
};
wire clk_1p7, clk_25, clk_6p25;
wire ps2_kbd_clk, ps2_kbd_data;
wire [2:0] r, g; 
wire [1:0] b; 
wire hs, vs;
wire  [1:0] buttons, switches;
wire			ypbpr;
wire        forced_scandoubler;
wire [31:0] status;
wire [7:0] audio;
wire [10:0] ps2_key;
assign LED = 1'b1;

pll pll (
	 .inclk0 ( CLOCK_27   ),
	 .c0     ( clk_1p7  ),
	 .c1     ( clk_25  ),
	 .c2     ( clk_6p25 )
	);


mist_io #(
	.STRLEN($size(CONF_STR)>>3)) 
user_io (
	.clk_sys(clk_25),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SCK(SPI_SCK),
	.SPI_DI(SPI_DI),
	.SPI_DO(SPI_DO),
	.SPI_SS2(SPI_SS2),	
	.conf_str(CONF_STR),
	.ypbpr(ypbpr),
	.status(status),
	.scandoubler_disable(forced_scandoubler),
	.buttons(buttons),
	.switches(switches),
	.ps2_key(ps2_key)
	);

video_mixer #(
	.LINE_LENGTH(320), 
	.HALF_DEPTH(0)) 
video_mixer (
	.clk_sys			( clk_25		),
	.ce_pix			( clk_6p25		),
	.ce_pix_actual	( clk_6p25		),
	.SPI_SCK			( SPI_SCK		),
	.SPI_SS3			( SPI_SS3		),
	.SPI_DI			( SPI_DI			),
	.R					( video[5:0]	),
	.G					( video[5:0]	),
	.B					( video[5:0]	),
	.HSync			( hs				),
	.VSync			( vs	   		),
	.VGA_R			( VGA_R			),
	.VGA_G			( VGA_G			),
	.VGA_B			( VGA_B			),
	.VGA_VS			( VGA_VS			),
	.VGA_HS			( VGA_HS			),
	.scanlines		(forced_scandoubler ? 2'b00 : {status[3:2] == 3, status[3:2] == 2}),
	.scandoubler_disable(1'b1),//forced_scandoubler),
	.hq2x				(status[3:2]==1),
	.ypbpr			( ypbpr			),
	.ypbpr_full		( 1				),
	.line_start		( 0				),
	.mono				( 1				)
	);
	wire [7:0] video;
galaksija_top galaksija_top (
   .sysclk(clk_25),
	.audclk(clk_1p7),
   .reset_in(~(status[0] | status[9] | buttons[1])),
   .ps2_key(ps2_key),
	.audio(audio),
	.cass_in(UART_RXD),
	.cass_out(UART_TXD),
   .video_dat(video),
   .video_hs(hs),
   .video_vs(vs),
	.video_blankn()//todo
);	

dac #(
   .msbi_g(7))
dac (
   .clk_i(clk_25),
   .res_n_i(1'b1),
   .dac_i(audio),
   .dac_o(AUDIO_L)
  );

assign AUDIO_R = AUDIO_L;	
endmodule

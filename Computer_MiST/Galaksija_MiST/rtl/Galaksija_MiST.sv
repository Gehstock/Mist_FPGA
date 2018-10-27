module Galaksija_MiST(
   input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,
   output        LED,
   output        AUDIO_L,
   output        AUDIO_R,
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
   input         CONF_DATA0/*,
   output [12:0] SDRAM_A,
   inout  [15:0] SDRAM_DQ,
   output        SDRAM_DQML,
   output        SDRAM_DQMH,
   output        SDRAM_nWE,
   output        SDRAM_nCAS,
   output        SDRAM_nRAS,
   output        SDRAM_nCS,
   output  [1:0] SDRAM_BA,
   output        SDRAM_CLK,
   output        SDRAM_CKE*/
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
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data)/*,
	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.ioctl_wr(ioctl_wr),
	.ioctl_index(ioctl_index),
	.ioctl_download(ioctl_download),	
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout)*/
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
	.R					( {r,r}),
	.G					( {g,g}),
	.B					( {2'b0,b,b}),
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
	.mono				( 0				)
	);
	
galaksija_top galaksija_top (
   .clk(clk_25),
	.a_en(clk_1p7),
   .pixclk(clk_25),
   .reset_n(~(status[0] | status[9] | buttons[1])),
   .PS2_DATA(ps2_kbd_data),
	.PS2_CLK(ps2_kbd_clk),
	.audio(audio),
   .LCD_DAT({b,g,r}),//todo
   .LCD_HS(hs),
   .LCD_VS(vs)
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

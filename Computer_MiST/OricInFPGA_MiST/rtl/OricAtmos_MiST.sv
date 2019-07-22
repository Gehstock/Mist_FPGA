module OricAtmos_MiST(
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
	"OricAtmos;;",
	"O23,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"T9,Reset;",
	"V,v1.00.",`BUILD_DATE
};
wire clk_24, clk_6;
wire [10:0] ps2_key;
wire 			r, g, b; 
wire 			hs, vs;
wire  [1:0] buttons, switches;
wire			ypbpr;
wire        scandoublerD;
wire [31:0] status;
wire [15:0] audio;
assign LED = 1'b1;
assign AUDIO_R = AUDIO_L;

pll pll (
	 .inclk0 ( CLOCK_27   ),
	 .c0     ( clk_24  ),
	 .c1     ( clk_6  )
	);


mist_io #(
	.STRLEN($size(CONF_STR)>>3)) 
user_io (
	.clk_sys(clk_24),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SCK(SPI_SCK),
	.SPI_DI(SPI_DI),
	.SPI_DO(SPI_DO),
	.SPI_SS2(SPI_SS2),	
	.conf_str(CONF_STR),
	.ypbpr(ypbpr),
	.status(status),
	.scandoublerD(scandoublerD),
	.buttons(buttons),
	.switches(switches),
	.ps2_key(ps2_key)
	);

video_mixer video_mixer (
	.clk_sys			( clk_24		),
	.ce_pix			( clk_6		),
	.ce_pix_actual	( clk_6		),
	.SPI_SCK			( SPI_SCK		),
	.SPI_SS3			( SPI_SS3		),
	.SPI_DI			( SPI_DI			),
	.R					( {r,r,r}),
	.G					( {g,g,g}),
	.B					( {b,b,b}),
	.HSync			( hs				),
	.VSync			( vs	   		),
	.VGA_R			( VGA_R			),
	.VGA_G			( VGA_G			),
	.VGA_B			( VGA_B			),
	.VGA_VS			( VGA_VS			),
	.VGA_HS			( VGA_HS			),
	.scanlines		(scandoublerD ? 2'b00 : status[3:2]),
	.scandoublerD  (scandoublerD	),
	.ypbpr			( ypbpr			),
	.ypbpr_full		( 1				),
	.line_start		( 0				),
	.mono				( 0				)
	);

oricatmos oricatmos(
	.RESET(status[0] | status[9] | buttons[1]),
	.ps2_key(ps2_key),
	.PSG_OUT(audio),
	.VIDEO_R(r),
	.VIDEO_G(g),
	.VIDEO_B(b),
	.VIDEO_HSYNC(hs),
	.VIDEO_VSYNC(vs),
	.K7_TAPEIN(UART_RXD),
	.K7_TAPEOUT(UART_TXD),
	.clk_in(clk_24)
	);
	
dac #(
   .msbi_g(15))
dac(
   .clk_i(clk_24),
   .res_n_i(1'b1),
   .dac_i(audio),
   .dac_o(AUDIO_L)
  );	

endmodule

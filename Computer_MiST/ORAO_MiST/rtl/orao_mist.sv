module orao_mist
(
	output        LED,
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         CONF_DATA0,
	input         UART_RX,
	output        UART_TX,
	input         CLOCK_27
);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"Orao;;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire        vid15khz;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire 			hs, vs, cs;
wire   		video;
wire  [7:0] kbjoy;
wire 			clk_50, clk_25, clk_12p5;

pll pll (
	.inclk0			( CLOCK_27		),
	.c0				( clk_50			),
	.c1				( clk_25			),
	.c2				( clk_12p5     )
);

orao #(.ram_kb(24), .clk_mhz(25), .serial_baud(9600)) orao (
	.n_reset		(~(status[0]|status[6]|buttons[1])),
	.clk			( clk_25			),
	.clkvid		( clk_50			),//Check
	.video		( video 			),
	.hs			( hs				),
	.vs			( vs				),
	.cs			( 					),
	.rxd			( UART_RX		),
	.txd			( UART_TX		),
	.rts			( 					),
	.key_b      ( 					),
	.key_c      ( 					),
	.key_enter  ( 					),
	.ps2clk		( ps2_kbd_clk  ),
	.ps2data		( ps2_kbd_data	)
);


video_mixer #(.LINE_LENGTH(256), .HALF_DEPTH(1)) video_mixer (
	.clk_sys			( clk_50			),
	.ce_pix			( clk_12p5		),
	.ce_pix_actual	( clk_12p5		),
	.SPI_SCK			( SPI_SCK		),
	.SPI_SS3			( SPI_SS3		),
	.SPI_DI			( SPI_DI			),
	.R					( {video,video,video}),
	.G					( {video,video,video}),
	.B					( {video,video,video}),
	.HSync			( hs				),
	.VSync			( vs				),
	.VGA_R			( VGA_R			),
	.VGA_G			( VGA_G			),
	.VGA_B			( VGA_B			),
	.VGA_VS			( VGA_VS			),
	.VGA_HS			( VGA_HS			),
	.scandoubler_disable(vid15khz	),
	.ypbpr_full		( 1				),
	.line_start		( 0				),
	.mono				( 1				)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io (
	.clk_sys       ( clk_50   	   ),
	.conf_str      ( CONF_STR     ),
	.SPI_SCK       ( SPI_SCK      ),
	.CONF_DATA0    ( CONF_DATA0   ),
	.SPI_SS2			( SPI_SS2      ),
	.SPI_DO        ( SPI_DO       ),
	.SPI_DI        ( SPI_DI       ),
	.buttons       ( buttons      ),
	.switches   	( switches     ),
	.scandoubler_disable(vid15khz ),
	.ypbpr         ( ypbpr        ),
	.ps2_kbd_clk   ( ps2_kbd_clk  ),
	.ps2_kbd_data	( ps2_kbd_data	),
	.status        ( status       )
);




endmodule 
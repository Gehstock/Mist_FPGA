module vectrex_mist
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
	"Vectrex;BINVEC;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [7:0]	pot_x;
wire  [7:0]	pot_y;
wire  [9:0] audio;
wire 			hs, vs, cs;
wire  [3:0] r, g, b;
wire       	blankn;
wire 			cart_rd;
wire [14:0] cart_addr;
wire  [7:0] cart_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [14:0] ioctl_addr;
wire  [7:0] ioctl_dout;


assign LED = !ioctl_downl;

wire 			clk_25, clk_12p5, clk_6p25, cpu_clock;
wire 			pll_locked;

always @(clk_6p25)begin
	pot_x = 8'h00;
	pot_y = 8'h00;
	if (joystick_0[3] | joystick_1[3] | kbjoy[3]) pot_y = 8'h7F;
	if (joystick_0[2] | joystick_1[2] | kbjoy[2]) pot_y = 8'h80;
	if (joystick_0[1] | joystick_1[1] | kbjoy[1]) pot_x = 8'h80;
	if (joystick_0[0] | joystick_1[0] | kbjoy[0]) pot_x = 8'h7F;
end

pll pll (
	.inclk0			( CLOCK_27		),
	.areset			( 0				),
	.c0				( clk_25			),
	.c1				( clk_12p5		),
	.c2				( clk_6p25		),
	.locked			( pll_locked	)
	);

card card (
	.clock			( cpu_clock		),
	.address			( ioctl_downl ? ioctl_addr : cart_addr),//16kb only for now
	.data				( ioctl_dout	),
	.rden				( !ioctl_downl && cart_rd),
	.wren				( ioctl_downl && ioctl_wr),
	.q					( cart_do		)
	);

vectrex vectrex (
	.clock_24		( clk_25			),  
	.clock_12		( clk_12p5		),
	.cpu_clock_o	( cpu_clock		),
	.reset			( status[0] | status[6] | buttons[1] | ioctl_downl),
	.video_r			( r				),
	.video_g			( g				),
	.video_b			( b				),
	.video_csync	(					),
	.video_blankn	( blankn			),
	.video_hs		( hs				),
	.video_vs		( vs				),
	.audio_out		( audio			),
	.cart_addr		( cart_addr		),
	.cart_do			( cart_do		),
	.cart_rd			( cart_rd		),	
	.rt_1				( joystick_0[4] | joystick_1[4] | kbjoy[4]),//1
	.lf_1				( joystick_0[5] | joystick_1[5] | kbjoy[5]),//2
	.dn_1				( kbjoy[6]		),//3
	.up_1				( kbjoy[7]		),//4
	.pot_x_1			( pot_x			),
	.pot_y_1			( pot_y			),
	.rt_2				( joystick_0[4] | joystick_1[4] | kbjoy[4]),//1
	.lf_2				( joystick_0[5] | joystick_1[5 ] | kbjoy[5]),//2
	.dn_2				( kbjoy[6]		),//3
	.up_2				( kbjoy[7]		),//4
	.pot_x_2			( pot_x			),
	.pot_y_2			( pot_y			),
	.leds				(					),
	.dbg_cpu_addr	(					)
	);

dac dac (
	.clk_i			( clk_25			),
	.res_n_i			( 1				),
	.dac_i			( audio			),
	.dac_o			( AUDIO_L		)
	);
assign AUDIO_R = AUDIO_L;

video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(1)) video_mixer (
	.clk_sys			( clk_25			),
	.ce_pix			( clk_6p25		),
	.ce_pix_actual	( clk_6p25		),
	.SPI_SCK			( SPI_SCK		),
	.SPI_SS3			( SPI_SS3		),
	.SPI_DI			( SPI_DI			),
	.R					( blankn ? r : "0000"),
	.G					( blankn ? g : "0000"),
	.B					( blankn ? b : "0000"),
	.HSync			( hs				),
	.VSync			( vs				),
	.VGA_R			( VGA_R			),
	.VGA_G			( VGA_G			),
	.VGA_B			( VGA_B			),
	.VGA_VS			( VGA_VS			),
	.VGA_HS			( VGA_HS			),
	.scandoubler_disable(1			),
	.ypbpr_full		( 1				),
	.line_start		( 0				),
	.mono				( 0				)
	);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io (
	.clk_sys       ( clk_25   	   ),
	.conf_str      ( CONF_STR     ),
	.SPI_SCK       ( SPI_SCK      ),
	.CONF_DATA0    ( CONF_DATA0   ),
	.SPI_SS2			( SPI_SS2      ),
	.SPI_DO        ( SPI_DO       ),
	.SPI_DI        ( SPI_DI       ),
	.buttons       ( buttons      ),
	.switches   	( switches     ),
	.ypbpr         ( ypbpr        ),
	.ps2_kbd_clk   ( ps2_kbd_clk  ),
	.ps2_kbd_data	( ps2_kbd_data	),
	.joystick_0   	( joystick_0   ),
	.joystick_1    ( joystick_1   ),
	.status        ( status       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index	( ioctl_index	),
	.ioctl_wr		( ioctl_wr		),
	.ioctl_addr		( ioctl_addr	),
	.ioctl_dout		( ioctl_dout	)
	);

keyboard keyboard (
	.clk				( clk_25			),
	.reset			(					),
	.ps2_kbd_clk	( ps2_kbd_clk	),
	.ps2_kbd_data	( ps2_kbd_data	),
	.joystick		( kbjoy			)
	);


endmodule 
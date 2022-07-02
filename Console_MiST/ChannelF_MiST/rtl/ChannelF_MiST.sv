module ChannelF_MiST(
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
	"ChannelF;BINCHFROM;",
	"O1,Swap Joystick,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
wire pll_locked,clock_28p636, clk3p579;
pll pll(
	.locked				( pll_locked		),
	.inclk0				( CLOCK_27			),
	.c0					( clock_28p636		),//28.63636000
	.c1					( clk3p579			)//3.579545
	);


chf_core chf_core(
	.clk					( clk3p579			),
   .reset				( status[0] | buttons[1] | ioctl_downl),
	.pal					(),
	.pll_locked			( pll_locked		),
   .vga_r				( r					),
   .vga_g				( g					),
   .vga_b				( b					),
   .vga_hs				( hs					),
   .vga_vs				( vs					),
   .vga_de				( blankn				),
   .joystick_0			( {m_fireD, m_fireC, m_fireB, m_fireA, 			m_four_players, m_three_players, m_two_players, m_one_player, 					m_up, m_down, m_left, m_right}),
   .joystick_1			( {m_fire2D, m_fire2C, m_fire2B, m_fire2A, 		m_four_players, m_three_players, m_two_players, m_one_player, 					m_up2, m_down2, m_left2, m_right2}),
   .ioctl_download	( ioctl_downl		),
   .ioctl_index		( ioctl_index		),
   .ioctl_wr			( ~ioctl_wr			),//?
   .ioctl_addr			( ioctl_addr		),
   .ioctl_dout			( ioctl_dout		),
   .ioctl_wait			( ),
   .audio_l				( audio				)
);

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;	

data_io data_io(
	.clk_sys       	( clock_28p636 	),
	.SPI_SCK       	( SPI_SCK      	),
	.SPI_SS2       	( SPI_SS2      	),
	.SPI_DI        	( SPI_DI       	),
	.ioctl_download	( ioctl_downl  	),
	.ioctl_index   	( ioctl_index  	),
	.ioctl_wr      	( ioctl_wr    	 	),
	.ioctl_addr    	( ioctl_addr   	),
	.ioctl_dout    	( ioctl_dout   	)
);

mist_video #(.COLOR_DEPTH(6),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys				( clock_28p636		),
	.SPI_SCK				( SPI_SCK			),
	.SPI_SS3				( SPI_SS3			),
	.SPI_DI				( SPI_DI				),
	.R						( blankn ? r[7:2] : 0),
	.G						( blankn ? g[7:2] : 0),
	.B						( blankn ? b[7:2] : 0),
	.HSync				( hs					),
	.VSync				( vs					),
	.VGA_R				( VGA_R				),
	.VGA_G				( VGA_G				),
	.VGA_B				( VGA_B				),
	.VGA_VS				( VGA_VS				),
	.VGA_HS				( VGA_HS				),
	.ce_divider			( 0					),
	.blend				( status[6]			),
	.scandoubler_disable(scandoublerD	),
	.scanlines			( status[4:3]		),
	.ypbpr				( ypbpr				),
	.no_csync			( no_csync			)
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0, joystick_1;
wire        scandoublerD;
wire  [7:0] r, g, b;
wire        hs, vs, blankn;
wire [15:0] audio;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        	( clock_28p636  	),
	.conf_str       	( CONF_STR       	),
	.SPI_CLK        	( SPI_SCK        	),
	.SPI_SS_IO      	( CONF_DATA0     	),
	.SPI_MISO       	( SPI_DO         	),
	.SPI_MOSI       	( SPI_DI         	),
	.buttons        	( buttons        	),
	.switches       	( switches       	),
	.scandoubler_disable (scandoublerD	),
	.ypbpr          	( ypbpr          	),
	.no_csync       	( no_csync       	),
	.key_strobe     	( key_strobe     	),
	.key_pressed    	( key_pressed    	),
	.key_code       	( key_code       	),
	.joystick_0    	( joystick_0     	),
	.joystick_1     	( joystick_1     	),
	.status         	( status         	)
	);

dac #(
	.C_bits(16))
dac(
	.clk_i				( clock_28p636		),
	.res_n_i				( 1'b1				),
	.dac_i				( audio				),
	.dac_o				( AUDIO_L			)
	);	

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG, m_fireH;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G, m_fire2H;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         		( clock_28p636		),
	.key_strobe  		( key_strobe  		),
	.key_pressed 		( key_pressed 		),
	.key_code    		( key_code    		),
	.joystick_0  		( joystick_0  		),
	.joystick_1  		( joystick_1  		),
//	.rotate      		( 0      			),
//	.orientation 		( 2'b00       		),
	.joyswap     		( status[1]   		),
	.oneplayer   		( 1'b0        		),
	.controls    		( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     		( {m_fireH, m_fireG, m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     		( {m_fire2H, m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);
endmodule 
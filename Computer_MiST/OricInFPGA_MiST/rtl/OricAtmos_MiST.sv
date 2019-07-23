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
wire clk_24;
wire        key_pressed;
wire [7:0]  key_code;
wire        key_strobe;
wire        key_extended;
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
	.inclk0				(CLOCK_27			),
	.c0					(clk_24 				)
	);
	
user_io #(
	.STRLEN				(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        	(clk_24         	),
	.conf_str       	(CONF_STR       	),
	.SPI_CLK        	(SPI_SCK        	),
	.SPI_SS_IO      	(CONF_DATA0     	),
	.SPI_MISO       	(SPI_DO         	),
	.SPI_MOSI       	(SPI_DI         	),
	.buttons        	(buttons        	),
	.switches       	(switches      	),
	.scandoubler_disable (scandoublerD	),
	.ypbpr          	(ypbpr          	),
	.key_strobe     	(key_strobe     	),
	.key_pressed    	(key_pressed    	),
	.key_extended   	(key_extended   	),
	.key_code       	(key_code       	),
	.status         	(status         	)
	);
	
mist_video #(.COLOR_DEPTH(3)) mist_video(
	.clk_sys				(clk_24				),
	.SPI_SCK				(SPI_SCK				),
	.SPI_SS3				(SPI_SS3				),
	.SPI_DI				(SPI_DI				),
	.R						({r,r,r}				),
	.G						({g,g,g}				),
	.B						({b,b,b}				),
	.HSync				(hs					),
	.VSync				(vs					),
	.VGA_R				(VGA_R				),
	.VGA_G				(VGA_G				),
	.VGA_B				(VGA_B				),
	.VGA_VS				(VGA_VS				),
	.VGA_HS				(VGA_HS				),
	.ce_divider			(1'b0					),
	.scandoubler_disable(scandoublerD	),
	.scanlines			(scandoublerD ? 2'b00 : status[4:3]),
	.ypbpr				(ypbpr				)
	);

oricatmos oricatmos(
	.RESET				(status[0] | status[9] | buttons[1]),
	.key_pressed		(key_pressed		),
	.key_code			(key_code			),
	.key_extended		(key_extended		),
	.key_strobe			(key_strobe			),
	.PSG_OUT				(audio				),
	.VIDEO_R				(r						),
	.VIDEO_G				(g						),
	.VIDEO_B				(b						),
	.VIDEO_HSYNC		(hs					),
	.VIDEO_VSYNC		(vs					),
	.K7_TAPEIN			(UART_RXD			),
	.K7_TAPEOUT			(UART_TXD			),
	.clk_in				(clk_24				)
	);
	
dac #(
   .c_bits				(16					))
dac(
   .clk_i				(clk_24				),
   .res_n_i				(1						),
   .dac_i				(audio				),
   .dac_o				(AUDIO_L				)
  );	

endmodule

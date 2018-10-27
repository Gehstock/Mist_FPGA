module game2048_mist (
   input 		CLOCK_27,
 	output 		LED,
   output      SPI_DO,
   input       SPI_DI,
   input       SPI_SCK,
   input       SPI_SS3,
   input       CONF_DATA0, 
   output 		VGA_HS,
   output 		VGA_VS,
   output [5:0]VGA_R,
   output [5:0]VGA_G,
   output [5:0]VGA_B
);

assign LED = 1;

`include "rtl/build_id.sv" 
localparam CONF_STR = {
	"2048;;",
	"T2,Reset;",	
	"V,v1.00.",`BUILD_DATE

};

wire clk50, clk12p5;
wire ps2_kbd_clk, ps2_kbd_data;
wire [3:0] r, g, b;
wire hs, vs;
wire ypbpr;
wire [31:0] status;
wire [1:0] buttons, switches;

pll pll (
	 .inclk0(CLOCK_27),
	 .c0(clk50),
	 .c1(clk12p5)
	);

GAME GAME (
	.clk_50Mhz			(clk50			),
	.reset				(status[0] || buttons[1] || status[2]),
	.PS2_CLK				(ps2_kbd_clk	),
	.PS2_DAT				(ps2_kbd_data  ),
	.hsync				(hs				),
	.vsync				(vs				),	
	.red					(r					),
	.green				(g					),
	.blue					(b					)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        	(clk50          	),
	.conf_str       	(CONF_STR       	),
	.SPI_SCK        	(SPI_SCK        	),
	.CONF_DATA0     	(CONF_DATA0     	),
	.SPI_SS2			 	(SPI_SS2        	),
	.SPI_DO         	(SPI_DO         	),
	.SPI_DI         	(SPI_DI         	),
	.buttons        	(buttons        	),
	.switches   	 	(switches       	),
	.scandoubler_disable(1					),
	.ypbpr          	(ypbpr          	),
	.ps2_kbd_clk    	(ps2_kbd_clk    	),
	.ps2_kbd_data   	(ps2_kbd_data   	),
	.status         	(status         	)
	);
	
video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys				(clk50			),
	.ce_pix				(clk12p5			),
	.ce_pix_actual		(clk12p5			),
	.SPI_SCK				(SPI_SCK			),
	.SPI_SS3				(SPI_SS3			),
	.SPI_DI				(SPI_DI			),
	.R						(r					),
	.G						(g					),
	.B						(b					),
	.HSync				(hs				),
	.VSync				(vs				),
	.VGA_R				(VGA_R			),
	.VGA_G				(VGA_G			),
	.VGA_B				(VGA_B			),
	.VGA_VS				(VGA_VS			),
	.VGA_HS				(VGA_HS			),
	.ypbpr_full			(1					),
	.ypbpr          	(ypbpr         ),
	.line_start			(0					),
	.mono					(0					)
	);


endmodule

module Cobra_MiST
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
	input 		  UART_RX,
	input         CLOCK_27
);

`include "build_id.v"
localparam CONF_STR =
{
	"Cobra;;",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire clk50, clk26, clk12p5, clk3p25;

pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk50),
	.c1(clk26),
	.c2(clk12p5),
	.c3(clk3p25)
);

wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire  [1:0] buttons, switches;
wire        forced_scandoubler;
wire [31:0] status;
wire			scandoubler_disable;
wire			ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire reset = status[0] | status[6] | buttons[1];
wire hs, vs;
wire r, g, b;

cobra_top cobra_top ( 
	.clk(clk50),
	.z80_clk(clk3p25),
	.clk26mhz(clk26),
	.led2(),
	.led3(LED),
	.z80_rst(reset),  
	.VGA_HSYNC_OUT(hs),
	.VGA_VSYNC_OUT(vs),
	.VGA_R_OUT(r),
	.VGA_G_OUT(g),
	.VGA_B_OUT(b),	
	.PLAYER_IN(UART_RX),//Tape Input
	.PS2_CLK(ps2_kbd_clk),
	.PS2_DATA(ps2_kbd_data)
	);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk50	        ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr          (ypbpr          ),
	.ps2_kbd_clk    (ps2_kbd_clk    ),
	.ps2_kbd_data   (ps2_kbd_data   ),
	.joystick_0		 (joystick_0	  ),
	.joystick_1		 (joystick_1     ),
	.status         (status         )
);

video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk50),
	.ce_pix(clk12p5),
	.ce_pix_actual(clk12p5),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r,r}),
	.G({g,g,g}),
	.B({b,b,b}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1),//scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[3:2] == 3, status[3:2] == 2}),
	.hq2x(status[3:2]==1),
	.ypbpr_full(1),
	.ypbpr(ypbpr),
	.line_start(0),
	.mono(1)
);

endmodule

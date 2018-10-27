module KC87_mist(
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
	input         SPI_SS4,
   input         CONF_DATA0
);

`include "rtl\build_id.v" 
assign LED = 1;	 
localparam CONF_STR = {
		  "KC87;;",
		  "O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
		  "T6,Reset;",
		  "V,v0.1.",`BUILD_DATE
		};


wire 			clk_sys;
wire 			clk_12p5;
wire 			clk_40;
wire        scandoubler_disable;
wire        ypbpr;
tri        ps2_kbd_clk, ps2_kbd_data;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [3:0] r, g, b;
wire 			hs, vs;

pll pll(
	.areset(),
	.inclk0(CLOCK_27),
	.c0(clk_sys),//50.0Mhz
	.c1(clk_12p5),//12.5Mhz
	.c2(clk_40)//40Mhz
	);


mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.conf_str(CONF_STR),
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SS2(SPI_SS2),
	.SPI_DO(SPI_DO),
	.SPI_DI(SPI_DI),
	.buttons(buttons),
	.switches(switches),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.status(status),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data)
);

video_mixer #(.LINE_LENGTH(768), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_sys),
	.ce_pix(clk_12p5),
	.ce_pix_actual(clk_12p5),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.scandoubler_disable(1),//scandoubler_disable),
	.hq2x(status[4:3]==1),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.R({r,r[1:0]}),
	.G({g,g[1:0]}),
	.B({b,b[1:0]}),
	.mono(0),
	.HSync(hs),
	.VSync(vs),
	.line_start(0),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS)
);

kc87 kc87(
	.vgaclock(clk_40),
   .clk(clk_sys),
	.ResetKey(~(status[0] | status[6] | buttons[1])),
   .VGA_R(r),
   .VGA_G(g),
   .VGA_B(b),
   .VGA_HS(hs),
   .VGA_VS(vs),   
   .PS2_CLK(ps2_kbd_clk),
   .PS2_DAT(ps2_kbd_data),  
   .UART_TXD(),
   .UART_RXD()
	);

endmodule 
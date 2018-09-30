module DottoriLog_mist(
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

`include "rtl\build_id.sv" 

localparam CONF_STR = {
	"DottoriLog;;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joy0, joy1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [7:0] audio;
wire			video;

wire clk_32, clk_8, clk_4;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_32),
	.c1(clk_8),
	.c2(clk_4)
);

dottori dottori (
	.CLK_4M(clk_4),
	.RED(r),
	.GREEN(g),
	.BLUE(b),
	.vSYNC(vs),
	.hSYNC(hs),
	.nRESET(~(status[0] | status[6] | buttons[1])),
	.BUTTONS({	~(kbjoy[5]),		  					//Test Mode
					~(kbjoy[6]),		  					//Start
					~(joy0[5] | joy1[5] | kbjoy[7]),	//Button 2 - Pause
					~(joy0[4] | joy1[4] | kbjoy[4]),	//Button 1 
					~(joy0[0] | joy1[0] | kbjoy[0]),	//Right
					~(joy0[1] | joy1[1] | kbjoy[1]),	//Left
					~(joy0[2] | joy1[2] | kbjoy[2]),	//Down
					~(joy0[3] | joy1[3] | kbjoy[3])})//Up
	);

wire hs; 
wire vs;

video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_32),
	.ce_pix(clk_8),
	.ce_pix_actual(clk_8),
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
	.scandoubler_disable(scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(1)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_32   	     ),
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
	.joystick_0   	 (joy0     ),
	.joystick_1     (joy1     ),
	.status         (status         )
);

keyboard keyboard(
	.clk(clk_32),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule

module CSpace
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
	"C. Space;;",
	"T2,START;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};


wire clk_5m;
wire clk_50m;
wire vclk;
wire pll_locked;
		
pll pll
(
	.inclk0(CLOCK_27),
	.areset(reset),
	.c0(clk_5m),
	.c1(clk_50m),
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire [15:0] audio;
wire video, blank;
wire reset = buttons[1] | status[0] | status[6];
wire hsync,vsync;
assign LED = 1;


wire [3:0] G = blank ? 4'b0 : {4{video}};
wire [3:0] R = blank ? 4'b0 : {4{video}};
wire [3:0] B = blank ? 4'b0 : {4{video}};

video_mixer #(.LINE_LENGTH(350), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_50m),
	.ce_pix(clk_5m),
	.ce_pix_actual(clk_5m),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(R),
	.G(G),
	.B(B),
	.HSync(hsync),
	.VSync(vsync),
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
	.clk_sys        (clk_50m        ),
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
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
);

computer_space_top computerspace
(
	.reset(reset),
	.clock_50(clk_50m),
	.game_clk(clk_5m),
	.signal_ccw(kbjoy[6] | joystick_0[1] | joystick_1[1]),//left
	.signal_cw(kbjoy[7] | joystick_0[0] | joystick_1[0]),//right
	.signal_thrust(kbjoy[4] | joystick_0[3] | joystick_1[3]),//thrust
	.signal_fire(kbjoy[0] | joystick_0[4] | joystick_1[4]),//fire
	.signal_start(kbjoy[3] | kbjoy[1] | kbjoy[1] | status[2]),//start
	.hsync(hsync),
	.vsync(vsync),
	.blank(blank),
	.video(video),
	.wav_out(audio)
);


sigma_delta_dac dacr(
	.CLK(clk_50m),
	.RESET(reset),
	.DACin(audio),
	.DACout(AUDIO_R)
	);
	
sigma_delta_dac dacl(
	.CLK(clk_50m),
	.RESET(reset),	
	.DACin(audio),
	.DACout(AUDIO_L)
	);	
	
keyboard keyboard(
	.clk(clk_50m),
	.reset(reset),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule

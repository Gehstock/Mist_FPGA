module Invaders_mist
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
	"Space Inv.;;",
	"O2,Joystick Control,Upright,Normal;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};


wire clk_sys, clk_mist;
wire pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(),
	.c0(clk_sys),
	.c1(clk_mist)
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
wire [7:0] audio;
wire hsync,vsync;
assign LED = 1;

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire r,g,b;

video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_mist),
	.ce_pix(clk_sys),
	.ce_pix_actual(clk_sys),
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
	.mono(0)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_mist       ),
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



keyboard keyboard(
	.clk(clk_mist),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);
	
//wire m_up     = status[2] ? kbjoy[6] | joystick_0[1] | joystick_1[1] : kbjoy[4] | joystick_0[3] | joystick_1[3];
//wire m_down   = status[2] ? kbjoy[7] | joystick_0[0] | joystick_1[0] : kbjoy[5] | joystick_0[2] | joystick_1[2];
wire m_left   = status[2] ? kbjoy[5] | joystick_0[2] | joystick_1[2] : kbjoy[6] | joystick_0[1] | joystick_1[1];
wire m_right  = status[2] ? kbjoy[4] | joystick_0[3] | joystick_1[3] : kbjoy[7] | joystick_0[0] | joystick_1[0];

wire m_fire   = kbjoy[0] | joystick_0[4] | joystick_1[4];
wire m_start1 = kbjoy[1];
wire m_start2 = kbjoy[2];
wire m_coin   = kbjoy[3];

wire [12:0]RAB;
wire [15:0]AD;
wire [7:0]RDB;
wire [7:0]RWD;
wire [7:0]IB;
wire [5:0]SoundCtrl3;
wire [5:0]SoundCtrl5;
wire Rst_n_s;
wire RWE_n;
wire Video;
wire HSync;
wire VSync;

invaderst invaderst(
		.Rst_n(~(status[0] | status[6] | buttons[1])),
		.Clk(clk_sys),
		.ENA(),
		.Coin(m_coin),
		.Sel1Player(~m_start1),
		.Sel2Player(~m_start2),
		.Fire(~m_fire),
		.MoveLeft(~m_left),
		.MoveRight(~m_right),
		.DIP(8'b0),
		.RDB(RDB),
		.IB(IB),
		.RWD(RWD),
		.RAB(RAB),
		.AD(AD),
		.SoundCtrl3(SoundCtrl3),
		.SoundCtrl5(SoundCtrl5),
		.Rst_n_s(Rst_n_s),
		.RWE_n(RWE_n),
		.Video(Video),
		.HSync(HSync),
		.VSync(VSync)
		);
		
Invaders_memory Invaders_memory (
		.CLK(clk_sys),
		.RWE_n(RWE_n),
		.AD(AD),
		.RAB(RAB),
		.RDB(RDB),
		.RWD(RWD),
		.IB(IB)
		);
		
invaders_audio invaders_audio (
	   .Clk(clk_sys),
	   .S1(SoundCtrl3),
	   .S2(SoundCtrl5),
	   .Aud(audio)
	  );		
	  
invaders_video invaders_video (
		.Video(Video),
		.CLK(clk_sys),
		.Rst_n_s(Rst_n_s),
		.HSync(HSync),
		.VSync(VSync),
		.O_VIDEO_R(r),
		.O_VIDEO_G(g),
		.O_VIDEO_B(b),
		.O_HSYNC(hs),
		.O_VSYNC(vs)
		);

dac dac
(
	.clk_i(clk_mist),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

endmodule

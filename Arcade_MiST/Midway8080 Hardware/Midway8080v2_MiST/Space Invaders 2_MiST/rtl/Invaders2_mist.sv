module Invaders2_mist(
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
	"Space Inv.2;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Overlay, On, Off;",
	"T6,Reset;",
	"V,v1.20.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;


wire clk_sys;
wire pll_locked;
pll pll
(
	.inclk0(CLOCK_27),
	.areset(),
	.c0(clk_sys)
);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;
wire  [7:0] joystick_0,joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [7:0] audio;
wire 			hsync,vsync;
wire 			hs, vs;
wire 			r,g,b;

wire [15:0]RAB;
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
	.Coin(btn_coin),
	.Sel1Player(~btn_one_player),
	.Sel2Player(~btn_two_players),
	.Fire(~m_fire),
	.MoveLeft(~m_left),
	.MoveRight(~m_right),
	.DIP(dip),
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
		
invaders_memory invaders_memory (
	.Clock(clk_sys),
	.RW_n(RWE_n),
	.Addr(AD),
	.Ram_Addr(RAB),
	.Ram_out(RDB),
	.Ram_in(RWD),
	.Rom_out(IB)
	);
		
invaders_audio invaders_audio (
	.Clk(clk_sys),
	.S1(SoundCtrl3),
	.S2(SoundCtrl5),
	.Aud(audio)
	);		
	  
invaders_video invaders_video (
	.Video(Video),
	.Overlay(~status[5]),
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

mist_video #(.COLOR_DEPTH(3)) mist_video(
	.clk_sys(clk_sys),
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
	.rotate({1'b0,status[2]}),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.ce_divider(1),
	.ypbpr(ypbpr)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_sys       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up     = ~status[2] ? btn_right | joystick_0[0] | joystick_1[0] : btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = ~status[2] ? btn_left | joystick_0[1] | joystick_1[1] : btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = ~status[2] ? btn_up | joystick_0[3] | joystick_1[3] : btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = ~status[2] ? btn_down | joystick_0[2] | joystick_1[2] : btn_right | joystick_0[0] | joystick_1[0];
wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];
wire m_bomb   = btn_fire2 | joystick_0[5] | joystick_1[5];
reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_fire3 = 0;
reg btn_coin  = 0;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up          <= key_pressed; // up
			'h72: btn_down        <= key_pressed; // down
			'h6B: btn_left        <= key_pressed; // left
			'h74: btn_right       <= key_pressed; // right
			'h76: btn_coin        <= key_pressed; // ESC
			'h05: btn_one_player  <= key_pressed; // F1
			'h06: btn_two_players <= key_pressed; // F2
			'h14: btn_fire3       <= key_pressed; // ctrl
			'h11: btn_fire2       <= key_pressed; // alt
			'h29: btn_fire1       <= key_pressed; // Space
		endcase
	end
end

endmodule

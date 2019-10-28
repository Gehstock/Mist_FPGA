module GunFight_mist(
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
	"Gun Fight;;",
	"O34,Scanlines,Off,25%,50%,75%;",
//	"O5,Overlay, On, Off;",
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
	.Sel1Player(btn_one_player),
	.Fire1(~joystick_0[4]),
	.Fire2(~joystick_1[4]),
	.GunUp1(gun1_up),
	.GunDown1(gun1_dw),
	.MoveLeft1(~joystick_0[1]),
	.MoveRight1(~joystick_0[0]),
	.MoveUp1(~joystick_0[3]),
	.MoveDown1(~joystick_0[2]),
	.GunUp2(gun2_up),
	.GunDown2(gun2_dw),
	.MoveLeft2(~joystick_1[1]),
	.MoveRight2(~joystick_1[0]),
	.MoveUp2(~joystick_1[3]),
	.MoveDown2(~joystick_1[2]),
//	.DIP(dip),
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
	.HSync(hs),
	.VSync(vs)
	);
		
GunFight_memory GunFight_memory (
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

mist_video #(.COLOR_DEPTH(3)) mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({Video,Video,Video}),
	.G({Video,Video,Video}),
	.B(3'b000),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(scandoublerD),
	.ce_divider(1),
	.scanlines(status[4:3]),
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

dac #(
	.c_bits(8))
dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);


reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_coin  = 0;

reg gun1_up  = 0;
reg gun1_dw  = 0;
reg gun2_up  = 0;
reg gun2_dw  = 0;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
			'h76: btn_coin        <= key_pressed; // ESC
			'h05: btn_one_player  <= key_pressed; // F1
			'h06: btn_two_players <= key_pressed; // F2
			'h15: gun1_up       <= key_pressed; // Q
			'h35: gun1_dw       <= key_pressed; // Y
			'h75: gun2_up       <= key_pressed; // Arrow up
			'h72: gun2_dw       <= key_pressed; // Arrow down
		endcase
	end
end

endmodule

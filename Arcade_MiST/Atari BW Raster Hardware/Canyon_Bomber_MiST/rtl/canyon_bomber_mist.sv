//Canyon Bomber from james10952001 Port to Mist by Gehstock

module canyon_bomber_mist(
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
	"Cany.Bomb.;;",
	"O1,Self_Test,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T6,Reset;",
	"V,v1.20.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_24, clk_12, clk_6;
wire locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.c2(clk_6),//6.048
	.locked(locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [7:0] joystick_0, joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [10:0] ps2_key;
wire  [6:0] audio1, audio2;
wire	[7:0] RGB;
wire 			vb, hb;
wire 			blankn = ~(hb | vb);
wire 			hs, vs;



canyon_bomber canyon_bomber(		
	.clk_12(clk_12),
	.Reset_I(~(status[0] | status[6] | buttons[1])),		
	.RGB(RGB),
	.Vblank_O(vb),
	.HBlank_O(hb),
	.HSync_O(hs),
	.VSync_O(vs),
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(~btn_coin),
	.Coin2_I(1'b1),
	.Start1_I(~btn_one_player),
	.Start2_I(~btn_two_players),
	.Fire1_I(~(btn_fire2 | joystick_0[4])),
	.Fire2_I(~joystick_1[4]),
	.Slam_I(1'b1),
	.Test_I(~status[1]),
	.Lamp1_O(),
	.Lamp2_O()
	);

dac dacl(
	.CLK(clk_24),
	.RESET(0),
	.DACin({audio1,audio2,2'b0}),
	.DACout(AUDIO_L)
	);

video_mixer video_mixer(
	.clk_sys(clk_24),
	.ce_pix(clk_6),
	.ce_pix_actual(clk_6),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? {RGB[7:2]} : 0),
	.G(blankn ? {RGB[7:2]} : 0),
	.B(blankn ? {RGB[7:2]} : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoublerD(scandoublerD),
	.scanlines(scandoublerD ? 2'b00 : status[4:3]),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(
	.STRLEN(($size(CONF_STR)>>3))) 
mist_io(
	.clk_sys        (clk_24   	     ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoublerD	 (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.ps2_key			 (ps2_key        ),
	.joystick_0   	 (joystick_0	  ),
	.joystick_1     (joystick_1	  ),
	.status         (status         )
	);

	
reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_coin  = 0;
wire       pressed = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];	

always @(posedge clk_24) begin
	reg old_state;
	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		case(code)
			'h75: btn_up         	<= pressed; // up
			'h72: btn_down        	<= pressed; // down
			'h6B: btn_left      		<= pressed; // left
			'h74: btn_right       	<= pressed; // right
			'h76: btn_coin				<= pressed; // ESC
			'h05: btn_one_player   	<= pressed; // F1
			'h06: btn_two_players  	<= pressed; // F2
			'h14: btn_fire1 			<= pressed; // ctrl
			'h11: btn_fire1 			<= pressed; // alt
			'h29: btn_fire2   		<= pressed; // Space
		endcase
	end
end

endmodule

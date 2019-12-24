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

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"CANYON;;",
	"O1,Self_Test,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

assign LED = 1;

wire clk_24, clk_12;
wire locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.locked(locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [7:0] joystick_0, joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;
wire  [6:0] audio1, audio2;
wire	[7:0] RGB;
wire 			vb, hb;
wire 			blankn = ~(hb | vb);
wire 			hs, vs;


canyon_bomber canyon_bomber(		
	.clk_12(clk_12),
	.Reset_I(~(status[0] | buttons[1])),		
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

dac #(7) dacl(
	.clk_i(clk_12),
	.res_n_i(1'b1),
	.dac_i(audio1),
	.dac_o(AUDIO_L)
	);

dac #(7) dacr(
	.clk_i(clk_12),
	.res_n_i(1'b1),
	.dac_i(audio2),
	.dac_o(AUDIO_R)
	);

mist_video #(.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_24           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? RGB[7:2] : 0 ),
	.G              ( blankn ? RGB[7:2] : 0 ),
	.B              ( blankn ? RGB[7:2] : 0 ),
	.HSync          ( ~hs              ),
	.VSync          ( ~vs              ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b1             ),
	.blend          ( status[5]        ),
	.scandoubler_disable(scandoublerD  ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_12         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD        ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
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

always @(posedge clk_12) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        <= key_pressed; // down
			'h6B: btn_left        <= key_pressed; // left
			'h74: btn_right       <= key_pressed; // right
			'h76: btn_coin				<= key_pressed; // ESC
			'h05: btn_one_player  <= key_pressed; // F1
			'h06: btn_two_players <= key_pressed; // F2
			'h14: btn_fire1       <= key_pressed; // ctrl
			'h11: btn_fire1 			<= key_pressed; // alt
			'h29: btn_fire2       <= key_pressed; // Space
		endcase
	end
end

endmodule

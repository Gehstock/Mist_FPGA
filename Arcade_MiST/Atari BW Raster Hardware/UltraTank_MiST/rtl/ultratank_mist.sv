//FPGA implementation of Ultra Tank arcade game released by Kee Games in 1978
//james10952001



module ultratank_mist(
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
	"Ultra Tank;;",
	"O1,Test Mode,Off,On;",
	"O2,Invisible,Off,On;",
	"O5,Rebound,Off,On;",
	"O7,Barrier,Off,On;",
// 	"O6,Blend,Off,On;",
	"OC,Color,Off,On;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"T0,Reset;",
	"V,v1.10.",`BUILD_DATE
};

assign LED = 1'b1;
wire clk_24, clk_12, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.locked(locked)
	);


wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [6:0] audio1, audio2;
wire	[7:0] Vid;
wire	[2:0] r, g, b;
wire hs, vs, hb, vb;
wire blankn = 1;//~(hb | vb);

reg JoyW_Fw,JoyW_Bk,JoyX_Fw,JoyX_Bk;
reg JoyY_Fw,JoyY_Bk,JoyZ_Fw,JoyZ_Bk;
always @(posedge clk_24) begin 
	case ({m_up,m_down,m_left,m_right}) // Up,down,Left,Right
		4'b1010: begin JoyW_Fw=0; JoyW_Bk=0; JoyX_Fw=1; JoyX_Bk=0; end //Up_Left
		4'b1000: begin JoyW_Fw=1; JoyW_Bk=0; JoyX_Fw=1; JoyX_Bk=0; end //Up
		4'b1001: begin JoyW_Fw=1; JoyW_Bk=0; JoyX_Fw=0; JoyX_Bk=0; end //Up_Right
		4'b0001: begin JoyW_Fw=1; JoyW_Bk=0; JoyX_Fw=0; JoyX_Bk=1; end //Right
		4'b0101: begin JoyW_Fw=0; JoyW_Bk=1; JoyX_Fw=0; JoyX_Bk=0; end //Down_Right
		4'b0100: begin JoyW_Fw=0; JoyW_Bk=1; JoyX_Fw=0; JoyX_Bk=1; end //Down
		4'b0110: begin JoyW_Fw=0; JoyW_Bk=0; JoyX_Fw=0; JoyX_Bk=1; end //Down_Left
		4'b0010: begin JoyW_Fw=0; JoyW_Bk=1; JoyX_Fw=1; JoyX_Bk=0; end //Left
		default: begin JoyW_Fw=0; JoyW_Bk=0; JoyX_Fw=0; JoyX_Bk=0; end
	endcase
	case ({m_up2,m_down2,m_left2,m_right2}) // Up,down,Left,Right
		4'b1010: begin JoyY_Fw=0; JoyY_Bk=0; JoyZ_Fw=1; JoyZ_Bk=0; end //Arriba_Izda
		4'b1000: begin JoyY_Fw=1; JoyY_Bk=0; JoyZ_Fw=1; JoyZ_Bk=0; end //Arriba
		4'b1001: begin JoyY_Fw=1; JoyY_Bk=0; JoyZ_Fw=0; JoyZ_Bk=0; end //Arriba_Derecha
		4'b0001: begin JoyY_Fw=1; JoyY_Bk=0; JoyZ_Fw=0; JoyZ_Bk=1; end //Derecha
		4'b0101: begin JoyY_Fw=0; JoyY_Bk=1; JoyZ_Fw=0; JoyZ_Bk=0; end //Abajo_Derecha		
		4'b0100: begin JoyY_Fw=0; JoyY_Bk=1; JoyZ_Fw=0; JoyZ_Bk=1; end //Abajo
		4'b0110: begin JoyY_Fw=0; JoyY_Bk=0; JoyZ_Fw=0; JoyZ_Bk=1; end //Abajo_Izquierda
		4'b0010: begin JoyY_Fw=0; JoyY_Bk=1; JoyZ_Fw=1; JoyZ_Bk=0; end //Izquierda
		default: begin JoyY_Fw=0; JoyY_Bk=0; JoyZ_Fw=0; JoyZ_Bk=0; end
	endcase
end


assign r = status[12] ? {3{video_r}} : Vid[7:5];
assign g = status[12] ? {3{video_g}} : Vid[7:5];
assign b = status[12] ? {3{video_b}} : Vid[7:5];
wire video_r,video_g,video_b;
wire compositesync;//todo
ultra_tank ultra_tank (
	.clk_12(clk_12),
	.Reset_n(~(status[0] | buttons[1])),
	.HS(hs),
	.VS(vs),
	.HB(hb),	
	.VB(vb),
	.Vid(Vid),
	.CC3_n_O(),
	.CC0_O(video_b),
	.CC1_O(video_g),
	.CC2_O(video_r),
	.Sync_O(compositesync),
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(~m_coin1),
	.Coin2_I(~m_coin2),
	.Start1_I(~m_one_player),
	.Start2_I(~m_two_players),
	.Invisible_I(~status[2]),
	.Rebound_I(~status[5]),
	.Barrier_I(~status[7]),
	.JoyW_Fw_I(~JoyW_Fw),
	.JoyW_Bk_I(~JoyW_Bk),
	.JoyY_Fw_I(~JoyY_Fw),
	.JoyY_Bk_I(~JoyY_Bk),
	.JoyX_Fw_I(~JoyX_Fw),
	.JoyX_Bk_I(~JoyX_Bk),
	.JoyZ_Fw_I(~JoyZ_Fw),
	.JoyZ_Bk_I(~JoyZ_Bk),
	.FireA_I(~m_fireA),
	.FireB_I(~m_fire2A),
	.Test_I(~status[1]),
	.Slam_I(1'b1),
	.LED1_O(),
	.LED2_O(),
	.Lockout_O()
);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_24         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);
	
mist_video #(
	.COLOR_DEPTH(3), 
	.SD_HCNT_WIDTH(9)) 
mist_video(
	.clk_sys        ( clk_24           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R			(blankn ? r : 0	   ),
	.G			(blankn ? g : 0	   ),
	.B			(blankn ? b : 0	   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scanlines      ( status[4:3]      ),
//	.rotate         ( { 1'b1, rotate } ),
//	.ce_divider     ( 1'b1             ),
	.blend          ( status[6]        ),
	.scandoubler_disable(scandoublerD  ),
	.no_csync       ( no_csync         ),
	.ypbpr          ( ypbpr            )
	);

dac #(
	.C_bits(7))
dac_l(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio1),
	.dac_o(AUDIO_L)
	);
	
dac #(
	.C_bits(7))
dac_r(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i(audio2),
	.dac_o(AUDIO_R)
	);	

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_24      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
//	.rotate      ( rotate      ),
//	.orientation ( 2'b11       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
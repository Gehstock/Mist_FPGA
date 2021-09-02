module ComputerSpace_MiST(
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

`include "build_id.v" 

localparam CONF_STR = {
	"C.SPACE;;",
//	"O1,Self_Test,Off,On;",
	"O2,Color,No,Yes;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T0,Reset;",
	"V,v1.25.",`BUILD_DATE
	};
	
assign AUDIO_R = AUDIO_L;
assign LED = 1;

wire clk_sys, clk_25, clk_5;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_sys),//50 MHz for game/sound generator? 
	.c1(clk_25), //4x pixel clock
	.c3(clk_5) //5,842 MHz pixel/game clock
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire [15:0] audio;
wire  [3:0] video;
wire hs, vs, blank;

wire [5:0] rs,gs,bs, ro,go,bo, rc,gc,bc, rm,gm,bm;
wire [3:0] r, g, b;
assign r = blank ? 0 : (rm[5:4] ? 4'b1111 : rm[3:0]) ^ {4{inv}};
assign g = blank ? 0 : (gm[5:4] ? 4'b1111 : gm[3:0]) ^ {4{inv}};
assign b = blank ? 0 : (bm[5:4] ? 4'b1111 : bm[3:0]) ^ {4{inv}};
assign {rs,gs,bs} = ~video[0] ? 18'd0 : status[2] ? {6'b0111,6'b0111,6'b0111} : {6'b0111,6'b0111,6'b0111};
assign {rc,gc,bc} = ~video[1] ? 18'd0 : status[2] ? {6'b0000,6'b1111,6'b1111} : {6'b0111,6'b0111,6'b0111};
assign {ro,go,bo} = ~video[2] ? 18'd0 : status[2] ? {6'b1111,6'b1111,6'b0000} : {6'b1111,6'b1111,6'b1111};

assign rm = rs + ro + rc;
assign gm = gs + go + gc;
assign bm = bs + bo + bc;

reg inv;
always @(posedge clk_5) begin
	reg old_vs, cur_inv;
	old_vs <= vs;
	
	cur_inv <= cur_inv | video[3];
	if (~old_vs & vs) {inv,cur_inv} <= {cur_inv, 1'b0};
end

computer_space_top computerspace(
	.reset(buttons[1] | status[0]),
	.clock_50(clk_sys),
	.game_clk(clk_5),
	.signal_ccw(m_left),
	.signal_cw(m_right),
	.signal_thrust(m_up),
	.signal_fire(m_fireA),
	.signal_start(m_one_player),
	.hsync(hs),
	.vsync(vs),
	.blank(blank),
	.video(video),
	.audio(audio)
	);
	
user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_sys        ),
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
	.COLOR_DEPTH(4), 
	.SD_HCNT_WIDTH(9)) 
mist_video(
	.clk_sys        ( clk_25           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R					 (~blank ? r : 0	  ),
	.G					 (~blank ? g : 0	  ),
	.B					 (~blank ? b : 0	  ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scanlines      ( status[4:3]      ),
//	.rotate         ( { 1'b1, rotate } ),
	.ce_divider     ( 1'b0             ),
	.blend          ( status[6]        ),
	.scandoubler_disable(scandoublerD  ),
	.no_csync       ( no_csync         ),
	.ypbpr          ( ypbpr            )
	);	

dac #(
	.C_bits(15))
dac(
   .dac_o(AUDIO_L),
   .dac_i({~audio[15], audio[14:0]}),
   .clk_i(clk_sys),
   .res_n_i(1)
	);
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
//	.rotate      ( rotate      ),
//	.orientation ( 2'b11       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);


endmodule 
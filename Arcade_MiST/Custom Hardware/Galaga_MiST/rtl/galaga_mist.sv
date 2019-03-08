module galaga_mist
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
	"Galaga;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
//	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.20.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_36, clk_18, clk_9;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_36),
	.c1(clk_18),
	.c2(clk_9)
	);


wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [10:0] ps2_key;
wire [9:0] audio;
wire hs, vs;
wire blankn = ~(hb | vb);
wire hb, vb;
wire [2:0] r,g;
wire [1:0] b;

galaga galaga(
	.clock_18(clk_18),
	.reset(status[0] | status[6] | buttons[1]),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hb(hb),
	.video_vb(vb),
	.video_hs(hs),
	.video_vs(vs),
	.audio(audio),
	.coin(btn_coin),
	.start1(btn_one_player),
	.left1(m_left),
	.right1(m_right),
	.fire1(m_fire),
	.start2(btn_two_players),
	.left2(m_left),
	.right2(m_right),
	.fire2(m_fire)
	);
	
video_mixer video_mixer(
	.clk_sys(clk_36),
	.ce_pix(clk_9),
	.ce_pix_actual(clk_9),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? {r,3'b1} : 0),
	.G(blankn ? {g,3'b1} : 0),
	.B(blankn ? {b,4'b1} : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b1,status[2]}),
	.scanlines(scandoublerD ? 2'b00 : status[4:3]),
//	.scanlines(scandoublerD ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
//	.hq2x(status[4:3]==1),
	.scandoublerD(scandoublerD),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(
	.STRLEN(($size(CONF_STR)>>3)))
mist_io(
	.clk_sys        (clk_36         ),
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
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.msbi_g(9))
dac (
	.clk_i(clk_36),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

//											Rotated														Normal
wire m_up     = ~status[2] ? btn_left | joystick_0[1] | joystick_1[1] : btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = ~status[2] ? btn_right | joystick_0[0] | joystick_1[0] : btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = ~status[2] ? btn_down | joystick_0[2] | joystick_1[2] : btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = ~status[2] ? btn_up | joystick_0[3] | joystick_1[3] : btn_right | joystick_0[0] | joystick_1[0];

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
wire       pressed = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];	

always @(posedge clk_36) begin
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
			'h14: btn_fire3 			<= pressed; // ctrl
			'h11: btn_fire2 			<= pressed; // alt
			'h29: btn_fire1   		<= pressed; // Space
		endcase
	end
end

endmodule 
module frenzy_mist(
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
	"Frenzy;;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"T6,Reset;",
	"V,v1.20.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_20, clk_10, clk_5;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_20),
	.c1(clk_10),
	.c2(clk_5)
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
wire 			hs, vs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire  		r, g, b;
wire [15:0] audio;

berzerk berzerk(
	.clock_10(clk_10),
	.reset(status[0] | status[6] | buttons[1]),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hi(),
   .video_clk(),
	.video_csync(),
	.video_hs(hs),
	.video_vs(vs),
	.video_hb(hb),
	.video_vb(vb),
	.audio_out(audio),  
	.start2(btn_two_players),
	.start1(btn_one_player),
	.coin1(btn_coin),
	.cocktail(1'b0),
	.right1(m_right),
	.left1(m_left),
	.down1(m_down),
	.up1(m_up),
	.fire1(m_fire),
	.right2(m_right),
	.left2(m_left),		
	.down2(m_down),
	.up2(m_up),
	.fire2(m_fire),
	.ledr(),
	.dbg_cpu_di(),
	.dbg_cpu_addr(),
	.dbg_cpu_addr_latch()
);

video_mixer video_mixer(
	.clk_sys(clk_20),
	.ce_pix(clk_5),
	.ce_pix_actual(clk_5),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? {r,r,r} : "000"),
	.G(blankn ? {g,g,g} : "000"),
	.B(blankn ? {b,b,b} : "000"),
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
	.clk_sys        (clk_20         ),
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
	.msbi_g(15))
dac(
	.clk_i(clk_20),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
);
	
wire m_up     = btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = btn_right | joystick_0[0] | joystick_1[0];
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

always @(posedge clk_20) begin
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

module MoonWar_mist(
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
	"MWar;;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"T6,Reset;",
	"V,v1.20.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_10, clk_20;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_10),
	.c1(clk_20)
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
	.hyperflip(m_hyperflip),//Cocktail Only
	.coin1(btn_coin),
	.start1(btn_one_player),//not working- activate hyperflip maybe DIP Setting
	.start2(btn_two_players),
	.fire3(m_fire3),//mines
	.fire2(m_fire2),//thrust
	.fire1(m_fire1),//bolts
	.cleft(m_left),
	.cright(m_right),
	.ledr(),
	.dbg_cpu_di(),
	.dbg_cpu_addr(),
	.dbg_cpu_addr_latch()
);

mist_video #(.COLOR_DEPTH(1), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_20),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b1),
	.rotate({1'b1,status[2]}),
	.scandoubler_disable(scandoublerD),
	.blend(status[5]),
	.scanlines(status[4:3]),
	.ypbpr(ypbpr)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_10         ),
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


dac #(16) dac(
	.clk_i(clk_10),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
);
	
wire m_up     = btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = btn_right | joystick_0[0] | joystick_1[0];
wire m_fire1   = btn_fire1 | joystick_0[4] | joystick_1[4];//Bolts
wire m_fire2   = btn_fire2 | joystick_0[5] | joystick_1[5];//thrust
wire m_fire3   = btn_fire3 | joystick_0[6] | joystick_1[6];//mines
wire m_hyperflip   = btn_test | joystick_0[7] | joystick_1[7];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_test = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_fire3 = 0;
reg btn_coin  = 0;
wire       key_pressed;
wire [7:0] key_code;
wire       key_strobe;

always @(posedge clk_10) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        	<= key_pressed; // down
			'h6B: btn_left      		<= key_pressed; // left
			'h74: btn_right       	<= key_pressed; // right
			'h76: btn_coin				<= key_pressed; // ESC
			'h05: btn_test   	      <= key_pressed; // F3
			'h05: btn_one_player   	<= key_pressed; // F1
			'h06: btn_two_players  	<= key_pressed; // F2
			'h14: btn_fire3 			<= key_pressed; // ctrl
			'h11: btn_fire2 			<= key_pressed; // alt
			'h29: btn_fire1   		<=key_pressed; // Space
		endcase
	end
end

endmodule

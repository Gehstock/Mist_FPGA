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
	"GALAGA;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Flip screen,Off,On;",
	"O7,Self-test mode,Off,On;",
	"T1,Service trigger,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.21.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        flip      = status[6];
wire        selftest  = status[7];
wire        service   = status[1];

wire  [7:0] dipa      = ~status[15:8];
wire  [7:0] dipb      = ~status[23:16];

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_18;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_18)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_18         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.no_csync       (no_csync       ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_18       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [15:0] audio;
wire hs, vs;
wire blankn = ~(hb | vb);
wire hb, vb;
wire [2:0] r,g;
wire [1:0] b;
reg  service_trg;
reg  reset;

always @(posedge clk_18) begin
	reg serviceD;
	reg [19:0] service_cnt = 0;

	serviceD <= service;
	if (~serviceD & service) service_cnt <= 24'hFFFFF;
	else if (|service_cnt) service_cnt <= service_cnt - 1'd1;

	service_trg <= |service_cnt;

	reset <= status[0] | buttons[1] | ioctl_downl;
end

galaga galaga(
	.clock_18(clk_18),
	.reset(reset),
	.flip_screen(flip),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.blank_h(hb),
	.blank_v(vb),
	.video_hs(hs),
	.video_vs(vs),
	.audio(audio),
	.coin1(m_coin1),
	.start1(m_one_player),
	.left1(m_left),
	.right1(m_right),
	.fire1(m_fireA),
	.start2(m_two_players),
	.left2(m_left2),
	.right2(m_right2),
	.fire2(m_fire2A),

	.dip_switch_a(dipa),
	.dip_switch_b(dipb),

	.service(service_trg),
	.self_test(selftest),
	.pause(1'b0),

	.dn_addr(ioctl_addr),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr)
	);
	
mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_18),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? {b, b[1]} : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b1),
	.no_csync(no_csync),
	.blend(blend),
	.rotate({~flip,rotate}),
	.scanlines(scanlines),
	.scandoubler_disable(scandoublerD),
	.ypbpr(ypbpr)
	);

dac #(
	.C_bits(16))
dac(
	.clk_i(clk_18),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);


wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_18      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {~flip, 1'b1} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
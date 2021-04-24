module bagman_mist (
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
	input         CLOCK_27,
	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE

);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"BAGMAN;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.25.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];

wire        pickin = core_mod[1];
wire        sbagman = !pickin & core_mod[0]; // 1
wire        squash = pickin & core_mod[0]; // 3

wire  [7:0] dipsw = status[15:8];
wire  [7:0] player1 = ~{ m_fireA, squash ? dial1[1] : m_down, squash ? dial1[0] : m_up, m_right, m_left, (sbagman & m_fireB) | m_one_player, m_coin2, m_coin1 };
wire  [7:0] player2 = ~{ m_fire2A, squash ? dial2[1] : m_down2, squash ? dial2[0] : m_up2, m_right2, m_left2, (sbagman & m_fire2B) | m_two_players, m_coin4, m_coin3 };

assign 		LED = 1;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = clock_48;
assign      SDRAM_CKE = 1;

wire clock_48, clock_12, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_48),
	.c1(clock_12),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [6:0] core_mod;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire [12:0] audio;
wire        hs, vs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire [2:0] 	r, g;
wire [1:0] 	b;

wire [15:0] rom_addr;
wire [15:0] rom_do;
wire        rom_rd;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

data_io data_io(
	.clk_sys       ( clock_48     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

reg port1_req;

sdram #(.MHZ(48)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_48     ),

	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( { ioctl_dout, ioctl_dout } ),
	.port1_q       ( ),

	// CPU
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : { 2'b00, rom_addr[15:1] } ),
	.cpu1_q        ( rom_do )
);

always @(posedge clock_48) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) port1_req <= ~port1_req;
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

bagman bagman(
	.clock_12(clock_12),
	.reset(reset),
	.pickin(pickin),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hblank(hb),
	.video_vblank(vb),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),
	.player1(player1),
	.player2(player2),
	.dipsw(dipsw),
	.roms_addr ( rom_addr ),
	.roms_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.dl_clk(clock_48),
	.dl_addr(ioctl_addr[15:0]),
	.dl_we(ioctl_wr),
	.dl_data(ioctl_dout)
	);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,b[0]} : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( { !squash, rotate } ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clock_12       ),
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
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(.C_bits(16))dac(
	.clk_i(clock_12),
	.res_n_i(1),
	.dac_i({audio,4'b0}),
	.dac_o(AUDIO_L)
	);

// Squash spinners
reg [1:0] dial1, dial2;
reg [4:0] dial_cnt;

always @(posedge clock_12) begin
	dial_cnt <= dial_cnt + 1'd1;
	if (dial_cnt == 0) begin
		if (dial1 != 2'b11) dial1 <= 2'b11;
		else if (m_up)      dial1 <= 2'b10;
		else if (m_down)    dial1 <= 2'b01;
		else                dial1 <= 2'b11;

		if (dial2 != 2'b11) dial2 <= 2'b11;
		else if (m_down2)   dial2 <= 2'b10;
		else if (m_up2)     dial2 <= 2'b01;
		else                dial2 <= 2'b11;
	end
end

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_12    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( { 1'b1, !squash } ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( !squash     ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

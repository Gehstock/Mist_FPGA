module CClimber_mist (
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
	"CCLIMBER;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Swap joysticks,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.21.",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];
wire       joyswap = status[6];

reg  [7:0] p1, p2, dip, sys1, sys2;
reg  [1:0] orientation;

always @(*) begin
	p1 = 0;
	p2 = 0;
	dip = status[15:8];
	sys1 = 0;
	sys2 = 0;
	orientation = 2'b10;

	case(core_mod[2:0])
		3'b000: begin
			if (core_mod[4:3] == 2'b01) begin
				// CCLIMBER
				p1 = {m_right2 | m_rightB, m_left2 | m_leftB, m_down2 | m_downB, m_up2 | m_upB, m_right, m_left, m_down, m_up};
				p2 = p1;
				sys1 = {4'b0001, m_two_players, m_one_player, m_coin2, m_coin1};
			end else begin
				// RPATROL, SILVLAND
				p1 = {m_right, m_left, 5'b00000, m_fireA};
				p2 = {m_right2, m_left2, 5'b00000, m_fire2A};
				sys1 = {4'b1111, m_two_players, m_one_player, 1'b1, ~m_coin1};
			end
		end
		3'b001: begin
			// CKONG
			orientation = 2'b11;
			p1 = {m_right, m_left, m_down, m_up, m_fireA, 3'b000};
			p2 = {m_right2, m_left2, m_down2, m_up2, m_fire2A, 3'b000};
			sys1 = {4'b1111, ~m_two_players, ~m_one_player, ~m_coin2, ~m_coin1};
		end
		3'b010: begin
			// YAMATO
			orientation = 2'b11;
			p1 = {m_right, m_left, m_down, m_up, m_fireB, m_fireA, 2'b00};
			p2 = {m_right2, m_left2, m_down2, m_up2, m_fire2B, m_fire2A, 2'b00};
			sys1 = {3'b000, m_coin3, 2'b00, m_coin1, m_coin2};
			sys2 = {4'b0000, m_two_players, m_one_player, 2'b00};
		end
		3'b011: begin
			p2 = {3'b000, m_fireA, m_down, m_up, m_left, m_right};
			p1 = {3'b000, m_fire2A, m_down2, m_up2, m_left2, m_right2};
			if (core_mod[5]) begin
				// GUZZLER
				orientation = 2'b11;
				sys1 = {status[23:20], 4'h0};
				sys2 = {4'h0, m_two_players, m_one_player, m_coin2, m_coin1};
			end else begin
				// SWIMMER
				sys1 = {status[23:19], m_one_player, m_two_players, 1'b0};
				sys2 = {6'd0, m_coin2, m_coin1};
			end
		end
		default: ;
	endcase
end

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire pll_locked, clock_24, clock_12;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_24),
	.c1(clock_12),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
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

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clock_24     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

reg        port1_req;
reg [15:0] rom_dout;
reg [15:0] rom_addr;

assign     SDRAM_CLK = clock_24;
assign     SDRAM_CKE = 1;

sdram #(.MHZ(24)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_24     ),

	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[22:1] ),
	.port1_ds      ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),

	// CPU
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : { 1'b0, rom_addr[15], 1'b0, rom_addr[14:1] } ),
	.cpu1_q        ( rom_dout  )
);

always @(posedge clock_24) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end
end

// reset generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_12) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded | ioctl_downl;
end
	
wire [15:0] audio;
wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
wire [3:0] r, g, b;

crazy_climber crazy_climber (
	.hwsel(core_mod[4:0]),
	.clock_12(clock_12),
	.reset(reset),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hblank(hb),
	.video_vblank(vb),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),

	.p1(p1),
	.p2(p2),
	.sys1(sys1),
	.sys2(sys2),
	.dip(dip),

	.rom_addr(rom_addr),
	.rom_do(rom_addr[0] ? rom_dout[15:8] : rom_dout[7:0]),

	.dl_clock(clock_24),
	.dl_addr(ioctl_addr - 16'h8000),
	.dl_wr(ioctl_wr),
	.dl_data(ioctl_dout)
	);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clock_24),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b1),
	.rotate({orientation[1],rotate}),
	.blend(blend),
	.scanlines(scanlines),
	.scandoubler_disable(scandoublerD),
	.ypbpr(ypbpr),
	.no_csync(no_csync)
	);

dac #(
	.C_bits(16))
dac(
	.clk_i(clock_12),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

// Common inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_upB, m_downB, m_leftB, m_rightB;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F, m_up4B, m_down4B, m_left4B, m_right4B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_12    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_upB, m_downB, m_leftB, m_rightB, 6'd0, m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, 6'd0, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, 6'd0, m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, 6'd0, m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule

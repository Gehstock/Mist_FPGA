module dkong_MiST(
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
	"DKONG;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];

wire        landscape = core_mod[3];

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = clock_24;
assign 		SDRAM_CKE = 1;

wire pll_locked,clock_24;
pll pll(
	.locked(pll_locked),
	.inclk0(CLOCK_27),
	.c0(clock_24)//W_CLK_24576M
	);

wire [15:0] main_rom_a;
wire [15:0] main_rom_do;
wire [11:0] sub_rom_a;
wire [15:0] sub_rom_do;
wire [18:0] wav_rom_a;
wire [15:0] wav_rom_do;

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

reg port1_req, port2_req;
sdram #(24) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_24     ),

	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b00, main_rom_a[14:1]} ),
	.cpu1_q        ( main_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : sub_rom_a[11:1] + 16'h7000 ),
	.cpu2_q        ( sub_rom_do ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.wav_addr       ( ioctl_downl ? 18'h3ffff : wav_rom_a[18:1]),
	.wav_q          ( wav_rom_do )
);

// ROM download controller
always @(posedge clock_24) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_24) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire  [7:0] audio;
wire        hs_n, vs_n;
wire        hb, vb;
wire        blankn = ~vb;//~(hb | vb);
wire [3:0] 	r, g, b;
	
dkong_top dkong(				   
	.I_CLK_24576M(clock_24),
	.I_RESETn(~reset),
	.I_U1(~m_up),
	.I_D1(~m_down),
	.I_L1(~m_left),
	.I_R1(~m_right),
	.I_J1(~m_fireA),
	.I_U2(~m_up2),
	.I_D2(~m_down2),
	.I_L2(~m_left2),
	.I_R2(~m_right2),
	.I_J2(~m_fire2A),
	.I_S1(~m_one_player),
	.I_S2(~m_two_players),
	.I_C1(~m_coin1),
	.I_DIP_SW(status[15:8]),
	.I_DKJR(core_mod[0]),
	.I_DK3B(core_mod[1]),
	.I_RADARSCP(core_mod[2]),
	.I_PESTPLCE(core_mod[3]),
	.O_SOUND_DAT(audio),
	.O_VGA_R(r),
	.O_VGA_G(g),
	.O_VGA_B(b),
	.O_H_BLANK(hb),
	.O_V_BLANK(vb),
	.O_VGA_H_SYNCn(hs_n),
	.O_VGA_V_SYNCn(vs_n),

	.DL_ADDR(ioctl_addr[15:0]),
	.DL_WR(ioctl_wr && ioctl_addr[23:16] == 0),
	.DL_DATA(ioctl_dout),
	.MAIN_CPU_A(main_rom_a),
	.MAIN_CPU_DO(main_rom_a[0] ? main_rom_do[15:8] : main_rom_do[7:0]),
	.SND_ROM_A(sub_rom_a),
	.SND_ROM_DO(sub_rom_a[0] ? sub_rom_do[15:8] : sub_rom_do[7:0]),
	.WAV_ROM_A(wav_rom_a),
	.WAV_ROM_DO(wav_rom_a[0] ? wav_rom_do[15:8] : wav_rom_do[7:0])
	);

mist_video #(.COLOR_DEPTH(4),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clock_24),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(hs_n),
	.VSync(vs_n),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b1,rotate}),
	.ce_divider(1'b1),
	.blend(blend),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ypbpr(ypbpr),
	.no_csync(no_csync)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clock_24       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD),
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

dac #(
	.C_bits(8))
dac(
	.clk_i(clock_24),
	.res_n_i(1'b1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

// General controls
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_24    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {1'b1, ~landscape} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

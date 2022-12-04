
module Zaxxon_MiST(
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

`include "rtl/build_id.v" 

localparam CONF_STR = {
	"ZAXXON;;",
	"O2,Rotate Controls,Off,On;",
	"O1,Pause,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Flip,Off,On;",
	"O7,Service,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v2.0.",`BUILD_DATE
};

wire           pause = status[1];
wire          rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire           blend = status[5];
wire           flip  = status[6];
wire        service  = status[7];

wire [7:0]       sw1 = status[23:16];
wire [7:0]       sw2 = status[31:24];

reg  [7:0] p1_input, p2_input;

always @(*) begin
	case (core_mod)
	7'h22: // FUTSPY 
	begin
		p1_input = {2'b00, m_fireB, m_fireA, m_down, m_up, m_left, m_right};
		p2_input = {2'b00, m_fire2B, m_fire2A, m_down2, m_up2, m_left2, m_right2};
	end

	default: // ZAXXON, SZAXXON
	begin
		p1_input = {3'b000, m_fireA, m_down, m_up, m_left, m_right};
		p2_input = {3'b000, m_fire2A, m_down2, m_up2, m_left2, m_right2};
	end
	endcase

end

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_sd;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_sd;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_sd),//48
	.c1(clk_sys),//24
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        key_pressed;
wire        key_strobe;
wire  [7:0] key_code;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;

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
	.status         (status         ),
	.core_mod       (core_mod       )
	);

wire [15:0] audio_l;
wire        hs, vs, cs, hb, vb;
wire        blankn = ~(hb | vb);
wire  [2:0] g, r;
wire  [1:0] b;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire [12:0] bg_addr;
wire [31:0] bg_do;
wire [13:0] sp_addr;
wire [31:0] sp_do;
wire [19:0] wave_addr;
wire [15:0] wave_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

// ROM structure
// 00000-06FFF CPU ROM   28k  u27-u28-u29-(u29-u29)
// 07000-0EFFF Tiledata  32k  u91-u90-u93-u92
// 0F000-0F7FF char1      2k  u68
// 0F800-0FFFF char2      2k  u69
// 10000-17FFF bg        32k  u113-u112-u111-(u111)
// 18000-27FFF spr       64k  u77-u78-u79-(u79)
// 28000-280FF          256b  u76
// 28100-281FF          256b  u72

data_io data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [24:0] gfx_ioctl_addr = ioctl_addr - 17'h10000;

reg port1_req, port2_req;
sdram #(48) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sd       ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 19'h7ffff : {5'd0, rom_addr[14:1]}),
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( wave_addr[19:1] + 17'h13100 ),
	.cpu2_q        ( wave_do ),

	// port2 for gfx
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( gfx_ioctl_addr[23:1] ),
	.port2_ds      ( {gfx_ioctl_addr[0], ~gfx_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.bg_addr       ( bg_addr ),
	.bg_q          ( bg_do ),
	.sp_addr       ( sp_addr + 16'h2000),
	.sp_q          ( sp_do )
);

always @(posedge clk_sys) begin
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
always @(posedge clk_sd) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire dl_wr = ioctl_wr && ioctl_addr < 18'h28200;

zaxxon zaxxon(
	.clock_24(clk_sys),
	.reset(reset),
	.pause(pause),

	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hblank(hb),
	.video_vblank(vb),
	.video_hs(hs),
	.video_vs(vs),
	.video_csync(cs),

	.audio_out_l(audio_l),

	.hwsel(core_mod[1]),
	.coin1(m_coin1),
	.coin2(m_coin2),
	.start2(m_two_players),
	.start1(m_one_player),
	.p1_input(p1_input),
	.p2_input(p2_input),
	.service(service),

	.sw1_input(sw1), // cocktail(1) / sound(1) / ships(2) / N.U.(2) /  extra ship (2)
	.sw2_input(sw2), // coin b(4) / coin a(4)  -- "3" => 1c_1c

	.flip_screen(flip),

	.enc_type     ( core_mod[6:4]) ,
	.cpu_rom_addr ( rom_addr  ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.wave_addr    ( wave_addr ),
	.wave_data    ( wave_do   ),

	.bg_graphics_addr( bg_addr ),
	.bg_graphics_do  ( bg_do   ),
	.sp_graphics_addr( sp_addr ),
	.sp_graphics_do  ( sp_do   ),

	.dl_addr      ( ioctl_addr[17:0] ),
	.dl_data      ( ioctl_dout ),
	.dl_wr        ( dl_wr )
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,b[1]} : 0 ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	.rotate         ( {flip, rotate}   ),
	.scandoubler_disable(scandoublerD  ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

dac #(
	.C_bits(16))
dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
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
	.rotate      ( rotate      ),
	.orientation ( {flip, 1'b1} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

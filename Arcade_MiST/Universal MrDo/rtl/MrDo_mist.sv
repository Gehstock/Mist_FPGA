module MrDo_mist (
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
	"MRDO;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"O6,Flip,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        user_flip = status[6];

wire  [7:0] dsw1 = status[15:8];
wire  [7:0] dsw2 = status[23:16];

assign 		LED = ~ioctl_downl;
assign 		SDRAM_CLK = mem_clk;
assign      SDRAM_CKE = 1;

wire mem_clk, sys_clk, pll_locked;

pll pll(
	.inclk0(CLOCK_27),
	.c0(mem_clk),
	.c1(sys_clk),
	.locked(pll_locked)
);
	
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire [7:0]  audio1, audio2;
wire        hs, vs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire [3:0] 	r, g, b;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

data_io data_io(
	.clk_sys       ( sys_clk     ),
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

sdram #(.MHZ(40)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( mem_clk      ),

	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( { ioctl_dout, ioctl_dout } ),
	.port1_q       ( ),

	// CPU
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : { 3'b000, rom_addr[14:1] } ),
	.cpu1_q        ( rom_do )
);

always @(posedge sys_clk) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) port1_req <= ~port1_req;
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge sys_clk) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

MrDo_top MrDo_top(
	.clk_20M(sys_clk),
	.reset(reset),
	.user_flip(user_flip),
	.red(r),
	.green(g),
	.blue(b),
	.hsync(hs),
	.vsync(vs),
	.hblank(hb),
	.vblank(vb),
	.sound1_out(audio1),
	.sound2_out(audio2),
	.p1(~{ 1'b0, m_two_players, m_one_player, m_fireA, m_up, m_right, m_down, m_left }),
	.p2(~{ m_coin1, 1'b0, 1'b0, m_fire2A, m_up2, m_right2, m_down2, m_left2 }),
	.dsw1(dsw1),
	.dsw2(dsw2),
	.rom_addr ( rom_addr ),
	.rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
    .dl_addr(ioctl_addr[15:0]),
    .dl_data(ioctl_dout),
    .dl_we(ioctl_wr)
);


mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( sys_clk         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b1             ),
	.rotate         ( { user_flip, rotate } ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (sys_clk       ),
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

dac #(.C_bits(16))dacl(
	.clk_i(sys_clk),
	.res_n_i(1),
	.dac_i({audio1, audio1}),
	.dac_o(AUDIO_L)
	);

dac #(.C_bits(16))dacr(
	.clk_i(sys_clk),
	.res_n_i(1),
	.dac_i({audio2, audio2}),
	.dac_o(AUDIO_R)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( sys_clk     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {user_flip, 1'b1} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

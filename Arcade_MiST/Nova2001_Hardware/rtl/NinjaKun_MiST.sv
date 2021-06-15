module NinjaKun_MiST (
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
`include "rtl/defs.v"

localparam CONF_STR = {
	"NINJAKUN;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"O6,Service,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = CLOCK_96;
assign 		SDRAM_CKE = 1;

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        service = status[6];

wire  [6:0] core_mod;
wire  [1:0] hwtype = core_mod[1:0];

reg   [7:0] CTR1, CTR2, CTR3;

always @(*) begin
	CTR1 = ~{2'b11, m_one_player, 1'b0, m_fireA, m_fireB, m_right, m_left };
	CTR2 = ~{~(m_coin1 | m_coin2), ~service, m_two_players, 1'b0, m_fire2A, m_fire2B, m_right2, m_left2 };
	CTR3 = 0;
	if (hwtype == `HW_RAIDERS5) begin
		CTR1 = ~{1'b0, 1'b0, m_one_player, m_fireA, m_up, m_down, m_right, m_left };
		CTR2 = ~{(m_coin1 | m_coin2), service, m_two_players, m_fire2A, m_up2, m_down2, m_right2, m_left2};
	end else if (hwtype == `HW_NOVA2001) begin
		CTR1 = ~{m_fireA, m_fireB, 2'b00, m_right, m_left, m_down, m_up};
		CTR2 = ~{m_fire2A, m_fire2B, 2'b00, m_right2, m_left2, m_down2, m_up2};
		CTR3 = ~{5'b00000, m_two_players, m_one_player, m_coin1 | m_coin2};
	end else if (hwtype == `HW_PKUNWAR) begin
		CTR1 = ~{2'b00, m_one_player, 2'b00, m_fireA, m_right, m_left };
		CTR2 = ~{(m_coin1 | m_coin2), service, m_two_players, 2'b00, m_fire2A, m_right2, m_left2 };
	end
end

wire CLOCK_96, CLOCK_48, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(CLOCK_96),
	.c1(CLOCK_48),
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
wire [15:0] audio;
wire        hs, vs;
wire [3:0] 	r, g, b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

/*
ROM Structure (same as the original)
fg gfx 32k ninja-6.7n ninja-7.7p ninja-8.7s ninja-9.7t
bg gfx 32k ninja-10.2c ninja-11.2d ninja-12.4c ninja-13.4d
cpu1   32k ninja-1.7a ninja-2.7b ninja-3.7d ninja-4.7e 
cpu2   32k ninja-5.7h ninja-2.7b ninja-3.7d ninja-4.7e
*/

data_io data_io(
	.clk_sys       ( CLOCK_48     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [24:0] cpu_ioctl_addr = ioctl_addr - 17'h10000;
reg         port1_req, port2_req;

wire [15:0] cpu1_rom_addr, cpu2_rom_addr;
wire [15:0] cpu1_rom_do, cpu2_rom_do;
wire [13:0] sp_rom_addr;
wire [31:0] sp_rom_do;
wire        sp_rdy;
wire [12:0] fg_rom_addr;
wire [31:0] fg_rom_do;
wire [13:0] bg_rom_addr;
wire [31:0] bg_rom_do;

sdram #(96) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( CLOCK_96     ),

	// port1 used for main + aux CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( cpu_ioctl_addr[23:1] ),
	.port1_ds      ( {cpu_ioctl_addr[0], ~cpu_ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, cpu1_rom_addr[15:1]} ),
	.cpu1_q        ( cpu1_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : {2'b01, cpu2_rom_addr[14:1]} ),
	.cpu2_q        ( cpu2_rom_do ),

	// port2 for graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {ioctl_addr[23:15], ioctl_addr[14], ioctl_addr[12:0]} ),
	.port2_ds      ( {ioctl_addr[13], ~ioctl_addr[13]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.fg_addr       ( ioctl_downl ? 15'h7fff : {1'b0, fg_rom_addr} ),
	.fg_q          ( fg_rom_do ),
	.sp_addr       ( ioctl_downl ? 15'h7fff : sp_rom_addr ),
	.sp_q          ( sp_rom_do ),
	.sp_rdy        ( sp_rdy ),
	.bg_addr       ( ioctl_downl ? 15'h7fff : bg_rom_addr ),
	.bg_q          ( bg_rom_do )
);

// ROM download controller
always @(posedge CLOCK_48) begin
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
always @(posedge CLOCK_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire        PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;

ninjakun_top ninjakun_top(
	.RESET(reset),
	.MCLK(CLOCK_48),
	.HWTYPE(hwtype),
	.CTR1(CTR1),
	.CTR2(CTR2),
	.CTR3(CTR3),
	.DSW1(status[15:8]),
	.DSW2({(hwtype == `HW_NOVA2001 ? ~service : status[23]), status[22:16]}),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK_EN(PCLK_EN),
	.POUT(oPIX),
	.SNDOUT(audio),
	.CPU1ADDR(cpu1_rom_addr),
	.CPU1DT(cpu1_rom_addr[0] ? cpu1_rom_do[15:8] : cpu1_rom_do[7:0]),
	.CPU2ADDR(cpu2_rom_addr),
	.CPU2DT(cpu2_rom_addr[0] ? cpu2_rom_do[15:8] : cpu2_rom_do[7:0]),
	.sp_rom_addr(sp_rom_addr),
	.sp_rom_data(sp_rom_do),
	.sp_rdy(sp_rdy),
	.fg_rom_addr(fg_rom_addr),
	.fg_rom_data(fg_rom_do),
	.bg_rom_addr(bg_rom_addr),
	.bg_rom_data(bg_rom_do),
	.PALADR(ioctl_addr[4:0]),
	.PALWR(ioctl_addr[23:5] == {16'h0180, 3'b000} && ioctl_wr),
	.PALDAT(ioctl_dout)

);

wire  [7:0] oPIX;
assign		POUT = {{oPIX[7:6],oPIX[1:0]},{oPIX[5:4],oPIX[1:0]},{oPIX[3:2],oPIX[1:0]}};

hvgen hvgen(
	.CLK(CLOCK_48),
	.PCLK_EN(PCLK_EN),
	.HPOS(HPOS),
	.VPOS(VPOS),
	.iRGB(POUT),
	.oRGB({b,g,r}),
	.HSYN(hs),
	.VSYN(vs)
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( CLOCK_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( { 1'b1, rotate } ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (CLOCK_48       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.core_mod       (core_mod       ),
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

dac #(.C_bits(16))dac(
	.clk_i(CLOCK_48),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( CLOCK_48    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b10       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

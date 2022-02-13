module TheTowerofDruaga_mist (
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

`define CORE_NAME "DRUAGA"
wire  [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME, ";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O7,Flip Screen,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        flip      = status[7];

reg   [7:0] DSW0;
reg   [7:0] DSW1;
reg   [7:0] DSW2;

reg   [5:0] INP0;
reg   [5:0] INP1;
reg   [2:0] INP2;

always @(*) begin
	INP0 = { m_fireB, m_fireA, m_left, m_down, m_right, m_up};
	INP1 = { m_fire2B, m_fire2A, m_left2, m_down2, m_right2, m_up2 };
	INP2 = { m_coin1 | m_coin2, m_two_players, m_one_player };
	DSW0 = 0;
	DSW1 = 0;
	DSW2 = 0;

	case (core_mod)
	7'h0, 7'h1, 7'h3: // DRUAGA, DIGDUG2
	begin
		DSW0 = status[15:8];
		DSW1 = status[23:16];
		DSW2 = { status[19:16], status[27:24] };
	end
	7'h2: // MAPPY
	begin
		DSW0 = status[15:8];
		DSW1 = status[23:16];
		DSW2 = { {2{status[27:24]}} };
	end
	7'h6: // GROBDA
	begin
		DSW0 = status[15:8];
		DSW1 = {status[23:22], m_fire2B, m_fireB, status[19:16]};
		DSW2 = status[31:24];
	end

	default:
	begin
		DSW0 = status[15:8];
		DSW1 = status[23:16];
		DSW2 = status[31:24];
	end

	endcase
end

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = clock_48;
assign    SDRAM_CKE = 1;

wire clock_48, clock_6, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_48),//49.147727
	.c1(clock_6),
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
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(.STRLEN($size(CONF_STR)>>3))user_io(
	.clk_sys        (clock_48       ),
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

/*
ROM map
00000-07FFF   cpu0     32k 3.1d+1.1b (+2.1c in Mappy)
08000-0BFFF   spchip0  16k 6.3m
0C000-0FFFF   spchip1  16k 7.3m
10000-11FFF   cpu1      8k 4.1k
12000-12FFF   bgchip    4k 5.3b
13000-133FF   spclut    1k 7.5k
13400-134FF   bgclut  256b 6.4c
13500-135FF   wave    256b 3.3m
13600-1361F   palet    32b 5.5b
*/

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

reg port1_req, port2_req;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire [12:0] snd_addr;
wire [15:0] snd_do;

sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_48     ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : {1'b0, rom_addr[14:1]} ),
	.cpu1_q        ( rom_do ),

	// port2 for sound CPU
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h8000 ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.snd_addr      ( ioctl_downl ? 15'h7fff : {3'b000, snd_addr[12:1]} ),
	.snd_q         ( snd_do )
);

always @(posedge clock_48) begin
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
always @(posedge clock_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded;
end

wire			PCLK, PCLK_EN;
wire  [8:0] HPOS,VPOS;

wire  [7:0] audio;
wire        hs, vs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire [2:0] 	r, g;
wire [1:0] 	b;

fpga_druaga fpga_druaga(
	.MCLK(clock_48),
	.CLKCPUx2(clock_6),
	.RESET(reset),
	.SOUT(audio),
	.rom_addr(rom_addr),
	.rom_data(rom_addr[0] ? rom_do[15:8] : rom_do[7:0]),
	.snd_addr(snd_addr),
	.snd_data(snd_addr[0] ? snd_do[15:8] : snd_do[7:0]),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK(PCLK),
	.PCLK_EN(PCLK_EN),
	.POUT({b,g,r}),
	.INP0(INP0),
	.INP1(INP1),
	.INP2(INP2),
	.DSW0(DSW0),
	.DSW1(DSW1),
	.DSW2(DSW2),

	.ROMAD(ioctl_addr[16:0]),
	.ROMDT(ioctl_dout),
	.ROMEN(ioctl_wr),
	.MODEL(core_mod[2:0]),
	.FLIP_SCREEN(flip)
	);

hvgen hvgen(
	.MCLK(clock_48),
	.HPOS(HPOS),
	.VPOS(VPOS),
	.PCLK(PCLK),
	.PCLK_EN(PCLK_EN),
	.HBLK(hb),
	.VBLK(vb),
	.HSYN(hs),
	.VSYN(vs)
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,b[1]} : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( { ~flip, rotate } ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            )
	);

dac #(.C_bits(16))dac(
	.clk_i(clock_48),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_48    ),
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

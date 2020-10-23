
module Segasys1_MiST(
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

`define CORE_NAME "FLICKY"
localparam CONF_STR = {
	`CORE_NAME,";ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];

wire  [7:0] INP0 = ~{m_left, m_right,m_up, m_down,1'b0,m_fireB,m_fireA,m_fireC};
wire  [7:0] INP1 = ~{m_left2,m_right2,m_up2, m_down2,1'b0,m_fire2B,m_fire2A,m_fire2C};
wire  [7:0] INP2 = ~{2'b00,m_two_players, m_one_player,3'b000, m_coin1};
wire  [7:0] DSW0 = status[15: 8];
wire  [7:0] DSW1 = status[23:16];

wire  [6:0] core_mod;  // [0]=SYS1/SYS2,[1]=H/V,[2]=H256/H240
wire  [1:0] orientation = { 1'b0, core_mod[1] };

assign LED = ~ioctl_downl;
assign SDRAM_CLK = sdram_clk;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, sdram_clk;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_sys),//48
	.c1(sdram_clk),//96
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
	.scandoubler_disable (scandoublerD ),
	.ypbpr          (ypbpr          ),
	.core_mod       (core_mod       ),
	.no_csync       (no_csync       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire [15:0] audio;
wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [15:0] spr_rom_addr;
wire [15:0] spr_rom_do;
wire [12:0] snd_rom_addr;
wire [15:0] snd_rom_do;
wire [13:0] tile_rom_addr;
wire [23:0] tile_rom_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

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

reg port1_req, port2_req;
wire [24:0] tl_ioctl_addr = ioctl_addr - 18'h20000;
sdram #(96) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( sdram_clk    ),

	// port1 used for main + sound CPUs
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, rom_addr[15:1]}), // offset 0
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : (16'h6000 + snd_rom_addr[12:1]) ), // offset c000
	.cpu2_q        ( snd_rom_do ),
	.cpu3_addr     ( ioctl_downl ? 16'hffff : (16'h8000 + spr_rom_addr[15:1]) ), // offset 10000
	.cpu3_q        ( spr_rom_do ),

	// port2 for backround tiles
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( tl_ioctl_addr[23:1] ),
	.port2_ds      ( {tl_ioctl_addr[0], ~tl_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 15'h7fff : tile_rom_addr ),
	.sp_q          ( tile_rom_do )
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
always @(posedge sdram_clk) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

SEGASYSTEM1 System1_Top(
	.clk48M(clk_sys),
	.reset(reset),

	.INP0(INP0),
	.INP1(INP1),
	.INP2(INP2),

	.DSW0(DSW0),
	.DSW1(DSW1),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK_EN(PCLK_EN),
	.POUT(POUT),

	.cpu_rom_addr(rom_addr),
	.cpu_rom_do( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),

	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_addr[0] ? snd_rom_do[15:8] : snd_rom_do[7:0] ),

	.spr_rom_addr(spr_rom_addr),
	.spr_rom_do(spr_rom_addr[0] ? spr_rom_do[15:8] : spr_rom_do[7:0] ),

	.tile_rom_addr(tile_rom_addr),
	.tile_rom_do(tile_rom_do),

	.ROMCL(clk_sys),
	.ROMAD(ioctl_addr[17:0]),
	.ROMDT( ioctl_dout ),
	.ROMEN( ioctl_wr ),
	.SOUT(audio)
);

wire        PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire  [7:0] POUT;
wire  [7:0] HOFFS = 8'd16;
wire  [7:0] VOFFS = 0;
wire        hs, vs;
wire  [2:0] g, r;
wire  [1:0] b;

HVGEN hvgen
(
	.HPOS(HPOS),.VPOS(VPOS),.CLK(clk_sys),.PCLK_EN(PCLK_EN),.iRGB(POUT),
	.oRGB({b,g,r}),.HBLK(),.VBLK(),.HSYN(hs),.VSYN(vs),
	.H240(core_mod[2]),.HOFFS(HOFFS),.VOFFS(VOFFS)
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( {b, b[1]}        ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b0             ),
	.blend          ( blend            ),
	.rotate         ( {1'b0, rotate}   ),
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
	.dac_i(audio),
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
	.orientation ( orientation ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

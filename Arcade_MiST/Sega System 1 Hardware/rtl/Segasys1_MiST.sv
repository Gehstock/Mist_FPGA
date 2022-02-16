
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

reg   [7:0] INP0, INP1, INP2;
always @(*) begin
	INP0 = ~{m_left, m_right,m_up, m_down,1'b0,m_fireB,m_fireA,m_fireC};
	INP1 = ~{m_left2,m_right2,m_up2, m_down2,1'b0,m_fire2B,m_fire2A,m_fire2C};
	INP2 = ~{2'b00,m_two_players, m_one_player,3'b000, m_coin1};
	if (core_mod[5]) begin
		// Block Gal
		INP0 = ~spin[8:1];
		INP1 = ~spin[8:1];
		INP2 = ~{m_fire2A | |mouse_flags[2:0], m_fireA | |mouse_flags[2:0], m_two_players, m_one_player, 2'b00, m_coin2, m_coin1};
	end else
	if (core_mod[3]) begin
		//WaterMatch
		INP0 = ~{m_left, m_right, m_up, m_down, m_left2,m_right2,m_up2,m_down2};
		INP1 = ~{m_left3,m_right3,m_up3,m_down3,m_left4,m_right4,m_up4,m_down4};
		INP2 = ~{m_fire3A | m_fire4A,m_fireA | m_fire2A,m_two_players, m_one_player,3'b000, m_coin1};
	end
end

wire signed [8:0] spin;
wire signed [8:0] spin_next = spin + mouse_x;
always @(posedge clk_sys) begin
	if (mouse_strobe) begin
		if (spin[8] != mouse_x[8] || spin[8] == spin_next[8])
			spin <= spin_next;
		else
			spin <= {spin[8], {8{~spin[8]}}};
	end
end

wire  [7:0] DSW0 = status[15: 8];
wire  [7:0] DSW1 = status[23:16];

wire  [6:0] core_mod;  // [0]=SYS1/SYS2,[1]=H/V,[2]=H256/H240,[3]=4controllers,[4]=CW/CCW,[5]=spinner,[6]=SYS2 rowscroll,
wire  [1:0] orientation = { core_mod[4], core_mod[1] };

assign LED = ~ioctl_downl;
assign SDRAM_CLK = sdram_clk;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, sdram_clk;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(sdram_clk),//80
	.c1(clk_sys),//40
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire  [7:0] joystick_2;
wire  [7:0] joystick_3;
wire        key_pressed;
wire        key_strobe;
wire  [7:0] key_code;
wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire  [7:0] mouse_flags;
wire        mouse_strobe;
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
	.mouse_strobe   (mouse_strobe   ),
	.mouse_x        (mouse_x        ),
	.mouse_y        (mouse_y        ),
	.mouse_flags    (mouse_flags    ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire [15:0] audio;
wire [16:0] cpu_rom_addr;
wire [15:0] cpu_rom_do;
wire [16:0] spr_rom_addr;
wire [15:0] spr_rom_do;
wire [14:0] snd_rom_addr;
wire [15:0] snd_rom_do;
wire [15:0] tile_rom_addr;
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
wire [24:0] tl_ioctl_addr = ioctl_addr - 20'h40000;
sdram #(80) sdram(
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

	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : (17'h4000 + cpu_rom_addr[16:1]) ), // offset 8000h
	.cpu1_q        ( cpu_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 17'h1ffff : snd_rom_addr[14:1] ), // offset 0
	.cpu2_q        ( snd_rom_do ),
	.cpu3_addr     ( ioctl_downl ? 17'h1ffff : (17'h10000 + spr_rom_addr[16:1]) ), // offset 20000h
	.cpu3_q        ( spr_rom_do ),

	// port2 for backround tiles
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( tl_ioctl_addr[23:1] ),
	.port2_ds      ( {tl_ioctl_addr[0], ~tl_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 16'hffff : tile_rom_addr ),
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
	.clk40M(clk_sys),
	.reset(reset),

	.INP0(INP0),
	.INP1(INP1),
	.INP2(INP2),

	.DSW0(DSW0),
	.DSW1(DSW1),

	.SYSTEM2(core_mod[0]),
	.SYSTEM2_ROWSCROLL(core_mod[6]),

	.PH(HPOS),
	.PV(VPOS),
	.PCLK_EN(PCLK_EN),
	.POUT(POUT),

	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_addr[0] ? cpu_rom_do[15:8] : cpu_rom_do[7:0] ),

	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_addr[0] ? snd_rom_do[15:8] : snd_rom_do[7:0] ),

	.spr_rom_addr(spr_rom_addr),
	.spr_rom_do(spr_rom_addr[0] ? spr_rom_do[15:8] : spr_rom_do[7:0] ),

	.tile_rom_addr(tile_rom_addr),
	.tile_rom_do(tile_rom_do),

	.ROMCL(clk_sys),
	.ROMAD(ioctl_addr),
	.ROMDT(ioctl_dout),
	.ROMEN(ioctl_wr),
	.SOUT(audio)
);

wire        PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;
wire  [7:0] HOFFS = 8'd2;
wire  [7:0] VOFFS = 8'd2;
wire        hs, vs;
wire  [3:0] b, g, r;

HVGEN hvgen
(
	.HPOS(HPOS),.VPOS(VPOS),.CLK(clk_sys),.PCLK_EN(PCLK_EN),.iRGB(POUT),
	.oRGB({b,g,r}),.HBLK(),.VBLK(),.HSYN(hs),.VSYN(vs),
	.H240(core_mod[2]),.HOFFS(HOFFS),.VOFFS(VOFFS)
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
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
	.ce_divider     ( 1'b0             ),
	.blend          ( blend            ),
	.rotate         ( {core_mod[4], rotate}   ),
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

wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F;

wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joystick_2  ( joystick_2  ),
	.joystick_3  ( joystick_3  ),	
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( ~core_mod[3]),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 

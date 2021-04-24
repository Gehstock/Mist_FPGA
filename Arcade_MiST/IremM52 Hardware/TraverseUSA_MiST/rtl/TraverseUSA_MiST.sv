//============================================================================
//  Arcade: TraverseUSA, ShotRider
//
//  DarFPGA's core ported to MiST by (C) 2019 Szombathelyi György
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module TraverseUSA_MiST(
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

`define CORE_NAME "TRAVRUSA"
wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O1,Video Timing,Original,Pal 50Hz;",
	"OA,Blending,Off,On;",
	"O5,Units,MP,Km;",
	"O6,Freeze,Disable,Enable;",
	"O7,Game name,Traverse USA,Zippyrace;",
	"O8,Demo mode,Off,On;",
	"O9,Test mode,Off,On;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[10];
wire       pal = status[1];

reg        shtrider = 0;
wire [7:0] dip1 = 8'hff;
reg  [7:0] dip2;

always @(*) begin
	if (core_mod == 7'h1) begin
		shtrider = 1;
		// Cocktail(3) / M-Km(1) / Flip(0)
		dip2 = { 4'b1111, 2'b11, status[5], 1'b0 };
	end else begin
		shtrider = 0;
		// Diag(7) / Demo(6) / Zippy(5) / Freeze (4) / M-Km(3) / Coin mode (2) / Cocktail(1) / Flip(0)
		dip2 = { ~status[9], ~status[8], ~status[7], ~status[6], ~status[5], 3'b110 };
	end
end

assign LED = 1;
assign AUDIO_R = AUDIO_L;
assign SDRAM_CLK = clk_sys;
assign SDRAM_CKE = 1;

wire clk_sys, clk_aud, clk_dac;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
	);

pll_aud pll_aud(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_aud),
	.c1(clk_dac)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

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
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);
	
wire [14:0] cart_addr;
wire [15:0] sdram_do;
wire        cart_rd;
wire [12:0] snd_addr, snd_rom_addr;
wire [15:0] snd_do;
wire        snd_vma, snd_vma_r, snd_vma_r2;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

/* ROM structure
00000-07FFF CPU ROM  32k zr1-0.m3 zr1-5.l3 zr1-6a.k3 zr1-7.j3
08000-09FFF SND ROM   8k mr10.1a mr10.1a
0A000-0FFFF GFX1     24k zippyrac.001 mr8.3c mr9.3a
10000-15FFF GFX2     24k zr1-8.n3 zr1-9.l3 zr1-10.k3
16000-161FF CHR PAL 512b mmi6349.ij
16200-162FF SPR PAL 256b tbp24s10.3
16300-1631F SPR LUT  32b tbp18s.2
*/
data_io data_io (
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
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sys      ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : {1'b0, cart_addr[14:1]} ),
	.cpu1_q        ( sdram_do ),
 
	// port2 for sound board
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h4000 ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.snd_addr      ( ioctl_downl ? 15'h7fff : {3'b000, snd_addr[12:1]} ),
	.snd_q         ( snd_do )
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

	// async clock domain crossing here (clk_aud -> clk_sys)
	snd_vma_r <= snd_vma;
	snd_vma_r2 <= snd_vma_r;
	if (snd_vma_r2) snd_addr <= snd_rom_addr;
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire [10:0] audio;
wire        hs, vs;
wire        blankn;
wire  [2:0] g,b;
wire  [1:0] r;

// Traverse_usa
traverse_usa traverse_usa (
	.clock_36     ( clk_sys         ),
	.clock_0p895  ( clk_aud         ),
	.reset        ( reset           ),

	.palmode      ( pal             ),
	.shtrider     ( shtrider        ),
	
	.video_r      ( r               ),
	.video_g      ( g               ),
	.video_b      ( b               ),
	.video_hs     ( hs              ),
	.video_vs     ( vs              ),
	.video_blankn ( blankn          ),

	.audio_out    ( audio           ),

	.dip_switch_1 ( dip1            ),  
	.dip_switch_2 ( dip2            ),

	.start2       ( m_two_players   ),
	.start1       ( m_one_player    ),
	.coin1        ( m_coin1         ),

	.right1       ( m_right         ),
	.left1        ( m_left          ),
	.brake1       ( m_down          ),
	.accel1       ( m_up            ),

	.right2       ( m_right2        ),
	.left2        ( m_left2         ),
	.brake2       ( m_down2         ),
	.accel2       ( m_up2           ),

	.cpu_rom_addr ( cart_addr       ),
	.cpu_rom_do   ( cart_addr[0] ? sdram_do[15:8] : sdram_do[7:0] ),
	.cpu_rom_rd   ( cart_rd         ),
	.snd_rom_addr ( snd_rom_addr    ),
	.snd_rom_do   ( snd_rom_addr[0] ? snd_do[15:8] : snd_do[7:0] ),
	.snd_rom_vma  ( snd_vma         ),
	.dl_addr      ( ioctl_addr[16:0]),
	.dl_data      ( ioctl_dout      ),
	.dl_wr        ( ioctl_wr        )
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? {r, r[1] } : 0 ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( { 1'b1, rotate } ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         ),
	.ce_divider     ( 1'b0             ),
	.blend          ( blend            )
	);

dac #(
	.C_bits(11))
dac(
	.clk_i(clk_dac),
	.res_n_i(1'b1),
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
	.orientation ( 2'b11       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

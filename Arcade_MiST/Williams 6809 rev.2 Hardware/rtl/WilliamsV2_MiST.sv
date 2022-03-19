//============================================================================
//  Arcade: Williams V2 Hardware by DarFPGA
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

module WilliamsV2_MiST(
	output        LED,
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        AUDIO_L,
	output        AUDIO_R,
	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         SPI_SS4,
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
	"TurkeyS;rom;",
	"O2,Rotate Controls,Off,On;",
	"O5,Blend,Off,On;",
	"O6,Autoup,Off,On;",
	"O8,Advance,Off,On;",
	"T9,Reset Highscores,Off,On;",
	"T0,Reset;",
	"V,v0.0.",`BUILD_DATE
};

wire rotate = status[2];
wire blend  = status[5];
wire autoup = status[6];
wire advance = status[8];
wire Hreset   = status[9];

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk48;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire clk48, clk_sys, clk12;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk48),
	.c1(clk_sys),//24
	.c2(clk12),
	.locked(pll_locked)
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)),
	.ROM_DIRECT_UPLOAD(1'b1))
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
	.status         (status         )
	);
	
wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io #(
	.ROM_DIRECT_UPLOAD(1'b1))
data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   ),
	.ioctl_din     ( ioctl_din    )
);

wire [24:0] sp_ioctl_addr = ioctl_addr - 18'h22000;//check

wire [13:0] prg_rom_addr;
wire [7:0] prg_rom_do;
wire [12:0] snd_rom_addr;
wire [7:0] snd_rom_do;
wire [16:0] bank_rom_addr;
wire [7:0] bank_rom_do;
wire [12:0] gfx_rom_addr;
wire [23:0] gfx_rom_do;
reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk48      ),

	// port1 used for main + sound CPUs
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, prg_rom_addr[13:1]} ),
	.cpu1_q        ( prg_rom_do ),

	.cpu2_addr     ( ioctl_downl ? 16'hffff : (16'h2000 + bank_rom_addr[16:1]) ),
	.cpu2_q        ( bank_rom_do ),
	.cpu3_addr     ( ioctl_downl ? 16'hffff : (16'hE000 + snd_rom_addr[12:1]) ),
	.cpu3_q        ( snd_rom_do ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {sp_ioctl_addr[23:17], sp_ioctl_addr[14:0], sp_ioctl_addr[16]} ), // merge sprite roms to 32-bit wide words
	.port2_ds      ( {sp_ioctl_addr[15], ~sp_ioctl_addr[15]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 15'h7fff : gfx_rom_addr ),//todo
	.sp_q          ( gfx_rom_do )
);

// ROM download controller
always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr && ioctl_index == 0) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end


wire [7:0] audio;
wire        hs, vs, cs;
wire        blankn;
wire  [3:0] g, r, b, intensity;

williams2 williams2(
	.clock_12			(clk12),
	.reset				(reset),
//prg low
	.prg_rom_addr		(prg_rom_addr),//(13 downto 0);
	.prg_rom_do			(prg_rom_do),//(7 downto 0);
//banks 
	.rom_addr			(bank_rom_addr),//(16 downto 0);
	.rom_do				(bank_rom_do),//( 7 downto 0);
	.rom_rd				(),//
//snd 
	.snd_rom_addr		(snd_rom_addr),//(12 downto 0);
	.snd_rom_do			(snd_rom_do),//(7 downto 0);
//gfx
	.gfx_rom_addr		(gfx_rom_addr),//(12 downto 0);
	.gfx_rom_do			(gfx_rom_do),//(23 downto 0);
//dec			hardcoded for now
	.dec_rom_addr		(),//(8 downto 0);
	.dec_rom_do			(),//(7 downto 0);

	.video_r				(r),
	.video_g				(g),
	.video_b				(b),
	.video_i				(intensity),
	.video_csync		(cs),
	.video_blankn		(blankn),
	.video_hs			(hs),
	.video_vs			(vs),
 
	.audio_out			(audio),
 
	.btn_auto_up		(autoup),
	.btn_advance		(advance),
	.btn_high_score_reset		(Hreset),

	.btn_gobble			(m_fireC),
	.btn_grenade		(m_fireB),
	.btn_coin			(m_coin1),
	.btn_start_2		(m_two_players),
	.btn_start_1		(m_one_player),
	.btn_trigger		(m_fireA),
	.btn_left			(m_left),
	.btn_right			(m_right),
	.btn_up				(m_up),
	.btn_down			(m_down),
 
	.sw_coktail_table	(1'b0)
);

wire [7:0]ri = r*intensity;
wire [7:0]gi = g*intensity;
wire [7:0]bi = b*intensity;

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? ri[7:4] : 0   ),
	.G              ( blankn ? gi[7:4] : 0   ),
	.B              ( blankn ? bi[7:4] : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( { 1'b1, rotate } ),
	.ce_divider     ( 1                ),
	.blend          ( blend            ),
	.scandoubler_disable(scandoublerD ),
	.no_csync       ( 1'b1             ),//todo
	.ypbpr          ( ypbpr            )
	);

dac #(
	.C_bits(8))
dac_(
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
	.orientation ( 2'b11       ),//check
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

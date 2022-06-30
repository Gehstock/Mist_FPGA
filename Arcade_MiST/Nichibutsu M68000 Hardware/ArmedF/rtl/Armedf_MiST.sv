//============================================================================
//  Nichibutsu M68000 HW top-level for MiST
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

module Armedf_MiST
(
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

`include "rtl\build_id.v"
`include "defs.v"

`define CORE_NAME "TERRAF"
wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME, ";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O7,Pause,Off,On;",
	"O8,Service mode,Off,On;",
//	"O9,GFX1,On,Off;",
//	"OA,GFX2,On,Off;",
//	"OB,GFX3,On,Off;",
//	"OC,GFX4,On,Off;",
	"DIP;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        joyswap   = status[6];
wire        pause     = status[7];
wire        service   = status[8];

wire  [7:0] dsw1      = status[23:16];
wire  [7:0] dsw2      = status[31:24];

reg  [15:0] p1, p2;
reg   [1:0] orientation;

always @(*) begin
	orientation = 2'b10;
	p1[15:8] = ~{ 4'h0, m_coin2, m_coin1, m_two_players, m_one_player };
	p2[15:8] = ~{ 5'h0, m_tilt, service, m_fireD/* service */ };

	p1[ 3:0] = ~{ m_right, m_left, m_down, m_up };
	p2[ 3:0] = ~{ m_right2, m_left2, m_down2, m_up2 };

	p1[ 7:4] = ~{ 1'b0, m_fireC, m_fireB, m_fireA };
	p2[ 7:4] = ~{ 1'b0, m_fire2C, m_fire2B, m_fire2A };

	if (core_mod == pcb_armedf || core_mod == pcb_legion) orientation = 2'b01;
	if (core_mod == pcb_cclimbr2) begin
		p2[ 3:0] = p1[3:0];
		p1[ 7:4] = ~{ m_right2 | m_rightB, m_left2 | m_leftB, m_down2 | m_downB, m_up2 | m_upB };
		p2[ 7:4] = p1[7:4];
	end
end

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_96;
assign SDRAM_CKE = 1;

wire clk_24, clk_96;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_96),
	.c1(clk_24),
	.locked(pll_locked)
	);

// reset generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_96) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded | ioctl_downl;
end

// ARM connection
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(
	.STRLEN($size(CONF_STR)>>3),
	.ROM_DIRECT_UPLOAD(1))
user_io(
	.clk_sys        (clk_24         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD ),
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

data_io #(.ROM_DIRECT_UPLOAD(1)) data_io(
	.clk_sys       ( clk_96       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [15:0] laudio, raudio;
wire        hs, vs;
wire        blankn = ~(hb | vb);
wire        hb, vb;
wire  [3:0] r,b,g;

armedf armedf
(
	.pll_locked   ( pll_locked ),
	.clk_96M      ( clk_96     ),
	.clk_24M      ( clk_24     ),
	.reset        ( reset      ),
	.pause_cpu    ( pause      ),

	.pcb          ( core_mod   ),
	.gfx1_en      ( ~status[9] ),
	.gfx2_en      ( ~status[10]),
	.gfx3_en      ( ~status[11]),
	.gfx4_en      ( ~status[12]),

	.p1           ( p1         ),
	.p2           ( p2         ),
	.dsw1         ( dsw1       ),
	.dsw2         ( dsw2       ),

	.hbl          ( hb         ),
	.vbl          ( vb         ),
	.hsync        ( hs         ),
	.vsync        ( vs         ),
	.r            ( r          ),
	.g            ( g          ),
	.b            ( b          ),

	.audio_l      ( laudio     ),
	.audio_r      ( raudio     ),

	.rom_download ( ioctl_downl && ioctl_index == 0),
	.ioctl_addr   ( ioctl_addr ),
	.ioctl_wr     ( ioctl_wr   ),
	.ioctl_dout   ( ioctl_dout ),

	.SDRAM_A      ( SDRAM_A    ),
	.SDRAM_BA     ( SDRAM_BA   ),
	.SDRAM_DQ     ( SDRAM_DQ   ),
	.SDRAM_DQML   ( SDRAM_DQML ),
	.SDRAM_DQMH   ( SDRAM_DQMH ),
	.SDRAM_nCS    ( SDRAM_nCS  ),
	.SDRAM_nCAS   ( SDRAM_nCAS ),
	.SDRAM_nRAS   ( SDRAM_nRAS ),
	.SDRAM_nWE    ( SDRAM_nWE  )
);

mist_video #(.COLOR_DEPTH(4),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_24),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 6'd0),
	.G(blankn ? g : 6'd0),
	.B(blankn ? b : 6'd0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.no_csync(no_csync),
	.rotate({orientation[1],rotate}),
	.ce_divider(1'b1),
	.blend(blend),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ypbpr(ypbpr)
	);

dac #(16) dacl(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i({~laudio[15], laudio[14:0]}),
	.dac_o(AUDIO_L)
	);

dac #(16) dacr(
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i({~raudio[15], raudio[14:0]}),
	.dac_o(AUDIO_R)
	);

// Common inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_upB, m_downB, m_leftB, m_rightB;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F, m_up4B, m_down4B, m_left4B, m_right4B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_24      ),
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

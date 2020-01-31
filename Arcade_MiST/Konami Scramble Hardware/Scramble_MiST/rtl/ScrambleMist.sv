//============================================================================
//  Scramble Arcade HW top-level for MiST
//
//  Scramble/Amidar/Frogger/Super Cobra/Tazzmania/Armored Car
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

module ScrambleMist
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

//`define CORE_NAME "SCRAMBLE"
//`define CORE_NAME "AMIDAR"
//`define CORE_NAME "FROGGER"
//`define CORE_NAME "SCOBRA"
//`define CORE_NAME "TAZMANIA"
//`define CORE_NAME "ARMORCAR"
//`define CORE_NAME "MOONWAR"
//`define CORE_NAME "SPDCOIN"
//`define CORE_NAME "CALIPSO"
//`define CORE_NAME "DARKPLNT" // video problem
//`define CORE_NAME "ANTEATER"
`define CORE_NAME "LOSTTOMB"

integer hwsel = 0;
reg [7:0] input0;
reg [7:0] input1;
reg [7:0] input2;

always @(*) begin
	input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_fireA, 1'b0, m_fireB, m_up2 };
	input1 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2A, m_fire2B, 2'b10 };
	input2 = ~{ 1'b1, m_down, 1'b1, m_up, 3'b111, m_down2 };

	if (`CORE_NAME == "SCRAMBLE" || `CORE_NAME == "AMIDAR") begin
		hwsel = 0;
	end else if (`CORE_NAME == "FROGGER") begin
		hwsel = 1;
	end else if (`CORE_NAME == "SCOBRA" || `CORE_NAME == "ARMORCAR") begin
		hwsel = 2;
	end else if (`CORE_NAME == "TAZMANIA") begin
		hwsel = 2;
		input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, m_fireA, m_fireB };
		input1 = ~{ m_fire2A, m_fire2B, m_left2, m_right2, m_up2, m_down2, 2'b11 };
		input2 = ~{ 1'b1, m_two_players, 2'b10, 3'b111, m_one_player };
	end else if (`CORE_NAME == "MOONWAR") begin
		hwsel = 2;
		input0 = ~{ m_coin1, m_coin2, 1'b0, dial };
		input1 = ~{ m_fireA, m_fireB, m_fireC, m_fireD, m_two_players, m_one_player, 2'b01 }; // lives
		input2 = ~{ 4'h0, 1'b1, 2'b11, 1'b0 };                                                // 4xunused, cabinet, coinage, p2fire(cocktail)
	end else if (`CORE_NAME == "CALIPSO") begin
		hwsel = 3;
	    input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, 1'b1, m_two_players|m_fire2A }; // coin1, coin2, left, right, down, up, unused, start 2p / player2 fire
        input1 = ~{ 1'b1, 1'b1, m_left2, m_right2, m_down2, m_up2, 1'b1, 1'b1 };                     // unused, unused, left, right, down, up, demo sounds, lives 3/5
        input2 = ~{ 5'b0, 2'b10, m_fireA | m_one_player };                                           // unused[7:3], coin dip[2:1], start 1p / player1 fire
	end else if (`CORE_NAME == "SPDCOIN") begin
		hwsel = 2;
		input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_two_players, 1'b0, m_one_player, 1'b0 };
		input1 = { 4'hf, 2'b00, 1'b0, 1'b0 };     // 6xunused, freeplay, freeze
		input2 = { 4'hf, 1'b0, 1'b0, 1'b1, 1'b1}; // 4xunused, lives, difficulty, unknown, unused
	end else if (`CORE_NAME == "DARKPLNT") begin
		hwsel = 4;
		input0 = ~{ m_coin1, m_coin2, 3'b000, m_two_players | m_fireB, m_one_player | m_fireA, m_fireC };
		input1 = 8'h00;
		input2 = 8'h00;
	end else if (`CORE_NAME == "ANTEATER") begin
		hwsel = 5;
		input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, m_fireA, m_fireB };
		input1 = ~{ m_fire2A, m_fire2B, m_left2, m_right2, m_up2, m_down2, 2'b11 };
		input2 = ~{ 1'b1, m_two_players, 2'b10, 3'b111, m_one_player };
	end else if (`CORE_NAME == "LOSTTOMB") begin
		hwsel = 6;
		input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, m_one_player, m_two_players };
		input1 = ~{ 1'b0, m_fireA, m_left2, m_right2, m_down2, m_up2, 2'b01 };
		input2 = ~{ 4'h0, 1'b0, 2'b10, 1'b0 }; //4xunused, demo sounds, 2xcoinage, unused
	end
end

localparam CONF_STR = {
	`CORE_NAME,";ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"06,Joystick Swap,Off,On;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       joyswap   = status[6];

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;
assign SDRAM_CLK = clk_sys;
assign SDRAM_CKE = 1;

wire clk_sys;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
	);

reg ce_6p, ce_6n, ce_12, ce_1p79;
always @(negedge clk_sys) begin
	reg [1:0] div = 0;
	reg [3:0] div179 = 0;

	div <= div + 1'd1;
	ce_12 <= div[0];
	ce_6p <= div[0] & ~div[1];
	ce_6n <= div[0] &  div[1];	
	ce_1p79 <= 0;
	div179 <= div179 - 1'd1;
	if(!div179) begin
		div179 <= 13;
		ce_1p79 <= 1;
	end
end

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

/* ROM structure
0000-7FFF 32k PGM ROM 
8000-9FFF  8k SND ROM

A000-A7FF  2k gfx1 5H
A800-AFFF  2k gfx2 5F
B000-B01F 32b palette LUT

Calipso:
A000-BFFF  8k gfx1 5H
C000-DFFF  8k gfx2 5F
E000-E01F 32b palette LUT
*/

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

reg      port1_req;
reg [15:0] rom_dout;
reg [14:0] rom_addr;

sdram #(.MHZ(24)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sys      ),

	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[22:1] ),
	.port1_ds      ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),

	// CPU
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : {3'b000, rom_addr[14:1] } ),
	.cpu1_q        ( rom_dout  )
);

always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end
end

wire  [9:0] audio;
wire        hs, vs;
//wire        blankn = ~(hb | vb);
wire        blankn = ~vb;
wire        hb, vb;
wire  [3:0] r,b,g;

scramble_top scramble(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_HBLANK(hb),
	.O_VBLANK(vb),
	.O_AUDIO(audio),
	.I_HWSEL(hwsel),
	.I_PA(input0),
	.I_PB(input1),
	.I_PC(input2),
	.RESET(status[0] | buttons[1] | ioctl_downl),
	.clk(clk_sys),
	.ena_12(ce_12),
	.ena_6(ce_6p),
	.ena_6b(ce_6n),
	.ena_1_79(ce_1p79),

	.rom_addr(rom_addr),
	.rom_dout(rom_addr[0] ? rom_dout[15:8] : rom_dout[7:0]),

	.dl_addr(ioctl_addr[15:0]),
	.dl_wr(ioctl_wr),
	.dl_data(ioctl_dout)
	);

mist_video #(.COLOR_DEPTH(4),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(~hs),
	.VSync(~vs),
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
	.ypbpr(ypbpr)
	);

dac #(10) dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire [4:0] dial;
moonwar_dial moonwar_dial (
	.clk(clk_sys),
	.moveleft(m_left | m_up),
	.moveright(m_right | m_down),
	.dialout(dial)
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
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
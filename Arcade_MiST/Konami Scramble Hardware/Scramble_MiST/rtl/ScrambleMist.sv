//============================================================================
//  Scramble Arcade HW top-level for MiST
//
//  Scramble/Amidar/Frogger/Super Cobra/Tazzmania/Armored Car
//  Moon War/Speed Coin/Calipso/Dark Planet/Anteater/Lost Tomb
//  Mars/Battle Of Attlantis/Strategy X/Turtles/Rescue/Minefield
//  Mighty Monkey
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

`define CORE_NAME "SCRAMBLE"
wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME, ";ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

integer hwsel = 0;
reg  [7:0] input0;
reg  [7:0] input1;
reg  [7:0] input2;
reg  [1:0] orientation;

always @(*) begin
	orientation = 2'b11; // portrait, left
	input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_fireA, /*service*/1'b0, m_fireB, m_up2 };
	input1 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2A, m_fire2B, /*lives*/~status[8:7] };
	input2 = ~{ 1'b1, m_down, 1'b1, m_up, /*cabinet*/1'b1, /*coinage*/2'b11, m_down2 };

	case (core_mod)
		7'h0: // SCRAMBLE
		begin
			hwsel = 0;
		end
		7'h1: // AMIDAR
		begin
			hwsel = 0;
			input1[1:0] = ~status[8:7]; // lives345unl
			//input2[1] = status[10]; // demo sounds - no effect
		end
		7'h2: // FROGGER
		begin
			hwsel = 1;
		end
		7'h3: // SCOBRA
		begin
			hwsel = 2;
			input1[0] = status[9]; // allow continue
			input1[1] = status[7]; // lives34
		end
		7'h4: // TAZMANIA
		begin
			hwsel = 2;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, m_fireA, m_fireB };
			input1 = ~{ m_fire2A, m_fire2B, m_left2, m_right2, m_up2, m_down2, /*demosnd*/status[10], /*lives35*/status[7] };
			input2 = ~{ 1'b1, m_two_players, 2'b10, 3'b111, m_one_player }; // unknown, start2, 2xunknown, cabinet, 2xcoinage, start1
		end
		7'h5: // ARMORCAR
		begin
			hwsel = 2;
			input1[0] = ~status[7]; //lives35
			input1[1] = ~status[10]; // demo sounds
		end
		7'h6: // MOONWAR
		begin
			hwsel = 2;
			input0 = ~{ m_coin1, m_coin2, 1'b0, dial };
			input1 = ~{ m_fireA, m_fireB, m_fireC, m_fireD, m_two_players, m_one_player, /*live345*/~status[8:7] };
			input2 = ~{ 4'h0, 1'b1, 2'b11, 1'b0 }; // 4xunused, cabinet, coinage, p2fire(cocktail)
		end
		7'h7: // SPDCOIN
		begin
			hwsel = 2;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_two_players, 1'b0, m_one_player, 1'b0 };
			input1 = { 4'hf, 2'b00, 1'b0, 1'b0 };     // 6xunused, freeplay, freeze
			input2 = { 4'hf, ~status[7], status[11], 1'b1, 1'b1}; // 4xunused, lives35, difficulty, unknown, unused
		end
		7'h8: // CALIPSO
		begin
			hwsel = 3;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, 1'b1, m_two_players|m_fire2A }; // coin1, coin2, left, right, down, up, unused, start 2p / player2 fire
			input1 = ~{ 1'b1, 1'b1, m_left2, m_right2, m_down2, m_up2, status[10], status[7] };          // unused, unused, left, right, down, up, demo sounds, lives 3/5
			input2 = ~{ 5'b0, 2'b10, m_fireA | m_one_player };                                           // unused[7:3], coin dip[2:1], start 1p / player1 fire
		end
		7'h9: // DARKPLNT
		begin
			hwsel = 4;
			input0 = ~{ m_coin1, m_coin2, 3'b000, m_two_players | m_fireB, m_one_player | m_fireA, m_fireC };
			input1 = { darkplnt_dial_scrambled, /*lives*/status[7], /*bonus*/1'b0 };
			input2 = { /*unk*/4'hf, /*bonus life*/1'b0, /*coinage*/ 2'b10, /*unk*/1'b1 };
		end
		7'hA: // ANTEATER
		begin
			hwsel = 6;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, m_fireA, m_fireB };
			input1 = ~{ m_fire2A, m_fire2B, m_left2, m_right2, m_up2, m_down2, /*demosdns*/status[10], /*lives35*/status[7] };
			input2 = ~{ 1'b1, m_two_players, 2'b10, 3'b111, m_one_player };
		end
		7'hB: // LOSTTOMB
		begin
			hwsel = 7;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, m_one_player, m_two_players };
			input1 = ~{ 1'b0, m_fireA, m_left2, m_right2, m_down2, m_up2, /*lives35/free play/invulnerability*/~(status[8:7]+1'd1) };
			input2 = ~{ 4'h0, status[10], 2'b10, 1'b0 }; //4xunused, demo sounds, 2xcoinage, unused
		end
		7'hC: // MARS
		begin
			hwsel = 10;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_left2 | m_fireA, m_right2 | m_fireB, 1'b0, 1'b0 };
			input1 = ~{ m_one_player, m_two_players, 4'h0, /*coinage*/2'b11 };
			input2 = ~{ m_up2 | m_fireC, m_down, m_down2 | m_fireD, m_up, /*lives*/status[7], /*unk*/1'b0, /*cabinet*/1'b1, 1'b0 };
		end
		7'hD: // ATLANTIS
		begin
			hwsel = 0;
			input1[0] = 1'b0; // upright
			input1[1] = ~status[7]; // lives35
		end
		7'hE: // STRATGYX
		begin
			hwsel = 5;
			orientation = 2'b10;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_fireA, 1'b0, m_fireB, m_up2 };
			input1 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2A, m_fire2B, ~status[8:7] };
			input2 = ~{ m_fire2C, m_down, m_fireC, m_up, /*upright*/1'b1, /*coinage*/2'b00, m_down2 };
		end
		7'hF: // TURTLES
		begin
			hwsel = 11;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_fireA, 1'b0, 1'b0, m_up2 };
			input1 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2A, 1'b0, ~status[8:7] };
			input2 = ~{ 1'b0, m_down, 1'b0, m_up, /*upright*/1'b1, /*coinage*/2'b00, m_down2 };
		end
		7'h10: // MINEFLD
		begin
			hwsel = 8;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, /*start level*/status[11], m_fireA };
			input1 = ~{ /*2xunk*/2'b00, m_left2, m_right2, m_down2, m_up2, /*demosnd*/status[10], /*lives35*/status[7] };
			input2 = ~{ /*unk*/1'b0, m_two_players, /*2xunk*/2'b00, /*difficulty*/status[9:8], /*coinage*/1'b0, m_one_player };
		end
		7'h11: // RESCUE
		begin
			hwsel = 9;
			input0 = ~{ m_coin1, m_coin2, m_left, m_right, m_down, m_up, /*start level*/status[9], m_fireA };
			input1 = ~{ /*2xunk*/2'b00, m_left2, m_right2, m_down2, m_up2, /*demosnd*/status[10], /*lives35*/status[7] };
			input2 = ~{ /*unk*/1'b0, m_two_players, /*2xunk*/2'b00, /*difficulty*/~status[8], /*coinage*/2'b11, m_one_player };
		end
		7'h12: // MIMONKEY
		begin
			hwsel = 12;
			input2[5] = status[9]; // infinite lives
		end
		7'h13: // MRKOUGAR
		begin
			hwsel = 13;
//			input2[5] = status[9]; // infinite lives
		end
		default:
		begin
			hwsel = 0;
		end
	endcase
end

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

// reset generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded | ioctl_downl;
end

// clock enables
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

// ARM connection
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

user_io #(
	.STRLEN($size(CONF_STR)>>3))
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
	.no_csync       (no_csync       ),
	.core_mod       (core_mod       ),
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

Calipso, Mighty Monkey:
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
wire  [5:0] r,b,g;

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
	.RESET(reset),
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

mist_video #(.COLOR_DEPTH(6),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_sys),
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

wire [6:0] darkplnt_dial;
spinner spinner (
	.clock(clk_sys),
	.reset(reset),
	.btn_left(m_left | m_up),
	.btn_right(m_right | m_down),
	.strobe(vs),
	.spin_angle(darkplnt_dial)
);

wire [5:0] dp_remap[64] = 
'{
	6'h03, 6'h02, 6'h00, 6'h01, 6'h21, 6'h20, 6'h22, 6'h23,
	6'h33, 6'h32, 6'h30, 6'h31, 6'h11, 6'h10, 6'h12, 6'h13,
	6'h17, 6'h16, 6'h14, 6'h15, 6'h35, 6'h34, 6'h36, 6'h37,
	6'h3f, 6'h3e, 6'h3c, 6'h3d, 6'h1d, 6'h1c, 6'h1e, 6'h1f,
	6'h1b, 6'h1a, 6'h18, 6'h19, 6'h39, 6'h38, 6'h3a, 6'h3b,
	6'h2b, 6'h2a, 6'h28, 6'h29, 6'h09, 6'h08, 6'h0a, 6'h0b,
	6'h0f, 6'h0e, 6'h0c, 6'h0d, 6'h2d, 6'h2c, 6'h2e, 6'h2f,
	6'h27, 6'h26, 6'h24, 6'h25, 6'h05, 6'h04, 6'h06, 6'h07
};

wire [5:0] darkplnt_dial_scrambled = dp_remap[darkplnt_dial[6:1]];

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
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
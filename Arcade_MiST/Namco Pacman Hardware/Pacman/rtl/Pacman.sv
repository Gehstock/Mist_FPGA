//============================================================================
//  Arcade: Pacman
//
//  Version for MiSTer
//  Copyright (C) 2017 Sorgelig
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

module Pacman_MiST(
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
	input         CLOCK_27
);

`include "rtl\build_id.v"

localparam CONF_STR = {
	"PACMAN;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Flip,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        flip = status[6];

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_snd;
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
reg ce_6m;
always @(posedge clk_sys) begin
	reg [1:0] div;

	div <= div + 1'd1;
	ce_6m <= !div;
end

reg ce_4m;
always @(posedge clk_sys) begin
	reg [2:0] div;

	div <= div + 1'd1;
	if(div == 5) div <= 0;
	ce_4m <= !div;
end

reg ce_1m79;
always @(posedge clk_sys) begin
	reg [3:0] div;

	div <= div + 1'd1;
	if(div == 12) div <= 0;
	ce_1m79 <= !div;
end

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

wire [63:0] status;
wire  [6:0] core_mod;
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

wire  [9:0] audio;
wire        hs, vs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire  [2:0] r,g;
wire  [1:0] b;

reg mod_plus = 0;
reg mod_jmpst= 0;
reg mod_club = 0;
reg mod_orig = 0;
//reg mod_crush= 0;
reg mod_bird = 0;
reg mod_ms   = 0;
reg mod_gork = 0;
reg mod_mrtnt= 0;
reg mod_woodp= 0;
reg mod_eeek = 0;
reg mod_alib = 0;
reg mod_ponp = 0;
reg mod_van  = 0;
reg mod_pmm  = 0;
reg mod_dshop= 0;
reg mod_glob = 0;
reg mod_numcr= 0;

wire mod_gm = mod_gork | mod_mrtnt;

always @(*) begin

	mod_orig = (core_mod == 0);
	mod_plus = (core_mod == 1);
	mod_club = (core_mod == 2);
	//mod_crush= (mod == 3);
	mod_bird = (core_mod == 4);
	mod_ms   = (core_mod == 5);
	mod_gork = (core_mod == 6);
	mod_mrtnt= (core_mod == 7);
	mod_woodp= (core_mod == 8);
	mod_eeek = (core_mod == 9);
	mod_alib = (core_mod == 10);
	mod_ponp = (core_mod == 11);
	mod_van  = (core_mod == 12);
	mod_pmm  = (core_mod == 13);
	mod_dshop= (core_mod == 14);
	mod_glob = (core_mod == 15);
	mod_jmpst= (core_mod == 16);
	mod_numcr= (core_mod == 17);
end

wire [7:0] in0xor = mod_ponp ? 8'hE0 : 8'hFF;
wire [7:0] in1xor = mod_ponp ? 8'h00 : 8'hFF;
wire       m_cheat = m_fireC;

pacman pacman(
	.mod_plus(mod_plus),
	.mod_jmpst(mod_jmpst),
	.mod_bird(mod_bird),
	.mod_ms(mod_ms),
	.mod_mrtnt(mod_mrtnt),
	.mod_woodp(mod_woodp),
	.mod_eeek(mod_eeek),
	.mod_alib(mod_alib),
	.mod_ponp(mod_ponp | mod_van | mod_dshop),
	.mod_van(mod_van | mod_dshop),
	.mod_dshop(mod_dshop),
	.mod_glob(mod_glob),
	.mod_club(mod_club),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr && !ioctl_index),

	.in0(status[15:8] & (in0xor ^ {
		mod_eeek & m_fireB,
		(mod_alib & m_fireA) | ( mod_numcr ),
		~mod_numcr & m_coin1,
		((mod_orig | mod_plus | mod_ms | mod_bird | mod_alib | mod_woodp | mod_numcr) & m_cheat) | ((mod_ponp | mod_van | mod_dshop) & m_fireA),
		m_down,
		(~mod_numcr & m_right) | ( mod_numcr & m_left  ),
		(~mod_numcr & m_left ) | ( mod_numcr & m_right ),
		m_up
	})),

	.in1(status[23:16] & (in1xor ^ {
		(mod_gm & m_fireB) ,
		m_two_players | (mod_eeek & m_fireA) | (mod_jmpst & m_fireB) | (mod_numcr & m_one_player),
		(~mod_numcr&m_one_player)   | (mod_jmpst & m_fireA) | (mod_numcr & m_coin1),
		(mod_gm & m_fireA) | ((mod_alib | mod_ponp | mod_van | mod_dshop) & m_fireB),
		~mod_pmm & m_down2,
		mod_pmm ? m_fireA : m_right2,
		~mod_pmm & m_left2,
		(~mod_pmm & m_up2) | (mod_numcr&m_fireA)
	})),
	.dipsw1(status[31:24]),
	.dipsw2((mod_numcr| mod_ponp | mod_van | mod_dshop) ? status[39:32] : 8'hFF),

	.flip_screen(flip),

	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_HBLANK(hb),
	.O_VBLANK(vb),
	.O_AUDIO(audio),

	.RESET(reset),
	.CLK(clk_sys),
	.ENA_6(ce_6m),
	.ENA_4(ce_4m),
	.ENA_1M79(ce_1m79)
	);

mist_video #(.COLOR_DEPTH(3),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? {b, 1'b0} : 0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({~flip,rotate}),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ce_divider(1'b1),
	.blend(blend),
	.ypbpr(ypbpr),
	.no_csync(no_csync)
	);

dac #(
	.C_bits(10))
dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

// controls
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
	.orientation ( {~flip, ~mod_ponp} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

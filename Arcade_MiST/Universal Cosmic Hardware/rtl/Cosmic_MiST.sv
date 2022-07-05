//  Arcade: Universal Cosmic series (Z80 version)
//
//  Mike Coates.
//
//  MiST port by slingshot
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

module Cosmic_MiST(
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

`define CORE_NAME "COSMIIEN"

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Swap Joysticks,Off,On;",
	"O7,Flip,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       joyswap   = status[6];
wire       flip      = status[7];

wire  [6:0] core_mod;
wire  [1:0] orientation = {flip, 1'b1}; // [left/right, landscape/portrait]

wire clk_vid, clk_sys;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_vid),//43.264
	.c1(clk_sys),//10.816
	.locked(pll_locked)
	);

assign SDRAM_CLK = clk_vid;
assign LED = ~ioctl_downl;

wire pix_clk = clk_div[0];      // Pixel clock = 5.408 Mhz

reg  [1:0] clk_div = 2'd0;      // Clock divider (for Pixel and CPU speed 2.7Mhz)
reg  [2:0] clk_div2 = 3'd0;     // Clock divider (for CPU speed 1.8 Mhz)
reg cpu_ena_27;                 // 2.7 Mhz
reg cpu_ena_18;                 // 1.8 Mhz

// Divider for other clocks (7474 and 74161 on PCB)
always @(posedge clk_sys) begin
	cpu_ena_27 <= 1'd0;
	cpu_ena_18 <= 1'd0;
        
	clk_div <= clk_div + 1'b1;
	clk_div2 <= clk_div2 + 1'b1;

	// cpu clocks
	if (clk_div == 3) cpu_ena_27 <= 1'd1;
                        
	if (clk_div2 == 5) begin
		cpu_ena_18 <= 1'd1;
		clk_div2 <= 3'd0;
	end
end

// Game ID - CPU Speed
// 01 = Space Panic - 1.8 Mhz
// 02 = Magic Spot  - 2.7 Mhz
// 03 = Cosmic Alien - 1.8 Mhz
// 04 = Devil Zone - 2.7 Mhz
// 05 = No Mans Land - 1.8Mhz

wire cpu_ena = (core_mod==2 || core_mod==4) ? cpu_ena_27 : cpu_ena_18;

wire [15:0] dip = status[23:8];
// Panic
wire  [7:0] Panic_P1 = {~m_fireB,2'd3,~m_up,~m_down,~m_left,~m_right,~m_fireA};
wire  [7:0] Panic_P2 = {~m_fire2B,2'd3,~m_up2,~m_down2,~m_left2,~m_right2,~m_fire2A};
wire  [7:0] Panic_P3 = {1'd1,~m_coin1,4'D15,~m_two_players,~m_one_player};
// Magical Spot
wire  [7:0] MagSpot_P1 = {dip[15:14],~m_right,3'd7,~m_left,1'd1}; // Includes bonus dips
wire  [7:0] MagSpot_P2 = {2'd3,~m_right2,3'd7,~m_left2,1'd1};
wire  [7:0] MagSpot_P3 = {~m_fireA,~m_fire2A,5'D31,~vblank};
wire  [7:0] MagSpot_P4 = {~m_one_player,~m_two_players,dip[5:0]};
// Cosmic Alien
wire  [7:0] Alien_P1 = {5'd31,~m_left,~m_right,~m_fireA};
wire  [7:0] Alien_P2 = {5'd31,~m_left2,~m_right2,~m_fire2A};
wire  [7:0] Alien_P3 = {2'd0,VCount[7:2]};
// No Mans Land
wire  [7:0] NML_P1 = m_fireA  ? 8'hFF : (m_up  && m_left ) ? 8'hFE : (m_down  && m_left ) ? 8'hFB : (m_down  && m_right ) ? 8'hEF : (m_up  && m_right ) ? 8'hBF : {~m_up ,1'd1,~m_right ,1'd1,~m_down ,1'd1,~m_left ,1'd1};
wire  [7:0] NML_P2 = m_fire2A ? 8'hFF : (m_up2 && m_left2) ? 8'hFE : (m_down2 && m_left2) ? 8'hFB : (m_down2 && m_right2) ? 8'hEF : (m_up2 && m_right2) ? 8'hBF : {~m_up2,1'd1,~m_right2,1'd1,~m_down2,1'd1,~m_left2,1'd1};

// Select correct inputs
wire  [7:0] IN0 = (core_mod==1)? Panic_P1 : (core_mod==2 || core_mod==4) ? MagSpot_P1 : (core_mod==5) ? NML_P1 : Alien_P1;
wire  [7:0] IN1 = (core_mod==1)? Panic_P2 : (core_mod==2 || core_mod==4) ? MagSpot_P2 : (core_mod==5) ? NML_P2 : Alien_P2;
wire  [7:0] IN2 = (core_mod==1)? Panic_P3 : (core_mod==2 || core_mod==4 || core_mod==5)? MagSpot_P3 : Alien_P3;
wire  [7:0] DIP = (core_mod==1)? dip[7:0] : MagSpot_P4;


wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [19:0] joystick_0;
wire [19:0] joystick_1;
wire        scandoublerD;
wire        no_csync;
wire        ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

wire        mouse_strobe;
wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire  [7:0] mouse_flags;
wire        mouse_idx;

user_io #(
	.STRLEN($size(CONF_STR)>>3))
user_io(
	.clk_sys        ( clk_sys          ),
	.conf_str       ( CONF_STR         ),
	.SPI_CLK        ( SPI_SCK          ),
	.SPI_SS_IO      ( CONF_DATA0       ),
	.SPI_MISO       ( SPI_DO           ),
	.SPI_MOSI       ( SPI_DI           ),
	.buttons        ( buttons          ),
	.switches       ( switches         ),
	.scandoubler_disable (scandoublerD ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         ),
	.core_mod       ( core_mod         ),
	.key_strobe     ( key_strobe       ),
	.key_pressed    ( key_pressed      ),
	.key_code       ( key_code         ),
	.mouse_idx      ( mouse_idx        ),
	.mouse_strobe   ( mouse_strobe     ),
	.mouse_x        ( mouse_x          ),
	.mouse_y        ( mouse_y          ),
	.mouse_flags    ( mouse_flags      ),
	.joystick_0     ( joystick_0       ),
	.joystick_1     ( joystick_1       ),
	.status         ( status           )
	);

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io data_io (
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
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

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded;
end

wire        audio;
wire        hblank, vblank;
wire        hs, vs;
wire  [3:0] r,g,b;
wire  [8:0] VCount;
wire        blank = hblank | vblank;
reg   [1:0] BackSpeed;

COSMIC COSMIC
(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_HBLANK(hblank),
	.O_VBLANK(vblank),
	.I_H_OFFSET(),
	.I_V_OFFSET(),
	.I_FLIP(flip),
	.O_VCOUNT(VCount),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr && (ioctl_index == 0) && ioctl_addr < table_offset),
	.dn_ld(ioctl_downl),

	.O_SoundPort(SoundTrigger),
	.O_SoundStop(SoundStop),
	.O_AUDIO(audio),
	.O_Sound_EN(),
	.O_NML_Speed(BackSpeed),

	.dipsw1(DIP),
	.dipsw2(dip[15:8]),
	.in0(IN0),
	.in1(IN1),
	.in2(IN2),
	.coin(m_coin1),

	.RESET(reset),
	.PIX_CLK(pix_clk),
	.CPU_ENA(cpu_ena),
	.CLK(clk_sys),
	.GAME(core_mod),

	.PAUSED(),

	.hs_address(),
	.hs_data_out(),
	.hs_data_in(),
	.hs_write(),
	.hs_access()
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( clk_vid          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blank ? 4'd0 : r ),
	.G              ( blank ? 4'd0 : g ),
	.B              ( blank ? 4'd0 : b ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( {flip,rotate}    ),
	.scandoubler_disable( scandoublerD ),
	.ce_divider     ( 1'b1             ),
	.no_csync       ( no_csync         ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            )
	);

// Samples

wire [24:0] table_offset = core_mod == 5 ? 24'd30720 : core_mod == 4 ? 24'd30752 : core_mod == 3 ? 24'd29696 : 24'd26656;
wire [24:0] wav_offset = table_offset + (core_mod == 5 ? 8'd192 : 8'd128);

wire        wav_download = ioctl_downl && (ioctl_index == 0) && ioctl_addr >= wav_offset;
reg  [24:0] wav_addr;
wire [15:0] wav_data;
reg         wav_want_byte;
wire [15:0] samples_left;
wire [15:0] samples_right;
reg         use_samples;
reg  [15:0] SoundTrigger;
reg  [15:0] SoundStop;
reg         Sound_Enable;

// 8 bit write, 16 bit read

sdram sdram (
	.*,
	.init(~pll_locked),
	.clk(clk_vid),

	.addr(ioctl_downl ? ioctl_addr-wav_offset : {wav_addr[24:1],1'd0}),
	.we(wav_download && ioctl_wr),
	.rd(~ioctl_downl & wav_want_byte),
	.din(ioctl_dout),
	.dout(wav_data),

	.ready()
);

// Link to Samples module

wire            samples_download = ioctl_downl && (ioctl_index == 0) && ioctl_addr >= table_offset && ioctl_addr < wav_offset;
samples samples
(
	.audio_enabled(1'd1),
	.audio_port_0(SoundTrigger[7:0]),
	.audio_port_1(SoundTrigger[15:8]),
	.audio_stop(SoundStop),

	.wave_addr(wav_addr),
	.wave_read(wav_want_byte),
	.wave_data(wav_data),

	.samples_ok(use_samples),

	.dl_addr(ioctl_addr-table_offset),
	.dl_wr(ioctl_wr),
	.dl_data(ioctl_dout),
	.dl_download(samples_download),

	.NML_Speed(BackSpeed),

	.CLK_SYS(clk_sys),
	.clock(clk_vid),
	.reset(reset),

	.audio_in({1'b0, {11{audio}}, 3'd0}),
	.audio_out_L(samples_left),
	.audio_out_R(samples_right)
);

dac #(
	.C_bits(16))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(samples_left),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(16))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(samples_right),
	.dac_o(AUDIO_R)
	);


// Common inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_upB, m_downB, m_leftB, m_rightB;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F, m_up4B, m_down4B, m_left4B, m_right4B;
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
	.player1     ( {m_upB, m_downB, m_leftB, m_rightB, 6'd0, m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, 6'd0, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, 6'd0, m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, 6'd0, m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 

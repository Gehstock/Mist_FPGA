//============================================================================
//  Midway SatansHollow/Tron/DominoMan/Wacko/Kozmik Krooz'r/Two Tigers
//  arcade top-level for MiST
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
`default_nettype none

module TwoTigers_MiST(
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

localparam CONF_STR = {
	"TWOTIGERC;;",
	"O2,Rotate Controls,Off,On;",
	"O5,Blend,Off,On;",
	"O6,Swap Joysticks,Off,On;",
	"O4,Spinner speed,Low,High;",
	"DIP;",
	"O7,Service,Off,On;",
	"R2048,Save NVRAM;",
	"T0,Reset;",
	"V,v2.0.",`BUILD_DATE
};

wire       rotate  = status[2];
wire       blend   = status[5];
wire       joyswap = status[6];
wire       service = status[7];
wire       spinspd = status[4];

wire       oneplayer = 1'b0;
wire  [1:0] orientation; //left/right / portrait/landscape
wire  [7:0] input_0 = ~{ service, 1'b0, m_tilt, m_three_players, m_two_players, m_one_player, m_coin2, m_coin1 };
wire  [7:0] input_1 = ~{ 1'b0, spin_angle1 };
wire  [7:0] input_2 = ~{ 4'b0000, m_fire2B, m_fire2A, m_fireB, m_fireA };
wire  [7:0] input_3 = 8'hFF;
wire  [7:0] input_4 = ~{ 1'b0, spin_angle2 };



assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_sys;
assign SDRAM_CKE = 1;

wire clk_sys;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
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
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire        mouse_strobe;
reg   [7:0] mouse_flags;

wire [31:0] sd_lba;
wire sd_rd;
wire sd_ack;
wire sd_ack_conf;
wire [7:0] sd_dout;
wire sd_dout_strobe;
wire img_mounted;
wire [63:0] img_size;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)),
	.SD_IMAGES(1))
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
	.mouse_x        (mouse_x        ),
	.mouse_y        (mouse_y        ),
	.mouse_strobe   (mouse_strobe   ),
	.mouse_flags    (mouse_flags    ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	
	// SD CARD
   .sd_lba         (sd_lba        ),
	.sd_rd          (sd_rd         ),
	.sd_wr          (1'b0 ),
	.sd_ack         (sd_ack        ),
	.sd_ack_conf    (sd_ack_conf   ),
	.sd_conf        (1'b0 ),
	.sd_sdhc        (1'b1 ),
	.sd_dout        (sd_dout       ),
	.sd_dout_strobe (sd_dout_strobe),
	.sd_din         ( ),
	.sd_din_strobe  ( ),
	.sd_buff_addr   ( ),
	.img_mounted    (img_mounted   ),
	.img_size       (img_size      ),
	
	.status         (status         )
	);

wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [13:0] snd_addr;
wire [15:0] snd_do;
wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

/* ROM structure
00000 - 0BFFF  48k CPU1
0C000 - 0FFFF  16k CPU2
10000 - 13FFF  16k GFX1
14000 - 1BFFF  32k GFX2
*/

data_io data_io(
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

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : rom_addr[15:1] ),
	.cpu1_q        ( rom_do ),

	// port2 for sound board
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h6000 ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.snd_addr      ( ioctl_downl ? 15'h7fff : {2'b00, snd_addr[13:1]} ),
	.snd_q         ( snd_do )
);

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
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded;
end

wire [15:0] audio_l, audio_r;
wire        hs, vs, cs;
wire        blankn;
wire  [2:0] g, r, b;
wire [7:0] output_4;

satans_hollow satans_hollow(
	.clock_40(clk_sys),
	.reset(reset),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_blankn(blankn),
	.video_hs(hs),
	.video_vs(vs),
	.video_csync(cs),
	.tv15Khz_mode(scandoublerD),
	.separate_audio(1'b1),
	.audio_out_l(audio_l),
	.audio_out_r(audio_r),

	.input_0      ( input_0         ),
	.input_1      ( input_1         ),
	.input_2      ( input_2         ),
	.input_3      ( input_3         ),
	.input_4      ( input_4         ),
	
	

	.cpu_rom_addr ( rom_addr        ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.snd_rom_addr ( snd_addr        ),
	.snd_rom_do   ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),

	.dl_addr      ( ioctl_addr[16:0]),
	.dl_wr        ( ioctl_wr && ioctl_index == 0 ),
	.dl_data      ( ioctl_dout ),
	.up_data      ( ioctl_din  ),
	.cmos_wr      ( ioctl_wr && ioctl_index == 8'hff )
);

wire vs_out;
wire hs_out;
always @(posedge clk_sys) begin
	VGA_HS <= (~no_csync & scandoublerD & ~ypbpr)? cs : hs_out;
	VGA_VS <= (~no_csync & scandoublerD & ~ypbpr)? 1'b1 : vs_out;
end

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( vs_out           ),
	.VGA_HS         ( hs_out           ),
	.rotate         ( { orientation[1], rotate } ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	.scandoubler_disable( 1'b1         ),
	.no_csync       ( 1'b1             ),
	.scanlines      (                  ),
	.ypbpr          ( ypbpr            )
	);

// Wave sound
	
wire wav_mounted;
wire [31:0] wav_addr;
wire wav_rd;
wire wav_rd_next;
wire [7:0] wav_d;
wire wav_ack;

assign wav_addr[31:28] = 4'h0;
assign sd_lba[31:23] = 8'h00;

// Bytewise interface to disk images
diskimage_by_byte waveinterface (
	.clk(clk_sys),
	.reset_n(~reset),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_ack(sd_ack),
	.sd_d(sd_dout),
	.sd_d_strobe(sd_dout_strobe),
	.sd_imgsize(img_size),
	.sd_imgmounted(img_mounted),

	.client_mounted(wav_mounted),
	.client_addr(wav_addr),
	.client_rd(wav_rd),
	.client_rd_next(wav_rd_next),
	.client_q(wav_d),
	.client_ack(wav_ack)
);

// Wave player

wire [15:0] wav_out_l;
wire [15:0] wav_out_r;

wire playing;

assign playing = wav_mounted && output_4[1];

wave_sound #(.SYSCLOCK(40000000)) waveplayer
(
	.I_CLK(clk_sys),
	.I_RST(reset | img_mounted),

	.I_BASE_ADDR(0),
	.I_LOOP(1'b1),
	.I_PAUSE(~playing),
	
	.O_ADDR(wav_addr),
	.O_READ(wav_rd),
	.O_READNEXT(wav_rd_next),
	.I_DATA(wav_d),
	.I_READY(wav_ack),

	.O_PCM_L(wav_out_l),
	.O_PCM_R(wav_out_r)
);


reg [16:0] audio_l_sum;
reg [16:0] audio_r_sum;

reg [16:0] dac_in_l;
reg [16:0] dac_in_r;

always @(posedge clk_sys) begin

	audio_l_sum <= {wav_out_l[15],wav_out_l} + {audio_l,1'b0} - 16'h4000;
	audio_r_sum <= {wav_out_r[15],wav_out_r} + {audio_r,1'b0} - 16'h4000;

	dac_in_l <= {~audio_l_sum[16],audio_l_sum[15:0]};
	dac_in_r <= {~audio_r_sum[16],audio_r_sum[15:0]};
end


dac #(
	.C_bits(17))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(dac_in_l),
	.dac_o(AUDIO_L)
	);
	
dac #(
	.C_bits(17))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(dac_in_r),
	.dac_o(AUDIO_R)
	);	

// Mouse controls for Wacko
reg signed [10:0] x_pos;
reg signed [10:0] y_pos;

always @(posedge clk_sys) begin
	if (mouse_strobe) begin
		if (rotate) begin
			x_pos <= x_pos - mouse_y;
			y_pos <= y_pos + mouse_x;
		end else begin
			x_pos <= x_pos + mouse_x;
			y_pos <= y_pos + mouse_y;
		end
	end
end

// Controls for Kozmik Krooz'r
reg  signed [9:0] x_pos_kroozr;
reg  signed [9:0] y_pos_kroozr;
wire signed [8:0] move_x = rotate ? -mouse_y : mouse_x;
wire signed [8:0] move_y = rotate ?  mouse_x : mouse_y;
wire signed [9:0] x_pos_new = x_pos_kroozr - move_x;
wire signed [9:0] y_pos_new = y_pos_kroozr + move_y;
reg  [1:0] mouse_btns;

always @(posedge clk_sys) begin
	if (mouse_strobe) begin
		mouse_btns <= mouse_flags[1:0];
		if (!((move_x[8] & ~x_pos_kroozr[9] &  x_pos_new[9]) || (~move_x[8] &  x_pos_kroozr[9] & ~x_pos_new[9]))) x_pos_kroozr <= x_pos_new;
		if (!((move_y[8] &  y_pos_kroozr[9] & ~y_pos_new[9]) || (~move_y[8] & ~y_pos_kroozr[9] &  y_pos_new[9]))) y_pos_kroozr <= y_pos_new;
	end
end

// Spinners for Tron, Two Tigers, Krooz'r
wire [6:0] spin_angle1;
spinner spinner1 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(spinspd),
	.btn_left(m_left | m_up),
	.btn_right(m_right | m_down),
	.ctc_zc_to_2(vs),
	.spin_angle(spin_angle1)
);

wire [6:0] spin_angle2;
spinner spinner2 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(spinspd),
	.btn_left(m_left2 | m_up2),
	.btn_right(m_right2 | m_down2),
	.ctc_zc_to_2(vs),
	.spin_angle(spin_angle2)
);

// Arcade inputs
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
	.oneplayer   ( oneplayer   ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

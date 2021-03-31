//============================================================================
//  Arcade: MCR1 for MiST top-level
//  Using Kickman by DarFPGA
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

module MCR1_MiST(
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

`define CORE_NAME "KICKMAN"
wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O2,Rotate Controls,Off,On;",
	"O5,Blend,Off,On;",
	"DIP;",
	"O6,Service,Off,On;",
	"R2048,Save NVRAM;",
	"T0,Reset;",
	"V,v1.1.",`BUILD_DATE
};

wire   rotate  = status[2];
wire   blend   = status[5];
wire   service = status[6];

reg  [7:0] input_0;
reg  [7:0] input_1;
reg  [7:0] input_2;
reg  [7:0] input_3;
reg signed [7:0] spr_offset;
reg vflip_sel;
reg dpoker_lamp;

always @(*) begin
	input_0 = 8'hff;
	input_1 = 8'hff;
	input_2 = 8'hff;
	input_3 = 8'hff;
	spr_offset = 8'd3;
	vflip_sel = 0;
	dpoker_lamp = 0;

	case (core_mod)
	7'h0: // KICK(MAN)
	begin
		input_0 = ~{ service, 2'b00, m_down, m_two_players, m_one_player, m_coin2, m_coin1 };
		input_1 = ~{ 4'h0, spin_angle };
		input_3 =  { /*music*/status[7], 7'd0 };
	end
	7'h1: // SOLARFOX
	begin
		spr_offset = -8'd3;
		input_0 = ~{ service, 2'b00, m_fireA, m_two_players | m_fire2B, m_one_player | m_fireB, m_coin2, m_coin1 };
		input_1 = ~{ m_up2, m_down2, m_left2, m_right2, m_up, m_down, m_left, m_right };
		input_2 = ~{ 7'd0, m_fire2A };
		input_3 = ~{ /*cocktail*/1'b0, /*ign.hw fail*/1'b0, /*demo snd*/status[9], /*unk*/2'b00, /*bonus*/&(~status[8:7]), status[8] };
	end
	7'h2: // DPOKER
	begin
		vflip_sel = 1;
		dpoker_lamp = status[7];
		input_0 = ~{ 2'b11, m_down, m_up, dpoker_hopper_release_status, 1'b0, dpoker_coin_release_status, dpoker_coin_in_status };
		input_1 = ~{ /*stand*/m_fireA, /*cancel*/m_fireB, /*deal*/m_fireC, btn_hold5, btn_hold4, btn_hold3, btn_hold2, btn_hold1 };
		input_3 = ~{ /*backgr.*/status[12], /*currency*/status[11], /*faceup*/status[10], /*2xunused*/2'b11, /*novelty*/status[9], /*music*/status[8], /*hopper*/1'b0 };
	end
	default : ;
	endcase

end

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

wire [14:0] rom_addr;
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
00000-07FFF CPU1
08000-0BFFF CPU2
0C000-13FFF gfx2
14000-15FFF gfx1
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

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : {1'b0, rom_addr[14:1]} ),
	.cpu1_q        ( rom_do ),

	// port2 for sound board
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h4000 ),
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
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire [15:0] audio_l, audio_r;
wire        hs, vs, cs;
wire        blankn;
wire  [3:0] g, r, b;
wire [24:0] dl_addr = ioctl_addr - 16'hC000;

kick kick(
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

	.ctc_zc_to_2(ctc_zc_to2),
	.input_0(input_0),
	.input_1(input_1),
	.input_2(input_2),
	.input_3(input_3),

	.spr_offset(spr_offset),
	.vflip_sel(vflip_sel),
	.dpoker_lamp(dpoker_lamp),
	.hopper(dpoker_hopper),

	.cpu_rom_addr ( rom_addr        ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.snd_rom_addr ( snd_addr        ),
	.snd_rom_do   ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),

	.dl_addr      ( dl_addr[16:0]   ),
	.dl_data      ( ioctl_dout      ),
	.dl_wr        ( ioctl_wr && ioctl_index == 0 ),
	.up_data      ( ioctl_din  ),
	.cmos_wr      ( ioctl_wr && ioctl_index == 8'hff )
);

wire vs_out;
wire hs_out;
assign VGA_HS = (~no_csync & scandoublerD & ~ypbpr)? cs : hs_out;
assign VGA_VS = (~no_csync & scandoublerD & ~ypbpr)? 1'b1 : vs_out;

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
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
	.rotate         ( { 1'b1, rotate } ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	.scandoubler_disable( 1'b1         ),
	.no_csync       ( 1'b1             ),
	.ypbpr          ( ypbpr            )
	);

dac #(
	.C_bits(16))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(16))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_r),
	.dac_o(AUDIO_R)
	);	

// Draw poker coin in detector
wire dpoker_coin_in_status, dpoker_coin_release_status;
coin_flow coin_in(clk_sys, reset, m_coin1, dpoker_coin_in_status, dpoker_coin_release_status);

// Draw poker hopper control
wire dpoker_hopper;
wire dpoker_hopper_in_status, dpoker_hopper_release_status;
coin_flow hopper(clk_sys, reset, dpoker_hopper, dpoker_hopper_in_status, dpoker_hopper_release_status);

// Draw poker extra buttons
reg btn_hold1 = 0;
reg btn_hold2 = 0;
reg btn_hold3 = 0;
reg btn_hold4 = 0;
reg btn_hold5 = 0;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
			'h1A: btn_hold1       <= key_pressed; // Z
			'h22: btn_hold2       <= key_pressed; // X
			'h21: btn_hold3       <= key_pressed; // C
			'h2A: btn_hold4       <= key_pressed; // V
			'h32: btn_hold5       <= key_pressed; // B
		endcase
	end
end

// Kick spinner
wire       ctc_zc_to2;
wire [3:0] spin_angle;

spinner spinner (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(m_fireA),
	.btn_left(m_left),
	.btn_right(m_right),
	.ctc_zc_to_2(ctc_zc_to2),
	.spin_angle(spin_angle)
);

// General controls
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

module coin_flow(
	input  clk,
	input  reset,
	input  coin_in,
	output reg in_status,
	output reg release_status
);

reg [23:0] timer;
reg  [1:0] state;

always @(posedge clk) begin

	if (reset) begin
		state <= 0;
		in_status <= 0;
		release_status <= 0;
	end else begin

		case (state)
		0:
		if (coin_in) begin
			timer <= 24'h3fffff;
			in_status <= 1;
			state <= 1;
		end

		1:
		if (timer != 0) timer <= timer - 1'd1;
		else begin
			in_status <= 0;
			release_status <= 1;
			timer <= 24'h3fffff;
			state <= 2;
		end

		2:
		if (timer != 0) timer <= timer - 1'd1;
		else begin
			release_status <= 0;
			state <= 0;
		end

		default : ;
		endcase

	end
end

endmodule

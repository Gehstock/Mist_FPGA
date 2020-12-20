//============================================================================
//  Arcade: Spy Hunter by DarFPGA
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

module SpyHunter_MiST(
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
	"SPYHUNT;;",
	"O2,Rotate Controls,Off,On;",
	"O5,Blend,Off,On;",
	"O6,Service,Off,On;",
	"O8,Demo Sounds,Off,On;",
	"O9,Show Lamps,Off,On;",
	"R2048,Save NVRAM;",
	"T0,Reset;",
	"V,v1.1.",`BUILD_DATE
};

wire rotate = status[2];
wire blend  = status[5];
wire service = status[6];
wire demosnd = status[8];
wire lamps   = status[9];

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_mem;
assign SDRAM_CKE = 1;

wire clk_sys, clk_mem;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
	.c1(clk_mem),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [15:0] joystick_0;
wire [15:0] joystick_1;
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

wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [12:0] snd_addr;
wire [15:0] snd_do;
wire [14:1] csd_addr;
wire [15:0] csd_do;
wire [14:0] sp_addr;
wire [31:0] sp_do;
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

// ROM structure:

//  0000 -  DFFF - Main ROM (8 bit)
//  E000 -  FFFF - Super Sound board ROM (8 bit)
// 10000 - 17FFF - CSD ROM (16 bit)
// 18000 - 37FFF - Sprite ROMs (32 bit)
// 38000 - 3FFFF - BG
// 40000 - 40FFF - Char

// spy-hunter_cpu_pg0_2-9-84.6d spy-hunter_cpu_pg1_2-9-84.7d spy-hunter_cpu_pg2_2-9-84.8d spy-hunter_cpu_pg3_2-9-84.9d spy-hunter_cpu_pg4_2-9-84.10d spy-hunter_cpu_pg5_2-9-84.11d
// spy-hunter_snd_0_sd_11-18-83.a7 spy-hunter_snd_1_sd_11-18-83.a8
// spy-hunter_cs_deluxe_u17_b_11-18-83.u17 spy-hunter_cs_deluxe_u18_d_11-18-83.u18 spy-hunter_cs_deluxe_u7_a_11-18-83.u7 spy-hunter_cs_deluxe_u8_c_11-18-83.u8
// spy-hunter_video_1fg_11-18-83.a7 spy-hunter_video_0fg_11-18-83.a8 spy-hunter_video_3fg_11-18-83.a5 spy-hunter_video_2fg_11-18-83.a6 spy-hunter_video_5fg_11-18-83.a3 spy-hunter_video_4fg_11-18-83.a4 spy-hunter_video_7fg_11-18-83.a1 spy-hunter_video_6fg_11-18-83.a2
// spy-hunter_cpu_bg0_11-18-83.3a spy-hunter_cpu_bg1_11-18-83.4a spy-hunter_cpu_bg2_11-18-83.5a spy-hunter_cpu_bg3_11-18-83.6a
// spy-hunter_cpu_alpha-n_11-18-83

wire [24:0] rom_ioctl_addr = ~ioctl_addr[16] ? ioctl_addr : // 8 bit ROMs
                             {ioctl_addr[24:16], ioctl_addr[15], ioctl_addr[13:0], ioctl_addr[14]}; // 16 bit ROM
wire [24:0] sp_ioctl_addr = ioctl_addr - 17'h18000;

reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_mem      ),

	// port1 used for main + sound CPUs
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( rom_ioctl_addr[23:1] ),
	.port1_ds      ( {rom_ioctl_addr[0], ~rom_ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, rom_addr[15:1]} ),
	.cpu1_q        ( rom_do ),
	// need higher priority for CSD
	.cpu2_addr     ( ioctl_downl ? 16'hffff : (16'h8000 + csd_addr[14:1]) ),
	.cpu2_q        ( csd_do ),
	.cpu3_addr     ( ioctl_downl ? 16'hffff : (16'h7000 + snd_addr[12:1]) ),
	.cpu3_q        ( snd_do ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {sp_ioctl_addr[23:17], sp_ioctl_addr[14:0], sp_ioctl_addr[16]} ), // merge sprite roms to 32-bit wide words
	.port2_ds      ( {sp_ioctl_addr[15], ~sp_ioctl_addr[15]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 15'h7fff : sp_addr ),
	.sp_q          ( sp_do )
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

// reset signal generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	reg [15:0] reset_count;
	ioctl_downlD <= ioctl_downl;

	// generate a second reset signal - needed for some reason
	if (status[0] | buttons[1] | ~rom_loaded) reset_count <= 16'hffff;
	else if (reset_count != 0) reset_count <= reset_count - 1'd1;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded | (reset_count == 16'h0001);

end

wire [15:0] audio_l, audio_r;
wire  [9:0] csd_audio;
wire        hs, vs, cs;
wire        blankn;
wire  [2:0] g, r, b;

spy_hunter_control spy_hunter_control(
	.clock_40(clk_sys),
	.reset(reset),
	.vsync(vs),
	.gas_plus(m_up),
	.gas_minus(m_down),
	.steering_plus(m_right),
	.steering_minus(m_left),
	.steering(steering),
	.gas(gas)
  );

spy_hunter spy_hunter(
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
	.csd_audio_out(csd_audio),
	.coin1(m_coin1),
	.coin2(m_coin2),	
	.shift(shift_state),
	.oil(oil),
	.missile(missile),
	.van(van),
	.smoke(smoke),
	.gun(gun),
	.steering(steering),
	.gas(gas),
	.timer(1),
	.show_lamps(lamps),	
	.demo_sound(demosnd),
	.service(service),
	.cpu_rom_addr ( rom_addr        ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.snd_rom_addr ( snd_addr        ),
	.snd_rom_do   ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),
	.csd_rom_addr ( csd_addr        ),
	.csd_rom_do   ( csd_do          ),
	.sp_addr      ( sp_addr         ),
	.sp_graphx32_do ( sp_do         ),
	.dl_addr      ( ioctl_addr[18:0]),
	.dl_data      ( ioctl_dout      ),
	.dl_wr        ( ioctl_wr && ioctl_index == 0 ),
	.up_data      ( ioctl_din       ),
	.cmos_wr      ( ioctl_wr && ioctl_index == 8'hff )
);

wire vs_out;
wire hs_out;
assign VGA_HS = (~no_csync & scandoublerD & ~ypbpr)? cs : hs_out;
assign VGA_VS = (~no_csync & scandoublerD & ~ypbpr)? 1'b1 : vs_out;

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
	.rotate         ( { 1'b1, rotate } ),
	.ce_divider     ( 1                ),
	.blend          ( blend            ),
	.scandoubler_disable(1),//scandoublerD ),
	.no_csync       ( 1'b1             ),
	.ypbpr          ( ypbpr            )
	);

dac #(
	.C_bits(16))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l + { csd_audio, 5'd0 }),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(16))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_r + { csd_audio, 5'd0 }),
	.dac_o(AUDIO_R)
	);	

wire  [7:0] steering;
wire  [7:0] gas;
wire        gun = m_fireA;
wire        missile = m_fireB;
wire        shift = m_fireC;
wire        van = m_fireD | btn_van;
wire        oil = m_fireE;
wire        smoke = m_fireF;
reg         shift_state;

input_toggle gearbox(clk_sys, m_coin1 | m_coin2, shift, shift_state);

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

reg btn_van = 0;
always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
			'h0D: btn_van 			 <= key_pressed; // TAB
		endcase
	end
end

endmodule 

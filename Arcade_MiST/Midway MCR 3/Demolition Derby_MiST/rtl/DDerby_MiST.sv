//============================================================================
//  Arcade: Demolition Derby by DarFPGA
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

module DDerby_MiST(
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
	"DDERBY;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Service,Off,On;",
	"O7,Swap Joystick,Off,On;",
	"O8,Players,2,4;",
	"O9,Difficulty,Normal,Hard;",
	"OA,Trophy Girl,Full,Limited;",
	"T0,Reset;",
	"V,v1.1.",`BUILD_DATE
};

wire   players4 = status[8];
wire   difficulty = status[9];
wire   girl = status[10];

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
wire  [7:0] joy_0;
wire  [7:0] joy_1;
wire  [7:0] joy_2;
wire  [7:0] joy_3;
wire        scandoublerD;
wire        ypbpr;
wire  [9:0] audio;
wire        hs, vs, cs;
wire        blankn;
wire  [2:0] g, r, b;
wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [14:0] snd_addr;
wire [15:0] snd_do;
wire [14:0] sp_addr;
wire [31:0] sp_do;
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

wire [24:0] sp_ioctl_addr = ioctl_addr - 17'h14000; //SP ROM offset: 0x11000

reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_mem      ),

	// port1 used for main + sound CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, rom_addr[15:1]} ),
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( cpu2_addr ),//Turbo Cheap Squeak
	.cpu2_q        ( snd_do ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {sp_ioctl_addr[14:0], sp_ioctl_addr[16]} ), // merge sprite roms to 32-bit wide words
	.port2_ds      ( {sp_ioctl_addr[15], ~sp_ioctl_addr[15]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 15'h7fff : sp_addr ),
	.sp_q          ( sp_do )
);

reg [15:0] cpu2_addr;

// ROM download controller
always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
	// register for better timings
	cpu2_addr <= ioctl_downl ? 16'hffff : (16'h8000 + snd_addr[14:1]);
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

wire [5:0] wheel1;
spinner spinner1 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(),
	.btn_left(m_left1),
	.btn_right(m_right1),
	.ctc_zc_to_2(vs),
	.spin_angle(wheel1)
);

wire [5:0] wheel2;
spinner spinner2 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(),
	.btn_left(m_left2),
	.btn_right(m_right2),
	.ctc_zc_to_2(vs),
	.spin_angle(wheel2)
);

wire [5:0] wheel3;
spinner spinner3 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(),
	.btn_left(m_left3),
	.btn_right(m_right3),
	.ctc_zc_to_2(vs),
	.spin_angle(wheel3)
);

wire [5:0] wheel4;
spinner spinner4 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(),
	.btn_left(m_left4),
	.btn_right(m_right4),
	.ctc_zc_to_2(vs),
	.spin_angle(wheel4)
);

dderby dderby(
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
	.separate_audio(1'b0),
	.audio_out(audio),
	.coin1(btn_coin),
	.coin2(btn_coin),
	.coin3(btn_coin),
	.coin4(btn_coin),
	
	.start4(btn_four_players),
	.start3(btn_three_players),
	.start2(btn_two_players),
	.start1(btn_one_player),
	
	.p1_fire1(m_fire1),
	.p1_fire2(m_fire1b),
	.p2_fire1(m_fire2),
	.p2_fire2(m_fire2b),
	.p3_fire1(m_fire3),
	.p3_fire2(m_fire3b),
	.p4_fire1(m_fire4),
	.p4_fire2(m_fire4b),

	.wheel1(wheel1),
	.wheel2(wheel2),
	.wheel3(wheel3),
	.wheel4(wheel4),

	.service(status[6]),
	.dipsw(~{3'b000, girl, 1'b0, difficulty, players4}), // NU, coins/credit, girl, free play, difficulty, 2player
	.cpu_rom_addr ( rom_addr        ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.snd_rom_addr ( snd_addr        ),
	.snd_rom_do   ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),
	.sp_addr      ( sp_addr         ),
	.sp_graphx32_do ( sp_do         )
);

wire vs_out;
wire hs_out;
assign VGA_VS = scandoublerD | vs_out;
assign VGA_HS = scandoublerD ? cs : hs_out;

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
	.rotate         ( {1'b1,status[2]} ),
	.ce_divider     ( 1                ),
	.blend          ( status[5]        ),
	.scandoubler_disable(1),//scandoublerD ),
	.no_csync       ( 1'b1             ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);

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
	.joystick_0     (joy_0          ),
	.joystick_1     (joy_1          ),
	.joystick_2     (joy_2          ),
	.joystick_3     (joy_3          ),
	.status         (status         )
	);

dac #(10) dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
assign AUDIO_R = AUDIO_L;

wire  [7:0] joystick_0 = status[7] ? joy_1 : joy_0;
wire  [7:0] joystick_1 = status[7] ? joy_0 : joy_1;

//											Rotated														Normal
wire m_left1   = btn_left  | joystick_0[1];
wire m_right1  = btn_right | joystick_0[0];
wire m_fire1   = btn_fire1 | joystick_0[4];
wire m_fire1b  = btn_fire2 | joystick_0[5];

wire m_left2   = joystick_1[1];
wire m_right2  = joystick_1[0];
wire m_fire2   = joystick_1[4];
wire m_fire2b  = joystick_1[5];

wire m_left3   = joy_2[1];
wire m_right3  = joy_2[0];
wire m_fire3   = joy_2[4];
wire m_fire3b  = joy_2[5];

wire m_left4   = joy_3[1];
wire m_right4  = joy_3[0];
wire m_fire4   = joy_3[4];
wire m_fire4b  = joy_3[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_three_players = 0;
reg btn_four_players = 0;
reg btn_left = 0;
reg btn_right = 0;
//reg btn_down = 0;
//reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;
wire       key_pressed;
wire [7:0] key_code;
wire       key_strobe;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
//			'h75: btn_up          <= key_pressed; // up
//			'h72: btn_down        <= key_pressed; // down
			'h6B: btn_left        <= key_pressed; // left
			'h74: btn_right       <= key_pressed; // right
			'h76: btn_coin        <= key_pressed; // ESC
			'h05: btn_one_player  <= key_pressed; // F1
			'h06: btn_two_players <= key_pressed; // F2
			'h04: btn_three_players  <= key_pressed; // F3
			'h0C: btn_four_players <= key_pressed; // F4
//			'h14: btn_fire3       <= key_pressed; // ctrl
			'h11: btn_fire2       <= key_pressed; // alt
			'h29: btn_fire1       <= key_pressed; // Space
		endcase
	end
end

endmodule 

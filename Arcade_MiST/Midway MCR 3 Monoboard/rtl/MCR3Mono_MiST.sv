//============================================================================
//  MCR3 monoboard arcades top-level for MiST
//  Sarge/Max RPM/Rampage/Power Drive
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

module MCR3Mono_MiST(
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

// Uncomment one to build with game-specific core name/inputs/sound board
`define CORE_NAME "SARGE"
//`define CORE_NAME "MAXRPM"
//`define CORE_NAME "RAMPAGE"
//`define CORE_NAME "POWERDRV"

reg       sg; // Sounds Good board
reg [7:0] input0;
reg [7:0] input1;
reg [7:0] input2;
reg [7:0] input3;
reg [7:0] input4;
reg [7:0] output5;
reg [7:0] output6;

// Game specific sound board/DIP/input settings
always @(*) begin
	if (`CORE_NAME == "SARGE" ||
	    `CORE_NAME == "MAXRPM")
		sg = 0;
	else
		sg = 1;

	input0 = 8'hff;
	input1 = 8'hff;
	input2 = 8'hff;
	input3 = 8'hff;
	input4 = 8'hff;

	if (`CORE_NAME == "SARGE") begin
		// Two stick/player like the original
		input0 = ~{2'b00, service, 1'b0, m_start2, m_start1, m_coin2, m_coin1};
		input1 = ~{m_fire1 | m_fire1b, m_fire1 | m_fire1b, m_fire2 | m_fire2b, m_fire2 | m_fire2b, m_down1, m_up1, m_down2, m_up2};
		input2 = ~{m_fire3 | m_fire3b, m_fire3 | m_fire3b, m_fire4 | m_fire4b, m_fire4 | m_fire4b, m_down3, m_up3, m_down4, m_up4};
	end else if (`CORE_NAME == "MAXRPM") begin
		input0 = ~{service, 3'b000, m_start1, m_start2, m_coin1, m_coin2};
		input1 =  {pedal1[5:2], pedal2[5:2]};
		input2 = ~{maxrpm_gear1, maxrpm_gear2};
	end else if (`CORE_NAME == "RAMPAGE") begin
		// normal controls for 3 players
		input0 = ~{2'b00, service, 1'b0, 2'b00, m_coin2, m_coin1};
		input1 = ~{2'b00, m_fire1b, m_fire1, m_left1, m_down1, m_right1, m_up1};
		input2 = ~{2'b00, m_fire2b, m_fire2, m_left2, m_down2, m_right2, m_up2};
		input4 = ~{2'b00, m_fire3b, m_fire3, m_left3, m_down3, m_right3, m_up3};
	end else if (`CORE_NAME == "POWERDRV") begin
		// Controls for 3 players using 4 buttons/joystick
		input0 = ~{2'b00, service, 1'b0, 1'b0, m_coin3, m_coin2, m_coin1};
		input1 = ~{m_fire2b, m_fire2, powerdrv_gear[1], m_fire2c, m_fire1b, m_fire1, powerdrv_gear[0], m_fire1c};
		input2 = ~{sndstat[0], 3'b000, m_fire3b, m_fire3, powerdrv_gear[2], m_fire3c};
	end
end

localparam CONF_STR = {
	`CORE_NAME,";ROM;",
	"O2,Rotate Controls,Off,On;",
	"O5,Blend,Off,On;",
	"O6,Swap Joystick,Off,On;",
	"O7,Service,Off,On;",
	"T0,Reset;",
	"V,v1.1.",`BUILD_DATE
};

wire       blend     = status[5];
wire       joyswap   = status[6];
wire       service   = status[7];

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

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

/*
ROM structure:

Sarge, MaxRPM (Turbo Cheap Squeak board):
00000-0FFFF MAIN CPU 64k
10000-2FFFF GFX2 (Sprites) 128k
30000-37FFF GFX1 32k
38000-      TCS  32k

Rampage, Power Drive (Sounds Good board):
00000-0FFFF MAIN CPU 64k
10000-4FFFF GFX2 (Sprites) 256k
50000-57FFF GFX1 32k
58000-      SG   128k
*/

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

wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [17:0] snd_addr;
wire [15:0] snd_do;
wire [15:0] sp_addr;
wire [31:0] sp_do;
wire [24:0] sp_ioctl_addr = ioctl_addr - 17'h10000; 
wire [24:0] snd_ioctl_addr = ioctl_addr - snd_offset;
reg         port1_req, port2_req;
reg  [23:0] port1_a;
reg  [23:0] port2_a;
reg  [19:0] snd_offset;
reg  [19:0] gfx1_offset;

always @(*) begin
	if (sg) begin
		snd_offset  = 20'h58000;
		gfx1_offset = 20'h50000;
		port1_a = ioctl_addr[23:0];
		port1_a = (ioctl_addr < snd_offset) ? ioctl_addr[23:0] : // 8 bit main ROM
              snd_offset + {snd_ioctl_addr[17], snd_ioctl_addr[15:0], snd_ioctl_addr[16]}; // 16 bit Sounds Good ROM

		// merge sprite roms (4x64k) into 32-bit wide words
		port2_a     = {sp_ioctl_addr[23:18], sp_ioctl_addr[15:0], sp_ioctl_addr[17:16]}; 
	end else begin
		snd_offset  = 20'h38000;
		gfx1_offset = 20'h30000;
		port1_a = ioctl_addr[23:0];
		// merge sprite roms (4x32k) into 32-bit wide words
		port2_a     = {sp_ioctl_addr[23:17], sp_ioctl_addr[14:0], sp_ioctl_addr[16:15]};
	end
end

sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_mem      ),

	// port1 used for main + sound CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( port1_a[23:1] ),
	.port1_ds      ( {port1_a[0], ~port1_a[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( cpu1_addr ), //Turbo Cheap Squeak/Sounds Good with higher priority
	.cpu1_q        ( snd_do ),
	.cpu2_addr     ( ioctl_downl ? 18'h3ffff : {3'b000, rom_addr[15:1]} ),
	.cpu2_q        ( rom_do ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( port2_a[23:1] ), 
	.port2_ds      ( {port2_a[0], ~port2_a[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 16'hffff : sp_addr ),
	.sp_q          ( sp_do )
);

reg [19:1] cpu1_addr;

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
	cpu1_addr <= ioctl_downl ? 19'h7ffff : (snd_offset[19:1] + snd_addr[17:1]);
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
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded | (reset_count == 16'h0001);
end

wire [1:0] sndstat;

mcr3mono mcr3mono (
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

	.soundsgood(sg),
	.snd_stat(sndstat),
	.audio_out(audio),

	.input_0(input0),
	.input_1(input1),
	.input_2(input2),
	.input_3(input3),
	.input_4(input4),
	.output_5(output5),
	.output_6(output6),

	.cpu_rom_addr ( rom_addr        ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.snd_rom_addr ( snd_addr        ),
	.snd_rom_do   ( snd_do          ),
	.sp_addr      ( sp_addr         ),
	.sp_graphx32_do ( sp_do         ),

	.dl_addr(ioctl_addr-gfx1_offset),
	.dl_data(ioctl_dout),
	.dl_wr(ioctl_wr)
);

wire vs_out;
wire hs_out;
assign VGA_VS = scandoublerD | vs_out;
assign VGA_HS = scandoublerD ? cs : hs_out;

mist_video #(.COLOR_DEPTH(3)) mist_video(
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
	.blend          ( blend            ),
	.scandoubler_disable(1),//scandoublerD ),
	.no_csync       ( 1'b1             ),
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

wire  [7:0] joystick_0 = joyswap ? joy_1 : joy_0;
wire  [7:0] joystick_1 = joyswap ? joy_0 : joy_1;

// Power Drive gear
reg  [2:0] powerdrv_gear;
always @(posedge clk_sys) begin
	reg [2:0] gear_old;
	if (reset) powerdrv_gear <= 0;
	else begin
		gear_old <= {m_fire3d, m_fire2d, m_fire1d};
		if (~gear_old[0] & m_fire1d) powerdrv_gear[0] <= ~powerdrv_gear[0];
		if (~gear_old[1] & m_fire2d) powerdrv_gear[1] <= ~powerdrv_gear[1];
		if (~gear_old[2] & m_fire3d) powerdrv_gear[2] <= ~powerdrv_gear[2];
	end
end

//Pedals for Max RPM
wire [5:0] pedal1;
spinner spinner1 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(),
	.btn_left(m_up1),
	.btn_right(m_down1),
	.ctc_zc_to_2(vs),
	.spin_angle(pedal1)
);

wire [5:0] pedal2;
spinner spinner2 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(),
	.btn_left(m_up2),
	.btn_right(m_down2),
	.ctc_zc_to_2(vs),
	.spin_angle(pedal2)
);

// MaxRPM gearbox
wire [3:0] maxrpm_gear_bits[5] = '{ 4'h0, 4'h5, 4'h6, 4'h1, 4'h2 };
wire [3:0] maxrpm_gear1 = maxrpm_gear_bits[gear1];
wire [3:0] maxrpm_gear2 = maxrpm_gear_bits[gear2];
reg  [2:0] gear1;
reg  [2:0] gear2;
always @(posedge clk_sys) begin
	reg m_fire1_last, m_fire1b_last;
	reg m_fire2_last, m_fire2b_last;

	if (reset) begin
		gear1 <= 0;
		gear2 <= 0;
	end else begin
		m_fire1_last <= m_fire1;
		m_fire1b_last <= m_fire1b;
		m_fire2_last <= m_fire2;
		m_fire2b_last <= m_fire2b;

		if (m_start1) gear1 <= 0;
		else if (~m_fire1_last && m_fire1 && gear1 != 3'd4) gear1 <= gear1 + 1'd1;
		else if (~m_fire1b_last && m_fire1b && gear1 != 3'd0) gear1 <= gear1 - 1'd1;

		if (m_start2) gear2 <= 0;
		else if (~m_fire2_last && m_fire2 && gear2 != 3'd4) gear2 <= gear2 + 1'd1;
		else if (~m_fire2b_last && m_fire2b && gear2 != 3'd0) gear2 <= gear2 - 1'd1;
	end
end

// Generic controls - make a module from this?
wire m_coin1   = btn_coin1_mame  | btn_coin;
wire m_start1  = btn_start1_mame | btn_one_player;
wire m_up1     = btn_up    | joystick_0[3];
wire m_down1   = btn_down  | joystick_0[2];
wire m_left1   = btn_left  | joystick_0[1];
wire m_right1  = btn_right | joystick_0[0];
wire m_fire1   = btn_fireA | joystick_0[4];
wire m_fire1b  = btn_fireB | joystick_0[5];
wire m_fire1c  = btn_fireC | joystick_0[6];
wire m_fire1d  = btn_fireD | joystick_0[7];

wire m_coin2   = btn_coin2_mame  | btn_coin;
wire m_start2  = btn_start2_mame | btn_two_players;
wire m_left2   = btn_left2  | joystick_1[1];
wire m_right2  = btn_right2 | joystick_1[0];
wire m_up2     = btn_up2    | joystick_1[3];
wire m_down2   = btn_down2  | joystick_1[2];
wire m_fire2   = btn_fire2A | joystick_1[4];
wire m_fire2b  = btn_fire2B | joystick_1[5];
wire m_fire2c  = btn_fire2C | joystick_1[6];
wire m_fire2d  = btn_fire2D | joystick_1[7];

wire m_coin3   = btn_coin3_mame  | btn_coin;
wire m_start3  = btn_start3_mame | btn_three_players;
wire m_left3   = joy_2[1];
wire m_right3  = joy_2[0];
wire m_up3     = joy_2[3];
wire m_down3   = joy_2[2];
wire m_fire3   = joy_2[4];
wire m_fire3b  = joy_2[5];
wire m_fire3c  = joy_2[6];
wire m_fire3d  = joy_2[7];

wire m_coin4   = btn_coin4_mame  | btn_coin;
wire m_start4  = btn_start4_mame | btn_four_players;
wire m_left4   = joy_3[1];
wire m_right4  = joy_3[0];
wire m_up4     = joy_3[3];
wire m_down4   = joy_3[2];
wire m_fire4   = joy_3[4];
wire m_fire4b  = joy_3[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_three_players = 0;
reg btn_four_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fireA = 0;
reg btn_fireB = 0;
reg btn_fireC = 0;
reg btn_fireD = 0;
reg btn_coin  = 0;
reg btn_start1_mame = 0;
reg btn_start2_mame = 0;
reg btn_start3_mame = 0;
reg btn_start4_mame = 0;
reg btn_coin1_mame = 0;
reg btn_coin2_mame = 0;
reg btn_coin3_mame = 0;
reg btn_coin4_mame = 0;
reg btn_up2 = 0;
reg btn_down2 = 0;
reg btn_left2 = 0;
reg btn_right2 = 0;
reg btn_fire2A = 0;
reg btn_fire2B = 0;
reg btn_fire2C = 0;
reg btn_fire2D = 0;

wire       key_pressed;
wire [7:0] key_code;
wire       key_strobe;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up            <= key_pressed; // up
			'h72: btn_down          <= key_pressed; // down
			'h6B: btn_left          <= key_pressed; // left
			'h74: btn_right         <= key_pressed; // right
			'h76: btn_coin          <= key_pressed; // ESC
			'h05: btn_one_player    <= key_pressed; // F1
			'h06: btn_two_players   <= key_pressed; // F2
			'h04: btn_three_players <= key_pressed; // F3
			'h0C: btn_four_players  <= key_pressed; // F4
			'h12: btn_fireD         <= key_pressed; // l-shift
			'h14: btn_fireC         <= key_pressed; // ctrl
			'h11: btn_fireB         <= key_pressed; // alt
			'h29: btn_fireA         <= key_pressed; // Space
			// JPAC/IPAC/MAME Style Codes
			'h16: btn_start1_mame   <= key_pressed; // 1
			'h1E: btn_start2_mame   <= key_pressed; // 2
			'h26: btn_start3_mame   <= key_pressed; // 3
			'h25: btn_start4_mame   <= key_pressed; // 4
			'h2E: btn_coin1_mame    <= key_pressed; // 5
			'h36: btn_coin2_mame    <= key_pressed; // 6
			'h3D: btn_coin3_mame    <= key_pressed; // 7
			'h3E: btn_coin4_mame    <= key_pressed; // 8
			'h2D: btn_up2           <= key_pressed; // R
			'h2B: btn_down2         <= key_pressed; // F
			'h23: btn_left2         <= key_pressed; // D
			'h34: btn_right2        <= key_pressed; // G
			'h1C: btn_fire2A        <= key_pressed; // A
			'h1B: btn_fire2B        <= key_pressed; // S
			'h21: btn_fire2C        <= key_pressed; // Q
			'h1D: btn_fire2D        <= key_pressed; // W
		endcase
	end
end

endmodule 

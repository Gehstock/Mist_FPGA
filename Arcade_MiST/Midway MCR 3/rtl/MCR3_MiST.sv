//============================================================================
//  MCR3 arcades top-level for MiST
//  Sarge/Max RPM/Rampage/Power Drive/Demolition Derby
//  Timber/Tapper/Discs of Tron
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

module MCR3_MiST(
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

`define CORE_NAME "RAMPAGE"
wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O2,Rotate Controls,Off,On;",
	"O5,Blend,Off,On;",
	"O6,Swap Joystick,Off,On;",
	"DIP;",
	"O7,Service,Off,On;",
	"R2048,Save NVRAM;",
	"T0,Reset;",
	"V,v1.1.",`BUILD_DATE
};

wire       rotate    = status[2];
wire       blend     = status[5];
wire       joyswap   = status[6];
wire       service   = status[7];

localparam SND_SSB = 2'd0;
localparam SND_TCS = 2'd1;
localparam SND_SG  = 2'd2;

reg       hflip;
reg       monoboard;
reg [1:0] soundboard;
reg [7:0] input0;
reg [7:0] input1;
reg [7:0] input2;
reg [7:0] input3;
reg [7:0] input4;
reg [7:0] output5;
reg [7:0] output6;

// Game specific sound board/DIP/input settings
always @(*) begin

	hflip = 0;
	monoboard = 1;
	soundboard = SND_SSB;
	input0 = 8'hff;
	input1 = 8'hff;
	input2 = 8'hff;
	input3 = 8'hff;
	input4 = 8'hff;

	case (core_mod)
	7'h0: // RAMPAGE
	begin
		soundboard = SND_SG;
		// normal controls for 3 players
		input0 = ~{2'b00, service, 1'b0, 2'b00, m_coin2, m_coin1};
		input1 = ~{2'b00, m_fireB, m_fireA, m_left, m_down, m_right, m_up};
		input2 = ~{2'b00, m_fire2B, m_fire2A, m_left2, m_down2, m_right2, m_up2};
		input3 = ~{/*cheat*/status[11], /*coin B*/3'b000, /*coin A*/1'b0, /*score opt*/status[10], /*difficulty*/status[9:8]};
		input4 = ~{2'b00, m_fire3B, m_fire3A, m_left3, m_down3, m_right3, m_up3};
	end
	7'h1: // SARGE
	begin
		soundboard = SND_TCS;
		// Two stick/player like the original
		input0 = ~{2'b00, service, 1'b0, m_two_players, m_one_player, m_coin2, m_coin1};
		input1 = ~{{2{sarge_fire1B}}, {2{sarge_fire1A}}, sarge_down2, sarge_up2, sarge_down1, sarge_up1};
		input2 = ~{{2{sarge_fire2B}}, {2{sarge_fire2A}}, sarge_down3, sarge_up3, sarge_down4, sarge_up4};
		input3 = ~{2'b00, /*coinage*/2'b00, /*free play*/status[8], 3'b000};
	end
	7'h2: //POWERDRV
	begin
		soundboard = SND_SG;
		// Controls for 3 players using 4 buttons/joystick
		input0 = ~{2'b00, service, 1'b0, 1'b0, m_coin3, m_coin2, m_coin1};
		input1 = ~{m_fire2B, m_fire2A, powerdrv_gear[1], m_fire2C, m_fireB, m_fireA, powerdrv_gear[0], m_fireC};
		input2 = ~{sndstat[0], 3'b000, m_fire3B, m_fire3A, powerdrv_gear[2], m_fire3C};
		input3 = ~{/*cheat*/status[11], /*demosnd*/status[10], /*difficulty*/status[9:8], 1'b0, /*coinage*/2'b00};
	end
	7'h3: // MAXRPM
	begin
		soundboard = SND_TCS;
		input0 = ~{service, 3'b000, m_one_player, m_two_players, m_coin1, m_coin2};
		input1 = ~{maxrpm_adc_data};
		input2 = ~{maxrpm_gear1, maxrpm_gear2};
		input3[0] = ~status[8]; // free play
	end
	7'h4: // DEMODERB
	begin
		soundboard = SND_TCS;
		input0 = ~{2'b00, service, 1'b0, m_two_players, m_one_player, m_coin2, m_coin1};
		input1 = dderby_input_sel ? ~{wheel3, m_fireB,  m_fireA}  : ~{wheel1, m_fireB,  m_fireA};
		input2 = dderby_input_sel ? ~{wheel4, m_fire2B, m_fire2A} : ~{wheel2, m_fire2B, m_fire2A};
		input3 = ~{3'b000, status[11], status[10], status[9], status[8]}; // NU, coins/credit, girl, free play, difficulty, 2player
		input4 = ~{m_fire4B, m_fire4A, m_fire3B, m_fire3A, m_four_players, m_three_players, m_coin4, m_coin3};
	end
	7'h6, 7'h7: // TIMBER, TAPPER
	begin
		soundboard = SND_SSB;
		monoboard = 0;
		input0 = ~{service, 3'b000, m_two_players, m_one_player, m_coin2, m_coin1};
		input1 = ~{2'b00, m_fireB, m_fireA, m_up, m_down, m_left, m_right};
		input2 = ~{2'b00, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2};
		input3 = ~{/*coin meters*/1'b0, /*upright*/status[9], 3'b000, /*demosnd*/status[10], 2'b00};
	end
	7'h8: // DOTRON
	begin
		soundboard = SND_SSB;
		monoboard = 0;
		hflip = 1;
		input0 = ~{service, 2'b00, m_fireA | m_down2, m_two_players, m_one_player, m_coin2, m_coin1};
		input1 = ~{1'b0, dotron_spinner};
		input2 = ~{1'b0, m_fireB, m_fireD, m_fireC, m_down, m_up, m_right, m_left};
	end

	default: ;
	endcase
end

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
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire [31:0] joystick_2;
wire [31:0] joystick_3;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)),
	.ROM_DIRECT_UPLOAD(1))
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
	.joystick_2     (joystick_2     ),
	.joystick_3     (joystick_3     ),
	.status         (status         )
	);

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

/*
ROM structure:

Sarge, MaxRPM, Demolition Derby (Turbo Cheap Squeak board):
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

data_io #(.ROM_DIRECT_UPLOAD(1)) data_io(
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
	if (soundboard == SND_SG) begin
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
		if (~ioctl_wr_last && ioctl_wr && ioctl_index == 0) begin
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

wire  [1:0] sndstat;
wire  [9:0] audio;
wire [15:0] audio_l;
wire [15:0] audio_r;
wire        hs, vs, cs;
wire        blankn;
wire  [2:0] g, r, b;

mcr3 mcr3 (
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

	.soundboard(soundboard),
	.snd_stat(sndstat),
	.audio_out(audio),
	.audio_out_l(audio_l),
	.audio_out_r(audio_r),

	.monoboard(monoboard),
	.h_flip(hflip),

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

	.dl_addr      ( ioctl_addr-(ioctl_index == 0 ? gfx1_offset : 0) ),
	.dl_data      ( ioctl_dout ),
	.dl_wr        ( ioctl_wr && ioctl_index == 0 ),
	.up_data      ( ioctl_din  ),
	.cmos_wr      ( ioctl_wr && ioctl_index == 8'hff )
);

wire vs_out;
wire hs_out;
assign VGA_HS = (~no_csync & scandoublerD & ~ypbpr)? cs : hs_out;
assign VGA_VS = (~no_csync & scandoublerD & ~ypbpr)? 1'b1 : vs_out;

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
	.dac_i(audio_l + { audio, 5'd0 }),
	.dac_o(AUDIO_L)
);

dac #(
	.C_bits(16))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_r + { audio, 5'd0 }),
	.dac_o(AUDIO_R)
);

// Sarge controls
wire       onestick = status[9];
wire       sarge_up1, sarge_up2, sarge_up3, sarge_up4;
wire       sarge_down1, sarge_down2, sarge_down3, sarge_down4;
wire       sarge_fire1A, sarge_fire1B, sarge_fire2A, sarge_fire2B;

always @(*) begin
	if (~onestick) begin
		sarge_up1 = m_up;
		sarge_up2 = m_up2 | m_upB;
		sarge_up3 = m_up3;
		sarge_up4 = m_up4 | m_up3B;
		sarge_down1 = m_down;
		sarge_down2 = m_down2 | m_downB;
		sarge_down3 = m_down3;
		sarge_down4 = m_down4 | m_down3B;
		sarge_fire1A = m_fireA | m_fire2A;
		sarge_fire1B = m_fireB | m_fire2B;
		sarge_fire2A = m_fire3A | m_fire4A;
		sarge_fire2B = m_fire3B | m_fire4B;
	end else begin
		sarge_up1 =   (m_up & ~m_left)      | (m_right & ~m_down);
		sarge_up2 =   (m_up & ~m_right)     | (m_left  & ~m_down);
		sarge_down1 = (m_down & ~m_right)   | (m_left  & ~m_up);
		sarge_down2 = (m_down & ~m_left)    | (m_right & ~m_up);
		sarge_up3   = (m_up2 & ~m_left2)    | (m_right2 & ~m_down2);
		sarge_up4 =   (m_up2 & ~m_right2)   | (m_left2  & ~m_down2);
		sarge_down3 = (m_down2 & ~m_right2) | (m_left2  & ~m_up2);
		sarge_down4 = (m_down2 & ~m_left2)  | (m_right2 & ~m_up2);
		sarge_fire1A = m_fireA;
		sarge_fire1B = m_fireB;
		sarge_fire2A = m_fire2A;
		sarge_fire2B = m_fire2B;
	end
end

// Power Drive gear
reg  [2:0] powerdrv_gear;
always @(posedge clk_sys) begin
	reg [2:0] gear_old;
	if (reset) powerdrv_gear <= 0;
	else begin
		gear_old <= {m_fire3D, m_fire2D, m_fireD};
		if (~gear_old[0] & m_fireD) powerdrv_gear[0] <= ~powerdrv_gear[0];
		if (~gear_old[1] & m_fire2D) powerdrv_gear[1] <= ~powerdrv_gear[1];
		if (~gear_old[2] & m_fire3D) powerdrv_gear[2] <= ~powerdrv_gear[2];
	end
end

//Pedals/Steering for Max RPM
reg [7:0] maxrpm_adc_data;
reg [3:0] maxrpm_adc_control;
always @(*) begin
	case (maxrpm_adc_control[1:0])
		2'b00: maxrpm_adc_data = gas2;
		2'b01: maxrpm_adc_data = gas1;
		2'b10: maxrpm_adc_data = steering2;
		2'b11: maxrpm_adc_data = steering1;
	endcase
end

always @(posedge clk_sys) if (~output6[6] & ~output6[5]) maxrpm_adc_control <= output5[4:1];

wire [7:0] gas1;
wire [7:0] steering1;
spy_hunter_control maxrpm_pl1 (
	.clock_40(clk_sys),
	.reset(reset),
	.vsync(vs),
	.gas_plus(m_up),
	.gas_minus(m_down),
	.steering_plus(m_right),
	.steering_minus(m_left),
	.steering(steering1),
	.gas(gas1)
	);

wire [7:0] gas2;
wire [7:0] steering2;
spy_hunter_control maxrpm_pl2 (
	.clock_40(clk_sys),
	.reset(reset),
	.vsync(vs),
	.gas_plus(m_up2),
	.gas_minus(m_down2),
	.steering_plus(m_right2),
	.steering_minus(m_left2),
	.steering(steering2),
	.gas(gas2)
	);

// MaxRPM gearbox
wire [3:0] maxrpm_gear_bits[5] = '{ 4'h0, 4'h5, 4'h6, 4'h1, 4'h2 };
wire [3:0] maxrpm_gear1 = maxrpm_gear_bits[gear1];
wire [3:0] maxrpm_gear2 = maxrpm_gear_bits[gear2];
reg  [2:0] gear1;
reg  [2:0] gear2;
always @(posedge clk_sys) begin
	reg m_fireA_last, m_fireB_last;
	reg m_fire2A_last, m_fire2B_last;

	if (reset) begin
		gear1 <= 0;
		gear2 <= 0;
	end else begin
		m_fireA_last <= m_fireA;
		m_fireB_last <= m_fireB;
		m_fire2A_last <= m_fire2A;
		m_fire2B_last <= m_fire2B;

		if (m_one_player) gear1 <= 0;
		else if (~m_fireA_last && m_fireA && gear1 != 3'd4) gear1 <= gear1 + 1'd1;
		else if (~m_fireB_last && m_fireB && gear1 != 3'd0) gear1 <= gear1 - 1'd1;

		if (m_two_players) gear2 <= 0;
		else if (~m_fire2A_last && m_fire2A && gear2 != 3'd4) gear2 <= gear2 + 1'd1;
		else if (~m_fire2B_last && m_fire2B && gear2 != 3'd0) gear2 <= gear2 - 1'd1;
	end
end

// Demolition Derby
reg dderby_input_sel;
always @(posedge clk_sys) begin
	if (reset)
		dderby_input_sel <= 0;
	else begin
		if (output6[7]) dderby_input_sel <= 0;
		else if (output6[6]) dderby_input_sel <= 1;
	end
end

wire [5:0] wheel1, wheel2, wheel3, wheel4;
spinner spinner1 (clk_sys, reset, m_left,  m_right,  1'b0, vs, wheel1);
spinner spinner2 (clk_sys, reset, m_left2, m_right2, 1'b0, vs, wheel2);
spinner spinner3 (clk_sys, reset, m_left3, m_right3, 1'b0, vs, wheel3);
spinner spinner4 (clk_sys, reset, m_left4, m_right4, 1'b0, vs, wheel4);

// dotron spinner
wire [5:0] dotron_spinner;
spinner #(15) dotron_spn (clk_sys, reset, m_fireE | m_fireG | m_leftB, m_fireF | m_fireH | m_rightB, 1'b0, vs, dotron_spinner);

// Common inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG, m_fireH, m_upB, m_downB, m_leftB, m_rightB;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G, m_fire2H, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F, m_fire3G, m_fire3H, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F, m_fire4G, m_fire4H, m_up4B, m_down4B, m_left4B, m_right4B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joystick_2  ( joystick_2  ),
	.joystick_3  ( joystick_3  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b10       ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_upB, m_downB, m_leftB, m_rightB, 4'd0, m_fireH, m_fireG, m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, 4'd0, m_fire2H, m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, 4'd0, m_fire3H, m_fire3G, m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, 4'd0, m_fire4H, m_fire4G, m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 

/*============================================================================
	FPGA implementation of Blockade by Gremlin Industries for MiSTer

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-02-13

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/

`timescale 1 ps / 1 ps

module blockade (
	input clk,
	input reset,
	input pause,
	input [1:0] game_mode,

	output ce_pix,
	output video,
	output vsync,
	output hsync,
	output vblank,
	output hblank,

	output signed [15:0] audio_l,
	output signed [15:0] audio_r,

	input [7:0] in_1,
	input [7:0] in_2,
	input [7:0] in_4,
	input coin,

	input [13:0] dn_addr,
	input 		 dn_wr,
	input [7:0]  dn_data
);

// Game mode constants
localparam GAME_BLOCKADE = 0;
localparam GAME_COMOTION = 1;
localparam GAME_HUSTLE = 2;
localparam GAME_BLASTO = 3;
localparam GAME_MINESWEEPER = 4;
localparam GAME_MINESWEEPER4 = 5;

localparam COIN_START_TIMER_WIDTH = 6;
reg [COIN_START_TIMER_WIDTH-1:0] coin_start;

localparam COIN_LATCH_TIMER_WIDTH = 6;
reg [COIN_LATCH_TIMER_WIDTH-1:0] coin_latch;

// CPU and Video system clock enables
// ----------------------------------

// - Replaces U31, U17, U8, U18 section of circuit
reg [3:0] phi_count;
reg [1:0] vid_count;
always @(posedge clk) begin
	// Phi counter is 0-9, generates PHI_1 and PHI_2 enable signals for CPU
	phi_count <= (phi_count == 4'd9) ? 4'b0 : phi_count + 1'b1;
	// Video counter is 0-3, generates ce_vid and ce_pix signals for video circuit
	vid_count <= vid_count + 2'b1;
end
// Video and pixel clock every 4 cycles of system clock
// - Video system clock one cycle ahead of pixel clock so video memory reads have time to complete
wire ce_vid = (vid_count == 2'd0);
assign ce_pix = (vid_count == 2'd3);
// 8080A CPU timing
// PHI1: XX--------
// PHI2: ---XXXXXX-
wire PHI_1 = phi_count[3:1] == 3'b000;
wire PHI_2 = phi_count >= 4'd3 && phi_count <= 4'd8;

// U21 - Video RAM address select
wire a12_n_a15 = ADDR[15] && ~ADDR[12];


// CPU
// ---

// U9 D flip-flop - Disables CPU using READY signal when attempting to write VRAM during vblank
reg u9_q;
reg PHI_2_last;
always @(posedge clk) begin
	if(reset) 
		u9_q <= 1'b1;
	else
		if(PHI_2) u9_q <= ~(VBLANK_N && a12_n_a15);
end

// Input data address selector
wire INP_1 = INP && ADDR[0];
wire INP_2 = INP && ADDR[1];
wire INP_4 = INP && ADDR[2];

// CPU data in mux
wire [7:0] cpu_data_in = INP_1 ? { ~(coin_latch > 6'b0), in_1[6:0] } :
						 INP_2 ? in_2 :
						 INP_4 ? in_4 :
						 rom1_cs ? rom1_data_out :
						 rom2_cs ? rom2_data_out :
						 vram_cs ? vram_data_out_cpu :
						 sram_cs ? sram_data_out :
						 8'h00;

// CPU signals
wire [15:0] ADDR;
wire [7:0] DATA;
wire DBIN;
wire WR_N;
wire SYNC /*verilator public_flat*/;

// CPU reset can originate from system reset signal or coin start signal (only for CoMotion, Hustle, and Blasto)
//wire RESET = reset || (game_mode != GAME_BLOCKADE && coin_start > 6'b0);
wire RESET = reset || (game_mode != GAME_BLOCKADE && coin_start > {COIN_START_TIMER_WIDTH{1'b0}});

// 8080A CPU
vm80a cpu
(
	.pin_clk(clk),
	.pin_f1(PHI_1),
	.pin_f2(PHI_2),
	.pin_reset(RESET),
	.pin_a(ADDR),
	.pin_d(DATA),
	.pin_hold(1'b0),
	.pin_hlda(),
	.pin_ready(u9_q && !pause),
	.pin_wait(),
	.pin_int(1'b0),
	.pin_inte(),
	.pin_sync(SYNC),
	.pin_dbin(DBIN),
	.pin_wr_n(WR_N)
);

// Handle CPU in/out data buffer
assign DATA = DBIN ? cpu_data_in: 8'hZZ;
reg [7:0] cpu_data_out;
always @(posedge clk) begin
	if(!WR_N) cpu_data_out <= DATA;
end

// Video timing generator
// ----------------------
// - Constants
localparam HBLANK_START = 9'd255;
localparam HSYNC_START = 9'd272;
localparam HSYNC_END = 9'd300;
localparam HRESET_LINE = 9'd329;
localparam VSYNC_START = 9'd238;
localparam VSYNC_END = 9'd248;
localparam VBLANK_START = 9'd224;
localparam VBLANK_END = 9'd261;
localparam VRESET_LINE = 9'd261;

// Video counters
reg [8:0] hcnt;
reg [8:0] vcnt;

// Video event signals
reg HBLANK_N = 1'b1;
reg HSYNC_N = 1'b1;
reg HSYNC_N_last = 1'b1;
wire VBLANK_N = ~(vcnt >= VBLANK_START);
wire VSYNC_N = ~(vcnt >= VSYNC_START && vcnt <= VSYNC_END);

// Video RAM read addresses
reg [2:0] prom_col;
wire [9:0] vram_read_addr = { vcnt[7:3], hcnt[7:3] }; // Generate VRAM read address from h/v counters { 128V, 64V, 32V, 16V, 8V, 128H, 64H, 32H, 16H, 8H };

always @(posedge clk)
begin
	if(ce_vid)
	begin
		HSYNC_N_last <= HSYNC_N; // Track last cycle hsync value

		if (hcnt == HRESET_LINE) // Horizontal reset point reached
		begin
			hcnt <= 9'b0000;   // Reset horizontal counter
			prom_col = 3'b111; // Set prom column to zero
			HBLANK_N <= 1'b1;  // Leave hblank
		end
		else
		begin
			hcnt <= hcnt + 9'b1;                       // Increment horizontal counter
			if(hcnt == HBLANK_START) HBLANK_N <= 1'b0; // Enter hblank when HBLANK_START reached
			if(hcnt == HSYNC_START) HSYNC_N <= 1'b0;   // Enter hsync when HSYNC_START reached
			if(hcnt == HSYNC_END) HSYNC_N <= 1'b1;     // Leave hsync when HSYNC_END reached
			prom_col = 3'b111 - { hcnt[2:0] + 3'b1};   // Set prom column to reverse of {H1,H2,H4} + 1
		end

		if(HSYNC_N && !HSYNC_N_last) // Leaving hysnc
		begin
			if (vcnt == VRESET_LINE) // Vertical reset point reached
				vcnt <= 9'b0;        // Reset vertical counter
			else
				vcnt <= vcnt + 9'b1; // Increment vertical counter
		end
	end
end

// Set video output signals
assign video = prom_data_out[prom_col];
assign hsync = ~HSYNC_N;
assign hblank = ~HBLANK_N;
assign vblank = ~VBLANK_N;
assign vsync = ~VSYNC_N;


// CPU IO control latches
// ----------------------

// U45 AND - Enable for U51 latch
wire u45 = PHI_1 && SYNC;
// U51 latch
reg [3:0] u51_latch;
always @(posedge clk) begin
	if(u45) u51_latch <= { DATA[7:6], DATA[4:3] };
end

// U45_1
wire OUTP = u51_latch[1] && ~WR_N;
// U44_1
wire MEMW = (u51_latch[0] && ~WR_N);
// U45_2
wire INP = (u51_latch[2] && DBIN);
// U44_2
wire MEMR = (u51_latch[3] && DBIN);


// Discrete audio circuit
// ----------------------

// 555 timer generates a base square wave at 93Khz-ish
wire u68_out;
reg u68_out_last;
astable_555 #(
	.HIGH_PERIOD(70),
	.LOW_PERIOD(26)
	// .HIGH_PERIOD(140),
	// .LOW_PERIOD(51)
) u68 (
	.clk(clk),
	.reset(RESET),
	.out(u68_out)
);

// U66 and U77 make up an 8-bit counter which is preloaded on overflow from U61 and U62 latches.
reg [7:0] u6261;
reg [7:0] u6766_count;
reg u6766_out;
reg u6766_out_last;
wire OUTP2 = OUTP && ADDR[1];

always @(posedge clk)
begin

	u68_out_last <= u68_out;
	if(RESET)
	begin
		// Reset preloader and counter outputs 
		u6766_count <= 8'hFF;
		u6766_out <= 1'b0;
		u6766_out_last <= 1'b0;
		u6261 <= 8'hFF;
	end
	else
	begin
		
		if(OUTP2) u6261 <= DATA; // OUTP2 - Latch CPU data into counter preloaders

		u6766_out_last <= u6766_out;
		if(u68_out && !u68_out_last)
		begin
			if((u6766_count == 8'd255)) // Load new inputs when counter overflows
			begin
				u6766_count <= u6261;
				u6766_out <= 1'b0;
			end
			else
			begin // Increment counter and output high if counter is overflowing
				u6766_count <= u6766_count + 8'b1;
				u6766_out <= (u6766_count == 8'd254);
			end
		end
	end
end

// U60 flip-flop - sound circuit enable and final /2 stage
reg u60_1_q;
reg u60_2_q;
always @(posedge clk)
begin
	if(RESET)
		u60_1_q <= 1'b0;
	else
	begin
		if(!u6766_out) u60_1_q <= 1'b1;
		if(~u60_1_q) u60_2_q <= 1'b0;
		else
			if(u6766_out && !u6766_out_last) u60_2_q <= ~u60_2_q;
	end
end

// Amplify square wave to produce output
wire signed [15:0] sound_out = u6766_count == 8'd255 ? 0 : (!u60_2_q ? -12000 : 12000);

// Low-pass filter the square wave
// - Cut-off frequency of 723.43Hz calculated from 220K resistor and 0.001µF capacitor pairing
wire signed [15:0] sound_filtered;
blockade_lpf lpf
(
	.clk(clk),
	.reset(RESET),
	.in(sound_out),
	.out(sound_filtered)
);


// Boom circuit
// ------------
// This is an analog noise generator which I can't replicate, so we have wave playback of a MAME-source sample

// Trigger circuit (OUTP_4 and OUTP_8)
wire u50_1 = ~(OUTP && ADDR[3]);
wire u50_2 = ~(OUTP && ADDR[2]);
/* verilator lint_off UNOPTFLAT */
wire u50_3 = ~(u50_1 && u50_4);
wire u50_4 = ~(u50_2 && u50_3);
/* verilator lint_on UNOPTFLAT */
always @(posedge clk) begin
	if(RESET)
		wav_play <= 1'b0; // Don't play sample during reset
	else
		wav_play <= u50_4; // Trigger ENV sound (play boom sample)
end

// Wave player
reg [15:0] wave_rom_addr;
wire [7:0] wave_rom_data_out;
reg [15:0] wave_rom_length = 16'd19082;
// Wave sample for boom sound
spram #(15,8, "rom/boom.hex") wave_rom  
(
	.clk(clk),
	.address(wave_rom_addr),
	.wren(1'b0),
	.data(),
	.q(wave_rom_data_out)
);
reg wav_playing = 1'b0;
reg wav_play = 1'b0;
reg [WAV_COUNTER_SIZE-1:0] wav_counter;
localparam WAV_COUNTER_SIZE = 10;
localparam WAV_COUNTER_MAX = 1000;
reg signed [7:0] wav_signed;
always @(posedge clk)
begin
	if(RESET)
	begin
		wav_signed <= 8'b0;
		wav_playing <= 1'b0;		
	end
	else
	begin
		if(!pause)
		begin
			if(!wav_playing)
			begin
				if(wav_play)
				begin
					wav_playing <= 1'b1;
					wave_rom_addr <= 15'b0;
					wav_counter <= WAV_COUNTER_MAX;
				end
			end
			else
			begin
				wav_counter <= wav_counter - 1'b1;
				if(wav_counter == {WAV_COUNTER_SIZE{1'b0}})
				begin
					if(wave_rom_addr < wave_rom_length)
					begin
						wav_signed <= wave_rom_data_out;
						wave_rom_addr <= wave_rom_addr + 15'b1;
						wav_counter <= {WAV_COUNTER_SIZE{1'b1}};
					end
					else
					begin
						wav_signed <= 8'b0;
						wave_rom_addr <= 15'b0;
						wav_playing <= 1'b0;
					end
				end
			end
		end
	end
end

wire signed [15:0] wav_amplified = { wav_signed[7], {1{wav_signed[7]}}, wav_signed[6:0], {7{wav_signed[7]}} };

// Audio mixer
// -----------
// - Combine discrete audio circuit and wave output, then invert
wire signed [15:0] sound_combined = 16'hFFFF - (sound_filtered + wav_amplified);
reg signed [15:0] sound_last;
always @(posedge clk) if(!pause) sound_last <= sound_combined;
assign audio_l = pause ? sound_last : sound_combined;
assign audio_r = audio_l;

// Coin circuit
// ------------
wire OUTP1 = OUTP && ADDR[0];
reg coin_last;
reg coin_inserted;

always @(posedge clk) begin
	if(reset)
	begin
		coin_latch <= 6'b0;
		coin_inserted <= 1'b0;
	end
	else
	begin
		// Register inserted coin when INP_1 active
		if(INP && ADDR[0])
		begin
			if(coin_inserted)
			begin
				coin_latch <= {COIN_LATCH_TIMER_WIDTH{1'b1}};
				coin_inserted <= 1'b0;
			end
			if(coin_latch > {COIN_LATCH_TIMER_WIDTH{1'b0}}) coin_latch <= coin_latch - 1'b1;
		end

		// When coin input is going high, latch coin inserted and start reset pulse
		coin_last <= coin;
		if(coin && !coin_last)
		begin
			coin_inserted <= 1'b1;
			coin_start <= {COIN_START_TIMER_WIDTH{1'b1}};
		end

		// Decrement coin start timer if active
		if(coin_start > {COIN_START_TIMER_WIDTH{1'b0}}) coin_start <= coin_start - 6'b1;
	end
end



// U2, U3 - Program ROM
// --------------------
// Each ROM is 1024 x 4 bytes.  Each pair is combined to 8 bytes:
// - U2 as most significant bits, U3 as least significant bits
// - U4 as most significant bits, U5 as least significant bits (not used by Blockade)

// Program ROM data outs
wire [3:0] rom1_data_out_lsb;
wire [3:0] rom1_data_out_msb;
wire [7:0] rom1_data_out = { rom1_data_out_msb, rom1_data_out_lsb };
wire [3:0] rom2_data_out_lsb;
wire [3:0] rom2_data_out_msb;
wire [7:0] rom2_data_out = { rom2_data_out_msb, rom2_data_out_lsb };

// Program ROM CPU address decode
wire rom1_cs = (!ADDR[15] && !ADDR[11] && !ADDR[10] && MEMR);
wire rom2_cs = (!ADDR[15] && !ADDR[11] && ADDR[10] && MEMR);

// Program ROM download write enables
wire rom1_msb_wr = dn_addr[12:10] == 3'b000 && dn_wr;
wire rom1_lsb_wr = dn_addr[12:10] == 3'b001 && dn_wr;
wire rom2_msb_wr = dn_addr[12:10] == 3'b010 && dn_wr;
wire rom2_lsb_wr = dn_addr[12:10] == 3'b011 && dn_wr;

// Program ROM - U2 - Most-significant bits
dpram #(10,4) rom1_msb
(
	.clock_a(clk),
	.address_a(ADDR[9:0]),
	.wren_a(1'b0),
	.data_a(),
	.q_a(rom1_data_out_msb),

	.clock_b(clk),
	.address_b(dn_addr[9:0]),
	.wren_b(rom1_msb_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);
// Program ROM - U3 - Least-significant bits
dpram #(10,4) rom1_lsb
(
	.clock_a(clk),
	.address_a(ADDR[9:0]),
	.wren_a(1'b0),
	.data_a(),
	.q_a(rom1_data_out_lsb),

	.clock_b(clk),
	.address_b(dn_addr[9:0]),
	.wren_b(rom1_lsb_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);
// Program ROM - U4 - Most-significant bits
dpram #(10,4) rom2_msb
(
	.clock_a(clk),
	.address_a(ADDR[9:0]),
	.wren_a(1'b0),
	.data_a(),
	.q_a(rom2_data_out_msb),

	.clock_b(clk),
	.address_b(dn_addr[9:0]),
	.wren_b(rom2_msb_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);
// Program ROM - U5 - Least-significant bits
dpram #(10,4) rom2_lsb
(
	.clock_a(clk),
	.address_a(ADDR[9:0]),
	.wren_a(1'b0),
	.data_a(),
	.q_a(rom2_data_out_lsb),

	.clock_b(clk),
	.address_b(dn_addr[9:0]),
	.wren_b(rom2_lsb_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);

// U38, U39, U40, U41, U42 - 2102 - Video RAM
// ------------------------------------------
// The original board used logic to allow CPU to write during VBLANK and the video system to read otherwise - I have used dual port RAM for simplicity
// In Blockade only 5-bits per address is used, but Comotion and others use 8-bits

// Data outs
wire [7:0] vram_data_out_cpu;	// Data read by CPU
wire [7:0] vram_data_out;		// Data read by video system

// Video RAM address select and write enable
wire vram_cs = ADDR[15] && !ADDR[12];
wire vram_we = vram_cs && !WR_N;

// U38, U39, U40, U41, U42 combined
dpram #(10,8) ram
(
	.clock_a(clk),
	.address_a(vram_read_addr),
	.wren_a(),
	.data_a(),
	.q_a(vram_data_out),

	.clock_b(clk),
	.address_b(ADDR[9:0]),
	.wren_b(vram_we),
	.data_b(cpu_data_out),
	.q_b(vram_data_out_cpu)
);


// U6, U7 - 2111 - Static RAM
// --------------------------

// Static RAM Data out
wire [7:0]	sram_data_out;

// Static RAM address select and write enable
wire sram_cs = ADDR[15] && ADDR[12];
wire sram_we = sram_cs && !WR_N;

// U6, U7 combined
spram #(8,8) sram
(
	.clk(clk),
	.address(ADDR[7:0]),
	.wren(sram_we),
	.data(cpu_data_out),
	.q(sram_data_out)
);

// U29, U43 - Graphics PROMs
// --------------------
// Blockade and CoMotion - each ROM is 256 x 4 bytes.
// Hustle - each ROM is 512 x 4 bytes.
// Combined to 8 bytes with U29 as most significant bits, U43 as least significant bits

// Graphics PROM data outs
wire [3:0] prom_data_out_lsb;
wire [3:0] prom_data_out_msb;
wire [7:0] prom_data_out = { prom_data_out_msb, prom_data_out_lsb } ;

// Graphics PROM read adress
wire [8:0] prom_addr = { vram_data_out[5:0], vcnt[2:0] };

// Graphics ROM download write enables
wire prom_msb_wr = dn_addr[12:9] == 4'b1000 && dn_wr;
wire prom_lsb_wr = dn_addr[12:9] == 4'b1001 && dn_wr;

// Graphics PROM - U29 - Most-significant bits
dpram #(9,4) prom_msb
(
	.clock_a(clk),
	.address_a(prom_addr),
	.wren_a(1'b0),
	.data_a(),
	.q_a(prom_data_out_msb),

	.clock_b(clk),
	.address_b(dn_addr[8:0]),
	.wren_b(prom_msb_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);
// Graphics ROM - U43 - Least-significant bits
dpram #(9,4) prom_lsb
(
	.clock_a(clk),
	.address_a(prom_addr),
	.wren_a(1'b0),
	.data_a(),
	.q_a(prom_data_out_lsb),

	.clock_b(clk),
	.address_b(dn_addr[8:0]),
	.wren_b(prom_lsb_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);

endmodule

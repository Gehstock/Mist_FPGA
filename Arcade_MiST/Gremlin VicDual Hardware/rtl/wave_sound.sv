/*============================================================================
	VIC arcade hardware by Gremlin Industries for MiSTer - WAVE sound module

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-02-20

	Adapted from wave_sound module by gaz68 and alanswx

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

`timescale 1ps/1ps

// Time-slicing multi-track SDRAM backed WAV player
// - Plays up to 16 concurrent samples
// - Supports RIFF WAV files with the following restrictions:
//    - Mono only
//    - 8-bit signed / 16-bit signed
//    - 22,050Hz / 44,100Hz
// - Re-mappable trigger signals

// Setup:
// - AUDIO_CLOCK_DIVIDE parameter should be set to divide providing clock down to 44,100Hz 
// - WAV file data loaded into SDRAM on ioctl_index 2
// - Metadata loaded into control registers on ioctl_index 3
// -- Each sound metadata entry has:
// - 4 bytes = WAV start offset in SDRAM
// - 1 byte = trigger index (0-7 = OUTP1 bit 0-7, 8-15 = OUTP2 bit 0-7)
// - 1 byte = options
//		bit 0 - trigger_mode - 0=always play on trigger high   1=play on trigger high, stop on trigger low
//		bit 1 - loop_mode - 0=no loop   1=loop
// - 2 bytes = UNUSED PADDING

module wave_sound 
#(
	`ifdef SIMULATION
	parameter [11:0] AUDIO_CLOCK_DIVIDE = 12'd350 // 44,100 / 15468480 Mhz - uses main system clock as simulated SDRAM has no wait
	`else
	parameter [11:0] AUDIO_CLOCK_DIVIDE = 12'd2104 // 44,100 / 92810880 Mhz - uses SDRAM clock
	`endif
)
(
	input				clk,
	input				ce_sys,
	input				reset,
	input				pause,

	input	[23:0]		dn_addr,
	input	[7:0]		dn_data,
	input				dn_wr,
	input				dn_download,
	input	[7:0]		dn_index,

	input	[15:0]		triggers,

	output	reg [24:0]	sdram_addr, // output address to wave ROM
	output	reg			sdram_rd, // read a byte
	input	[7:0]		sdram_dout,  // Data coming back from wave ROM
	input				sdram_ack, // data is ready

	output	[15:0]		out
);


// Track sfx metadata and wave data load state
wire sfx_wave_load = dn_index == 2 && dn_download;
wire sfx_data_load = dn_index == 3 && dn_download;
reg sfx_wave_loaded = 0;
reg sfx_data_loaded = 0;
wire sfx_ready = sfx_wave_loaded && sfx_data_loaded;

localparam SFX_MAX_SAMPLES = 12;
localparam SFX_SAMPLE_SIZE = $clog2(SFX_MAX_SAMPLES) - 1;
reg [(SFX_MAX_SAMPLES*32)-1:0] sfx_data_offset = 0;
reg [(SFX_MAX_SAMPLES*8)-1:0] sfx_data_trigger = 0;
reg [(SFX_MAX_SAMPLES)-1:0] sfx_data_trigger_mode = 0;
reg [(SFX_MAX_SAMPLES)-1:0] sfx_data_loop_mode = 0;
reg [SFX_MAX_SAMPLES-1:0] sfx_data_valid = 0;
reg [3:0] sfx_active_index = 0;
reg [3:0] sfx_check_index = 0;

wire [8:0] sfx_offset_lookup = { sfx_active_index, 5'b000 };
wire [6:0] sfx_trigger_lookup = { sfx_active_index, 3'b000 };
wire [6:0] sfx_trigger_check_lookup = { sfx_check_index, 3'b000 };

localparam [1:0] SFX_STATE_STOPPED = 2'd0;
localparam [1:0] SFX_STATE_HEADER = 2'd1;
localparam [1:0] SFX_STATE_PLAYING = 2'd2;
localparam [1:0] SFX_STATE_WAITING = 2'd3;

reg [(SFX_MAX_SAMPLES*2)-1:0] sfx_state = 0;
reg [(SFX_MAX_SAMPLES*2)-1:0] sfx_timer = 0; // Timer for wait state (to slow down 11Khz samples)
reg [(SFX_MAX_SAMPLES)-1:0] sfx_trigger_last = 0;
reg [(SFX_MAX_SAMPLES)-1:0] sfx_start_pending = 0;
reg [(SFX_MAX_SAMPLES)-1:0] sfx_stop_pending = 0;
reg [(SFX_MAX_SAMPLES)-1:0] sfx_bits = 0; // 0=8 bit sample, 1=16 bit sample
reg [(SFX_MAX_SAMPLES*2)-1:0] sfx_rate = 0; // 0=44,100hz, 1=22,050hz, 2=11,000hz
reg [(SFX_MAX_SAMPLES*32)-1:0] sfx_address = 0;
reg [(SFX_MAX_SAMPLES*32)-1:0] sfx_address_end = 0;

wire [4:0] sfx_state_lookup = { sfx_active_index, 1'b0 };
wire [8:0] sfx_address_lookup = { sfx_active_index, 5'b00000 };
wire [31:0] sfx_address_current = sfx_address[sfx_address_lookup+:32];
wire [7:0] sfx_check_trigger = sfx_data_trigger[sfx_trigger_check_lookup+:8];

reg sfx_next_ready = 1'b0;
reg sfx_data_hold = 1'b0;

reg	[15:0]	num_channels;
reg	[31:0]	sample_rate;
reg	[15:0]	temp_bit_depth;
reg	[31:0]	data_size;
reg	[7:0]	W_SAMPL_LSB;
reg	signed [15:0]	W_SAMPL;

localparam ACC_WIDTH = 18;

reg signed [ACC_WIDTH-1:0] sample_current;
reg signed [ACC_WIDTH-1:0] sample_accumulator;

`define sample_value $signed(W_SAMPL[15:0])
`define sample_last $signed(last_sample_ram_out)

reg [11:0] audio_cycle_count = AUDIO_CLOCK_DIVIDE;
reg [23:0] audio_cycle = 24'b0;
reg audio_cycle_due = 1'b0;

reg [23:0] debug_cycle = 0;

// SDRAM interface
reg read_done = 1'b0;
reg wave_read = 1'b0;
reg wave_data_ready = 1'b0;

always@(posedge clk)
begin
	reg old_wave_load, old_data_load, old_wav_rd, old_ack;

	old_wave_load <= sfx_wave_load;
	old_data_load <= sfx_data_load;
	old_wav_rd <= wave_read;
	old_ack <= sdram_ack;
	
	// Wave data load has finished
	if(old_wave_load & ~sfx_wave_load) sfx_wave_loaded <= 1;

	// SFX meta load in progress
	if(sfx_data_load) 
	begin
		sfx_active_index <= dn_addr[6:3];
		if(dn_wr)
		begin
			case(dn_addr[2:0])
				3'd0: sfx_data_offset[(sfx_offset_lookup+24)+:8] <= dn_data;
				3'd1: sfx_data_offset[(sfx_offset_lookup+16)+:8] <= dn_data;
				3'd2: sfx_data_offset[(sfx_offset_lookup+8)+:8] <= dn_data;
				3'd3: sfx_data_offset[(sfx_offset_lookup+0)+:8] <= dn_data;
				3'd4: sfx_data_trigger[sfx_trigger_lookup +: 8] <= dn_data; 
				3'd5: begin
					sfx_data_trigger_mode[sfx_active_index] <= dn_data[0];
					sfx_data_loop_mode[sfx_active_index] <= dn_data[1];
				end
				3'd6: sfx_data_valid[sfx_active_index] <= 1'b1;
				default: $display("sfx_data_load unhandled case");
			endcase
		end
	end

	if((old_ack ^ sdram_ack)) 
	begin
		//if(!reset) $display("ACK! ack=%b lack=%B rd=%B wrd=%B owrd=%B", sdram_ack, old_ack, sdram_rd, wave_read, old_wav_rd);
		wave_data_ready <= 1;
		sdram_rd <= 1'b0;
	end
	else
	begin
		if(!old_wav_rd && wave_read)
		begin
			//$display("RD! ack=%b lack=%B rd=%B wrd=%B owrd=%B", sdram_ack, old_ack, sdram_rd, wave_read, old_wav_rd);
			sdram_addr <= sfx_address_out[24:0];
			sdram_rd <= 1'b1;
			wave_data_ready <= 0;
		end
	end
	// SFX metadata load has finished
	if(old_data_load & ~sfx_data_load) 
	begin
		sfx_active_index <= 4'b0;
		sfx_data_loaded <= 1;
		$display("SFX data load complete");
	end

	// Track current audio cycle and wait until next
	if(sfx_ready && !reset)
	begin

		last_sample_ram_write <= 1'b0;
		debug_cycle <= debug_cycle + 24'd1;

		// Constantly check through sfx triggers and log a pending high trigger
		sfx_trigger_last[sfx_check_index] <= triggers[sfx_check_trigger[3:0]];
		if(triggers[sfx_check_trigger[3:0]] && !sfx_trigger_last[sfx_check_index]) 
		begin
			sfx_start_pending[sfx_check_index] <= 1'b1;
			$display("%d / %d) SFX %d trigger high - OUT[%d]", debug_cycle, audio_cycle, sfx_check_index, sfx_check_trigger[3:0]);
		end
		if(!triggers[sfx_check_trigger[3:0]] && sfx_trigger_last[sfx_check_index] && sfx_data_trigger_mode[sfx_check_index]==1'b1)
		begin
			sfx_stop_pending[sfx_check_index] <= 1'b1;
			$display("%d / %d) SFX %d trigger low - OUT[%d]", debug_cycle, audio_cycle, sfx_check_index, sfx_check_trigger[3:0]);
		end
		sfx_check_index <= sfx_check_index + 4'b1;
		if(sfx_check_index + 1'b1 == SFX_MAX_SAMPLES || !sfx_data_valid[sfx_check_index + 1'b1]) sfx_check_index <= 4'b0;

		// Manage the audio cycle
		audio_cycle_count <= audio_cycle_count - 1'b1;
		if(audio_cycle_count == 12'b0) begin
			audio_cycle_count <= AUDIO_CLOCK_DIVIDE;
			audio_cycle_due <= 1'b1;
			audio_cycle <= audio_cycle + 24'd1;
		end

		// If an audio cycle is due and the current sfx index has valid data
		if(audio_cycle_due && sfx_data_valid[sfx_active_index])
		begin

			case(sfx_state[sfx_state_lookup+:2])
			SFX_STATE_STOPPED:
			begin
				if(sfx_start_pending[sfx_active_index])
				begin
					// Trigger has gone high - start (or restart) the sample
					sfx_state[sfx_state_lookup+:2] <= SFX_STATE_HEADER;
					sfx_address[sfx_address_lookup+:32] <= 32'b0;
					sfx_start_pending[sfx_active_index] <= 1'b0;
					wave_read <= 1'b1;
					read_done <= 1'b0;
					sfx_next_ready = 1'b0;
					$display("%d / %d) SFX %d starting", debug_cycle, audio_cycle, sfx_active_index);
				end
				else
				begin
					sfx_next_ready = 1'b1;
				end
			end
			SFX_STATE_HEADER:
			begin
				//$display("SFX %d header read at %d", sfx_active_index, sfx_address_current);
				if (wave_data_ready)
				begin
					wave_read <= 1'b0;
					if (!wave_read & !read_done) begin
						wave_read <= 1;
						wave_data_ready <= 1'b0;
						//$display("HEADER READ: %d %x", sfx_address_current[5:0], sdram_dout);
						case (sfx_address[sfx_address_lookup+:6])
							22: num_channels[7:0]		<= sdram_dout;
							23: num_channels[15:8]		<= sdram_dout;
							24: sample_rate[7:0]		<= sdram_dout;
							25: sample_rate[15:8]		<= sdram_dout;
							26: sample_rate[23:16]		<= sdram_dout;
							27: sample_rate[31:24]		<= sdram_dout;
							34: temp_bit_depth[7:0]		<= sdram_dout;
							35: temp_bit_depth[15:8]	<= sdram_dout;
							40: data_size[7:0]			<= sdram_dout;
							41: data_size[15:8]			<= sdram_dout;
							42: data_size[23:16]		<= sdram_dout;
							43: data_size[31:24]		<= sdram_dout; 
							44: begin
								//$display("%d) SFX: channels=%d",audio_cycle, num_channels);
								// $display("%d / %d) SFX: sample_rate=%d", debug_cycle, audio_cycle, sample_rate);
								//$display("%d) SFX: bits_per_sample=%d", audio_cycle, temp_bit_depth);
								//$display("%d) SFX: length = %d",audio_cycle, data_size);
								sfx_bits[sfx_active_index] <= temp_bit_depth == 16'd16 ? 1'b1 : 1'b0;
								sfx_rate[sfx_state_lookup+:2] <= 2'd0; // Default to 44,100Hz
								if(sample_rate == 32'd22050) sfx_rate[sfx_state_lookup+:2] <= 2'd1;
								if(sample_rate == 32'd11025) sfx_rate[sfx_state_lookup+:2] <= 2'd2;
								sfx_address_end[sfx_address_lookup+:32] <= sfx_address_current + data_size;
								sfx_state[sfx_state_lookup+:2] <= SFX_STATE_PLAYING;
								end
						endcase
						if(!(sfx_address_current == 32'd0 && sdram_dout == 8'b0) && sfx_address[sfx_address_lookup+:6] != 6'd44) sfx_address[sfx_address_lookup+:32] <= sfx_address_current + 1'd1;
					end
				end
			end
			SFX_STATE_PLAYING:
			begin
				//$display("SFX %d playing at %d", sfx_active_index, sfx_address_current);
				if (wave_data_ready)
				begin
					wave_read <= 0;
					if (!wave_read & ~read_done) begin
						wave_data_ready <= 1'b0;
						// If this is an 8-bit sample then just use what we have and move on
						if (!sfx_bits[sfx_active_index]) 
						begin
							W_SAMPL		<= {sdram_dout, sdram_dout};
							read_done	<= 1;
						end
						// Otherwise get the low byte for the sample then read again
						else if (!sfx_address_current[0]) begin
							W_SAMPL_LSB	<= sdram_dout;
							wave_read	<= 1;
						end
						// Finally get the high byte for the sample we are done
						else begin
							W_SAMPL		<= {sdram_dout, W_SAMPL_LSB};
							read_done	<= 1;
						end
						sfx_address[sfx_address_lookup+:32] <= sfx_address_current + 1'd1;
					end
				end

				// Sample is ready for this SFX item
				if(read_done) begin

					read_done <= 0;
					wave_read <= 1;
					
					last_sample_ram_addr <= sfx_active_index;
					last_sample_ram_write <= 1'b1;
					last_sample_ram_in <= `sample_value;
					sample_accumulator = sample_accumulator + `sample_value;
					//$display("%d / %d) SFX %d sfx_last_sample: %d %d %d", debug_cycle, audio_cycle, sfx_active_index, `sample_value, $signed(sfx_last_sample[sfx_last_sample_lookup+:ACC_WIDTH]), `sample_last);
					// $display("%d / %d) SFX %d @ %d sample %d %d", debug_cycle, audio_cycle, sfx_active_index, sfx_address_current, `sample_last, W_SAMPL);
					// $display("%d / %d) SFX %d ACC = %d", debug_cycle, audio_cycle, sfx_active_index, sample_accumulator);
					if(sfx_address_current == sfx_address_end[sfx_address_lookup+:32])
					begin
						// If this is a one-shot sample, stop, otherwise loop
						if(sfx_data_loop_mode[sfx_active_index] == 1'b0)
						begin
							$display("%d / %d) SFX %d finished at %d", debug_cycle, audio_cycle, sfx_active_index, sfx_address_current);
							sfx_state[sfx_state_lookup+:2] <= SFX_STATE_STOPPED;
						end
						else
						begin
							$display("%d / %d) SFX %d looping at %d", debug_cycle, audio_cycle, sfx_active_index, sfx_address_current);
							sfx_address[sfx_address_lookup+:32] <= 32'd44;
						end
					end
					else
					begin
						if(sfx_rate[sfx_state_lookup+:2] > 2'd0)
						begin
							// 22Khz sample mode so need to skip until next audio cycle
							sfx_state[sfx_state_lookup+:2] <= SFX_STATE_WAITING;
							sfx_timer[sfx_state_lookup+:2] <= sfx_rate[sfx_state_lookup+:2] == 2'd1 ? 2'd0 : 2'd2;
						end
					end
					sfx_next_ready = 1'b1;
				end

				if(sfx_data_trigger_mode[sfx_active_index] == 1'b0 && sfx_start_pending[sfx_active_index])
				begin
					$display("%d / %d) SFX %d halted for restart at %d", debug_cycle, audio_cycle, sfx_active_index, sfx_address_current);
					sfx_state[sfx_state_lookup+:2] <= SFX_STATE_STOPPED;
				end

				if(sfx_data_trigger_mode[sfx_active_index] == 1'b1 && sfx_stop_pending[sfx_active_index] && sfx_state[sfx_state_lookup+:2] == SFX_STATE_PLAYING)
				begin
					$display("%d / %d) SFX %d stopped at %d", debug_cycle, audio_cycle, sfx_active_index, sfx_address_current);
					sfx_stop_pending[sfx_active_index] <= 1'b0;
					sfx_state[sfx_state_lookup+:2] <= SFX_STATE_STOPPED;
				end
			end
			SFX_STATE_WAITING:
			begin
				last_sample_ram_addr <= sfx_active_index;
				if(sfx_data_hold == 1'b1)
				begin
					sample_accumulator = sample_accumulator + `sample_last;
					// $display("%d / %d) SFX %d @ %d waiting %d %d @ %x", debug_cycle, audio_cycle, sfx_active_index, sfx_address_current, `sample_last, last_sample_ram_out, last_sample_ram_addr);
					// $display("%d / %d) SFX %d ACC = %d", debug_cycle, audio_cycle, sfx_active_index, sample_accumulator);
					if(sfx_timer[sfx_state_lookup+:2] == 2'd0)
					begin
						sfx_state[sfx_state_lookup+:2] <= SFX_STATE_PLAYING;
						read_done <= 0;
						wave_read <= 1;
					end
					else
					begin
						sfx_timer[sfx_state_lookup+:2] <= sfx_timer[sfx_state_lookup+:2] - 2'd1;
					end
					sfx_next_ready = 1'b1;
					sfx_data_hold <= 1'b0;
				end
				else
				begin
					sfx_data_hold <= 1'b1;
				end
			end
			endcase

			if(sfx_next_ready == 1'b1)
			begin
				sfx_active_index <= sfx_active_index + 1'b1;
				sfx_next_ready = 1'b0;
				if(sfx_active_index + 1'b1 == SFX_MAX_SAMPLES || !sfx_data_valid[sfx_active_index + 1'b1] )
				begin
					// Apply accumulator and clear
					sfx_active_index <= 4'd0;
					sample_current = sample_accumulator;
					sample_accumulator = {ACC_WIDTH{1'b0}};
					audio_cycle_due <= 1'b0;
				end
			end
		end
	end
	if(reset || pause) W_SAMPL <= 0;
end

wire [31:0] sfx_address_out = sfx_address_current + sfx_data_offset[sfx_offset_lookup+:32];

//assign sdram_addr = sfx_address_out[24:0];

// Drop last two bits of sample accumulator to lower volume on the way out
assign out  = sample_current[ACC_WIDTH-1:ACC_WIDTH-16];

// Last sample RAM buffer (to propagate last samples for freq lower than 44Khz)
wire signed [15:0] last_sample_ram_out;
reg signed [15:0] last_sample_ram_in;
reg [3:0] last_sample_ram_addr;
reg last_sample_ram_write = 1'b0;
spram #(4,16) last_sample_ram
(
	.clock(clk),
	.address(last_sample_ram_addr),
	.wren(last_sample_ram_write),
	.data(last_sample_ram_in),
	.q(last_sample_ram_out)
);

endmodule

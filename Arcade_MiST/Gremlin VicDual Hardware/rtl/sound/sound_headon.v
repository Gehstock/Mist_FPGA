/*============================================================================
	VIC arcade hardware by Gremlin Industries for MiSTer - Head On sound board

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-03-12

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

module sound_headon (
	input clk,
	input reset,
	input [7:0] control,
	output signed [15:0] out_l,
	output signed [15:0] out_r
);

	// Sound triggers
	wire car_on = control[6];
	wire bonus_en = control[5];
	wire screech_2 = control[4];
	wire hispeed_cpu = control[3];
	wire crash_en = control[2];
	wire screech_1 = control[1];
	wire hispeed_player = control[0];
	
	// always @(posedge clk)
	// begin
	// 	if(car_on) $display("car_on %b", control);
	// end

	// Player car sound
	wire signed [15:0] player_car_out;
	sound_headon_car player_car
	(
		.clk(clk),
		.reset(reset),
		.enable(car_on),
		.high_speed(hispeed_player),
		.out(player_car_out)
	);

	// CPU car sound
	wire signed [15:0] cpu_car_out;
	sound_headon_car cpu_car
	(
		.clk(clk),
		.reset(reset),
		.enable(car_on),
		.high_speed(hispeed_cpu),
		.out(cpu_car_out)
	);

	// Generate 48Khz enable
	reg [18:0] ce_48Khz_count;
	localparam ce_48Khz_count_max = 19'D322;
	reg ce_48Khz;
	always @(posedge clk)
	begin
		if(ce_48Khz_count < ce_48Khz_count_max)
		begin
			ce_48Khz_count <= ce_48Khz_count + 19'd1;
			ce_48Khz <= 1'b0;
		end
		else
		begin
			ce_48Khz_count <= 19'd0;
			ce_48Khz <= 1'b1;
		end
	end
	
	// Bonus sound
	wire [15:0] bonus_out;
	sound_headon_bonus bonus
	(
		.clk(clk),
		.clk_48KHz_en(ce_48Khz),
		.bonus_en(bonus_en),
		.out(bonus_out)
	);

	// Crash sound
//	wire [15:0] crash_out;
//	sound_headon_crash crash
//	(
//		.clk(clk),
//		.clk_48KHz_en(ce_48Khz),
//		.crash_en(crash_en),
//		.out(crash_out)
//	);

	//assign out_r = bonus_en ? { bonus_out } : 16'd0;
	//assign out_r = player_car_out + { 2'b0, bonus_out[13:0] } + { 2'b0, crash_out[13:0] };
	assign out_r = player_car_out + { 2'b0, bonus_out[13:0] };
	//assign out_r = { 2'b0, crash_out[13:0] };
	//assign out_r = bonus_out;
	assign out_l = out_r;

	// wire [16:0] lfsr_out;
	// lfsr #(
	// 	.LEN(17),
	// 	.TAPS(17'b10100000000000000)
	// ) lfsr
	// (
	// 	.clk(clk),
	// 	.rst(reset),
	// 	.en(1'b1),
	// 	.seed(17'b1),
	// 	.sreg(lfsr_out)
	// );

	// assign out_r = lfsr_out[15:0];

endmodule



module freq_ramp
#(
	FREQ_NORMAL = 24'd90000,
	FREQ_HIGH = 24'd20000,
	FREQ_COUNTER_MAX = 8'd150
)(
	input clk,
	input reset,
	input high,
	output reg [23:0] out
);

	// Simple frequency ramp generator
	// -------------------------------
	// Linear interpolation between normal and high frequency based on 'high' input

	// FREQ_NORMAL = number of cycles per 555 pulse at lowest speed
	// FREQ_HIGH = number of cycles per 555 pulse at highest speed
	// FREQ_COUNTER_MAX = number of cycles between lerps

	wire [23:0] target = high ? FREQ_HIGH : FREQ_NORMAL;
	reg [7:0] freq_counter;

	always @(posedge clk)
	begin
		if(reset)
		begin
			out <= FREQ_NORMAL;
			freq_counter <= 8'd0;
		end
		else
		begin
			if(out != target)
			begin
				freq_counter <= freq_counter + 8'd1;
				if(freq_counter >= FREQ_COUNTER_MAX)
				begin
					out <= out + (out < target ? 1 : -1);
					freq_counter <= 8'd0;
				end
			end
		end
	end

endmodule

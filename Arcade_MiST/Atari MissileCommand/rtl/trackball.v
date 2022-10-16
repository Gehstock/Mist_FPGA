/*============================================================================
	Missile Command for MiSTer FPGA - Trackball emulator

	Copyright (C) 2022 - Jim Gregory - https://github.com/JimmyStones/

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
`default_nettype none

module trackball(
	input			clk,
	input			flip,
	input  [3:0]	joystick,
	input [15:0]	joystick_analog,
	input			joystick_mode, // 0 = digital, 1 = analog
	input			joystick_sensitivity,
	input  [1:0]	mouse_speed,
	input [24:0]	ps2_mouse,
	output reg		v_dir,
	output reg		v_clk,
	output reg		h_dir,
	output reg		h_clk

);

wire [7:0] joystick_speed = joystick_sensitivity ? 8'd32 : 8'd16; 

localparam joystick_divider_width = 16;
localparam [joystick_divider_width-1:0] joystick_divider_max = 60000;
reg [joystick_divider_width-1:0] joystick_divider = joystick_divider_max;

localparam analog_divider_width = 19;
localparam [analog_divider_width-1:0] analog_divider_max = 300000;
reg [analog_divider_width-1:0] analog_divider = analog_divider_max;

// Trackball movement
localparam trackball_falloff_width = 11;
reg [trackball_falloff_width-1:0] trackball_falloff;

localparam analog_falloff_max = 1;

reg [7:0] mouse_mag_x /* synthesis preserve noprune */;
reg [7:0] mouse_mag_y /* synthesis preserve noprune */;

wire mouse_clock /* synthesis keep */ = ps2_mouse[24];
wire mouse_sign_x = /* synthesis preserve noprune */ ps2_mouse[4];
wire mouse_sign_y = /* synthesis preserve noprune */ ps2_mouse[5];

localparam [15:0] clock_base = 16'd3000;

reg [15:0] h_clock_counter;
reg [15:0] h_clock_max = 0;
reg [15:0] v_clock_counter;
reg [15:0] v_clock_max = 0;

// Trackball movement
always @(posedge clk)
begin
	reg	old_mstate;

	if(joystick_mode == 1'b0)
	begin
		joystick_divider <= joystick_divider - 1'b1;
		if(joystick_divider == 0)
		begin
			joystick_divider <= joystick_divider_max;
			
			// Right
			if(joystick[0])
			begin
				h_dir <= 1'b0;
				mouse_mag_x = joystick_speed;
				trackball_falloff <= {trackball_falloff_width{1'b1}};
			end

			// Left
			if(joystick[1])
			begin
				h_dir <= 1'b1;
				mouse_mag_x = joystick_speed;
				trackball_falloff <= {trackball_falloff_width{1'b1}};
			end

			// Down
			if(joystick[2])
			begin
				v_dir <= 1'b1;
				mouse_mag_y = joystick_speed;
				trackball_falloff <= {trackball_falloff_width{1'b1}};
			end

			// Up
			if(joystick[3])
			begin
				v_dir <= 1'b0;
				mouse_mag_y = joystick_speed;
				trackball_falloff <= {trackball_falloff_width{1'b1}};
			end
			
		end
	end
	else
	begin
		analog_divider <= analog_divider - 1'b1;
		if(analog_divider == 0)
		begin
			analog_divider <= analog_divider_max;

			// Horizontal analog joystick
			if(joystick_analog[7:0] != 0)
			begin
				h_dir <= joystick_analog[7];
				mouse_mag_x = {1'b0, joystick_analog[7] ? -joystick_analog[6:0] : joystick_analog[6:0]};
				if(mouse_mag_x < 10)
					mouse_mag_x = 0;
				else
					mouse_mag_x = mouse_mag_x >> (joystick_sensitivity ? 2 : 1);
				trackball_falloff <= analog_falloff_max;
			end
			// Vertical analog joystick
			if(joystick_analog[15:8] != 0)
			begin
				v_dir <= ~joystick_analog[15];
				mouse_mag_y = {1'b0, joystick_analog[15] ? -joystick_analog[14:8] : joystick_analog[14:8]};
				if(mouse_mag_y < 10)
					mouse_mag_y = 0;
				else
					mouse_mag_y = mouse_mag_y >> (joystick_sensitivity ? 2 : 1);
				trackball_falloff <= analog_falloff_max;
			end
		end
	end

	old_mstate <= mouse_clock;
	if(old_mstate != mouse_clock)
	begin

		h_dir <= mouse_sign_x;
		v_dir <= mouse_sign_y;

		mouse_mag_x = mouse_sign_x ? -ps2_mouse[15:8] : ps2_mouse[15:8];
		mouse_mag_y = mouse_sign_y ? -ps2_mouse[23:16] : ps2_mouse[23:16];

		if(mouse_speed == 2'd0) // 25% speed
		begin
			mouse_mag_x = mouse_mag_x >> 2;
			mouse_mag_y = mouse_mag_y >> 2;
		end
		else if(mouse_speed == 2'd1) // 50% speed
		begin
			mouse_mag_x = mouse_mag_x >> 1;
			mouse_mag_y = mouse_mag_y >> 1;
		end
		else if(mouse_speed == 2'd3) // 200% speed
		begin
			mouse_mag_x = mouse_mag_x << 1;
			mouse_mag_y = mouse_mag_y << 1;
		end
		
		trackball_falloff <= {trackball_falloff_width{1'b1}};
	end

	if(mouse_mag_x > 0) h_clock_max <= clock_base + ((16'd255 - {8'b0,mouse_mag_x}) << 4);
	else h_clock_max <= 0;
	if(mouse_mag_y > 0) v_clock_max <= clock_base + ((16'd255 - {8'b0,mouse_mag_y}) << 4);
	else v_clock_max <= 0;

	if(trackball_falloff == 0)
	begin
		if (mouse_mag_x > 0) mouse_mag_x = mouse_mag_x - 1'b1;
		if (mouse_mag_y > 0) mouse_mag_y = mouse_mag_y - 1'b1;
		trackball_falloff <= {trackball_falloff_width{1'b1}};
	end
	else
		trackball_falloff <= trackball_falloff - 1'b1;

	if(h_clock_max == 0)
		h_clock_counter <= 0;
	else
	begin
		h_clock_counter <= h_clock_counter + 1'b1;
		if(h_clock_counter >= h_clock_max)
		begin
			h_clock_counter <= 0;
			h_clk <= ~h_clk;
		end
	end

	if(v_clock_max == 0)
		v_clock_counter <= 0;
	else
	begin
		v_clock_counter <= v_clock_counter + 1'b1;
		if(v_clock_counter >= v_clock_max)
		begin
			v_clock_counter <= 0;
			v_clk <= ~v_clk;
		end
	end

end

endmodule
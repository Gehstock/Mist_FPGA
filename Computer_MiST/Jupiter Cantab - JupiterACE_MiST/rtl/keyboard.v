//============================================================================
//  Jupiter Ace keyboard
//  Copyright (C) 2018 Sorgelig
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

module keyboard
(
	input        reset,
	input        clk_sys,

	input [10:0] ps2_key,

	input  [7:0] kbd_row,
	output [4:0] kbd_col
);

reg  [4:0] keys[7:0];
wire       press_n = ~ps2_key[9];

// Output addressed row to ULA
assign kbd_col = ({5{kbd_row[0]}} | keys[0])
                &({5{kbd_row[1]}} | keys[1])
                &({5{kbd_row[2]}} | keys[2])
                &({5{kbd_row[3]}} | keys[3])
                &({5{kbd_row[4]}} | keys[4])
                &({5{kbd_row[5]}} | keys[5])
                &({5{kbd_row[6]}} | keys[6])
                &({5{kbd_row[7]}} | keys[7]);

wire shift = ~keys[0][0];

always @(posedge clk_sys) begin
	reg old_reset = 0;
	reg old_state;

	old_state <= ps2_key[10];

	old_reset <= reset;
	if(~old_reset & reset)begin
		keys[0] <= 5'b11111;
		keys[1] <= 5'b11111;
		keys[2] <= 5'b11111;
		keys[3] <= 5'b11111;
		keys[4] <= 5'b11111;
		keys[5] <= 5'b11111;
		keys[6] <= 5'b11111;
		keys[7] <= 5'b11111;
	end

	if(old_state != ps2_key[10]) begin
		case(ps2_key[7:0])
			8'h12 : keys[0][0] <= press_n; // Left shift (CAPS SHIFT)
			8'h59 : keys[0][0] <= press_n; // Right shift (CAPS SHIFT)
			8'h14:  keys[0][1] <= press_n; // ctrl
			8'h1a : keys[0][2] <= press_n; // Z
			8'h22 : keys[0][3] <= press_n; // X
			8'h21 : keys[0][4] <= press_n; // C

			8'h1c : keys[1][0] <= press_n; // A
			8'h1b : keys[1][1] <= press_n; // S
			8'h23 : keys[1][2] <= press_n; // D
			8'h2b : keys[1][3] <= press_n; // F
			8'h34 : keys[1][4] <= press_n; // G

			8'h15 : keys[2][0] <= press_n; // Q
			8'h1d : keys[2][1] <= press_n; // W
			8'h24 : keys[2][2] <= press_n; // E
			8'h2d : keys[2][3] <= press_n; // R
			8'h2c : keys[2][4] <= press_n; // T

			8'h16 : keys[3][0] <= press_n; // 1
			8'h1e : keys[3][1] <= press_n; // 2
			8'h26 : keys[3][2] <= press_n; // 3
			8'h25 : keys[3][3] <= press_n; // 4
			8'h2e : keys[3][4] <= press_n; // 5

			8'h45 : keys[4][0] <= press_n; // 0
			8'h46 : keys[4][1] <= press_n; // 9
			8'h3e : keys[4][2] <= press_n; // 8
			8'h3d : keys[4][3] <= press_n; // 7
			8'h36 : keys[4][4] <= press_n; // 6

			8'h4d : keys[5][0] <= press_n; // P
			8'h44 : keys[5][1] <= press_n; // O
			8'h43 : keys[5][2] <= press_n; // I
			8'h3c : keys[5][3] <= press_n; // U
			8'h35 : keys[5][4] <= press_n; // Y

			8'h5a : keys[6][0] <= press_n; // ENTER
			8'h4b : keys[6][1] <= press_n; // L
			8'h42 : keys[6][2] <= press_n; // K
			8'h3b : keys[6][3] <= press_n; // J
			8'h33 : keys[6][4] <= press_n; // H

			8'h29 : keys[7][0] <= press_n; // SPACE
			8'h3a : keys[7][1] <= press_n; // M
			8'h31 : keys[7][2] <= press_n; // N
			8'h32 : keys[7][3] <= press_n; // B
			8'h2a : keys[7][4] <= press_n; // V

			8'h6B : begin // Left (CAPS 5)
					keys[0][0] <= press_n;
					keys[3][4] <= press_n;
				end
			8'h72 : begin // Up (CAPS 6)
					keys[0][0] <= press_n;
					keys[4][3] <= press_n;
				end
			8'h75 : begin // Down (CAPS 7)
					keys[0][0] <= press_n;
					keys[4][4] <= press_n;
				end
			8'h74 : begin // Right (CAPS 8)
					keys[0][0] <= press_n;
					keys[4][2] <= press_n;
				end

			8'h66 : begin // Backspace (CAPS 0)
					keys[0][0] <= press_n;
					keys[4][0] <= press_n;
				end
			8'h76 : begin // Escape (CAPS SPACE)
					keys[0][0] <= press_n;
					keys[7][0] <= press_n;
				end
			8'h58 : begin // Caps Lock
					keys[0][0] <= press_n;
					keys[3][1] <= press_n;
				end
			8'h0D : begin // TAB
					keys[0][0] <= press_n;
					keys[3][0] <= press_n;
				end

			8'h41 : begin // , <
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[7][2] <= 1;
						keys[2][3] <= 1;
					end
					else if(shift) keys[2][3] <= 0;
					else keys[7][2] <= 0;
				end
			8'h49 : begin // . >
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[7][1] <= 1;
						keys[2][4] <= 1;
					end
					else if(shift) keys[2][4] <= 0;
					else keys[7][1] <= 0;
				end
			8'h4C : begin // ; :
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[5][1] <= 1;
						keys[0][2] <= 1;
					end
					else if(shift) keys[0][2] <= 0;
					else keys[5][1] <= 0;
				end
			8'h52 : begin // " '
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[5][0] <= 1;
						keys[4][3] <= 1;
					end
					else if(shift) keys[4][3] <= 0;
					else keys[5][0] <= 0;
				end
			8'h4A : begin // / ?
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[0][4] <= 1;
						keys[7][4] <= 1;
					end
					else if(shift) keys[0][4] <= 0;
					else keys[7][4] <= 0;
				end
			8'h4E : begin // - _
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[6][3] <= 1;
						keys[4][0] <= 1;
					end
					else if(shift) keys[4][0] <= 0;
					else keys[6][3] <= 0;
				end
			8'h55 : begin // = +
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[6][1] <= 1;
						keys[6][2] <= 1;
					end
					else if(shift) keys[6][2] <= 0;
					else keys[6][1] <= 0;
				end
			8'h54 : begin // [ {
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[5][4] <= 1;
						keys[1][3] <= 1;
					end
					else if(shift) keys[1][3] <= 0;
					else keys[5][4] <= 0;
				end
			8'h5B : begin // ] }
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[5][3] <= 1;
						keys[1][4] <= 1;
					end
					else if(shift) keys[1][4] <= 0;
					else keys[5][3] <= 0;
				end
			8'h5D : begin // \ |
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[1][2] <= 1;
						keys[1][1] <= 1;
					end
					else if(shift) keys[1][1] <= 0;
					else keys[1][2] <= 0;
				end
			8'h0E : begin // ~ *
					keys[0][1] <= press_n;
					if(press_n) begin
						keys[1][0] <= 1;
						keys[7][3] <= 1;
					end
					else if(shift) keys[7][3] <= 0;
					else keys[1][0] <= 0;
				end
			default: ;
		endcase
	end
end

endmodule

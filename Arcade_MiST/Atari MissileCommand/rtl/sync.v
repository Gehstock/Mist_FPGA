/*============================================================================
	Missile Command for MiSTer FPGA - Sync circuit

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

module sync
(
	input wire			clk_10M, 
	input wire			ce_5M,
	input wire			reset,
	input wire			flip,
	output reg			h_sync,
	output reg			v_sync,
	output reg			h_blank,
	output reg			v_blank/*verilator public_flat*/,	
	output wire			s_phi_x,
	output wire			s_3INH,
	output reg [8:0]	hcnt/*verilator public_flat*/,
	output reg [7:0]	vcnt/*verilator public_flat*/
);


///// CLOCKS
reg		s_A7_1;
reg		s_A7_2_n;
reg		s_B8;

always @(posedge clk_10M)
begin
	reg h_sync_last;
	reg ce_5M_last;
	reg s_1h_last;

	///// HORIZONTAL COUNTER AND SYNC
	if(ce_5M == 1'b1)
	begin
		hcnt <= hcnt + 9'b1;
		begin
			case (hcnt)
				256:	h_blank <= 1;
				260:	h_sync <= 1;
				288:	h_sync <= 0;
				319:	
				begin
					hcnt <= 0;
					h_blank <=0;
				end
			endcase
		end
		///// VERTICAL COUNTER AND SYNC
		if (h_sync == 1'b1 && h_sync_last == 1'b0) begin
			if(flip)
				vcnt <= vcnt + 8'b1;
			else
				vcnt <= vcnt - 8'b1;
		end
		h_sync_last <= h_sync;
		
		case (vcnt)
			0:	v_blank <= flip;
			25:	v_blank <= ~flip; 
			4:	if(flip) v_sync <= 1;
			8:	if(flip) v_sync <= 0;
			20:	if(~flip) v_sync <= 1;
			16:	if(~flip) v_sync <= 0;
		endcase
	end

	ce_5M_last <= ce_5M;
	if(ce_5M && !ce_5M_last) s_A7_1 <= ~s_3INH;
	
	s_1h_last <= hcnt[0];
	if(hcnt[0] && !s_1h_last) s_A7_2_n <= (~hcnt[1] & hcnt[2]);
	if(!hcnt[0] && s_1h_last) s_B8 <= s_A7_2_n;

end

assign s_3INH = (vcnt[7:5] == 3'b111);
assign s_phi_x = (~(s_B8 & ~s_A7_1)) & (~(s_A7_1 & hcnt[1]));

endmodule
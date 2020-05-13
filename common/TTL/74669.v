//============================================================================
//  SNK Alpha68k for MiSTer
//
//  Copyright (C) 2020 Sean 'Furrtek' Gonsalves
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

module C74669 (
	input [3:0] DIN,
	input CLK,
	input DU,
	input nLOAD,
	output reg [3:0] QOUT,
	output RCO
);

	assign RCO = DU ? (QOUT == 4'd0) : (QOUT == 4'd15);

	always @(posedge CLK or negedge nLOAD)
	begin
		if (!nLOAD)
			QOUT <= DIN;
		else
			QOUT <= DU ? QOUT - 4'd1 : QOUT + 4'd1;
	end

endmodule

//============================================================================
//  Irem M72 for MiSTer FPGA - Palette chip
//
//  Copyright (C) 2022 Martin Donlon
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

module kna91h014 (
    input CLK_32M,

    input [7:0] CB,	// Pins 3-10.
    input [7:0] CA,	// Pins 11-18.
    
    input SELECT,	// Pin 50. "S"
    
    input E1_N,		// Pin 52.
    input E2_N,		// Pin 51. CBLK.

    input G,		// Pin 30. G_N.
    
    input MWR,	// Pin 29.
    input MRD,	// Pin 28.

    input [15:0] DIN,	// Pins 25, 22-19 (split to input for Verilog).
    output [15:0] DOUT,	// Pins 25, 22-19 (split to output for Verilog).
    output DOUT_VALID,
    
    input [19:0] A,	// Pins 53-60

    output reg [4:0] RED,	// Pins 47-43.
    output reg [4:0] GRN,	// Pins 42-40, 37-36.
    output reg [4:0] BLU	// Pins 35-31.
);

wire [7:0] A_IN = A[8:1];
wire [2:0] A_S = { A[11], A[10], A[0] };

reg [7:0] color_addr;

always @(posedge CLK_32M) begin
    color_addr <= SELECT ? CA : CB;
end

// Palette RAMs...
reg [4:0] ram_a [256];
reg [4:0] ram_b [256];
reg [4:0] ram_c [256];

// RAM Addr decoding...
wire ram_a_cs = A_S==3'b000 | A_S==3'b110;
wire ram_b_cs = A_S==3'b010;
wire ram_c_cs = A_S==3'b100;

// Write enable, and addr decoding for RAM writes.
wire wr_ena = G & MWR;
wire rd_ena = G & MRD;

wire ram_wr_a = ram_a_cs & wr_ena;
wire ram_wr_b = ram_b_cs & wr_ena;
wire ram_wr_c = ram_c_cs & wr_ena;

reg [4:0] red_lat;
reg [4:0] grn_lat;
reg [4:0] blu_lat;

// DOUT read driver...
assign DOUT = { 11'd0,
    (ram_a_cs) ? red_lat :
    (ram_b_cs) ? grn_lat :
    (ram_c_cs) ? blu_lat : 5'h00 };
assign DOUT_VALID = rd_ena;

always @(posedge CLK_32M)
begin
    red_lat <= ram_a[A_IN];
    if (ram_wr_a)
        ram_a[A_IN] <= DIN[4:0];

    grn_lat <= ram_b[A_IN];
    if (ram_wr_b)
        ram_b[A_IN] <= DIN[4:0];

    blu_lat <= ram_c[A_IN];
    if (ram_wr_c)
        ram_c[A_IN] <= DIN[4:0];


    RED <= ram_a[color_addr];
    GRN <= ram_b[color_addr];
    BLU <= ram_c[color_addr];
end

endmodule

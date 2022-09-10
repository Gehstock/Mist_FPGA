//============================================================================
//  Irem M72 for MiSTer FPGA - B-D board, two background layers
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


module board_b_d (
    input CLK_32M,
    input CE_PIX,

    output [15:0] DOUT,
    output DOUT_VALID,

    input [15:0] DIN,
    input [19:0] A,
    input [1:0]  BYTE_SEL,

    input [7:0] IO_A,
    input [7:0] IO_DIN,

    input MRD,
    input MWR,
    input IORD,
    input IOWR,
    input a_memrq,
    input b_memrq,
    input palette_memrq,
    input NL,

    input [8:0] VE,
    input [8:0] HE,

    output [4:0] RED,
    output [4:0] GREEN,
    output [4:0] BLUE,
    output P1L,

    input [31:0] sdr_data_a,
    output [24:0] sdr_addr_a,
    output sdr_req_a,
    input sdr_ack_a,

    input [31:0] sdr_data_b,
    output [24:0] sdr_addr_b,
    output sdr_req_b,
    input sdr_ack_b,

    input paused,
    
    input en_layer_a,
    input en_layer_b,
    input en_palette,

    input m84
);

// M72-B-D 1/8
// Didn't implement WAIT signal
wire WRA = MWR & a_memrq;
wire WRB = MWR & b_memrq;
wire RDA = MRD & a_memrq;
wire RDB = MRD & b_memrq;

wire VSCKA = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b000);
wire HSCKA = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b001);
wire VSCKB = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b010);
wire HSCKB = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b011);

wire [3:0] BITA;
wire [3:0] BITB;
wire [3:0] COLA;
wire [3:0] COLB;
wire CP15A, CP15B, CP8A, CP8B;

wire [15:0] DOUT_A, DOUT_B;

assign DOUT = pal_dout_valid ? pal_dout : RDA ? DOUT_A : DOUT_B;
assign DOUT_VALID = RDA | RDB | pal_dout_valid;

wire [20:0] addr_a, addr_b;
assign sdr_addr_a = { REGION_BG_A.base_addr[24:21], addr_a };
assign sdr_addr_b = { m84 ? REGION_BG_A.base_addr[24:21] : REGION_BG_B.base_addr[24:21], addr_b };

board_b_d_layer layer_a(
    .CLK_32M(CLK_32M),
    .CE_PIX(CE_PIX),

    .DOUT(DOUT_A),
    .DIN(DIN),
    .A(A),
    .BYTE_SEL(BYTE_SEL),
    .RD(RDA),
    .WR(WRA),

    .IO_DIN(IO_DIN),
    .IO_A(IO_A),

    .VSCK(VSCKA),
    .HSCK(HSCKA),
    .NL(NL),

    .VE(VE),
    .HE(HE),

    .BIT(BITA),
    .COL(COLA),
    .CP15(CP15A),
    .CP8(CP8A),

    .sdr_addr(addr_a),
    .sdr_data(sdr_data_a),
    .sdr_req(sdr_req_a),
    .sdr_ack(sdr_ack_a),

    .enabled(en_layer_a),
    .paused(paused),

    .m84(m84)
);

board_b_d_layer layer_b(
    .CLK_32M(CLK_32M),
    .CE_PIX(CE_PIX),

    .DOUT(DOUT_B),
    .DIN(DIN),
    .A(A),
    .BYTE_SEL(BYTE_SEL),
    .RD(RDB),
    .WR(WRB),

    .IO_DIN(IO_DIN),
    .IO_A(IO_A),

    .VSCK(VSCKB),
    .HSCK(HSCKB),
    .NL(NL),

    .VE(VE),
    .HE(HE),

    .BIT(BITB),
    .COL(COLB),
    .CP15(CP15B),
    .CP8(CP8B),

    .sdr_addr(addr_b),
    .sdr_data(sdr_data_b),
    .sdr_req(sdr_req_b),
    .sdr_ack(sdr_ack_b),

    .enabled(en_layer_b),
    .paused(paused),

    .m84(m84)
);

wire [4:0] r_out, g_out, b_out;
wire [15:0] pal_dout;
wire pal_dout_valid;

wire a_opaque = (BITA != 4'b0000);
wire b_opaque = (BITB != 4'b0000);

wire S = a_opaque;

assign P1L = ~(CP15A & a_opaque) & ~(CP15B & b_opaque) & ~(CP8A & BITA[3]) & ~(CP8B & BITB[3]);

kna91h014 kna91h014(
    .CLK_32M(CLK_32M),
    .CE_PIX(CE_PIX),

    .G(palette_memrq),
    .SELECT(S),
    .CA({COLA, BITA}),
    .CB({COLB, BITB}),

    .E1_N(), // TODO
    .E2_N(), // TODO
    
    .MWR(MWR & BYTE_SEL[0]),
    .MRD(MRD),

    .DIN(DIN),
    .DOUT(pal_dout),
    .DOUT_VALID(pal_dout_valid),
    .A(A),

    .RED(r_out),
    .GRN(g_out),
    .BLU(b_out)
);

assign RED = en_palette ? r_out : b_opaque ? { BITB, BITB[3] } : { BITA, BITA[3] };
assign GREEN = en_palette ? g_out : b_opaque ? { BITB, BITB[3] } : { BITA, BITA[3] };
assign BLUE = en_palette ? b_out : b_opaque ? { BITB, BITB[3] } : { BITA, BITA[3] };

endmodule




//============================================================================
//  Irem M92 for MiSTer FPGA - Programmable interrupt controller
//
//  Copyright (C) 2023 Martin Donlon
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

module m92_pic(
    input clk,
    input ce,
    input reset,

    input cs,
    input wr,
    input rd,
    input a0,

    input [7:0] din,

    output int_req,
    output reg [8:0] int_vector,
    input int_ack,

    input [7:0] intp
);

enum {
    UNINIT,
    INIT_IW2,
    INIT_IW3,
    INIT_IW4,
    INIT_DONE
} init_state = UNINIT;

reg [7:0] IW1, IW2, IW3, IW4;
reg [7:0] IMW;
reg [7:0] PFCW;
reg [7:0] MCW;

reg [7:0] IRR;
int ISR;

wire [7:0] IRQ = ( IRR & ~IMW );
assign int_req = IRQ != 8'd0;

wire iw4_write = IW1[0];
wire iw4_not_written = ~IW1[0];
wire single_mode = IW1[1];
wire extended_mode = ~IW1[1];
wire address_gap_4 = IW1[2];
wire address_gap_8 = ~IW1[2];
wire level_triggered = IW1[3];
wire edge_triggered = ~IW1[3];

reg [7:0] intp_latch = 0;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        init_state <= UNINIT;
        intp_latch <= 0;
        IRR <= 8'd0;
        ISR <= 8;
    end else if (ce) begin
        if (cs & wr) begin
            if (~a0) begin
                if (din[4]) begin
                    init_state <= INIT_IW2;
                    IW1 <= din;
                    PFCW <= 0;
                    MCW <= 0;
                    IMW <= 0;
                    IRR <= 0;
                    ISR <= 8;
                end else if (~din[4] & ~din[3]) begin
                    PFCW <= din;
                end else if (~din[4] & din[3]) begin
                    MCW <= din;
                end
            end

            if (a0) begin
                case (init_state)
                INIT_IW2: begin
                    IW2 <= din;
                    if (extended_mode) init_state <= INIT_IW3;
                    else if (iw4_write) init_state <= INIT_IW4;
                    else init_state <= INIT_DONE;
                end
                INIT_IW3: begin
                    IW3 <= din;
                    if (iw4_write) init_state <= INIT_IW4;
                    else init_state <= INIT_DONE;
                end
                INIT_IW4: begin
                    IW4 <= din;
                    init_state <= INIT_DONE;
                end
                INIT_DONE: begin
                    IMW <= din;
                end
                endcase
            end
        end

        if (init_state == INIT_DONE) begin
            bit [7:0] trig;
            int p;

            intp_latch <= intp;

            if (int_req) begin
                if (int_ack) begin
                    if ( IRQ[0] ) begin int_vector <= {IW2[6:3], 3'd0, 2'b00}; IRR[0] <= 0; end
                    else if ( IRQ[1] ) begin int_vector <= {IW2[6:3], 3'd1, 2'b00}; IRR[1] <= 0; end
                    else if ( IRQ[2] ) begin int_vector <= {IW2[6:3], 3'd2, 2'b00}; IRR[2] <= 0; end
                    else if ( IRQ[3] ) begin int_vector <= {IW2[6:3], 3'd3, 2'b00}; IRR[3] <= 0; end
                    else if ( IRQ[4] ) begin int_vector <= {IW2[6:3], 3'd4, 2'b00}; IRR[4] <= 0; end
                    else if ( IRQ[5] ) begin int_vector <= {IW2[6:3], 3'd5, 2'b00}; IRR[5] <= 0; end
                    else if ( IRQ[6] ) begin int_vector <= {IW2[6:3], 3'd6, 2'b00}; IRR[6] <= 0; end
                    else if ( IRQ[7] ) begin int_vector <= {IW2[6:3], 3'd7, 2'b00}; IRR[7] <= 0; end
                end
            end

            if (edge_triggered)
                trig = intp & ~intp_latch;
            else
                trig = intp;
            
            for( p = 0; p < 8; p = p + 1 ) begin
                if (intp[p]) begin
                    if (trig[p]) begin
                        IRR[p] <= 1'b1;
                    end
                end
            end
        end
    end
end

endmodule
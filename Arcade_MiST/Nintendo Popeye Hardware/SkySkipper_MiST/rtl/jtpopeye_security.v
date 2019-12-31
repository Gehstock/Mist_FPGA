/*  This file is part of JTPOPEYE.
    JTPOPEYE program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTPOPEYE program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR AD PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTPOPEYE.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 12-3-2019 */

`timescale 1ns/1ps

// 7J: '139 decoder
// /MemWR and /MemRD serve as enable signals. If H all outputs will be H
//
// /OE is the same as addr1
// Mode is the same addr0. Mode pin is not used in this model.
//
//    CPU         || /MemWR ||  /MemRD
// /sec_cs addr0  || A[1:0] || /OE     || Mode
// ===========================================
//   0     0      ||  10    ||  1      ||   0
//   0     1      ||  01    ||  0      ||   1
//   1     x      ||  11    ||  1      ||   1

// based on code provided by www.JAMMARCADE.net

module jtpopeye_security(
    input            clk,
    input            cen,
    input      [7:0] din,
    output reg [7:0] dout,
    input            cs,
    input            A0,
    input            rd_n,
    input            wr_n
);

reg [7:0] fifo [1:0];
reg [2:0] shift;

reg last_addr0, last_addr1;
reg addr0, addr1, oen;
wire csn = ~cs;
reg [7:0] result;

always @(*) begin
    addr0 = 1'b1;
    addr1 = 1'b1;
    oen   = 1'b1;
   // mode  = 1'b1;
    if( csn ) begin
        if(!wr_n) begin
            addr0 = A0;
            addr1 = ~A0;
        end
        if(!rd_n) begin
            oen =   A0;
            //mode = ~A0;
        end
    end
    // dout = result;
    // dout = A0 ? 8'd0 : result;
end


always @(posedge clk) if(cen) begin
    // if( !addr0 )
    //     shift <= din[2:0];
    // if( !addr1 ) begin
    //     fifo[0] <= fifo[1];
    //     fifo[1] <= din;
    // end
    if( cs && !wr_n ) begin
        if( A0 ) begin
            fifo[0] <= fifo[1];
            fifo[1] <= din;
        end else begin
            shift <= din[2:0];
        end
    end
    result <= (fifo[1] << shift) | (fifo[0] >> (4'd8-{1'b0,shift}));
    // dout   <= { result[7:3], A0 ? 3'd0 : result[2:0] }; 
    if( cs && !rd_n) dout <= A0 ? 8'd0 : result;
end


endmodule
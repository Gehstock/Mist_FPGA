/*  This file is part of JT5205.
    JT5205 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT5205 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT5205.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 30-12-2019 */

// Simple 2x interpolator
// Reduces HF content without altering too much the
// original sound

module jt5205_interpol2x(
    input                      rst,
    input                      clk,
    (* direct_enable *) input  cen_mid,
    input      signed [11:0]   din,
    output reg signed [11:0]   dout
);

reg signed [11:0] last;

always @(posedge clk, posedge rst) begin
    if(rst) begin
        last <= 12'd0;
        dout <= 12'd0;
    end else if(cen_mid) begin
        last <= din;
        dout <= (last>>>1)+(din>>>1);
    end
end

endmodule

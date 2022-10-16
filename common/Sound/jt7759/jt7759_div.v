/*  This file is part of JT7759.
    JT7759 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT7759 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT7759.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 5-7-2020 */

module jt7759_div(
    input            clk,
    input            cen,  // 640kHz
    input      [5:0] divby,
    output reg       cen_ctl,   // control = 8x faster than decoder
    output reg       cen_dec
);

reg [1:0] cnt4;
reg [5:0] decdiv, ctldiv, divby_l;
wire      eoc_ctl, eoc_dec, eoc_cnt; //  end of count

assign eoc_ctl = ctldiv == { 1'b0, divby_l[5:1] };
assign eoc_dec = decdiv == divby_l;
assign eoc_cnt = &cnt4;

`ifdef SIMULATION
initial begin
    cnt4   = 2'd0;
    divby_l= 0;
    decdiv = 6'd3; // bad start numbers to show the auto allignment feature
    ctldiv = 6'd7;
end
`endif

always @(posedge clk) if(cen) begin
    cnt4   <= cnt4+2'd1;
    if( eoc_cnt ) begin
        decdiv <= eoc_dec ? 6'd0 : (decdiv+1'd1);
        if( eoc_dec ) divby_l <= divby < 9 ? 9 : divby; // The divider is updated only at EOC
    end
    ctldiv <= eoc_ctl || (eoc_dec && eoc_cnt) ? 6'd0 : (ctldiv+1'd1);
end

always @(posedge clk) begin
    cen_ctl <= cen; // && eoc_ctl;
    cen_dec <= cen && eoc_dec && eoc_cnt;
end

endmodule
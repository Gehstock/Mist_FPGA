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
    Date: 30-10-2019 */

module jt5205(
    input                  rst,
    input                  clk,
    input                  cen /* direct_enable */,
    input         [ 1:0]   sel,        // s pin
    input         [ 3:0]   din,
    output signed [11:0]   sound,
    output                 sample,
    // This output pin is not part of MSM5205 I/O
    // It helps integrating the system as it produces
    // a strobe
    // at the internal clock divider pace
    output                 irq,
    output                 vclk_o
    `ifdef JT5205_DEBUG
    ,
    output signed [11:0]   debug_raw,
    output                 debug_cen_lo
    `endif
);

// Enabling the interpolator changes the sound of Chun Li's beat in
// SF2 too much. So I decided to disable it
parameter INTERPOL=0; // 1 for simple linear interpolation. 0 for raw output

wire               cen_lo, cen_mid;
wire signed [11:0] raw;

assign irq=cen_lo; // Notice that irq is active even if rst is high. This is
    // important for games such as Tora e no michi.

`ifdef JT5205_DEBUG
assign debug_raw    = raw;
assign debug_cen_lo = cen_lo;
`endif


jt5205_timing u_timing(
    .clk    ( clk       ),
    .cen    ( cen       ),
    .sel    ( sel       ),
    .cen_lo ( cen_lo    ),
    .cen_mid( cen_mid   ),
    .cenb_lo(           ),
    .vclk_o (vclk_o     )
);

jt5205_adpcm u_adpcm(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen_lo ( cen_lo    ),
    .cen_hf ( cen       ),
    .din    ( din       ),
    .sound  ( raw       )
);

generate
    if( INTERPOL == 1 ) begin
        jt5205_interpol2x u_interpol(
            .rst    ( rst       ),
            .clk    ( clk       ),
            .cen_mid( cen_mid   ),
            .din    ( raw       ),
            .dout   ( sound     )
        );
        assign sample=cen_mid; // 2x the original sampling freq. because of interpolator
    end else begin
        assign sound  = raw;
        assign sample = cen_lo;
    end
endgenerate


endmodule
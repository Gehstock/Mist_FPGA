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

module jt7759(
    input                  rst,
    input                  clk,  // Use same clock as sound CPU
    input                  cen,  // 640kHz
    input                  stn,  // STart (active low)
    input                  cs,
    input                  mdn,  // MODE: 1 for stand alone mode, 0 for slave mode
                                 // see chart in page 13 of PDF
    output                 busyn,
    // CPU interface
    input                  wrn,  // for slave mode only, 31.7us after drqn is set
    input         [ 7:0]   din,
    output                 drqn,  // data request. 50-70us delay after mdn goes low
    // ROM interface
    output                 rom_cs,      // equivalent to DRQn in original chip
    output        [16:0]   rom_addr,
    input         [ 7:0]   rom_data,
    input                  rom_ok,
    // Sound output
    output signed [ 8:0]   sound

`ifdef DEBUG
    ,output [3:0] debug_nibble
    ,output       debug_cen_dec
    ,output       debug_dec_rst
`endif
);

wire   [ 5:0] divby;
wire          cen_dec;    // internal clock enable for sound
wire          cen_ctl;    // cen_dec x4

wire          dec_rst;
wire   [ 3:0] encoded;

wire          ctrl_cs, ctrl_ok, ctrl_flush;
wire   [16:0] ctrl_addr;
wire   [ 7:0] ctrl_din;


`ifdef DEBUG
    assign debug_nibble  = encoded;
    assign debug_cen_dec = cen_dec;
    assign debug_dec_rst = dec_rst;
`endif

jt7759_div u_div(
    .clk        ( clk       ),
    .cen        ( cen       ),
    .cen_ctl    ( cen_ctl   ),
    .divby      ( divby     ),
    .cen_dec    ( cen_dec   )
);

jt7759_ctrl u_ctrl(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen_ctl    ( cen_ctl   ),
    .cen_dec    ( cen_dec   ),
    .divby      ( divby     ),
    // chip interface
    .stn        ( stn       ),
    .cs         ( cs        ),
    .mdn        ( mdn       ),
    .drqn       ( drqn      ),
    .busyn      ( busyn     ),
    .wrn        ( wrn       ),
    .din        ( din       ),
    // ADPCM engine
    .dec_rst    ( dec_rst   ),
    .dec_din    ( encoded   ),
    // ROM interface
    .rom_cs     ( ctrl_cs   ),
    .rom_addr   ( ctrl_addr ),
    .rom_data   ( ctrl_din  ),
    .rom_ok     ( ctrl_ok   ),
    .flush      ( ctrl_flush)
);

jt7759_data u_data(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen_ctl    ( cen_ctl   ),
    .cen_dec    ( cen_dec   ),
    .mdn        ( mdn       ),
    // Control interface
    .ctrl_flush ( ctrl_flush),
    .ctrl_cs    ( ctrl_cs   ),
    .ctrl_addr  ( ctrl_addr ),
    .ctrl_din   ( ctrl_din  ),
    .ctrl_ok    ( ctrl_ok   ),
    .ctrl_busyn ( busyn     ),
    // ROM interface
    .rom_cs     ( rom_cs    ),
    .rom_addr   ( rom_addr  ),
    .rom_data   ( rom_data  ),
    .rom_ok     ( rom_ok    ),
    // Passive interface
    .cs         ( cs        ),
    .wrn        ( wrn       ),
    .din        ( din       ),
    .drqn       ( drqn      )
);

jt7759_adpcm u_adpcm(
    .rst        ( dec_rst   ),
    .clk        ( clk       ),
    .cen_dec    ( cen_dec   ),
    .encoded    ( encoded   ),
    .sound      ( sound     )
);


`ifdef SIMULATION
integer fsnd;
initial begin
    fsnd=$fopen("jt7759.raw","wb");
end
wire signed [15:0] snd_log = { sound, 7'b0 };
always @(posedge cen_dec) begin
    $fwrite(fsnd,"%u", {snd_log, snd_log});
end
`endif
endmodule
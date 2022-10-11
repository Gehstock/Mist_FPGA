/*  This file is part of JTOPL.

    JTOPL is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTOPL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTOPL.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 17-6-2020

    */

module jtopl_eg_comb(
    input wire          keyon_now,
    input wire          keyoff_now,
    input wire  [ 2:0]  state_in,
    input wire  [ 9:0]  eg_in,
    // envelope configuration
    input wire          en_sus, // enable sustain
    input wire  [ 3:0]  arate, // attack  rate
    input wire  [ 3:0]  drate, // decay   rate
    input wire  [ 3:0]  rrate,
    input wire  [ 3:0]  sl,   // sustain level    

    output wire [ 4:0]  base_rate,
    output wire [ 2:0]  state_next,
    output wire         pg_rst,
    ///////////////////////////////////
    // II
    input wire          step_attack,
    input wire  [ 4:0]  step_rate_in,
    input wire  [ 3:0]  keycode,
    input wire  [14:0]  eg_cnt,
    input wire          cnt_in,
    input wire          ksr,
    output wire         cnt_lsb,
    output wire         step,
    output wire [ 5:0]  step_rate_out,
    output wire         sum_up_out,
    ///////////////////////////////////
    // III
    input wire          pure_attack,
    input wire          pure_step,
    input wire  [ 5:1]  pure_rate,
    input wire  [ 9:0]  pure_eg_in,
    output wire  [ 9:0]  pure_eg_out,
    input wire          sum_up_in,
    ///////////////////////////////////
    // IV
    input wire  [ 3:0]  lfo_mod,
    input wire  [ 3:0]  fnum,
    input wire  [ 2:0]  block,
    input wire          amsen,
    input wire          ams,
    input wire  [ 5:0]  tl,
    input wire  [ 1:0]  ksl,
    input wire  [ 3:0]  final_keycode,
    input wire  [ 9:0]  final_eg_in,
    output wire [ 9:0]  final_eg_out
);

// I
jtopl_eg_ctrl u_ctrl(    
    .keyon_now      ( keyon_now     ),
    .keyoff_now     ( keyoff_now    ),
    .state_in       ( state_in      ),
    .eg             ( eg_in         ),
    // envelope configuration
    .en_sus         ( en_sus        ),
    .arate          ( arate         ), // attack  rate
    .drate          ( drate         ), // decay   rate
    .rrate          ( rrate         ),
    .sl             ( sl            ), // sustain level

    .base_rate      ( base_rate     ),
    .state_next     ( state_next    ),
    .pg_rst         ( pg_rst        )
);

// II

jtopl_eg_step u_step(
    .attack     ( step_attack   ),
    .base_rate  ( step_rate_in  ),
    .keycode    ( keycode       ),
    .eg_cnt     ( eg_cnt        ),
    .cnt_in     ( cnt_in        ),
    .ksr        ( ksr           ),
    .cnt_lsb    ( cnt_lsb       ),
    .step       ( step          ),
    .rate       ( step_rate_out ),
    .sum_up     ( sum_up_out    )
);

// III

wire [9:0] egin, egout;
jtopl_eg_pure u_pure(
    .attack ( pure_attack   ),
    .step   ( pure_step     ),
    .rate   ( pure_rate     ),
    .eg_in  ( pure_eg_in    ),
    .eg_pure( pure_eg_out   ),
    .sum_up ( sum_up_in     )
);

// IV

jtopl_eg_final u_final(
    .fnum       ( fnum          ),
    .block      ( block         ),
    .lfo_mod    ( lfo_mod       ),
    .amsen      ( amsen         ),
    .ams        ( ams           ),
    .tl         ( tl            ),
    .ksl        ( ksl           ),
    .keycode    ( final_keycode ),
    .eg_pure_in ( final_eg_in   ),
    .eg_limited ( final_eg_out  )
);

endmodule // jtopl_eg_comb
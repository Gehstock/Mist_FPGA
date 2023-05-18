//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_sprite.vhd,v 1.11 2006/06/18 10:47:06 arnim Exp $
//
// Sprite Generation Controller
//
// Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// SystemVerilog conversion (c) 2022 Frank Bruno (fbruno@asicsolutions.com)
//
//-----------------------------------------------------------------------------

import vdp18_pkg::*;

module vdp18_sprite
  (
    input              clk_i,
    input              clk_en_5m37_i,
    input              clk_en_acc_i,
    input              reset_i,

    input access_t     access_type_i,
    input signed [0:8] num_pix_i,
    input signed [0:8] num_line_i,

    input [0:7]        vram_d_i,
    input              vert_inc_i,
    input              reg_size1_i,
    input              reg_mag1_i,
    output logic       spr_5th_o,
    output logic [0:4] spr_5th_num_o,
    output logic       stop_sprite_o,
    output logic       spr_coll_o,
    output logic [0:4] spr_num_o,
    output logic [0:3] spr_line_o,
    output logic [0:7] spr_name_o,
    output logic [0:3] spr0_col_o,
    output logic [0:3] spr1_col_o,
    output logic [0:3] spr2_col_o,
    output logic [0:3] spr3_col_o
   );

  logic [0:4]          sprite_numbers_q[0:3];

  logic [0:4]          sprite_num_q;
  logic [0:2]          sprite_idx_q;
  logic [0:7]          sprite_name_q;

  logic [0:7]          sprite_xpos_q[0:3];
  logic [0:3]          sprite_ec_q;
  logic [0:3]          sprite_xtog_q;

  logic [0:3]          sprite_cols_q[0:3];

  logic [0:15]         sprite_pats_q[0:3];

  logic [0:3]          sprite_line_s;
  logic [0:3]          sprite_line_q;
  logic                sprite_visible_s;

  logic [0:2]          sprite_idx_inc_v;
  logic [0:2]          sprite_idx_dec_v;
  logic [1:0]          sprite_idx_v;

  // sprite index will be incremented during sprite tests
  assign sprite_idx_inc_v = sprite_idx_q + 1'b1;
  // sprite index will be decremented at end of sprite pattern data
  assign sprite_idx_dec_v = sprite_idx_q - 1'b1;
  // just save typing
  assign sprite_idx_v = sprite_idx_q[1:2];

  //---------------------------------------------------------------------------
  // Process seq
  //
  // Purpose:
  //  Implements the sequential elements.
  //

  always @(posedge clk_i, posedge reset_i )
    begin: seq
      if (reset_i)
        begin
          sprite_numbers_q <= '{default: '0};
          sprite_num_q     <= '0;
          sprite_idx_q     <= '0;
          sprite_line_q    <= '0;
          sprite_name_q    <= '0;
          sprite_cols_q    <= '{default: '0};
          sprite_xpos_q    <= '{default: '0};
          sprite_ec_q      <= '0;
          sprite_xtog_q    <= '0;
          sprite_pats_q    <= '{default: '0};
        end
      else
        begin
          if (clk_en_5m37_i)
            begin
              // pre-decrement index counter when sprite reading starts
              if ((num_pix_i == hv_sprite_start_c) && (sprite_idx_q > 0))
                sprite_idx_q <= sprite_idx_dec_v;

              //---------------------------------------------------------------------
              // X position counters
              //---------------------------------------------------------------------
              for (int idx = 0; idx <= 3; idx++)
                if (~num_pix_i[0] || (sprite_ec_q[idx] && (&num_pix_i[0:3])))
                  begin
                    if (sprite_xpos_q[idx])
                      // decrement counter until 0
                      sprite_xpos_q[idx] <= sprite_xpos_q[idx] - 1'b1;
                    else
                      // toggle magnification flag
                      sprite_xtog_q[idx] <= ~sprite_xtog_q[idx];
                  end

              //---------------------------------------------------------------------
              // Sprite pattern shift registers
              //---------------------------------------------------------------------
              for (int idx = 0; idx <= 3; idx++)
                begin
                  if (sprite_xpos_q[idx] == '0)		// x counter elapsed
                    begin
                      // decide when to shift pattern information
                      // case 1: pixel number is >= 0
                      //         => active display area
                      // case 2: early clock bit is set and pixel number is between
                      //         -32 and 0
                      //   shift if
                      //     magnification not enbled
                      //       or
                      //     magnification enabled and toggle marker true
                      if ((~num_pix_i[0] || (sprite_ec_q[idx] && (&num_pix_i[0:3]))) && (sprite_xtog_q[idx] || ~reg_mag1_i))
                        begin
                          //
                          // shift pattern left and fill vacated position with
                          // transparent information
                          sprite_pats_q[idx][0:14] <= sprite_pats_q[idx][1:15];
                          sprite_pats_q[idx][15] <= 1'b0;
                        end
                    end

                  // clear pattern at end of visible display
                  // this removes "left-overs" when a sprite overlaps the right border
                  if (num_pix_i == 9'b011111111)
                    sprite_pats_q[idx] <= '0;
                end
            end

          if (vert_inc_i)
            begin
              // reset sprite num counter and sprite index counter
              sprite_num_q <= '0;
              sprite_idx_q <= '0;
            end

          else if (clk_en_acc_i)
            case (access_type_i)
              AC_STST :
                begin
                  // increment sprite number counter
                  sprite_num_q <= sprite_num_q + 1'b1;

                  if (sprite_visible_s)
                    begin
                      if (sprite_idx_q < 4)
                        begin
                          // store sprite number
                          sprite_numbers_q[sprite_idx_v] <= sprite_num_q;
                          // and increment index counter
                          sprite_idx_q <= sprite_idx_inc_v;
                        end
                    end
                end

              AC_SATY :
                // store sprite line
                sprite_line_q <= sprite_line_s;

              AC_SATX :
                begin
                  // save x position
                  sprite_xpos_q[sprite_idx_v] <= vram_d_i;
                  // reset toggle flag for magnified sprites
                  sprite_xtog_q[sprite_idx_v] <= '0;
                end

              AC_SATN :
                // save sprite name
                sprite_name_q <= vram_d_i;

              AC_SATC :
                begin
                  // save sprite color
                  sprite_cols_q[sprite_idx_v] <= vram_d_i[4:7];
                  // and save early clock bit
                  sprite_ec_q[sprite_idx_v] <= vram_d_i[0];
                end

              AC_SPTH :
                begin
                  // save upper pattern data
                  sprite_pats_q[sprite_idx_v][0:7] <= vram_d_i;
                  // set lower part to transparent
                  sprite_pats_q[sprite_idx_v][8:15] <= '0;

                  if (~reg_size1_i)
                    // decrement index counter in 8-bit mode
                    sprite_idx_q <= sprite_idx_dec_v;
                end

              AC_SPTL :
                begin
                  // save lower pattern data
                  sprite_pats_q[sprite_idx_v][8:15] <= vram_d_i;

                  // always decrement index counter
                  sprite_idx_q <= sprite_idx_dec_v;
                end
              default: begin end
            endcase
        end
    end

  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process calc_vert
  //
  // Purpose:
  //   Calculates the displayed line of the sprite and determines whether it
  //   is visible on the current line or not.
  //

  logic [0:8]        sprite_line_v;
  logic signed [0:8] vram_d_v;

  always_comb
    begin: calc_vert
      // default assignments
      sprite_visible_s = '0;
      stop_sprite_o    = '0;

      vram_d_v = signed'(vram_d_i);
      // determine if y information from VRAM should be treated
      // as a signed or unsigned number
      if (vram_d_v < -31)
        // treat as unsigned number
        vram_d_v[0] = 1'b0;

      sprite_line_v = num_line_i - vram_d_v;
      if (reg_mag1_i)
        // unmagnify line number
        sprite_line_v = {1'b0, sprite_line_v[0:7]};

      // check result bounds
      if (sprite_line_v >= 0)
        begin
          if (reg_size1_i)
            begin
              // double sized sprite: 16 data lines
              if (sprite_line_v < 16)
                sprite_visible_s = '1;
            end
          else
            // standard sized sprite: 8 data lines
            if (sprite_line_v < 8)
              sprite_visible_s = '1;
        end

      // finally: line number of current sprite
      sprite_line_s = sprite_line_v[5:8];

      if (clk_en_acc_i)
        begin
          // determine when to stop sprite scanning
          if (access_type_i == AC_STST)
            begin
              if (vram_d_v == 208)
                // stop upon Y position 208
                stop_sprite_o = '1;

              if (sprite_idx_q == 4)
                // stop when all sprite positions have been vacated
                stop_sprite_o = '1;

              if (sprite_num_q == 31)
                // stop when all sprites have been read
                stop_sprite_o = '1;
            end

          // stop sprite reading when last active sprite has been processed
          if ((sprite_idx_q == 0) && ((access_type_i == AC_SPTL) || ((access_type_i == AC_SPTH) && ~reg_size1_i)))
            stop_sprite_o = '1;
        end

      // stop sprite reading when no sprite is active on current line
      if ((num_pix_i == hv_sprite_start_c) && (sprite_idx_q == 0))
        stop_sprite_o = '1;
    end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process fifth
  //
  // Purpose:
  //   Detects the fifth sprite.
  //

  always_comb
    begin: fifth
      // default assignments
      spr_5th_o     = '0;
      spr_5th_num_o = '0;

      if (clk_en_acc_i && (access_type_i == AC_STST))
        begin
          if (sprite_visible_s && (sprite_idx_q == 4))
            begin
              spr_5th_o = '1;
              spr_5th_num_o = sprite_num_q;
            end
        end
    end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process col_mux
  //
  // Purpose:
  //   Implements the color multiplexers.
  //

  logic [0:3] spr_col[0:3];
  logic [0:2] num_spr_pix_v;

  always_comb begin: col_mux
    // default assignments
    // sprite colors are set to transparent
    spr_col       = '{default: '0};
    num_spr_pix_v = '0;

    for (int i = 0; i < 4; i++) begin
      if (~|sprite_xpos_q[i] && sprite_pats_q[i][0])
        begin
          spr_col[i] = sprite_cols_q[i];
          num_spr_pix_v++;
        end
    end
  end : col_mux

  assign spr_coll_o = num_spr_pix_v > 1;
  assign spr0_col_o = spr_col[0];
  assign spr1_col_o = spr_col[1];
  assign spr2_col_o = spr_col[2];
  assign spr3_col_o = spr_col[3];

  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Output mapping
  //---------------------------------------------------------------------------
  assign spr_num_o = (access_type_i == AC_STST) ? sprite_num_q :
                     (sprite_numbers_q[(sprite_idx_q[1:2])]);
  assign spr_line_o = sprite_line_q;
  assign spr_name_o = sprite_name_q;

endmodule

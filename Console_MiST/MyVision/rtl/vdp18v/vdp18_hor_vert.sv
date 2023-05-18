//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_hor_vert.vhd,v 1.11 2006/06/18 10:47:01 arnim Exp $
//
// Horizontal / Vertical Timing Generator
//
//-----------------------------------------------------------------------------
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

module vdp18_hor_vert
  #
  (
   parameter   is_pal_g = 0
   )
  (
   input                     clk_i,
   input                     clk_en_5m37_i,
   input                     reset_i,
   input  opmode_t           opmode_i,
   output logic signed [0:8] num_pix_o,
   output logic signed [0:8] num_line_o,
   output logic              vert_inc_o,
   output logic              hsync_n_o,
   output logic              vsync_n_o,
   output logic              blank_o,
   output logic              hblank_o,
   output logic              vblank_o
   );

  logic        signed [0:8] last_line_s;
  logic        signed [0:8] first_line_s;

  logic         signed [0:8] first_pix_s;
  logic         signed [0:8] last_pix_s;

  logic         signed [0:8] cnt_hor_q;
  logic         signed [0:8] cnt_vert_q;

  logic                     vert_inc_s;

  logic                      hblank_q;
  logic                      vblank_q;

  //---------------------------------------------------------------------------
  // Prepare comparison signals for NTSC and PAL.
  //
  always_comb begin
    if (is_pal_g == 1)
      begin : is_pal
        first_line_s = hv_first_line_pal_c;
        last_line_s = hv_last_line_pal_c;
      end else begin : is_ntsc
        first_line_s = hv_first_line_ntsc_c[8:0];
        last_line_s = hv_last_line_ntsc_c[8:0];
      end
  end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process opmode_mux
  //
  // Purpose:
  //   Generates the horizontal counter limits based on the current operating
  //   mode.
  //

  always_comb
    begin: opmode_mux
      if (opmode_i == OPMODE_TEXTM)
        begin
          first_pix_s = hv_first_pix_text_c[8:0];
          last_pix_s = hv_last_pix_text_c[8:0];
        end
      else
        begin
          first_pix_s = hv_first_pix_graph_c[8:0];
          last_pix_s = hv_last_pix_graph_c[8:0];
        end
    end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process counters
  //
  // Purpose:
  //   Implements the horizontal and vertical counters.
  //

  always @(posedge clk_i, posedge reset_i )
    begin: counters
      if (reset_i)
        begin
          cnt_hor_q <= hv_first_pix_text_c[8:0];
          cnt_vert_q <= first_line_s;
          hsync_n_o <= 1'b1;
          vsync_n_o <= 1'b1;
          hblank_q <= 1'b0;
          vblank_q <= 1'b0;
        end

      else
        begin
          if (clk_en_5m37_i)
            begin
              // The horizontal counter ---------------------------------------------
              if (cnt_hor_q == last_pix_s)
                cnt_hor_q <= first_pix_s;
              else
                cnt_hor_q <= cnt_hor_q + 1'b1;

              // The vertical counter -----------------------------------------------
              if (cnt_vert_q == last_line_s)
                cnt_vert_q <= first_line_s;
              else if (vert_inc_s)
                // increment when horizontal counter is at trigger position
                cnt_vert_q <= cnt_vert_q + 1'b1;

              // Horizontal sync ----------------------------------------------------
              if (cnt_hor_q == -64)
                hsync_n_o <= 1'b0;
              else if (cnt_hor_q == -38)
                hsync_n_o <= 1'b1;
              if (cnt_hor_q == -72)
                hblank_q <= 1'b1;
              else if (cnt_hor_q == -14)
                hblank_q <= 1'b0;

              // Vertical sync ------------------------------------------------------
              if (is_pal_g == 1)
                begin
                  if (cnt_vert_q == 244)
                    vsync_n_o <= 1'b0;
                  else if (cnt_vert_q == 247)
                    vsync_n_o <= 1'b1;
                end
              else
                begin
                  if (cnt_vert_q == 218)
                    vsync_n_o <= 1'b0;
                  else if (cnt_vert_q == 221)
                    vsync_n_o <= 1'b1;

                  if (cnt_vert_q == 214)
                    vblank_q <= 1'b1;
                  else if (cnt_vert_q == first_line_s + 14)
                    vblank_q <= 1'b0;
                end
            end
        end
    end

  //
  //---------------------------------------------------------------------------

  // comparator for vertical line increment
  assign vert_inc_s = clk_en_5m37_i & cnt_hor_q == hv_vertical_inc_c;

  //---------------------------------------------------------------------------
  // Output mapping
  //---------------------------------------------------------------------------
  assign num_pix_o = cnt_hor_q;
  assign num_line_o = cnt_vert_q;
  assign vert_inc_o = vert_inc_s;
  assign blank_o = hblank_q | vblank_q;
  assign vblank_o = vblank_q;
  assign hblank_o = hblank_q;

endmodule

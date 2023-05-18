//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_col_mux.vhd,v 1.10 2006/06/18 10:47:01 arnim Exp $
//
// Color Information Multiplexer
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

module vdp18_col_mux
  #
  (
   parameter          compat_rgb_g = 0
   )
  (
   input              clk_i,
   input              clk_en_5m37_i,
   input              reset_i,
   input              vert_active_i,
   input              hor_active_i,
   input              border_i,
   input              blank_i,
   input              hblank_i,
   input              vblank_i,
   output logic       blank_n_o,
   output logic       hblank_n_o,
   output logic       vblank_n_o,
   input [0:3]        reg_col0_i,
   input [0:3]        pat_col_i,
   input [0:3]        spr0_col_i,
   input [0:3]        spr1_col_i,
   input [0:3]        spr2_col_i,
   input [0:3]        spr3_col_i,
   output logic [0:3] col_o,
   output logic [0:7] rgb_r_o,
   output logic [0:7] rgb_g_o,
   output logic [0:7] rgb_b_o
   );

  //---------------------------------------------------------------------------
  // Process col_mux
  //
  // Purpose:
  //   Multiplexes the color information from different sources.
  //

  always_comb
    begin: col_mux
      if (~blank_i)
        begin
          if (hor_active_i & vert_active_i)
            begin
                // priority decoder
                if (spr0_col_i != 4'b0000)
                    col_o = spr0_col_i;
                else if (spr1_col_i != 4'b0000)
                    col_o = spr1_col_i;
                else if (spr2_col_i != 4'b0000)
                    col_o = spr2_col_i;
                else if (spr3_col_i != 4'b0000)
                    col_o = spr3_col_i;
                else if (pat_col_i != 4'b0000)
                    col_o = pat_col_i;
                else
                    col_o = reg_col0_i;
            end
            else

                // display border
                col_o = reg_col0_i;
        end
        else

            // blank color channels during horizontal and vertical
            // trace back
            // required to initialize colors for each new scan line
            col_o = '0;
    end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process rgb_reg
  //
  // Purpose:
  //   Converts the color information to simple RGB and saves these in
  //   output registers.
  //

  const logic [7:0] compat_rgb_table_c[16][3] =
                    '{'{  0,   0,   0},                    // Transparent
                      '{  0,   0,   0},                    // Black
                      '{ 32, 192,  32},                    // Medium Green
                      '{ 96, 224,  96},                    // Light Green
                      '{ 32,  32, 224},                    // Dark Blue
                      '{ 64,  96, 224},                    // Light Blue
                      '{160,  32,  32},                    // Dark Red
                      '{ 64, 192, 224},                    // Cyan
                      '{224,  32,  32},                    // Medium Red
                      '{224,  96,  96},                    // Light Red
                      '{192, 192,  32},                    // Dark Yellow
                      '{192, 192, 128},                    // Light Yellow
                      '{ 32, 128,  32},                    // Dark Green
                      '{192,  64, 160},                    // Magenta
                      '{160, 160, 160},                    // Gray
                      '{224, 224, 224}};                   // White
  //---------------------------------------------------------------------------
  // Full RGB Value Array
  //
  // Refer to tms9928a.c of the MAME source distribution.
  //
  const logic [7:0] full_rgb_table_c[16][3] =
                    '{'{  0,   0,   0},                    // Transparent
                      '{  0,   0,   0},                    // Black
                      '{ 33, 200,  66},                    // Medium Green
                      '{ 94, 220, 120},                    // Light Green
                      '{ 84,  85, 237},                    // Dark Blue
                      '{125, 118, 252},                    // Light Blue
                      '{212,  82,  77},                    // Dark Red
                      '{ 66, 235, 245},                    // Cyan
                      '{252,  85,  84},                    // Medium Red
                      '{255, 121, 120},                    // Light Red
                      '{212, 193,  84},                    // Dark Yellow
                      '{230, 206, 128},                    // Light Yellow
                      '{ 33, 176,  59},                    // Dark Green
                      '{201,  91, 186},                    // Magenta
                      '{204, 204, 204},                    // Gray
                      '{255, 255, 255}};                   // White

  always @(posedge clk_i, posedge reset_i )
    begin: rgb_reg
        if (reset_i)
        begin
          rgb_r_o <= '0;
          rgb_g_o <= '0;
          rgb_b_o <= '0;
        end

        else
          begin
            if (clk_en_5m37_i)
              begin
                // select requested RGB table
                if (compat_rgb_g)
                  begin
                    rgb_r_o <= compat_rgb_table_c[col_o][0];
                    rgb_g_o <= compat_rgb_table_c[col_o][1];
                    rgb_b_o <= compat_rgb_table_c[col_o][2];
                  end
                else
                  begin
                    rgb_r_o <= full_rgb_table_c[col_o][0];
                    rgb_g_o <= full_rgb_table_c[col_o][1];
                    rgb_b_o <= full_rgb_table_c[col_o][2];
                  end

                blank_n_o <= ~blank_i;
                if (~border_i)
                  begin
                    hblank_n_o <= hor_active_i;
                    vblank_n_o <= vert_active_i;
                  end
                else
                  begin
                    hblank_n_o <= ~hblank_i;
                    vblank_n_o <= ~vblank_i;
                  end
              end
          end
    end
endmodule

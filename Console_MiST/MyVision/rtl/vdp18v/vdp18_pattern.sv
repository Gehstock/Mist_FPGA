//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_pattern.vhd,v 1.8 2006/06/18 10:47:06 arnim Exp $
//
// Pattern Generation Controller
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

module vdp18_pattern
  (
   input              clk_i,
   input              clk_en_5m37_i,
   input              clk_en_acc_i,
   input              reset_i,

   input opmode_t     opmode_i,
   input access_t     access_type_i,
   input signed [0:8] num_line_i,


   input [0:7]        vram_d_i,
   input              vert_inc_i,
   input              vsync_n_i,
   input [0:3]        reg_col1_i,
   input [0:3]        reg_col0_i,
   output logic [0:9] pat_table_o,
   output logic [0:7] pat_name_o,
   output logic [0:3] pat_col_o
   );


  logic [0:7]           pat_tmp_q;
  logic [0:7]           pat_shift_q;
  logic [0:7]           pat_col_q;

  //---------------------------------------------------------------------------
  // Process seq
  //
  // Purpose:
  //  Implements the sequential elements:
  //    * pattern shift register
  //    * pattern color register
  //    * pattern counter
  //

  always @(posedge clk_i, posedge reset_i )
    begin: seq
      if (reset_i)
        begin
          pat_table_o <= '0;
          pat_name_o  <= '0;
          pat_tmp_q   <= '0;
          pat_shift_q <= '0;
          pat_col_q   <= '0;
        end

      else
        begin
          if (clk_en_5m37_i) begin
            // shift pattern with every pixel clock
            pat_shift_q[0:6] <= pat_shift_q[1:7];
          end

          if (clk_en_acc_i) begin
            // determine register update based on current access type -------------
            case (access_type_i)
              AC_PNT :
                begin
                  // store pattern name
                  pat_name_o <= vram_d_i;
                  // increment pattern counter
                  pat_table_o<= pat_table_o + 1'b1;
                end

              AC_PCT : begin
                // store pattern color in temporary register
                pat_tmp_q <= vram_d_i;
              end

              AC_PGT :
                if (opmode_i == OPMODE_MULTIC)
                  begin
                    // set shift register to constant value
                    // this value generates 4 bits of color1
                    // followed by 4 bits of color0
                    pat_shift_q <= 8'b11110000;
                    // set pattern color from pattern generator memory
                    pat_col_q <= vram_d_i;
                  end
                else
                  begin
                    // all other modes:
                    // store pattern line in shift register
                    pat_shift_q <= vram_d_i;
                    // move pattern color from temporary register to color register
                    pat_col_q <= pat_tmp_q;
                  end
              default: begin end
            endcase
          end // if (clk_en_acc_i)

          if (vert_inc_i)
            begin
              // redo patterns of if there are more lines inside this pattern
              if (~num_line_i[0])
                case (opmode_i)
                  OPMODE_TEXTM :
                    if (num_line_i[6:8] != 3'b111)
                      pat_table_o <= pat_table_o - 10'd40;

                  OPMODE_GRAPH1, OPMODE_GRAPH2, OPMODE_MULTIC :
                    if (num_line_i[6:8] != 3'b111)
                      pat_table_o <= pat_table_o - 10'd32;
                  default: begin end
                endcase
            end

          if (vsync_n_i == 1'b0) begin
            // reset pattern counter at end of active display area
            pat_table_o <= '0;
          end
        end // else: !if(reset_i)
    end

  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process col_gen
  //
  // Purpose:
  //   Generates the color of the current pattern pixel.
  //

  always_comb
    begin: col_gen
      // default assignment
      pat_col_o = '0;

      case (opmode_i)
        // Text Mode ------------------------------------------------------------
        OPMODE_TEXTM :
          if (pat_shift_q[0])
            pat_col_o = reg_col1_i;
          else
            pat_col_o = reg_col0_i;

        // Graphics I, II and Multicolor Mode -----------------------------------
        OPMODE_GRAPH1, OPMODE_GRAPH2, OPMODE_MULTIC :
          if (pat_shift_q[0])
            pat_col_o = pat_col_q[0:3];
          else
            pat_col_o = pat_col_q[4:7];
        default: begin end

      endcase
    end
endmodule

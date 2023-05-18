//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_addr_mux.vhd,v 1.10 2006/06/18 10:47:01 arnim Exp $
//
// Address Multiplexer / Generator
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

module vdp18_addr_mux
  (
   input access_t      access_type_i,
   input opmode_t      opmode_i,
   input signed [0:8]  num_line_i,
   input [0:3]         reg_ntb_i,
   input [0:7]         reg_ctb_i,
   input [0:2]         reg_pgb_i,
   input [0:6]         reg_satb_i,
   input [0:2]         reg_spgb_i,
   input               reg_size1_i,
   input [0:13]        cpu_vram_a_i,
   input [0:9]         pat_table_i,
   input [0:7]         pat_name_i,
   input [0:4]         spr_num_i,
   input [0:3]         spr_line_i,
   input [0:7]         spr_name_i,
   output logic [0:13] vram_a_o
   );

  //---------------------------------------------------------------------------
  // Process mux
  //
  // Purpose:
  //   Generates the VRAM address based on the current access type.
  //

  always_comb
    begin: mux
        // default assignment
        vram_a_o = '0;

        case (access_type_i)
            // CPU Access -----------------------------------------------------------
            AC_CPU :
                vram_a_o = cpu_vram_a_i;

            // Pattern Name Table Access --------------------------------------------
            AC_PNT :
                begin
                    vram_a_o[0:3] = reg_ntb_i;
                    vram_a_o[4:13] = pat_table_i;
                end

            // Pattern Color Table Access -------------------------------------------
            AC_PCT :
                case (opmode_i)
                    OPMODE_GRAPH1 :
                        begin
                            vram_a_o[0:7] = reg_ctb_i;
                            vram_a_o[8] = '0;
                            vram_a_o[9:13] = pat_name_i[0:4];
                        end

                    OPMODE_GRAPH2 :
                        begin
                            vram_a_o[0] = reg_ctb_i[0];
                            // remaining bits in CTB mask color
                            // lookups
                            vram_a_o[1:2] = num_line_i[1:2] & {reg_ctb_i[1], reg_ctb_i[2]};
                            // remaining bits in CTB mask color
                            // lookups
                            vram_a_o[3:10] = pat_name_i & {reg_ctb_i[3], reg_ctb_i[4], reg_ctb_i[5], reg_ctb_i[6], reg_ctb_i[7], 3'b111};
                            vram_a_o[11:13] = num_line_i[6:8];
                        end
                  default: begin end
                endcase

            // Pattern Generator Table Access ---------------------------------------
            AC_PGT :
                case (opmode_i)
                    OPMODE_TEXTM, OPMODE_GRAPH1 :
                        begin
                            vram_a_o[0:2] = reg_pgb_i;
                            vram_a_o[3:10] = pat_name_i;
                            vram_a_o[11:13] = num_line_i[6:8];
                        end

                    OPMODE_MULTIC :
                        begin
                            vram_a_o[0:2] = reg_pgb_i;
                            vram_a_o[3:10] = pat_name_i;
                            vram_a_o[11:13] = num_line_i[4:6];
                        end

                    OPMODE_GRAPH2 :
                        begin
                            vram_a_o[0] = reg_pgb_i[0];
                            // remaining bits in PGB mask pattern
                            // lookups
                            vram_a_o[1:2] = num_line_i[1:2] & {reg_pgb_i[1], reg_pgb_i[2]};
                            // remaining bits in CTB mask pattern
                            // lookups
                            vram_a_o[3:10] = pat_name_i & {reg_ctb_i[3], reg_ctb_i[4], reg_ctb_i[5], reg_ctb_i[6], reg_ctb_i[7], 3'b111};
                            vram_a_o[11:13] = num_line_i[6:8];
                        end
                endcase

            // Sprite Test ----------------------------------------------------------
            AC_STST, AC_SATY :
                begin
                    vram_a_o[0:6] = reg_satb_i;
                    vram_a_o[7:11] = spr_num_i;
                    vram_a_o[12:13] = 2'b00;
                end

            // Sprite Attribute Table: X --------------------------------------------
            AC_SATX :
                begin
                    vram_a_o[0:6] = reg_satb_i;
                    vram_a_o[7:11] = spr_num_i;
                    vram_a_o[12:13] = 2'b01;
                end

            // Sprite Attribute Table: Name -----------------------------------------
            AC_SATN :
                begin
                    vram_a_o[0:6] = reg_satb_i;
                    vram_a_o[7:11] = spr_num_i;
                    vram_a_o[12:13] = 2'b10;
                end

            // Sprite Attribute Table: Color ----------------------------------------
            AC_SATC :
                begin
                    vram_a_o[0:6] = reg_satb_i;
                    vram_a_o[7:11] = spr_num_i;
                    vram_a_o[12:13] = 2'b11;
                end

            // Sprite Pattern, Upper Part -------------------------------------------
            AC_SPTH :
                begin
                    vram_a_o[0:2] = reg_spgb_i;
                    if (~reg_size1_i)
                    begin
                        // 8x8 sprite
                        vram_a_o[3:10] = spr_name_i;
                        vram_a_o[11:13] = spr_line_i[1:3];
                    end
                    else
                    begin
                        // 16x16 sprite
                        vram_a_o[3:8] = spr_name_i[0:5];
                        vram_a_o[9] = 1'b0;
                        vram_a_o[10:13] = spr_line_i;
                    end
                end

            // Sprite Pattern, Lower Part -------------------------------------------
            AC_SPTL :
                begin
                    vram_a_o[0:2] = reg_spgb_i;
                    vram_a_o[3:8] = spr_name_i[0:5];
                    vram_a_o[9] = 1'b1;
                    vram_a_o[10:13] = spr_line_i;
                end
          default: vram_a_o = '0;
        endcase
    end

endmodule


//
//---------------------------------------------------------------------------

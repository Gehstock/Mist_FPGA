//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_clk_gen.vhd,v 1.8 2006/06/18 10:47:01 arnim Exp $
//
// Clock Generator
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

module vdp18_clk_gen
  (
   input        clk_i,
   input        clk_en_10m7_i,
   input        reset_i,
   output logic clk_en_5m37_o,
   output logic clk_en_3m58_o,
   output logic clk_en_2m68_o
   );

    logic [3:0]  cnt_q;

    //---------------------------------------------------------------------------
    // Process seq
    //
    // Purpose:
    //   Implements the sequential elements.
    //   * clock counter
    //

    always @(posedge clk_i, posedge reset_i )
    begin: seq
        if (reset_i) cnt_q <= '0;
        else
        begin
            if (clk_en_10m7_i)
            begin
                if (cnt_q == 11)
                    // wrap after counting 12 clocks
                    cnt_q <= '0;
                else
                    cnt_q <= cnt_q + 1'b1;
            end
        end
    end

    //
    //---------------------------------------------------------------------------

    //---------------------------------------------------------------------------
    // Process clk_en
    //
    // Purpose:
    //   Generates the derived clock enable signals.
    //

    always_comb
    begin: clk_en
        // 5.37 MHz clock enable --------------------------------------------------
        if (clk_en_10m7_i)
            case (cnt_q)
                1, 3, 5, 7, 9, 11 :
                    clk_en_5m37_o = '1;
                default :
                    clk_en_5m37_o = '0;
            endcase
        else
            clk_en_5m37_o = '0;

        // 3.58 MHz clock enable --------------------------------------------------
        if (clk_en_10m7_i)
            case (cnt_q)
                2, 5, 8, 11 :
                    clk_en_3m58_o = '1;
                default :
                    clk_en_3m58_o = '0;
            endcase
        else
            clk_en_3m58_o = 1'b0;

        // 2.68 MHz clock enable --------------------------------------------------
        if (clk_en_10m7_i)
            case (cnt_q)
                3, 7, 11 :
                    clk_en_2m68_o = '1;
                default :
                    clk_en_2m68_o = '0;
            endcase
        else
            clk_en_2m68_o = '0;
    end

endmodule

//
//---------------------------------------------------------------------------

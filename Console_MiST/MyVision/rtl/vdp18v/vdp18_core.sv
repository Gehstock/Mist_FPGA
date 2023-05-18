//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_core.vhd,v 1.28 2006/06/18 10:47:01 arnim Exp $
//
// Core Toplevel
//
// Notes:
//   This core implements a simple VRAM interface which is suitable for a
//   synchronous SRAM component. There is currently no support of the
//   original DRAM interface.
//
//   Please be aware that the colors might me slightly different from the
//   original TMS9918. It is assumed that the simplified conversion to RGB
//   encoding is equivalent to the compatability mode of the V9938.
//   Implementing a 100% correct color encoding for RGB would require
//   significantly more logic and 8-bit wide RGB DACs.
//
// References:
//
//   * TI Data book TMS9918.pdf
//     http://www.bitsavers.org/pdf/ti/_dataBooks/TMS9918.pdf
//
//   * Sean Young's tech article:
//     http://bifi.msxnet.org/msxnet/tech/tms9918a.txt
//
//   * Paul Urbanus' discussion of the timing details
//     http://bifi.msxnet.org/msxnet/tech/tmsposting.txt
//
//   * Richard F. Drushel's article series
//     "This Week With My Coleco ADAM"
//     http://junior.apk.net/~drushel/pub/coleco/twwmca/index.html
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

module vdp18_core
  #
  (
   parameter     is_pal_g = 0,
   parameter     compat_rgb_g = 0
   )
  (
   // Global Interface -------------------------------------------------------
   input         clk_i,
   input         clk_en_10m7_i,
   input         reset_n_i,
   // CPU Interface ----------------------------------------------------------
   input         csr_n_i,
   input         csw_n_i,
   input         mode_i,
   output        int_n_o,
   input [0:7]   cd_i,
   output [0:7]  cd_o,
   // VRAM Interface ---------------------------------------------------------
   output        vram_we_o,
   output [0:13] vram_a_o,
   output [0:7]  vram_d_o,
   input [0:7]   vram_d_i,
   // Video Interface --------------------------------------------------------
   input         border_i,
   output [0:3]  col_o,
   output [0:7]  rgb_r_o,
   output [0:7]  rgb_g_o,
   output [0:7]  rgb_b_o,
   output        hsync_n_o,
   output        vsync_n_o,
   output        blank_n_o,
   output        hblank_o,
   output        vblank_o,
   output        comp_sync_n_o,
	output logic signed [0:8] num_pix_o,
   output logic signed [0:8] num_line_o

   );

  logic           reset_s;

  logic           clk_en_10m7_s;
  logic           clk_en_5m37_s;
  logic           clk_en_acc_s;


  opmode_t           opmode_s;
  access_t           access_type_s;

  logic signed [0:8] num_pix_s;
  logic signed [0:8] num_line_s;

  logic              hsync_n_s;
  logic              vsync_n_s;
  logic              blank_s;
  logic              hblank_s;
  logic              vblank_s;

  logic              vert_inc_s;

  logic              reg_blank_s;
  logic              reg_size1_s;
  logic              reg_mag1_s;

  logic              spr_5th_s;
  logic [0:4]        spr_5th_num_s;

  logic              stop_sprite_s;
  logic              vert_active_s;
  logic              hor_active_s;

  logic              rd_s;
  logic              wr_s;

  logic [0:3]        reg_ntb_s;
  logic [0:7]        reg_ctb_s;
  logic [0:2]        reg_pgb_s;
  logic [0:6]        reg_satb_s;
  logic [0:2]        reg_spgb_s;
  logic [0:3]        reg_col1_s;
  logic [0:3]        reg_col0_s;
  logic [0:13]       cpu_vram_a_s;

  logic [0:9]        pat_table_s;
  logic [0:7]        pat_name_s;
  logic [0:3]        pat_col_s;

  logic [0:4]        spr_num_s;
  logic [0:3]        spr_line_s;
  logic [0:7]        spr_name_s;
  logic [0:3]        spr0_col_s;
  logic [0:3]        spr1_col_s;
  logic [0:3]        spr2_col_s;
  logic [0:3]        spr3_col_s;
  logic              spr_coll_s;

  logic              irq_s;

  logic              blank_n;
  logic              hblank_n;
  logic              vblank_n;

  assign clk_en_10m7_s = clk_en_10m7_i;
  assign rd_s = ~csr_n_i;
  assign wr_s = ~csw_n_i;

  assign reset_s = reset_n_i == 1'b0;
  
  assign num_pix_o = num_pix_s;
  assign num_line_o = num_line_s;

  //---------------------------------------------------------------------------
  // Clock Generator
  //---------------------------------------------------------------------------

  vdp18_clk_gen clk_gen_b
    (
     .clk_i(clk_i),
     .clk_en_10m7_i(clk_en_10m7_i),
     .reset_i(reset_s),
     .clk_en_5m37_o(clk_en_5m37_s),
     .clk_en_2m68_o()
     );

  //---------------------------------------------------------------------------
  // Horizontal and Vertical Timing Generator
  //---------------------------------------------------------------------------

  vdp18_hor_vert
    #
    (
     .is_pal_g(is_pal_g)
     )
  hor_vert_b
    (
     .clk_i(clk_i),
     .clk_en_5m37_i(clk_en_5m37_s),
     .reset_i(reset_s),
     .opmode_i(opmode_s),
     .num_pix_o(num_pix_s),
     .num_line_o(num_line_s),
     .vert_inc_o(vert_inc_s),
     .hsync_n_o(hsync_n_s),
     .vsync_n_o(vsync_n_s),
     .blank_o(blank_s),
     .hblank_o(hblank_s),
     .vblank_o(vblank_s)
     );

  assign hsync_n_o = hsync_n_s;
  assign vsync_n_o = vsync_n_s;
  assign comp_sync_n_o = (~(hsync_n_s ^ vsync_n_s));

  //---------------------------------------------------------------------------
  // Control Module
  //---------------------------------------------------------------------------
  vdp18_ctrl ctrl_b
    (
     .clk_i(clk_i),
     .clk_en_5m37_i(clk_en_5m37_s),
     .reset_i(reset_s),
     .opmode_i(opmode_s),
     .num_pix_i(num_pix_s),
     .num_line_i(num_line_s),
     .vert_inc_i(vert_inc_s),
     .reg_blank_i(reg_blank_s),
     .reg_size1_i(reg_size1_s),
     .stop_sprite_i(stop_sprite_s),
     .clk_en_acc_o(clk_en_acc_s),
     .access_type_o(access_type_s),
     .vert_active_o(vert_active_s),
     .hor_active_o(hor_active_s),
     .irq_o(irq_s)
     );

  //---------------------------------------------------------------------------
  // CPU I/O Module
  //---------------------------------------------------------------------------
  vdp18_cpuio cpu_io_b
    (
     .clk_i(clk_i),
     .clk_en_10m7_i(clk_en_10m7_s),
     .clk_en_acc_i(clk_en_acc_s),
     .reset_i(reset_s),
     .rd_i(rd_s),
     .wr_i(wr_s),
     .mode_i(mode_i),
     .cd_i(cd_i),
     .cd_o(cd_o),
     .cd_oe_o(),
     .access_type_i(access_type_s),
     .opmode_o(opmode_s),
     .vram_we_o(vram_we_o),
     .vram_a_o(cpu_vram_a_s),
     .vram_d_o(vram_d_o),
     .vram_d_i(vram_d_i),
     .spr_coll_i(spr_coll_s),
     .spr_5th_i(spr_5th_s),
     .spr_5th_num_i(spr_5th_num_s),
     .reg_ev_o(),
     .reg_16k_o(),
     .reg_blank_o(reg_blank_s),
     .reg_size1_o(reg_size1_s),
     .reg_mag1_o(reg_mag1_s),
     .reg_ntb_o(reg_ntb_s),
     .reg_ctb_o(reg_ctb_s),
     .reg_pgb_o(reg_pgb_s),
     .reg_satb_o(reg_satb_s),
     .reg_spgb_o(reg_spgb_s),
     .reg_col1_o(reg_col1_s),
     .reg_col0_o(reg_col0_s),
     .irq_i(irq_s),
     .int_n_o(int_n_o)
     );

  //---------------------------------------------------------------------------
  // VRAM Address Multiplexer
  //---------------------------------------------------------------------------
  vdp18_addr_mux addr_mux_b
    (
     .access_type_i(access_type_s),
     .opmode_i(opmode_s),
     .num_line_i(num_line_s),
     .reg_ntb_i(reg_ntb_s),
     .reg_ctb_i(reg_ctb_s),
     .reg_pgb_i(reg_pgb_s),
     .reg_satb_i(reg_satb_s),
     .reg_spgb_i(reg_spgb_s),
     .reg_size1_i(reg_size1_s),
     .cpu_vram_a_i(cpu_vram_a_s),
     .pat_table_i(pat_table_s),
     .pat_name_i(pat_name_s),
     .spr_num_i(spr_num_s),
     .spr_line_i(spr_line_s),
     .spr_name_i(spr_name_s),
     .vram_a_o(vram_a_o)
     );

  //---------------------------------------------------------------------------
  // Pattern Generator
  //---------------------------------------------------------------------------
  vdp18_pattern pattern_b
    (
     .clk_i(clk_i),
     .clk_en_5m37_i(clk_en_5m37_s),
     .clk_en_acc_i(clk_en_acc_s),
     .reset_i(reset_s),
     .opmode_i(opmode_s),
     .access_type_i(access_type_s),
     .num_line_i(num_line_s),
     .vram_d_i(vram_d_i),
     .vert_inc_i(vert_inc_s),
     .vsync_n_i(vsync_n_s),
     .reg_col1_i(reg_col1_s),
     .reg_col0_i(reg_col0_s),
     .pat_table_o(pat_table_s),
     .pat_name_o(pat_name_s),
     .pat_col_o(pat_col_s)
     );

  //---------------------------------------------------------------------------
  // Sprite Generator
  //---------------------------------------------------------------------------
  vdp18_sprite sprite_b
    (
     .clk_i(clk_i),
     .clk_en_5m37_i(clk_en_5m37_s),
     .clk_en_acc_i(clk_en_acc_s),
     .reset_i(reset_s),
     .access_type_i(access_type_s),
     .num_pix_i(num_pix_s),
     .num_line_i(num_line_s),
     .vram_d_i(vram_d_i),
     .vert_inc_i(vert_inc_s),
     .reg_size1_i(reg_size1_s),
     .reg_mag1_i(reg_mag1_s),
     .spr_5th_o(spr_5th_s),
     .spr_5th_num_o(spr_5th_num_s),
     .stop_sprite_o(stop_sprite_s),
     .spr_coll_o(spr_coll_s),
     .spr_num_o(spr_num_s),
     .spr_line_o(spr_line_s),
     .spr_name_o(spr_name_s),
     .spr0_col_o(spr0_col_s),
     .spr1_col_o(spr1_col_s),
     .spr2_col_o(spr2_col_s),
     .spr3_col_o(spr3_col_s)
     );

  //---------------------------------------------------------------------------
  // Color Multiplexer
  //---------------------------------------------------------------------------
  vdp18_col_mux
    #
    (
     .compat_rgb_g(compat_rgb_g)
     )
  col_mux_b
    (
     .clk_i(clk_i),
     .clk_en_5m37_i(clk_en_5m37_s),
     .reset_i(reset_s),
     .vert_active_i(vert_active_s),
     .hor_active_i(hor_active_s),
     .border_i(border_i),
     .blank_i(blank_s),
     .hblank_i(hblank_s),
     .vblank_i(vblank_s),
     .reg_col0_i(reg_col0_s),
     .pat_col_i(pat_col_s),
     .spr0_col_i(spr0_col_s),
     .spr1_col_i(spr1_col_s),
     .spr2_col_i(spr2_col_s),
     .spr3_col_i(spr3_col_s),
     .col_o(col_o),
     .blank_n_o(blank_n),
     .hblank_n_o(hblank_n),
     .vblank_n_o(vblank_n),
     .rgb_r_o(rgb_r_o),
     .rgb_g_o(rgb_g_o),
     .rgb_b_o(rgb_b_o)
     );

  assign blank_n_o = (blank_n) ? 1'b1 : 1'b0;
  assign hblank_o = (hblank_n) ? 1'b0 : 1'b1;
  assign vblank_o = (vblank_n) ? 1'b0 : 1'b1;

endmodule

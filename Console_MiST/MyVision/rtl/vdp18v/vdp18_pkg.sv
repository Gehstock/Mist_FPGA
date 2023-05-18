`ifndef _VDP18_PKG
`define _VDP18_PKG
package vdp18_pkg;

  typedef enum bit [3:0]
               {
                // pattern access
                // read Pattern Name Table
                AC_PNT,// = 4'h1,
                // read Pattern Generator Table
                AC_PGT,// = 4'h2,
                // read Pattern Color Table
                AC_PCT,// = 4'h3,
                // sprite access
                // sprite test read (y coordinate)
                AC_STST,// = 4'h4,
                // read Sprite Attribute Table/Y
                AC_SATY,// = 4'h5,
                // read Sprite Attribute Table/X
                AC_SATX,// = 4'h6,
                // read Sprite Attribute Table/N
                AC_SATN,// = 4'h7,
                // read Sprite Attribute Table/C
                AC_SATC,// = 4'h8,
                // read Sprite Pattern Table/high quadrant
                AC_SPTH,// = 4'hA,
                // read Sprite Pattern Table/low quadrant
                AC_SPTL,// = 4'h9,
                //
                // CPU access
                AC_CPU,// = 4'hF,
                //
                // no access at all
                AC_NONE// = 4'h0
                } access_t;

  typedef enum bit [1:0]
               {
                OPMODE_GRAPH1 = 2'h00,
                OPMODE_GRAPH2 = 2'b01,
                OPMODE_MULTIC = 2'b10,
                OPMODE_TEXTM  = 2'b11} opmode_t;

  parameter hv_first_line_ntsc_c = -40;
  parameter hv_last_line_ntsc_c  = 221;
  parameter hv_first_line_pal_c  = -65;
  parameter hv_last_line_pal_c   = 247;
  parameter hv_first_pix_text_c  = -102;
  parameter hv_last_pix_text_c   = 239;
  parameter hv_first_pix_graph_c = -86;
  parameter hv_last_pix_graph_c  = 255;
  parameter hv_vertical_inc_c    = -32;
  parameter hv_sprite_start_c    = 247;

endpackage // vdp18_pkg
`endif

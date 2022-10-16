//============================================================================
//
//  Nichibutsu Galivan Hardware
//
//  Original by (C) 2022 Pierre Cornier
//  Enhanced/optimized by (C) Gyorgy Szombathelyi
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module gfx(
  input           clk,
  input           ce_pix,

  input       [8:0] hh,
  input       [8:0] vv,

  input      [10:0] scrollx,
  input      [10:0] scrolly,
  input       [2:0] layers,

  // mcpu sprite ram interface
  input       [7:0] spram_addr,
  input       [7:0] spram_din,
  output reg  [7:0] spram_dout,
  input             spram_wr,

  output reg [13:0] bg_map_addr,
  input       [7:0] bg_map_data,
  input       [7:0] bg_attr_data,

  output reg [16:0] bg_tile_addr,
  input       [7:0] bg_tile_data,

  output reg [10:0] vram_addr,
  input       [7:0] vram1_data,
  input       [7:0] vram2_data,

  output reg [13:0] tx_tile_addr,
  input       [7:0] tx_tile_data,

  output reg  [7:0] prom_addr,
  input       [3:0] prom1_data,
  input       [3:0] prom2_data,
  input       [3:0] prom3_data,

  output reg [15:0] spr_gfx_addr,
  input       [7:0] spr_gfx_data,
  input             spr_gfx_rdy,

  output reg  [7:0] spr_bnk_addr,
  input       [3:0] spr_bnk_data,

  output reg  [7:0] spr_lut_addr,
  input       [3:0] spr_lut_data,

  output reg  [2:0] r, g,
  output reg  [1:0] b,

  input             h_flip,
  input             v_flip,

  input             hb,

  input             bg_on,
  input             tx_on,
  input             sp_on

);

// object RAM
// 4 bytes/sprite
// offset 0 - Y
// offset 1 - code[7:0]
// offset 2 - attr
// offset 3 - X

reg [7:0] info[255:0];
reg [7:0] smap[255:0]; // object ram copy

wire [8:0] vh = v_flip ? {vv[8], ~vv[7:0]} : vv;
wire [8:0] hr = h_flip ? {hh[8], ~hh[7:0]} : hh;

// line buffers
reg         spbuf_wren_a;
reg   [8:0] spbuf_addr_a;
reg   [5:0] spbuf_data_a;
wire  [5:0] spbuf_q_b;
wire  [8:0] hr_sp = hr - (h_flip ? -4'd13 : 4'd13);

dpram #(9,6) spbuf(
  .clock     ( clk          ),
  .address_a ( spbuf_addr_a ),
  .data_a    ( spbuf_data_a ),
  .q_a       (              ),
  .rden_a    ( 1'b0         ),
  .wren_a    ( spbuf_wren_a ),

  .address_b ( { ~vh[0], hr_sp[7:0] } ),
  .data_b    ( 6'h3f        ),
  .q_b       ( spbuf_q_b    ),
  .rden_b    ( 1'b1         ),
  .wren_b    ( ce_pix & ~hr_sp[8] )
);

// sprite registers

reg   [3:0] sp_next;
reg   [3:0] sp_state;
reg   [7:0] spri;

reg   [7:0] attr;
reg   [8:0] spx;
reg   [7:0] spy;
reg   [8:0] code;

wire  [7:0] smap_q = smap[spri];
wire  [8:0] spy_next = v_flip ? smap_q : 8'd239 - smap_q;
wire  [7:0] spxa = spx[7:0] - 8'd128;
wire  [7:0] sdy  = vv - spy;
wire  [3:0] sdyf = (!v_flip ^ attr[7]) ? sdy[3:0] : 4'd15 - sdy[3:0];
reg   [3:0] sdx;
wire  [3:0] sdxf = attr[6] ? 4'd15 - sdx[3:0] : sdx[3:0];
wire  [3:0] sp_color_code = spr_gfx_data[sdx[0]*4+:4];

// bg registers
reg  [10:0] scx_reg;
reg  [10:0] scy_reg;
reg   [7:0] bg_attr_data_d;
reg   [7:0] bg_attr_data_d2;
reg   [7:0] bg_tile_data_d;
wire [10:0] sh = {h_flip & hr[8], h_flip & hr[8], hr} + scx_reg;
wire [10:0] sv = vh + scy_reg;
wire  [3:0] bg_color_code = bg_tile_data_d[sh[0]*4+:4];

// txt registers
reg  [7:0] vram2_data_d;
reg  [7:0] vram2_data_d2;
reg  [7:0] tx_tile_data_d;
wire [3:0] tx_color_code = tx_tile_data_d[hr[0]*4+:4];

reg        color_ok;
reg  [3:0] rstate;
reg  [3:0] rnext;
reg  [5:0] bg, tx;

reg  [7:0] smap_addr;
reg        copied;

// sprite rendering to dual-line buffer
always @(posedge clk) begin

  spram_dout <= info[spram_addr];
  if (spram_wr) info[spram_addr] <= spram_din;

  if (vv == 0 && hh == 0) begin
    scx_reg <= scrollx;
    scy_reg <= scrolly;
    copied = 1'b0;
  end

  if (vv > 250 && ~copied) begin
    smap[smap_addr] <= info[smap_addr];
    smap_addr <= smap_addr + 8'd1;
    if (smap_addr == 8'd255) copied <= 1'b1;
  end

  spbuf_wren_a <= 0;
  case (sp_state)

    4'd0: begin
      spri <= 8'd0;
      sp_state <= (hh == 0 && vv < 256 && sp_on) ? 4'd1 : 4'd0;
    end

    4'd1: begin
      spy <= spy_next; // spri=0
      if (vv >= spy_next && vv < (spy_next+16)) begin
        // sprite is visible
        sp_state <= 4'd2;
        spri <= spri + 1'd1;
      end
      else begin
        // not visible, check next or finish
        if (spri == 8'd252) sp_state <= 4'd0;
        else spri <= spri + 4'd4;
      end
    end

    4'd2: begin
      code[7:0] <= smap_q; // spri=1
      spri <= spri + 1'd1;
      sp_state <= 4'd3;
    end

    4'd3: begin
      attr <= smap_q; // spri=2
      spri <= spri + 1'd1;
      sp_state <= 4'd4;
    end

    4'd4: begin
      spx <= { attr[0], smap_q }; // range is 0-511 visible area is 128-383 (spri=3)
      code[8] <= attr[1];
      spri <= spri + 1'd1;
      sp_state <= 4'd5;
      sdx <= 4'd0;
    end

    4'd5: begin
      spr_gfx_addr <= { sdx[1], code, sdyf[3:0], sdx[3:2] };
      spr_bnk_addr <= code[8:2];
`ifdef EXT_ROM
      if (spr_gfx_rdy) sp_state <= 4'd6;
`else
      sp_state <= 4'd14; // for internal ROMs only
      sp_next <= 4'd6;
`endif
    end

    4'd6: begin
      spr_lut_addr <= { spr_bnk_data, sp_color_code };
      sp_state <= 4'd14;
      sp_next <= 4'd7;
    end

    4'd7: begin
      if (spx+sdxf > 128 && spx+sdxf < 256+128 && spr_lut_data != 4'hf) begin
        spbuf_addr_a <= { vh[0], spxa+sdxf };
        spbuf_data_a <= { (spr_lut_data[3] ? spr_bnk_data[3:2] : spr_bnk_data[1:0]), sp_color_code };
        spbuf_wren_a <= 1;
      end

      sdx <= sdx + 4'd1;
      sp_state <= sdx[0] ? 4'd5 : 4'd6;
      if (sdx == 4'd15) begin
        sp_state <= spri == 0 ? 4'd0 : 4'd1;
      end
    end

    4'd14: sp_state <= 4'd15;
    4'd15: sp_state <= sp_next;

  endcase
end

// scrolling background layer
always @(posedge clk) begin
  if (ce_pix) begin
    if(sh[2:0] == (3'b111 ^ {3{h_flip}}))
      bg_map_addr <= {sv[10:4], sh[10:4]};
    if(sh[0] ^ h_flip) begin
      bg_tile_addr <= { bg_attr_data[1:0], bg_map_data, sv[3:0], ~sh[3], sh[2:1] };
      bg_tile_data_d <= bg_tile_data;
      bg_attr_data_d <= bg_attr_data;
      bg_attr_data_d2 <= bg_attr_data_d;
    end
    bg <= { (bg_color_code[3] ? bg_attr_data_d2[6:5] : bg_attr_data_d2[4:3]), bg_color_code };
  end
end

// text layer
always @(posedge clk) begin
  if (ce_pix) begin
    if(hh[2:0] == 3'b111)
      vram_addr <= { hr[7:3], vh[7:3] };
    if(hh[0]) begin
      tx_tile_addr <= { vram2_data[0], vram1_data, vh[2:0], hr[2:1] };
      tx_tile_data_d <= tx_tile_data;
      vram2_data_d <= vram2_data;
      vram2_data_d2 <= vram2_data_d;
    end
    tx <= { (tx_color_code[3] ? vram2_data_d2[6:5] : vram2_data_d2[4:3]), tx_color_code };
  end
end

// display output
always @(posedge clk) begin
  if (ce_pix) begin

    color_ok <= 1'b0;

    if (~layers[1]) begin
      prom_addr <= { 2'b11, bg };
      color_ok <= 1'b1;
    end

    if (spbuf_q_b[3:0] != 4'hf) begin
      prom_addr <= { 2'b10, spbuf_q_b };
      color_ok <= 1'b1;
    end

    if (~layers[2] && tx[3:0] != 4'hf) begin
      prom_addr <= { 2'b00, tx };
      color_ok <= 1'b1;
    end

    if (layers[0] && spbuf_q_b[3:0] != 4'hf) begin
      prom_addr <= { 2'b10, spbuf_q_b };
      color_ok <= 1'b1;
    end

    if (color_ok) begin
      r <= prom1_data[3:1];
      g <= prom2_data[3:1];
      b <= prom3_data[3:2];
    end
    else begin
      { r, g, b } <= 8'd0;
    end
  end
end

endmodule

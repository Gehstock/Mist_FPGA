
// ** CHARS:
// ROM: 8x8, 512 tiles, 2bpp shared between two roms, ROM: 8 bytes/tile
// Only one tilemap, 32x32. Color RAM has colors and attributes.
// VRAM decoding:
//   xxxxxxxx = id [7:0]
// Color RAM decoding:
//   ..x..... = id [8]
//   ...xxxxx = color
//   .x...... = flip x
//   x....... = flip y
//
// ** SPRITES:
// ROM: 16x16, 128 sprites, 2bpp, 32 bytes/sprite
// VRAM mem layout: Y, attr1, X, attr2 - from 00-3F so 16 sprites (16*4=64)
// attr1:
//   xxxxxx.. = id [5:0]
//   ......x. = flip x
//   .......x = flip y
// attr2:
//   ...xxxxx = color
//   ..x..... = id [6]
//   xx...... = no idea, priority?
//
// SPRITES & CHARS use the same graphic ROMs
// for the 16x16 layout, grouping is:
//     0         1     etc.
//  --------  -------
// | 1 | 3 | | 5 | 7 |
// |---+---| |---+---|
// | 0 | 2 | | 4 | 6 |
//  --------  -------
//
// Final color ROM address for SPRITE/CHAR is:
// { 5 bit color attribute, GFX ROM bit0, GFX ROM bit1 }
//
// If screen flip is disabled (DSW[1]=0), CPU writes VRAM at addr+2.
// It makes the first two columns blank and avoid additional logic to
// center the screen after XOR'ing the horizontal count.

module video(

  input             reset,
  input             clk_sys,
  output            hb,
  output            vb,
  output            hs,
  output            vs,
  output            ce_pix,

  input      [15:0] cpu_ab,
  input       [7:0] cpu_dout,
  output      [7:0] cpu_vdata,
  input             cpu_rd,
  input             cpu_wr,

  output     [11:0] char_rom_addr,
  input       [7:0] char_data1,
  input       [7:0] char_data2,

  output reg [11:0] spr_rom_addr,
  input       [7:0] spr_data1,
  input       [7:0] spr_data2,

  output reg [6:0] prom_addr,
  input      [7:0] prom_data,

  output reg [4:0] pal_addr,
  input      [7:0] pal_data,

  output reg [2:0] red,
  output reg [2:0] green,
  output reg [1:0] blue,

  input            vram_cs,
  input            cram_cs,

  input            flip

);

wire [8:0] hcount = flip ? {hc[8], ~hc[7:0]} : hc;
wire [8:0] vcount = flip ? {vc[8], ~vc[7:0]} : vc;
wire [8:0] hc;
wire [8:0] vc;

hvgen u_hvgen(
  .clk_sys ( clk_sys ),
  .hb      ( hb      ),
  .vb      ( vb      ),
  .hs      ( hs      ),
  .vs      ( vs      ),
  .hcount  ( hc      ),
  .vcount  ( vc      ),
  .ce_pix  ( ce_pix  )
);

wire spram_sel      = ~|cpu_ab[12:6] & vram_cs;
wire [3:0] spram_cs = { 3'b0, spram_sel } << cpu_ab[1:0];
wire spram0_wr      = spram_cs[0] & cpu_wr;
wire spram1_wr      = spram_cs[1] & cpu_wr;
wire spram2_wr      = spram_cs[2] & cpu_wr;
wire spram3_wr      = spram_cs[3] & cpu_wr;
wire vram_wr        = cpu_wr & vram_cs;
wire cram_wr        = cpu_wr & cram_cs;

wire [9:0] vram_addr;
wire [9:0] cram_addr;
wire [7:0] vram_data;
wire [7:0] cram_data;
reg  [3:0] spram_addr;

wire [6:0] bg_color_data;

wire [7:0] spram_data0;
wire [7:0] spram_data1;
wire [7:0] spram_data2;
wire [7:0] spram_data3;

wire [7:0] cpu_vdo;
wire [7:0] cpu_cdo;

assign cpu_vdata =
  vram_cs     ? cpu_vdo  :
  cram_cs     ? cpu_cdo  : 8'h0;

dpram #(4,8) u_spram0 (
  .address_a    ( cpu_ab[5:2] ),
  .address_b    ( spram_addr  ),
  .clock        ( clk_sys     ),
  .data_a       ( cpu_dout    ),
  .data_b       (             ),
  .wren_a       ( spram0_wr   ),
  .wren_b       (             ),
  .rden_a       ( 1'b0        ),
  .rden_b       ( 1'b1        ),
  .q_a          (             ),
  .q_b          ( spram_data0 )
);

dpram #(4,8) u_spram1 (
  .address_a    ( cpu_ab[5:2] ),
  .address_b    ( spram_addr  ),
  .clock        ( clk_sys     ),
  .data_a       ( cpu_dout    ),
  .data_b       (             ),
  .wren_a       ( spram1_wr   ),
  .wren_b       (             ),
  .rden_a       ( 1'b0        ),
  .rden_b       ( 1'b1        ),
  .q_a          (             ),
  .q_b          ( spram_data1 )
);

dpram #(4,8) u_spram2 (
  .address_a    ( cpu_ab[5:2] ),
  .address_b    ( spram_addr  ),
  .clock        ( clk_sys     ),
  .data_a       ( cpu_dout    ),
  .data_b       (             ),
  .wren_a       ( spram2_wr   ),
  .wren_b       (             ),
  .rden_a       ( 1'b0        ),
  .rden_b       ( 1'b1        ),
  .q_a          (             ),
  .q_b          ( spram_data2 )
);

dpram #(4,8) u_spram3 (
  .address_a    ( cpu_ab[5:2] ),
  .address_b    ( spram_addr  ),
  .clock        ( clk_sys     ),
  .data_a       ( cpu_dout    ),
  .data_b       (             ),
  .wren_a       ( spram3_wr   ),
  .wren_b       (             ),
  .rden_a       ( 1'b0        ),
  .rden_b       ( 1'b1        ),
  .q_a          (             ),
  .q_b          ( spram_data3 )
);

dpram #(10,8) vram(
  .address_a    ( cpu_ab[9:0] ),
  .address_b    ( vram_addr   ),
  .clock        ( clk_sys     ),
  .data_a       ( cpu_dout    ),
  .data_b       (             ),
  .wren_a       ( vram_wr     ),
  .wren_b       (             ),
  .rden_a       ( 1'b1        ),
  .rden_b       ( 1'b1        ),
  .q_a          ( cpu_vdo     ),
  .q_b          ( vram_data   )
);

dpram #(10,8) cram(
  .address_a    ( cpu_ab[9:0] ),
  .address_b    ( cram_addr   ),
  .clock        ( clk_sys     ),
  .data_a       ( cpu_dout    ),
  .data_b       (             ),
  .wren_a       ( cram_wr     ),
  .wren_b       (             ),
  .rden_a       ( 1'b1        ),
  .rden_b       ( 1'b1        ),
  .q_a          ( cpu_cdo     ),
  .q_b          ( cram_data   )
);

wire [2:0] hf = {3{cram_data[6]}};
wire [2:0] vf = {3{cram_data[7]}};
assign vram_addr = { vcount[7:3], hcount[7:3] };
assign cram_addr = { vcount[7:3], hcount[7:3] };
assign bg_color_data = { cram_data[4:0], char_data2[hcount[2:0]^hf], char_data1[hcount[2:0]^hf] };
assign char_rom_addr = { cram_data[5], vram_data, vcount[2:0]^vf };

wire [6:0] sid = { spram_data3[5], spram_data1[7:2] };
wire yflip = spram_data1[1];
wire xflip = spram_data1[0];
wire [7:0] sy = 239 - spram_data0;
reg [3:0] sxc;

wire spc0 = spr_data1[sxc[2:0]^{3{xflip}}];
wire spc1 = spr_data2[sxc[2:0]^{3{xflip}}];

wire [3:0] syc = yflip ? 4'd15 - (vcount - sy) : vcount - sy;
wire [7:0] sxc2 = spram_data2 + sxc + (flip ? -8'd16 : 8'd16);
reg [6:0] spn;
reg [6:0] dlbuf[511:0];
reg [1:0] state, next_state;
reg [6:0] sp_color_data;
reg [8:0] oldv;

always @(posedge clk_sys) begin

  if (reset) begin
    state <= 0;
  end
  else begin

    oldv <= vcount;

    case (state)
      0: begin
        spram_addr <= 0;
        next_state <= 1;
        if (oldv != vcount) state <= 3;
      end
      1: begin
        if (sid != 0 && vcount >= sy && vcount < sy + 16) begin
          sxc <= 0;
          spr_rom_addr <= xflip ? { sid, 1'b0, syc[3:0] } + syc[3] * 8 + 8 : { sid, 1'b0, syc[3:0] } + syc[3] * 8;
          next_state <= 2;
          state <= 3;
        end
        else begin
          spram_addr <= spram_addr + 4'd1;
          next_state <= 1;
          state <= spram_addr ==  4'd15 ? 0 : 3;
        end
      end
      2: begin
        if (spc1|spc0) begin
          dlbuf[{ vcount[0], sxc2 }] <= { spram_data3[4:0], spc1, spc0 };
        end
        sxc <= sxc + 4'd1;
        if (sxc == 4'd5) begin
          spr_rom_addr <= xflip ? { sid, 1'b0, syc[3:0] } + syc[3] * 8 : { sid, 1'b0, syc[3:0] } + syc[3] * 8 + 8;
          next_state <= 2;
          state <= 3;
        end
        if (sxc == 4'd15) begin
          spram_addr <= spram_addr + 4'd1;
          next_state <= spram_addr == 4'd15 ? 0 : 1;
          state <= 3;
        end
        else begin
          state <= 2;
        end
      end
      3: if (ce_pix) state <= next_state;
      default: state <= 0;
    endcase

  end

end


always @(posedge clk_sys) begin
  sp_color_data <= dlbuf[{ ~vcount[0], hcount[7:0] }];
  if (ce_pix) begin
    if (!hc[8]) dlbuf[{ ~vcount[0], hcount[7:0] }] <= 7'd0;
    prom_addr <= |sp_color_data[1:0] ? sp_color_data : bg_color_data;
    pal_addr <= prom_data[4:0];
    red <= pal_data[2:0];
    green <= pal_data[5:3];
    blue <= pal_data[7:6];
  end
end

endmodule

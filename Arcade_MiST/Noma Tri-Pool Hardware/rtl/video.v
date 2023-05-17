
module video(

  input             reset,
  input             clk_sys,
  output            hb,
  output            vb,
  output            hs,
  output            vs,
  output            ce_pix,

  input      [15:0] mcpu_ab,
  input       [7:0] mcpu_data,
  input             mcpu_wr,
  input             mcpu_rd,

  input             mcpu_pal_en,
  input             mcpu_spram_en,
  input             mcpu_vram_en,
  input             mcpu_cram_en,
  input             mcpu_flip_en,

  output      [7:0] mcpu_vdata,

  output reg [12:0] char_rom_addr,
  input       [7:0] char_data1,
  input       [7:0] char_data2,

  output reg [12:0] spr_rom_addr,
  input       [7:0] spr_data1,
  input       [7:0] spr_data2,

  output reg [2:0] red,
  output reg [2:0] green,
  output reg [1:0] blue

);

reg vflip;
reg hflip;

always @(posedge clk_sys) begin
  if (mcpu_flip_en) begin
    if (mcpu_ab[0]) begin // flip set
      vflip <= 1'b1;
      hflip <= 1'b0;
    end
    else begin // flip clear
      vflip <= 1'b0;
      hflip <= 1'b1;
    end
  end
end

wire [8:0] hc;
wire [8:0] vc;
wire [8:0] hcount = hc^{9{hflip}};
wire [8:0] vcount = vc^{9{vflip}};

wire [7:0] mcpu_pal_data;
wire [7:0] mcpu_spr_data0;
wire [7:0] mcpu_spr_data1;
wire [7:0] mcpu_spr_data2;
wire [7:0] mcpu_spr_data3;
wire [7:0] mcpu_vram_data;
wire [7:0] mcpu_cram_data;

reg [9:0] cram_addr;
reg [9:0] vram_addr;
reg  [4:0] pal_addr;
wire [7:0] cram_data;
wire [7:0] vram_data;
wire [7:0] pal_data;
reg  [4:0] bg_color_data;

wire [3:0] spram_cs = { 3'b0, mcpu_spram_en } << mcpu_ab[1:0];

assign mcpu_vdata =
  spram_cs[0]  ? mcpu_spr_data0 :
  spram_cs[1]  ? mcpu_spr_data1 :
  spram_cs[2]  ? mcpu_spr_data2 :
  spram_cs[3]  ? mcpu_spr_data3 :
  mcpu_vram_en ? mcpu_vram_data :
  mcpu_cram_en ? mcpu_cram_data :
  8'd0;

// h/v flip logic could be simplfied a lot but I don't want to spend more time on this

reg  [4:0] sp_addr;
wire [7:0] sp_data0;
wire [7:0] sp_data1;
wire [7:0] sp_data2;
wire [7:0] sp_data3;
reg [4:0] sb[511:0];
wire sc1 = spr_data1[xp^{3{~sp_data3[7]}}];
wire sc2 = spr_data2[xp^{3{~sp_data3[7]}}];
wire [7:0] yy = vflip ? 8'd250 - sp_data0^{8{vflip}} : 8'd255 - sp_data0^{8{vflip}};
reg [7:0] xx;
reg [2:0] xp;
wire [2:0] yp = vflip ? vc - yy - 1 : yy - vc;
reg [7:0] xcl;
reg render;
always @(posedge clk_sys) begin
  if (hc >= 9'h100) begin
    sb[{ ~vc[0], xcl }] <= 5'd0;
    xcl <= xcl + 8'd1;
  end
  if (ce_pix && hc < 9'h100) begin
    if (hc == 0) sp_addr <= 5'd31;
    else if (render) begin
      if (sc1|sc2) sb[{ vc[0], xx+xp }] <= { sp_data3[2:0], sc1, sc2 };
      xp <= xp + 3'd1;
      if (xp == 3'd7) begin
        render <= 1'b0;
        sp_addr <= sp_addr - 5'd1;
      end
    end
    else if (sp_addr >= 0) begin
      if (yy >= vc && yy < vc+8) begin
        xp <= 0;
        xx <= sp_data1;
        spr_rom_addr <= { sp_data3[3], sp_data2, yp^{3{sp_data3[6]}} };
        render <= 1'b1;
      end
      else begin
        sp_addr <= sp_addr - 5'd1;
      end
    end
  end
end

reg cnt;
always @(posedge clk_sys) begin
  cnt <= ~cnt;
  if (~cnt) begin
    hd <= hflip ? hcount[7:0]+8'd1 : hcount[7:0]-8'd1;
    vram_addr <= { hcount[7:3], vcount[7:3] };
    cram_addr <= { hcount[7:3], vcount[7:3] };
  end
  else begin
    char_rom_addr <= { cram_data[4:3], vram_data, 3'd7-vcount[2:0] };
  end
end

reg [5:0] sp_col;
wire [7:0] col = 8'hff ^ pal_data;
reg [7:0] hd;
always @(posedge clk_sys) begin
  sp_col <= sb[{ ~vc[0], hcount[7:0] }];
  if (~cnt) begin
    pal_addr <= (|sp_col[1:0]) ?
    sp_col :
    { cram_data[2:0], char_data1[3'd7^hd[2:0]], char_data2[3'd7^hd[2:0]] };
  end
  else begin
    blue <= col[7:6];
    green <= col[5:3];
    red <= col[2:0];
  end
end



dpram #(5,8) pal(
  .clock     ( clk_sys               ),
  .address_a ( mcpu_ab[4:0]          ),
  .data_a    ( mcpu_data             ),
  .q_a       ( mcpu_pal_data         ),
  .rden_a    ( mcpu_rd               ),
  .wren_a    ( mcpu_wr & mcpu_pal_en ),
  .address_b ( pal_addr              ),
  .data_b    (                       ),
  .q_b       ( pal_data              ),
  .wren_b    (                       ),
  .rden_b    ( 1'b1                  )
);

dpram #(5,8) spram0(
  .clock     ( clk_sys                 ),
  .address_a ( mcpu_ab[6:2]            ),
  .data_a    ( mcpu_data               ),
  .q_a       ( mcpu_spr_data0          ),
  .rden_a    ( mcpu_rd & spram_cs[0]   ),
  .wren_a    ( mcpu_wr & spram_cs[0]   ),
  .address_b ( sp_addr                 ),
  .data_b    (                         ),
  .q_b       ( sp_data0                ),
  .wren_b    (                         ),
  .rden_b    ( 1'b1                    )
);

dpram #(5,8) spram1(
  .clock     ( clk_sys                 ),
  .address_a ( mcpu_ab[6:2]            ),
  .data_a    ( mcpu_data               ),
  .q_a       ( mcpu_spr_data1          ),
  .rden_a    ( mcpu_rd & spram_cs[1]   ),
  .wren_a    ( mcpu_wr & spram_cs[1]   ),
  .address_b ( sp_addr                 ),
  .data_b    (                         ),
  .q_b       ( sp_data1                ),
  .wren_b    (                         ),
  .rden_b    ( 1'b1                    )
);

dpram #(5,8) spram2(
  .clock     ( clk_sys                 ),
  .address_a ( mcpu_ab[6:2]            ),
  .data_a    ( mcpu_data               ),
  .q_a       ( mcpu_spr_data2          ),
  .rden_a    ( mcpu_rd & spram_cs[2]   ),
  .wren_a    ( mcpu_wr & spram_cs[2]   ),
  .address_b ( sp_addr                 ),
  .data_b    (                         ),
  .q_b       ( sp_data2                ),
  .wren_b    (                         ),
  .rden_b    ( 1'b1                    )
);

dpram #(5,8) spram3(
  .clock     ( clk_sys                 ),
  .address_a ( mcpu_ab[6:2]            ),
  .data_a    ( mcpu_data               ),
  .q_a       ( mcpu_spr_data3          ),
  .rden_a    ( mcpu_rd & spram_cs[3]   ),
  .wren_a    ( mcpu_wr & spram_cs[3]   ),
  .address_b ( sp_addr                 ),
  .data_b    (                         ),
  .q_b       ( sp_data3                ),
  .wren_b    (                         ),
  .rden_b    ( 1'b1                    )
);

dpram #(10,8) vram(
  .clock     ( clk_sys                 ),
  .address_a ( mcpu_ab[9:0]            ),
  .data_a    ( mcpu_data               ),
  .q_a       ( mcpu_vram_data          ),
  .rden_a    ( mcpu_rd & mcpu_vram_en  ),
  .wren_a    ( mcpu_wr & mcpu_vram_en  ),
  .address_b ( vram_addr               ),
  .data_b    (                         ),
  .q_b       ( vram_data               ),
  .wren_b    (                         ),
  .rden_b    ( 1'b1                    )
);

dpram #(10,8) cram(
  .clock     ( clk_sys                 ),
  .address_a ( mcpu_ab[9:0]            ),
  .data_a    ( mcpu_data               ),
  .q_a       ( mcpu_cram_data          ),
  .rden_a    ( mcpu_rd & mcpu_cram_en  ),
  .wren_a    ( mcpu_wr & mcpu_cram_en  ),
  .address_b ( cram_addr               ),
  .data_b    (                         ),
  .q_b       ( cram_data               ),
  .wren_b    (                         ),
  .rden_b    ( 1'b1                    )
);


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


endmodule

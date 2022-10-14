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
module core(
  input reset,
  input clk_sys,
  output ce_pix,
  input pause,

  input [7:0] j1,
  input [7:0] j2,
  input [7:0] p1,
  input [7:0] p2,
  input [7:0] system,

  input [7:0]  ioctl_index,
  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr,


  output [2:0] red,
  output [2:0] green,
  output [1:0] blue,

  output [15:0] sound,

  input [8:0] hh,
  input [8:0] vv,
  input vs,
  input hb,
  output hflip,

  input bg_on,
  input tx_on,
  input sp_on,

  input [1:0] fdiv,

  output        cpu1_rom_cs,
  output [15:0] cpu1_rom_addr,
  input   [7:0] cpu1_rom_q,
  input         cpu1_rom_valid,
  output        cpu2_rom_cs,
  output [15:0] cpu2_rom_addr,
  input   [7:0] cpu2_rom_q,
  input         cpu2_rom_valid,

  output [13:0] gfx1_rom_addr,
  input   [7:0] gfx1_rom_q,
  output [16:0] gfx2_rom_addr,
  input   [7:0] gfx2_rom_q,
  output [15:0] gfx3_rom_addr,
  input   [7:0] gfx3_rom_q,
  input         gfx3_rom_ready
);


/******** CLOCKS ********/

wire clk_en_4, clk_en_6, acpu_irq_en;
clk_en mcpu_clk_en(clk_sys, clk_en_6, 16'd7, fdiv);
clk_en acpu_clk_en(clk_sys, clk_en_4, 16'd11);
clk_en acpu_irq_cen(clk_sys, acpu_irq_en, 16'd6400);

assign ce_pix = clk_en_6;

/******** MCPU ********/

wire  [7:0] mcpu_din;
wire [15:0] mcpu_addr;
wire  [7:0] mcpu_dout;
wire        mcpu_rd_n;
wire        mcpu_wr_n;
wire        mcpu_m1_n;
wire        mcpu_mreq_n;
wire        mcpu_iorq_n;
wire        mcpu_rfsh_n;
reg         mcpu_int_n;

reg oldvs;
always @(posedge clk_sys) begin
  oldvs <= vs;
  if (oldvs & ~vs) mcpu_int_n <= 1'b0;
  if (~mcpu_iorq_n & ~mcpu_m1_n) mcpu_int_n <= 1'b1;
end

reg real_pause = 0;
always @(posedge clk_sys)
	if (~clk_en_6 & mcpu_mreq_n & mcpu_iorq_n) real_pause <= pause;


t80s mcpu(
  .reset_n ( ~reset      ),
  .clk     ( clk_sys     ),
  .cen     ( clk_en_6 & (!cpu1_rom_cs | cpu1_rom_valid) & !real_pause ),
  .wait_n  ( 1'b1        ),
  .int_n   ( mcpu_int_n  ),
  .nmi_n   ( 1'b1        ),
  .busrq_n ( 1'b1        ),
  .m1_n    ( mcpu_m1_n   ),
  .mreq_n  ( mcpu_mreq_n ),
  .iorq_n  ( mcpu_iorq_n ),
  .rd_n    ( mcpu_rd_n   ),
  .wr_n    ( mcpu_wr_n   ),
  .rfsh_n  ( mcpu_rfsh_n ),
  .halt_n  (             ),
  .busak_n (             ),
  .A       ( mcpu_addr   ),
  .di      ( mcpu_din    ),
  .do      ( mcpu_dout   )
);

/******** MCPU MEMORY CS ********/

wire mcpu_rom1_en = mcpu_iorq_n & ~mcpu_addr[15];                  // (mcpu_addr < 16'h8000);
wire mcpu_rom2_en = mcpu_iorq_n & mcpu_addr[15:14] == 2'b10;       // ~mcpu_rom1_en & (mcpu_addr < 16'hc000);
wire mcpu_rom_en  = mcpu_iorq_n & (mcpu_rom1_en | mcpu_rom2_en);
wire mcpu_bank_en = mcpu_iorq_n & /*mcpu_addr[15:13] == 3'b110;      */ ~mcpu_rom_en & (mcpu_addr < 16'he000);
wire mcpu_vram1_en = mcpu_iorq_n & /*mcpu_addr[15:10] == 5'b1101_10; */ ~mcpu_rom_en & mcpu_bank_en & (mcpu_addr >= 16'hd800 && mcpu_addr < 16'hdc00);
wire mcpu_vram2_en = mcpu_iorq_n & /*mcpu_addr[15:10] == 5'b1101_11; */ ~mcpu_rom_en & mcpu_bank_en & (mcpu_addr >= 16'hdc00);
wire mcpu_spr_en  = mcpu_iorq_n & ~mcpu_rom_en & ~mcpu_bank_en & (mcpu_addr < 16'he100);
wire mcpu_ram_en  = mcpu_iorq_n & ~mcpu_rom_en & ~mcpu_bank_en & ~mcpu_spr_en;

/******** MCPU MEMORIES ********/
wire  [9:0] gfx_vram_addr;
wire  [5:0] gfx_spr_addr;

wire  [7:0] mcpu_rom1_q;
wire  [7:0] mcpu_rom2_q;
wire  [7:0] mcpu_bank1_q;
wire  [7:0] mcpu_bank2_q;
wire  [7:0] mcpu_vram1_q;
wire  [7:0] mcpu_vram2_q;
wire  [7:0] mcpu_spr_q;
wire [31:0] mcpu_spr_qb;
wire  [7:0] mcpu_ram_q;

`ifndef EXT_ROM
wire  [7:0] mcpu_rom1_data    = ioctl_dout[7:0];
wire [14:0] mcpu_rom1_addr    = ioctl_download ? ioctl_addr : mcpu_addr[14:0];
wire        mcpu_rom1_wren_a  = ioctl_download && ioctl_addr < 27'h8000 ? ioctl_wr : 1'b0;
wire  [7:0] mcpu_rom2_data    = ioctl_dout[7:0];
wire [14:0] mcpu_rom2_addr    = ioctl_download ? ioctl_addr - 27'h8000 : mcpu_addr[14:0];
wire        mcpu_rom2_wren_a  = ioctl_download && ioctl_addr >= 27'h8000 && ioctl_addr < 27'hc000 ? ioctl_wr : 1'b0;
wire  [7:0] mcpu_bank1_data   = ioctl_dout[7:0];
wire [13:0] mcpu_bank1_addr   = ioctl_download ? ioctl_addr - 27'hc000 : mcpu_addr[13:0];
wire        mcpu_bank1_wren_a = ioctl_download && ioctl_addr >= 27'hc000 && ioctl_addr < 27'he000 ? ioctl_wr : 1'b0;
wire  [7:0] mcpu_bank2_data   = ioctl_dout[7:0];
wire [13:0] mcpu_bank2_addr   = ioctl_download ? ioctl_addr - 27'he000 : mcpu_addr[13:0];
wire        mcpu_bank2_wren_a = ioctl_download && ioctl_addr >= 27'he000 && ioctl_addr < 27'h10000 ? ioctl_wr : 1'b0;

dpram #(15,8) mcpu_rom1(
  .clock     ( clk_sys          ),
  .address_a ( mcpu_rom1_addr   ),
  .data_a    ( mcpu_rom1_data   ),
  .q_a       ( mcpu_rom1_q      ),
  .rden_a    ( 1'b1             ),
  .wren_a    ( mcpu_rom1_wren_a )
);

dpram #(14,8) mcpu_rom2(
  .clock     ( clk_sys          ),
  .address_a ( mcpu_rom2_addr   ),
  .data_a    ( mcpu_rom2_data   ),
  .q_a       ( mcpu_rom2_q      ),
  .rden_a    ( 1'b1             ),
  .wren_a    ( mcpu_rom2_wren_a )
);

// 0xc000-0xdfff
dpram #(14,8) mcpu_bank1(
  .clock     ( clk_sys           ),
  .address_a ( mcpu_bank1_addr   ),
  .data_a    ( mcpu_bank1_data   ),
  .q_a       ( mcpu_bank1_q      ),
  .rden_a    ( 1'b1              ),
  .wren_a    ( mcpu_bank1_wren_a )
);

// 0xc000-0xdfff
dpram #(14,8) mcpu_bank2(
  .clock     ( clk_sys           ),
  .address_a ( mcpu_bank2_addr   ),
  .data_a    ( mcpu_bank2_data   ),
  .q_a       ( mcpu_bank2_q      ),
  .rden_a    ( 1'b1              ),
  .wren_a    ( mcpu_bank2_wren_a )
);

`else
assign mcpu_rom1_q = cpu1_rom_q;
assign mcpu_rom2_q = cpu1_rom_q;
assign mcpu_bank1_q = cpu1_rom_q;
assign mcpu_bank2_q = cpu1_rom_q;
assign cpu1_rom_addr = mcpu_bank_en ? {bank ? 3'b111 : 3'b110, mcpu_addr[12:0]} : mcpu_addr;
assign cpu1_rom_cs = (mcpu_rom_en | mcpu_bank_en) & mcpu_rfsh_n & ~mcpu_mreq_n;
`endif

// 0xd800-0xdbff (mcpu write only)
dpram #(10,8) mcpu_vram1(
  .clock     ( clk_sys                    ),
  .address_a ( mcpu_addr[9:0]             ),
  .address_b ( gfx_vram_addr              ),
  .data_a    ( mcpu_dout                  ),
  .q_b       ( mcpu_vram1_q               ),
  .rden_b    ( 1'b1                       ),
  .wren_a    ( ~mcpu_wr_n & mcpu_vram1_en )
);

// 0xdc00-0xdfff (mcpu write only)
dpram #(10,8) mcpu_vram2(
  .clock     ( clk_sys                    ),
  .address_a ( mcpu_addr[9:0]             ),
  .address_b ( gfx_vram_addr              ),
  .data_a    ( mcpu_dout                  ),
  .q_b       ( mcpu_vram2_q               ),
  .rden_b    ( 1'b1                       ),
  .wren_a    ( ~mcpu_wr_n & mcpu_vram2_en )
);

// 0xe000-0xe0ff
// SPRAM is managed by the GFX module

// 0xe100-0xffff
dpram #(13,8) mcpu_ram(
  .clock     ( clk_sys                  ),
  .address_a ( mcpu_addr[12:0]          ),
  .data_a    ( mcpu_dout                ),
  .q_a       ( mcpu_ram_q               ),
  .rden_a    ( 1'b1                     ),
  .wren_a    ( ~mcpu_wr_n & mcpu_ram_en )
);

/******** MCPU I/O ********/

reg [7:0]  mcpu_io_data;
reg [10:0] scrollx;
reg [10:0] scrolly;
reg [2:0]  layers;
reg [7:0]  snd_latch;
reg        clear_latch;
reg        bank;
reg        flip;
assign     hflip = flip;

always @(posedge clk_sys) begin
  reg [7:0] old_j1;
  old_j1 <= j1;

  if (clear_latch) snd_latch <= 8'd0;
  if (~mcpu_iorq_n & mcpu_m1_n) begin
    case (mcpu_addr[7:0])
      8'h00: mcpu_io_data <= j1;
      8'h01: mcpu_io_data <= j2;
      8'h02: mcpu_io_data <= system;
      8'h03: mcpu_io_data <= p1;
      8'h04: mcpu_io_data <= p2;
      8'h40: { bank, flip } <= { mcpu_dout[7], mcpu_dout[2] };
      8'h41: scrollx[7:0]  <= mcpu_dout;
      8'h42: { layers, scrollx[10:8] } <= { mcpu_dout[7:5], mcpu_dout[2:0] };
      8'h43: scrolly[7:0]  <= mcpu_dout;
      8'h44: scrolly[10:8] <= mcpu_dout[2:0];
      8'h45: snd_latch <= { mcpu_dout[6:0], 1'b1 };
      8'hc0: mcpu_io_data <= 8'h58;
    endcase
  end
  // for scroll layer debug
/*
  if (real_pause) begin
	if (~j1[0] & old_j1[0]) scrollx <= scrollx - 5'd16;
	if (~j1[1] & old_j1[1]) scrollx <= scrollx + 5'd16;
	if (~j1[2] & old_j1[2]) scrollx <= scrollx - 1'd1;
	if (~j1[3] & old_j1[3]) scrollx <= scrollx + 1'd1;
  end
*/
end

/******** MCPU DATA BUS ********/

assign mcpu_din =
      ~mcpu_iorq_n ? mcpu_io_data :
      mcpu_rom1_en ? mcpu_rom1_q :
      mcpu_rom2_en ? mcpu_rom2_q :
      mcpu_bank_en & ~bank ? mcpu_bank1_q :
      mcpu_bank_en & bank ? mcpu_bank2_q :
      mcpu_spr_en ? mcpu_spr_q :
      mcpu_ram_en ? mcpu_ram_q : 8'd0;

/******** ACPU ********/

wire  [7:0] acpu_din;
wire [15:0] acpu_addr;
wire  [7:0] acpu_dout;
wire        acpu_rd_n;
wire        acpu_wr_n;
wire        acpu_m1_n;
wire        acpu_mreq_n;
wire        acpu_iorq_n;
wire        acpu_rfsh_n;
reg         acpu_int_n;

reg old_acpu_irq_en;
always @(posedge clk_sys) begin
  old_acpu_irq_en <= acpu_irq_en;
  if (~old_acpu_irq_en & acpu_irq_en) acpu_int_n <= 1'b0;
  if (~acpu_iorq_n & ~acpu_m1_n) acpu_int_n <= 1'b1;
end

t80s acpu(
  .reset_n ( ~reset      ),
  .clk     ( clk_sys     ),
  .cen     ( clk_en_4 & (!cpu2_rom_cs | cpu2_rom_valid) ),
  .wait_n  ( 1'b1        ),
  .int_n   ( acpu_int_n  ),
  .nmi_n   ( 1'b1        ),
  .busrq_n ( 1'b1        ),
  .m1_n    ( acpu_m1_n   ),
  .mreq_n  ( acpu_mreq_n ),
  .iorq_n  ( acpu_iorq_n ),
  .rd_n    ( acpu_rd_n   ),
  .wr_n    ( acpu_wr_n   ),
  .rfsh_n  ( acpu_rfsh_n ),
  .halt_n  (             ),
  .busak_n (             ),
  .A       ( acpu_addr   ),
  .di      ( acpu_din    ),
  .do      ( acpu_dout   )
);


/******** ACPU MEMORY CS ********/

wire acpu_rom1_en = acpu_iorq_n & ~acpu_addr[15]; // acpu_addr < 16'h8000;
wire acpu_rom2_en = acpu_iorq_n & acpu_addr[15:14] == 2'b10; //~acpu_rom1_en & acpu_addr < 16'hc000;
wire acpu_ram_en  = acpu_iorq_n & acpu_addr[15:14] == 2'b11; //~acpu_rom1_en & ~acpu_rom2_en;

/******** ACPU MEMORIES ********/
wire  [7:0] acpu_ram_q;
wire  [7:0] acpu_rom1_q;
wire  [7:0] acpu_rom2_q;

`ifndef EXT_ROM
wire  [7:0] acpu_rom_data    = ioctl_dout;
wire [15:0] acpu_rom1_addr   = ioctl_download ? ioctl_addr - 27'h10000 : acpu_addr;
wire        acpu_rom1_wren_a = ioctl_download && ioctl_addr >= 27'h10000 && ioctl_addr < 27'h18000 ? ioctl_wr : 1'b0;
wire [15:0] acpu_rom2_addr   = ioctl_download ? ioctl_addr - 27'h18000 : acpu_addr;
wire        acpu_rom2_wren_a = ioctl_download && ioctl_addr >= 27'h18000 && ioctl_addr < 27'h1c000 ? ioctl_wr : 1'b0;

dpram #(15,8) acpu_rom1(
  .clock     ( clk_sys          ),
  .address_a ( acpu_rom1_addr   ),
  .data_a    ( acpu_rom_data    ),
  .q_a       ( acpu_rom1_q      ),
  .rden_a    ( 1'b1             ),
  .wren_a    ( acpu_rom1_wren_a )
);

dpram #(14,8) acpu_rom2(
  .clock     ( clk_sys          ),
  .address_a ( acpu_rom2_addr   ),
  .data_a    ( acpu_rom_data    ),
  .q_a       ( acpu_rom2_q      ),
  .rden_a    ( 1'b1             ),
  .wren_a    ( acpu_rom2_wren_a )
);
`else
assign cpu2_rom_addr = acpu_addr;
assign cpu2_rom_cs = (acpu_rom1_en | acpu_rom2_en) & acpu_rfsh_n & ~acpu_mreq_n;
assign acpu_rom1_q = cpu2_rom_q;
assign acpu_rom2_q = cpu2_rom_q;
`endif

dpram #(11,8) acpu_ram(
  .clock     ( clk_sys                  ),
  .address_a ( acpu_addr[10:0]          ),
  .data_a    ( acpu_dout                ),
  .q_a       ( acpu_ram_q               ),
  .rden_a    ( 1'b1                     ),
  .wren_a    ( ~acpu_wr_n & acpu_ram_en )
);

/******** ACPU I/O ********/
reg  [7:0] dac1, dac2;
always @(posedge clk_sys) begin
  clear_latch <= 1'b0;
  if (~acpu_iorq_n & acpu_m1_n & ~acpu_wr_n) begin
    case (acpu_addr[7:0])
      8'h02: dac1 <= acpu_dout;
      8'h03: dac2 <= acpu_dout;
      8'h04: clear_latch <= 1'b1;
      default: ;
    endcase
  end
end
wire snd_latch_cs = ~acpu_iorq_n & acpu_m1_n & acpu_addr[7:0] == 8'h06;

/******** YM3526 ********/

wire ym3526_addr = acpu_addr[0];
wire ym3526_cs = ~acpu_iorq_n & acpu_m1_n & acpu_addr[7:1] == 0;

jtopl ym3526(
    .rst    ( reset         ),
    .clk    ( clk_sys       ),
    .cen    ( clk_en_4      ),
    .din    ( acpu_dout     ),
    .addr   ( ym3526_addr   ),
    .cs_n   ( ~ym3526_cs    ),
    .wr_n   ( acpu_wr_n     ),
    .dout   (               ),
    .irq_n  (               ),
    .snd    ( ym_sound      ),
    .sample (               )
);
wire [15:0] ym_sound;
assign sound = ym_sound + {dac1, 5'd0} + {dac2, 5'd0};

/******** ACPU DATA BUS ********/

assign acpu_din =
      snd_latch_cs ? snd_latch :
      acpu_ram_en  ? acpu_ram_q   :
      acpu_rom1_en ? acpu_rom1_q  :
      acpu_rom2_en ? acpu_rom2_q  :
      8'hFF; // RST38h - important, as the code mistakenly enables interrupts in IM0 mode

/********* GFX ********/

wire [13:0] gfx1_addr;
wire [16:0] gfx2_addr;
wire [15:0] gfx3_addr;
wire [13:0] gfx4_addr;

wire  [7:0] gfx_rom1_q;
wire  [7:0] gfx_rom2_q;
wire  [7:0] gfx_rom3_q;
wire  [7:0] gfx_rom41_q;
wire  [7:0] gfx_rom42_q;

wire [7:0] gfx_prom_addr;
wire [7:0] gfx_prom4_addr;
wire [7:0] gfx_sprom_addr;

wire [3:0] prom1_q;
wire [3:0] prom2_q;
wire [3:0] prom3_q;
wire [3:0] prom4_q;
wire [3:0] sprom_q;

wire [2:0] r;
wire [2:0] g;
wire [1:0] b;

gfx gfx(

  .clk          ( clk_sys                  ),
  .ce_pix       ( ce_pix                   ),
  .hh           ( hh                       ),
  .vv           ( vv                       ),

  .scrollx      ( scrollx                  ),
  .scrolly      ( scrolly                  ),
  .layers       ( layers                   ),

  .spram_addr   ( mcpu_addr[7:0]           ),
  .spram_din    ( mcpu_dout                ),
  .spram_dout   ( mcpu_spr_q               ),
  .spram_wr     ( ~mcpu_wr_n & mcpu_spr_en ),

  .bg_map_addr  ( gfx4_addr                ),
  .bg_map_data  ( gfx_rom41_q              ),
  .bg_attr_data ( gfx_rom42_q              ),
  .bg_tile_addr ( gfx2_addr                ),
  .bg_tile_data ( gfx_rom2_q               ),

  .vram_addr    ( gfx_vram_addr            ),
  .vram1_data   ( mcpu_vram1_q             ),
  .vram2_data   ( mcpu_vram2_q             ),
  .tx_tile_addr ( gfx1_addr                ),
  .tx_tile_data ( gfx_rom1_q               ),


  .spr_gfx_addr ( gfx3_addr                ),
  .spr_gfx_data ( gfx_rom3_q               ),
  .spr_gfx_rdy  ( gfx3_rom_ready           ),
  .spr_bnk_addr ( gfx_sprom_addr           ),
  .spr_bnk_data ( sprom_q                  ),
  .spr_lut_addr ( gfx_prom4_addr           ),
  .spr_lut_data ( prom4_q                  ),

  .prom_addr    ( gfx_prom_addr            ),
  .prom1_data   ( prom1_q                  ),
  .prom2_data   ( prom2_q                  ),
  .prom3_data   ( prom3_q                  ),

  .r            ( red                      ),
  .g            ( green                    ),
  .b            ( blue                     ),
  .h_flip       ( flip                     ),
  .v_flip       ( flip                     ),

  .hb           ( hb                       ),

  .bg_on        ( bg_on                    ),
  .tx_on        ( tx_on                    ),
  .sp_on        ( sp_on                    )

);

/******** GFX ROMs ********/
wire  [7:0] gfx_rom_data     = ioctl_dout;

`ifndef EXT_ROM
wire [13:0] gfx_rom1_addr    = ioctl_download ? ioctl_addr - 27'h1c000 : gfx1_addr;
wire        gfx_rom1_wren_a  = ioctl_download && ioctl_addr >= 27'h1c000 && ioctl_addr < 27'h20000 ? ioctl_wr : 1'b0;
wire [16:0] gfx_rom2_addr    = ioctl_download ? ioctl_addr - 27'h20000 : gfx2_addr;
wire        gfx_rom2_wren_a  = ioctl_download && ioctl_addr >= 27'h20000 && ioctl_addr < 27'h40000 ? ioctl_wr : 1'b0;
wire [15:0] gfx_rom3_addr    = ioctl_download ? ioctl_addr - 27'h40000 : gfx3_addr;
wire        gfx_rom3_wren_a  = ioctl_download && ioctl_addr >= 27'h40000 && ioctl_addr < 27'h50000 ? ioctl_wr : 1'b0;

dpram #(14,8) gfx_rom1(
  .clock     ( clk_sys         ),
  .address_a ( gfx_rom1_addr   ),
  .data_a    ( gfx_rom_data    ),
  .q_a       ( gfx_rom1_q      ),
  .rden_a    ( 1'b1            ),
  .wren_a    ( gfx_rom1_wren_a )
);

dpram #(17,8) gfx_rom2(
  .clock     ( clk_sys         ),
  .address_a ( gfx_rom2_addr   ),
  .data_a    ( gfx_rom_data    ),
  .q_a       ( gfx_rom2_q      ),
  .rden_a    ( 1'b1            ),
  .wren_a    ( gfx_rom2_wren_a )
);

dpram #(16,8) gfx_rom3(
  .clock     ( clk_sys         ),
  .address_a ( gfx_rom3_addr   ),
  .data_a    ( gfx_rom_data    ),
  .q_a       ( gfx_rom3_q      ),
  .rden_a    ( 1'b1            ),
  .wren_a    ( gfx_rom3_wren_a )
);

`else

assign gfx1_rom_addr = gfx1_addr;
assign gfx_rom1_q = gfx1_rom_q;
assign gfx2_rom_addr = gfx2_addr;
assign gfx_rom2_q = gfx2_rom_q;
assign gfx3_rom_addr = gfx3_addr;
assign gfx_rom3_q = gfx3_rom_q;

`endif

wire [13:0] gfx_rom41_addr   = ioctl_download ? ioctl_addr - 27'h50000 : gfx4_addr;
wire        gfx_rom41_wren_a = ioctl_download && ioctl_addr >= 27'h50000 && ioctl_addr < 27'h54000 ? ioctl_wr : 1'b0;
wire [13:0] gfx_rom42_addr   = ioctl_download ? ioctl_addr - 27'h54000 : gfx4_addr;
wire        gfx_rom42_wren_a = ioctl_download && ioctl_addr >= 27'h54000 && ioctl_addr < 27'h58000 ? ioctl_wr : 1'b0;

dpram #(14,8) gfx_rom41(
  .clock     ( clk_sys          ),
  .address_a ( gfx_rom41_addr   ),
  .data_a    ( gfx_rom_data     ),
  .q_a       ( gfx_rom41_q      ),
  .rden_a    ( 1'b1             ),
  .wren_a    ( gfx_rom41_wren_a )
);

dpram #(14,8) gfx_rom42(
  .clock     ( clk_sys          ),
  .address_a ( gfx_rom42_addr   ),
  .data_a    ( gfx_rom_data     ),
  .q_a       ( gfx_rom42_q      ),
  .rden_a    ( 1'b1             ),
  .wren_a    ( gfx_rom42_wren_a )
);

/******** COLOR ROMs ********/

wire  [7:0] prom1_addr    = ioctl_download ? ioctl_addr - 27'h58000 : gfx_prom_addr;
wire        prom1_wren_a  = ioctl_download && ioctl_addr >= 27'h58000 && ioctl_addr < 27'h58100 ? ioctl_wr : 1'b0;
wire  [7:0] prom2_addr    = ioctl_download ? ioctl_addr - 27'h58100 : gfx_prom_addr;
wire        prom2_wren_a  = ioctl_download && ioctl_addr >= 27'h58100 && ioctl_addr < 27'h58200 ? ioctl_wr : 1'b0;
wire  [7:0] prom3_addr    = ioctl_download ? ioctl_addr - 27'h58200 : gfx_prom_addr;
wire        prom3_wren_a  = ioctl_download && ioctl_addr >= 27'h58200 && ioctl_addr < 27'h58300 ? ioctl_wr : 1'b0;

wire  [7:0] prom4_addr    = ioctl_download ? ioctl_addr - 27'h58300 : gfx_prom4_addr;
wire        prom4_wren_a  = ioctl_download && ioctl_addr >= 27'h58300 && ioctl_addr < 27'h58400 ? ioctl_wr : 1'b0;
wire  [7:0] sprom_addr    = ioctl_download ? ioctl_addr - 27'h58400 : gfx_sprom_addr;
wire        sprom_wren_a  = ioctl_download && ioctl_addr >= 27'h58400 && ioctl_addr < 27'h58500 ? ioctl_wr : 1'b0;

dpram #(8,4) prom1(
  .clock     ( clk_sys      ),
  .address_a ( prom1_addr   ),
  .data_a    ( gfx_rom_data ),
  .q_a       ( prom1_q      ),
  .rden_a    ( 1'b1         ),
  .wren_a    ( prom1_wren_a )
);

dpram #(8,4) prom2(
  .clock     ( clk_sys      ),
  .address_a ( prom2_addr   ),
  .data_a    ( gfx_rom_data ),
  .q_a       ( prom2_q      ),
  .rden_a    ( 1'b1         ),
  .wren_a    ( prom2_wren_a )
);

dpram #(8,4) prom3(
  .clock     ( clk_sys      ),
  .address_a ( prom3_addr   ),
  .data_a    ( gfx_rom_data ),
  .q_a       ( prom3_q      ),
  .rden_a    ( 1'b1         ),
  .wren_a    ( prom3_wren_a )
);

// sprite color lut
dpram #(8,4) slookup(
  .clock     ( clk_sys      ),
  .address_a ( prom4_addr   ),
  .data_a    ( gfx_rom_data ),
  .q_a       ( prom4_q      ),
  .rden_a    ( 1'b1         ),
  .wren_a    ( prom4_wren_a )
);

// sprite color bank info
dpram #(8,4) sprom(
  .clock     ( clk_sys      ),
  .address_a ( sprom_addr   ),
  .data_a    ( gfx_rom_data ),
  .q_a       ( sprom_q      ),
  .rden_a    ( 1'b1         ),
  .wren_a    ( sprom_wren_a )
);

endmodule

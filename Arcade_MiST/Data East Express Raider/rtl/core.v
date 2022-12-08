
module core(

  input reset,
  input clk_sys,
  input pause,

  input [7:0] p1,
  input [7:0] p2,
  input [7:0] p3,
  input [7:0] dsw,

  input [7:0]  ioctl_index,
  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr,

  output [3:0] red,
  output [3:0] green,
  output [3:0] blue,
  output       vb,
  output       hb,
  output       vs,
  output       hs,
  output       ce_pix,

  output signed [16:0] sound,

  output        cpu_rom_cs,
  output [15:0] cpu_rom_addr,
  input   [7:0] cpu_rom_data,
  output        audio_rom_cs,
  output [14:0] audio_rom_addr,
  input   [7:0] audio_rom_data,
  output[14:0] gfx1_addr,
  input  [7:0] gfx1_data,
  output[14:0] gfx2_addr,
  input  [7:0] gfx2_data,
  output[15:0] gfx3_addr,
  input  [7:0] gfx3_data,
  output[15:0] sp_addr,
  input [31:0] sp_data
);

wire [7:0] cpu_dout;
wire [15:0] cpu_ab;
wire [7:0] romdata;
wire [7:0] prot_data;
wire [7:0] prot_status;
wire [7:0] sram_data;
wire [14:0] map_rom_addr;
wire [7:0] map_data;
wire [15:0] bg_rom_addr;
wire [7:0] bg_data1;
wire [7:0] bg_data2;
wire [13:0] char_rom_addr;
wire [7:0] char_data;
wire [7:0] col_rom_addr;
wire [11:0] col_data;
wire [15:0] sp_rom_addr;
wire [7:0] sp_rom_data1;
wire [7:0] sp_rom_data2;
wire [7:0] sp_rom_data3;
wire [7:0] prom_addr;
wire [7:0] prom_data;
wire sram_cs;
wire vram_cs;
wire cram_cs;
wire rom_cs;
wire ds0_read;
wire ds1_read;
wire in1_read;
wire in2_read;
wire nmi_clear;
wire snd_write;
wire flp_write;
wire dma_swap;
wire bg_sel;
wire pdat_read;
wire psta_read;
wire pdat_write;
wire scx_write;
wire scy_write;
wire rw;

wire coin1 = ~&p2[7:6];

wire [7:0] cpu_din =
  ds0_read  ? dsw         :
  in1_read  ? p1          :
  in2_read  ? p2          :
  ds1_read  ? p3          :
  rom_cs    ? romdata     :
  pdat_read ? prot_data   :
  psta_read ? prot_status :
  sram_cs   ? sram_data   :
  8'h0;


er_decode u_er_decode(
  .cpu_addr   ( cpu_ab     ),
  .sram_cs    ( sram_cs    ),
  .vram_cs    ( vram_cs    ),
  .cram_cs    ( cram_cs    ),
  .rom_cs     ( rom_cs     ),
  .ds0_read   ( ds0_read   ),
  .ds1_read   ( ds1_read   ),
  .in1_read   ( in1_read   ),
  .in2_read   ( in2_read   ),
  .nmi_clear  ( nmi_clear  ),
  .snd_write  ( snd_write  ),
  .flp_write  ( flp_write  ),
  .dma_swap   ( dma_swap   ),
  .bg_sel     ( bg_sel     ),
  .pdat_read  ( pdat_read  ),
  .psta_read  ( psta_read  ),
  .pdat_write ( pdat_write ),
  .scx_write  ( scx_write  ),
  .scy_write  ( scy_write  )
);

prot u_prot(
  .clk_sys ( clk_sys     ),
  .wr      ( pdat_write  ),
  .din     ( cpu_dout    ),
  .dout    ( prot_data   ),
  .status  ( prot_status )
);

mcpu u_mcpu(
  .clk_sys   ( clk_sys   ),
  .reset     ( reset     ),
  .pause     ( pause     ),
  .coin1     ( coin1     ),
  .nmi_clear ( nmi_clear ),
  .vblk      ( vb        ),
  .cpu_din   ( cpu_din   ),
  .cpu_ab    ( cpu_ab    ),
  .cpu_dout  ( cpu_dout  ),
  .rw        ( rw        )
);

mcpu_rom u_mcpu_rom(
  .clk_sys        ( clk_sys        ),
  .cpu_ab         ( cpu_ab         ),
  .romdata        ( romdata        ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       ),
  .rom_cs         ( cpu_rom_cs     ),
  .rom_addr       ( cpu_rom_addr   ),
  .rom_data       ( cpu_rom_data   )
);

video u_video(
  .reset         ( reset         ),
  .clk_sys       ( clk_sys       ),
  .hb            ( hb            ),
  .vb            ( vb            ),
  .hs            ( hs            ),
  .vs            ( vs            ),
  .ce_pix        ( ce_pix        ),
  .red           ( red           ),
  .green         ( green         ),
  .blue          ( blue          ),
  .cpu_ab        ( cpu_ab        ),
  .cpu_dout      ( cpu_dout      ),
  .rw            ( rw            ),
  .dma_swap      ( dma_swap      ),
  .sram_data     ( sram_data     ),
  .map_rom_addr  ( map_rom_addr  ),
  .map_data      ( map_data      ),
  .char_rom_addr ( char_rom_addr ),
  .char_data     ( char_data     ),
  .bg_rom_addr   ( bg_rom_addr   ),
  .bg_data1      ( bg_data1      ),
  .bg_data2      ( bg_data2      ),
  .col_rom_addr  ( col_rom_addr  ),
  .col_data      ( col_data      ),
  .prom_addr     ( prom_addr     ),
  .prom_data     ( prom_data     ),
  .sp_rom_addr   ( sp_rom_addr   ),
  .sp_rom_data1  ( sp_rom_data1  ),
  .sp_rom_data2  ( sp_rom_data2  ),
  .sp_rom_data3  ( sp_rom_data3  ),
  .vram_cs       ( vram_cs       ),
  .sram_cs       ( sram_cs       ),
  .cram_cs       ( cram_cs       ),
  .scx_write     ( scx_write     ),
  .scy_write     ( scy_write     ),
  .bg_sel        ( bg_sel        )
);

vdata u_vdata(
  .clk_sys        ( clk_sys        ),
  .map_rom_addr   ( map_rom_addr   ),
  .map_data       ( map_data       ),
  .char_rom_addr  ( char_rom_addr  ),
  .char_data      ( char_data      ),
  .col_rom_addr   ( col_rom_addr   ),
  .col_data       ( col_data       ),
  .prom_addr      ( prom_addr      ),
  .prom_data      ( prom_data      ),
  .bg_rom_addr    ( bg_rom_addr    ),
  .bg_data1       ( bg_data1       ),
  .bg_data2       ( bg_data2       ),
  .sp_rom_addr    ( sp_rom_addr    ),
  .sp_rom_data1   ( sp_rom_data1   ),
  .sp_rom_data2   ( sp_rom_data2   ),
  .sp_rom_data3   ( sp_rom_data3   ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       ),
  .gfx1_addr      ( gfx1_addr      ),
  .gfx1_data      ( gfx1_data      ),
  .gfx2_addr      ( gfx2_addr      ),
  .gfx2_data      ( gfx2_data      ),
  .gfx3_addr      ( gfx3_addr      ),
  .gfx3_data      ( gfx3_data      ),
  .sp_addr        ( sp_addr        ),
  .sp_data        ( sp_data        )
);

audio audio(
  .reset          ( reset          ),
  .clk_sys        ( clk_sys        ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       ),
  .snd_write      ( snd_write      ),
  .mcpu_dout      ( cpu_dout       ),
  .sound_mix      ( sound          ),
  .rom_cs         ( audio_rom_cs   ),
  .rom_addr       ( audio_rom_addr ),
  .rom_data       ( audio_rom_data )
);


endmodule


module core(

  input reset,
  input clk_sys,

  input [7:0] p1,
  input [7:0] p2,
  input [7:0] dsw,

  input [7:0]  ioctl_index,
  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr,

  output [2:0] red,
  output [2:0] green,
  output [1:0] blue,
  output       vb,
  output       hb,
  output       vs,
  output       hs,
  output       ce_pix,
  output       flipped,

  output [15:0] sound_mix

);

wire [7:0] cpu_dout;
wire [15:0] cpu_ab;
wire [7:0] rom_data;
wire [7:0] ram1_data;
wire [7:0] ram2_data;
wire [7:0] cpu_vdata;
wire cpu_wr;
wire cpu_rd;
wire cpu_io;
wire cpu_m1;

wire rom_cs;
wire ram1_cs;
wire ram2_cs;
wire vram_cs;
wire cram_cs;
wire p1_cs;
wire p2_cs;
wire dsw_cs;
wire flip_wr;
wire sn1_wr;
wire sn2_wr;
wire sn1_rdy;
wire sn2_rdy;

wire [11:0] char_rom_addr;
wire [7:0] char_data1;
wire [7:0] char_data2;
wire [11:0] spr_rom_addr;
wire [7:0] spr_data1;
wire [7:0] spr_data2;
wire [6:0] prom_addr;
wire [7:0] prom_data;
wire [4:0] pal_addr;
wire [7:0] pal_data;
wire       snd1_rdy;
wire       snd2_rdy;

reg hflip;

always @(posedge clk_sys)
  if (flip_wr) hflip <= cpu_dout[2];

assign flipped = hflip;

wire [7:0] cpu_din =
  p1_cs             ? p1        :
  p2_cs             ? p2        :
  dsw_cs            ? dsw       :
  ram1_cs           ? ram1_data :
  ram2_cs           ? ram2_data :
  rom_cs            ? rom_data  :
  vram_cs | cram_cs ? cpu_vdata : 8'h0;

jg_decode u_jg_decode(
  .cpu_ab   ( cpu_ab   ),
  .cpu_io   ( cpu_io   ),
  .cpu_m1   ( cpu_m1   ),
  .cpu_wr   ( cpu_wr   ),
  .rom_cs   ( rom_cs   ),
  .ram1_cs  ( ram1_cs  ),
  .ram2_cs  ( ram2_cs  ),
  .vram_cs  ( vram_cs  ),
  .cram_cs  ( cram_cs  ),
  .p1_cs    ( p1_cs    ),
  .p2_cs    ( p2_cs    ),
  .dsw_cs   ( dsw_cs   ),
  .flip_wr  ( flip_wr  ),
  .sn1_wr   ( sn1_wr   ),
  .sn2_wr   ( sn2_wr   )
);

mcpu u_mcpu(
  .clk_sys  ( clk_sys  ),
  .reset    ( reset    ),
  .cpu_din  ( cpu_din  ),
  .cpu_dout ( cpu_dout ),
  .cpu_ab   ( cpu_ab   ),
  .cpu_wr   ( cpu_wr   ),
  .cpu_rd   ( cpu_rd   ),
  .cpu_io   ( cpu_io   ),
  .cpu_m1   ( cpu_m1   ),
  .vb       ( vb       )
);

cpu_rom u_cpu_rom(
  .clk_sys        ( clk_sys        ),
  .rom_data       ( rom_data       ),
  .cpu_ab         ( cpu_ab         ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);

cpu_ram u_cpu_ram(
  .reset     ( reset     ),
  .clk_sys   ( clk_sys   ),
  .cpu_ab    ( cpu_ab    ),
  .cpu_dout  ( cpu_dout  ),
  .ram1_data ( ram1_data ),
  .ram2_data ( ram2_data ),
  .cpu_wr    ( cpu_wr    ),
  .cpu_rd    ( cpu_rd    ),
  .ram1_cs   ( ram1_cs   ),
  .ram2_cs   ( ram2_cs   )
);

video u_video(
  .reset         ( reset          ),
  .clk_sys       ( clk_sys        ),
  .hb            ( hb             ),
  .vb            ( vb             ),
  .hs            ( hs             ),
  .vs            ( vs             ),
  .ce_pix        ( ce_pix         ),
  .cpu_ab        ( cpu_ab         ),
  .cpu_dout      ( cpu_dout       ),
  .cpu_vdata     ( cpu_vdata      ),
  .cpu_wr        ( cpu_wr         ),
  .cpu_rd        ( cpu_rd         ),
  .char_rom_addr ( char_rom_addr  ),
  .char_data1    ( char_data1     ),
  .char_data2    ( char_data2     ),
  .spr_rom_addr  ( spr_rom_addr   ),
  .spr_data1     ( spr_data1      ),
  .spr_data2     ( spr_data2      ),
  .prom_addr     ( prom_addr      ),
  .prom_data     ( prom_data      ),
  .pal_addr      ( pal_addr       ),
  .pal_data      ( pal_data       ),
  .red           ( red            ),
  .green         ( green          ),
  .blue          ( blue           ),
  .vram_cs       ( vram_cs        ),
  .cram_cs       ( cram_cs        ),
  .flip          ( flipped        )
);

vdata u_vdata(
  .clk_sys        ( clk_sys        ),
  .char_rom_addr  ( char_rom_addr  ),
  .char_data1     ( char_data1     ),
  .char_data2     ( char_data2     ),
  .spr_rom_addr   ( spr_rom_addr   ),
  .spr_data1      ( spr_data1      ),
  .spr_data2      ( spr_data2      ),
  .prom_addr      ( prom_addr      ),
  .prom_data      ( prom_data      ),
  .pal_addr       ( pal_addr       ),
  .pal_data       ( pal_data       ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);

/*verilator tracing_off*/
audio u_audio(
  .reset     ( reset     ),
  .clk_sys   ( clk_sys   ),
  .sn1_wr    ( sn1_wr    ),
  .sn2_wr    ( sn2_wr    ),
  .cpu_dout  ( cpu_dout  ),
  .sound_mix ( sound_mix ),
  .sn1_rdy   ( sn1_rdy   ),
  .sn2_rdy   ( sn2_rdy   )
);


endmodule

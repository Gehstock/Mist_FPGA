
module vdata(
  input clk_sys,
//  input [14:0] map_rom_addr,
//  output [7:0] map_data,

  input [12:0] char_rom_addr,
  output [7:0] char_data1,
  output [7:0] char_data2,

  input [12:0] spr_rom_addr,
  output [7:0] spr_data1,
  output [7:0] spr_data2,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr
);

wire [12:0] chr_addr1 = ioctl_download ? ioctl_addr - 27'ha000 : char_rom_addr;
wire [12:0] chr_addr2 = ioctl_download ? ioctl_addr - 27'hc000 : char_rom_addr;
wire        gfx_wr1   = ioctl_download && ioctl_addr >= 27'ha000 && ioctl_addr < 27'hc000 ? ioctl_wr : 1'b0;
wire        gfx_wr2   = ioctl_download && ioctl_addr >= 27'hc000 && ioctl_addr < 27'he000 ? ioctl_wr : 1'b0;

dpram #(13,8) gfx_rom1(
  .address_a    ( chr_addr1     ),
  .address_b    ( spr_rom_addr  ),
  .clock        ( clk_sys       ),
  .data_a       ( ioctl_dout    ),
  .data_b       (               ),
  .wren_a       ( gfx_wr1       ),
  .wren_b       (               ),
  .rden_a       ( 1'b1          ),
  .rden_b       ( 1'b1          ),
  .q_a          ( char_data1   ),
  .q_b          ( spr_data1    )
);

dpram #(13,8) gfx_rom2(
  .address_a    ( chr_addr2     ),
  .address_b    ( spr_rom_addr  ),
  .clock        ( clk_sys       ),
  .data_a       ( ioctl_dout    ),
  .data_b       (               ),
  .wren_a       ( gfx_wr2       ),
  .wren_b       (               ),
  .rden_a       ( 1'b1          ),
  .rden_b       ( 1'b1          ),
  .q_a          ( char_data2   ),
  .q_b          ( spr_data2    )
);

endmodule


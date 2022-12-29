
module vdata(
  input clk_sys,

  input [11:0] char_rom_addr,
  output [7:0] char_data1,
  output [7:0] char_data2,

  input [11:0] spr_rom_addr,
  output [7:0] spr_data1,
  output [7:0] spr_data2,

  input [6:0] prom_addr,
  output [7:0] prom_data,

  input [4:0] pal_addr,
  output [7:0] pal_data,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr
);

wire [11:0] char_addr = ioctl_download ? ioctl_addr - 27'h8000 : char_rom_addr;
wire        char1_wr  = ioctl_download && ioctl_addr >= 27'h8000 && ioctl_addr < 27'h9000 ? ioctl_wr : 1'b0;
wire        char2_wr  = ioctl_download && ioctl_addr >= 27'h9000 && ioctl_addr < 27'ha000 ? ioctl_wr : 1'b0;

dpram #(12,8) char_rom1(
  .address_a    ( char_addr    ),
  .address_b    ( spr_rom_addr ),
  .clock        ( clk_sys      ),
  .data_a       ( ioctl_dout   ),
  .data_b       (              ),
  .wren_a       ( char1_wr     ),
  .wren_b       (              ),
  .rden_a       ( 1'b1         ),
  .rden_b       ( 1'b1         ),
  .q_a          ( char_data1   ),
  .q_b          ( spr_data1    )
);

dpram #(12,8) char_rom2(
  .address_a    ( char_addr    ),
  .address_b    ( spr_rom_addr ),
  .clock        ( clk_sys      ),
  .data_a       ( ioctl_dout   ),
  .data_b       (              ),
  .wren_a       ( char2_wr     ),
  .wren_b       (              ),
  .rden_a       ( 1'b1         ),
  .rden_b       ( 1'b1         ),
  .q_a          ( char_data2   ),
  .q_b          ( spr_data2    )
);


// wrong
wire [4:0] pal_admux  = ioctl_download ? ioctl_addr - 27'ha000 : pal_addr;
wire       pal_wr     = ioctl_download && ioctl_addr >= 27'ha000 && ioctl_addr < 27'ha020 ? ioctl_wr : 1'b0;
wire [6:0] prom_admux = ioctl_download ? ioctl_addr - 27'ha020 : prom_addr;
wire       prom_wr    = ioctl_download && ioctl_addr >= 27'ha020 && ioctl_addr < 27'ha0a0 ? ioctl_wr : 1'b0;

ram #(5,16) palette(
  .clk  ( clk_sys    ),
  .addr ( pal_admux  ),
  .din  ( ioctl_dout ),
  .q    ( pal_data   ),
  .wr_n ( ~pal_wr    )
);

ram #(7,8) prom(
  .clk  ( clk_sys    ),
  .addr ( prom_admux ),
  .din  ( ioctl_dout ),
  .q    ( prom_data  ),
  .wr_n ( ~prom_wr   )
);


endmodule


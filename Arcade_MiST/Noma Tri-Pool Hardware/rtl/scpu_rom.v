
module scpu_rom(
  input         clk_sys,
  output [7:0]  rom_data,
  input  [15:0] cpu_ab,

  input         ioctl_download,
  input [26:0]  ioctl_addr,
  input [15:0]  ioctl_dout,
  input         ioctl_wr
);

wire [12:0] rom_addr = ioctl_download ? ioctl_addr[12:0] - 27'h8000 : cpu_ab[12:0];
wire        rom_wr   = ioctl_download && ioctl_addr >= 27'h8000 && ioctl_addr < 27'ha000 ? ioctl_wr : 1'b0;

ram #(13,8) rom(
  .clk  ( clk_sys    ),
  .addr ( rom_addr   ),
  .din  ( ioctl_dout ),
  .q    ( rom_data   ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~rom_wr    ),
  .ce_n ( 1'b0       )
);

endmodule 
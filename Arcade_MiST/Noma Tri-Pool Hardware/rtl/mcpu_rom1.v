
module mcpu_rom1(
  input         clk_sys,
  output [7:0]  rom_data,
  input  [15:0] cpu_ab,

  input         ioctl_download,
  input [26:0]  ioctl_addr,
  input [15:0]  ioctl_dout,
  input         ioctl_wr
);

wire [13:0] rom_addr = ioctl_download ? ioctl_addr[13:0] : cpu_ab[13:0];
wire        rom_wr   = ioctl_download && ioctl_addr < 27'h4000 ? ioctl_wr : 1'b0;

ram #(14,8) rom(
  .clk  ( clk_sys    ),
  .addr ( rom_addr   ),
  .din  ( ioctl_dout ),
  .q    ( rom_data   ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~rom_wr    ),
  .ce_n ( 1'b0       )
);

endmodule 
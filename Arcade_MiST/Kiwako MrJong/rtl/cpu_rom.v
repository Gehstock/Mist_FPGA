
module cpu_rom(
  input         clk_sys,
  output [7:0]  rom_data,
  input  [15:0] cpu_ab,

  input         ioctl_download,
  input [26:0]  ioctl_addr,
  input [15:0]  ioctl_dout,
  input         ioctl_wr
);


wire [14:0] rom_addr = ioctl_download ? ioctl_addr[14:0] : cpu_ab[14:0];
wire        rom_wr   = ioctl_download && ioctl_addr < 27'h8000 ? ioctl_wr : 1'b0;

ram #(15,8) rom(
  .clk  ( clk_sys    ),
  .addr ( rom_addr   ),
  .din  ( ioctl_dout ),
  .q    ( rom_data   ),
  .wr_n ( ~rom_wr    )
);


endmodule


module mcpu_rom(
  input clk_sys,
  input [15:0] cpu_ab,
  output [7:0] romdata,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr,

  output       rom_cs,
  output[15:0] rom_addr,
  input  [7:0] rom_data
);

assign rom_cs = cpu_ab[15] | cpu_ab[14];
assign rom_addr = cpu_ab[15:0] - 16'h4000;
`ifdef EXT_ROM
assign romdata = rom_data;
`else
wire [13:0] u16B_addr = ioctl_download ? ioctl_addr : cpu_ab[13:0];
wire        u16B_wr_n = ioctl_download && ioctl_addr < 27'h4000 ? ioctl_wr : 1'b0;
wire [14:0] u16A_addr = ioctl_download ? ioctl_addr - 27'h4000 : cpu_ab[14:0];
wire        u16A_wr_n = ioctl_download && ioctl_addr >= 27'h4000 && ioctl_addr < 27'hc000 ? ioctl_wr : 1'b0;

wire [7:0] u16A_Q, u16B_Q;
assign romdata = u16A_Q | u16B_Q;

wire u16B_ce_n = ~(cpu_ab[14] & ~cpu_ab[15]);
ram #(14,8) u16B(
  .clk  ( clk_sys    ),
  .addr ( u16B_addr  ),
  .din  ( ioctl_dout ),
  .q    ( u16B_Q     ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~u16B_wr_n ),
  .ce_n ( u16B_ce_n  )
);

ram #(15,8) u16A(
  .clk  ( clk_sys    ),
  .addr ( u16A_addr  ),
  .din  ( ioctl_dout ),
  .q    ( u16A_Q     ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~u16A_wr_n ),
  .ce_n ( ~cpu_ab[15] )
);
`endif
endmodule

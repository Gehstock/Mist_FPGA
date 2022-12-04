
module acpu_mem(
  input        clk_sys,
  input        cpu_cen,
  input [15:0] acpu_ab,
  input  [7:0] din,
  output [7:0] dout,
  input        rw,
  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr,
  input  [7:0] mcpu_dout,
  input        snd_write,
  output       cs1,
  output       cs2,
  input  [7:0] ym2203_data,
  input  [7:0] ym3526_data,
  output       rom_cs,
  output[14:0] rom_addr,
  input  [7:0] rom_data
);

wire [7:0] u3A_q;
wire [7:0] u6A_q;

reg [7:0] u2E;
always @(posedge clk_sys)
  if (snd_write) u2E <= mcpu_dout;

// memory map decoding u1D
// cs1 = ym2203 cs2 = ym3526 cs3 = snd latch
wire [3:0] cs = acpu_ab[15] ? 4'b0 : 1 << acpu_ab[14:13];

assign cs1 = cs[1];
assign cs2 = cs[2];

//always @(posedge clk_sys)
//  if (cpu_cen)
assign dout =
      cs[0] ? u6A_q : // ram
      cs[1] ? ym2203_data :
      cs[2] ? ym3526_data :
      cs[3] ? u2E   : // snd latch
              u3A_q;  // rom

assign rom_cs = acpu_ab[15];
assign rom_addr = acpu_ab[14:0];

`ifdef EXT_ROM
assign u3A_q = rom_data;
`else

wire [14:0] u3A_addr = ioctl_download ? ioctl_addr - 27'hc000 : acpu_ab[14:0];
wire        u3A_wr_n = ioctl_download && ioctl_addr >= 27'hc000 && ioctl_addr < 27'h14000 ? ioctl_wr : 1'b0;

ram #(15,8) u3A(
  .clk  ( clk_sys      ),
  .addr ( u3A_addr     ),
  .din  ( ioctl_dout   ),
  .q    ( u3A_q        ),
  .rd_n ( 1'b0         ),
  .wr_n ( ~u3A_wr_n    ),
  .ce_n ( ~acpu_ab[15] )
);
`endif

ram #(11,8) u6A(
  .clk  ( clk_sys       ),
  .addr ( acpu_ab[10:0] ),
  .din  ( din           ),
  .q    ( u6A_q         ),
  .rd_n ( 1'b0          ),
  .wr_n ( rw | ~cs[0]   ),
  .ce_n ( ~cs[0]        )
);

endmodule

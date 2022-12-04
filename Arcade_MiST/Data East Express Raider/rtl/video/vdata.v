
module vdata(
  input clk_sys,
  input [14:0] map_rom_addr,
  output [7:0] map_data,

  input [13:0] char_rom_addr,
  output [7:0] char_data,

  input [7:0]   col_rom_addr,
  output [11:0] col_data,

  input  [7:0] prom_addr,
  output [7:0] prom_data,

  input [15:0] bg_rom_addr,
  output [7:0] bg_data1,
  output [7:0] bg_data2,

  input [15:0] sp_rom_addr,
  output [7:0] sp_rom_data1,
  output [7:0] sp_rom_data2,
  output [7:0] sp_rom_data3,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr,

  output[14:0] gfx1_addr,
  input  [7:0] gfx1_data,
  output[14:0] gfx2_addr,
  input  [7:0] gfx2_data,
  output[15:0] gfx3_addr,
  input  [7:0] gfx3_data,
  output[15:0] sp_addr,
  input [31:0] sp_data
);

// color ROMs

wire [3:0] uc5B_q;
wire [3:0] uc6B_q;
wire [3:0] uc7B_q;
wire [3:0] uc9B_q;

assign col_data  = { uc5B_q, uc6B_q, uc7B_q };
assign prom_data = uc9B_q;

wire [7:0] uc5B_addr = ioctl_download ? ioctl_addr - 27'h78000 : col_rom_addr;
wire       uc5B_wr_n = ioctl_download && ioctl_addr >= 27'h78000 && ioctl_addr < 27'h78100 ? ioctl_wr : 1'b0;
wire [7:0] uc6B_addr = ioctl_download ? ioctl_addr - 27'h78100 : col_rom_addr;
wire       uc6B_wr_n = ioctl_download && ioctl_addr >= 27'h78100 && ioctl_addr < 27'h78200 ? ioctl_wr : 1'b0;
wire [7:0] uc7B_addr = ioctl_download ? ioctl_addr - 27'h78200 : col_rom_addr;
wire       uc7B_wr_n = ioctl_download && ioctl_addr >= 27'h78200 && ioctl_addr < 27'h78300 ? ioctl_wr : 1'b0;
wire [7:0] uc9B_addr = ioctl_download ? ioctl_addr - 27'h78300 : prom_addr;
wire       uc9B_wr_n = ioctl_download && ioctl_addr >= 27'h78300 && ioctl_addr < 27'h78400 ? ioctl_wr : 1'b0;

ram #(8,8) uc5B(
  .clk  ( clk_sys    ),
  .addr ( uc5B_addr  ),
  .din  ( ioctl_dout ),
  .q    ( uc5B_q     ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~uc5B_wr_n ),
  .ce_n ( 1'b0       )
);

ram #(8,8) uc6B(
  .clk  ( clk_sys    ),
  .addr ( uc6B_addr  ),
  .din  ( ioctl_dout ),
  .q    ( uc6B_q     ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~uc6B_wr_n ),
  .ce_n ( 1'b0       )
);

ram #(8,8) uc7B(
  .clk  ( clk_sys    ),
  .addr ( uc7B_addr  ),
  .din  ( ioctl_dout ),
  .q    ( uc7B_q     ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~uc7B_wr_n ),
  .ce_n ( 1'b0       )
);

ram #(8,8) uc9B(
  .clk  ( clk_sys    ),
  .addr ( uc9B_addr  ),
  .din  ( ioctl_dout ),
  .q    ( uc9B_q     ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~uc9B_wr_n ),
  .ce_n ( 1'b0       )
);



// char ROM

wire [7:0] u5B_q;

wire [13:0] u5B_addr = ioctl_download ? ioctl_addr - 27'h14000 : char_rom_addr;
wire        u5B_wr_n = ioctl_download && ioctl_addr >= 27'h14000 && ioctl_addr < 27'h18000 ? ioctl_wr : 1'b0;

assign char_data = u5B_q;

ram #(14,8) u5B(
  .clk  ( clk_sys    ),
  .addr ( u5B_addr   ),
  .din  ( ioctl_dout ),
  .q    ( u5B_q      ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~u5B_wr_n  ),
  .ce_n ( 1'b0       )
);

// tilemap ROM

`ifdef EXT_ROM
assign gfx1_addr = map_rom_addr;
assign map_data = gfx1_data;
`else
wire  [7:0] u12F_q;

assign map_data = u12F_q;
wire [14:0] u12F_addr = ioctl_download ? ioctl_addr - 27'h60000 : map_rom_addr;
wire        u12F_wr_n = ioctl_download && ioctl_addr >= 27'h60000 && ioctl_addr < 27'h68000 ? ioctl_wr : 1'b0;

ram #(15,8) u12F(
  .clk  ( clk_sys    ),
  .addr ( u12F_addr  ),
  .din  ( ioctl_dout ),
  .q    ( u12F_q     ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~u12F_wr_n ),
  .ce_n ( 1'b0       )
);
`endif

// background tiles ROMs

wire [7:0] u8E_q;
wire [7:0] u8F_q;
wire [7:0] u8H_q;

// remove bit 12 (BGCA 7)
wire [14:0] bg_rom_addr_u8E = { bg_rom_addr[15:13], bg_rom_addr[11:0] };

`ifdef EXT_ROM
assign gfx2_addr = bg_rom_addr_u8E;
assign bg_data2  = gfx2_data;
assign gfx3_addr = bg_rom_addr;
assign bg_data1  = gfx3_data;
`else
wire [14:0] u8E_addr = ioctl_download ? ioctl_addr - 27'h48000 : bg_rom_addr_u8E;
wire        u8E_wr_n = ioctl_download && ioctl_addr >= 27'h48000 && ioctl_addr < 27'h50000 ? ioctl_wr : 1'b0;
wire [14:0] u8F_addr = ioctl_download ? ioctl_addr - 27'h50000 : bg_rom_addr[14:0];
wire        u8F_wr_n = ioctl_download && ioctl_addr >= 27'h50000 && ioctl_addr < 27'h58000 ? ioctl_wr : 1'b0;
wire [14:0] u8H_addr = ioctl_download ? ioctl_addr - 27'h58000 : bg_rom_addr[14:0];
wire        u8H_wr_n = ioctl_download && ioctl_addr >= 27'h58000 && ioctl_addr < 27'h60000 ? ioctl_wr : 1'b0;

assign bg_data1 = u8F_q | u8H_q;
assign bg_data2 = u8E_q;

wire u8F_ce = ~bg_rom_addr[15];
wire u8H_ce =  bg_rom_addr[15];

ram #(15,8) u8E(
  .clk  ( clk_sys    ),
  .addr ( u8E_addr   ),
  .din  ( ioctl_dout ),
  .q    ( u8E_q      ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~u8E_wr_n  ),
  .ce_n ( 1'b0       )
);

ram #(15,8) u8F(
  .clk  ( clk_sys    ),
  .addr ( u8F_addr   ),
  .din  ( ioctl_dout ),
  .q    ( u8F_q      ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~u8F_wr_n  ),
  .ce_n ( ~u8F_ce    )
);

ram #(15,8) u8H(
  .clk  ( clk_sys    ),
  .addr ( u8H_addr   ),
  .din  ( ioctl_dout ),
  .q    ( u8H_q      ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~u8H_wr_n  ),
  .ce_n ( ~u8H_ce    )
);
`endif

// sprite ROMs

assign sp_addr = sp_rom_addr[15:0];

`ifdef EXT_ROM

assign sp_rom_data1 = sp_data[ 7: 0];
assign sp_rom_data2 = sp_data[15: 8];
assign sp_rom_data3 = sp_data[23:16];

`else

wire [14:0] u16H_addr = ioctl_download ? ioctl_addr - 27'h18000 : sp_rom_addr[14:0];
wire        u16H_wr_n = ioctl_download && ioctl_addr >= 27'h18000 && ioctl_addr < 27'h20000 ? ioctl_wr : 1'b0;
wire [14:0] u14H_addr = ioctl_download ? ioctl_addr - 27'h20000 : sp_rom_addr[14:0];
wire        u14H_wr_n = ioctl_download && ioctl_addr >= 27'h20000 && ioctl_addr < 27'h28000 ? ioctl_wr : 1'b0;
wire [14:0] u16K_addr = ioctl_download ? ioctl_addr - 27'h28000 : sp_rom_addr[14:0];
wire        u16K_wr_n = ioctl_download && ioctl_addr >= 27'h28000 && ioctl_addr < 27'h30000 ? ioctl_wr : 1'b0;
wire [14:0] u14K_addr = ioctl_download ? ioctl_addr - 27'h30000 : sp_rom_addr[14:0];
wire        u14K_wr_n = ioctl_download && ioctl_addr >= 27'h30000 && ioctl_addr < 27'h38000 ? ioctl_wr : 1'b0;
wire [14:0] u13K_addr = ioctl_download ? ioctl_addr - 27'h38000 : sp_rom_addr[14:0];
wire        u13K_wr_n = ioctl_download && ioctl_addr >= 27'h38000 && ioctl_addr < 27'h40000 ? ioctl_wr : 1'b0;
wire [14:0] u11K_addr = ioctl_download ? ioctl_addr - 27'h40000 : sp_rom_addr[14:0];
wire        u11K_wr_n = ioctl_download && ioctl_addr >= 27'h40000 && ioctl_addr < 27'h48000 ? ioctl_wr : 1'b0;

wire [7:0] u16H_q;
wire [7:0] u14H_q;
wire [7:0] u16K_q;
wire [7:0] u14K_q;
wire [7:0] u13K_q;
wire [7:0] u11K_q;

wire sroml_ce = ~sp_rom_addr[15];
wire sromh_ce =  sp_rom_addr[15];

assign sp_rom_data1 = sroml_ce ? u16H_q : u14H_q;
assign sp_rom_data2 = sroml_ce ? u16K_q : u14K_q;
assign sp_rom_data3 = sroml_ce ? u13K_q : u11K_q;

ram #(15,8) u16H(
  .clk  ( clk_sys     ),
  .addr ( u16H_addr   ),
  .din  ( ioctl_dout  ),
  .q    ( u16H_q      ),
  .rd_n ( 1'b0        ),
  .wr_n ( ~u16H_wr_n  ),
  .ce_n ( ~sroml_ce   )
);

ram #(15,8) u14H(
  .clk  ( clk_sys     ),
  .addr ( u14H_addr   ),
  .din  ( ioctl_dout  ),
  .q    ( u14H_q      ),
  .rd_n ( 1'b0        ),
  .wr_n ( ~u14H_wr_n  ),
  .ce_n ( ~sromh_ce   )
);

ram #(15,8) u16K(
  .clk  ( clk_sys     ),
  .addr ( u16K_addr   ),
  .din  ( ioctl_dout  ),
  .q    ( u16K_q      ),
  .rd_n ( 1'b0        ),
  .wr_n ( ~u16K_wr_n  ),
  .ce_n ( ~sroml_ce   )
);

ram #(15,8) u14K(
  .clk  ( clk_sys     ),
  .addr ( u14K_addr   ),
  .din  ( ioctl_dout  ),
  .q    ( u14K_q      ),
  .rd_n ( 1'b0        ),
  .wr_n ( ~u14K_wr_n  ),
  .ce_n ( ~sromh_ce   )
);

ram #(15,8) u13K(
  .clk  ( clk_sys     ),
  .addr ( u13K_addr   ),
  .din  ( ioctl_dout  ),
  .q    ( u13K_q      ),
  .rd_n ( 1'b0        ),
  .wr_n ( ~u13K_wr_n  ),
  .ce_n ( ~sroml_ce   )
);

ram #(15,8) u11K(
  .clk  ( clk_sys     ),
  .addr ( u11K_addr   ),
  .din  ( ioctl_dout  ),
  .q    ( u11K_q      ),
  .rd_n ( 1'b0        ),
  .wr_n ( ~u11K_wr_n  ),
  .ce_n ( ~sromh_ce   )
);

`endif

endmodule


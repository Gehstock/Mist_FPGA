
module mcpu(
  input clk_sys,
  input reset,
  input pause,
  input coin1,
  input nmi_clear,
  input vblk,
  output [15:0] cpu_ab,
  input [7:0] cpu_din,
  output [7:0] cpu_dout,
  output rw
);

wire cen_15;
wire cpu_clk;
clk_en #(31) cpu_clk_en(clk_sys, cen_15, cpu_clk);

wire coin1_re;
rising_edge rising_edge_coin(clk_sys, coin1, coin1_re);

reg F13E_Q;
always @(posedge clk_sys) begin
  if (coin1_re) F13E_Q <= 1'b1;
  if (nmi_clear) F13E_Q <= 1'b0;
end

wire irq = ~F13E_Q;

wire [7:0] din, dout;
wire [15:0] addr;
wire sync;

`ifdef SYNTH

T65 M6502 (
  .Res_n  ( ~reset ),
  .Enable ( cen_15  ),
  .Rdy    ( ~pause  ),
  .Clk    ( clk_sys ),
  .IRQ_n  ( irq     ),
  .R_W_n  ( rw      ),
  .A      ( addr    ),
  .DI     ( din     ),
  .DO     ( dout    ),
  .Sync   ( sync    )
);

`else

wire m6502_we;
assign rw = ~m6502_we;

cpu6502 M6502(
  .clk   ( cen_15   ),
  .reset ( reset    ),
  .AB    ( addr     ),
  .DI    ( din      ),
  .DO    ( dout     ),
  .WE    ( m6502_we ),
  .IRQ   ( ~irq     ),
  .NMI   ( 1'b0     ),
  .RDY   ( 1'b1     ),
  .SYNC  ( sync     )
);

`endif

CPU16 CPU16(
  .clk     ( clk_sys  ),
  .cen     ( cen_15   ),
  .reset   ( reset    ),
  .ABI     ( addr     ),
  .ABO     ( cpu_ab   ),
  .CPU_DBI ( dout     ),
  .CPU_DBO ( din      ),
  .DBI     ( cpu_din  ),
  .DBO     ( cpu_dout ),
  .SYNC    ( sync     ),
  .RW      ( rw       ),
  .VB      ( vblk     )
);


endmodule

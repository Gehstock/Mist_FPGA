
module mcpu(
  input         clk_sys,
  input         reset,
  input  [7:0]  cpu_din,
  output [7:0]  cpu_dout,
  output [15:0] cpu_ab,
  output        cpu_wr,
  output        cpu_rd,
  output        cpu_io,
  output        cpu_m1,
  input         vb
);

wire cen_26;
assign cpu_io = ~cpu_iorq_n;
assign cpu_m1 = ~cpu_m1_n;
assign cpu_wr = ~cpu_wr_n;
assign cpu_rd = ~cpu_rd_n;

wire        cpu_rd_n;
wire        cpu_wr_n;
wire        cpu_m1_n;
wire        cpu_mreq_n;
wire        cpu_iorq_n;
wire        cpu_rfsh_n;
wire        cpu_nmi_n = ~|hold_nmi;
wire        cpu_wait_n = 1'b1;

clk_en #(17) cpu_clk_en(clk_sys, cen_26);

reg old_vb;
reg [7:0] hold_nmi;
always @(posedge clk_sys) begin
  old_vb <= vb;
  if (~old_vb & vb) hold_nmi <= 8'hff;
  if (hold_nmi != 8'd0) hold_nmi <= hold_nmi - 8'd1;
end

T80se cpu (
	.RESET_n			( ~reset      ),
	.CLK_n			( clk_sys     ),
	.CLKEN			( cen_26      ),
	.WAIT_n			( cpu_wait_n  ),
	.INT_n			( 1'b1        ),
	.NMI_n			( cpu_nmi_n   ),
	.BUSRQ_n			( 1'b1        ),
	.M1_n				( cpu_m1_n    ),
	.MREQ_n			( cpu_mreq_n  ),
	.IORQ_n			( cpu_iorq_n  ),
	.RD_n				( cpu_rd_n    ),
	.WR_n				( cpu_wr_n    ),
	.RFSH_n			( cpu_rfsh_n  ),
	.HALT_n			(             ),
	.BUSAK_n			(             ),
	.A					( cpu_ab      ),
	.DI				( cpu_din  ),
	.DO				( cpu_dout    )
	);

endmodule

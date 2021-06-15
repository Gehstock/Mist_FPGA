// Copyright (c) 2011 MiSTer-X

module Z80IP
(
	input				reset_in,
	input				clk,
	input				clken_p,
	input				clken_n,
	output [15:0]	adr,
	input  [7:0]	data_in,
	output [7:0]	data_out,
	output			rd,
	output			wr,
	input				intreq,
	output			intack
);

assign intack = (adr==16'h38);

wire nmireq = 0;

wire i_mreq, i_iorq, i_rd, i_wr, i_rfsh; 

T80pa cpu(
	.CLK(clk),
	.CEN_p(clken_p),
	.CEN_n(clken_n),
	.RESET_n(~reset_in),
	.INT_n(~intreq),
	.NMI_n(~nmireq),
	.MREQ_n(i_mreq),
	.IORQ_n(i_iorq),
	.RFSH_n(i_rfsh),
	.RD_n(i_rd),
	.WR_n(i_wr),
	.A(adr),
	.DI(data_in),
	.DO(data_out),
	.WAIT_n(1'b1),
	.BUSRQ_n(1'b1),
	.BUSAK_n(),
	.HALT_n(),
	.M1_n()
);

wire mreq = (~i_mreq) & (i_rfsh);
//wire iorq = ~i_iorq;
wire rdr  = ~i_rd;
wire wrr  = ~i_wr;

assign rd = mreq & rdr;
assign wr = mreq & wrr;

endmodule


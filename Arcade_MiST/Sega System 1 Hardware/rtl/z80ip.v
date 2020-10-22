// Copyright (c) 2017,19 MiSTer-X

module Z80IP
(
	input         reset,
	input         clk,
	input         clk_en,
	output [15:0] adr,
	input   [7:0] data_in,
	output  [7:0] data_out,
	output        m1,
	output        mx,
	output        ix,
	output        rd,
	output        wr,
	input         intreq,
	output        intack,
	input         nmireq,
	output        nmiack
);

wire i_mreq, i_iorq, i_rd, i_wr, i_rfsh, i_m1;

T80s cpu
(
	.CLK(clk),
	.CEN(clk_en),
	.RESET_n(~reset),
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
	.M1_n(i_m1)
);

wire mreq = (~i_mreq) & (i_rfsh);
wire iorq = ~i_iorq;
wire rdr  = ~i_rd;
wire wrr  = ~i_wr;

assign intack = (adr==16'h38) & mx & rdr;
assign nmiack = (adr==16'h66) & mx & rdr;

assign m1 = ~i_m1;
assign mx = mreq;
assign ix = iorq;
assign rd = rdr;
assign wr = wrr;

endmodule


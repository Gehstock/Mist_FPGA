module clock(
    input clk,
    input rst_n,
	input Phi2,
    output cpu_clken
    );

wire ff1_out;

ls74 LS74
(
  .n_pre1(1'b1),
  .n_pre2(),
  .n_clr1(1'b1),
  .n_clr2(),
  .clk1(clk),
  .clk2(),
  .d1(Phi2),
  .d2(),
  .q1(ff1_out),
  .q2(),
  .n_q1(),
  .n_q2()
);

wire int1 = (Phi2 ^ ff1_out);
assign cpu_clken = (Phi2 & int1);

endmodule

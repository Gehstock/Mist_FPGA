/*
 * Clock
 */
module clock(
  input  logic CLK_DRV, CLK_SRC,
  output logic CLOCK, CLOCK_N
);
  logic C7b_Q, C7b_Q_N;

  SN7474 SN7474_C7b(
    .CLK_DRV,
    .CLK(CLK_SRC),
    .PRE_N(1'b1),
    .CLR_N(1'b1),
    .D(C7b_Q_N),
    .Q(C7b_Q), .Q_N(C7b_Q_N)
  );

  assign CLOCK   = C7b_Q_N;
  assign CLOCK_N = C7b_Q;

endmodule

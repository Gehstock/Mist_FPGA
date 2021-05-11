/*
 * Vertical video counter
 */
module vcounter(
  input  logic CLK_DRV, HRESET,
  input  logic RESET_N,
  output logic _1V, _2V, _4V, _8V, _16V, _32V, _64V, _128V, _256V, _256V_N,
  output logic VRESET, VRESET_N
);
  logic F6_QA, F6_QB, F6_QC, F6_QD;
  logic H6_QA, H6_QB, H6_QC, H6_QD;
  logic H7a_Q, H7a_Q_N;
  logic E6;
  logic F7b_Q, F7b_Q_N;

  SN7493 SN7493_F6(
    .CLK_DRV,
    .CKA_N(HRESET), .CKB_N(F6_QA),
    .R0(F7b_Q_N), .R1(F7b_Q_N),
    .QA(F6_QA), .QB(F6_QB), .QC(F6_QC), .QD(F6_QD)
  );

  SN7493 SN7493_H6(
    .CLK_DRV,
    .CKA_N(F6_QD), .CKB_N(H6_QA),
    .R0(F7b_Q_N), .R1(F7b_Q_N),
    .QA(H6_QA), .QB(H6_QB), .QC(H6_QC), .QD(H6_QD)
  );

  SN74107 SN74107_H7a(
    .CLK_DRV,
    .CLK_N(H6_QD),
    .CLR_N(F7b_Q),
    .J(1'b1), .K(1'b1),
    .Q(H7a_Q), .Q_N(H7a_Q_N)
  );

  assign E6 = ~(H7a_Q & F6_QA & F6_QC);

  SN7474 SN7474_F7b(
    .CLK_DRV,
    .CLK(HRESET),
    .PRE_N(1'b1), .CLR_N(RESET_N),
    .D(E6),
    .Q(F7b_Q), .Q_N(F7b_Q_N)
  );

  assign {_1V, _2V, _4V, _8V}      = {F6_QA, F6_QB, F6_QC, F6_QD};
  assign {_16V, _32V, _64V, _128V} = {H6_QA, H6_QB, H6_QC, H6_QD};
  assign {_256V, _256V_N}          = {H7a_Q, H7a_Q_N};
  assign {VRESET, VRESET_N}        = {F7b_Q_N, F7b_Q};

endmodule

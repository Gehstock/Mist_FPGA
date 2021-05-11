/*
 * Horizontal video counter
 */
module hcounter(
  input  logic CLK_DRV, CLOCK,
  input  logic RESET_N,
  output logic _1H, _2H, _4H, _8H, _16H, _32H, _64H, _128H, _256H, _256H_N,
  output logic HRESET, HRESET_N
);
  logic L7_QA, L7_QB, L7_QC, L7_QD;
  logic K7_QA, K7_QB, K7_QC, K7_QD;
  logic H7b_Q, H7b_Q_N;
  logic J7;
  logic F7a_Q, F7a_Q_N;

  SN7493 SN7493_L7(
    .CLK_DRV,
    .CKA_N(CLOCK), .CKB_N(L7_QA),
    .R0(F7a_Q_N), .R1(F7a_Q_N),
    .QA(L7_QA), .QB(L7_QB), .QC(L7_QC), .QD(L7_QD)
  );

  SN7493 SN7493_K7(
    .CLK_DRV,
    .CKA_N(L7_QD), .CKB_N(K7_QA),
    .R0(F7a_Q_N), .R1(F7a_Q_N),
    .QA(K7_QA), .QB(K7_QB), .QC(K7_QC), .QD(K7_QD)
  );

  SN74107 SN74107_H7b(
    .CLK_DRV,
    .CLK_N(K7_QD),
    .CLR_N(F7a_Q),
    .J(1'b1), .K(1'b1),
    .Q(H7b_Q), .Q_N(H7b_Q_N)
  );

  assign J7 = ~(1'b1 & 1'b1 & 1'b1 & H7b_Q & K7_QD & K7_QC & L7_QC & L7_QB);

  SN7474 SN7474_F7a(
    .CLK_DRV,
    .CLK(CLOCK),
    .PRE_N(1'b1), .CLR_N(RESET_N),
    .D(J7),
    .Q(F7a_Q), .Q_N(F7a_Q_N)
  );

  assign {_1H, _2H, _4H, _8H}      = {L7_QA, L7_QB, L7_QC, L7_QD};
  assign {_16H, _32H, _64H, _128H} = {K7_QA, K7_QB, K7_QC, K7_QD};
  assign {_256H, _256H_N}          = {H7b_Q, H7b_Q_N};
  assign {HRESET, HRESET_N}        = {F7a_Q_N, F7a_Q};

endmodule

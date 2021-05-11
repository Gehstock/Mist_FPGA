/*
 * Score count and display
 */
module score(
  input  logic CLK_DRV,
  input  logic SCORE_1, SCORE_2,
  input  logic RESET_SCORE_N,
  input  logic STAR_BLANK,
  input  logic _4H, _8H, _16H, _32H, _64H, _128H, _256H_N,
  input  logic _4V, _8V, _16V,
  output logic SCORE_N
);
  // ---------------------------------------------------------------------------
  // Score reset
  // ---------------------------------------------------------------------------
  logic E9b;
  assign E9b = ~RESET_SCORE_N;

  // ---------------------------------------------------------------------------
  // Score counter for Rocket 1
  // ---------------------------------------------------------------------------
  logic J9_QA, J9_QB, J9_QC, J9_QD;
  logic H9_QA, H9_QB, H9_QC, H9_QD;

  // Ones digit
  SN7490 SN7490_J9(
    .CLK_DRV,
    .CKA_N(SCORE_1), .CKB_N(J9_QA),
    .R01(E9b), .R02(E9b),
    .R91(1'b0), .R92(1'b0),
    .QA(J9_QA), .QB(J9_QB), .QC(J9_QC), .QD(J9_QD)
  );

  // Tens digit
  SN7490 SN7490_H9(
    .CLK_DRV,
    .CKA_N(J9_QD), .CKB_N(H9_QA),
    .R01(E9b), .R02(E9b),
    .R91(1'b0), .R92(1'b0),
    .QA(H9_QA), .QB(H9_QB), .QC(H9_QC), .QD(H9_QD)
  );

  // ---------------------------------------------------------------------------
  // Score counter for Rocket 2
  // ---------------------------------------------------------------------------
  logic L9_QA, L9_QB, L9_QC, L9_QD;
  logic K9_QA, K9_QB, K9_QC, K9_QD;

  // Ones digit
  SN7490 SN7490_L9(
    .CLK_DRV,
    .CKA_N(SCORE_2), .CKB_N(L9_QA),
    .R01(E9b), .R02(E9b),
    .R91(1'b0), .R92(1'b0),
    .QA(L9_QA), .QB(L9_QB), .QC(L9_QC), .QD(L9_QD)
  );

  // Tens digit
  SN7490 SN7490_K9(
    .CLK_DRV,
    .CKA_N(L9_QD), .CKB_N(K9_QA),
    .R01(E9b), .R02(E9b),
    .R91(1'b0), .R92(1'b0),
    .QA(K9_QA), .QB(K9_QB), .QC(K9_QC), .QD(K9_QD)
  );

  // ---------------------------------------------------------------------------
  // Score selector
  // ---------------------------------------------------------------------------
  logic A, B, C, D;

  SN74153 SN74153_L8(
    .A(_32H), .B(_64H),
    ._1G_N(1'b0), ._2G_N(1'b0),
    ._1C0(H9_QA), ._1C1(J9_QA), ._1C2(K9_QA), ._1C3(L9_QA),
    ._2C0(H9_QB), ._2C1(J9_QB), ._2C2(K9_QB), ._2C3(L9_QB),
    ._1Y(A), ._2Y(B)
  );

  SN74153 SN74153_K8(
    .A(_32H), .B(_64H),
    ._1G_N(1'b0), ._2G_N(1'b0),
    ._1C0(H9_QC), ._1C1(J9_QC), ._1C2(K9_QC), ._1C3(L9_QC),
    ._2C0(H9_QD), ._2C1(J9_QD), ._2C2(K9_QD), ._2C3(L9_QD),
    ._1Y(C), ._2Y(D)
  );

  // ---------------------------------------------------------------------------
  // 7-seg decoder
  // ---------------------------------------------------------------------------
  logic a, b, c, d, e, f, g;

  SN7448 #(
    .BI_RBO_N_AS_INPUT(1'b0)
  ) SN7448_J8 (
    .BI_RBO_N(), .RBI_N(_32H), .LT_N(1'b1),
    .A, .B, .C, .D,
    .a, .b, .c, .d, .e, .f, .g
  );

  // ---------------------------------------------------------------------------
  // Score dipslay
  // ---------------------------------------------------------------------------
  logic D6d, D7a, B7c, E7a, E6a, E7b, D7b, E9c, D7d;
  logic E7c, E8c, H8a, H8c, F8b, H8b, E8b, F8a, F8c;
  logic D7c, D8b, F9, E8a;

  assign D6d = ~(_4H & _8H);
  assign D7a = ~_16H;
  assign B7c = ~D6d & ~D7a;
  assign E7a = ~D7a & ~_4V & ~_8V;
  assign E6a = ~(_16H & _4V & _8V);
  assign E7b = ~_4H & ~_8H & ~D7a;
  assign D7b = ~_64H;
  assign E9c = ~_16V;
  assign D7d = ~E6a;
  assign E7c = ~D7b & ~_128H & ~_256H_N;
  assign E8c = ~(D7b & _128H & _256H_N);
  assign H8a = ~(f & E7b & E9c);
  assign H8c = ~(e & E7b & _16V);
  assign F8b = ~(b & B7c & E9c);
  assign H8b = ~(c & B7c & _16V);
  assign E8b = ~(a & E9c & E7a);
  assign F8a = ~(g & E9c & D7d);
  assign F8c = ~(d & D7d & _16V);
  assign D7c = ~E7c;
  assign D8b = ~D7c | ~E8c;
  assign F9  = ~H8a | ~H8c | ~F8b | ~1'b1 | ~H8b | ~E8b | ~F8a | ~F8c;
  assign E8a = ~(STAR_BLANK & D8b & F9);

  assign SCORE_N = E8a;

endmodule

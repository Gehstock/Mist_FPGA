/*
 * Stars generation
 */
module stars(
  input  logic CLK_DRV,
  input  logic CLOCK,
  input  logic RESET_N,
  input  logic HRESET_N,
  input  logic VRESET, VRESET_N,
  input  logic VBLANK_N,
  input  logic _1V, _2V, _4V, _8V, _16V, _32V, _64V, _128V,
  input  logic V_WINDOW,
  output logic STARS_N
);
  // ---------------------------------------------------------------------------
  // Horizontal counter drifting rightward
  // ---------------------------------------------------------------------------
  // A counter formed by E2, D2, C2a counts from 57 to 511 (total 455),
  // which is the same count as the horizontal video counter.
  //
  // Only on VRESET asserted, its start (load) value changes to 56,
  // which means it counts only one more than the horizontal video counter.
  //
  // B1a is asserted on count 511.
  // So B1a is asserted on the same position on every horizontal video line
  // in one video frame.
  // And the position drifts one to the right on next video frame.
  //
  // B1a can be said to the horizontal base line of stars flowing leftward.
  //
  logic E2_RCO, D2_RCO, C2a_Q, B1a;

  DM9316 DM9316_E2(
    .CLK_DRV,
    .CLK(CLOCK), .CLR_N(RESET_N), .LOAD_N(B1a), .ENP(1'b1), .ENT(1'b1),
    .A(VRESET_N), .B(1'b0), .C(1'b0), .D(1'b1),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(E2_RCO)
  );

  DM9316 DM9316_D2(
    .CLK_DRV,
    .CLK(CLOCK), .CLR_N(RESET_N), .LOAD_N(B1a), .ENP(1'b1), .ENT(E2_RCO),
    .A(1'b1), .B(1'b1), .C(1'b0), .D(1'b0),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(D2_RCO)
  );

  SN74107 SN74107_C2a(
    .CLK_DRV,
    .CLK_N(D2_RCO),
    .CLR_N(RESET_N),
    .J(1'b1), .K(1'b1),
    .Q(C2a_Q), .Q_N()
  );

  assign B1a = ~(C2a_Q & D2_RCO);

  // ---------------------------------------------------------------------------
  // Horizontal counter drifting leftward
  // ---------------------------------------------------------------------------
  // A counter formed by A2, B2, C2b counts from 57 to 511 (total 455),
  // which is the same count as the horizontal video counter.
  //
  // Only on VRESET asserted, its start (load) value changes to 58,
  // which means it counts only one less than the horizontal video counter.
  //
  // B1b is asserted on count 511.
  // So B1b is asserted on the same position on every horizontal video line
  // in one video frame.
  // And the position drifts one to the left on next video frame.
  //
  // B1b can be said to the horizontal base line of stars flowing leftward.
  //
  logic A2_RCO, B2_RCO, C2b_Q, B1b;

  DM9316 DM9316_A2(
    .CLK_DRV,
    .CLK(CLOCK), .CLR_N(1'b1), .LOAD_N(B1b), .ENP(1'b1), .ENT(1'b1),
    .A(VRESET_N), .B(VRESET), .C(1'b0), .D(1'b1),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(A2_RCO)
  );

  DM9316 DM9316_B2(
    .CLK_DRV,
    .CLK(CLOCK), .CLR_N(1'b1), .LOAD_N(B1b), .ENP(1'b1), .ENT(A2_RCO),
    .A(1'b1), .B(1'b1), .C(1'b0), .D(1'b0),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(B2_RCO)
  );

  SN74107 SN74107_C2b(
    .CLK_DRV,
    .CLK_N(B2_RCO),
    .CLR_N(1'b1),
    .J(1'b1), .K(1'b1),
    .Q(C2b_Q), .Q_N()
  );

  assign B1b = ~(C2b_Q & B2_RCO);

  // -------------------------------------------------------------------------
  // Selecting vertical line where stars will appear
  // -------------------------------------------------------------------------
  // D1 counter counts 0 to 8 repeatedly at rising edge of A1c (HRESET)
  // except on VBLANK.
  //
  // E1b_Q_N is asserted on count 0 and is gating B1a at C1a.
  // So stars flowing rightward will appear once per 9 lines.
  // C1a is indicating base position where stars flowing rightward will appear.
  //
  // F4a_Q is asserted on count 5 and is gating B1b at C1c.
  // So stars flowing rightward will appear once per 9 lines
  // and between starts flowing leftward.
  // C1c is indicating base position where stars flowing leftward will appear.
  //
  // A1b is combined signal of C1a and C1c,
  // indicating base position of each star.
  //
  logic A1c, B1d, E3e, C1b, E3d;
  logic C1a, C1c, A1b;
  logic D1_QA, D1_QB, D1_QC, D1_QD;
  logic E1b_Q_N, F4a_Q;

  SN7493 SN7493_D1(
    .CLK_DRV,
    .CKA_N(A1c), .CKB_N(D1_QA),
    .R0(B1d), .R1(B1d),
    .QA(D1_QA), .QB(D1_QB), .QC(D1_QC), .QD(D1_QD)
  );

  SN7474 SN7474_E1b(
    .CLK_DRV,
    .CLK(A1c),
    .PRE_N(1'b1), .CLR_N(1'b1),
    .D(D1_QD),
    .Q(), .Q_N(E1b_Q_N)
  );

  SN74107 SN74107_F4a(
    .CLK_DRV,
    .CLK_N(A1c),
    .CLR_N(1'b1),
    .J(E3d), .K(C1b),
    .Q(F4a_Q), .Q_N()
  );

  assign A1c = ~(HRESET_N | HRESET_N);
  assign B1d = ~E1b_Q_N | ~VBLANK_N;
  assign E3e = ~D1_QC;
  assign C1b = ~E3e & ~D1_QA & ~D1_QB;
  assign E3d = ~C1b;

  assign C1a = ~B1a & ~E1b_Q_N & ~A1c;
  assign C1c = ~B1b & ~F4a_Q   & ~A1c;
  assign A1b = ~(C1a | C1c);

  // ---------------------------------------------------------------------------
  // Giving variance to horizontal position of stars
  // ---------------------------------------------------------------------------
  // A counter formed by F5 and E5 counts different but predetermined value
  // starting from A1b(base position of each star) on each vertical line,
  // which gives variance to horizontal position of stars.
  //
  // Randomness comes from the following two factors.
  //
  // 1. Counter load value
  //  Counter load value is constructed from reversed each bit of
  //  vertical video counter.
  //
  // 2. Extra count depending on even or odd line
  //  On vertical line with even vertical video count,
  //  F4b_Q goes low when count starts, which gives extra 256 counts
  //  after once count ends.
  //  This does not happen on vertical line with odd vertical video count.
  //
  // Counting is inhibited during V_WINDOW deasserted,
  // thus no stars will appear on the bottom of the screen(score area).
  //
  // Falling edge of D4c indicates where each star will appear.
  //
  logic F5_RCO, E5_RCO;
  logic F4b_Q;
  logic D5c, D4b, D4a, F3a, D4c, H1a, E4d, E4b, H1c, E4a;
  logic H1a_q;

  DM9316 DM9316_F5(
    .CLK_DRV,
    .CLK(H1c), .CLR_N(V_WINDOW), .LOAD_N(A1b), .ENP(1'b1), .ENT(1'b1),
    .A(1'b0), .B(_128V), .C(_64V), .D(_32V),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(F5_RCO)
  );

  DM9316 DM9316_E5(
    .CLK_DRV,
    .CLK(H1c), .CLR_N(V_WINDOW), .LOAD_N(A1b), .ENP(1'b1), .ENT(F5_RCO),
    .A(_16V), .B(_8V), .C(_4V), .D(_2V),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(E5_RCO)
  );

  // E5_RCO is not connected to nowhere on schematics.
  // But it should be connected to F3a, D4c, H1a.

  SN74107 SN74107_F4b(
    .CLK_DRV,
    .CLK_N(E4a),
    .CLR_N(V_WINDOW),
    .J(D4b), .K(D4a),
    .Q(F4b_Q), .Q_N()
  );

  assign D5c = ~A1b;
  assign D4b = ~(D5c & D4a);
  assign D4a = ~(D5c & _1V);
  assign F3a = ~(E5_RCO | E5_RCO);
  assign D4c = ~(E5_RCO & F4b_Q); // TC_N
  assign H1a = ~(F4b_Q & E5_RCO & A1b);
  assign E4d = ~CLOCK & ~CLOCK;
  assign E4b = ~H1c & ~A1b;
  assign H1c = ~(H1a_q & E4d & E4d);
  assign E4a = ~(F3a | E4b);

  // break combinational loop
  always_ff @(posedge CLK_DRV) H1a_q <= H1a;

  // ---------------------------------------------------------------------------
  // Final signal
  // ---------------------------------------------------------------------------
  // DM9602 Monostable multivibrator outputs star signal with some width.
  //
  DM9602 #(
    .COUNTS(23)  // 400 ns
  ) DM9602_L4b (
    .CLK(CLK_DRV),
    .A_N(D4c), .B(1'b0),
    .CLR_N(1'b1),
    .Q(), .Q_N(STARS_N)
  );

endmodule

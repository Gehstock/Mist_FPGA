/*
 * Miscellaneous video signal
 */
module videomisc(
  input  logic CLK_DRV,
  input  logic _8V, _16V, _32V, _64V, _128V,
  input  logic HSYNC,
  input  logic VRESET_N,
  input  logic ROCKETS_N,
  input  logic STARS_N,
  input  logic SCORE_N,
  input  logic FUEL_N,
  output logic STAR_BLANK,
  output logic V_WINDOW,
  output logic R_RESET,
  output logic R_BBOUND,
  output logic VIDEO, SCORE
);
  // ---------------------------------------------------------------------------
  // STAR_BLANK (to score)
  // ---------------------------------------------------------------------------
  // STAR_BLANK : vertical video counter from 224 to 255
  // STAR_BLANK defines the area where score will be displayed.
  //
  logic K6b, E3f;
  assign K6b = ~(_32V & _64V & _128V);
  assign E3f = ~K6b;
  assign STAR_BLANK = E3f;

  // ---------------------------------------------------------------------------
  // V_WINDOW
  // ---------------------------------------------------------------------------
  // D6a(V_WINDOW)  : vertical video counter from 0 to 223
  // D6b(V_WINDOW_N): vertical video counter from 224 to 261
  //
  // V_WINDOW defines the area where flowing stars will appear.
  // There are no flowing stars on D6b(V_WINDOW_N).
  //
  logic D6b, D6a;

  nand_rsff nand_rsff_D6b_D6a(
    .CLK_DRV,
    .S_N(K6b), .R_N(VRESET_N),
    .Q(D6b), .Q_N(D6a)
  );

  assign V_WINDOW = D6a;

  // ---------------------------------------------------------------------------
  // R_RESET
  // ---------------------------------------------------------------------------
  // R_RESET is asserted on the beginning of vertical video count 248 and is
  // used for resetting rocket Y-pos counter to determine the initial position.
  //
  logic E6c, F3b, E1a_Q_N;

  SN7474 SN7474_E1a(
    .CLK_DRV,
    .CLK(HSYNC),
    .PRE_N(1'b1), .CLR_N(1'b1),
    .D(E6c),
    .Q(), .Q_N(E1a_Q_N)
  );

  assign E6c = ~(D6b & _16V & _8V);
  assign F3b = ~E6c & ~E1a_Q_N;
  assign R_RESET = F3b;

  // ---------------------------------------------------------------------------
  // R_BBOUND
  // ---------------------------------------------------------------------------
  // E1a_Q_N has no name on schematics but but given it a name for convenience.
  //
  // It is asserted just after R_RESET deasserted on vertical video count 248
  // and is used for STOP signal generation.
  //
  assign R_BBOUND = E1a_Q_N;

  // ---------------------------------------------------------------------------
  // Video mix
  // ---------------------------------------------------------------------------
  logic D3a, D8a;
  assign D3a = ~ROCKETS_N | ~STARS_N;
  assign D8a = ~SCORE_N | ~FUEL_N;

  assign VIDEO = D3a;
  assign SCORE = D8a;

endmodule

/*
 * Crash detection and signal generation
 */
module crash(
  input  logic CLK_DRV,
  input  logic ROCKETS_N,
  input  logic STARS_N,
  input  logic _256H, _256H_N,
  output logic CRASH_1_N, CRASH_2_N, CRASH_N
);
  // ---------------------------------------------------------------------------
  // Crash detection
  // ---------------------------------------------------------------------------
  logic A1d;
  assign A1d = ~ROCKETS_N & ~STARS_N;

  // ---------------------------------------------------------------------------
  // Rocket 1 crash signal
  // ---------------------------------------------------------------------------
  logic A6_OUT, D3c, E5d;

  oneshot_555 #(
    .COUNTS(97588491)  // 1.7s
  ) oneshot_555_A6 (
    .CLK(CLK_DRV),
    .RST_N(1'b1),
    .TRG_N(D3c),
    .OUT(A6_OUT)
  );

  assign D3c = ~(_256H_N & A1d);
  assign E5d = ~A6_OUT;
  assign CRASH_1_N = E5d;

  // ---------------------------------------------------------------------------
  // Rocket 2 crash signal
  // ---------------------------------------------------------------------------
  logic B6_OUT, D3b, D5e;

  oneshot_555 #(
    .COUNTS(97588491)  // 1.7s
  ) oneshot_555_B6 (
    .CLK(CLK_DRV),
    .RST_N(1'b1),
    .TRG_N(D3b),
    .OUT(B6_OUT)
  );

  assign D3b = ~(_256H & A1d);
  assign D5e = ~B6_OUT;
  assign CRASH_2_N = D5e;

  // ---------------------------------------------------------------------------
  // Common crash signal for crash sound trigger
  // ---------------------------------------------------------------------------
  logic A1a;
  assign A1a = ~(A1d | A1d);
  assign CRASH_N = A1a;

endmodule

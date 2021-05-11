/*
 * Rockets control and display
 */
module rockets(
  input  logic CLK_DRV,
  input  logic CLOCK_N,
  input  logic UP1_N, DOWN1_N,
  input  logic UP2_N, DOWN2_N,
  input  logic GAME_ON,
  input  logic CRASH_1_N, CRASH_2_N,
  input  logic _1H, _2H, _4H, _8H, _16H, _32H, _64H, _128H, _256H, _256H_N,
  input  logic HSYNC_N, VBLANK, VBLANK_N, VRESET_N,
  input  logic R_RESET, R_BBOUND,
  output logic ROCKETS_N,
  output logic SCORE_1, SCORE_2,
  output logic ROCKET_1, ROCKET_2,
  output logic SR1, SR2
);
  // Internal nets
  logic STOP_1, STOP_2;
  logic QA1, QB1, QC1, QD1;
  logic QA2, QB2, QC2, QD2;
  logic ROCKET_WINDOW;

  // ---------------------------------------------------------------------------
  // Rocket 1: y-pos counter
  // ---------------------------------------------------------------------------
  // # Basics
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // A 8-bit counter formed by J3 and H3 determines the y-pos of Rocket 1.
  // It counts up on each valid veritical video line (not on VBLANK).
  //
  // While H3 (upper 4 bits) is outputting a carry, ROCKET_WINDOW is enabled,
  // which means that Rocket 1 will be displayed on count from 240 to 255.
  //
  // On the period, J3 (lower 4 bits) will be used as y-index counter of
  // rocket pixel image.
  //
  // # When no input is applied
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // The counter counts from 10 to 255 (total 246).
  //
  // 246 is the same count as valid vertical video lines (262 - 16(VBLANK)),
  // so the counter is synced with vertical video counter.
  //
  // Therefore, Rocket 1 will stay on the same y-position.
  //
  // # When UP input is applied
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // The counter counts from 11 to 255 (total 245) only one less than
  // valid vertical video lines.
  //
  // Therefore, Rocket 1 will move forward.
  //
  // # When DOWN input is applied
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // The counter counts from 9 to 255 (total 247) only one more than
  // valid vertical video lines.
  //
  // Therefore, Rocket 1 will move backward.
  //
  // Rocket 1 cannot move backward even with DOWN input applied
  // when STOP_1 is asserted.
  //
  logic F3c, E3c, J2a, J2b, J2d, J2c;
  logic J3_RCO, H3_RCO;

  DM9316 DM9316_J3(
    .CLK_DRV,
    .CLK(HSYNC_N), .CLR_N(J2d), .LOAD_N(J2c), .ENP(1'b1), .ENT(VBLANK_N),
    .A(J2a), .B(E3c), .C(1'b0), .D(1'b1),
    .QA(QA1), .QB(QB1), .QC(QC1), .QD(QD1),
    .RCO(J3_RCO)
  );

  DM9316 DM9316_H3(
    .CLK_DRV,
    .CLK(HSYNC_N), .CLR_N(J2d), .LOAD_N(J2c), .ENP(J3_RCO), .ENT(1'b1),
    .A(1'b0), .B(1'b0), .C(1'b0), .D(1'b0),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(H3_RCO)
  );

  assign F3c = ~STOP_1 & ~DOWN1_N;
  assign E3c = ~F3c;
  assign J2a = ~E3c | ~UP1_N;
  assign J2b = ~CRASH_1_N | ~GAME_ON;
  assign J2d = ~(J2b & R_RESET);
  assign J2c = ~(J3_RCO & H3_RCO);

  assign ROCKET_1 = H3_RCO;
  assign SR1 = J2b;

  // ---------------------------------------------------------------------------
  // Rocket 1: score and stop
  // ---------------------------------------------------------------------------
  // SCORE_1 is asserted when Rocket 1 reaches the top of the screen.
  //
  // STOP_1 is asserted when Rocket 1 reaches R_BBOUND(vertical video count 248)
  // or SCORE_1 is asserted.
  //
  // That is to say, Rocket 1 cannot move backward behind R_BBOUND.
  // And Rocket 1 cannot move backward once it reaches the top of the screen.
  //
  logic D3d, H2b_Q_N, H2a_Q_N;

  // On schematics, CLK of H2b is VBLANK but VBLANK_N can be used as well.
  // And it is reasonable since VBLANK_N is used as CLK on K2b(Rocket 2).
  // A negative bar may be missing on schematics?
  SN7474 SN7474_H2b(
    .CLK_DRV,
    .CLK(VBLANK_N),
    .PRE_N(1'b1), .CLR_N(1'b1),
    .D(H3_RCO),
    .Q(), .Q_N(H2b_Q_N)
  );

  SN7474 SN7474_H2a(
    .CLK_DRV,
    .CLK(R_BBOUND),
    .PRE_N(1'b1), .CLR_N(1'b1),
    .D(H3_RCO),
    .Q(), .Q_N(H2a_Q_N)
  );

  assign D3d = ~H2b_Q_N | ~H2a_Q_N;
  assign SCORE_1 = H2b_Q_N;
  assign STOP_1  = D3d;

  // ---------------------------------------------------------------------------
  // Rocket 2: y-pos counter
  // ---------------------------------------------------------------------------
  // A 8-bit counter formed by L3 and K3 determines the Y-pos of Rocket 2.
  // The rest of the description is the same as for Rocket 1.
  //
  logic F3d, E3b, L2a, L2b, L2d, L2c;
  logic L3_RCO, K3_RCO;

  DM9316 DM9316_L3(
    .CLK_DRV,
    .CLK(HSYNC_N), .CLR_N(L2d), .LOAD_N(L2c), .ENP(1'b1), .ENT(VBLANK_N),
    .A(L2a), .B(E3b), .C(1'b0), .D(1'b1),
    .QA(QA2), .QB(QB2), .QC(QC2), .QD(QD2),
    .RCO(L3_RCO)
  );

  DM9316 DM9316_K3(
    .CLK_DRV,
    .CLK(HSYNC_N), .CLR_N(L2d), .LOAD_N(L2c), .ENP(L3_RCO), .ENT(1'b1),
    .A(1'b0), .B(1'b0), .C(1'b0), .D(1'b0),
    .QA(), .QB(), .QC(), .QD(),
    .RCO(K3_RCO)
  );

  assign F3d = ~STOP_2 & ~DOWN2_N;
  assign E3b = ~F3d;
  assign L2a = ~E3b | ~UP2_N;
  assign L2b = ~CRASH_2_N | ~GAME_ON;
  assign L2d = ~(L2b & R_RESET);
  assign L2c = ~(L3_RCO & K3_RCO);

  assign ROCKET_2 = K3_RCO;
  assign SR2 = L2b;

  // ---------------------------------------------------------------------------
  // Rocket 2: score and stop
  // ---------------------------------------------------------------------------
  // Description is the same as for Rocket 1.
  //
  logic B1c, K2b_Q_N, K2a_Q_N;

  SN7474 SN7474_K2b(
    .CLK_DRV,
    .CLK(VBLANK_N),
    .PRE_N(1'b1), .CLR_N(1'b1),
    .D(K3_RCO),
    .Q(), .Q_N(K2b_Q_N)
  );

  SN7474 SN7474_K2a(
    .CLK_DRV,
    .CLK(R_BBOUND),
    .PRE_N(1'b1), .CLR_N(1'b1),
    .D(K3_RCO),
    .Q(), .Q_N(K2a_Q_N)
  );

  assign B1c = ~K2b_Q_N | ~K2a_Q_N;
  assign SCORE_2 = K2b_Q_N;
  assign STOP_2  = B1c;

  // ---------------------------------------------------------------------------
  // Rocket window
  // ---------------------------------------------------------------------------
  // ROCKET_WINDOW determines where rockets will be displayed on the screen.
  //
  // Horizontal position is fixed.
  //   Rocket 1: horizontal video count from 192 to 207 (16 px width)
  //   Rocket 2: horizontal video count from 304 to 319 (16 px width)
  //
  // Vertical position is determined by y-pos counter as described above.
  //
  // While CRASH signal is asserted, the rocket will not be displayed.
  //
  logic K6a, K6c, J6b, J6a, C6a, C6b, D6c;

  assign K6a = ~(_32H & _16H & _256H);
  assign K6c = ~(_256H_N & _128H & _64H);
  assign J6b = ~_128H & ~_64H & ~K6a;
  assign J6a = ~_32H & ~_16H & ~K6c;
  assign C6a = ~(K3_RCO & J6b & CRASH_2_N & VRESET_N);
  assign C6b = ~(H3_RCO & J6a & CRASH_1_N & VRESET_N);
  assign D6c = ~C6a | ~C6b;

  // Add delay to ROCKET_WINDOW.
  // The delay is actually caused by ripple counter and gates in real hardware.
  // Without the delay, the edge of rocket wing will be chipped by one pixel.
  logic [5:0] ROCKET_WINDOW_DELAY;
  always_ff @(posedge CLK_DRV) begin
    ROCKET_WINDOW_DELAY <= {D6c, ROCKET_WINDOW_DELAY[5:1]};
  end
  assign ROCKET_WINDOW = ROCKET_WINDOW_DELAY[0];

  // ---------------------------------------------------------------------------
  // Rocket pixel image
  // ---------------------------------------------------------------------------
  // Rocket pixel image is constructed of diode matrix ROM.
  // Since it is symmetrical, only the left half is provided.
  //
  // H4 selects y-index counter for Rocket 1 and for Rocket 2.
  // K4 indicates which y-line of rocket pixel image will be displayed.
  // Note that the output of K4 is active low.
  // L5 selects x-line on the selected y-line.
  // The pixel on the (x, y) coordinates will be active if the selected x-line
  // is connected to the selected y-line(low level).
  // Otherwise the pixel will be inactive since x-line is pulled-up to high.
  //
  // Input select of L5 (= selected x-line) changes as follows on ROCKET_WINDOW.
  // 0, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 1, 0
  //
  logic H4_Y1, H4_Y2, H4_Y3, H4_Y4;
  logic y0, y1, y2, y3, y4, y5, y6, y7, y8, y9, yA, yB, yC, yD, yE, yF; // Rocket Y
  logic x0, x1, x2, x3, x4, x5, x6, x7; // Rocket X
  logic L5_Y_N;
  logic L6b, L6c, L6d;

  DM9322 DM9322_H4(
    .SELECT(_256H),
    .STROBE_N(1'b0),
    .A1(QA1), .A2(QB1), .A3(QC1), .A4(QD1),
    .B1(QA2), .B2(QB2), .B3(QC2), .B4(QD2),
    .Y1(H4_Y1), .Y2(H4_Y2), .Y3(H4_Y3), .Y4(H4_Y4)
  );

  DM9311 DM9311_K4(
    .G1_N(1'b1), .G2_N(1'b1),
    .A(H4_Y1), .B(H4_Y2), .C(H4_Y3), .D(H4_Y4),
    .D0_N(y0),  .D1_N(y1),  .D2_N(y2),  .D3_N(y3),
    .D4_N(y4),  .D5_N(y5),  .D6_N(y6),  .D7_N(y7),
    .D8_N(y8),  .D9_N(y9),  .D10_N(yA), .D11_N(yB),
    .D12_N(yC), .D13_N(yD), .D14_N(yE), .D15_N(yF)
  );

  // Diaode matrix ROM (wired AND logic connections)
  always_comb begin
    //   y0 & y1 & y2 & y3 & y4 & y5 & y6 & y7 & y8 & y9 & yA & yB & yC & yD & yE & yF;
    x0 =                                                                  yD;
    x1 =                                                             yC & yD;
    x2 =                                                        yB &      yD;
    x3 =                     y4 &                          yA &           yD & yE & yF;
    x4 =                y3 & y4 &                     y9 &                        & yF;
    x5 =           y2 &      y4 & y5 & y6 & y7 & y8 &                     yD & yE & yF;
    x6 =      y1 &                                                        yD;
    x7 = y0 &                                                             yD;
  end

  DM9312 DM9312_L5(
    .A(L6b), .B(L6c), .C(L6d),
    .D0(x0), .D1(x1), .D2(x2), .D3(x3),
    .D4(x4), .D5(x5), .D6(x6), .D7(x7),
    .G_N(1'b0),
    .Y(), .Y_N(L5_Y_N)
  );

  assign L6b = _1H ^ _8H;
  assign L6c = _2H ^ _8H;
  assign L6d = _4H ^ _8H;

  // ---------------------------------------------------------------------------
  // Final output
  // ---------------------------------------------------------------------------
  // The output is suppressed except on ROCKET_WINDOW.
  // Note that the output is captured at negative edge of clock.
  //
  logic C7a_Q_N;

  SN7474 SN7474_C7a(
    .CLK_DRV,
    .CLK(CLOCK_N),
    .PRE_N(1'b1), .CLR_N(ROCKET_WINDOW),
    .D(L5_Y_N),
    .Q(), .Q_N(C7a_Q_N)
  );

  assign ROCKETS_N = C7a_Q_N;

endmodule

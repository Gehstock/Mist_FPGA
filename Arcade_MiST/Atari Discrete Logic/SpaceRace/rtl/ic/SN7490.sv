/*
 * Synchronous version of SN7490 (ripple decade counter)
 * driven by faster clock than the original clock.
 * The origial clock is treated as data signal for edge detection.
 */
module SN7490(
  input   logic CLK_DRV,          // clock for synchronously drive
  input   logic CKA_N, CKB_N,     // clock negative edge
  input   logic R01, R02,         // reset to zero, positive asyncronous
  input   logic R91, R92,         // reset to nine, positive asyncronous
  output  logic QA, QB, QC, QD    // 4 bit counter output
);
  logic RESET_0_N, RESET_9_N, RESET_QB_QC_N;
  assign RESET_0_N = ~(R01 & R02);
  assign RESET_9_N = ~(R91 & R92);
  assign RESET_QB_QC_N = RESET_0_N & RESET_9_N;

  logic QD_N;

  // Internally chain of synchronous SN74107 J-K FF(Toggle mode) is used
  SN74107 QA_FF(.CLK_DRV, .CLK_N(CKA_N), .CLR_N(RESET_0_N),
                .J(1'b1), .K(1'b1), .Q(QA), .Q_N());

  SN74107 QB_FF(.CLK_DRV, .CLK_N(CKB_N), .CLR_N(RESET_QB_QC_N),
                .J(QD_N), .K(1'b1), .Q(QB), .Q_N());

  SN74107 QC_FF(.CLK_DRV, .CLK_N(QB), .CLR_N(RESET_QB_QC_N),
                .J(1'b1), .K(1'b1), .Q(QC), .Q_N());

  clocked_srff QD_FF(.CLK_DRV, .CLK_N(CKB_N),
                     .PRE_N(RESET_9_N), .CLR_N(RESET_0_N),
                     .S(QB & QC), .R(QD), .Q(QD), .Q_N(QD_N));
endmodule

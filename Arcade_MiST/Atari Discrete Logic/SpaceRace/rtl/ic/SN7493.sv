/*
 * Synchronous version of SN7493 (4-bit ripple binary counter)
 * driven by faster clock than the original clock.
 * The origial clock is treated as data signal for edge detection.
 */
module SN7493(
  input   logic CLK_DRV,        // clock for synchronously drive
  input   logic CKA_N, CKB_N,   // clock negative edge
  input   logic R0, R1,         // reset positive asyncronous
  output  logic QA, QB, QC, QD  // 4 bit counter output
);
  logic RESET_N;
  assign RESET_N = ~(R0 & R1);

  // Internally chain of synchronous SN74107 J-K FF(Toggle mode) is used
  SN74107 QA_FF(.CLK_DRV, .CLK_N(CKA_N), .CLR_N(RESET_N),
                .J(1'b1), .K(1'b1), .Q(QA), .Q_N());

  SN74107 QB_FF(.CLK_DRV, .CLK_N(CKB_N), .CLR_N(RESET_N),
                .J(1'b1), .K(1'b1), .Q(QB), .Q_N());

  SN74107 QC_FF(.CLK_DRV, .CLK_N(QB), .CLR_N(RESET_N),
                .J(1'b1), .K(1'b1), .Q(QC), .Q_N());

  SN74107 QD_FF(.CLK_DRV, .CLK_N(QC), .CLR_N(RESET_N),
                .J(1'b1), .K(1'b1), .Q(QD), .Q_N());

endmodule

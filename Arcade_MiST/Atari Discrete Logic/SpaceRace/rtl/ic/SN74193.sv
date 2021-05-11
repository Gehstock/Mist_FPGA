/*
 * Synchronous version of SN74193
 * (SYNCHRONOUS 4-BIT UP/DOWN BINARY COUNTERS (DUAL CLOCK WITH CLEAR))
 * driven by faster clock than the original clock.
 * The origial clock is treated as data signal for edge detection.
 */
 module SN74193(
  input   logic   CLK_DRV,        // clock for synchronously drive
  input   logic   UP, DOWN,       // up/down clock positive edge
  input   logic   CLR,            // clear positive asynchronous
  input   logic   LOAD_N,         // load negative asynchronous
  input   logic   A, B, C, D,     // load input
  output  logic   QA, QB, QC, QD, // 4 bit counter output
  output  logic   BO_N, CO_N      // borrow/carry out negative
);
  logic UP_N, DOWN_N, LOAD, CLR_N;
  assign UP_N   = ~UP;
  assign DOWN_N = ~DOWN;
  assign LOAD   = ~LOAD_N;
  assign CLR_N  = ~CLR;

  logic QA_CLK_N, QA_PRE_N, QA_CLR_N, QA_N;
  assign QA_CLK_N = DOWN_N | UP_N;
  assign QA_PRE_N = ~(A & LOAD & CLR_N);
  assign QA_CLR_N = CLR_N & ~(QA_PRE_N & LOAD);

  toggle_ff QA_FF(
    .CLK_DRV, .CLK_N(QA_CLK_N),
    .PRE_N(QA_PRE_N), .CLR_N(QA_CLR_N),
    .Q(QA), .Q_N(QA_N)
  );

  logic QB_CLK_N, QB_PRE_N, QB_CLR_N, QB_N;
  assign QB_CLK_N = (DOWN_N & QA_N) | (UP_N & QA);
  assign QB_PRE_N = ~(B & LOAD & CLR_N);
  assign QB_CLR_N = CLR_N & ~(QB_PRE_N & LOAD);

  toggle_ff QB_FF(
    .CLK_DRV, .CLK_N(QB_CLK_N),
    .PRE_N(QB_PRE_N), .CLR_N(QB_CLR_N),
    .Q(QB), .Q_N(QB_N)
  );

  logic QC_CLK_N, QC_PRE_N, QC_CLR_N, QC_N;
  assign QC_CLK_N = (DOWN_N & QA_N & QB_N) | (UP_N & QA & QB);
  assign QC_PRE_N = ~(C & LOAD & CLR_N);
  assign QC_CLR_N = CLR_N & ~(QC_PRE_N & LOAD);

  toggle_ff QC_FF(
    .CLK_DRV, .CLK_N(QC_CLK_N),
    .PRE_N(QC_PRE_N), .CLR_N(QC_CLR_N),
    .Q(QC), .Q_N(QC_N)
  );

  logic QD_CLK_N, QD_PRE_N, QD_CLR_N, QD_N;
  assign QD_CLK_N = (DOWN_N & QA_N & QB_N & QC_N) | (UP_N & QA & QB & QC);
  assign QD_PRE_N = ~(D & LOAD & CLR_N);
  assign QD_CLR_N = CLR_N & ~(QD_PRE_N & LOAD);

  toggle_ff QD_FF(
    .CLK_DRV, .CLK_N(QD_CLK_N),
    .PRE_N(QD_PRE_N), .CLR_N(QD_CLR_N),
    .Q(QD), .Q_N(QD_N)
  );

  assign BO_N = ~(DOWN_N & QA_N & QB_N & QC_N & QD_N);
  assign CO_N = ~(UP_N & QA & QB & QC & QD);

endmodule

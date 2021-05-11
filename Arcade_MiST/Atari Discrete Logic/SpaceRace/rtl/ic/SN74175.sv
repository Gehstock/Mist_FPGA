/*
 * Synchronous version of SN74175 (QUADRUPLE D-TYPE FLIP-FLOPS WITH CLEAR)
 * driven by faster clock than the original clock.
 * The origial clock is treated as data signal for edge detection.
 */
module SN74175(
  input   logic CLK_DRV,  // clock for synchronously drive
  input   logic CLK,      // clock positive edge
  input   logic CLR_N,    // clear negative asynchronous
  input   logic DA, DB, DC, DD,                           // D FF input
  output  logic QA, QA_N, QB, QB_N, QC, QC_N, QD, QD_N    // D FF output
);
  // Using four 7474s internally
  SN7474 SN7474_QA(
    .CLK_DRV,
    .CLK, .PRE_N(1'b1), .CLR_N,
    .D(DA),
    .Q(QA), .Q_N(QA_N)
  );

  SN7474 SN7474_QB(
    .CLK_DRV,
    .CLK, .PRE_N(1'b1), .CLR_N,
    .D(DB),
    .Q(QB), .Q_N(QB_N)
  );

  SN7474 SN7474_QC(
    .CLK_DRV,
    .CLK, .PRE_N(1'b1), .CLR_N,
    .D(DC),
    .Q(QC), .Q_N(QC_N)
  );

  SN7474 SN7474_QD(
    .CLK_DRV,
    .CLK, .PRE_N(1'b1), .CLR_N,
    .D(DD),
    .Q(QD), .Q_N(QD_N)
  );


endmodule

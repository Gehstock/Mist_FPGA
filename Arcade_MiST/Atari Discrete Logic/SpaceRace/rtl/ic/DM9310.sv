/*
 * Synchronous version of DM9310[SN74160] (synchronous decade counters)
 * driven by faster clock than the original clock.
 * The origial clock is treated as data signal for edge detection.
 */
module DM9310(
  input   logic   CLK_DRV,        // clock for synchronously drive
  input   logic   CLK,            // clock positive edge
  input   logic   CLR_N,          // clear negative asynchronous
  input   logic   LOAD_N,         // load negative synchronous
  input   logic   ENP, ENT,       // count enable
  input   logic   A, B, C, D,     // load input
  output  logic   QA, QB, QC, QD, // 4 bit counter output
  output  logic   RCO             // ripple carry output
);
  logic QA_J, QA_K, QB_J, QB_K, QC_J, QC_K, QD_J, QD_K;
  logic QA_EN, QB_EN, QC_EN, QD_EN;
  logic QA_N, QB_N, QC_N, QD_N;

  assign QA_EN = ENP & ENT;
  always_comb begin
    if (!LOAD_N)
      {QA_J, QA_K} = {A, ~A};
    else if (QA_EN)
      {QA_J, QA_K} = 2'b11;
    else
      {QA_J, QA_K} = 2'b00;
  end
  SN74107 QA_FF(.CLK_DRV(CLK_DRV), .CLK_N(~CLK), .CLR_N(CLR_N),
                .J(QA_J), .K(QA_K), .Q(QA), .Q_N(QA_N));

  assign QB_EN = ENP & ENT & QA & ~QD;
  always_comb begin
    if (!LOAD_N)
      {QB_J, QB_K} = {B, ~B};
    else if (QB_EN)
      {QB_J, QB_K} = 2'b11;
    else
      {QB_J, QB_K} = 2'b00;
  end
  SN74107 QB_FF(.CLK_DRV(CLK_DRV), .CLK_N(~CLK), .CLR_N(CLR_N),
                .J(QB_J), .K(QB_K), .Q(QB), .Q_N(QB_N));

  assign QC_EN = ENP & ENT & QA & QB;
  always_comb begin
    if (!LOAD_N)
      {QC_J, QC_K} = {C, ~C};
    else if (QC_EN)
      {QC_J, QC_K} = 2'b11;
    else
      {QC_J, QC_K} = 2'b00;
  end
  SN74107 QC_FF(.CLK_DRV(CLK_DRV), .CLK_N(~CLK), .CLR_N(CLR_N),
                .J(QC_J), .K(QC_K), .Q(QC), .Q_N(QC_N));

  assign QD_EN = ENP & ENT & ((QA & QB & QC) | (QA & ~QB & ~QC & QD));
  always_comb begin
    if (!LOAD_N)
      {QD_J, QD_K} = {D, ~D};
    else if (QD_EN)
      {QD_J, QD_K} = 2'b11;
    else
      {QD_J, QD_K} = 2'b00;
  end
  SN74107 QD_FF(.CLK_DRV(CLK_DRV), .CLK_N(~CLK), .CLR_N(CLR_N),
                .J(QD_J), .K(QD_K), .Q(QD), .Q_N(QD_N));

  assign RCO = ~(QA_N | QB | QC | QD_N | ~ENT);

endmodule

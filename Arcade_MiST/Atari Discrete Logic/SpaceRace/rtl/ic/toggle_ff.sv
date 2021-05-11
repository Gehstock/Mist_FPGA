/*
 * Synchronous version of T-FF with preset and clear
 * driven by fast enough clock.
 */
 module toggle_ff(
  input   logic   CLK_DRV,
  input   logic   CLK_N,
  input   logic   PRE_N, CLR_N,
  output  logic   Q, Q_N
);
  logic PREV_Q, CLK_Q;
  logic FALL; // CLK_N falling edge

  assign Q_N = ~Q;
  assign FALL = ~CLK_N & CLK_Q;

  always_ff @(posedge CLK_DRV) begin
    PREV_Q <= Q;
    if (!PRE_N | !CLR_N) CLK_Q <= 1'b0;
    else CLK_Q <= CLK_N;
  end

  always_comb begin
    if (PRE_N == 1'b0)
      Q = 1'b1;
    else if (CLR_N == 1'b0)
      Q = 1'b0;
    else if (FALL == 1'b0)
      Q = PREV_Q;
    else
      Q = ~PREV_Q;
  end
endmodule

/*
 * Synchronous version of clocked SR-FF with preset and clear
 * driven by fast enough clock.
 * S=1, R=1 input (not allowed) is treated as holding previous Q value
 */
module clocked_srff(
  input   logic   CLK_DRV,
  input   logic   CLK_N,
  input   logic   PRE_N, CLR_N,
  input   logic   S, R,
  output  logic   Q, Q_N
);
  logic S_Q, R_Q, PREV_Q, CLK_Q;
  logic FALL; // CLK_N falling edge

  assign Q_N = ~Q;
  assign FALL = ~CLK_N & CLK_Q;

  always_ff @(posedge CLK_DRV) begin
    S_Q <= S;
    R_Q <= R;
    PREV_Q <= Q;
    if (!PRE_N | !CLR_N) CLK_Q <= 1'b1;
    else CLK_Q <= CLK_N;
  end

  always_comb begin
    if (PRE_N == 1'b0)
      Q = 1'b1;
    else if (CLR_N == 1'b0)
      Q = 1'b0;
    else if (FALL == 1'b0)
      Q = PREV_Q;
    else begin
      unique case ({S_Q, R_Q})
        2'b00: Q = PREV_Q;
        2'b01: Q = 1'b0;
        2'b10: Q = 1'b1;
        2'b11: Q = PREV_Q;
      endcase
    end
  end

endmodule

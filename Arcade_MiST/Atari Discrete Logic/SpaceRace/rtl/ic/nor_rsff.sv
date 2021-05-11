/*
 * Synchronous version of RS-FF constructed from loops of SN7402 NOR
 * driven by fast enough clock.
 * R=1, S=1 input (not allowed) is treated as holding previous Q value
 */
module nor_rsff(
  input   logic  CLK_DRV,
  input   logic  R, S,
  output  logic  Q, Q_N
);
  logic dq;

  always_ff @(posedge CLK_DRV) begin
    dq <= Q;
  end

  assign Q_N = ~Q;
  assign Q = (R ^ S) ? (~R & S) : dq;

endmodule

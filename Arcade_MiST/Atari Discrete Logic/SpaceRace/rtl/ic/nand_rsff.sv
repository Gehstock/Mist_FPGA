/*
 * Synchronous version of RS-FF constructed from loops of SN7400 NAND
 * driven by fast enough clock.
 * R_N=0, S_N=0 input (not allowed) is treated as holding previous Q value
 */
module nand_rsff(
  input   logic  CLK_DRV,
  input   logic  S_N, R_N,
  output  logic  Q, Q_N
);
  logic dq;

  always_ff @(posedge CLK_DRV) begin
    dq <= Q;
  end

  assign Q_N = ~Q;
  assign Q = (S_N ^ R_N) ? (~S_N & R_N) : dq;

endmodule

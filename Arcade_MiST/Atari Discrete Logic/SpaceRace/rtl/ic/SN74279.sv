/*
 * Synchronous version of SN74279 (S_N-R_N LATCH)
 * driven by faster clock than the original clock.
 * R_N=0, S_N=0 input (not allowed) is treated as holding previous Q value.
 */
module SN74279(
  input   logic CLK_DRV,  // clock for synchronously drive
  input   logic S_N, R_N, // set/reset negative
  output  logic Q
);
  // Using nand rsff
  nand_rsff nand_rsff(
    .CLK_DRV,
    .S_N, .R_N,
    .Q, .Q_N()
  );

endmodule

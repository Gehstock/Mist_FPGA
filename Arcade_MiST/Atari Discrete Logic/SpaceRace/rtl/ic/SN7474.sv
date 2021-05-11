/*
 * Synchronous version of SN7474 (D-FF with PRESET and CLEAR)
 * driven by faster clock than the original clock.
 * The origial clock is treated as data signal for edge detection.
 */
module SN7474(
  input   logic CLK_DRV,  // clock for synchronously drive
  input   logic CLK,      // clock positive edge
  input   logic PRE_N,    // preset negative asynchronous
  input   logic CLR_N,    // clear negative asynchronous
  input   logic D,        // D FF input
  output  logic Q, Q_N    // D FF output
);
  logic D_Q, PREV_Q, CLK_Q;
  logic RISE; // CLK rising edge

  assign Q_N = ~Q;
  assign RISE = CLK & ~CLK_Q;

  always_ff @(posedge CLK_DRV) begin
    D_Q <= D;
    PREV_Q <= Q;
    if (!PRE_N | !CLR_N) CLK_Q <= 1'b1;
    else CLK_Q <= CLK;
  end

  always_comb begin
    if (PRE_N == 1'b0)
      Q = 1'b1;
    else if (CLR_N == 1'b0)
      Q = 1'b0;
    else if (RISE == 1'b0)
      Q = PREV_Q;
    else
      Q = D_Q;
  end

endmodule

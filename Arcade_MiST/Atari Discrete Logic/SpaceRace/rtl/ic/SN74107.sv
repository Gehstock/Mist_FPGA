/*
 * Synchronous version of SN74107 (J-K FF with CLEAR)
 * driven by faster clock than the original clock.
 * The origial clock is treated as data signal for edge detection.
 */
module SN74107(
  input   logic CLK_DRV,  // clock for synchronously drive
  input   logic CLK_N,    // clock negative edge
  input   logic CLR_N,    // clear negative asyncronous
  input   logic J, K,     // J-K FF input
  output  logic Q, Q_N    // J-K FF output
);
  logic J_Q, K_Q, PREV_Q, CLK_Q;
  logic FALL; // CLK_N falling edge

  assign Q_N = ~Q;
  assign FALL = ~CLK_N & CLK_Q;

  always_ff @(posedge CLK_DRV) begin
    J_Q <= J;
    K_Q <= K;
    PREV_Q <= Q;
    if (!CLR_N) CLK_Q <= 1'b0;
    else CLK_Q <= CLK_N;
  end

  always_comb begin
    if (CLR_N == 1'b0)
      Q = 1'b0;
    else if (FALL == 1'b0)
      Q = PREV_Q;
    else begin
      unique case ({J_Q, K_Q})
        2'b00: Q = PREV_Q;
        2'b10: Q = 1'b1;
        2'b01: Q = 1'b0;
        2'b11: Q = ~PREV_Q;
      endcase
    end
  end

endmodule

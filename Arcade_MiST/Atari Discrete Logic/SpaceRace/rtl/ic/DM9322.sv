/*
 * DM9322 (Quad 2-Line to 1-LineData Selectors Multiplexers)
 */
module DM9322(
  // pin       1
  input  logic SELECT,         // Select input
  // pin       15
  input  logic STROBE_N,       // Strobe negative
  // pin       2   5   11  14
  input  logic A1, A2, A3, A4, // Input A
  // pin       3   6   10  13
  input  logic B1, B2, B3, B4, // Input B
  // pin       4   7   9   12
  output logic Y1, Y2, Y3, Y4  // Output
);

  always_comb begin
    if (STROBE_N)
      {Y4, Y3, Y2, Y1} = 4'd0;
    else if (SELECT)
      {Y4, Y3, Y2, Y1} = {B4, B3, B2, B1};
    else
      {Y4, Y3, Y2, Y1} = {A4, A3, A2, A1};
  end

endmodule

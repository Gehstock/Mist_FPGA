/*
 * SN7448 (bcd-to-seven-segment decoders/drivers)
 */
module SN7448(
  inout   logic BI_RBO_N,               // blanking input or ripple-blanking output
  input   logic RBI_N,                  // ripple-blanking input
  input   logic LT_N,                   // lamp-test input
  input   logic A, B, C, D,             // inputs
  output  logic a, b, c, d, e, f, g     // outputs
);
  // Set BI_RBO_N_AS_INPUT = 1'b0 to use BI_RBO_N pin as ripple-blanking output (RBO_N).
  // By default, BI_RBO_N pin is blanking input.
  //
  // Note:
  // Original BI_RBO_N pin is bi-directional pin implemented by wired AND logic.
  // Because it cannot be implemented in FPGA,
  // optional parameter and tri-state buffer are used to determine the pin direction.
  parameter logic BI_RBO_N_AS_INPUT = 1'b1;

  logic BLANKING_N, BLANKING_AND_N;
  assign BLANKING_N = ~(LT_N & ~RBI_N & ~A & ~B & ~C & ~D);
  assign BLANKING_AND_N = BLANKING_N & BI_RBO_N;
  assign BI_RBO_N = BI_RBO_N_AS_INPUT ? 1'bz : BLANKING_N; // Tri-state buffer

  always_comb begin
    if (!LT_N)
      {a, b, c, d, e, f, g} = 7'b1111111;
    else if (!BLANKING_AND_N)
      {a, b, c, d, e, f, g} = 7'b0000000;
    else begin
        unique case ({D, C, B, A})
          4'b0000: {a, b, c, d, e, f, g} = 7'b1111110; // 0
          4'b0001: {a, b, c, d, e, f, g} = 7'b0110000; // 1
          4'b0010: {a, b, c, d, e, f, g} = 7'b1101101; // 2
          4'b0011: {a, b, c, d, e, f, g} = 7'b1111001; // 3
          4'b0100: {a, b, c, d, e, f, g} = 7'b0110011; // 4
          4'b0101: {a, b, c, d, e, f, g} = 7'b1011011; // 5
          4'b0110: {a, b, c, d, e, f, g} = 7'b0011111; // 6
          4'b0111: {a, b, c, d, e, f, g} = 7'b1110000; // 7
          4'b1000: {a, b, c, d, e, f, g} = 7'b1111111; // 8
          4'b1001: {a, b, c, d, e, f, g} = 7'b1110011; // 9
          4'b1010: {a, b, c, d, e, f, g} = 7'b0001101; // -
          4'b1011: {a, b, c, d, e, f, g} = 7'b0011001; // -
          4'b1100: {a, b, c, d, e, f, g} = 7'b0100011; // -
          4'b1101: {a, b, c, d, e, f, g} = 7'b1001011; // -
          4'b1110: {a, b, c, d, e, f, g} = 7'b0001111; // -
          4'b1111: {a, b, c, d, e, f, g} = 7'b0000000; // -
      endcase
    end
  end

endmodule

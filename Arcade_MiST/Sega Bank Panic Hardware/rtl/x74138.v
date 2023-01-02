
module x74138(
  input G1,
  input G2A,
  input G2B,
  input [2:0] A,
  output reg [7:0] Y
);

always @*
  if (~G2B & ~G2A & G1) Y = ~(1<<A);
  else Y = 8'b11111111;

endmodule

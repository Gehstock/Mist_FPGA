/*
 * SN7483 (4-bit binary full adder with fast carry)
 */
module SN7483(
  input   logic   A1, A2, A3, A4, // input A
  input   logic   B1, B2, B3, B4, // input B
  input   logic   C0,             // carry input
  output  logic   S1, S2, S3, S4, // sum output
  output  logic   C4              // carry output
);
  assign {C4, S4, S3, S2, S1} = {A4, A3, A2, A1} + {B4, B3, B2, B1} + C0;

endmodule
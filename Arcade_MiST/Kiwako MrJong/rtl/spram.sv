
module spram(
  input clock,
  input [8:0] address_a,
  input [6:0] address_b,
  input [7:0] data_a,
  output reg [7:0] q_a,
  output reg [31:0] q_b,
  input wren_a,
  input rden_a
);


reg [3:0][7:0] mem[127:0];


always @(posedge clock) begin
  if (wren_a) mem[address_a/4][address_a%4] <= data_a;
  if (rden_a) q_a <= mem[address_a/4][address_a%4];
  q_b <= mem[address_b];
end

endmodule

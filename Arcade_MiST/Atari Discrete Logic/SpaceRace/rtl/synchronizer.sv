/*
 * Synchronizer (Intel/Altera)
 */
module synchronizer #(
  parameter WIDTH = 1
) (
  input   logic              clk,
  input   logic [WIDTH-1:0]  in,
  output  logic [WIDTH-1:0]  out
);
  (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) logic [WIDTH-1:0] q1;
  (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) logic [WIDTH-1:0] q2;

  always @(posedge clk) begin
    q1 <= in;
    q2 <= q1;
  end

  assign out = q2;

endmodule

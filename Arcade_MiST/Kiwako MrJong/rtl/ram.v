
module ram
#(
  parameter addr_width=12,
  parameter data_width=8
)
(
  input clk,
  input [addr_width-1:0] addr,
  input [data_width-1:0] din,
  output [data_width-1:0] q,
  input wr_n
);

reg [data_width-1:0] data;
reg [data_width-1:0] mem[(1<<addr_width)-1:0];

assign q = data;

always @(posedge clk) begin

  data <= mem[addr];
  if (~wr_n) mem[addr] <= din;

end


endmodule

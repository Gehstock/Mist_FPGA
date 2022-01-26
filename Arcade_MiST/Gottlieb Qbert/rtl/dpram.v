
module dpram #(parameter addr_width=16, parameter data_width=8) (
  input clk,
  input [addr_width-1:0] addr,
  output [data_width-1:0] dout,
  input ce,
  input oe,

  input we,
  input [addr_width-1:0] waddr,
  input [data_width-1:0] wdata,
  output reg [data_width-1:0] doutb
);

reg [data_width-1:0] d;
reg [data_width-1:0] memory[(1<<addr_width)-1:0];

assign dout = ~ce & ~oe ? d : {data_width{1'b0}};

always @(posedge clk) begin
  if (we) memory[waddr] <= wdata;
  doutb <= memory[waddr];
  d <= memory[addr];
end

endmodule

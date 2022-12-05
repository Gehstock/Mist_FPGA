
module falling_edge(
  input clk_sys,
  input signal,
  output falling
);

assign falling = old & ~signal ? 1'b1 : 1'b0;

reg old;
always @(posedge clk_sys)
  old <= signal;

endmodule

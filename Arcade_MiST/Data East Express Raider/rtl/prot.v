
module prot(
  input clk_sys,
  input wr, // prot_data_write
  input [7:0] din,
  output [7:0] dout,
  output [7:0] status
);

wire wr_re;
reg [7:0] writes;
rising_edge rising_edge_wr(clk_sys, wr, wr_re);

assign dout = writes;
assign status = 2;

always @(posedge clk_sys) begin
  if (wr_re) begin
    if (din[7]) writes <= writes + 8'd1;
    if (din[4]) writes <= 8'd0;
  end
end

endmodule

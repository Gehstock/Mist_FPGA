
module clk_en #(
  parameter DIV=12,
  parameter OFFSET=0
)
(
  input ref_clk,
  output reg cen
);

reg [15:0] cnt = OFFSET;
always @(posedge ref_clk) begin
  if (cnt == DIV) begin
    cnt <= 16'd0;
    cen <= 1'b1;
  end
  else begin
    cen <= 1'b0;
    cnt <= cnt + 16'd1;
  end
end

endmodule

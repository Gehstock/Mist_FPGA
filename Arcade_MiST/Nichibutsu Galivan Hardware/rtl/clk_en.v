
module clk_en #(
  parameter DIV=12,
  parameter OFFSET=0
)
(
  input ref_clk,
  output reg cen,
  input [15:0] div,
  input [1:0] fdiv
);

reg [15:0] cnt = OFFSET;
wire [15:0] cmax = div << { fdiv, 1'b0 };

always @(posedge ref_clk) begin
  if (fdiv != 2'b11) begin
    if (cnt == cmax) begin
      cnt <= 16'd0;
      cen <= 1'b1;
    end
    else begin
      cen <= 1'b0;
      cnt <= cnt + 16'd1;
    end
  end
end

endmodule

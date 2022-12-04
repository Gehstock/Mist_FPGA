
module hvgen(
  input clk_sys,
  output reg hb, vb, hs, vs,
  output reg [8:0] hcount, vcount,
  output ce_pix
);

wire cen_6;
clk_en #(7) hclk_en(clk_sys, cen_6);
assign ce_pix = cen_6;

always @(posedge clk_sys) begin
  if (cen_6) begin
    hcount <= hcount + 9'd1;
    case (hcount)
      21: hb <= 1'b0;
      276: hb <= 1'b1;
      308: hs <= 1'b0;
      340: hs <= 1'b1;
      383: begin
        vcount <= vcount + 9'd1;
        hcount <= 9'b0;
        case (vcount)
          8: vb <= 1'b0;
          247: vb <= 1'b1;
          249: vs <= 1'b0;
          252: vs <= 1'b1;
          262: vcount <= 9'd0;
        endcase
      end
    endcase
  end
end


endmodule

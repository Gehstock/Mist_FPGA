
module hvgen(
  input clk_sys,
  output reg hb, vb, hs, vs,
  output reg [8:0] hcount, vcount,
  output reg ce_pix
);

wire cen_vid;
clk_en #(8-1) hclk_en(clk_sys, cen_vid);

// 256x240 - 384/264
always @(posedge clk_sys) begin
  ce_pix <= 1'b0;
  if (cen_vid) begin
    ce_pix <= 1'b1;
    hcount <= hcount + 9'd1;
    case (hcount)
      1: hb <= 1'b0;
      257: hb <= 1'b1;
      308: hs <= 1'b0;
      340: hs <= 1'b1;
      383: begin
        vcount <= vcount + 9'd1;
        hcount <= 9'b0;
        case (vcount)
          15: vb <= 1'b0;
          239: vb <= 1'b1;
          249: vs <= 1'b0;
          252: vs <= 1'b1;
          263: vcount <= 9'd0;
        endcase
      end
    endcase
  end
end


endmodule

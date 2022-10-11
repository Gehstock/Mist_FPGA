
module video(
  input clk,
  input ce_pix,
  output reg hs,
  output reg vs,
  output reg hb,
  output reg vb,
  output reg [8:0] hcount,
  output reg [8:0] vcount,
  output reg frame,
  input [3:0] hoffs,
  input [3:0] voffs
);

initial begin
  hs <= 1'b1;
  vs <= 1'b1;
end

always @(posedge clk) begin
  frame <= 1'b0;
  if (ce_pix) begin
    hcount <= hcount + 9'd1;
    case (hcount)
      16: hb <= 1'b0;
      271: hb <= 1'b1;
      (308 - $signed(hoffs)): hs <= 1'b0;
      (340 - $signed(hoffs)): hs <= 1'b1;
      383: begin
        vcount <= vcount + 9'd1;
        hcount <= 9'b0;
        case (vcount)
           15: vb <= 1'b0;
          239: vb <= 1'b1;
          (249 - $signed(voffs)) : vs <= 1'b0;
          (252 - $signed(voffs)) : vs <= 1'b1;
          262: vcount <= 9'd0;
        endcase
      end
    endcase
  end
end

endmodule

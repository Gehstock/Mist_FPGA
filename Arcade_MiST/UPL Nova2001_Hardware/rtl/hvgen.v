module hvgen
(
	input         CLK,
	input         PCLK_EN,
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input	 [11:0]		iRGB,
	output reg [11:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-9'd16;
assign VPOS = vcnt-9'd16;

always @(posedge CLK) begin
	if (PCLK_EN) begin
		case (hcnt)
			 15: begin HBLK <= 0; hcnt <= hcnt+1'd1; end
			271: begin HBLK <= 1; hcnt <= hcnt+1'd1; end
			311: begin HSYN <= 0; hcnt <= hcnt+1'd1; end
			342: begin HSYN <= 1; hcnt <= 471;    end
			511: begin hcnt <= 0;
				case (vcnt)
					 15: begin VBLK <= 0; vcnt <= vcnt+1'd1; end
					207: begin VBLK <= 1; vcnt <= vcnt+1'd1; end
					226: begin VSYN <= 0; vcnt <= vcnt+1'd1; end
					233: begin VSYN <= 1; vcnt <= 483;	  end
					511: begin vcnt <= 0; end
					default: vcnt <= vcnt+1'd1;
				endcase
			end
			default: hcnt <= hcnt+1'd1;
		endcase
		oRGB <= (HBLK|VBLK) ? 12'h0 : iRGB;
	end
end

endmodule 
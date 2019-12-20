module HVGEN
(
	output      [8:0] HPOS,
	output      [8:0] VPOS,
	input             CLK,
	input             PCLK_EN,
	input      [11:0] iRGB,

	output reg [11:0] oRGB,
	output reg        HBLK = 1,
	output reg        VBLK = 1,
	output reg        HSYN = 1,
	output reg        VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-9'd24;
assign VPOS = vcnt;

always @(posedge CLK) begin
	if (PCLK_EN) begin
			case (hcnt)
				 24: begin HBLK <= 0; hcnt <= hcnt+9'd1; end
				265: begin HBLK <= 1; hcnt <= hcnt+9'd1; end
				311: begin HSYN <= 0; hcnt <= hcnt+9'd1; end
				342: begin HSYN <= 1; hcnt <= 9'd471;    end
				511: begin hcnt <= 0;
							case (vcnt)
								223: begin VBLK <= 1; vcnt <= vcnt+9'd1; end
								226: begin VSYN <= 0; vcnt <= vcnt+9'd1; end
								233: begin VSYN <= 1; vcnt <= 9'd483;    end
								511: begin VBLK <= 0; vcnt <= 0; end
								default: vcnt <= vcnt+9'd1;
							endcase
						end
				default: hcnt <= hcnt+9'd1;
			endcase
		oRGB <= (HBLK|VBLK) ? 12'h0 : iRGB;
	end
end

endmodule

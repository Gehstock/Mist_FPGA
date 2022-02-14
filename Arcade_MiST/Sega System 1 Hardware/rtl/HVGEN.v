// Copyright (c) 2019 MiSTer-X

module HVGEN
(
	output  [8:0] HPOS,
	output  [8:0] VPOS,
	input         CLK,
	input         PCLK_EN,
	input  [11:0] iRGB,

	output reg [11:0]	oRGB,
	output reg        HBLK = 1,
	output reg        VBLK = 1,
	output reg        HSYN = 1,
	output reg        VSYN = 1,

	input             H240,

	input       [8:0] HOFFS,
	input       [8:0] VOFFS
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

wire [8:0] HS_B = 9'd462+(HOFFS*2'd2);
wire [8:0] HS_E =  9'd32+(HS_B);

wire [8:0] VS_B = 9'd226+(VOFFS*3'd4);
wire [8:0] VS_E =   9'd4+(VS_B);

always @(posedge CLK) begin
	if (PCLK_EN) begin
		hcnt <= hcnt + 1'd1;
		case (hcnt)
		 13: HBLK <= H240;
		 21: HBLK <= 0;
		261: HBLK <= H240;
		269: begin 
			hcnt <= 9'd462; // original: 0-255, 448-511 = 320, now: 0-269, 462-511 = 320
			HBLK <= 1;
			vcnt <= vcnt + 1'd1;
			case (vcnt)
				223: VBLK <= 1;
				255: vcnt <= 9'd505;
				511: VBLK <= 0;
				default: ;
			endcase
			end
		default: ;
		endcase

		if (hcnt==HS_B) begin HSYN <= 0; end
		if (hcnt==HS_E) begin HSYN <= 1; end

		if (vcnt==VS_B) begin VSYN <= 0; end
		if (vcnt==VS_E) begin VSYN <= 1; end

		oRGB <= (HBLK|VBLK) ? 12'h0 : iRGB;
	end
end

endmodule


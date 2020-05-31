// Copyright (c) 2020 MiSTer-X 

module PKWARS_HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	 [11:0]		iRGB,

	input   [8:0]		HOFFS,
	input	  [8:0]		VOFFS,

	output reg [11:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-5'd16;
assign VPOS = vcnt-5'd24;

wire [8:0] HS_B = 287+(HOFFS*2);
wire [8:0] HS_E =  31+(HS_B);
wire [8:0] HS_N = 447+(HOFFS*2);

wire [8:0] VS_B = 219+(VOFFS*4);
wire [8:0] VS_E =   7+(VS_B);
wire [8:0] VS_N = 478+(VOFFS*4);

always @(posedge PCLK) begin
	case (hcnt)
		 15: begin HBLK <= 0; hcnt <= hcnt+1'd1; end
		272: begin HBLK <= 1; hcnt <= hcnt+1'd1; end
		511: begin hcnt <= 0;
			case (vcnt)
				215: begin VBLK <= 1; vcnt <= vcnt+1'd1; end
				 23: begin VBLK <= 0; vcnt <= vcnt+1'd1; end
				default: vcnt <= vcnt+1'd1;
			endcase
		end
		default: hcnt <= hcnt+1'd1;
	endcase

	if (hcnt==HS_B) begin HSYN <= 0; end
	if (hcnt==HS_E) begin HSYN <= 1; hcnt <= HS_N; end

	if (vcnt==VS_B) begin VSYN <= 0; end
	if (vcnt==VS_E) begin VSYN <= 1; vcnt <= VS_N; end

	oRGB <= (HBLK|VBLK) ? 12'h0 : iRGB;
end

endmodule


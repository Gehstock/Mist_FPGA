module hvgen
(
	input					MCLK,
	input					PCLK_EN,
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	  [7:0]		iRGB,

	output reg [7:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-1'd1;
assign VPOS = vcnt;

always @(posedge MCLK) begin
	if (PCLK_EN) begin
		case (hcnt)
				0: begin HBLK <= 0; hcnt <= hcnt+1'd1; end
			337: begin HBLK <= 1; hcnt <= hcnt+1'd1; end
			352: begin HSYN <= 0; hcnt <= hcnt+1'd1; end
			416: begin HSYN <= 1; hcnt <= 481;    end
			511: begin hcnt <= 0;
				case (vcnt)
					239: begin VBLK <= 1; vcnt <= vcnt+1'd1; end
					248: begin VSYN <= 0; vcnt <= vcnt+1'd1; end
					259: begin VSYN <= 1; vcnt <= vcnt+1'd1; end
					262: begin VBLK <= 0; vcnt <= 0;      end
					default: vcnt <= vcnt+1'd1;
				endcase
			end
			default: hcnt <= hcnt+1'd1;
		endcase
		oRGB <= (HBLK|VBLK) ? 8'h0 : iRGB;
	end
end

endmodule

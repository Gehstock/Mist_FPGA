module hvgen
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

always @(posedge PCLK) begin
	case (hcnt)
		293: begin HBLK <= 1; HSYN <= 0; hcnt <= hcnt+1; end//289
		311: begin HSYN <= 1; hcnt <= hcnt+1; end
		383: begin
			HBLK <= 0; HSYN <= 1; hcnt <= 0;
			case (vcnt)
				225: begin VBLK <= 1; vcnt <= vcnt+1; end
				226: begin VSYN <= 0; vcnt <= vcnt+1; end
				233: begin VSYN <= 1; vcnt <= vcnt+1; end
				262: begin VBLK <= 0; vcnt <= 0; end//262
				default: vcnt <= vcnt+1;
			endcase
		end
		default: hcnt <= hcnt+1;
	endcase
end

endmodule

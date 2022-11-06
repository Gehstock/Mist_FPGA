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
		288: begin HBLK <= 1; hcnt <= hcnt+1'b1; end
		311: begin HSYN <= 0; hcnt <= hcnt+1'b1; end
		342: begin HSYN <= 1; hcnt <= 471;    end
		511: begin HBLK <= 0; hcnt <= 0;
			case (vcnt)
				223: begin VBLK <= 1; vcnt <= vcnt+1'b1; end
				226: begin VSYN <= 0; vcnt <= vcnt+1'b1; end
				233: begin VSYN <= 1; vcnt <= 483;	  end
				511: begin VBLK <= 0; vcnt <= 0;		  end
				default: vcnt <= vcnt+1'b1;
			endcase
		end
		default: hcnt <= hcnt+1'b1;
	endcase
end

endmodule

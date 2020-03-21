module hvgen
(
	input					MCLK,
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input					PCLK_EN,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

always @(posedge MCLK) begin
	if (PCLK_EN)
	case (hcnt)
		  1: begin HBLK <= 0; hcnt <= hcnt+1'd1; end
		290: begin HBLK <= 1; hcnt <= hcnt+1'd1; end
		311: begin HSYN <= 0; hcnt <= hcnt+1'd1; end
		342: begin HSYN <= 1; hcnt <= 9'd470;    end
		511: begin hcnt <= 0;
			case (vcnt)
				223: begin VBLK <= 1; vcnt <= vcnt+1'd1; end
				226: begin VSYN <= 0; vcnt <= vcnt+1'd1; end
				233: begin VSYN <= 1; vcnt <= 9'd483;	  end
				511: begin VBLK <= 0; vcnt <= 0;		  end
				default: vcnt <= vcnt+1'd1;
			endcase
		end
		default: hcnt <= hcnt+1'd1;
	endcase
end

endmodule 
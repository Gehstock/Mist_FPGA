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

localparam [8:0] VS_START = 9'd228,
                 VS_END   = VS_START+9'd3,
                 VB_START = 9'd223,
                 VB_END   = 9'd511;

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

always @(posedge MCLK) begin
	if (PCLK_EN)
	case (hcnt)
		  2: begin HBLK <= 0; hcnt <= hcnt+1'd1; end
		290: begin HBLK <= 1; hcnt <= hcnt+1'd1; end
		311: begin HSYN <= 0; hcnt <= hcnt+1'd1; end
		342: begin HSYN <= 1; hcnt <= 9'd470;    end
		511: begin hcnt <= 0;
			case (vcnt)
				VB_START: begin VBLK <= 1; vcnt <= vcnt+1'd1; end
				VS_START: begin VSYN <= 0; vcnt <= vcnt+1'd1; end
				VS_END:   begin VSYN <= 1; vcnt <= 9'd483;	 end
				VB_END:   begin VBLK <= 0; vcnt <= 0;		  end
				default: vcnt <= vcnt+1'd1;
			endcase
		end
		default: hcnt <= hcnt+1'd1;
	endcase
end

endmodule
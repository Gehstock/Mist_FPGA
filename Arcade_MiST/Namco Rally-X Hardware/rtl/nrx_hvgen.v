module nrx_hvgen
(
	input        CLK,
	output [8:0] HPOS,
	output [8:0] VPOS,
	input        PCLK_EN,
	output reg   HBLK = 1,
	output reg   VBLK = 1,
	output reg   HSYN = 1,
	output reg   VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

always @(posedge CLK) begin
	if (PCLK_EN) begin
	hcnt <= hcnt + 1'd1;
	case (hcnt)
		291: HBLK <= 1;
		300: HSYN <= 0;
		324: HSYN <= 1;
		383: begin
			hcnt <= 0;
			vcnt <= vcnt + 1'd1;
			case (vcnt)
				223: VBLK <= 1;
				228: VSYN <= 0;
				235: VSYN <= 1;
				242: begin VBLK <= 0; vcnt <= 0; end
				default: ;
			endcase
		end
		1: HBLK <= 0;
		default: ;
	endcase
	end
end

endmodule

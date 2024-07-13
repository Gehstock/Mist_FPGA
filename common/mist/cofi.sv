// Composite-like horizontal blending by Kitrinx

// AMR - disable shift register recognition
(* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *)
module cofi (
    input        clk,
    input        pix_ce,
    input        enable,

    input        hblank,
    input        vblank,
    input        hs,
    input        vs,
    input  [VIDEO_DEPTH-1:0] red,
    input  [VIDEO_DEPTH-1:0] green,
    input  [VIDEO_DEPTH-1:0] blue,

    output reg       hblank_out,
    output reg       vblank_out,
    output reg       hs_out,
    output reg       vs_out,
    output reg [VIDEO_DEPTH-1:0] red_out,
    output reg [VIDEO_DEPTH-1:0] green_out,
    output reg [VIDEO_DEPTH-1:0] blue_out,
    output reg       pix_ce_out
);

parameter VIDEO_DEPTH=8;

    function bit [VIDEO_DEPTH-1:0] color_blend (
        input [VIDEO_DEPTH-1:0] color_prev,
        input [VIDEO_DEPTH-1:0] color_curr,
        input blank_last
    );
    begin
        color_blend = blank_last ? color_curr : (color_prev >> 1) + (color_curr >> 1);
    end
    endfunction

reg [VIDEO_DEPTH-1:0] red_last;
reg [VIDEO_DEPTH-1:0] green_last;
reg [VIDEO_DEPTH-1:0] blue_last;

wire      ce = enable ? pix_ce : 1'b1;
always @(posedge clk) begin
	pix_ce_out <= 0;
	if (ce) begin
		hblank_out <= hblank;
		vblank_out <= vblank;
		vs_out     <= vs;
		hs_out     <= hs;
		pix_ce_out <= pix_ce;

		red_last   <= red;
		blue_last  <= blue;
		green_last <= green;

		red_out    <= enable ? color_blend(red_last,   red,   hblank_out) : red;
		blue_out   <= enable ? color_blend(blue_last,  blue,  hblank_out) : blue;
		green_out  <= enable ? color_blend(green_last, green, hblank_out) : green;
	end
end

endmodule

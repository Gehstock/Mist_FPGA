//============================================================================
// 
//  SystemVerilog implementation of the Konami 082 custom chip, used by
//  several Konami arcade PCBs to generate video timings
//  Copyright (C) 2020, 2021 Ace
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

//Chip pinout:
/*        _____________
        _|             |_
reset  |_|1          28|_| VCC
        _|             |_
h1     |_|2          27|_| GND
        _|             |_
h2     |_|3          26|_| v1
        _|             |_
h4     |_|4          25|_| v2
        _|             |_
h8     |_|5          24|_| v4
        _|             |_
h16    |_|6          23|_| v8
        _|             |_
h32    |_|7          22|_| v16
        _|             |_
h64    |_|8          21|_| v32
        _|             |_
h128   |_|9          20|_| v64
        _|             |_
n_h256 |_|10         19|_| v128
        _|             |_
h256   |_|11         18|_| n_vsync
        _|             |_
VCC    |_|12         17|_| sync
        _|             |_
clk    |_|13         16|_| vblk
        _|             |_
GND    |_|14         15|_| n_vblk
         |_____________|

Note: Pins 12 and 27 may control other features of the 082 - these, if any, have not
been modelled yet.
*/

module k082
(
	input       reset, //Active low
	input       clk,
	input       cen, //Set to 1 if using this code to replace a real 082
	input [3:0] h_center, v_center, //These inputs are additions for screen centering and don't exist on the actual 082
	output      n_vsync, sync,
	output      n_hsync, //Not exposed on the original chip
	output reg  vblk = 1,
	output      n_vblk,
	output reg  vblk_irq_en = 0, //This is an extra output not present on the real 082 to signal when to
	                             //trigger a VBlank IRQ (signal is active high)
	output      h1, h2, h4, h8, h16, h32, h64, h128, h256, n_h256,
	output      v1, v2, v4, v8, v16, v32, v64, v128
);

//The horizontal and vertical counters are 9 bits wide - delcare them here
reg [8:0] h_cnt = 9'd0;
reg [8:0] v_cnt = 9'd0;

//Define the range of values the vertical counter will count between based on the additional vertical center signal
//Shift the screen up by 1 line when horizontal centering shifts the screen left
wire [8:0] vcnt_start = 9'd248 - v_center;
wire [8:0] vcnt_end = 9'd511 - v_center;

//The horizontal and vertical counters behave as follows at every rising edge of the pixel clock:
//-Start at 0, then count to 511 (both counters increment by 1 when the horizontal counter is set to 48)
//-Horizontal counter resets to 128 for a total of 384 horizontal lines
//-Vertical counter resets to 248 for a total of 264 vertical lines (adjustable with added vertical center signal)
//-Vertical counter increments when the horizontal counter equals 176
//-VBlank is active when the horizontal counter is between 495 - 511 and 248 - 270
//Model this behavior here
always_ff @(posedge clk or negedge reset) begin
	if(!reset) begin
		h_cnt <= 9'd0;
		v_cnt <= 9'd0;
	end
	else if(cen) begin
		case(h_cnt)
			48: begin
				v_cnt <= v_cnt + 9'd1;
				h_cnt <= h_cnt + 9'd1;
			end
			176: begin
				h_cnt <= h_cnt + 9'd1;
				case(v_cnt)
					16: begin
						vblk <= 0;
						v_cnt <= v_cnt + 9'd1;
					end
					271: begin
						vblk <= 0;
						v_cnt <= v_cnt + 9'd1;
					end
					495: begin
						vblk <= 1;
						vblk_irq_en <= 1;
						v_cnt <= v_cnt + 9'd1;
					end
					vcnt_end: v_cnt <= vcnt_start;
					default: v_cnt <= v_cnt + 9'd1;
				endcase
			end
			177: begin
				vblk_irq_en <= 0;
				h_cnt <= h_cnt + 9'd1;
			end
			511: h_cnt <= 9'd128;
			default: h_cnt <= h_cnt + 9'd1;
		endcase
	end
end

//The Konami 082 has both an active low VBlank and an active high VBlank - generate the active low VBlank by inverting
//the active high VBlank generated in the previous sequential block
assign n_vblk = ~vblk;

//Generate active low HSync, VSync and composite sync
assign n_hsync = h_center[3] ? ~(h_cnt > (182 - h_center[2:0]) && h_cnt < (215 - h_center[2:0])):
                               ~(h_cnt > (175 - h_center[2:0]) && h_cnt < (208 - h_center[2:0]));
assign n_vsync = h_center[3] ? ~(v_cnt >= vcnt_start + 9'd1 && v_cnt <= vcnt_start + 9'd8) : ~(v_cnt >= vcnt_start && v_cnt <= vcnt_start + 9'd7);
assign sync = n_hsync ^ n_vsync;

//Assign the individual horizontal counter bits to their respective outputs (also invert bit 8 of the horizontal counter for H256)
assign h1 = h_cnt[0];
assign h2 = h_cnt[1];
assign h4 = h_cnt[2];
assign h8 = h_cnt[3];
assign h16 = h_cnt[4];
assign h32 = h_cnt[5];
assign h64 = h_cnt[6];
assign h128 = h_cnt[7];
assign h256 = ~h_cnt[8];
assign n_h256 = h_cnt[8];

//Assign the individual vertical counter bits to their respective outputs
assign v1 = v_cnt[0];
assign v2 = v_cnt[1];
assign v4 = v_cnt[2];
assign v8 = v_cnt[3];
assign v16 = v_cnt[4];
assign v32 = v_cnt[5];
assign v64 = v_cnt[6];
assign v128 = v_cnt[7];

endmodule

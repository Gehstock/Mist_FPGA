//============================================================================
// 
//  SystemVerilog implementation of the Konami 082 custom chip, used by
//  several Konami arcade PCBs to generate video timings
//  Copyright (C) 2020 Ace
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
VCC    |_|1          28|_| VCC
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

Note: Pins 1, 12 and 27 may control other features of the 082 - these, if any, have not
been modelled yet.
*/

module k082
(
	input      clk,
	output     n_vsync, sync,
	output     n_hsync, //Not exposed on the original chip
	output reg vblk = 1,
	output     n_vblk,
	output     h1, h2, h4, h8, h16, h32, h64, h128, h256, n_h256,
	output     v1, v2, v4, v8, v16, v32, v64, v128
);

reg [8:0] h_cnt = 9'd0;
reg [8:0] v_cnt = 9'd0;

always_ff @(posedge clk) begin
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
					v_cnt <= v_cnt + 9'd1;
				end
				511: v_cnt <= 9'd248;
				default: v_cnt <= v_cnt + 9'd1;
			endcase
		end
		511: h_cnt <= 9'd128;
		default: h_cnt <= h_cnt + 9'd1;
	endcase
end

assign n_vblk = ~vblk;
assign n_hsync = ~(h_cnt > 175 && h_cnt < 208);
assign n_vsync = v_cnt[8];
assign sync = n_hsync ^ n_vsync;

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

assign v1 = v_cnt[0];
assign v2 = v_cnt[1];
assign v4 = v_cnt[2];
assign v8 = v_cnt[3];
assign v16 = v_cnt[4];
assign v32 = v_cnt[5];
assign v64 = v_cnt[6];
assign v128 = v_cnt[7];

endmodule

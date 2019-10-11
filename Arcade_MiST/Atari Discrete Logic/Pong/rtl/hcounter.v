/*
  MIT License

  Copyright (c) 2019 Richard Eng

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

/*
  Pong - Horizontal Counter Circuit
  ---------------------------------
*/
`default_nettype none

module hcounter
(
  input wire clk7_159,
  output wire h1, h2, h4, h8, h16, h32, h64, h128, h256, _h256, hreset, _hreset
);

/*
wire f7_to_e7b;

ls93 f8(clk7_159, , hreset, hreset, h1, h2, h4, h8);
ls93 f9(h8, , hreset, hreset, h16, h32, h64, h128);
ls107 f6b(h128, _hreset, 1'b1, 1'b1, h256, _h256);
ls30 f7(h256, 1'b1, 1'b1, 1'b1, h4, h2, h128, h64, f7_to_e7b);
ls74 e7b(clk7_159, f7_to_e7b, 1'b1, 1'b1, _hreset, hreset);
*/

/* verilator lint_off UNOPTFLAT */
reg [8:0] hcnt;
/* verilator lint_on UNOPTFLAT */

initial hcnt = 9'd0;

assign { _h256, h256, h128, h64, h32, h16, h8, h4, h2, h1 } = { ~hcnt[8], hcnt[8], hcnt[7], hcnt[6], hcnt[5], hcnt[4], hcnt[3], hcnt[2], hcnt[1], hcnt[0] };

always @(negedge clk7_159 or posedge hreset) begin
    if (hreset)
        hcnt <= 9'd0;
    else
        hcnt <= hcnt + 1'b1;
end

reg rst;

initial rst = 1'b0;

always @(posedge clk7_159) begin
    rst <= (hcnt == 9'd454);
end

assign hreset = rst;
assign _hreset = ~hreset;

endmodule

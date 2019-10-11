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
  Pong - Vertical Counter Circuit
  -------------------------------
*/
`default_nettype none

module vcounter
(
  input wire hreset,
  output wire v1, v2, v4, v8, v16, v32, v64, v128, v256, _v256, vreset, _vreset
);

/*
wire d8c_to_e7a;

ls93 e8(hreset, , vreset, vreset, v1, v2, v4, v8);
ls93 e9(v8, , vreset, vreset, v16, v32, v64, v128);
ls107 d9b(v128, _vreset, 1'b1, 1'b1, v256, _v256);
ls10 d8c(v256, v4, v1, d8c_to_e7a);
ls74 e7a(hreset, d8c_to_e7a, 1'b1, 1'b1, _vreset, vreset);
*/

reg [8:0] vcnt;

initial vcnt = 9'd0;

assign { _v256, v256, v128, v64, v32, v16, v8, v4, v2, v1 } = { ~vcnt[8], vcnt[8], vcnt[7], vcnt[6], vcnt[5], vcnt[4], vcnt[3], vcnt[2], vcnt[1], vcnt[0] };

always @(negedge hreset or posedge vreset) begin
  if (vreset)
    vcnt <= 9'd0;
  else
    vcnt <= vcnt + 1'b1;
end

reg rst;
always @(posedge hreset) begin
  rst <= (vcnt == 9'd261);
end

assign vreset = rst;
assign _vreset = ~vreset;

endmodule

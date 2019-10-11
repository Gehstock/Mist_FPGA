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
  Pong - The Net Circuit
  ----------------------
*/
`default_nettype none

module net
(
    input wire  clk7_159, vblank, v4, h256, _h256,
    output wire net
);

wire unused, f3b_to_g3b, g3b_to_g2b;

ls107 f3b(clk7_159, 1'b1, h256, _h256, unused, f3b_to_g3b);
ls00 g3b(h256, f3b_to_g3b, g3b_to_g2b);
ls27 g2b(vblank, v4, g3b_to_g2b, net);

endmodule
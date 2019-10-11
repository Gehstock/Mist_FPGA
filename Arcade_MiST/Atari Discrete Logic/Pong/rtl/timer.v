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
  Pong - Single Shot Timer
  Simple emulation of an analogue 555 timer
  -----------------------------------------
*/
`default_nettype none

module timer
#(
	parameter CLK_FREQ 		= 0,
	parameter DURATION_MS 	= 0
)
(
    input wire  _clk, _trigger,
    output reg  out
);

localparam TIMEOUT = (CLK_FREQ / 1000) * DURATION_MS;

reg [31:0] counter;

initial counter = 32'd0;

always @(negedge _clk) begin
    if (counter > 0) begin
        counter <= counter - 32'd1;
        if (counter == 32'd1) begin
            out <= 1'b0;
        end
    end else if (counter == 32'd0 && !_trigger) begin
        counter <= TIMEOUT;
        out <= 1'b1;
    end
end

endmodule

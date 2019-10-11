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
  Pong - Paddle Circuit
  ---------------------
*/
`default_nettype none

module paddle
(
    input wire [7:0] paddle_vpos, input wire _hsync, _v256,
    output wire b, c, d, _vpad
);

wire b7b_c_out;
ls00 b7b_c(_hsync, a7a_b_out, b7b_c_out);

wire a8_9_qa, a8_9_qb, a8_9_qc, a8_9_qd;
ls93 a8_9(b7b_c_out, 1'b0, a9_b9_out, a9_b9_out, a8_9_qa, a8_9_qb, a8_9_qc, a8_9_qd);

wire a7a_b_out;
ls20 a7a_b(a8_9_qa, a8_9_qb, a8_9_qc, a8_9_qd, a7a_b_out);

wire a9_b9_out;

wire c9a_b_out;
ls04 c9a_b(a9_b9_out, c9a_b_out);

wire b7a_d_out;
ls00 b7a_d(c9a_b_out, a7a_b_out, b7a_d_out);

assign b = a8_9_qb;
assign c = a8_9_qc;
assign d = a8_9_qd;
assign _vpad = b7a_d_out;

assign a9_b9_out = trigger;

// Simulate 555 timer to position paddle vertical position
reg [8:0] counter;
reg trigger;

always @(negedge _hsync) begin
    if (counter > 9'd0) begin
        counter <= counter - 9'd1;
        if (counter == 9'd1) begin
            trigger <= 1'b0;
        end
    end else if (counter == 9'd0 && !_v256) begin
        // 22 full range
        // 38 limited (authentic)
        counter <= ( { 1'b0, paddle_vpos } + 9'd5 + 9'd16) < 9'd38 ? 9'd38 : 
				   ( { 1'b0, paddle_vpos } + 9'd5 + 9'd16) > 9'd261 ? 9'd261 :
				   ( { 1'b0, paddle_vpos } + 9'd5 + 9'd16); // 261-256=5 lines + 16 vblank lines
        trigger <= 1'b1;

    end
end

endmodule

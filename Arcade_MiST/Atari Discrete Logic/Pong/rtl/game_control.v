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
  Pong - Game Control Circuit
  ---------------------------
*/
`default_nettype none

module game_control
(
    input wire clk7_159, _miss, stop_g, pad1, coin_sw,
    output wire _srst, srst, rst_speed, attract, _attract, serve, _serve 
);

wire e6b_out;
ls00 e6b(_srst, _miss, e6b_out);
assign rst_speed = e6b_out;

wire e6a_out;
ls00 e6a(e6b_out, e6b_out, e6a_out);

wire f4_out;
timer #(7_159_000, 1700) f4(clk7_159, e6a_out, f4_out);

wire _run;
wire e5a_out;
ls27 e5a(_run, stop_g, f4_out, e5a_out);
assign _run = ~running;

ls74 b5b(pad1, e5a_out, e5a_out, 1'b1, _serve, serve);

ls02 d2a(stop_g, _run, _attract);
ls04 d1b(_attract, attract);

assign srst = coin_sw;
assign _srst = ~srst;

reg running, coin_sw_old, stop_g_old;

initial begin
  running = 1'b0;
  coin_sw_old = 1'b0;
  stop_g_old = 1'b0;
end

always @(negedge clk7_159) begin
    if (coin_sw_old == 1'b0 && coin_sw == 1'b1) begin
      running <= 1'b1;
    end else if (stop_g_old == 1'b0 && stop_g == 1'b1) begin
      running <= 1'b0;
    end
    coin_sw_old <= coin_sw;
    stop_g_old <= stop_g;
end

endmodule

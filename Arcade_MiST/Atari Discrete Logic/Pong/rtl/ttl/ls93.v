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
  74LS93
  ------
  4-Bit Ripple Counter
  
  Pinout
  ------
          _______
         |       |
   _cp1 -| 1  14 |- _cp0
    mr1 -| 2  13 |- NC
    mr2 -| 3  12 |- q0
     NC -| 4  11 |- q3
    VCC -| 5  10 |- GND
     NC -| 6   9 |- q1
     NC -| 7   8 |- q2
         |_______|
*/
`default_nettype none

module ls93
(
    input wire  _cp0, /* verilator lint_off UNUSED */ _cp1 /* verilator lint_on UNUSED */, mr1, mr2,
    output reg  q0, q1, q2, q3
);

wire mr;
assign mr = (mr1 & mr2);

always @(negedge _cp0 or posedge mr) begin
    if (mr == 1'b1) begin
        q0 <= 1'b0;
    end else begin
        q0 <= ~q0;
    end
end

always @(negedge q0 or posedge mr) begin
    if (mr == 1'b1) begin
        q1 <= 1'b0;
    end else begin
        q1 <= ~q1;
    end
end

always @(negedge q1 or posedge mr) begin
    if (mr == 1'b1) begin
        q2 <= 1'b0;
    end else begin
        q2 <= ~q2;
    end
end

always @(negedge q2 or posedge mr) begin
    if (mr == 1'b1) begin
        q3 <= 1'b0;
    end else begin
        q3 <= ~q3;
    end
end

endmodule

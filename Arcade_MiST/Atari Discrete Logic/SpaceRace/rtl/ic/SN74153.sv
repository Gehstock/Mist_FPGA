/*
 * SN74153 (dual 4-line TO 1-line data selectors/multiplexers)
 */
module SN74153(
  input   logic A, B,                   // select
  input   logic _1G_N, _2G_N,           // strobe (enable)
  input   logic _1C0, _1C1, _1C2, _1C3, // input 1
  input   logic _2C0, _2C1, _2C2, _2C3, // input 2
  output  logic _1Y, _2Y                // output
);
  always_comb begin
    if (_1G_N)
      _1Y = 1'b0;
    else
      unique case ({B, A})
        2'b00: _1Y = _1C0;
        2'b01: _1Y = _1C1;
        2'b10: _1Y = _1C2;
        2'b11: _1Y = _1C3;
      endcase
  end

  always_comb begin
    if (_2G_N)
      _2Y = 1'b0;
    else
      unique case ({B, A})
        2'b00: _2Y = _2C0;
        2'b01: _2Y = _2C1;
        2'b10: _2Y = _2C2;
        2'b11: _2Y = _2C3;
      endcase
  end

endmodule

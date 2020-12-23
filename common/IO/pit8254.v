
module pit8254(
  input [7:0] Di,
  output reg [7:0] Do,
  input RD,
  input WR,
  input CS,
  input A0,
  input A1,
  input clk0,
  input clk1,
  input clk2,
  input gate0,
  input gate1,
  input gate2,
  output out0,
  output out1,
  output out2
);

wire [1:0] addr = { A1, A0 };
wire sel = Di[7:6];
wire [7:0] dout0, dout1, dout2;
wire read = WR & ~RD;

always @(posedge read)
  case (sel)
    2'b00: Do <= dout0;
    2'b01: Do <= dout1;
    2'b10: Do <= dout2;
  endcase

counter c0(clk0, Di, dout0, RD, WR, gate0, addr == 2'b00, addr == 2'b11 && sel == 2'b00, out0);
counter c1(clk1, Di, dout1, RD, WR, gate1, addr == 2'b01, addr == 2'b11 && sel == 2'b01, out1);
counter c2(clk2, Di, dout2, RD, WR, gate2, addr == 2'b10, addr == 2'b11 && sel == 2'b10, out2);

endmodule


module counter(
  input clk,
  input [7:0] din,
  output reg [7:0] dout,
  input RD,
  input WR,
  input gate,
  input sel,
  input WR_CTRL,
  output reg out
);

reg [15:0] cnt = 0;
reg [15:0] latch, init;
reg [1:0] format;
reg [2:0] mode;
reg bcd;
reg [1:0] latched;
reg counting;
reg msb = 0;
reg [1:0] dec;
reg gate_latch;

reg [3:0] state;

parameter
  IDLE = 0,
  WRITE_CTRL = 1,
  START_COUNTER = 2,
  LATCH_COUNTER = 3,
  WRITE_COUNTER = 4,
  READ_COUNTER = 5;


always @*
  if (WR_CTRL & RD & ~WR)
    if (din[5:4] != 2'b00)
      state = WRITE_CTRL;
    else
      state = LATCH_COUNTER;
  else if (sel & ~RD & WR)
    state = READ_COUNTER;
  else if (sel & ~WR & RD)
    state = WRITE_COUNTER;
  else
    state = IDLE;

always @*
  if (state == WRITE_COUNTER) init = cnt;

always @(posedge clk)
  gate_latch <= gate;

always @(posedge clk) begin
  if (counting & cnt > 0) cnt <= cnt - { 14'd0, dec };
  casez (mode)
    3'b000: begin
      out <= cnt == 0;
      counting <= gate;
      dec <= 2'b1;
    end
    3'b001: begin
      dec <= 2'b1;
      if (gate & ~counting) begin
        counting <= 1'b1;
        cnt <= init;
      end
      if (gate_latch^gate && gate) begin
       cnt <= init;
      end
      out <= counting ? cnt == 0 : 1'b1;
    end
    3'b?10: begin
      dec <= 2'b1;
      if (~gate) begin
        counting <= 1'b0;
        cnt <= init;
        out <= 1'b1;
      end
      else begin
        counting <= 1'b1;
        out <= cnt == 1;
      end
      if (cnt == 1) cnt <= init;
    end
    3'b?11: begin
      dec <= 2'd2;
      if (~gate) begin
        counting <= 1'b0;
        cnt <= init*2;
        out <= 1'b1;
      end
      else begin
        counting <= 1'b1;
        out <= cnt > init;
      end
      if (cnt == 2) cnt <= init*2;
    end
    3'b100: begin
      dec <= 2'b1;
      out <= cnt == 0;
      counting <= gate;
      if (cnt == 0) cnt <= init;
    end
    3'b101: begin
      dec <= 2'b1;
      out <= cnt == 0;
      if (gate & ~counting) begin
        counting <= 1'b1;
        cnt <= init;
      end
      if (gate_latch^gate && gate) begin
       cnt <= init;
      end
      if (cnt == 0) cnt <= init;
    end
  endcase
  case (state)
    WRITE_CTRL: begin
      format <= din[5:4];
      mode <= din[3:1];
      bcd <= din[0];
      counting <= 1'b0;
      if (din[3:0] == 0) out <= 1'b0;
    end
    LATCH_COUNTER: begin
      latch <= cnt;
      latched <= 2'b11;
    end
    WRITE_COUNTER: begin
      case (format)
        2'b01: cnt[7:0] <= din;
        2'b10: cnt[15:8] <= din;
        2'b11:
          if (msb) begin
            cnt <= { din, cnt[7:0] };
            msb <= 1'b0;
          end
          else begin
            msb <= 1'b1;
            cnt <= { cnt[15:8], din };
          end
      endcase
    end
    READ_COUNTER:
      case (format)
        2'b01: begin
          dout <= latched ? latch[7:0] : cnt[7:0];
          latched[0] <= 1'b0;
        end
        2'b10: begin
          dout <= latched ? latch[15:8] : cnt[15:8];
          latched[1] <= 1'b0;
        end
        2'b11:
          if (msb) begin
            dout <= latched ? latch[15:8] : cnt[15:8];
            latched[1] <= 1'b0;
            msb <= 1'b0;
          end
          else begin
            dout <= latched ? latch[7:0] : cnt[7:0];
            latched[0] <= 1'b0;
            msb <= 1'b1;
          end
      endcase
  endcase
end


endmodule

module audio (
  input clk, // clk_sys

  input [9:0] CH1_freq,
  input [7:0] CH1_vduty,
  input [7:0] CH1_length,

  input [9:0] CH2_freq,
  input [7:0] CH2_vduty,
  input [7:0] CH2_length,

  input [7:0] DMA_addr,
  input [7:0] DMA_length,
  input [7:0] DMA_ctrl,
  input [7:0] DMA_trigger,

  input [7:0] noise_freq_vol,
  input [7:0] noise_length,
  input [7:0] noise_ctrl,

  output [3:0] CH1,
  output [3:0] CH2
);



reg [23:0] clk_cnt;
reg pulse;
reg clk_audio;
reg [15:0] prescaler;
reg prescaler_overflow;

// 50000/125=400/2=200  2^24/200=83886
always @(posedge clk)
  { pulse, clk_cnt } <= clk_cnt + 24'd83886;

always @(posedge pulse)
  clk_audio <= ~clk_audio;

always @(posedge clk)
  { prescaler_overflow, prescaler } <= prescaler + 16'd1;

reg [16:0] CH1_sum, CH2_sum;
reg [16:0] CH1_dc, CH2_dc; // duty cycle
reg CH1_sw, CH2_sw; // square wave
reg [7:0] CH1_dlength, CH2_dlength, CH1_timer, CH2_timer;

wire [3:0] CH1_out = CH1_sw ? CH1_vduty[3:0] : 4'd0;
wire [3:0] CH2_out = CH2_sw ? CH2_vduty[3:0] : 4'd0;
wire CH1_en = CH1_timer || CH1_vduty[6] ? 1'b1 : 1'b0;
wire CH2_en = CH2_timer || CH2_vduty[6] ? 1'b1 : 1'b0;
assign CH1 = CH1_en ? CH1_out : 4'd0;
assign CH2 = CH2_en ? CH2_out : 4'd0;

always @(posedge clk) begin
  if (prescaler_overflow && CH1_timer > 8'd0) CH1_timer <= CH1_timer - 8'd1;
  if (prescaler_overflow && CH2_timer > 8'd0) CH2_timer <= CH2_length - 8'd1;
  if (CH1_dlength != CH1_length) begin
    CH1_dlength <= CH1_length;
    CH1_timer <= CH1_length;
  end
  if (CH2_dlength != CH2_length) begin
    CH2_dlength <= CH2_length;
    CH2_timer <= CH2_length;
  end
end

always @*
  case (CH1_vduty[5:4])
    2'b00: CH1_dc = 17'd15240; // 12.5%
    2'b01: CH1_dc = 17'd31750; // 25%
    2'b10: CH1_dc = 17'd63500; // 50%
    2'b11: CH1_dc = 17'd95250; // 75%
  endcase

always @*
  case (CH2_vduty[5:4])
    2'b00: CH2_dc = 17'd15240; // 12.5%
    2'b01: CH2_dc = 17'd31750; // 25%
    2'b10: CH2_dc = 17'd63500; // 50%
    2'b11: CH2_dc = 17'd95250; // 75%
  endcase

always @(posedge clk_audio) begin
  CH1_sum <= CH1_sum + { 7'd0, CH1_freq };
  if (CH1_sum >= CH1_dc) begin
    CH1_sum <= 17'd0;
    CH1_sw = ~CH1_sw;
  end
end

always @(posedge clk_audio) begin
  CH2_sum <= CH2_sum + { 7'd0, CH2_freq };
  if (CH2_sum >= CH2_dc) begin
    CH2_sum <= 17'd0;
    CH2_sw = ~CH2_sw;
  end
end


endmodule 
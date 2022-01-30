
module sc01(
  input clk,
  input [5:0] PhCde,
  input [1:0] Pitch,
  input LatchCde,
  output reg [7:0] audio,
  output AR
);

// master clock freq 720KHz

assign AR = ~speaking;

reg speaking;
reg OldLatchSignal;
reg [19:0] sample_addr, addr;
reg [15:0] sample_size, size, length;
// reg [7:0] samples[695293:0];

// initial $readmemh("sc01.mem", samples);

always @*
  case (PhCde)
    6'd00: sample_addr = 20'd0;
    6'd01: sample_addr = 20'd10959;
    6'd02: sample_addr = 20'd21499;
    6'd05: sample_addr = 20'd33136;
    6'd06: sample_addr = 20'd45951;
    6'd07: sample_addr = 20'd58475;
    6'd08: sample_addr = 20'd67390;
    6'd09: sample_addr = 20'd77054;
    6'd10: sample_addr = 20'd86228;
    6'd11: sample_addr = 20'd96253;
    6'd12: sample_addr = 20'd107874;
    6'd13: sample_addr = 20'd114887;
    6'd14: sample_addr = 20'd121241;
    6'd15: sample_addr = 20'd127270;
    6'd16: sample_addr = 20'd134890;
    6'd17: sample_addr = 20'd145262;
    6'd18: sample_addr = 20'd156627;
    6'd19: sample_addr = 20'd164575;
    6'd20: sample_addr = 20'd179405;
    6'd21: sample_addr = 20'd191402;
    6'd22: sample_addr = 20'd206696;
    6'd23: sample_addr = 20'd219084;
    6'd24: sample_addr = 20'd235266;
    6'd25: sample_addr = 20'd246255;
    6'd26: sample_addr = 20'd252546;
    6'd27: sample_addr = 20'd259999;
    6'd28: sample_addr = 20'd264834;
    6'd29: sample_addr = 20'd272270;
    6'd30: sample_addr = 20'd283590;
    6'd31: sample_addr = 20'd289934;
    6'd32: sample_addr = 20'd299899;
    6'd33: sample_addr = 20'd316683;
    6'd34: sample_addr = 20'd329237;
    6'd35: sample_addr = 20'd339503;
    6'd36: sample_addr = 20'd350597;
    6'd37: sample_addr = 20'd369549;
    6'd38: sample_addr = 20'd377017;
    6'd39: sample_addr = 20'd392476;
    6'd40: sample_addr = 20'd409215;
    6'd41: sample_addr = 20'd425366;
    6'd42: sample_addr = 20'd438552;
    6'd43: sample_addr = 20'd445807;
    6'd44: sample_addr = 20'd458196;
    6'd45: sample_addr = 20'd475296;
    6'd46: sample_addr = 20'd485607;
    6'd47: sample_addr = 20'd502421;
    6'd48: sample_addr = 20'd515878;
    6'd49: sample_addr = 20'd528026;
    6'd50: sample_addr = 20'd540159;
    6'd51: sample_addr = 20'd552804;
    6'd52: sample_addr = 20'd568549;
    6'd53: sample_addr = 20'd579838;
    6'd54: sample_addr = 20'd593988;
    6'd55: sample_addr = 20'd604540;
    6'd56: sample_addr = 20'd616552;
    6'd57: sample_addr = 20'd620964;
    6'd58: sample_addr = 20'd629725;
    6'd59: sample_addr = 20'd645470;
    6'd60: sample_addr = 20'd661185;
    6'd61: sample_addr = 20'd674792;
  endcase

always @*
  case (PhCde)
    6'd00: sample_size = 16'd10959;
    6'd01: sample_size = 16'd10540;
    6'd02: sample_size = 16'd11637;
    6'd05: sample_size = 16'd12815;
    6'd06: sample_size = 16'd12524;
    6'd07: sample_size = 16'd8915;
    6'd08: sample_size = 16'd9664;
    6'd09: sample_size = 16'd9174;
    6'd10: sample_size = 16'd10025;
    6'd11: sample_size = 16'd11621;
    6'd12: sample_size = 16'd7013;
    6'd13: sample_size = 16'd6354;
    6'd14: sample_size = 16'd6029;
    6'd15: sample_size = 16'd7620;
    6'd16: sample_size = 16'd10372;
    6'd17: sample_size = 16'd11365;
    6'd18: sample_size = 16'd7948;
    6'd19: sample_size = 16'd14830;
    6'd20: sample_size = 16'd11997;
    6'd21: sample_size = 16'd15294;
    6'd22: sample_size = 16'd12388;
    6'd23: sample_size = 16'd16182;
    6'd24: sample_size = 16'd10989;
    6'd25: sample_size = 16'd6291;
    6'd26: sample_size = 16'd7453;
    6'd27: sample_size = 16'd4835;
    6'd28: sample_size = 16'd7436;
    6'd29: sample_size = 16'd11320;
    6'd30: sample_size = 16'd6344;
    6'd31: sample_size = 16'd9965;
    6'd32: sample_size = 16'd16784;
    6'd33: sample_size = 16'd12554;
    6'd34: sample_size = 16'd10266;
    6'd35: sample_size = 16'd11094;
    6'd36: sample_size = 16'd18952;
    6'd37: sample_size = 16'd7468;
    6'd38: sample_size = 16'd15459;
    6'd39: sample_size = 16'd16739;
    6'd40: sample_size = 16'd16151;
    6'd41: sample_size = 16'd13186;
    6'd42: sample_size = 16'd7255;
    6'd43: sample_size = 16'd12389;
    6'd44: sample_size = 16'd17100;
    6'd45: sample_size = 16'd10311;
    6'd46: sample_size = 16'd16814;
    6'd47: sample_size = 16'd13457;
    6'd48: sample_size = 16'd12148;
    6'd49: sample_size = 16'd12133;
    6'd50: sample_size = 16'd12645;
    6'd51: sample_size = 16'd15745;
    6'd52: sample_size = 16'd11289;
    6'd53: sample_size = 16'd14150;
    6'd54: sample_size = 16'd10552;
    6'd55: sample_size = 16'd12012;
    6'd56: sample_size = 16'd4412;
    6'd57: sample_size = 16'd8761;
    6'd58: sample_size = 16'd15745;
    6'd59: sample_size = 16'd15715;
    6'd60: sample_size = 16'd13607;
    6'd61: sample_size = 16'd20502;
    default: sample_size = 0;
  endcase

always @(posedge clk) begin

  if (LatchCde && OldLatchSignal != LatchCde) begin
    speaking <= 1'b1;
    addr <= sample_addr;
    size <= sample_size;
    length <= 16'd0;
  end

  if (speaking) begin
    // audio <= samples[addr];

    if (length < size) begin
      addr <= addr + 1'b1;
      length <= length + 1'b1;
    end
    else begin
      speaking <= 1'b0;
    end
  end

  OldLatchSignal <= LatchCde;

end

endmodule
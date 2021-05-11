/*
 * DM9311 (4-Line to 16-Line Decoders/Demultiplexers)
 */
module DM9311(
  // pin       18    19
  input  logic G1_N, G2_N,  // Strobe negative
  // pin       23 22 21 20
  input  logic A, B, C, D,  // Input
  // pin       1     2     3      4      5      6      7      8
  output logic D0_N, D1_N, D2_N,  D3_N,  D4_N,  D5_N,  D6_N,  D7_N, // Output negative
  // pin       9     10    11     13     14     15     16     17
  output logic D8_N, D9_N, D10_N, D11_N, D12_N, D13_N, D14_N, D15_N // Output negative
);
  logic [15:0] DBUS_N;
  assign {D15_N, D14_N, D13_N, D12_N, D11_N, D10_N, D9_N, D8_N, D7_N, D6_N, D5_N, D4_N, D3_N, D2_N, D1_N, D0_N} = DBUS_N;

  always_comb begin
    if (!G1_N && !G2_N) begin
      DBUS_N = 16'b1111_1111_1111_1111;
    end else begin
      unique case ({D, C, B, A})
        4'd0:  DBUS_N = 16'b1111_1111_1111_1110;
        4'd1:  DBUS_N = 16'b1111_1111_1111_1101;
        4'd2:  DBUS_N = 16'b1111_1111_1111_1011;
        4'd3:  DBUS_N = 16'b1111_1111_1111_0111;
        4'd4:  DBUS_N = 16'b1111_1111_1110_1111;
        4'd5:  DBUS_N = 16'b1111_1111_1101_1111;
        4'd6:  DBUS_N = 16'b1111_1111_1011_1111;
        4'd7:  DBUS_N = 16'b1111_1111_0111_1111;
        4'd8:  DBUS_N = 16'b1111_1110_1111_1111;
        4'd9:  DBUS_N = 16'b1111_1101_1111_1111;
        4'd10: DBUS_N = 16'b1111_1011_1111_1111;
        4'd11: DBUS_N = 16'b1111_0111_1111_1111;
        4'd12: DBUS_N = 16'b1110_1111_1111_1111;
        4'd13: DBUS_N = 16'b1101_1111_1111_1111;
        4'd14: DBUS_N = 16'b1011_1111_1111_1111;
        4'd15: DBUS_N = 16'b0111_1111_1111_1111;
      endcase
    end
  end

endmodule

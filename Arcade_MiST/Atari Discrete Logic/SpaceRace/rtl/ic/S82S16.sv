/*
 * 256-BIT RAM
 */
module S82S16(
  input  logic CLK_DRV,                        // Clock for synchronous operation
  input  logic A0, A1, A2, A3, A4, A5, A6, A7, // Address
  input  logic DIN,                            // Data input
  input  logic CE1_N, CE2_N, CE3_N,            // Chip enable (enbale for all negative)
  input  logic WE_N,                           // Write enable negative
  output logic DOUT_N                          // Data out negative
);

  logic [7:0] addr;
  assign addr = {A7, A6, A5, A4, A3, A2, A1, A0};

  logic enable;
  assign enable = ~CE1_N & ~CE2_N & ~CE3_N;

  // Origianl IC can accept asynchronous write,
  // but this version uses synchronous write to avoid latches.
  logic mem [0:255];
  always_ff @(posedge CLK_DRV) begin
    if (enable & ~WE_N)
      mem[addr] <= DIN;
  end

  always_comb begin
    if (enable & WE_N)
      DOUT_N = ~mem[addr];
    else if (enable & ~WE_N)
      DOUT_N = ~DIN; // output new input data while write cycle
    else
      DOUT_N = 1'b1;
      // Ideally this should be 1'bz (Hi-Z)
      // But in the original breakout circuit consists of a TTL ICs,
      // Hi-Z output is treated as high input of the latter gate.
      // FPGA cannot treat Hi-Z as high so output high signal.
  end

endmodule

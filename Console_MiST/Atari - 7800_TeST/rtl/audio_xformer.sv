`timescale 1ns / 1ps

module audio_xformer(input logic AUD0, AUD1,
                     input logic [3:0] AUDV0, AUDV1,
                     output logic [15:0] AUD_SIGNAL);

  logic [15:0] audio0,audio1;


  assign AUD_SIGNAL = audio0 + audio1;

  always_comb begin
    case (AUD0)
      1: audio0 = 16'h3FF * AUDV0;
      0: audio0 = 16'hFC00 * AUDV0;
    endcase
    case (AUD1)
      1: audio1 = 16'h3FF * AUDV1;
      0: audio1 = 16'hFC00 * AUDV1;
    endcase
  end


endmodule 
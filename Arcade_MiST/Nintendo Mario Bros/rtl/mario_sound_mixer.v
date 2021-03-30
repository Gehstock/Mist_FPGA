//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Sound mixer.
// Mixes the analogue sounds (samples) with the digital
// sound produced by the M58715 chip.
//----------------------------------------------------------------------------

module mario_sound_mixer
(
   input               I_CLK_48M,
   input         [15:0]I_SND1,I_SND2,I_SND3,I_SND4,
   output signed [15:0]O_SND_DAT
);

wire signed [18:0]sound_mix = {{3{I_SND1[15]}}, I_SND1} + 
                              {{3{I_SND2[15]}}, I_SND2} + 
                              {{3{I_SND3[15]}}, I_SND3} + 
                              {{3{I_SND4[15]}}, I_SND4};

reg signed [15:0]dac_di;

always@(posedge I_CLK_48M)
begin
   if(sound_mix >= 19'sh07FFF)
      dac_di <= 16'sh7FFF;
   else if(sound_mix <= -19'sh08000)
      dac_di <= -16'sh8000;
   else
      dac_di <= sound_mix[15:0]; 
end


assign O_SND_DAT = dac_di;

endmodule

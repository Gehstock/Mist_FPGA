//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Top level sound module.
//----------------------------------------------------------------------------

module mario_sound
(
   input         I_CLK_48M,
   input         I_CEN_12M,
   input         I_CEN_11M,
   input         I_RESETn,
   input    [7:0]I_SND_DATA,
   input    [9:0]I_SND_CTRL,
   input    [3:0]I_ANLG_VOL,
   input    [3:0]I_H_CNT,
   output signed  [15:0]O_SND_DAT,
	output  	[12:0]	snd_rom_addr,
	input   	[15:0]	snd_rom_do
);

//------------------------------------------------
// Digital sound
// Background music and some of the sound effects
//------------------------------------------------

wire   [15:0]W_D_S_DATA;

mario_sound_digital digital_sound
(
   .I_CLK_48M(I_CLK_48M),
   .I_CEN_12M(I_CEN_12M),
   .I_CEN_11M(I_CEN_11M),
   .I_RST(I_RESETn),
   .I_SND_DATA(I_SND_DATA),
   .I_SND_CTRL(I_SND_CTRL[6:0]),
   .O_SND_OUT(W_D_S_DATA)
);

//--------------------------------------
// Analogue Sounds (samples)
// Mario run, Luigi run and skid sounds
//--------------------------------------

wire signed [15:0]W_WAVROM_DS[0:2];

mario_sound_analog analog_sound
(
   .I_CLK_48M(I_CLK_48M),
   .I_RESETn(I_RESETn),

   .I_SND_CTRL(I_SND_CTRL[9:7]),
   .I_ANLG_VOL(I_ANLG_VOL),
   .I_H_CNT(I_H_CNT),
   .O_WAVROM_DS0(W_WAVROM_DS[0]),
   .O_WAVROM_DS1(W_WAVROM_DS[1]),
   .O_WAVROM_DS2(W_WAVROM_DS[2]),
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_do)
);

//----------------------------------
// Sound Mixer (Analogue & Digital)
//----------------------------------

wire signed [15:0]W_SND_MIX;

mario_sound_mixer mixer
(
   .I_CLK_48M(I_CLK_48M),
   .I_SND1(W_WAVROM_DS[0]),
   .I_SND2(W_WAVROM_DS[1]),
   .I_SND3(W_WAVROM_DS[2]),
   .I_SND4(W_D_S_DATA),
   .O_SND_DAT(W_SND_MIX)
);

assign O_SND_DAT = W_SND_MIX;

endmodule

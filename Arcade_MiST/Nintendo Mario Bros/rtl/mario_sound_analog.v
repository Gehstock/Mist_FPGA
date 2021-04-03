//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Analogue sounds (samples).
// Mario run, Luigi run and skid sounds.
//----------------------------------------------------------------------------

module mario_sound_analog
(
   input          I_CLK_48M,
   input          I_RESETn,

   input     [2:0]I_SND_CTRL,
   input     [3:0]I_ANLG_VOL,
   input     [3:0]I_H_CNT,

   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR,

   output   signed [15:0]O_WAVROM_DS0,
   output   signed [15:0]O_WAVROM_DS1,
   output   signed [15:0]O_WAVROM_DS2,
	output  	[12:0]	snd_rom_addr,
	input   	[15:0]	snd_rom_do
);

//-----------------------
// Extra ROM for samples
//-----------------------

reg   [12:0]WAVROM_ADDR;
wire  [15:0]W_WAVROM_DO;

//WAV_ROM wavrom(I_CLK_48M, WAVROM_ADDR, W_WAVROM_DO,
//               I_CLK_48M, I_DLADDR, I_DLDATA, I_DLWR);

assign snd_rom_addr = WAVROM_ADDR;
assign W_WAVROM_DO = snd_rom_do;

wire signed [15:0]W_WAVROM_DS[0:3];
wire        [12:0]W_WAVROM_A[0:3];

//------------
// Skid sound
//------------
mario_wav_sound skid_sound
(
   .I_CLK(I_CLK_48M),
   .I_RSTn(I_RESETn),
   .I_H_CNT(I_H_CNT[3:0]),
   .I_DIV(12'd2176), // 48Mhz / 2176 = 22,050Hz
   .I_VOL(I_ANLG_VOL),
   .I_DMA_TRIG(~I_SND_CTRL[0]),
   .I_DMA_STOP(1'b0),
   .I_RETRIG_EN(1'b1),
   .I_DMA_CHAN(3'd0),
   .I_DMA_ADDR(16'h0000),
   .I_DMA_LEN(16'h0800),
   .I_DMA_DATA(W_WAVROM_DO), // Sample data from wave ROM.
   .O_DMA_ADDR(W_WAVROM_A[0]), // Wave ROM address.
   .O_SND(W_WAVROM_DS[0])
);

assign O_WAVROM_DS0 = W_WAVROM_DS[0];

//-----------------
// Mario run sound
//-----------------
mario_wav_sound mario_run_sound
(
   .I_CLK(I_CLK_48M),
   .I_RSTn(I_RESETn),
   .I_H_CNT(I_H_CNT[3:0]),
   .I_DIV(12'd2176),
   .I_VOL(I_ANLG_VOL),
   .I_DMA_TRIG(~I_SND_CTRL[1]),
   .I_DMA_STOP(1'b0),
   .I_RETRIG_EN(1'b0),
   .I_DMA_CHAN(3'd1),
   .I_DMA_ADDR(16'h0800),
   .I_DMA_LEN(16'h0800),
   .I_DMA_DATA(W_WAVROM_DO),
   .O_DMA_ADDR(W_WAVROM_A[1]),
   .O_SND(W_WAVROM_DS[1])
);

assign O_WAVROM_DS1 = W_WAVROM_DS[1];

//-----------------
// Luigi run sound
//-----------------
mario_wav_sound luigi_run_sound
(
   .I_CLK(I_CLK_48M),
   .I_RSTn(I_RESETn),
   .I_H_CNT(I_H_CNT[3:0]),
   .I_DIV(12'd2176),
   .I_VOL(I_ANLG_VOL),
   .I_DMA_TRIG(~I_SND_CTRL[2]),
   .I_DMA_STOP(1'b0),
   .I_RETRIG_EN(1'b0),
   .I_DMA_CHAN(3'd2),
   .I_DMA_ADDR(16'h1000),
   .I_DMA_LEN(16'h0800),
   .I_DMA_DATA(W_WAVROM_DO),
   .O_DMA_ADDR(W_WAVROM_A[2]),
   .O_SND(W_WAVROM_DS[2])
);

assign O_WAVROM_DS2 = W_WAVROM_DS[2];

//--------------------------------
// Sample ROM address bus sharing
//--------------------------------

always @(posedge I_CLK_48M or negedge I_RESETn)
begin
   if(! I_RESETn)begin

      WAVROM_ADDR <= 0;

   end else begin

      case(I_H_CNT[3:0])
         0: WAVROM_ADDR <= W_WAVROM_A[0];
         2: WAVROM_ADDR <= W_WAVROM_A[1];
         4: WAVROM_ADDR <= W_WAVROM_A[2];
         default:;
      endcase

   end
end

endmodule

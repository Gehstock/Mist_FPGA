module mist_audio
(
	input		clk,
	input		reset_n,
	input		[BITS-1:0] audio_inL,
	input		[BITS-1:0] audio_inR,
	output   AUDIO_L,
	output   AUDIO_R
);

parameter BITS = 16;
parameter STEREO = 0;
parameter SIGNED = 0;

wire [BITS-1:0] aud_left = ~SIGNED ? audio_inL : {~audio_inL[BITS-1],audio_inL[BITS-2:0]};
wire [BITS-1:0] aud_right = STEREO ? ~SIGNED ? audio_inR : {~audio_inR[BITS-1],audio_inR[BITS-2:0]} : aud_left;

dac #(
	.C_bits(BITS))
dacl(
	.clk_i(clk),
	.res_n_i(reset_n),
	.dac_i(aud_left),
	.dac_o(AUDIO_L)
	);
	
dac #(
	.C_bits(BITS))
dacr(
	.clk_i(clk),
	.res_n_i(reset_n),
	.dac_i(aud_right),
	.dac_o(AUDIO_R)
	);

endmodule 

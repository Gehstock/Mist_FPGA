module dkong_soundboard(
	input					W_RESETn,
	input					W_CLK_24576M,
	input					W_CLK_12288M,
	input					WB_CLK_06144M,
	input					W_W0_WE,
	input					W_W1_WE,
	input					W_CNF_EN,
	input		[5:0]		W_6H_Q,
	input					W_5H_Q,
	input					W_3D_Q,
	output 	[15:0]	O_SOUND_DAT
);

wire   [7:0]W_D_S_DAT;

wire    [7:0]I8035_DBI;
wire    [7:0]I8035_DBO;
wire    [7:0]I8035_PAI;
wire    [7:0]I8035_PBI;
wire    [7:0]I8035_PBO;
wire    I8035_ALE;
wire    I8035_RDn;
wire    I8035_PSENn;
wire    I8035_CLK = WB_CLK_06144M;
wire    I8035_INTn;
wire    I8035_T0;
wire    I8035_T1;
wire    I8035_RSTn;

I8035IP SOUND_CPU
(
	.I_CLK(I8035_CLK),
	.I_RSTn(I8035_RSTn),
	.I_INTn(I8035_INTn),
	.I_EA(1'b1),
	.O_PSENn(I8035_PSENn),
	.O_RDn(I8035_RDn),
	.O_WRn(),
	.O_ALE(I8035_ALE),
	.O_PROGn(),
	.I_T0(I8035_T0),
	.O_T0(),
	.I_T1(I8035_T1),
	.I_DB(I8035_DBO),
	.O_DB(I8035_DBI),
	.I_P1(8'h00),
	.O_P1(I8035_PAI),
	.I_P2(I8035_PBO),
	.O_P2(I8035_PBI)
);
//-------------------------------------------------

dkong_sound Digtal_sound
(
	.I_CLK1(W_CLK_12288M),
	.I_CLK2(W_CLK_24576M),
	.I_RST(W_RESETn),
	.I8035_DBI(I8035_DBI),
	.I8035_DBO(I8035_DBO),
	.I8035_PAI(I8035_PAI),
	.I8035_PBI(I8035_PBI),
	.I8035_PBO(I8035_PBO), 
	.I8035_ALE(I8035_ALE),
	.I8035_RDn(I8035_RDn),
	.I8035_PSENn(I8035_PSENn),
	.I8035_RSTn(I8035_RSTn),
	.I8035_INTn(I8035_INTn),
	.I8035_T0(I8035_T0),
	.I8035_T1(I8035_T1),
	.I_SOUND_DAT(W_3D_Q), 
	.I_SOUND_CNT({W_6H_Q[5:3],W_5H_Q}),
	.O_SOUND_DAT(W_D_S_DAT)
);
/*
dkong_wav_sound Analog_sound
(
	.O_ROM_AB(WAV_ROM_A),
	.I_ROM_DB(WAV_ROM_DO),

	.I_CLK(W_CLK_24576M),
	.I_RSTn(W_RESETn),
	.I_SW(W_6H_Q[2:0])
);*/

//  SOUND MIXER (WAV + DIG ) -----------------------
/*wire   [8:0]sound_mix = {1'b0, WAV_ROM_DO} + {1'b0, W_D_S_DAT};
reg    [8:0]dac_di;
always@(posedge W_CLK_12288M)
begin
   if(sound_mix >= 9'h17F)     // POS Limiter
      dac_di <= 9'h0FF;
   else if(sound_mix <= 9'h080)// NEG Limiter
      dac_di <= 9'h000;
   else
      dac_di <= sound_mix - 9'h080; 
end*/

assign O_SOUND_DAT = W_D_S_DAT;//dac_di[7:0];

endmodule

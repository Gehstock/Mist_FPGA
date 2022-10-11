module dkong_soundboard(
	input         W_CLK_24576M,
	input         W_RESETn,
	input         I_DKJR,
	input         W_W0_WE,
	input         W_W1_WE,
	input         W_CNF_EN,
	input   [6:0] W_6H_Q,
	input         W_5H_Q0,
	input   [1:0] W_4H_Q,
	input   [4:0] W_3D_Q,
	output [15:0] O_SOUND_DAT,
	output        O_SACK,
	output [11:0] ROM_A,
	input   [7:0] ROM_D,
	output [18:0] WAV_ROM_A,
	input   [7:0] WAV_ROM_DO
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
reg     I8035_CLK_EN;
wire    I8035_INTn;
wire    I8035_T0;
wire    I8035_T1;
wire    I8035_RSTn;

reg [1:0] cnt;
always @(posedge W_CLK_24576M) begin
	cnt <= cnt + 1'd1;
	I8035_CLK_EN <= cnt == 0;
end

I8035IP SOUND_CPU
(
	.I_CLK(W_CLK_24576M),
	.I_CLK_EN(I8035_CLK_EN),
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
assign O_SACK = I8035_PBI[4];
//-------------------------------------------------

dkong_sound Digtal_sound
(
	.I_CLK(W_CLK_24576M),
	.I_RST(W_RESETn),
	.I_DKJR(I_DKJR),
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
	.I_SOUND_DAT(I_DKJR ? ~W_3D_Q : {1'b1, W_3D_Q[3:0]}),
	.I_SOUND_CNT(I_DKJR ? {W_4H_Q[1],W_6H_Q[6:3],W_5H_Q0} : {2'b11,W_6H_Q[5:3],W_5H_Q0}),
	.O_SOUND_DAT(W_D_S_DAT),
	.ROM_A(ROM_A),
	.ROM_D(ROM_D)
);

dkong_wav_sound Analog_sound
(
	.O_ROM_AB(WAV_ROM_A),
	.I_ROM_DB(WAV_ROM_DO),

	.I_CLK(W_CLK_24576M),
	.I_RSTn(W_RESETn),
	.I_SW(I_DKJR ? 3'b000 : W_6H_Q[2:0])
);

//  SOUND MIXER (WAV + DIG ) -----------------------
wire   [8:0]sound_mix = {1'b0, I_DKJR ? 8'd0 : WAV_ROM_DO} + {1'b0, W_D_S_DAT};

assign O_SOUND_DAT = sound_mix[8:1];

endmodule

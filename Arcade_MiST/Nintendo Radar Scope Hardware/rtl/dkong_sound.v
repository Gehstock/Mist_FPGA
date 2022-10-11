//===============================================================================
// FPGA DONKEY KONG SOUND_I/F
//
// Version : 4.00 
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
// 2004- 9- 2 T48-IP(beta3) was include.  K.Degawa
// 2004- 9-14 T48-IP was changed to beta4.  K.Degawa
// 2005- 2- 9 The description of the ROM was changed.
//            Data on the ROM are initialized at the time of the start.   
//================================================================================
 
module dkong_sound(
	input   I_CLK,
	input   I_RST,
	input   I_DKJR,
	input   [7:0]I8035_DBI,
	output  [7:0]I8035_DBO,
	input   [7:0]I8035_PAI,
	input   [7:0]I8035_PBI,
	output  [7:0]I8035_PBO,
	input   I8035_ALE,
	input   I8035_RDn,
	input   I8035_PSENn,
	input   [4:0]I_SOUND_DAT,
	input   [5:0]I_SOUND_CNT,
	output  I8035_INTn,
	output  I8035_T0,
	output  I8035_T1,
	output  I8035_RSTn,
	output  [7:0]O_SOUND_DAT,
	output  [11:0] ROM_A,
	input   [7:0] ROM_D
);

assign  I8035_PBO[6] = ~I_SOUND_CNT[5];
assign  I8035_PBO[4] = ~I_SOUND_CNT[4];
assign  I8035_T0    = ~I_SOUND_CNT[3];
assign  I8035_T1    = ~I_SOUND_CNT[2];
assign  I8035_PBO[5] = ~I_SOUND_CNT[1];
assign  I8035_INTn  = ~I_SOUND_CNT[0];
assign  I8035_RSTn  = I_RST;

assign  I8035_PBO[3:0] = 4'b0000;
assign  I8035_PBO[7] = 1'b0;
//----  Parts 4FH -----------------------------
wire    [10:0]S_ROM_A;
reg     [7:0]L_ROM_A;

//always@(negedge I8035_ALE) L_ROM_A <= I8035_DBI ;
reg I8035_ALE_D;
always@(posedge I_CLK) begin
	I8035_ALE_D <= I8035_ALE;
	if (!I8035_ALE & I8035_ALE_D) L_ROM_A <= I8035_DBI;
end
assign  S_ROM_A = {I8035_PBI[2:0],L_ROM_A[7:0]};
assign  ROM_A = {I_DKJR ? I8035_PBI[3] : I8035_PSENn,S_ROM_A};

//----  Parts 4C ------------------------------
reg     S_D1_CS;
always@(posedge I_CLK) S_D1_CS <= (I_DKJR | I8035_PBI[6])&(~I8035_RDn);

wire    [7:0]S_D1 = S_D1_CS ? {3'h0,~I_SOUND_DAT[4:0]}: 8'h00 ; 

wire    [7:0]S_PROG_DB;
wire    [7:0]S_PROG_D  = I8035_PSENn ? 8'h00 : S_PROG_DB ;
/*
snd1 snd1 (
	.clk(I_CLK),
	.addr(S_ROM_A),
	.data(S_PROG_DB)
	);
*/
assign S_PROG_DB = ROM_D;

//----  DATA ROM 3H ---------------------------
wire    S_D2_CS = (~I_DKJR & ~I8035_PBI[6])&(~I8035_RDn);

wire    [7:0]S_DB2;
wire    [7:0]S_D2 = S_D2_CS ? S_DB2 : 8'h00 ;
/*
snd2 snd2 (
	.clk(I_CLK),
	.addr(S_ROM_A),
	.data(S_DB2)
	);
*/
assign S_DB2 = ROM_D;

//----  I8035_DB IO I/F -----------------------
wire    [7:0]I8035_DO = S_PROG_D | S_D1 | S_D2 ;

reg     [7:0]DO;
always@(posedge I_CLK) DO <= I8035_DO;
assign  I8035_DBO = DO;

//----    DAC  I/F     ------------------------  
assign  O_SOUND_DAT = I8035_PAI;


endmodule

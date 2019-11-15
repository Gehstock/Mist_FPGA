//===============================================================================
// Arcade: Donkey Kong Junior by gaz68 (Oct 2019) 
// https://github.com/gaz68
//
// Original Donkey Kong core by Katsumi Degawa.
//===============================================================================

//===============================================================================
// FPGA DONKEY KONG TOP
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
// 2004- 3- 3 first release.
// 2004- 6- 8 Quartus2 v4.0sp1 used (bug fix) K.Degawa
// 2004- 8-24 T80-IP was include.  K.Degawa
// 2004- 9- 2 T48-IP(beta3) was include.  K.Degawa
// 2004- 9-14 T48-IP was changed to beta4.  K.Degawa
// 2005- 2- 9 Data on the ROM are initialized at the time of the start.
//            added device.
//            changed module I/O.
//================================================================================
//--------------------------------------------------------------------------------


module dkongjr_top
(
	//    FPGA_USE
	input  I_CLK_24576M,
	input  I_RESETn,
	output O_PIX,

	//    INPORT SW IF
	input  I_U1,I_D1,I_L1,I_R1,I_J1,
	input  I_U2,I_D2,I_L2,I_R2,I_J2,
	input  I_S1,I_S2,I_C1,I_SF,
	//input	 I_DEBUG,
	input  [7:0]I_DIP_SW,
	
	//    VGA (VIDEO) IF
	output [2:0]O_VGA_R,
	output [2:0]O_VGA_G,
	output [1:0]O_VGA_B,
	output O_H_BLANK,
	output O_V_BLANK,
	output O_VGA_H_SYNCn,
	output O_VGA_V_SYNCn,

	//    SOUND IF
	output signed [15:0] O_SOUND_DAT
);

assign O_H_BLANK = ~W_H_BLANKn;
assign O_V_BLANK = ~W_V_BLANKn;

wire   W_CLK_24576M = I_CLK_24576M;
wire   W_CLK_12288M,WB_CLK_12288M;
wire   WB_CLK_06144M;
wire   W_RESETn = I_RESETn;

//============   CPU MODULE ( Donkey Kong )   ====================================
//========  Assign Wire  =========================================================
//  INPUT DATA BUS
wire   [7:0]ZDO,ZDI;
wire   [7:0]WI_D = ZDI;
//  INPORT DATA OUT
wire   [7:0]W_SW_DO;
//  ADDRESS DECODER
wire   W_ROM_CSn;
wire   W_RAM1_CSn;
wire   W_RAM2_CSn;
wire   W_RAM3_CSn;
wire   W_RAM_CSn = W_RAM1_CSn & W_RAM2_CSn & W_RAM3_CSn;
//wire   W_6A_Gn;
wire   W_OBJ_RQn;
wire   W_OBJ_RDn;
wire   W_OBJ_WRn;
wire   W_VRAM_RDn;
wire   W_VRAM_WRn;
wire   W_SW1_OEn ;
wire   W_SW2_OEn ;
wire   W_SW3_OEn ;
wire   W_DIP_OEn ;

wire   W_SW_OEn =  W_SW1_OEn & W_SW2_OEn & W_SW3_OEn & W_DIP_OEn;

wire   [1:0]W_4H_Q;
wire   [7:0]W_5H_Q;
wire   [7:0]W_6H_Q;
wire   [4:0]W_3D_Q;

//  INT RAM DATA
wire   [7:0]W_RAM1_DO;
wire   [7:0]W_RAM2_DO;
wire   [7:0]W_RAM3_DO;

//  EXT ROM DATA
wire   [7:0]W_ROM_DO;

//  H&V COUNTER
wire   [9:0]W_H_CNT;
//wire   [7:0]W_V_CNT;
wire   W_H_BLANKn;
wire   W_V_BLANKn;
wire   W_C_BLANKn;
wire   W_H_SYNCn;
wire   W_V_SYNCn;

wire   [7:0]W_OBJ_DB;
wire   [7:0]W_VRAM_DB;
wire   [7:0]W_OBJ_DI;

wire   W_CPU_CLK;
wire   W_CPU_RESETn = W_RESETn;
wire   W_CPU_WAITn;
wire   W_CPU_RFSHn;
wire   W_CPU_M1n;
wire   W_CPU_NMIn;
wire   W_CPU_MREQn;
wire   W_CPU_RDn;  
wire   W_CPU_WRn;
wire   [15:0]W_CPU_A;

assign WB_CLK_06144M = W_H_CNT[0];   //  6.144MHz
assign WB_CLK_12288M = W_CLK_12288M; // 12.288MHz
assign W_CPU_CLK = W_H_CNT[1];       //  3.072MHz

T80as z80core(
	.RESET_n(W_RESETn),
	.CLK_n(W_CPU_CLK),
	.WAIT_n(W_CPU_WAITn),
	.INT_n(1'b1),
	.NMI_n(W_CPU_NMIn),
	.BUSRQ_n(1'b1),
	.M1_n(W_CPU_M1n),
	.MREQ_n(W_CPU_MREQn),
	.RD_n(W_CPU_RDn),
	.WR_n(W_CPU_WRn),
	.RFSH_n(W_CPU_RFSHn),
	.A(W_CPU_A),
	.DI(ZDO),
	.DO(ZDI)
	);
 
//=========   CPU  DATA BUS[7:0]    ==============================================
wire   [7:0]WO_D = W_SW_DO | W_RAM1_DO |W_RAM2_DO |W_RAM3_DO | W_ROM_DO | W_VRAM_DB ;
assign ZDO = WO_D;

wire  [11:0]OBJ_ROM_A;
reg   [7:0]OBJ_ROM1_DO,OBJ_ROM2_DO,OBJ_ROM3_DO,OBJ_ROM4_DO;

reg    [7:0]WB_ROM_DO;
assign W_ROM_DO = (~W_ROM_CSn & ~W_CPU_RDn)? WB_ROM_DO :8'h00;

//---------------------------------------------------------

prog ROM(
	.clk(W_CLK_12288M),
	.addr(W_CPU_A[14:0]),
	.data(WB_ROM_DO)
);


//========   INT RAM Interface  ==================================================

ram_1024_8 U_3C4C
(
	.I_CLK(~W_CLK_12288M),
	.I_ADDR(W_CPU_A[9:0]),
	.I_D(WI_D),
	.I_CE(~W_RAM1_CSn),
	.I_WE(~W_CPU_WRn),
	.O_D(W_RAM1_DO)
);

ram_1024_8 U_3B4B
(
	.I_CLK(~W_CLK_12288M),
	.I_ADDR(W_CPU_A[9:0]),
	.I_D(WI_D),
	.I_CE(~W_RAM2_CSn),
	.I_WE(~W_CPU_WRn),
	.O_D(W_RAM2_DO)
);

//---- Sprite DMA ------------------------------------------

wire   [9:0]W_OBJ_AB = {W_2PSL, W_H_CNT[8:0]};

wire [9:0]W_DMA_A;
wire [7:0]W_DMA_D;
wire W_DMA_CE;

wire [9:0]W_DMA_AB;
wire [7:0]W_DMA_DB;
wire W_DMA_CEB;

ram_1024_8_8 U_3A4A
(
	//   A Port
	.I_CLKA(~W_CLK_12288M),
	.I_ADDRA(W_CPU_A[9:0]),
	.I_DA(WI_D),
	.I_CEA(~W_RAM3_CSn),
	.I_WEA(~W_CPU_WRn),
	.O_DA(W_RAM3_DO),
	//   B Port
	.I_CLKB(W_CLK_12288M),
	.I_ADDRB(W_DMA_A),
	.I_DB(8'h00),
	.I_CEB(W_DMA_CE),
	.I_WEB(1'b0),
	.O_DB(W_DMA_D)
);


dkongjr_dma sprite_dma
(
	.I_CLK(W_H_CNT[0]), // 3.072 Mhz
	.I_DMA_TRIG(W_DREQ),
	.I_DMA_DS(W_DMA_D),

	.O_DMA_AS(W_DMA_A),
	.O_DMA_AD(W_DMA_AB),
	.O_DMA_DD(W_DMA_DB),
	.O_DMA_CES(W_DMA_CE),
	.O_DMA_CED(W_DMA_CEB)
);


ram_1024_8_8 U_6PR
(
	//   A Port
	.I_CLKA(~W_CLK_12288M),
	.I_ADDRA(W_DMA_AB),
	.I_DA(W_DMA_DB),
	.I_CEA(W_DMA_CEB),
	.I_WEA(1'b1),
	.O_DA(),
	//   B Port
	.I_CLKB(W_CLK_12288M),
	.I_ADDRB(W_OBJ_AB[9:0]),
	.I_DB(8'h00),
	.I_CEB(1'b1),
	.I_WEB(1'b0),
	.O_DB(W_OBJ_DI)
);


//---- SW Interface ---------------------------------
wire [7:0]W_SW1={1'b1,1'b1,1'b1,I_J1,I_D1,I_U1,I_L1,I_R1};
wire [7:0]W_SW2={1'b1,1'b1,1'b1,I_J2,I_D2,I_U2,I_L2,I_R2};
wire [7:0]W_SW3={I_C1,1'b1,1'b1,1'b1,I_S2,I_S1,1'b1,1'b1};


dkongjr_inport inport
(
	//  input
	.I_SW1(W_SW1),
	.I_SW2(W_SW2),
	.I_SW3(W_SW3),
	.I_DIP(I_DIP_SW),
	//  enable
	.I_SW1_OE_n(W_SW1_OEn),
	.I_SW2_OE_n(W_SW2_OEn),
	.I_SW3_OE_n(W_SW3_OEn),
	.I_DIP_OE_n(W_DIP_OEn),
	//  output
	.O_D(W_SW_DO)
);


//========   Address Decoder  =====================================================
wire   W_VRAMBUSYn;

dkongjr_adec adec
(
	.I_CLK12M(W_CLK_12288M),
	.I_CLK(W_CPU_CLK),
	.I_RESET_n(W_RESETn),
	.I_AB(W_CPU_A),
	.I_DB(WI_D), 
	.I_MREQ_n(W_CPU_MREQn),
	.I_RFSH_n(W_CPU_RFSHn),
	.I_RD_n(W_CPU_RDn),
	.I_WR_n(W_CPU_WRn),
	.I_VRAMBUSY_n(W_VRAMBUSYn),
	.I_VBLK_n(W_V_BLANKn),
	.O_WAIT_n(W_CPU_WAITn),
	.O_NMI_n(W_CPU_NMIn),
	.O_ROM_CS_n(W_ROM_CSn),
	.O_RAM1_CS_n(W_RAM1_CSn),
	.O_RAM2_CS_n(W_RAM2_CSn),
	.O_RAM3_CS_n(W_RAM3_CSn),
	.O_DMA_CS_n(/*O_DMA_CSn*/),
	.O_6A_G_n(/*W_6A_Gn*/),
	.O_OBJ_RQ_n(W_OBJ_RQn),
	.O_OBJ_RD_n(W_OBJ_RDn),
	.O_OBJ_WR_n(W_OBJ_WRn),
	.O_VRAM_RD_n(W_VRAM_RDn),
	.O_VRAM_WR_n(W_VRAM_WRn),
	.O_SW1_OE_n(W_SW1_OEn),
	.O_SW2_OE_n(W_SW2_OEn),
	.O_SW3_OE_n(W_SW3_OEn),
	.O_DIP_OE_n(W_DIP_OEn),
	.O_4H_Q(W_4H_Q),
	.O_5H_Q(W_5H_Q),
	.O_6H_Q(W_6H_Q),
	.O_3D_Q(W_3D_Q)
);

wire   W_FLIPn = W_5H_Q[2];
wire   W_2PSL  = W_5H_Q[3];
wire   W_DREQ  = W_5H_Q[5]; // DMA Trigger


//===========   VIDEO MODULE ===================================
//========  Assign Wire  =======================================
wire   [7:0]W_VF_CNT;
wire   [5:0]W_OBJ_DAT;
wire   W_FLIP_VRAM;
wire   W_FLIP_HV;
wire   W_L_CMPBLKn;
wire   [3:0]W_VRAM_COL;
wire   [1:0]W_VRAM_VID;
wire   [5:0]W_VRAM_DAT = {W_VRAM_COL[3:0],W_VRAM_VID[1:0]};

//========   H & V Counter   =====================================================

dkongjr_hv_count hv
(
	// input
	.I_CLK(W_CLK_24576M),
	.RST_n(W_RESETn),
	.V_FLIP(W_FLIP_HV),
	// output
	.O_CLK(W_CLK_12288M),
	.H_CNT(W_H_CNT),
	.V_CNT(/*W_V_CNT*/),
	.VF_CNT(W_VF_CNT),
	.H_BLANKn(W_H_BLANKn),
	.V_BLANKn(W_V_BLANKn),
	.C_BLANKn(W_C_BLANKn),
	.H_SYNCn(W_H_SYNCn),
	.V_SYNCn(W_V_SYNCn)
);
         
//========    OBJ (VIDEO)    =====================================================

dkongjr_obj obj
(
	// input
	.CLK_24M(W_CLK_24576M),
	.CLK_12M(WB_CLK_12288M),
	.I_AB(),
	.I_DB(/*W_2N_DO*/),
	.I_OBJ_D(W_OBJ_DI),
	.I_OBJ_WRn(1'b1),
	.I_OBJ_RDn(1'b1),
	.I_OBJ_RQn(1'b1),
	.I_2PSL(W_2PSL),
	.I_FLIPn(W_FLIPn),
	.I_H_CNT(W_H_CNT),
	.I_VF_CNT(W_VF_CNT),
	.I_CMPBLKn(W_C_BLANKn),
	// Debug
	// output
	.O_DB(W_OBJ_DB),
	.O_OBJ_DO(W_OBJ_DAT),
	.O_FLIP_VRAM(W_FLIP_VRAM),
	.O_FLIP_HV(W_FLIP_HV),
	.O_L_CMPBLKn(W_L_CMPBLKn)
);

//========   V-RAM (VIDEO)   =====================================================

dkongjr_vram vram
(
	// input
	.CLK_12M(~W_CLK_12288M),
	.I_AB(W_CPU_A[9:0]),
	.I_DB(WI_D),
	.I_VRAM_WRn(W_VRAM_WRn),
	.I_VRAM_RDn(W_VRAM_RDn),
	.I_FLIP(W_FLIP_VRAM),
	.I_H_CNT(W_H_CNT),
	.I_VF_CNT(W_VF_CNT),
	.I_CMPBLK(W_C_BLANKn),
	.I_4H_Q0(W_4H_Q[0]),
	//  Debug
	//  output
	.O_DB(W_VRAM_DB),
	.O_COL(W_VRAM_COL),
	.O_VID(W_VRAM_VID),
	.O_VRAMBUSYn(W_VRAMBUSYn),
	.O_ESBLKn()
);

//========   COLOR PALETE    =====================================================
wire   [2:0]W_R;
wire   [2:0]W_G;
wire   [1:0]W_B;

assign O_PIX = W_H_CNT[0];

dkongjr_col_pal cpal
(
	// input
	.CLK_6M(W_H_CNT[0]),
	.CLK_12M(W_CLK_12288M),
	.I_VRAM_D(W_VRAM_DAT),
	.I_OBJ_D(W_OBJ_DAT),
	.I_CMPBLKn(W_L_CMPBLKn),
	.I_5H_Q6(W_5H_Q[6]),
	.I_5H_Q7(W_5H_Q[7]),
	// output
	.O_R(W_R),
	.O_G(W_G),
	.O_B(W_B)
);

//========   VIDEO Interface   =====================================================

assign O_VGA_R = W_R;
assign O_VGA_G = W_G;
assign O_VGA_B = W_B;
assign O_VGA_H_SYNCn = W_H_SYNCn;
assign O_VGA_V_SYNCn = W_V_SYNCn;

//========   DIGTAL SOUND    =====================================================
// Background music and some of the sound effects

wire    [7:0]W_D_S_DAT;
wire    [15:0]W_D_S_DATB;
wire    [15:0]W_D_S_DATC;

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

dkongjr_sound Digtal_sound
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
	.I_SOUND_CNT({W_4H_Q[1],W_6H_Q[6:3],W_5H_Q[0]}),
	.O_SOUND_DAT(W_D_S_DAT)
);

assign O_SOUND_DAT = W_D_S_DAT;



endmodule



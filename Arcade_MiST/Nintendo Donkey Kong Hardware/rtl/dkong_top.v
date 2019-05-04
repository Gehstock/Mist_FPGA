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

module dkong_top
(
	//    FPGA_USE
	input  I_CLK_24576M,
	input  I_RESETn,
	output O_PIX,

	//    INPORT SW IF
	input  I_U1,I_D1,I_L1,I_R1,I_J1,
	input  I_U2,I_D2,I_L2,I_R2,I_J2,
	input  I_S1,I_S2,I_C1,

	input  [7:0] I_DIP_SW,
	
	//    VGA (VIDEO) IF
	output [2:0]O_VGA_R,
	output [2:0]O_VGA_G,
	output [1:0]O_VGA_B,
	output O_H_BLANK,
	output O_V_BLANK,
	output O_VGA_H_SYNCn,
	output O_VGA_V_SYNCn,

	//    SOUND IF
	output [7:0] O_SOUND_DAT
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

wire   [7:0]W_5H_Q;
wire   [7:0]W_6H_Q;
wire   [3:0]W_3D_Q;

//  RAM DATA
wire   [7:0]W_RAM1_DO;
wire   [7:0]W_RAM2_DO;
wire   [7:0]W_RAM3_DO;

//  ROM DATA
wire   [7:0]W_ROM_DO;

//  H&V COUNTER
wire   [9:0]W_H_CNT;
//wire   [7:0]W_V_CNT;
wire   W_H_BLANKn;
wire   W_V_BLANKn;
wire   W_C_BLANKn;


wire   [7:0]W_VRAM_DB;
wire   [7:0]W_OBJ_DI;

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
wire   W_CPU_CLK = W_H_CNT[1];       //  3.072MHz

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
	.addr(W_CPU_A[13:0]),
	.data(WB_ROM_DO)
);

//========   INT RAM Interface  ==================================================

ram_1024_8 U_3C4C
(
	.I_CLK(W_CLK_12288M),
	.I_ADDR(W_CPU_A[9:0]),
	.I_D(WI_D),
	.I_CE(~W_RAM1_CSn),
	.I_WE(~W_CPU_WRn),
	.O_D(W_RAM1_DO)
);

ram_1024_8 U_3B4B
(
	.I_CLK(W_CLK_12288M),
	.I_ADDR(W_CPU_A[9:0]),
	.I_D(WI_D),
	.I_CE(~W_RAM2_CSn),
	.I_WE(~W_CPU_WRn),
	.O_D(W_RAM2_DO)
);

//----    DMA   ------------------------------------------
wire   [1:0]W_OBJ_A_offset = W_H_CNT[8]+1'd1;
wire   [9:0]W_OBJ_AB = {W_OBJ_A_offset[1:0],W_H_CNT[7:0]};

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
	.I_ADDRB(W_OBJ_AB[9:0]),
	.I_DB(8'h00),
	.I_CEB(1'b1),
	.I_WEB(1'b0),
	.O_DB(W_OBJ_DI)
);

wire   [7:0]W_SW1 = W_SW1_OEn ?  8'h00: ~{1'b1,1'b1,1'b1,I_J1,I_D1,I_U1,I_L1,I_R1};
wire   [7:0]W_SW2 = W_SW2_OEn ?  8'h00: ~{1'b1,1'b1,1'b1,I_J2,I_D2,I_U2,I_L2,I_R2};
wire   [7:0]W_SW3 = W_SW3_OEn ?  8'h00: ~{I_C1,1'b1,1'b1,1'b1,I_S2,I_S1,1'b1,1'b1};
wire   [7:0]W_DIP = W_DIP_OEn ?  8'h00:  I_DIP_SW;


assign  W_SW_DO = W_SW1 | W_SW2 | W_SW3 | W_DIP;
//========   Address Decoder  =====================================================
wire   W_VRAMBUSYn;

dkong_adec adec
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
	.O_5H_Q(W_5H_Q),
	.O_6H_Q(W_6H_Q),
	.O_3D_Q(W_3D_Q)
);

wire   W_FLIPn = W_5H_Q[2];
wire   W_2PSL  = W_5H_Q[3];

//===========   VIDEO MODULE ( Donkey Kong )   ===================================
//========  Assign Wire  =========================================================
wire   [7:0]W_VF_CNT;
wire   [5:0]W_OBJ_DAT;
wire   W_FLIP_VRAM;
wire   W_FLIP_HV;
wire   W_L_CMPBLKn;
wire   [3:0]W_VRAM_COL;
wire   [1:0]W_VRAM_VID;

//========   H & V Counter   =====================================================

dkong_hv_count hv
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
	.H_SYNCn(O_VGA_H_SYNCn),
	.V_SYNCn(O_VGA_V_SYNCn)
);
         
//========    OBJ (VIDEO)    =====================================================

dkong_obj obj
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
	// Debug output
	.O_OBJ_DO(W_OBJ_DAT),
	.O_FLIP_VRAM(W_FLIP_VRAM),
	.O_FLIP_HV(W_FLIP_HV),
	.O_L_CMPBLKn(W_L_CMPBLKn)
);

dkong_vram vram
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
	//  Debug output
	.O_DB(W_VRAM_DB),
	.O_COL(W_VRAM_COL),
	.O_VID(W_VRAM_VID),
	.O_VRAMBUSYn(W_VRAMBUSYn),
	.O_ESBLKn()
);

assign O_PIX = W_H_CNT[0];

dkong_col_pal cpal
(
	// input
	.CLK_6M(W_H_CNT[0]),
	.CLK_12M(W_CLK_12288M),
	.I_VRAM_D({W_VRAM_COL[3:0],W_VRAM_VID[1:0]}),
	.I_OBJ_D(W_OBJ_DAT),
	.I_CMPBLKn(W_L_CMPBLKn),
	.I_5H_Q6(W_5H_Q[6]),
	.I_5H_Q7(W_5H_Q[7]),
	.O_R(O_VGA_R),
	.O_G(O_VGA_G),
	.O_B(O_VGA_B)
);

dkong_soundboard dkong_soundboard(
	.WB_CLK_06144M(WB_CLK_06144M),
	.W_CLK_12288M(W_CLK_12288M),
	.W_CLK_24576M(W_CLK_24576M),
	.W_RESETn(W_RESETn),
	.O_SOUND_DAT(O_SOUND_DAT),
	.W_6H_Q(W_6H_Q),
	.W_5H_Q(W_5H_Q),
	.W_3D_Q(W_3D_Q)
	);
	
endmodule




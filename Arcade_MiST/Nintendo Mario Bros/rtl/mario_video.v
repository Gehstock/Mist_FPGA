//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Top level video module.
//----------------------------------------------------------------------------

module mario_video
(
   input        I_CLK_48M,
   input        I_CEN_24Mp,
   input        I_CEN_24Mn,
   input        I_CEN_6M,
   input        I_CEN_12M,
   input        I_RESETn,
   input   [9:0]I_CPU_A,
   input   [7:0]I_CPU_D,
   input        I_VRAM_WRn,
   input        I_VRAM_RDn,
   input   [7:0]I_2L_Q,
   input        I_VMOV,
   input   [9:0]I_H_CNT,
   input   [7:0]I_VF_CNT,
   input        I_CBLANKn,
   input        I_VBLKn,
   input        I_VCKn,
   input   [9:0]I_OBJDMA_A,
   input   [7:0]I_OBJDMA_D,
   input        I_OBJDMA_CE,
   output  [7:0]O_VRAM_DB,
   output       O_VRAMBUSYn,
   output       O_FLIP_HV,
   output  [7:0]O_OBJ_DB,
   output  [2:0]O_VGA_RED,
   output  [2:0]O_VGA_GRN,
   output  [1:0]O_VGA_BLU
);

//------------------
// VRAM
// Background tiles
//------------------

wire   [3:0]W_VRAM_COL;
wire   [1:0]W_VRAM_VID;
wire   [7:0]W_VRAM_DB;
wire        W_VRAMBUSYn;
wire        W_TROMn = I_2L_Q[0];

mario_vram vram
(
   .I_CLK_48M(I_CLK_48M),
   .I_CEN_24Mp(I_CEN_24Mp),
   .I_CEN_24Mn(I_CEN_24Mn),
   .I_AB(I_CPU_A),
   .I_DB(I_CPU_D),
   .I_VRAM_WRn(I_VRAM_WRn),
   .I_VRAM_RDn(I_VRAM_RDn),
   .I_FLIP(W_FLIP_VRAM),
   .I_H_CNT(I_H_CNT),
   .I_CMPBLK(I_CBLANKn),
   .I_VBLKn(I_VBLKn),
   .I_VCKn(I_VCKn),
   .I_GFXBANK(W_TROMn),
   .I_VMOV(I_VMOV),
   .O_DB(W_VRAM_DB),
   .O_COL(W_VRAM_COL),
   .O_VID(W_VRAM_VID),
   .O_VRAMBUSYn(W_VRAMBUSYn)
);

wire   [6:0]W_VRAM_DAT = {W_VRAM_COL[3:0],1'b0,W_VRAM_VID[1:0]};

assign O_VRAM_DB   = W_VRAM_DB;
assign O_VRAMBUSYn = W_VRAMBUSYn;

//-------------------
// Objects / Sprites
//-------------------

wire  [6:0]W_OBJ_DAT;
wire       W_FLIP_VRAM;
wire       W_FLIP_HV;
wire       W_FLIPn = ~I_2L_Q[2];
wire       W_2PSL  = I_2L_Q[1];
wire       W_L_CMPBLKn;
wire  [7:0]W_OBJ_DB;

mario_obj sprites
(
   .I_CLK_48M(I_CLK_48M),
   .I_CEN_24Mp(I_CEN_24Mp),
   .I_CEN_24Mn(I_CEN_24Mn),
   .I_CEN_12M(I_CEN_12M),
   .I_AB(),            // Not used
   .I_DB(/*W_2N_DO*/), // Not used
   .I_OBJ_WRn(1'b1),   // Not used
   .I_OBJ_RDn(1'b1),   // Not used
   .I_OBJ_RQn(1'b1),   // Not used
   .I_2PSL(W_2PSL),
   .I_FLIPn(W_FLIPn),
   .I_CMPBLKn(I_CBLANKn),
   .I_H_CNT(I_H_CNT),
   .I_VF_CNT(I_VF_CNT),
   .I_OBJ_DMA_A(I_OBJDMA_A),
   .I_OBJ_DMA_D(I_OBJDMA_D),
   .I_OBJ_DMA_CE(I_OBJDMA_CE),
   .O_DB(W_OBJ_DB), // Not used
   .O_OBJ_DO(W_OBJ_DAT),
   .O_FLIP_VRAM(W_FLIP_VRAM),
   .O_FLIP_HV(W_FLIP_HV),
   .O_L_CMPBLKn(W_L_CMPBLKn)
);

assign O_OBJ_DB  = W_OBJ_DB;
assign O_FLIP_HV = W_FLIP_HV;

//----------------
// Colour Palette
//----------------

wire   [2:0]W_R;
wire   [2:0]W_G;
wire   [1:0]W_B;

mario_col_pal cpal
(
   .I_CLK_48M(I_CLK_48M),
   .I_CEN_24Mn(I_CEN_24Mn),
   .I_CEN_6M(I_CEN_6M),
   .I_VRAM_D(W_VRAM_DAT),
   .I_OBJ_D(W_OBJ_DAT),
   .I_CMPBLKn(W_L_CMPBLKn),
   .I_CPAL_SEL(I_2L_Q[3]),
   .O_R(W_R),
   .O_G(W_G),
   .O_B(W_B)
);

assign O_VGA_RED = W_R;
assign O_VGA_GRN = W_G;
assign O_VGA_BLU = W_B;

endmodule

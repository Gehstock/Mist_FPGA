//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Top level module
//----------------------------------------------------------------------------

module mario_top
(
   input         I_CLK_48M,
   input         		I_RESETn,

   input		[3:0]		I_ANLG_VOL,
   input 	[7:0]		I_SW1,
   input 	[7:0]		I_SW2,
   input 	[7:0]		I_DIPSW,

   output	[15:0]	cpu_rom_addr,
   input    [7:0]		cpu_rom_do,
	output  	[12:0]	snd_rom_addr,
	input   	[15:0]	snd_rom_do,

   output   [2:0]		O_VGA_R,
   output   [2:0]		O_VGA_G,
   output   [1:0]		O_VGA_B,
   output        		O_HBLANK,
   output        		O_VBLANK,
   output        		O_VGA_HSYNCn,
   output        		O_VGA_VSYNCn,
   output        		O_PIX,
   output signed [15:0] O_SOUND_DAT
);

wire   	W_RESETn      = I_RESETn;
wire   	W_CPU_RESETn  = W_RESETn;
wire 		W_CLK_48M = I_CLK_48M;
wire 		cen24p, cen24n, cen12p, cen12n, cen11, cen6, cen4p, cen4n;

reg [2:0] div8;

always @(posedge W_CLK_48M) begin
   div8 <= div8 + 1'd1;
end

assign  cen24p = div8[0];
assign  cen24n = ~div8[0];
assign  cen12p = div8[0] & div8[1];
assign  cen12n = div8[0] & ~div8[1];
assign  cen6   = div8 == 0;

reg [3:0] div12;

always @(posedge W_CLK_48M) begin
   div12 <= div12 + 1'd1;
   if (div12 == 4'd11) begin
     div12 <= 0;
   end
end

assign cen4p = div12 == 0;
assign cen4n = div12 == 6;

reg [2:0] div8b;
reg [2:0] div5;
reg       flip;

always @(posedge W_CLK_48M) begin
   if (flip) begin
      div8b <= div8b + 1'd1;
      if (div8b == 7) begin
         flip <= 1'b0;
         div5 <= 0;
      end
   end else begin
      div5 <= div5 + 1'd1;
      if (div5 == 4) begin
         flip <= 1'b1;
         div8b <= 0;
      end
   end
end

assign cen11 = flip ? (div8b == 0 || div8b == 4) : (div5 == 0);

//-----------------
// Video timing
//-----------------


wire   [9:0]W_H_CNT;
wire   [7:0]W_V_CNT;
wire   [7:0]W_VF_CNT;
wire        W_HBLANKn;
wire        W_VBLANKn;
wire        W_CBLANKn;
wire        W_HSYNCn;
wire        W_VSYNCn;
wire        W_VCKn;

mario_hv_generator hv
(
   .I_CLK(W_CLK_48M),
   .I_CEN(cen12n),
   .I_RST_n(W_RESETn),
   .I_VFLIP(W_FLIP_HV),
   .H_CNT(W_H_CNT),
   .V_CNT(W_V_CNT), // Not used
   .VF_CNT(W_VF_CNT),
   .H_BLANKn(W_HBLANKn),
   .V_BLANKn(W_VBLANKn),
   .C_BLANKn(W_CBLANKn),
   .H_SYNCn(W_HSYNCn),
   .V_SYNCn(W_VSYNCn),
   .VCKn(W_VCKn)
);

assign O_PIX         = W_H_CNT[0];

assign O_HBLANK      = ~W_HBLANKn;
assign O_VBLANK      = ~W_VBLANKn;
assign O_VGA_HSYNCn  = W_HSYNCn;
assign O_VGA_VSYNCn  = W_VSYNCn;

//-----------------------------------------
// Main CPU 
// ROM, RAM, address decoding, inputs etc.
//-----------------------------------------

wire  [15:0]W_MCPU_A;
wire   [7:0]ZDI;
wire   [7:0]WI_D = ZDI;
wire        W_MCPU_RDn;  
wire        W_MCPU_WRn;

wire   [9:0]W_DMAD_A;
wire   [7:0]W_DMAD_D;
wire        W_DMAD_CE;

wire        W_OBJ_RQn;
wire        W_OBJ_RDn;
wire        W_OBJ_WRn;
wire        W_VRAM_RDn;
wire        W_VRAM_WRn;

wire   [7:0]W_4C_Q;
wire   [7:0]W_2L_Q;
wire   [7:0]W_7M_Q;
wire   [7:0]W_7J_Q;

mario_main maincpu
(
   .I_CLK_48M(I_CLK_48M),
   .I_CEN_12M(cen12p),
   .I_MCPU_CEN4Mp(cen4p),
   .I_MCPU_CEN4Mn(cen4n),
   .I_MCPU_RESETn(W_CPU_RESETn),
   .I_VRAMBUSY_n(W_VRAMBUSYn),
   .I_VBLK_n(W_VBLANKn),
   .I_VRAM_DB(W_VRAM_DB),
   .I_SW1(I_SW1),
   .I_SW2(I_SW2),
   .I_DIPSW(I_DIPSW),
	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_do),
   .O_MCPU_A(W_MCPU_A),
   .WI_D(ZDI),
   .O_MCPU_RDn(W_MCPU_RDn),
   .O_MCPU_WRn(W_MCPU_WRn),
   .O_DMAD_A(W_DMAD_A),
   .O_DMAD_D(W_DMAD_D),
   .O_DMAD_CE(W_DMAD_CE),
   .O_OBJ_RQn(W_OBJ_RQn),
   .O_OBJ_RDn(W_OBJ_RDn),
   .O_OBJ_WRn(W_OBJ_WRn),
   .O_VRAM_RDn(W_VRAM_RDn),
   .O_VRAM_WRn(W_VRAM_WRn),
   .O_4C_Q(W_4C_Q),
   .O_2L_Q(W_2L_Q),
   .O_7M_Q(W_7M_Q),
   .O_7J_Q(W_7J_Q)
);

//------------------------------------
// Video
// Background tiles, sprites, colours
//------------------------------------

wire       W_VRAMBUSYn;
wire  [7:0]W_VRAM_DB;
wire  [7:0]W_OBJ_DB;
wire       W_FLIP_HV;

mario_video vid
(
	.I_CLK_48M(I_CLK_48M),
   .I_CEN_24Mp(cen24p),
   .I_CEN_24Mn(cen24n),
   .I_CEN_12M(cen12p),
   .I_CEN_6M(cen6),
   .I_RESETn(W_RESETn),
   .I_CPU_A(W_MCPU_A[9:0]),
   .I_CPU_D(WI_D),

   .I_VRAM_WRn(W_VRAM_WRn),
   .I_VRAM_RDn(W_VRAM_RDn),
   .I_2L_Q(W_2L_Q),
   .I_VMOV(W_4C_Q[2]),

   .I_H_CNT(W_H_CNT),
   .I_VF_CNT(W_VF_CNT),
   .I_CBLANKn(W_CBLANKn),
   .I_VBLKn(W_VBLANKn),
   .I_VCKn(W_VCKn),
   .I_OBJDMA_A(W_DMAD_A),
   .I_OBJDMA_D(W_DMAD_D),
   .I_OBJDMA_CE(W_DMAD_CE),
   .O_VRAM_DB(W_VRAM_DB),
   .O_VRAMBUSYn(W_VRAMBUSYn),
   .O_FLIP_HV(W_FLIP_HV),
   .O_OBJ_DB(W_OBJ_DB), // Not used
   .O_VGA_RED(O_VGA_R),
   .O_VGA_GRN(O_VGA_G),
   .O_VGA_BLU(O_VGA_B)
);


//-------
// Sound
//-------

mario_sound sound
(
   .I_CLK_48M(I_CLK_48M),
	.I_CEN_12M(cen12p),
	.I_CEN_11M(cen11),
   .I_RESETn(W_RESETn),
   .I_SND_DATA(W_7J_Q),
   .I_SND_CTRL({W_4C_Q[1:0],W_7M_Q}),
   .I_ANLG_VOL(I_ANLG_VOL),
   .I_H_CNT(W_H_CNT[3:0]),
   .O_SND_DAT(O_SOUND_DAT),
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_do)
);


endmodule 
//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Main CPU, ROM, RAM, address decoding, DMA and inputs.
//----------------------------------------------------------------------------

module mario_main
(
   input        I_CLK_48M,
   input        I_CEN_12M,
   input        I_MCPU_CEN4Mp,
   input        I_MCPU_CEN4Mn,
   input        I_MCPU_RESETn,

   input        I_VRAMBUSY_n,
   input        I_VBLK_n,
   input   [7:0]I_SW1,
   input   [7:0]I_SW2,
   input   [7:0]I_DIPSW,
   input   [7:0]I_VRAM_DB,

   output [15:0]O_MCPU_A,
   output  [7:0]WI_D,
	output [15:0]cpu_rom_addr,
   input   [7:0]cpu_rom_do,
   output       O_MCPU_RDn,
   output       O_MCPU_WRn,

   output  [9:0]O_DMAD_A,
   output  [7:0]O_DMAD_D,
   output       O_DMAD_CE,

   output       O_OBJ_RQn,
   output       O_OBJ_RDn,
   output       O_OBJ_WRn,
   output       O_VRAM_RDn,
   output       O_VRAM_WRn,
   output  [7:0]O_4C_Q,
   output  [7:0]O_2L_Q,
   output  [7:0]O_7M_Q,
   output  [7:0]O_7J_Q
);

//-----------------------
// Main CPU - Z80 (4MHz)
//-----------------------

wire   W_MCPU_WAITn;
wire   W_MCPU_RFSHn;
wire   W_MCPU_M1n;
wire   W_MCPU_NMIn;
wire   W_MCPU_MREQn;
wire   W_MCPU_RDn;  
wire   W_MCPU_WRn;
wire   [15:0]W_MCPU_A;

// INPUT DATA BUS
wire   [7:0]ZDO, ZDI;
assign WI_D = ZDI;

T80pa z80core(
	.RESET_n(I_MCPU_RESETn),
	.CLK(I_CLK_48M),
	.CEN_p(I_MCPU_CEN4Mp),
	.CEN_n(I_MCPU_CEN4Mn),
	.WAIT_n(W_MCPU_WAITn),
	.INT_n(1'b1),
	.NMI_n(W_MCPU_NMIn),
	.BUSRQ_n(),
	.BUSAK_n(),
	.M1_n(W_MCPU_M1n),
	.IORQ_n(),
	.MREQ_n(W_MCPU_MREQn),
	.RD_n(W_MCPU_RDn),
	.WR_n(W_MCPU_WRn),
	.RFSH_n(W_MCPU_RFSHn),
	.A(W_MCPU_A),
	.DI(ZDO),
	.DO(ZDI)
	);

assign O_MCPU_A    = W_MCPU_A;
assign O_MCPU_RDn  = W_MCPU_RDn;
assign O_MCPU_WRn  = W_MCPU_WRn;
assign cpu_rom_addr = W_MCPU_A;
// CPU Data Bus (Data In)
wire   [7:0]WO_D = W_MROM_DO | W_MRAM7B_DO | W_MRAM7A_DO | W_SW_DO | I_VRAM_DB;
assign ZDO = WO_D;

//------------------
// Address decoding
//------------------

wire  [3:0]W_MROM_CS_n;
wire  [1:0]W_MRAM_CS_n;

wire       W_OBJ_RQn;
wire       W_OBJ_RDn;
wire       W_OBJ_WRn;
wire       W_VRAM_RDn;
wire       W_VRAM_WRn;
wire       W_SW1_OEn;
wire       W_SW2_OEn;
wire       W_DIPSW_OEn;
wire  [7:0]W_4C_Q;
wire  [7:0]W_2L_Q;
wire  [7:0]W_7M_Q;
wire  [7:0]W_7J_Q;

mario_adec adec
(
   .I_CLK_48M(I_CLK_48M),
   .I_CEN_12M(I_CEN_12M),
   .I_CEN_4Mp(I_MCPU_CEN4Mp),
   .I_CEN_4Mn(I_MCPU_CEN4Mn),
   .I_RESET_n(I_MCPU_RESETn),
   .I_AB(W_MCPU_A),
   .I_DB(WI_D),
   .I_MREQ_n(W_MCPU_MREQn),
   .I_RFSH_n(W_MCPU_RFSHn),
   .I_RD_n(W_MCPU_RDn),
   .I_WR_n(W_MCPU_WRn),
   .I_VRAMBUSY_n(I_VRAMBUSY_n),
   .I_VBLK_n(I_VBLK_n),
   .O_WAIT_n(W_MCPU_WAITn),
   .O_NMI_n(W_MCPU_NMIn),
   
   .O_MROM_CSn(W_MROM_CS_n),
   .O_MRAM_CSn(W_MRAM_CS_n),

   .O_3J_G_n(/*W_3J_G_n*/),
   .O_OBJ_RQ_n(W_OBJ_RQn),
   .O_OBJ_RD_n(W_OBJ_RDn),
   .O_OBJ_WR_n(W_OBJ_WRn),
   .O_VRAM_RD_n(W_VRAM_RDn),
   .O_VRAM_WR_n(W_VRAM_WRn),
   .O_SW1_OE_n(W_SW1_OEn),
   .O_SW2_OE_n(W_SW2_OEn),
   .O_DIPSW_OE_n(W_DIPSW_OEn),
   .O_4C_Q(W_4C_Q), 
   .O_2L_Q(W_2L_Q),
   .O_7M_Q(W_7M_Q),
   .O_7J_Q(W_7J_Q)
);

assign O_OBJ_RQn     = W_OBJ_RQn;
assign O_OBJ_RDn     = W_OBJ_RDn;
assign O_OBJ_WRn     = W_OBJ_WRn;
assign O_VRAM_RDn    = W_VRAM_RDn;
assign O_VRAM_WRn    = W_VRAM_WRn;
assign O_4C_Q        = W_4C_Q;
assign O_2L_Q        = W_2L_Q;
assign O_7M_Q        = W_7M_Q;
assign O_7J_Q        = W_7J_Q;

//----------
// Main ROM
//----------

wire  [7:0]W_MROM_DO;

assign cpu_rom_addr = W_MCPU_A;

assign W_MROM_DO = 	(W_MROM_CS_n[0] == 1'b0 & W_MCPU_RDn == 1'b0) ? cpu_rom_do :
							(W_MROM_CS_n[1] == 1'b0 & W_MCPU_RDn == 1'b0) ? cpu_rom_do :
							(W_MROM_CS_n[2] == 1'b0 & W_MCPU_RDn == 1'b0) ? cpu_rom_do :
							(W_MROM_CS_n[3] == 1'b0 & W_MCPU_RDn == 1'b0) ? cpu_rom_do :
							8'h00;

//---------------------
// Main CPU RAM 7A, 7B
// 2 x 2KB (6116)
//---------------------

wire  [7:0]W_7B_DO;
reg   [7:0]W_MRAM7B_DO;

ram_2048_8 U_7B // 6000H - 67FFH
(
   .I_CLK(I_CLK_48M),
   .I_ADDR(W_MCPU_A[10:0]),
   .I_D(WI_D),
   .I_CE(~W_MRAM_CS_n[0]),
   .I_WE(~W_MCPU_WRn),
   .O_D(W_7B_DO)
);

wire  [7:0]W_7A_DO;
reg   [7:0]W_MRAM7A_DO;

ram_2048_8_8 U_7A // 6800H - 6FFFH
(
   // A Port
   .I_CLKA(I_CLK_48M),
   .I_ADDRA(W_MCPU_A[10:0]),
   .I_DA(WI_D),
   .I_CEA(~W_MRAM_CS_n[1]),
   .I_OEA(~W_MCPU_RDn),
   .I_WEA(~W_MCPU_WRn),
   .O_DA(W_7A_DO),

   // B Port - DMA port (read-only)
   .I_CLKB(I_CLK_48M),
   .I_ADDRB(W_DMAS_A),
   .I_DB(8'h00),
   .I_CEB(W_DMAS_CE),
   .I_OEB(1'b1),
   .I_WEB(1'b0),
   .O_DB(W_DMAS_D)
);

always@(posedge I_CLK_48M)
begin
   if (I_CEN_12M) begin
      W_MRAM7B_DO <= (W_MCPU_RDn == 1'b0 & W_MRAM_CS_n[0] == 1'b0) ? W_7B_DO : 8'h00;
      W_MRAM7A_DO <= (W_MCPU_RDn == 1'b0 & W_MRAM_CS_n[1] == 1'b0) ? W_7A_DO : 8'h00;
   end
end

//------------------------------------------
// Sprite DMA
// transfers $180 bytes from $6900 to $7000
//------------------------------------------

wire  [9:0]W_DMAS_A;
wire  [7:0]W_DMAS_D;
wire       W_DMAS_CE;
wire  [9:0]W_DMAD_A;
wire  [7:0]W_DMAD_D;
wire       W_DMAD_CE;

mario_dma sprite_dma
(
   .I_CLK_48M(I_CLK_48M),
   .I_CEN_4M(I_MCPU_CEN4Mn),
   .I_DMA_TRIG(W_2L_Q[5]),
   .I_DMA_DS(W_DMAS_D),

   .O_DMA_AS(W_DMAS_A),
   .O_DMA_CES(W_DMAS_CE),
   .O_DMA_AD(W_DMAD_A),
   .O_DMA_DD(W_DMAD_D),
   .O_DMA_CED(W_DMAD_CE)
);

assign O_DMAD_A  = W_DMAD_A;
assign O_DMAD_D  = W_DMAD_D;
assign O_DMAD_CE = W_DMAD_CE;

//---------------------------
// Inputs
// Controls and dip switches
//---------------------------

wire [7:0]W_SW_DO;

mario_inport inport
(
   .I_SW1(I_SW1),
   .I_SW2(I_SW2),
   .I_DIPSW(I_DIPSW),
   .I_SW1_OEn(W_SW1_OEn),
   .I_SW2_OEn(W_SW2_OEn),
   .I_DIPSW_OEn(W_DIPSW_OEn),

   .O_D(W_SW_DO)
);


endmodule

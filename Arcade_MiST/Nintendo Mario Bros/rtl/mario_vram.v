//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Video RAM (background tiles)
// Based on the Donkey Kong version by Katsumi Degawa.
//----------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
// H_CNT[0],H_CNT[1],H_CNT[2],H_CNT[3],H_CNT[4],H_CNT[5],H_CNT[6],H_CNT[7],H_CNT[8],H_CNT[9]  
//   1/2 H     1 H     2 H      4H       8H       16 H     32H      64 H     128 H   256 H
//-----------------------------------------------------------------------------------------
// V_CNT[0], V_CNT[1], V_CNT[2], V_CNT[3], V_CNT[4], V_CNT[5], V_CNT[6], V_CNT[7]  
//    1 V      2 V       4 V       8 V       16 V      32 V      64 V     128 V 
//-----------------------------------------------------------------------------------------
// VF_CNT[0],VF_CNT[1],VF_CNT[2],VF_CNT[3],VF_CNT[4],VF_CNT[5],VF_CNT[6],VF_CNT[7]  
//    1 VF     2 VF      4 VF      8 VF      16 VF     32 VF     64 VF    128 VF 
//-----------------------------------------------------------------------------------------

module mario_vram(
   input        I_CLK_48M,
   input        I_CEN_24Mp,
   input        I_CEN_24Mn,
   input   [9:0]I_AB,
   input   [7:0]I_DB,
   input        I_VRAM_WRn,
   input        I_VRAM_RDn,
   input        I_FLIP,
   input   [9:0]I_H_CNT,
   input        I_CMPBLK,
   input        I_VBLKn,
   input        I_VCKn,
   input        I_GFXBANK,
   input        I_VMOV,

   output     [7:0]O_DB,
   output reg [3:0]O_COL,
   output     [1:0]O_VID,
   output          O_VRAMBUSYn
);

//---------------------------------------------------
// Vertical scroll register
// Used to make screen bounce when POW block is used
//---------------------------------------------------

reg    [7:0]W_1E_Q;
reg    [7:0]W_1AC_Q;
wire   [7:0]W_1BD_Q = W_1E_Q[7:0]^{8{I_FLIP}};

always@(posedge I_CLK_48M)
begin
   if (I_CEN_24Mn) begin
      reg VCKnp, VBLKnp, VMOVp;
      VCKnp  <= I_VCKn;
      VBLKnp <= I_VBLKn;
      VMOVp  <= I_VMOV;

      if(I_VMOV && !VMOVp) W_1E_Q <= I_DB;
      
      if(I_VBLKn && !VBLKnp)
         W_1AC_Q <= W_1BD_Q; // Load
      else
         if(!VCKnp && I_VCKn)
            W_1AC_Q <= W_1AC_Q + 8'd1;
   end
end


wire   [7:0]W_VF_CNT = W_1AC_Q[7:0]^{8{I_FLIP}};

//-------------------------
// VRAM
// 2 x 2114 @ 3D, 3E (1KB)
//-------------------------

wire   [7:0]WI_DB = I_VRAM_WRn ? 8'h00: I_DB;
wire   [7:0]WO_DB;

assign O_DB       = I_VRAM_RDn ? 8'h00: WO_DB;

wire   [4:0]W_HF_CNT  = I_H_CNT[8:4]^{I_FLIP,I_FLIP,I_FLIP,I_FLIP,I_FLIP};
wire   [9:0]W_CNT_AB  = {W_VF_CNT[7:3],W_HF_CNT[4:0]};
wire   [9:0]W_VRAM_AB = I_CMPBLK ? W_CNT_AB : I_AB ;
wire        W_VRAM_CS = I_CMPBLK ? 1'b0     : I_VRAM_WRn & I_VRAM_RDn;
wire        W_2S4     = I_CMPBLK ? 1'b0     : 1'b1 ;

ram_1024_8 U_3DE(

   .I_CLK(I_CLK_48M),
   .I_ADDR(W_VRAM_AB), 
   .I_D(WI_DB),
   .I_CE(~W_VRAM_CS),
   .I_WE(~I_VRAM_WRn),
   .O_D(WO_DB)

);

reg    CLK_3K;

// TCOL 0-2 connections to 3K are numbered 
// in the wrong order on the schematics
reg    [3:0]TCOL;

always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn) begin
      reg CLK_3Kp, H_CNT0p;

      CLK_3K  <= ~(I_H_CNT[1]&I_H_CNT[2]&I_H_CNT[3]);
      CLK_3Kp <= CLK_3K;
      
      if (CLK_3Kp && !CLK_3K) TCOL <= {1'b1,WO_DB[7:5]};
      
      // Fix for timing issue
      H_CNT0p <= I_H_CNT[0];
      if (!H_CNT0p && I_H_CNT[0]) O_COL <= TCOL;
   end
end

//-------------------
// Video ROMs 3F, 3J
//-------------------

wire [11:0]W_VROM_AB = {I_GFXBANK,WO_DB[7:0],W_VF_CNT[2:0]};
wire [15:0]W_3FJ_DO;

//VID_ROM roms3FJ(I_CLK_48M, W_VROM_AB, 1'b0, W_3FJ_DO,
//                I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

gfx_3f gfx_3f(
	.clk(I_CLK_48M),
	.addr(W_VROM_AB),
	.data(W_3FJ_DO[15:8])
);

gfx_3j gfx_3j(
	.clk(I_CLK_48M),
	.addr(W_VROM_AB),
	.data(W_3FJ_DO[7:0])
);

//-------------------
// Shift register 2H
//-------------------

wire   W_2H_Qa, W_2H_Qh;

wire   [1:0]C_2H = W_2K_Y[1:0];
wire   [7:0]W_2H = W_3FJ_DO[7:0];
reg    [7:0]reg_2H;

assign W_2H_Qa = reg_2H[7];
assign W_2H_Qh = reg_2H[0];
   
//-------------------
// Shift register 2J
//-------------------

wire   W_2J_Qa, W_2J_Qh;

wire   [1:0]C_2J = W_2K_Y[1:0];
wire   [7:0]W_2J = W_3FJ_DO[15:8];
reg    [7:0]reg_2J;

assign W_2J_Qa = reg_2J[7];
assign W_2J_Qh = reg_2J[0];

always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mp) begin
      reg H_CNT0p;
      H_CNT0p <= I_H_CNT[0];

      if (!H_CNT0p && I_H_CNT[0]) begin
         case(C_2H)
            2'b00: reg_2H <= reg_2H;
            2'b10: reg_2H <= {reg_2H[6:0],1'b0};
            2'b01: reg_2H <= {1'b0,reg_2H[7:1]};
            2'b11: reg_2H <= W_2H;
         endcase

         case(C_2J)
            2'b00: reg_2J <= reg_2J;
            2'b10: reg_2J <= {reg_2J[6:0],1'b0};
            2'b01: reg_2J <= {1'b0,reg_2J[7:1]};
            2'b11: reg_2J <= W_2J;
         endcase
      end
   end
end

//---------
// Part 2K
//---------

wire   [3:0]W_2K_a,W_2K_b;
wire   [3:0]W_2K_Y;

assign W_2K_a = {W_2H_Qa,W_2J_Qa,1'b1,~(CLK_3K|W_2S4)};
assign W_2K_b = {W_2H_Qh,W_2J_Qh,~(CLK_3K|W_2S4),1'b1};
assign W_2K_Y = I_FLIP ? W_2K_b : W_2K_a;

assign O_VID[0] = W_2K_Y[2];
assign O_VID[1] = W_2K_Y[3];

//------------------
// VRAM BUSY signal
//------------------

reg    W_VRAMBUSY;

always@(posedge I_CLK_48M)
begin
   if (I_CEN_24Mp) begin
      reg last_HCNT2;
      last_HCNT2 <= I_H_CNT[2];

      if(I_H_CNT[9] == 1'b0)
         W_VRAMBUSY <= 1'b1;
      else if (I_H_CNT[2] && !last_HCNT2)
         W_VRAMBUSY <= I_H_CNT[4]&I_H_CNT[5]&I_H_CNT[6]&I_H_CNT[7];
   end
end

assign O_VRAMBUSYn = ~W_VRAMBUSY;


endmodule

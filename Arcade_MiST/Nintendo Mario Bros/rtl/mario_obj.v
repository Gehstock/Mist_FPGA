//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Objects (sprites)
// Based on the Donkey Kong version by Katsumi Degawa.
//----------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
// H_CNT[0],H_CNT[1],H_CNT[2],H_CNT[3],H_CNT[4],H_CNT[5],H_CNT[6],H_CNT[7],H_CNT[8],H_CNT[9]  
//   1/2H      1H       2H       4H       8H      16H      32H      64H      128H     256H
//-----------------------------------------------------------------------------------------
// V_CNT[0],V_CNT[1],V_CNT[2],V_CNT[3],V_CNT[4],V_CNT[5],V_CNT[6],V_CNT[7]  
//    1V       2V       4V       8V      16V      32V      64V      128V 
//-----------------------------------------------------------------------------------------
// VF_CNT[0],VF_CNT[1],VF_CNT[2],VF_CNT[3],VF_CNT[4],VF_CNT[5],VF_CNT[6],VF_CNT[7]  
//    1 VF     2 VF      4 VF      8 VF      16 VF     32 VF     64 VF    128 VF 
//-----------------------------------------------------------------------------------------

module mario_obj
(
   input        I_CLK_48M,
   input        I_CEN_24Mp,
   input        I_CEN_24Mn,
   input        I_CEN_12M,
   input   [9:0]I_AB,
   input   [7:0]I_DB,
   //input   [7:0]I_OBJ_D,
   input        I_OBJ_WRn,
   input        I_OBJ_RDn,
   input        I_OBJ_RQn,
   input        I_2PSL,
   input        I_FLIPn,
   input        I_CMPBLKn,
   input   [9:0]I_H_CNT,
   input   [7:0]I_VF_CNT,
   input   [9:0]I_OBJ_DMA_A,
   input   [7:0]I_OBJ_DMA_D,
   input        I_OBJ_DMA_CE,
   output  [7:0]O_DB, // Not used
   output  [6:0]O_OBJ_DO,
   output       O_FLIP_VRAM,
   output       O_FLIP_HV,
   output       O_L_CMPBLKn
);

reg [1:0] cnt;
always@(posedge I_CLK_48M) begin
   cnt <= cnt + 1'd1;
end
wire I_CLK_12M; // as data not clock
assign I_CLK_12M = (cnt == 0) || (cnt == 1);


// Add a bit delay to make it work correctly
reg I_CMPBLKn_delayed;
always@(posedge I_CLK_48M) begin
   I_CMPBLKn_delayed <=  I_CMPBLKn;
end

//------------
// Part 6P(1)
//------------

reg    W_6P1;
always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn) begin
      W_6P1 <= ~(I_H_CNT[0]&I_H_CNT[1]&I_H_CNT[2]&I_H_CNT[3]);
   end
end

//-----------------
// Part 4K (LS139)
//-----------------

wire   W_4K1_G = ~(I_H_CNT[0]&I_H_CNT[1]&I_H_CNT[2]&I_H_CNT[3]);

wire   [3:0]W_4K1_Q;
wire   [3:0]W_4K2_QB;

logic_74xx139 U_4K1
(
   .I_G(W_4K1_G),
   .I_Sel({~I_H_CNT[9],I_H_CNT[3]}),
   .O_Q(W_4K1_Q)

);

// The outputs from this are wired
// differently from DK, DKJ and DK3.
logic_74xx139 U_4K2
(
   .I_G(1'b0),
   .I_Sel({I_H_CNT[3],I_H_CNT[2]}),
   .O_Q(W_4K2_QB)
);

reg    [3:0]W_4K2_Q;
always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn) begin
      W_4K2_Q <= W_4K2_QB;
   end
end

//------
// Flip
//------

wire   W_FLIP_1  = ~I_FLIPn;                 // INV  
wire   W_FLIP_2  =  W_FLIP_1 ^ 1'b1;         // INV => XOR
wire   W_FLIP_3  = ~W_FLIP_2;                // INV => XOR => INV 
wire   W_FLIP_4  =  W_FLIP_3 | W_4K2_Q[0];
wire   W_FLIP_5  = ~W_FLIP_4;

assign O_FLIP_VRAM = W_FLIP_1;
assign O_FLIP_HV   = W_FLIP_3;

//------------
// DB CONTROL
//------------

wire   [7:0]WI_DB = I_OBJ_WRn ? 8'h00: I_DB;
wire   [7:0]WO_DB;
//assign O_DB       = I_OBJ_RDn ? 8'h00: WO_DB;

//------------------------------------------------
// Object RAM 8B, 8C
// 2 x 2148 (1KB)
// Sprite data is written to these RAM's via DMA.
//------------------------------------------------

wire   [9:0]W_OBJ_AB = {I_2PSL, I_H_CNT[8:0]};
wire   [7:0]W_OBJ_DI;

ram_1024_8_8 U_8BC
(
   // A Port - DMA port (write) 
   .I_CLKA(I_CLK_48M),
   .I_ADDRA(I_OBJ_DMA_A),
   .I_DA(I_OBJ_DMA_D),
   .I_CEA(I_OBJ_DMA_CE),
   .I_WEA(1'b1),
   .O_DA(),

   // B Port (read)
   .I_CLKB(I_CLK_48M),
   .I_ADDRB(W_OBJ_AB[9:0]),
   .I_DB(8'h00),
   .I_CEB(1'b1),
   .I_WEB(1'b0),
   .O_DB(W_OBJ_DI)
);

//------------
// AB CONTROL
//------------

wire        W_AB_SEL = I_OBJ_WRn & I_OBJ_RDn & I_OBJ_RQn;
wire   [9:0]W_obj_AB = W_AB_SEL ? {I_2PSL,I_H_CNT[8:0]} : I_AB ;
wire        W_obj_CS = W_AB_SEL ? 1'b0     : I_OBJ_WRn & I_OBJ_RDn;

//--------------
// VFC_CNT[7:0]
//--------------

reg  I_H_CNT9_q;
wire I_H_CNT9_fall = I_H_CNT9_q & ~I_H_CNT[9];
always@(posedge I_CLK_48M) begin
   I_H_CNT9_q <= I_H_CNT[9];
end

reg    [7:0]W_VFC_CNT;
always@(posedge I_CLK_48M) begin
   if (I_H_CNT9_fall) begin
      W_VFC_CNT <= I_VF_CNT; // 6J, 7J
   end
end

//-----------------
// Part 7D (LS273)
//-----------------

reg    [7:0]W_7D_Q;
always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn) begin
      if (I_CLK_12M == 1'b0)
         W_7D_Q <= W_OBJ_DI;
   end
end

//----------------------
// Parts 6E,7E,6F,7F
// 4-bit adders (LS283)
//----------------------

wire   [7:0]W_67E_A = W_7D_Q;
wire   [7:0]W_67E_B = {4'b1111,I_FLIPn,W_FLIP_1,W_FLIP_1,1'b1}; 
wire   [8:0]W_67E_Q = W_67E_A + W_67E_B + 8'b00000001;

wire   [7:0]W_67F_A = W_67E_Q[7:0];
wire   [7:0]W_67F_B = I_VF_CNT[7:0]; 
wire   [8:0]W_67F_Q = W_67F_A + W_67F_B;

//----

reg    W_5F;
always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn) begin
      if (I_CLK_12M)
         W_5F <= ~(W_67F_Q[7]&W_67F_Q[6]&W_67F_Q[5]&W_67F_Q[4]);
   end
end

reg    CLK_4F;
always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn) begin
      CLK_4F = ~(I_H_CNT[0] & (~I_H_CNT[1]));
   end
end
wire   W_5E = ~(W_5CD_Q[6] | W_5CD_Q[7]);
wire   W_4J = ~(I_H_CNT[2]&I_H_CNT[3]&I_H_CNT[4]&I_H_CNT[5]&I_H_CNT[6]&I_H_CNT[7]&I_H_CNT[8] & W_5E);

//---------------
//Part 4F (LS74)
//---------------

reg    W_4F_Q;
wire   W_RST_4F = ~I_H_CNT[9];

reg  CLK_4F_q;
wire CLK_4F_rise = ~CLK_4F_q & CLK_4F;
always@(posedge I_CLK_48M) begin
   CLK_4F_q <= CLK_4F;
end

always@(posedge I_CLK_48M or negedge W_RST_4F)
begin
	if(W_RST_4F == 0)     W_4F_Q <= 1'b0;
   else if (CLK_4F_rise) W_4F_Q <= ~(W_5F & W_4J);
end

//-----------------
// Counters 5C, 5D
//-----------------

wire   CLK_5CD = ~(I_CLK_12M & (~I_H_CNT[9]) & W_4F_Q & W_5E);
wire   W_5CD_RST = ~I_H_CNT[9];
reg    [7:0]W_5CD_Q;

reg  CLK_5CD_q;
wire CLK_5CD_rise = ~CLK_5CD_q & CLK_5CD;
always@(posedge I_CLK_48M) begin
   CLK_5CD_q <= CLK_5CD;
end

always@(posedge I_CLK_48M or negedge W_5CD_RST)
begin
   if(W_5CD_RST == 1'b0)  W_5CD_Q <= 0;
   else if (CLK_5CD_rise) W_5CD_Q <= W_5CD_Q + 1'd1;
end

//---------
// Part 8D
//---------

reg    [7:0]W_8D_Q;
always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn) begin
      if (I_CLK_12M == 1'b0)
         W_8D_Q <= W_7D_Q;
   end
end

//----------------------------------------------------
// RAM 8E
// 64 x 9 bits bipolar RAM with inverted O/C outputs.
// A LS240 is used to re-invert the outputs.
//----------------------------------------------------

wire   [5:0]W_RAM_8E_AB   = ~I_H_CNT[9] ? W_5CD_Q[5:0] : I_H_CNT[7:2];
wire   [8:0]W_RAM_8E_DIB  = {W_8D_Q[7:0],W_4J};
wire   [8:0]W_RAM_8E_DOB;

ram_64_9 U_8E
(
   .I_CLKA(I_CLK_48M),
   .I_ADDRA(W_RAM_8E_AB),
   .I_DA(W_RAM_8E_DIB),
   .I_CEA(1'b1),
   .I_WEA(~CLK_5CD),
   .O_DA(W_RAM_8E_DOB)
);

reg    [7:0]W_HD;
always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn)
      W_HD <= W_RAM_8E_DOB[8:1]; // Not on the schematics?
end

// Add a bit delay to make it work correctly
reg [8:0] W_RAM_8E_DOB_delayed;
always@(posedge I_CLK_48M) begin
   W_RAM_8E_DOB_delayed <= W_RAM_8E_DOB;
end

//----------------------
// Parts 6K,7K,6L,7L
// 4-bit adders (LS283)
//----------------------

wire   [7:0]W_67K_A = W_RAM_8E_DOB_delayed[8:1];
wire   [7:0]W_67K_B = {4'b1111,W_FLIP_5,W_FLIP_4,W_FLIP_4,1'b1}; 
wire   [8:0]W_67K_Q = W_67K_A + W_67K_B + 8'b00000001;

wire   [7:0]W_67L_A = W_67K_Q[7:0];
wire   [7:0]W_67L_B = W_VFC_CNT[7:0]; 
wire   [8:0]W_67L_Q = W_67L_A + W_67L_B;

//-------------------
// Part 6M (LS273)
//-------------------

wire   [7:0]W_6M_D  = W_67L_Q[7:0];
reg    [7:0]W_6M_Q;
reg  W_4K2_Q0_q;
wire W_4K2_Q0_rise = ~W_4K2_Q0_q & W_4K2_Q[0];
always@(posedge I_CLK_48M) begin
   W_4K2_Q0_q <= W_4K2_Q[0];
end

always@(posedge I_CLK_48M) begin
   if (W_4K2_Q0_rise)
      W_6M_Q <= W_6M_D;
end

//-------------------
// Part 8J (LS273)
//-------------------

reg    [7:0]W_8J_Q;

reg  W_4K2_Q1_q;
wire W_4K2_Q1_rise = ~W_4K2_Q1_q & W_4K2_Q[1];
always@(posedge I_CLK_48M) begin
   W_4K2_Q1_q <= W_4K2_Q[1];
end

always@(posedge I_CLK_48M) begin
   if (W_4K2_Q1_rise)
      W_8J_Q <= W_HD[7:0];
end

//-------------------
// Part 6R (LS377)
//-------------------

wire   [7:0]W_6R_D = {W_8J_Q[7],I_CMPBLKn_delayed,~I_H_CNT[9],
                      ~(I_H_CNT[9]|W_FLIP_2),W_8J_Q[3:0]};
reg    [7:0]W_6R_Q;

always@(posedge I_CLK_48M)
begin
   if (I_CEN_12M) begin
      if(W_6P1 == 1'b0)
         W_6R_Q <= W_6R_D;
      else
         W_6R_Q <= W_6R_Q;
   end
end

assign O_L_CMPBLKn = W_6R_Q[6];

//---------------
// Part 3M
// J-K flip flop
//---------------

wire   W_3M_Q;

logic_74xx109 U_3M
(	
	.FAST_CLK(I_CLK_48M),
   .CLK(W_4K2_Q[0]),
   .RST(I_H_CNT[9]),
   .I_J(~W_RAM_8E_DOB[0]),
   .I_K(1'b1),
   .O_Q(W_3M_Q)
);

wire   W_6P2 = ~(W_6M_Q[4]&W_6M_Q[5]&W_6M_Q[6]&W_6M_Q[7]);
wire   W_4L  = W_3M_Q | W_6P2;
wire   W_6S  = ~(W_4L | W_6P1);

//-----------------
// Part 8K (LS373)
//-----------------

wire   W_8K_G = ~W_4K2_Q[2];
reg    [7:0]W_8K_Q;

always@(W_8K_G or W_HD[7:0])
begin
   if(W_8K_G) 
      W_8K_Q <= W_HD[7:0];
   else
      W_8K_Q <= W_8K_Q;
end

//------------------------
// Object ROMs (6 x 2732)
//------------------------

wire   [11:0]W_ROM_OBJ_AB;
assign W_ROM_OBJ_AB[3:0]  = W_6M_Q[3:0]^{W_8J_Q[6],W_8J_Q[6],W_8J_Q[6],W_8J_Q[6]};
assign W_ROM_OBJ_AB[11:4] = W_8K_Q;
wire [47:0]W_ROM_OBJ_D;

//OBJ_ROM objrom(I_CLK_48M, W_ROM_OBJ_AB, W_ROM_OBJ_D, 
//               I_CLK_48M, I_DLADDR, I_DLDATA, I_DLWR);

obj_7m obj_7m(
	.clk(I_CLK_48M),
	.addr(W_ROM_OBJ_AB),
	.data(W_ROM_OBJ_D[47:40])
);

obj_7n obj_7n(
	.clk(I_CLK_48M),
	.addr(W_ROM_OBJ_AB),
	.data(W_ROM_OBJ_D[39:32])
);

obj_7p obj_7p(
	.clk(I_CLK_48M),
	.addr(W_ROM_OBJ_AB),
	.data(W_ROM_OBJ_D[31:24])
);

obj_7s obj_7s(
	.clk(I_CLK_48M),
	.addr(W_ROM_OBJ_AB),
	.data(W_ROM_OBJ_D[23:16])
);

obj_7t obj_7t(
	.clk(I_CLK_48M),
	.addr(W_ROM_OBJ_AB),
	.data(W_ROM_OBJ_D[15:8])
);

obj_7u obj_7u(
	.clk(I_CLK_48M),
	.addr(W_ROM_OBJ_AB),
	.data(W_ROM_OBJ_D[7:0])
);

//-----------------------------
// Parts 8N, 8P
// Shift registers (2 x LS299)
//-----------------------------

wire   W_8N_Qa, W_8P_Qh;

wire   [1:0]C_8NP = W_8LM_Y[1:0];
wire  [15:0]W_8NP = W_ROM_OBJ_D[47:32];
reg   [15:0]reg_8NP;

assign W_8N_Qa = reg_8NP[15];
assign W_8P_Qh = reg_8NP[0];

always@(posedge I_CLK_48M)
begin
   if (I_CEN_12M) begin
      case(C_8NP)
         2'b00: reg_8NP <= reg_8NP;
         2'b10: reg_8NP <= {reg_8NP[14:0],1'b0};
         2'b01: reg_8NP <= {1'b0,reg_8NP[15:1]};
         2'b11: reg_8NP <= W_8NP;
      endcase
   end
end

//-----------------------------
// Parts 8R, 8S
// Shift registers (2 x LS299)
//-----------------------------

wire   W_8R_Qa, W_8S_Qh;

wire   [1:0]C_8RS = W_8LM_Y[1:0];
wire  [15:0]W_8RS = W_ROM_OBJ_D[31:16];
reg   [15:0]reg_8RS;

assign W_8R_Qa = reg_8RS[15];
assign W_8S_Qh = reg_8RS[0];

always@(posedge I_CLK_48M)
begin
   if (I_CEN_12M) begin
      case(C_8RS)
         2'b00: reg_8RS <= reg_8RS;
         2'b10: reg_8RS <= {reg_8RS[14:0],1'b0};
         2'b01: reg_8RS <= {1'b0,reg_8RS[15:1]};
         2'b11: reg_8RS <= W_8RS;
      endcase
   end
end

//-----------------------------
// Parts 8T, 8U
// Shift registers (2 x LS299)
//-----------------------------

wire   W_8T_Qa, W_8U_Qh;

wire   [1:0]C_8TU = W_8LM_Y[1:0];
wire  [15:0]W_8TU = W_ROM_OBJ_D[15:0];
reg   [15:0]reg_8TU;

assign W_8T_Qa = reg_8TU[15];
assign W_8U_Qh = reg_8TU[0];

always@(posedge I_CLK_48M)
begin
   if (I_CEN_12M) begin
      case(C_8TU)
         2'b00: reg_8TU <= reg_8TU;
         2'b10: reg_8TU <= {reg_8TU[14:0],1'b0};
         2'b01: reg_8TU <= {1'b0,reg_8TU[15:1]};
         2'b11: reg_8TU <= W_8TU;
      endcase
   end
end

//--------------
// Parts 8L, 8M
// 2 x LS157
//--------------

wire   [4:0]W_8LM_A, W_8LM_B, W_8LM_Y;

assign W_8LM_A = {W_8N_Qa,W_8R_Qa,W_8T_Qa,1'b1,W_6S};
assign W_8LM_B = {W_8P_Qh,W_8S_Qh,W_8U_Qh,W_6S,1'b1};
assign W_8LM_Y = W_6R_Q[7] ? W_8LM_B : W_8LM_A;

//--------------
// Parts 4M, 5M
// 2 x LS163
//--------------

reg    CLK_4M5M;

always@(posedge I_CLK_48M) begin
   if (I_CEN_24Mn)
      CLK_4M5M <= ~(~(I_H_CNT[0] & W_6R_Q[5]) & I_CLK_12M);
end

wire   [7:0]W_4M5M_DI = W_67K_Q[7:0];

wire   W_4M5M_RST = W_4K1_Q[3] | W_6R_Q[5];
wire   W_4M5M_LD  = W_4K1_Q[1];

reg    [7:0]W_4M5M_Q;

reg  CLK_4M5M_q;
wire CLK_4M5M_rise = ~CLK_4M5M_q & CLK_4M5M;
always@(posedge I_CLK_48M) begin
   CLK_4M5M_q <= CLK_4M5M;
end

always@(posedge I_CLK_48M)
begin
   if (CLK_4M5M_rise) begin
      if(W_4M5M_LD == 1'b0) 
         W_4M5M_Q <= W_4M5M_DI;
      else begin
         if(W_4M5M_RST == 1'b0)
            W_4M5M_Q <= 0 ;
         else     
            W_4M5M_Q <= W_4M5M_Q + 1'd1;
      end
   end
end

//-------------------------------
// ECL RAM (2 x 256x4bit) 3R, 3P
//-------------------------------

wire   [7:0]W_RAM_3RP_AB = W_4M5M_Q[7:0]^{8{W_6R_Q[4]}};

wire   [6:0]W_4S5S_A     = {W_6R_Q[3:0],W_8LM_Y[2],W_8LM_Y[3],W_8LM_Y[4]};
wire   [6:0]W_RAM_3RP_DI = W_6R_Q[5] ? 7'h00 :(W_8LM_Y[2]|W_8LM_Y[3]|W_8LM_Y[4])? W_4S5S_A : W_RAM_3RP_DO;
wire   [6:0]W_RAM_3RP_DO;

ram_256_8 U_3RP
(
   .I_CLKA(I_CLK_48M),
   .I_ADDRA(W_RAM_3RP_AB),
   .I_DA(W_RAM_3RP_DI),
   .I_CEA(1'b1),
   .I_WEA(~CLK_4M5M),
   .O_DA(W_RAM_3RP_DO)
);

//-----------------
// Part 4T (LS373)
//-----------------

reg    [6:0]W_OBJ_DO;

always@(posedge I_CLK_48M)
begin
   if (I_CEN_24Mp) begin
      if(~I_CLK_12M)
         W_OBJ_DO <= W_RAM_3RP_DO;
      else 
         W_OBJ_DO <= W_OBJ_DO ;
   end
end

assign O_OBJ_DO = W_OBJ_DO;


endmodule


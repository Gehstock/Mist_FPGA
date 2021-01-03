//===============================================================================
// FPGA DONKEY KONG OBJ
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
// 2004 -8-24  OBJ ROM REMOVED  K.Degawa
// 2005- 2- 9 	The description of the ROM was changed.
//             Data on the ROM are initialized at the time of the start. 
//================================================================================

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

module dkong_obj(
	input  				CLK_24M,
	input  				CLK_12M,
	input         CLK_12M_EN,
	input         I_PESTPLCE,
	input  		[9:0]	I_AB,
//	input  		[7:0]	I_DB,
	input  		[7:0]	I_OBJ_D,
	input  				I_OBJ_WRn,
	input  				I_OBJ_RDn,
	input  				I_OBJ_RQn,
	input  				I_2PSL,
	input  				I_FLIPn,
	input  				I_CMPBLKn,
	input  		[9:0]	I_H_CNT,
	input  		[7:0]	I_VF_CNT,
	output 		[7:0]	O_DB,
	output reg 	[5:0]	O_OBJ_DO,
	output 				O_FLIP_VRAM,
	output 				O_FLIP_HV,
	output 				O_L_CMPBLKn,

	input [15:0] DL_ADDR,
	input DL_WR,
	input [7:0] DL_DATA
	);

//---- Debug ---------
//--------------------

wire   W_5F1_G = ~(I_H_CNT[0]&I_H_CNT[1]&I_H_CNT[2]&I_H_CNT[3]);
reg    W_5B;
always@(negedge CLK_24M) W_5B <= ~(I_H_CNT[0]&I_H_CNT[1]&I_H_CNT[2]&I_H_CNT[3]);

wire   [3:0]W_5F1_Q;
wire   [3:0]W_5F2_QB;

logic_74xx139 U_5F1(
	.I_G(W_5F1_G),
	.I_Sel({~I_H_CNT[9],I_H_CNT[3]}),
	.O_Q(W_5F1_Q)
	);

logic_74xx139 U_5F2(
	.I_G(1'b0),
	.I_Sel({I_H_CNT[3],I_H_CNT[2]}),
	.O_Q(W_5F2_QB)
	);

reg    [3:0]W_5F2_Q;
always@(negedge CLK_24M) W_5F2_Q <= W_5F2_QB;

//----------  FLIP ----------------------------------------------------
wire   W_FLIP_1  = ~I_FLIPn;                          // INV  
wire   W_FLIP_2  =  W_FLIP_1 ^ 1'b1;                  // INV => XOR
wire   W_FLIP_3  = ~W_FLIP_2;                         // INV => XOR => INV 
wire   W_FLIP_4  =  W_FLIP_3 | W_5F2_Q[0];
wire   W_FLIP_5  = ~W_FLIP_4;

assign O_FLIP_VRAM = W_FLIP_1;
assign O_FLIP_HV   = W_FLIP_3;


//-------  AB CONTROL  ------------------------------------------------
//wire        W_AB_SEL = I_OBJ_WRn & I_OBJ_RDn & I_OBJ_RQn;
//wire   [9:0]W_obj_AB = W_AB_SEL ? {I_2PSL,I_H_CNT[8:0]} : I_AB ;
//wire        W_obj_CS = W_AB_SEL ? 1'b0     : I_OBJ_WRn & I_OBJ_RDn;

//-------  VFC_CNT[7:0] ------------------------------------------------
reg    [7:0]W_VFC_CNT;
always@(posedge CLK_24M) if (CLK_12M & I_H_CNT[9:0] == 10'b1011111111) W_VFC_CNT <= I_VF_CNT;

//------  PARTS 6N
reg    [7:0]W_6N_Q;
always@(posedge CLK_24M) if (CLK_12M_EN) W_6N_Q <= I_OBJ_D;

wire   [7:0]W_78R_A = W_6N_Q;
wire   [7:0]W_78R_B = {4'b1111,I_FLIPn,W_FLIP_1,W_FLIP_1,1'b1}; 

wire   [8:0]W_78R_Q = W_78R_A + W_78R_B + 8'b00000001;

wire   [7:0]W_78P_A = W_78R_Q[7:0];
wire   [7:0]W_78P_B = I_VF_CNT[7:0]; 

wire   [8:0]W_78P_Q = W_78P_A + W_78P_B;

reg    W_7H;
always@(posedge CLK_24M) if (CLK_12M) W_7H <= ~(W_78P_Q[7]&W_78P_Q[6]&W_78P_Q[5]&W_78P_Q[4]);

reg    [7:0]W_5L_Q;
reg    CLK_4L;
always@(negedge CLK_24M) CLK_4L = ~(I_H_CNT[0]&(~I_H_CNT[1]));

wire   W_6L = ~(W_5L_Q[6]|W_5L_Q[7]);
wire   W_3P = ~(I_H_CNT[2]&I_H_CNT[3]&I_H_CNT[4]&I_H_CNT[5]&I_H_CNT[6]&I_H_CNT[7]&I_H_CNT[8] & W_6L);

//-- U_4L ---------------

reg    W_4L_Q;
wire   RST_4L = ~I_H_CNT[9];
always@(posedge CLK_4L or negedge RST_4L)
begin
   if(RST_4L == 0) W_4L_Q <= 1'b0;
   else            W_4L_Q <= ~(W_7H&W_3P);
end

wire   CLK_5L = ~(CLK_12M&(~I_H_CNT[9])&W_4L_Q&W_6L);

wire   W_5L_RST = ~I_H_CNT[9];
always@(posedge CLK_5L or negedge W_5L_RST)
begin
   if(W_5L_RST == 1'b0) W_5L_Q <= 0;
   else                 W_5L_Q <= W_5L_Q + 1'b1;
end

//------  PARTS 6M  ----------------------------------------------
reg    [7:0]W_6M_Q;
always@(posedge CLK_24M) if (CLK_12M_EN) W_6M_Q <= W_6N_Q;
//----------------------------------------------------------------
wire   [5:0]W_RAM_7M_AB  = ~I_H_CNT[9] ? W_5L_Q[5:0]:I_H_CNT[7:2];
wire   [8:0]W_RAM_7M_DIB = {W_6M_Q[7:0],W_3P};
wire   [8:0]W_RAM_7M_DOB;
wire   [8:0]W_RAM_7M_DOBn = W_RAM_7M_DOB[8:0];

reg    [7:0]W_HD;
always@(negedge CLK_24M) W_HD <= W_RAM_7M_DOBn[8:1];

wire   [7:0]W_78K_A = W_RAM_7M_DOBn[8:1];
wire   [7:0]W_78K_B = {4'b1111,W_FLIP_5,W_FLIP_4,W_FLIP_4,1'b1}; 

wire   [8:0]W_78K_Q = W_78K_A + W_78K_B + 8'b00000001;

wire   [7:0]W_78J_A = W_78K_Q[7:0];
wire   [7:0]W_78J_B = W_VFC_CNT[7:0]; 

wire   [8:0]W_78J_Q = W_78J_A + W_78J_B;
wire   [7:0]W_8H_D = W_78J_Q[7:0];

reg    [7:0]W_8H_Q;
always@(posedge W_5F2_Q[0]) W_8H_Q <= W_8H_D;

reg    [7:0]W_6J_Q;
always@(posedge W_5F2_Q[2]) W_6J_Q <= W_HD[7:0];

wire   [7:0]W_6K_D = !I_PESTPLCE ? 
	{W_6J_Q[7],I_CMPBLKn,~I_H_CNT[9],~(I_H_CNT[9]|W_FLIP_2),W_6J_Q[3:0]} :
	{W_6H_Q[7],I_CMPBLKn,~I_H_CNT[9],~(I_H_CNT[9]|W_FLIP_2),W_6H_Q[3:0]};

reg    [7:0]W_6K_Q;
always@(posedge CLK_24M)
if (CLK_12M_EN) begin
   if(W_5B == 1'b0) W_6K_Q <= W_6K_D;
   else             W_6K_Q <= W_6K_Q;
end

assign O_L_CMPBLKn = W_6K_Q[6];

wire   W_8N_Q;

logic_74xx109 U_8N(
	.CLK(W_5F2_Q[0]),
	.RST(I_H_CNT[9]),
	.I_J(~W_RAM_7M_DOBn[0]),
	.I_K(1'b1),
	.O_Q(W_8N_Q)
	);

wire   W_6F = ~(W_8H_Q[4]&W_8H_Q[5]&W_8H_Q[6]&W_8H_Q[7]);
wire   W_5J = W_8N_Q|W_6F;
wire   W_6L1 = ~(W_5J|W_5B);

//------  PARTS 6H  ----------------------------------------------       
wire   W_6H_G = ~W_5F2_Q[1];
reg    [7:0]W_6H_Q;
always@(W_6H_G or W_HD[7:0] or W_6H_Q)
begin
   if(W_6H_G)
      W_6H_Q <= W_HD[7:0];
   else
      W_6H_Q <= W_6H_Q;
end
//----------------------------------------------------------------

wire   [3:0]W_8B_A,W_8B_B,W_8B_Y;
wire   W_8C_Qa,W_8D_Qh;
wire   W_8E_Qa,W_8F_Qh;

//------  PARTS 8CD ---------------------------------------------- 
wire  [1:0]C_8CD  = W_8B_Y[1:0];
wire  [15:0]I_8CD = {W_OBJ_DO_7C,W_OBJ_DO_7D};
reg   [15:0]reg_8CD;

assign W_8C_Qa = reg_8CD[15];
assign W_8D_Qh = reg_8CD[0];
always@(posedge CLK_24M)
if (CLK_12M_EN) begin
   case(C_8CD)
      2'b00: reg_8CD <= reg_8CD;
      2'b10: reg_8CD <= {reg_8CD[14:0],1'b0};
      2'b01: reg_8CD <= {1'b0,reg_8CD[15:1]};
      2'b11: reg_8CD <= I_8CD;
   endcase
end

//------  PARTS 8EF ---------------------------------------------- 
wire  [1:0]C_8EF  = W_8B_Y[1:0];
wire  [15:0]I_8EF = {W_OBJ_DO_7E,W_OBJ_DO_7F};
reg   [15:0]reg_8EF;

assign W_8E_Qa = reg_8EF[15];
assign W_8F_Qh = reg_8EF[0];
always@(posedge CLK_24M)
if (CLK_12M_EN) begin
   case(C_8EF)
      2'b00: reg_8EF <= reg_8EF;
      2'b10: reg_8EF <= {reg_8EF[14:0],1'b0};
      2'b01: reg_8EF <= {1'b0,reg_8EF[15:1]};
      2'b11: reg_8EF <= I_8EF;
   endcase
end

//------  PARTS 8B  ----------------------------------------------
assign W_8B_A = {W_8C_Qa,W_8E_Qa,1'b1,W_6L1};
assign W_8B_B = {W_8D_Qh,W_8F_Qh,W_6L1,1'b1};

assign W_8B_Y = W_6K_Q[7] ? W_8B_B:W_8B_A;

//------  PARTS 3E & 4E  -----------------------------------------
reg    CLK_3E;
always@(negedge CLK_24M)
   CLK_3E <= ~(~(I_H_CNT[0]&W_6K_Q[5])& CLK_12M);
//wire CLK_3E = ~(~(I_H_CNT[0]&W_6K_Q[5])& CLK_12M);

wire   [7:0]W_3E_LD_DI = W_78K_Q[7:0];

wire   W_3E_RST = W_5F1_Q[3]|W_6K_Q[5];
wire   W_3E_LD  = W_5F1_Q[1];
reg    [7:0]W_3E_Q;
always@(posedge CLK_3E)
begin
   if(W_3E_LD == 1'b0) 
      W_3E_Q <= W_3E_LD_DI;
   else begin
      if(W_3E_RST == 1'b0) 
         W_3E_Q <= 0 ;
      else     
         W_3E_Q <= W_3E_Q +1'b1;
   end
end

wire   [5:0]W_RAM_2EH_DO;
wire   [5:0]W_3J_B       = {W_6K_Q[3:0],W_8B_Y[2],W_8B_Y[3]};

wire   [5:0]W_RAM_2EH_DI = W_6K_Q[5] ? 6'h00 :(W_8B_Y[2]|W_8B_Y[3])? W_3J_B: W_RAM_2EH_DO;

wire   [7:0]W_RAM_2EH_AB = W_3E_Q[7:0]^{8{W_6K_Q[4]}};

ram_2EH7M U_2EH_7M(
// 256_6
.I_CLKA(CLK_24M),
.I_ADDRA(W_RAM_2EH_AB),
.I_DA(W_RAM_2EH_DI),
.I_CEA(1'b1),
.I_WEA(~CLK_3E),
.O_DA(W_RAM_2EH_DO),
// 64_9
.I_CLKB(~CLK_24M),
.I_ADDRB(W_RAM_7M_AB),
.I_DB(W_RAM_7M_DIB),
.I_CEB(1'b1),
.I_WEB(~CLK_5L),
.O_DB(W_RAM_7M_DOB)

);

//------  PARTS 3K  ----------------------------------------------
always@(posedge CLK_24M)
begin
   if(~CLK_12M)
      O_OBJ_DO <= W_RAM_2EH_DO;
   else 
      O_OBJ_DO <= O_OBJ_DO ;
end

wire   [11:0]W_ROM_OBJ_AB = !I_PESTPLCE ? 
	{W_6J_Q[6],W_6H_Q[6:0],W_8H_Q[3:0]^{{4{W_6H_Q[7]}}}} :
	{W_6J_Q[7:0],W_8H_Q[3:0]^{4{W_6H_Q[6]}}};

wire   [7:0]W_OBJ_DO_7C,W_OBJ_DO_7D,W_OBJ_DO_7E,W_OBJ_DO_7F;

/*
obj1 obj1 (
	.clk(CLK_24M),
	.addr(W_ROM_OBJ_AB),
	.data(W_OBJ_DO_7C)
	);
*/
dpram #(12,8) obj1 (
	.clock_a(CLK_24M),
	.address_a(W_ROM_OBJ_AB),
	.q_a(W_OBJ_DO_7C),

	.clock_b(CLK_24M),
	.address_b(DL_ADDR[11:0]),
	.wren_b(DL_WR && DL_ADDR[15:12] == 4'hA),
	.data_b(DL_DATA)
	);
/*
obj2 obj2 (
	.clk(CLK_24M),
	.addr(W_ROM_OBJ_AB),
	.data(W_OBJ_DO_7D)
	);
*/
dpram #(12,8) obj2 (
	.clock_a(CLK_24M),
	.address_a(W_ROM_OBJ_AB),
	.q_a(W_OBJ_DO_7D),

	.clock_b(CLK_24M),
	.address_b(DL_ADDR[11:0]),
	.wren_b(DL_WR && DL_ADDR[15:12] == 4'hB),
	.data_b(DL_DATA)
	);
/*
obj3 obj3 (
	.clk(CLK_24M),
	.addr(W_ROM_OBJ_AB),
	.data(W_OBJ_DO_7E)
	);
*/
dpram #(12,8) obj3 (
	.clock_a(CLK_24M),
	.address_a(W_ROM_OBJ_AB),
	.q_a(W_OBJ_DO_7E),

	.clock_b(CLK_24M),
	.address_b(DL_ADDR[11:0]),
	.wren_b(DL_WR && DL_ADDR[15:12] == 4'hC),
	.data_b(DL_DATA)
	);
/*
obj4 obj4 (
	.clk(CLK_24M),
	.addr(W_ROM_OBJ_AB),
	.data(W_OBJ_DO_7F)
	);
*/
dpram #(12,8) obj4 (
	.clock_a(CLK_24M),
	.address_a(W_ROM_OBJ_AB),
	.q_a(W_OBJ_DO_7F),

	.clock_b(CLK_24M),
	.address_b(DL_ADDR[11:0]),
	.wren_b(DL_WR && DL_ADDR[15:12] == 4'hD),
	.data_b(DL_DATA)
	);
	
endmodule

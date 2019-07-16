//===============================================================================
// FPGA DONKEY KONG   COLOR_PALETE(XILINX EDITION)
//
// Version : 3.00
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
// 2005- 2- 9 	The description of the ROM was changed.
//              Data on the ROM are initialized at the time of the start.            
//================================================================================
module dkong_col_pal(
	input  CLK_6M,
	input  CLK_12M,
	input  [5:0]I_VRAM_D,
	input  [5:0]I_OBJ_D,
	input  I_CMPBLKn,
	input  I_5H_Q6,
	input  I_5H_Q7,
	output [2:0]O_R,
	output [2:0]O_G,
	output [1:0]O_B
	);


//-------  PARTS 3ML ------------------------------------
wire   [5:0]W_3ML_Y = (~(I_OBJ_D[0]|I_OBJ_D[1])) ? I_VRAM_D: I_OBJ_D;

//-------  PARTS 1EF ------------------------------------
wire   [9:0]W_1EF_D = {I_5H_Q7,I_5H_Q6,W_3ML_Y[5:0],W_3ML_Y[0]|W_3ML_Y[1],I_CMPBLKn};
reg    [9:0]W_1EF_Q;
wire   W_1EF_RST  =  I_CMPBLKn|W_1EF_Q[0];

always@(posedge CLK_6M or negedge W_1EF_RST)
begin
   if(W_1EF_RST == 1'b0) W_1EF_Q <= 1'b0;
   else                  W_1EF_Q <= W_1EF_D;
end   

//-------  PARTS 2EF ------------------------------------
wire   [3:0]W_2E_DO,W_2F_DO;

col1 rom2j(
	.clk(CLK_12M),
	.addr(W_1EF_Q[9:2]),
	.data(W_2F_DO)
);

col2 rom2k(
	.clk(CLK_12M),
	.addr(W_1EF_Q[9:2]),
	.data(W_2E_DO)
);


assign {O_R, O_G, O_B} = {~W_2F_DO, ~W_2E_DO};

endmodule






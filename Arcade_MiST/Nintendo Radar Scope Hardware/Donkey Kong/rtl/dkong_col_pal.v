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
	input  CLK_24M,
	input  CLK_6M_EN,
	input  I_DK3B,
	input  I_PESTPLCE,
	input  I_PALBNK,
	input  [5:0]I_VRAM_D,
	input  [5:0]I_OBJ_D,
	input  I_CMPBLKn,
	input  I_5H_Q6,
	input  I_5H_Q7,
	output [3:0]O_R,
	output [3:0]O_G,
	output [3:0]O_B,

	input [15:0] DL_ADDR,
	input DL_WR,
	input [7:0] DL_DATA
	);


//-------  PARTS 3ML ------------------------------------
wire   [5:0]W_3ML_Y = (~(I_OBJ_D[0]|I_OBJ_D[1])) ? I_VRAM_D: I_OBJ_D;

//-------  PARTS 1EF ------------------------------------
wire   [9:0]W_1EF_D = {I_5H_Q7,I_5H_Q6,W_3ML_Y[5:0],W_3ML_Y[0]|W_3ML_Y[1],I_CMPBLKn};
reg    [9:0]W_1EF_Q;
wire   W_1EF_RST  =  I_CMPBLKn|W_1EF_Q[0];

always@(posedge CLK_24M or negedge W_1EF_RST)
begin
   if(W_1EF_RST == 1'b0) W_1EF_Q <= 1'b0;
   else if(CLK_6M_EN)    W_1EF_Q <= W_1EF_D;
end   

//-------  PARTS 2EF ------------------------------------
wire   [7:0]W_2E_DO,W_2F_DO;
/*
col1 rom2j(
	.clk(CLK_24M),
	.addr(W_1EF_Q[9:2]),
	.data(W_2F_DO)
);
*/
dpram #(9,8) col1 (
	.clock_a(CLK_24M),
	.address_a(W_1EF_Q[9:2]),
	.q_a(W_2F_DO),

	.clock_b(CLK_24M),
	.address_b(DL_ADDR[7:0]),
	.wren_b(DL_WR && DL_ADDR[15:9] == {4'hF, 3'b001}),
	.data_b(DL_DATA)
	);
/*
col2 rom2k(
	.clk(CLK_24M),
	.addr(W_1EF_Q[9:2]),
	.data(W_2E_DO)
);
*/
dpram #(9,8) col2 (
	.clock_a(CLK_24M),
	.address_a(W_1EF_Q[9:2]),
	.q_a(W_2E_DO),

	.clock_b(CLK_24M),
	.address_b(DL_ADDR[7:0]),
	.wren_b(DL_WR && DL_ADDR[15:9] == {4'hF, 3'b000}),
	.data_b(DL_DATA)
	);

//assign {O_R, O_G, O_B} = I_DK3B ? {W_2F_DO, W_2E_DO} : ~{W_2F_DO[3:1], W_2F_DO[3], ~W_2E_DO};
assign O_R = I_DK3B ? W_2F_DO[7:4] : {4{I_PESTPLCE}} ^ ~{W_2F_DO[3:1], W_2F_DO[3]};
assign O_G = I_DK3B ? W_2F_DO[3:0] : {4{I_PESTPLCE}} ^ ~{W_2F_DO[0], W_2E_DO[3:2], W_2F_DO[0]};
assign O_B = I_DK3B ? W_2E_DO[3:0] : {4{I_PESTPLCE}} ^ ~{W_2E_DO[1:0], W_2E_DO[1:0]};

endmodule

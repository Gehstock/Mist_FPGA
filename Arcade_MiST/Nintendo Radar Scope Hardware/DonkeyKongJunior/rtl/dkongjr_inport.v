//===============================================================================
//
// Modified for Donkey Kong Junior by gaz68.
//
// FPGA DONKEY KONG  INPORT
//
// Version : 1.00
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
//================================================================================



module dkongjr_inport(

//  input
I_SW1,
I_SW2,
I_SW3,
I_DIP,
//  enable
I_SW1_OE_n,
I_SW2_OE_n,
I_SW3_OE_n,
I_DIP_OE_n,
//  output
O_D

);

//                       B0      B1      B2      B3      B4      B5      B6      B7
//-----------------------------------------------------------------------------------
//7C00(R)   sw1(MAIN)   RIGHT   LEFT     UP     DOWN    JUMP   
//7C80(R)   sw2(SUB)    RIGHT   LEFT     UP     DOWN    JUMP
//7D00(R)   sw3(    )                    1P      2P                             COIN
//7D80(R)   DIP       
//        JUMPMAN  3      0       0
//                 4      1       0
//                 5      0       1
//                 6      1       1
//        BONUS 10000                     0       0
//              15000                     1       0
//              20000                     0       1                     
//              25000                     1       1
//        COIN    1/1                                      0      0      0
//                1/2                                      0      1      0
//	               1/3                                      0      0      1
//                1/4                                      0      1      1
//                2/1                                      1      0      0
//                3/1                                      1      1      0
//                4/1                                      1      0      1
//                5/1                                      1      1      1
//        Table                                                                  0
//        Upright                                                                1
//  
input  [7:0]I_SW1,I_SW2,I_SW3,I_DIP;
input  I_SW1_OE_n,I_SW2_OE_n,I_SW3_OE_n,I_DIP_OE_n;   //   Active  LOW
output [7:0]O_D;

wire   [7:0]W_SW1 = I_SW1_OE_n ?  8'h00: ~I_SW1;
wire   [7:0]W_SW2 = I_SW2_OE_n ?  8'h00: !I_DIP[7] ? ~I_SW2 : ~I_SW1;
wire   [7:0]W_SW3 = I_SW3_OE_n ?  8'h00: ~I_SW3;
wire   [7:0]W_DIP = I_DIP_OE_n ?  8'h00:  I_DIP;


assign  O_D = W_SW1 | W_SW2 | W_SW3 | W_DIP;


endmodule
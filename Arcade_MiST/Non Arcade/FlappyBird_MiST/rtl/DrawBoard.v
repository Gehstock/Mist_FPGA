`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:58:48 04/26/2014 
// Design Name: 
// Module Name:    DrawBoard 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module DrawBoard(input [24:0] Clks,Reset,CounterX,CounterY,Button,Status,output reg R_Board_on,G_Board_on,B_Board_on,R_Board_off,G_Board_off,B_Board_off);

reg [15:0] ScoreBoardPositionX = 185;
reg [15:0] ScoreBoardPositionY = 120;

reg [15:0] ScoreTextPositionX = 287;
reg [15:0] ScoreTextPositionY = 150;

reg [15:0] BestTextPositionX = 295;
reg [15:0] BestTextPositionY = 255;

reg [15:0] ScorePositionX = 320;
reg [15:0] ScorePositionY = 285;

reg [15:0] LogoPositionX = 203;
reg [15:0] LogoPositionY = 140;

reg Start = 0;

reg [15:0] Name0PositionX = 210;
reg [15:0] Name0PositionY = 220;

reg [15:0] Name1PositionX = 210;
reg [15:0] Name1PositionY = 250;

reg [15:0] Name2PositionX = 210;
reg [15:0] Name2PositionY = 270;

reg [15:0] Name3PositionX = 210;
reg [15:0] Name3PositionY = 290;

reg ScoreBoardBlack,ScoreText,BestText,ScoreBoardWhite,BestBlackUnit,BestBlackTen,BestWhiteUnit,BestWhiteTen,LogoBlack,LogoWhite,LogoYellow,LogoGreen,Name0,Name1,Name2,Name3;

always @ (CounterX or CounterY)
begin

LogoWhite <= (CounterX>=LogoPositionX+0*3) && (CounterX<=LogoPositionX+22*3) && (CounterY>=LogoPositionY+0*3) && (CounterY<=LogoPositionY+1*3)

||          (CounterX>=LogoPositionX+47*3) && (CounterX<=LogoPositionX+62*3) && (CounterY>=LogoPositionY+0*3) && (CounterY<=LogoPositionY+1*3)
||          (CounterX>=LogoPositionX+71*3) && (CounterX<=LogoPositionX+78*3) && (CounterY>=LogoPositionY+0*3) && (CounterY<=LogoPositionY+1*3)

||          (CounterX>=LogoPositionX+0*3) && (CounterX<=LogoPositionX+1*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+19*3)

||          (CounterX>=LogoPositionX+2*3) && (CounterX<=LogoPositionX+5*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)

||          (CounterX>=LogoPositionX+1*3) && (CounterX<=LogoPositionX+7*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+19*3)

||          (CounterX>=LogoPositionX+5*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+6*3)
||          (CounterX>=LogoPositionX+5*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+11*3) && (CounterY<=LogoPositionY+12*3)
||          (CounterX>=LogoPositionX+6*3) && (CounterX<=LogoPositionX+7*3) && (CounterY>=LogoPositionY+13*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+7*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+13*3) && (CounterY<=LogoPositionY+14*3)
||          (CounterX>=LogoPositionX+8*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+14*3) && (CounterY<=LogoPositionY+19*3)

||          (CounterX>=LogoPositionX+2*3) && (CounterX<=LogoPositionX+4*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+3*3)
||          (CounterX>=LogoPositionX+11*3) && (CounterX<=LogoPositionX+13*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+3*3)
||          (CounterX>=LogoPositionX+14*3) && (CounterX<=LogoPositionX+18*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+3*3)
||          (CounterX>=LogoPositionX+16*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+11*3) && (CounterY<=LogoPositionY+12*3)

||          (CounterX>=LogoPositionX+10*3) && (CounterX<=LogoPositionX+12*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+13*3) && (CounterX<=LogoPositionX+20*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+14*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+6*3)
||          (CounterX>=LogoPositionX+9*3) && (CounterX<=LogoPositionX+20*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+19*3)

||          (CounterX>=LogoPositionX+21*3) && (CounterX<=LogoPositionX+22*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+4*3)
||          (CounterX>=LogoPositionX+19*3) && (CounterX<=LogoPositionX+20*3) && (CounterY>=LogoPositionY+19*3) && (CounterY<=LogoPositionY+22*3)
||          (CounterX>=LogoPositionX+21*3) && (CounterX<=LogoPositionX+24*3) && (CounterY>=LogoPositionY+19*3) && (CounterY<=LogoPositionY+20*3)

||          (CounterX>=LogoPositionX+20*3) && (CounterX<=LogoPositionX+26*3) && (CounterY>=LogoPositionY+21*3) && (CounterY<=LogoPositionY+22*3)
||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+28*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+25*3) && (CounterX<=LogoPositionX+26*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+21*3)

||          (CounterX>=LogoPositionX+26*3) && (CounterX<=LogoPositionX+28*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+19*3)
||          (CounterX>=LogoPositionX+27*3) && (CounterX<=LogoPositionX+28*3) && (CounterY>=LogoPositionY+19*3) && (CounterY<=LogoPositionY+22*3)
||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+8*3) && (CounterY<=LogoPositionY+9*3)

||          (CounterX>=LogoPositionX+16*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+11*3) && (CounterY<=LogoPositionY+12*3)
||          (CounterX>=LogoPositionX+32*3) && (CounterX<=LogoPositionX+33*3) && (CounterY>=LogoPositionY+8*3) && (CounterY<=LogoPositionY+9*3)
||          (CounterX>=LogoPositionX+22*3) && (CounterX<=LogoPositionX+45*3) && (CounterY>=LogoPositionY+3*3) && (CounterY<=LogoPositionY+4*3)

||          (CounterX>=LogoPositionX+29*3) && (CounterX<=LogoPositionX+32*3) && (CounterY>=LogoPositionY+19*3) && (CounterY<=LogoPositionY+20*3)
||          (CounterX>=LogoPositionX+28*3) && (CounterX<=LogoPositionX+34*3) && (CounterY>=LogoPositionY+21*3) && (CounterY<=LogoPositionY+22*3)
||          (CounterX>=LogoPositionX+33*3) && (CounterX<=LogoPositionX+34*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+21*3)

||          (CounterX>=LogoPositionX+32*3) && (CounterX<=LogoPositionX+36*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+34*3) && (CounterX<=LogoPositionX+36*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+19*3)
||          (CounterX>=LogoPositionX+35*3) && (CounterX<=LogoPositionX+36*3) && (CounterY>=LogoPositionY+19*3) && (CounterY<=LogoPositionY+22*3)

||          (CounterX>=LogoPositionX+36*3) && (CounterX<=LogoPositionX+40*3) && (CounterY>=LogoPositionY+14*3) && (CounterY<=LogoPositionY+15*3)
||          (CounterX>=LogoPositionX+37*3) && (CounterX<=LogoPositionX+43*3) && (CounterY>=LogoPositionY+19*3) && (CounterY<=LogoPositionY+20*3)
||          (CounterX>=LogoPositionX+36*3) && (CounterX<=LogoPositionX+44*3) && (CounterY>=LogoPositionY+21*3) && (CounterY<=LogoPositionY+22*3)

||          (CounterX>=LogoPositionX+44*3) && (CounterX<=LogoPositionX+45*3) && (CounterY>=LogoPositionY+4*3) && (CounterY<=LogoPositionY+22*3)

||          (CounterX>=LogoPositionX+47*3) && (CounterX<=LogoPositionX+48*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+19*3)
||          (CounterX>=LogoPositionX+61*3) && (CounterX<=LogoPositionX+70*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+2*3)
||          (CounterX>=LogoPositionX+69*3) && (CounterX<=LogoPositionX+70*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+4*3)
||          (CounterX>=LogoPositionX+70*3) && (CounterX<=LogoPositionX+72*3) && (CounterY>=LogoPositionY+3*3) && (CounterY<=LogoPositionY+4*3)
||          (CounterX>=LogoPositionX+71*3) && (CounterX<=LogoPositionX+72*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+3*3)

||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+53*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+6*3)
||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+53*3) && (CounterY>=LogoPositionY+11*3) && (CounterY<=LogoPositionY+12*3)
||          (CounterX>=LogoPositionX+55*3) && (CounterX<=LogoPositionX+56*3) && (CounterY>=LogoPositionY+8*3) && (CounterY<=LogoPositionY+9*3)
||          (CounterX>=LogoPositionX+57*3) && (CounterX<=LogoPositionX+60*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+6*3)

||          (CounterX>=LogoPositionX+49*3) && (CounterX<=LogoPositionX+56*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+57*3) && (CounterX<=LogoPositionX+60*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+61*3) && (CounterX<=LogoPositionX+64*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+48*3) && (CounterX<=LogoPositionX+66*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+19*3)

||          (CounterX>=LogoPositionX+65*3) && (CounterX<=LogoPositionX+68*3) && (CounterY>=LogoPositionY+9*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+65*3) && (CounterX<=LogoPositionX+66*3) && (CounterY>=LogoPositionY+11*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+66*3) && (CounterX<=LogoPositionX+68*3) && (CounterY>=LogoPositionY+11*3) && (CounterY<=LogoPositionY+12*3)
||          (CounterX>=LogoPositionX+67*3) && (CounterX<=LogoPositionX+68*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+19*3)

||          (CounterX>=LogoPositionX+72*3) && (CounterX<=LogoPositionX+73*3) && (CounterY>=LogoPositionY+9*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+69*3) && (CounterX<=LogoPositionX+76*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+68*3) && (CounterX<=LogoPositionX+78*3) && (CounterY>=LogoPositionY+18*3) && (CounterY<=LogoPositionY+19*3)
||          (CounterX>=LogoPositionX+77*3) && (CounterX<=LogoPositionX+78*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+18*3);

LogoBlack <= (CounterX>=LogoPositionX+1*3) && (CounterX<=LogoPositionX+21*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+2*3)

||          (CounterX>=LogoPositionX+1*3) && (CounterX<=LogoPositionX+2*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+2*3) && (CounterX<=LogoPositionX+6*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)

||          (CounterX>=LogoPositionX+5*3) && (CounterX<=LogoPositionX+6*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+6*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+13*3)
||          (CounterX>=LogoPositionX+9*3) && (CounterX<=LogoPositionX+10*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+10*3) && (CounterX<=LogoPositionX+20*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)

||          (CounterX>=LogoPositionX+13*3) && (CounterX<=LogoPositionX+14*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+6*3)
||          (CounterX>=LogoPositionX+5*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+6*3) && (CounterY<=LogoPositionY+7*3)
||          (CounterX>=LogoPositionX+12*3) && (CounterX<=LogoPositionX+13*3) && (CounterY>=LogoPositionY+7*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+16*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+13*3)

||          (CounterX>=LogoPositionX+20*3) && (CounterX<=LogoPositionX+21*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+21*3)

||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+9*3) && (CounterY<=LogoPositionY+12*3)
||          (CounterX>=LogoPositionX+21*3) && (CounterX<=LogoPositionX+24*3) && (CounterY>=LogoPositionY+20*3) && (CounterY<=LogoPositionY+21*3)
||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+21*3)
||          (CounterX>=LogoPositionX+25*3) && (CounterX<=LogoPositionX+28*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)

||          (CounterX>=LogoPositionX+21*3) && (CounterX<=LogoPositionX+44*3) && (CounterY>=LogoPositionY+4*3) && (CounterY<=LogoPositionY+5*3)
||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+9*3) && (CounterY<=LogoPositionY+12*3)

||          (CounterX>=LogoPositionX+21*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+20*3) && (CounterY<=LogoPositionY+21*3)
||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+20*3)
||          (CounterX>=LogoPositionX+25*3) && (CounterX<=LogoPositionX+28*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)

||          (CounterX>=LogoPositionX+28*3) && (CounterX<=LogoPositionX+29*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+21*3)

||          (CounterX>=LogoPositionX+29*3) && (CounterX<=LogoPositionX+33*3) && (CounterY>=LogoPositionY+20*3) && (CounterY<=LogoPositionY+21*3)
||          (CounterX>=LogoPositionX+32*3) && (CounterX<=LogoPositionX+33*3) && (CounterY>=LogoPositionY+9*3) && (CounterY<=LogoPositionY+12*3)
||          (CounterX>=LogoPositionX+32*3) && (CounterX<=LogoPositionX+33*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+20*3)
||          (CounterX>=LogoPositionX+33*3) && (CounterX<=LogoPositionX+36*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)

||          (CounterX>=LogoPositionX+35*3) && (CounterX<=LogoPositionX+36*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+36*3) && (CounterX<=LogoPositionX+40*3) && (CounterY>=LogoPositionY+15*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+36*3) && (CounterX<=LogoPositionX+37*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+21*3)

||          (CounterX>=LogoPositionX+37*3) && (CounterX<=LogoPositionX+43*3) && (CounterY>=LogoPositionY+20*3) && (CounterY<=LogoPositionY+21*3)
||          (CounterX>=LogoPositionX+43*3) && (CounterX<=LogoPositionX+44*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+21*3)

||          (CounterX>=LogoPositionX+48*3) && (CounterX<=LogoPositionX+61*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+2*3)
||          (CounterX>=LogoPositionX+48*3) && (CounterX<=LogoPositionX+49*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+48*3) && (CounterX<=LogoPositionX+65*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)

||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+53*3) && (CounterY>=LogoPositionY+6*3) && (CounterY<=LogoPositionY+7*3)
||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+53*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+13*3)
||          (CounterX>=LogoPositionX+55*3) && (CounterX<=LogoPositionX+56*3) && (CounterY>=LogoPositionY+9*3) && (CounterY<=LogoPositionY+10*3)

||          (CounterX>=LogoPositionX+56*3) && (CounterX<=LogoPositionX+57*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+17*3)
||          (CounterX>=LogoPositionX+57*3) && (CounterX<=LogoPositionX+60*3) && (CounterY>=LogoPositionY+6*3) && (CounterY<=LogoPositionY+7*3)
||          (CounterX>=LogoPositionX+60*3) && (CounterX<=LogoPositionX+61*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+17*3)

||          (CounterX>=LogoPositionX+61*3) && (CounterX<=LogoPositionX+69*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+3*3)
||          (CounterX>=LogoPositionX+68*3) && (CounterX<=LogoPositionX+69*3) && (CounterY>=LogoPositionY+3*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+64*3) && (CounterX<=LogoPositionX+65*3) && (CounterY>=LogoPositionY+7*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+61*3) && (CounterX<=LogoPositionX+64*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+65*3) && (CounterX<=LogoPositionX+68*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+11*3)

||          (CounterX>=LogoPositionX+69*3) && (CounterX<=LogoPositionX+73*3) && (CounterY>=LogoPositionY+4*3) && (CounterY<=LogoPositionY+5*3)
||          (CounterX>=LogoPositionX+72*3) && (CounterX<=LogoPositionX+73*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+4*3)
||          (CounterX>=LogoPositionX+73*3) && (CounterX<=LogoPositionX+77*3) && (CounterY>=LogoPositionY+1*3) && (CounterY<=LogoPositionY+2*3)
||          (CounterX>=LogoPositionX+76*3) && (CounterX<=LogoPositionX+77*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+72*3) && (CounterX<=LogoPositionX+73*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+13*3)
||          (CounterX>=LogoPositionX+69*3) && (CounterX<=LogoPositionX+76*3) && (CounterY>=LogoPositionY+17*3) && (CounterY<=LogoPositionY+18*3)
||          (CounterX>=LogoPositionX+12*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+6*3) && (CounterY<=LogoPositionY+7*3)
||          (CounterX>=LogoPositionX+39*3) && (CounterX<=LogoPositionX+40*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3) ;

LogoYellow <= (CounterX>=LogoPositionX+2*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+5*3)

||          (CounterX>=LogoPositionX+2*3) && (CounterX<=LogoPositionX+5*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+7*3)   
||          (CounterX>=LogoPositionX+2*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+7*3) && (CounterY<=LogoPositionY+10*3)

||          (CounterX>=LogoPositionX+10*3) && (CounterX<=LogoPositionX+12*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+12*3) && (CounterX<=LogoPositionX+13*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+14*3) && (CounterX<=LogoPositionX+20*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+5*3)
||          (CounterX>=LogoPositionX+17*3) && (CounterX<=LogoPositionX+20*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+13*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+7*3) && (CounterY<=LogoPositionY+10*3)

||          (CounterX>=LogoPositionX+21*3) && (CounterX<=LogoPositionX+24*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+8*3)
||          (CounterX>=LogoPositionX+25*3) && (CounterX<=LogoPositionX+28*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)

||          (CounterX>=LogoPositionX+29*3) && (CounterX<=LogoPositionX+32*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+32*3) && (CounterX<=LogoPositionX+33*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+8*3)
||          (CounterX>=LogoPositionX+33*3) && (CounterX<=LogoPositionX+35*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)

||          (CounterX>=LogoPositionX+36*3) && (CounterX<=LogoPositionX+39*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+40*3) && (CounterX<=LogoPositionX+43*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)

||          (CounterX>=LogoPositionX+49*3) && (CounterX<=LogoPositionX+52*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+56*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+5*3)
||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+55*3) && (CounterY>=LogoPositionY+7*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+53*3) && (CounterX<=LogoPositionX+56*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+7*3)
||          (CounterX>=LogoPositionX+55*3) && (CounterX<=LogoPositionX+56*3) && (CounterY>=LogoPositionY+7*3) && (CounterY<=LogoPositionY+8*3)

||          (CounterX>=LogoPositionX+57*3) && (CounterX<=LogoPositionX+60*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+5*3)
||          (CounterX>=LogoPositionX+57*3) && (CounterX<=LogoPositionX+60*3) && (CounterY>=LogoPositionY+7*3) && (CounterY<=LogoPositionY+10*3)

||          (CounterX>=LogoPositionX+61*3) && (CounterX<=LogoPositionX+64*3) && (CounterY>=LogoPositionY+3*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+64*3) && (CounterX<=LogoPositionX+65*3) && (CounterY>=LogoPositionY+3*3) && (CounterY<=LogoPositionY+7*3)
||          (CounterX>=LogoPositionX+65*3) && (CounterX<=LogoPositionX+68*3) && (CounterY>=LogoPositionY+3*3) && (CounterY<=LogoPositionY+9*3)

||          (CounterX>=LogoPositionX+69*3) && (CounterX<=LogoPositionX+72*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+72*3) && (CounterX<=LogoPositionX+73*3) && (CounterY>=LogoPositionY+5*3) && (CounterY<=LogoPositionY+9*3)
||          (CounterX>=LogoPositionX+73*3) && (CounterX<=LogoPositionX+76*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+10*3)
||          (CounterX>=LogoPositionX+12*3) && (CounterX<=LogoPositionX+13*3) && (CounterY>=LogoPositionY+2*3) && (CounterY<=LogoPositionY+6*3) ;


LogoGreen <= (CounterX>=LogoPositionX+2*3) && (CounterX<=LogoPositionX+5*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+5*3) && (CounterX<=LogoPositionX+9*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+11*3)
||          (CounterX>=LogoPositionX+10*3) && (CounterX<=LogoPositionX+12*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+13*3) && (CounterX<=LogoPositionX+16*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+17*3) && (CounterX<=LogoPositionX+20*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+16*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+13*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+16*3) && (CounterX<=LogoPositionX+17*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+11*3) 

||          (CounterX>=LogoPositionX+21*3) && (CounterX<=LogoPositionX+24*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+19*3)
||          (CounterX>=LogoPositionX+24*3) && (CounterX<=LogoPositionX+25*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+25*3) && (CounterX<=LogoPositionX+28*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+29*3) && (CounterX<=LogoPositionX+32*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+19*3)
||          (CounterX>=LogoPositionX+32*3) && (CounterX<=LogoPositionX+33*3) && (CounterY>=LogoPositionY+12*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+33*3) && (CounterX<=LogoPositionX+35*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+36*3) && (CounterX<=LogoPositionX+43*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+14*3)
||          (CounterX>=LogoPositionX+40*3) && (CounterX<=LogoPositionX+43*3) && (CounterY>=LogoPositionY+14*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+37*3) && (CounterX<=LogoPositionX+43*3) && (CounterY>=LogoPositionY+16*3) && (CounterY<=LogoPositionY+19*3)

||          (CounterX>=LogoPositionX+49*3) && (CounterX<=LogoPositionX+52*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+53*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+11*3)
||          (CounterX>=LogoPositionX+53*3) && (CounterX<=LogoPositionX+56*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+52*3) && (CounterX<=LogoPositionX+53*3) && (CounterY>=LogoPositionY+13*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+57*3) && (CounterX<=LogoPositionX+60*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+61*3) && (CounterX<=LogoPositionX+64*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)

||          (CounterX>=LogoPositionX+69*3) && (CounterX<=LogoPositionX+72*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+73*3) && (CounterX<=LogoPositionX+76*3) && (CounterY>=LogoPositionY+10*3) && (CounterY<=LogoPositionY+16*3)
||          (CounterX>=LogoPositionX+72*3) && (CounterX<=LogoPositionX+73*3) && (CounterY>=LogoPositionY+13*3) && (CounterY<=LogoPositionY+16*3);



ScoreBoardBlack <= (CounterX>=ScoreBoardPositionX+4*3) && (CounterX<=ScoreBoardPositionX+86*3) && (CounterY>=ScoreBoardPositionY+0*3) && (CounterY<=ScoreBoardPositionY+1*3)
||          (CounterX>=ScoreBoardPositionX+2*3) && (CounterX<=ScoreBoardPositionX+4*3) && (CounterY>=ScoreBoardPositionY+1*3) && (CounterY<=ScoreBoardPositionY+2*3)
||          (CounterX>=ScoreBoardPositionX+86*3) && (CounterX<=ScoreBoardPositionX+88*3) && (CounterY>=ScoreBoardPositionY+1*3) && (CounterY<=ScoreBoardPositionY+2*3)
||          (CounterX>=ScoreBoardPositionX+1*3) && (CounterX<=ScoreBoardPositionX+2*3) && (CounterY>=ScoreBoardPositionY+2*3) && (CounterY<=ScoreBoardPositionY+4*3)
||          (CounterX>=ScoreBoardPositionX+88*3) && (CounterX<=ScoreBoardPositionX+89*3) && (CounterY>=ScoreBoardPositionY+2*3) && (CounterY<=ScoreBoardPositionY+4*3)
||          (CounterX>=ScoreBoardPositionX+0*3) && (CounterX<=ScoreBoardPositionX+1*3) && (CounterY>=ScoreBoardPositionY+4*3) && (CounterY<=ScoreBoardPositionY+76*3)
||          (CounterX>=ScoreBoardPositionX+89*3) && (CounterX<=ScoreBoardPositionX+90*3) && (CounterY>=ScoreBoardPositionY+4*3) && (CounterY<=ScoreBoardPositionY+76*3)
||          (CounterX>=ScoreBoardPositionX+4*3) && (CounterX<=ScoreBoardPositionX+86*3) && (CounterY>=ScoreBoardPositionY+79*3) && (CounterY<=ScoreBoardPositionY+80*3)
||          (CounterX>=ScoreBoardPositionX+2*3) && (CounterX<=ScoreBoardPositionX+4*3) && (CounterY>=ScoreBoardPositionY+78*3) && (CounterY<=ScoreBoardPositionY+79*3)
||          (CounterX>=ScoreBoardPositionX+86*3) && (CounterX<=ScoreBoardPositionX+88*3) && (CounterY>=ScoreBoardPositionY+78*3) && (CounterY<=ScoreBoardPositionY+79*3)
||          (CounterX>=ScoreBoardPositionX+1*3) && (CounterX<=ScoreBoardPositionX+2*3) && (CounterY>=ScoreBoardPositionY+76*3) && (CounterY<=ScoreBoardPositionY+78*3)
||          (CounterX>=ScoreBoardPositionX+88*3) && (CounterX<=ScoreBoardPositionX+89*3) && (CounterY>=ScoreBoardPositionY+76*3) && (CounterY<=ScoreBoardPositionY+78*3);

ScoreBoardWhite <= (CounterX>=ScoreBoardPositionX+4*3) && (CounterX<=ScoreBoardPositionX+86*3) && (CounterY>=ScoreBoardPositionY+1*3) && (CounterY<=ScoreBoardPositionY+2*3)

||          (CounterX>=ScoreBoardPositionX+2*3) && (CounterX<=ScoreBoardPositionX+88*3) && (CounterY>=ScoreBoardPositionY+2*3) && (CounterY<=ScoreBoardPositionY+4*3)

||          (CounterX>=ScoreBoardPositionX+4*3) && (CounterX<=ScoreBoardPositionX+86*3) && (CounterY>=ScoreBoardPositionY+78*3) && (CounterY<=ScoreBoardPositionY+79*3)

||          (CounterX>=ScoreBoardPositionX+2*3) && (CounterX<=ScoreBoardPositionX+88*3) && (CounterY>=ScoreBoardPositionY+76*3) && (CounterY<=ScoreBoardPositionY+78*3)

||          (CounterX>=ScoreBoardPositionX+1*3) && (CounterX<=ScoreBoardPositionX+89*3) && (CounterY>=ScoreBoardPositionY+4*3) && (CounterY<=ScoreBoardPositionY+76*3);


ScoreText <= (CounterX>=ScoreTextPositionX+1*3) && (CounterX<=ScoreTextPositionX+4*3) && (CounterY>=ScoreTextPositionY+0*3) && (CounterY<=ScoreTextPositionY+1*3)

||          (CounterX>=ScoreTextPositionX+0*3) && (CounterX<=ScoreTextPositionX+1*3) && (CounterY>=ScoreTextPositionY+1*3) && (CounterY<=ScoreTextPositionY+2*3)

||          (CounterX>=ScoreTextPositionX+1*3) && (CounterX<=ScoreTextPositionX+3*3) && (CounterY>=ScoreTextPositionY+2*3) && (CounterY<=ScoreTextPositionY+3*3)

||          (CounterX>=ScoreTextPositionX+3*3) && (CounterX<=ScoreTextPositionX+4*3) && (CounterY>=ScoreTextPositionY+3*3) && (CounterY<=ScoreTextPositionY+4*3)

||          (CounterX>=ScoreTextPositionX+0*3) && (CounterX<=ScoreTextPositionX+3*3) && (CounterY>=ScoreTextPositionY+4*3) && (CounterY<=ScoreTextPositionY+5*3)

||          (CounterX>=ScoreTextPositionX+6*3) && (CounterX<=ScoreTextPositionX+8*3) && (CounterY>=ScoreTextPositionY+0*3) && (CounterY<=ScoreTextPositionY+1*3)

||          (CounterX>=ScoreTextPositionX+5*3) && (CounterX<=ScoreTextPositionX+6*3) && (CounterY>=ScoreTextPositionY+1*3) && (CounterY<=ScoreTextPositionY+4*3)

||          (CounterX>=ScoreTextPositionX+6*3) && (CounterX<=ScoreTextPositionX+8*3) && (CounterY>=ScoreTextPositionY+4*3) && (CounterY<=ScoreTextPositionY+5*3)

||          (CounterX>=ScoreTextPositionX+10*3) && (CounterX<=ScoreTextPositionX+12*3) && (CounterY>=ScoreTextPositionY+0*3) && (CounterY<=ScoreTextPositionY+1*3)

||          (CounterX>=ScoreTextPositionX+9*3) && (CounterX<=ScoreTextPositionX+10*3) && (CounterY>=ScoreTextPositionY+1*3) && (CounterY<=ScoreTextPositionY+4*3)

||          (CounterX>=ScoreTextPositionX+12*3) && (CounterX<=ScoreTextPositionX+13*3) && (CounterY>=ScoreTextPositionY+1*3) && (CounterY<=ScoreTextPositionY+4*3)

||          (CounterX>=ScoreTextPositionX+10*3) && (CounterX<=ScoreTextPositionX+12*3) && (CounterY>=ScoreTextPositionY+4*3) && (CounterY<=ScoreTextPositionY+5*3)

||          (CounterX>=ScoreTextPositionX+14*3) && (CounterX<=ScoreTextPositionX+17*3) && (CounterY>=ScoreTextPositionY+0*3) && (CounterY<=ScoreTextPositionY+1*3)

||          (CounterX>=ScoreTextPositionX+14*3) && (CounterX<=ScoreTextPositionX+15*3) && (CounterY>=ScoreTextPositionY+1*3) && (CounterY<=ScoreTextPositionY+5*3)

||          (CounterX>=ScoreTextPositionX+17*3) && (CounterX<=ScoreTextPositionX+18*3) && (CounterY>=ScoreTextPositionY+1*3) && (CounterY<=ScoreTextPositionY+3*3)

||          (CounterX>=ScoreTextPositionX+15*3) && (CounterX<=ScoreTextPositionX+17*3) && (CounterY>=ScoreTextPositionY+3*3) && (CounterY<=ScoreTextPositionY+4*3)

||          (CounterX>=ScoreTextPositionX+17*3) && (CounterX<=ScoreTextPositionX+18*3) && (CounterY>=ScoreTextPositionY+4*3) && (CounterY<=ScoreTextPositionY+5*3)

||          (CounterX>=ScoreTextPositionX+19*3) && (CounterX<=ScoreTextPositionX+22*3) && (CounterY>=ScoreTextPositionY+0*3) && (CounterY<=ScoreTextPositionY+1*3)

||          (CounterX>=ScoreTextPositionX+19*3) && (CounterX<=ScoreTextPositionX+20*3) && (CounterY>=ScoreTextPositionY+1*3) && (CounterY<=ScoreTextPositionY+5*3)

||          (CounterX>=ScoreTextPositionX+20*3) && (CounterX<=ScoreTextPositionX+22*3) && (CounterY>=ScoreTextPositionY+2*3) && (CounterY<=ScoreTextPositionY+3*3)

||          (CounterX>=ScoreTextPositionX+20*3) && (CounterX<=ScoreTextPositionX+22*3) && (CounterY>=ScoreTextPositionY+4*3) && (CounterY<=ScoreTextPositionY+5*3);

BestText <= (CounterX>=BestTextPositionX+0*3) && (CounterX<=BestTextPositionX+3*3) && (CounterY>=BestTextPositionY+0*3) && (CounterY<=BestTextPositionY+1*3)

||          (CounterX>=BestTextPositionX+0*3) && (CounterX<=BestTextPositionX+1*3) && (CounterY>=BestTextPositionY+1*3) && (CounterY<=BestTextPositionY+5*3)

||          (CounterX>=BestTextPositionX+3*3) && (CounterX<=BestTextPositionX+4*3) && (CounterY>=BestTextPositionY+1*3) && (CounterY<=BestTextPositionY+2*3)

||          (CounterX>=BestTextPositionX+1*3) && (CounterX<=BestTextPositionX+3*3) && (CounterY>=BestTextPositionY+2*3) && (CounterY<=BestTextPositionY+3*3)

||          (CounterX>=BestTextPositionX+3*3) && (CounterX<=BestTextPositionX+4*3) && (CounterY>=BestTextPositionY+3*3) && (CounterY<=BestTextPositionY+4*3)

||          (CounterX>=BestTextPositionX+1*3) && (CounterX<=BestTextPositionX+3*3) && (CounterY>=BestTextPositionY+4*3) && (CounterY<=BestTextPositionY+5*3)

||          (CounterX>=BestTextPositionX+5*3) && (CounterX<=BestTextPositionX+8*3) && (CounterY>=BestTextPositionY+0*3) && (CounterY<=BestTextPositionY+1*3)

||          (CounterX>=BestTextPositionX+5*3) && (CounterX<=BestTextPositionX+6*3) && (CounterY>=BestTextPositionY+1*3) && (CounterY<=BestTextPositionY+5*3)

||          (CounterX>=BestTextPositionX+6*3) && (CounterX<=BestTextPositionX+8*3) && (CounterY>=BestTextPositionY+2*3) && (CounterY<=BestTextPositionY+3*3)

||          (CounterX>=BestTextPositionX+6*3) && (CounterX<=BestTextPositionX+8*3) && (CounterY>=BestTextPositionY+4*3) && (CounterY<=BestTextPositionY+5*3)

||          (CounterX>=BestTextPositionX+10*3) && (CounterX<=BestTextPositionX+13*3) && (CounterY>=BestTextPositionY+0*3) && (CounterY<=BestTextPositionY+1*3)

||          (CounterX>=BestTextPositionX+9*3) && (CounterX<=BestTextPositionX+10*3) && (CounterY>=BestTextPositionY+1*3) && (CounterY<=BestTextPositionY+2*3)

||          (CounterX>=BestTextPositionX+10*3) && (CounterX<=BestTextPositionX+12*3) && (CounterY>=BestTextPositionY+2*3) && (CounterY<=BestTextPositionY+3*3)

||          (CounterX>=BestTextPositionX+12*3) && (CounterX<=BestTextPositionX+13*3) && (CounterY>=BestTextPositionY+3*3) && (CounterY<=BestTextPositionY+4*3)

||          (CounterX>=BestTextPositionX+9*3) && (CounterX<=BestTextPositionX+12*3) && (CounterY>=BestTextPositionY+4*3) && (CounterY<=BestTextPositionY+5*3)

||          (CounterX>=BestTextPositionX+14*3) && (CounterX<=BestTextPositionX+17*3) && (CounterY>=BestTextPositionY+0*3) && (CounterY<=BestTextPositionY+1*3)

||          (CounterX>=BestTextPositionX+15*3) && (CounterX<=BestTextPositionX+16*3) && (CounterY>=BestTextPositionY+1*3) && (CounterY<=BestTextPositionY+5*3);
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BestBlackUnit <= (CounterX>=ScorePositionX+3+0*3) && (CounterX<=ScorePositionX+3+9*3) && (CounterY>=ScorePositionY+0*3) && (CounterY<=ScorePositionY+1*3)
||          (CounterX>=ScorePositionX+3+0*3) && (CounterX<=ScorePositionX+3+1*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX+3+8*3) && (CounterX<=ScorePositionX+3+9*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX+3+4*3) && (CounterX<=ScorePositionX+3+5*3) && (CounterY>=ScorePositionY+4*3) && (CounterY<=ScorePositionY+5*3)
||          (CounterX>=ScorePositionX+3+1*3) && (CounterX<=ScorePositionX+3+5*3) && (CounterY>=ScorePositionY+9*3) && (CounterY<=ScorePositionY+10*3)
||	    (CounterX>=ScorePositionX+3+0*3) && (CounterX<=ScorePositionX+3+9*3) && (CounterY>=ScorePositionY+13*3) && (CounterY<=ScorePositionY+14*3);

BestWhiteUnit <= (CounterX>=ScorePositionX+3+1*3) && (CounterX<=ScorePositionX+3+4*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+9*3)
||          (CounterX>=ScorePositionX+3+5*3) && (CounterX<=ScorePositionX+3+8*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX+3+1*3) && (CounterX<=ScorePositionX+3+5*3) && (CounterY>=ScorePositionY+10*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX+3+4*3) && (CounterX<=ScorePositionX+3+5*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+4*3)
||          (CounterX>=ScorePositionX+3+4*3) && (CounterX<=ScorePositionX+3+5*3) && (CounterY>=ScorePositionY+5*3) && (CounterY<=ScorePositionY+9*3);


BestBlackTen <= (CounterX>=ScorePositionX-30+0*3) && (CounterX<=ScorePositionX-30+9*3) && (CounterY>=ScorePositionY+0*3) && (CounterY<=ScorePositionY+1*3)
||          (CounterX>=ScorePositionX-30+0*3) && (CounterX<=ScorePositionX-30+1*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX-30+8*3) && (CounterX<=ScorePositionX-30+9*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX-30+4*3) && (CounterX<=ScorePositionX-30+5*3) && (CounterY>=ScorePositionY+4*3) && (CounterY<=ScorePositionY+5*3)
||          (CounterX>=ScorePositionX-30+1*3) && (CounterX<=ScorePositionX-30+5*3) && (CounterY>=ScorePositionY+9*3) && (CounterY<=ScorePositionY+10*3)
||	    (CounterX>=ScorePositionX-30+0*3) && (CounterX<=ScorePositionX-30+9*3) && (CounterY>=ScorePositionY+13*3) && (CounterY<=ScorePositionY+14*3);

BestWhiteTen <= (CounterX>=ScorePositionX-30+1*3) && (CounterX<=ScorePositionX-30+4*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+9*3)
||          (CounterX>=ScorePositionX-30+5*3) && (CounterX<=ScorePositionX-30+8*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX-30+1*3) && (CounterX<=ScorePositionX-30+5*3) && (CounterY>=ScorePositionY+10*3) && (CounterY<=ScorePositionY+13*3)
||          (CounterX>=ScorePositionX-30+4*3) && (CounterX<=ScorePositionX-30+5*3) && (CounterY>=ScorePositionY+1*3) && (CounterY<=ScorePositionY+4*3)
||          (CounterX>=ScorePositionX-30+4*3) && (CounterX<=ScorePositionX-30+5*3) && (CounterY>=ScorePositionY+5*3) && (CounterY<=ScorePositionY+9*3);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Name0 <=    (CounterX>=Name0PositionX+50*2) && (CounterX<=Name0PositionX+54*2) && (CounterY>=Name0PositionY+0*2) && (CounterY<=Name0PositionY+1*2)
||          (CounterX>=Name0PositionX+50*2) && (CounterX<=Name0PositionX+51*2) && (CounterY>=Name0PositionY+1*2) && (CounterY<=Name0PositionY+5*2)
||          (CounterX>=Name0PositionX+54*2) && (CounterX<=Name0PositionX+55*2) && (CounterY>=Name0PositionY+1*2) && (CounterY<=Name0PositionY+2*2)
||          (CounterX>=Name0PositionX+54*2) && (CounterX<=Name0PositionX+55*2) && (CounterY>=Name0PositionY+3*2) && (CounterY<=Name0PositionY+4*2)
||          (CounterX>=Name0PositionX+51*2) && (CounterX<=Name0PositionX+54*2) && (CounterY>=Name0PositionY+2*2) && (CounterY<=Name0PositionY+3*2)
||          (CounterX>=Name0PositionX+51*2) && (CounterX<=Name0PositionX+54*2) && (CounterY>=Name0PositionY+4*2) && (CounterY<=Name0PositionY+5*2)   //  B

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||          (CounterX>=Name0PositionX+56*2) && (CounterX<=Name0PositionX+57*2) && (CounterY>=Name0PositionY+0*2) && (CounterY<=Name0PositionY+1*2)
||          (CounterX>=Name0PositionX+60*2) && (CounterX<=Name0PositionX+61*2) && (CounterY>=Name0PositionY+0*2) && (CounterY<=Name0PositionY+1*2)
||          (CounterX>=Name0PositionX+57*2) && (CounterX<=Name0PositionX+58*2) && (CounterY>=Name0PositionY+1*2) && (CounterY<=Name0PositionY+2*2)
||          (CounterX>=Name0PositionX+59*2) && (CounterX<=Name0PositionX+60*2) && (CounterY>=Name0PositionY+1*2) && (CounterY<=Name0PositionY+2*2)
||          (CounterX>=Name0PositionX+58*2) && (CounterX<=Name0PositionX+59*2) && (CounterY>=Name0PositionY+2*2) && (CounterY<=Name0PositionY+5*2);   //  Y

Name1 <= (CounterX>=Name1PositionX+0*2) && (CounterX<=Name1PositionX+1*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+3*2)

||          (CounterX>=Name1PositionX+4*2) && (CounterX<=Name1PositionX+5*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+3*2)
||          (CounterX>=Name1PositionX+1*2) && (CounterX<=Name1PositionX+2*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+3*2) && (CounterX<=Name1PositionX+4*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+2*2) && (CounterX<=Name1PositionX+3*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)     // V

||          (CounterX>=Name1PositionX+6*2) && (CounterX<=Name1PositionX+11*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+6*2) && (CounterX<=Name1PositionX+11*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+6*2) && (CounterX<=Name1PositionX+7*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+7*2) && (CounterX<=Name1PositionX+9*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)   //  E

||          (CounterX>=Name1PositionX+12*2) && (CounterX<=Name1PositionX+17*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+12*2) && (CounterX<=Name1PositionX+17*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+12*2) && (CounterX<=Name1PositionX+13*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+13*2) && (CounterX<=Name1PositionX+15*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)   //  E

||          (CounterX>=Name1PositionX+18*2) && (CounterX<=Name1PositionX+22*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+18*2) && (CounterX<=Name1PositionX+19*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+19*2) && (CounterX<=Name1PositionX+22*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)
||          (CounterX>=Name1PositionX+22*2) && (CounterX<=Name1PositionX+23*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+21*2) && (CounterX<=Name1PositionX+22*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+22*2) && (CounterX<=Name1PositionX+23*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)   //  R

||          (CounterX>=Name1PositionX+26*2) && (CounterX<=Name1PositionX+27*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+25*2) && (CounterX<=Name1PositionX+26*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+27*2) && (CounterX<=Name1PositionX+28*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+24*2) && (CounterX<=Name1PositionX+29*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)
||          (CounterX>=Name1PositionX+24*2) && (CounterX<=Name1PositionX+25*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+28*2) && (CounterX<=Name1PositionX+29*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+5*2)   //  A

||          (CounterX>=Name1PositionX+30*2) && (CounterX<=Name1PositionX+34*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+30*2) && (CounterX<=Name1PositionX+31*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+31*2) && (CounterX<=Name1PositionX+34*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)
||          (CounterX>=Name1PositionX+34*2) && (CounterX<=Name1PositionX+35*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)   //  P


||          (CounterX>=Name1PositionX-12+44*2) && (CounterX<=Name1PositionX-12+45*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX-12+43*2) && (CounterX<=Name1PositionX-12+44*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX-12+45*2) && (CounterX<=Name1PositionX-12+46*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX-12+42*2) && (CounterX<=Name1PositionX-12+47*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)
||          (CounterX>=Name1PositionX-12+42*2) && (CounterX<=Name1PositionX-12+43*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX-12+46*2) && (CounterX<=Name1PositionX-12+47*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+5*2)   //  A

||          (CounterX>=Name1PositionX-12+48*2) && (CounterX<=Name1PositionX-12+53*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX-12+50*2) && (CounterX<=Name1PositionX-12+51*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+5*2)   //  T

||          (CounterX>=Name1PositionX+65*2) && (CounterX<=Name1PositionX+66*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+66*2) && (CounterX<=Name1PositionX+68*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)
||          (CounterX>=Name1PositionX+68*2) && (CounterX<=Name1PositionX+69*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+68*2) && (CounterX<=Name1PositionX+69*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+69*2) && (CounterX<=Name1PositionX+70*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+69*2) && (CounterX<=Name1PositionX+70*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)   //  K

||          (CounterX>=Name1PositionX+71*2) && (CounterX<=Name1PositionX+72*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+75*2) && (CounterX<=Name1PositionX+76*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+72*2) && (CounterX<=Name1PositionX+75*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)   //  U

||          (CounterX>=Name1PositionX+77*2) && (CounterX<=Name1PositionX+78*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+81*2) && (CounterX<=Name1PositionX+82*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+78*2) && (CounterX<=Name1PositionX+79*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+80*2) && (CounterX<=Name1PositionX+81*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+79*2) && (CounterX<=Name1PositionX+80*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)   //  M

||          (CounterX>=Name1PositionX+83*2) && (CounterX<=Name1PositionX+84*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+84*2) && (CounterX<=Name1PositionX+87*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+84*2) && (CounterX<=Name1PositionX+87*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+87*2) && (CounterX<=Name1PositionX+88*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+87*2) && (CounterX<=Name1PositionX+88*2) && (CounterY>=Name1PositionY+3*2) && (CounterY<=Name1PositionY+4*2)   //  C

||          (CounterX>=Name1PositionX+89*2) && (CounterX<=Name1PositionX+90*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+93*2) && (CounterX<=Name1PositionX+94*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+90*2) && (CounterX<=Name1PositionX+93*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2)   //  H

||          (CounterX>=Name1PositionX+95*2) && (CounterX<=Name1PositionX+96*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+99*2) && (CounterX<=Name1PositionX+100*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+4*2)
||          (CounterX>=Name1PositionX+96*2) && (CounterX<=Name1PositionX+99*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+1*2)
||          (CounterX>=Name1PositionX+96*2) && (CounterX<=Name1PositionX+99*2) && (CounterY>=Name1PositionY+4*2) && (CounterY<=Name1PositionY+5*2)   //  O

||          (CounterX>=Name1PositionX+101*2) && (CounterX<=Name1PositionX+102*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+105*2) && (CounterX<=Name1PositionX+106*2) && (CounterY>=Name1PositionY+0*2) && (CounterY<=Name1PositionY+5*2)
||          (CounterX>=Name1PositionX+102*2) && (CounterX<=Name1PositionX+103*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+104*2) && (CounterX<=Name1PositionX+105*2) && (CounterY>=Name1PositionY+1*2) && (CounterY<=Name1PositionY+2*2)
||          (CounterX>=Name1PositionX+103*2) && (CounterX<=Name1PositionX+104*2) && (CounterY>=Name1PositionY+2*2) && (CounterY<=Name1PositionY+3*2);   //  M


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Name2 <= (CounterX>=Name2PositionX+0*2) && (CounterX<=Name2PositionX+1*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+4*2)

||          (CounterX>=Name2PositionX+1*2) && (CounterX<=Name2PositionX+4*2) && (CounterY>=Name2PositionY+4*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+4*2) && (CounterX<=Name2PositionX+5*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+4*2)    // J

||          (CounterX>=Name2PositionX+8*2) && (CounterX<=Name2PositionX+9*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+7*2) && (CounterX<=Name2PositionX+8*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+9*2) && (CounterX<=Name2PositionX+10*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+6*2) && (CounterX<=Name2PositionX+11*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+6*2) && (CounterX<=Name2PositionX+7*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+10*2) && (CounterX<=Name2PositionX+11*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)   //  A

||          (CounterX>=Name2PositionX+12*2) && (CounterX<=Name2PositionX+13*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+16*2) && (CounterX<=Name2PositionX+17*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+13*2) && (CounterX<=Name2PositionX+14*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+14*2) && (CounterX<=Name2PositionX+15*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+15*2) && (CounterX<=Name2PositionX+16*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)   //  N

||          (CounterX>=Name2PositionX+18*2) && (CounterX<=Name2PositionX+23*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+18*2) && (CounterX<=Name2PositionX+23*2) && (CounterY>=Name2PositionY+4*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+18*2) && (CounterX<=Name2PositionX+19*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+4*2)
||          (CounterX>=Name2PositionX+19*2) && (CounterX<=Name2PositionX+21*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)   //  E

||          (CounterX>=Name2PositionX+24*2) && (CounterX<=Name2PositionX+25*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+28*2) && (CounterX<=Name2PositionX+29*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+26*2) && (CounterX<=Name2PositionX+27*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+25*2) && (CounterX<=Name2PositionX+26*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)
||          (CounterX>=Name2PositionX+27*2) && (CounterX<=Name2PositionX+28*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)   //  W

||          (CounterX>=Name2PositionX+30*2) && (CounterX<=Name2PositionX+35*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+30*2) && (CounterX<=Name2PositionX+35*2) && (CounterY>=Name2PositionY+4*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+32*2) && (CounterX<=Name2PositionX+33*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+4*2)   //  I

||          (CounterX>=Name2PositionX+36*2) && (CounterX<=Name2PositionX+41*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+38*2) && (CounterX<=Name2PositionX+39*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+5*2)   //  T

||          (CounterX>=Name2PositionX+65*2) && (CounterX<=Name2PositionX+66*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+4*2)
||          (CounterX>=Name2PositionX+66*2) && (CounterX<=Name2PositionX+69*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+66*2) && (CounterX<=Name2PositionX+69*2) && (CounterY>=Name2PositionY+4*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+69*2) && (CounterX<=Name2PositionX+70*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+69*2) && (CounterX<=Name2PositionX+70*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)   //  C

||          (CounterX>=Name2PositionX+71*2) && (CounterX<=Name2PositionX+72*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+75*2) && (CounterX<=Name2PositionX+76*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+72*2) && (CounterX<=Name2PositionX+75*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)   //  H

||          (CounterX>=Name2PositionX+79*2) && (CounterX<=Name2PositionX+80*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+78*2) && (CounterX<=Name2PositionX+79*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+80*2) && (CounterX<=Name2PositionX+81*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+77*2) && (CounterX<=Name2PositionX+82*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+77*2) && (CounterX<=Name2PositionX+78*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+81*2) && (CounterX<=Name2PositionX+82*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)   //  A

||          (CounterX>=Name2PositionX+83*2) && (CounterX<=Name2PositionX+84*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+87*2) && (CounterX<=Name2PositionX+88*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+85*2) && (CounterX<=Name2PositionX+86*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+84*2) && (CounterX<=Name2PositionX+85*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)
||          (CounterX>=Name2PositionX+86*2) && (CounterX<=Name2PositionX+87*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)   //  W

||          (CounterX>=Name2PositionX+89*2) && (CounterX<=Name2PositionX+90*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+93*2) && (CounterX<=Name2PositionX+94*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+91*2) && (CounterX<=Name2PositionX+92*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+90*2) && (CounterX<=Name2PositionX+91*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)
||          (CounterX>=Name2PositionX+92*2) && (CounterX<=Name2PositionX+93*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)   //  W

||          (CounterX>=Name2PositionX+97*2) && (CounterX<=Name2PositionX+98*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+96*2) && (CounterX<=Name2PositionX+97*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+98*2) && (CounterX<=Name2PositionX+99*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+95*2) && (CounterX<=Name2PositionX+100*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+95*2) && (CounterX<=Name2PositionX+96*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+99*2) && (CounterX<=Name2PositionX+100*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)   //  A

||          (CounterX>=Name2PositionX+101*2) && (CounterX<=Name2PositionX+102*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+105*2) && (CounterX<=Name2PositionX+106*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+102*2) && (CounterX<=Name2PositionX+103*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+103*2) && (CounterX<=Name2PositionX+104*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+104*2) && (CounterX<=Name2PositionX+105*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)   //  N

||          (CounterX>=Name2PositionX+109*2) && (CounterX<=Name2PositionX+110*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+108*2) && (CounterX<=Name2PositionX+109*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+110*2) && (CounterX<=Name2PositionX+111*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+107*2) && (CounterX<=Name2PositionX+112*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+107*2) && (CounterX<=Name2PositionX+108*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+111*2) && (CounterX<=Name2PositionX+112*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)   //  A

||          (CounterX>=Name2PositionX+113*2) && (CounterX<=Name2PositionX+114*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+117*2) && (CounterX<=Name2PositionX+118*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+114*2) && (CounterX<=Name2PositionX+115*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+115*2) && (CounterX<=Name2PositionX+116*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+116*2) && (CounterX<=Name2PositionX+117*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2)   //  N

||          (CounterX>=Name2PositionX+121*2) && (CounterX<=Name2PositionX+122*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+1*2)
||          (CounterX>=Name2PositionX+120*2) && (CounterX<=Name2PositionX+121*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+122*2) && (CounterX<=Name2PositionX+123*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+119*2) && (CounterX<=Name2PositionX+124*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+119*2) && (CounterX<=Name2PositionX+120*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+123*2) && (CounterX<=Name2PositionX+124*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+5*2)   //  A

||          (CounterX>=Name2PositionX+125*2) && (CounterX<=Name2PositionX+126*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+129*2) && (CounterX<=Name2PositionX+130*2) && (CounterY>=Name2PositionY+0*2) && (CounterY<=Name2PositionY+5*2)
||          (CounterX>=Name2PositionX+126*2) && (CounterX<=Name2PositionX+127*2) && (CounterY>=Name2PositionY+1*2) && (CounterY<=Name2PositionY+2*2)
||          (CounterX>=Name2PositionX+127*2) && (CounterX<=Name2PositionX+128*2) && (CounterY>=Name2PositionY+2*2) && (CounterY<=Name2PositionY+3*2)
||          (CounterX>=Name2PositionX+128*2) && (CounterX<=Name2PositionX+129*2) && (CounterY>=Name2PositionY+3*2) && (CounterY<=Name2PositionY+4*2);   //  N

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Name3 <= (CounterX>=Name3PositionX+0*2) && (CounterX<=Name3PositionX+5*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+2*2) && (CounterX<=Name3PositionX+3*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+5*2)   //  T

||          (CounterX>=Name3PositionX+6*2) && (CounterX<=Name3PositionX+7*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+10*2) && (CounterX<=Name3PositionX+11*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+7*2) && (CounterX<=Name3PositionX+10*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2)   //  H

||          (CounterX>=Name3PositionX+12*2) && (CounterX<=Name3PositionX+17*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+12*2) && (CounterX<=Name3PositionX+17*2) && (CounterY>=Name3PositionY+4*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+14*2) && (CounterX<=Name3PositionX+15*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+4*2)   //  I

||	         (CounterX>=Name3PositionX+18*2) && (CounterX<=Name3PositionX+23*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+20*2) && (CounterX<=Name3PositionX+21*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+5*2)   //  T

||          (CounterX>=Name3PositionX+24*2) && (CounterX<=Name3PositionX+29*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+24*2) && (CounterX<=Name3PositionX+29*2) && (CounterY>=Name3PositionY+4*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+26*2) && (CounterX<=Name3PositionX+27*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+4*2)   //  I

||          (CounterX>=Name3PositionX+30*2) && (CounterX<=Name3PositionX+31*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+4*2)
||          (CounterX>=Name3PositionX+31*2) && (CounterX<=Name3PositionX+34*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+31*2) && (CounterX<=Name3PositionX+34*2) && (CounterY>=Name3PositionY+4*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+34*2) && (CounterX<=Name3PositionX+35*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+34*2) && (CounterX<=Name3PositionX+35*2) && (CounterY>=Name3PositionY+3*2) && (CounterY<=Name3PositionY+4*2)   //  C

||          (CounterX>=Name3PositionX+36*2) && (CounterX<=Name3PositionX+37*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+40*2) && (CounterX<=Name3PositionX+41*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+37*2) && (CounterX<=Name3PositionX+40*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2)   //  H

||          (CounterX>=Name3PositionX+44*2) && (CounterX<=Name3PositionX+45*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+43*2) && (CounterX<=Name3PositionX+44*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+45*2) && (CounterX<=Name3PositionX+46*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+42*2) && (CounterX<=Name3PositionX+47*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2)
||          (CounterX>=Name3PositionX+42*2) && (CounterX<=Name3PositionX+43*2) && (CounterY>=Name3PositionY+3*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+46*2) && (CounterX<=Name3PositionX+47*2) && (CounterY>=Name3PositionY+3*2) && (CounterY<=Name3PositionY+5*2)   //  A

||          (CounterX>=Name3PositionX+48*2) && (CounterX<=Name3PositionX+49*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+52*2) && (CounterX<=Name3PositionX+53*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+49*2) && (CounterX<=Name3PositionX+50*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+51*2) && (CounterX<=Name3PositionX+52*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+50*2) && (CounterX<=Name3PositionX+51*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+5*2)   //  Y

||          (CounterX>=Name3PositionX+56*2) && (CounterX<=Name3PositionX+57*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+55*2) && (CounterX<=Name3PositionX+56*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+57*2) && (CounterX<=Name3PositionX+58*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+54*2) && (CounterX<=Name3PositionX+59*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2)
||          (CounterX>=Name3PositionX+54*2) && (CounterX<=Name3PositionX+55*2) && (CounterY>=Name3PositionY+3*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+58*2) && (CounterX<=Name3PositionX+59*2) && (CounterY>=Name3PositionY+3*2) && (CounterY<=Name3PositionY+5*2)   //  A

||          (CounterX>=Name3PositionX+65*2) && (CounterX<=Name3PositionX+66*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+4*2)
||          (CounterX>=Name3PositionX+66*2) && (CounterX<=Name3PositionX+69*2) && (CounterY>=Name3PositionY+4*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+69*2) && (CounterX<=Name3PositionX+70*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+4*2)    // J

||          (CounterX>=Name3PositionX+71*2) && (CounterX<=Name3PositionX+72*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+4*2)
||          (CounterX>=Name3PositionX+75*2) && (CounterX<=Name3PositionX+76*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+4*2)
||          (CounterX>=Name3PositionX+72*2) && (CounterX<=Name3PositionX+75*2) && (CounterY>=Name3PositionY+4*2) && (CounterY<=Name3PositionY+5*2)   //  U

||          (CounterX>=Name3PositionX+77*2) && (CounterX<=Name3PositionX+78*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+81*2) && (CounterX<=Name3PositionX+82*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+78*2) && (CounterX<=Name3PositionX+79*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+79*2) && (CounterX<=Name3PositionX+80*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2)
||          (CounterX>=Name3PositionX+80*2) && (CounterX<=Name3PositionX+81*2) && (CounterY>=Name3PositionY+3*2) && (CounterY<=Name3PositionY+4*2)   //  N

||          (CounterX>=Name3PositionX+83*2) && (CounterX<=Name3PositionX+87*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+83*2) && (CounterX<=Name3PositionX+84*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+84*2) && (CounterX<=Name3PositionX+87*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2)
||          (CounterX>=Name3PositionX+87*2) && (CounterX<=Name3PositionX+88*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)   //  P

||          (CounterX>=Name3PositionX+89*2) && (CounterX<=Name3PositionX+94*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+89*2) && (CounterX<=Name3PositionX+94*2) && (CounterY>=Name3PositionY+4*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+89*2) && (CounterX<=Name3PositionX+90*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+4*2)
||          (CounterX>=Name3PositionX+90*2) && (CounterX<=Name3PositionX+92*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2)   //  E

||	         (CounterX>=Name3PositionX+95*2) && (CounterX<=Name3PositionX+100*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+97*2) && (CounterX<=Name3PositionX+98*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+5*2)   //  T

||          (CounterX>=Name3PositionX+101*2) && (CounterX<=Name3PositionX+102*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+4*2)
||          (CounterX>=Name3PositionX+102*2) && (CounterX<=Name3PositionX+105*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+1*2)
||          (CounterX>=Name3PositionX+102*2) && (CounterX<=Name3PositionX+105*2) && (CounterY>=Name3PositionY+4*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+105*2) && (CounterX<=Name3PositionX+106*2) && (CounterY>=Name3PositionY+1*2) && (CounterY<=Name3PositionY+2*2)
||          (CounterX>=Name3PositionX+105*2) && (CounterX<=Name3PositionX+106*2) && (CounterY>=Name3PositionY+3*2) && (CounterY<=Name3PositionY+4*2)   //  C

||          (CounterX>=Name3PositionX+107*2) && (CounterX<=Name3PositionX+108*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+111*2) && (CounterX<=Name3PositionX+112*2) && (CounterY>=Name3PositionY+0*2) && (CounterY<=Name3PositionY+5*2)
||          (CounterX>=Name3PositionX+108*2) && (CounterX<=Name3PositionX+111*2) && (CounterY>=Name3PositionY+2*2) && (CounterY<=Name3PositionY+3*2);   //  H












				if (Status == 0) begin
				R_Board_on = ScoreBoardWhite | ScoreText | BestText | BestWhiteUnit | BestWhiteTen;
				G_Board_on = ScoreBoardWhite | BestWhiteUnit | BestWhiteTen;
				B_Board_on = ScoreBoardWhite | BestWhiteUnit | BestWhiteTen;

				R_Board_off = ScoreBoardBlack | BestBlackUnit | BestBlackTen;
				G_Board_off = ScoreBoardBlack | ScoreText | BestText | BestBlackUnit | BestBlackTen;
				B_Board_off = ScoreBoardBlack | ScoreText | BestText | BestBlackUnit | BestBlackTen;
				end
				
				if (!Button && Start == 0) Start <= 1;
				if (!Reset) Start <= 0;
				
				if (Start == 0) begin
				R_Board_on = LogoWhite | LogoYellow;
				G_Board_on = LogoWhite | LogoYellow | LogoGreen;
				B_Board_on = LogoWhite;

				R_Board_off = LogoBlack | LogoGreen | Name0 | Name1 | Name2 | Name3;
				G_Board_off = LogoBlack| Name0 | Name1 | Name2  | Name3;
				B_Board_off = LogoBlack | LogoYellow | LogoGreen | Name0 | Name1 | Name2  | Name3;
				end
				
				 
end
endmodule
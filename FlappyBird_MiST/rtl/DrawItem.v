`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:53:31 04/24/2014 
// Design Name: 
// Module Name:    DrawItem 
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
module DrawItem(input [24:0] Clks,CounterX,CounterY,Button,output reg R_Item_on,G_Item_on,B_Item_on,R_Item_off,G_Item_off,B_Item_off);

reg [15:0] ItemPositionX = 0;
reg [15:0] ItemPositionY = 0;
reg [15:0] StarPositionX = 100;
reg [15:0] StarPositionY = 100;
reg [15:0] ScoreBoardPositionX = 200;
reg [15:0] ScoreBoardPositionY = 0;
reg [15:0] FlowerPositionX = 300;
reg [15:0] FlowerPositionY = 0;


reg MushroomBlack,MushroomRed,MushroomWhite,StarBlack,StarYellow,FlowerBlack,FlowerRed,FlowerGreen;
always @ (CounterX or CounterY)
begin

MushroomBlack <= (CounterX>=ItemPositionX+6*3) && (CounterX<=ItemPositionX+12*3) && (CounterY>=ItemPositionY+0*3) && (CounterY<=ItemPositionY+1*3)

||          (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+6*3) && (CounterY>=ItemPositionY+1*3) && (CounterY<=ItemPositionY+2*3)
||          (CounterX>=ItemPositionX+12*3) && (CounterX<=ItemPositionX+14*3) && (CounterY>=ItemPositionY+1*3) && (CounterY<=ItemPositionY+2*3)

||          (CounterX>=ItemPositionX+3*3) && (CounterX<=ItemPositionX+4*3) && (CounterY>=ItemPositionY+2*3) && (CounterY<=ItemPositionY+3*3)
||          (CounterX>=ItemPositionX+14*3) && (CounterX<=ItemPositionX+15*3) && (CounterY>=ItemPositionY+2*3) && (CounterY<=ItemPositionY+3*3)

||          (CounterX>=ItemPositionX+2*3) && (CounterX<=ItemPositionX+3*3) && (CounterY>=ItemPositionY+3*3) && (CounterY<=ItemPositionY+5*3)
||          (CounterX>=ItemPositionX+15*3) && (CounterX<=ItemPositionX+16*3) && (CounterY>=ItemPositionY+3*3) && (CounterY<=ItemPositionY+5*3)

||          (CounterX>=ItemPositionX+1*3) && (CounterX<=ItemPositionX+2*3) && (CounterY>=ItemPositionY+5*3) && (CounterY<=ItemPositionY+11*3)
||          (CounterX>=ItemPositionX+16*3) && (CounterX<=ItemPositionX+17*3) && (CounterY>=ItemPositionY+5*3) && (CounterY<=ItemPositionY+11*3)
||          (CounterX>=ItemPositionX+5*3) && (CounterX<=ItemPositionX+13*3) && (CounterY>=ItemPositionY+10*3) && (CounterY<=ItemPositionY+11*3)

||          (CounterX>=ItemPositionX+2*3) && (CounterX<=ItemPositionX+5*3) && (CounterY>=ItemPositionY+11*3) && (CounterY<=ItemPositionY+12*3)
||          (CounterX>=ItemPositionX+13*3) && (CounterX<=ItemPositionX+16*3) && (CounterY>=ItemPositionY+11*3) && (CounterY<=ItemPositionY+12*3)
||          (CounterX>=ItemPositionX+7*3) && (CounterX<=ItemPositionX+8*3) && (CounterY>=ItemPositionY+11*3) && (CounterY<=ItemPositionY+13*3)
||          (CounterX>=ItemPositionX+10*3) && (CounterX<=ItemPositionX+11*3) && (CounterY>=ItemPositionY+11*3) && (CounterY<=ItemPositionY+13*3)

||          (CounterX>=ItemPositionX+3*3) && (CounterX<=ItemPositionX+4*3) && (CounterY>=ItemPositionY+10*3) && (CounterY<=ItemPositionY+14*3)
||          (CounterX>=ItemPositionX+14*3) && (CounterX<=ItemPositionX+15*3) && (CounterY>=ItemPositionY+10*3) && (CounterY<=ItemPositionY+14*3)

||          (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+5*3) && (CounterY>=ItemPositionY+14*3) && (CounterY<=ItemPositionY+15*3)
||          (CounterX>=ItemPositionX+13*3) && (CounterX<=ItemPositionX+14*3) && (CounterY>=ItemPositionY+14*3) && (CounterY<=ItemPositionY+15*3)

||          (CounterX>=ItemPositionX+5*3) && (CounterX<=ItemPositionX+13*3) && (CounterY>=ItemPositionY+15*3) && (CounterY<=ItemPositionY+16*3);

MushroomRed <= (CounterX>=ItemPositionX+6*3) && (CounterX<=ItemPositionX+10*3) && (CounterY>=ItemPositionY+1*3) && (CounterY<=ItemPositionY+4*3)

||          (CounterX>=ItemPositionX+5*3) && (CounterX<=ItemPositionX+6*3) && (CounterY>=ItemPositionY+3*3) && (CounterY<=ItemPositionY+4*3)
||          (CounterX>=ItemPositionX+10*3) && (CounterX<=ItemPositionX+11*3) && (CounterY>=ItemPositionY+3*3) && (CounterY<=ItemPositionY+4*3)

||          (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+6*3) && (CounterY>=ItemPositionY+4*3) && (CounterY<=ItemPositionY+5*3)
||          (CounterX>=ItemPositionX+10*3) && (CounterX<=ItemPositionX+12*3) && (CounterY>=ItemPositionY+4*3) && (CounterY<=ItemPositionY+5*3)

||          (CounterX>=ItemPositionX+2*3) && (CounterX<=ItemPositionX+5*3) && (CounterY>=ItemPositionY+5*3) && (CounterY<=ItemPositionY+7*3)
||          (CounterX>=ItemPositionX+11*3) && (CounterX<=ItemPositionX+16*3) && (CounterY>=ItemPositionY+5*3) && (CounterY<=ItemPositionY+6*3)

||          (CounterX>=ItemPositionX+11*3) && (CounterX<=ItemPositionX+13*3) && (CounterY>=ItemPositionY+6*3) && (CounterY<=ItemPositionY+7*3)
||          (CounterX>=ItemPositionX+15*3) && (CounterX<=ItemPositionX+16*3) && (CounterY>=ItemPositionY+6*3) && (CounterY<=ItemPositionY+7*3)

||          (CounterX>=ItemPositionX+3*3) && (CounterX<=ItemPositionX+5*3) && (CounterY>=ItemPositionY+7*3) && (CounterY<=ItemPositionY+8*3)
||          (CounterX>=ItemPositionX+11*3) && (CounterX<=ItemPositionX+12*3) && (CounterY>=ItemPositionY+7*3) && (CounterY<=ItemPositionY+8*3)

||          (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+6*3) && (CounterY>=ItemPositionY+8*3) && (CounterY<=ItemPositionY+10*3)
||          (CounterX>=ItemPositionX+10*3) && (CounterX<=ItemPositionX+12*3) && (CounterY>=ItemPositionY+8*3) && (CounterY<=ItemPositionY+10*3)

||          (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+13*3) && (CounterY>=ItemPositionY+9*3) && (CounterY<=ItemPositionY+10*3)
||          (CounterX>=ItemPositionX+15*3) && (CounterX<=ItemPositionX+16*3) && (CounterY>=ItemPositionY+9*3) && (CounterY<=ItemPositionY+10*3)

||          (CounterX>=ItemPositionX+3*3) && (CounterX<=ItemPositionX+5*3) && (CounterY>=ItemPositionY+10*3) && (CounterY<=ItemPositionY+11*3)
||          (CounterX>=ItemPositionX+13*3) && (CounterX<=ItemPositionX+16*3) && (CounterY>=ItemPositionY+10*3) && (CounterY<=ItemPositionY+11*3);

MushroomWhite <= (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+6*3) && (CounterY>=ItemPositionY+2*3) && (CounterY<=ItemPositionY+3*3)

||          (CounterX>=ItemPositionX+10*3) && (CounterX<=ItemPositionX+12*3) && (CounterY>=ItemPositionY+1*3) && (CounterY<=ItemPositionY+3*3)
||          (CounterX>=ItemPositionX+12*3) && (CounterX<=ItemPositionX+14*3) && (CounterY>=ItemPositionY+2*3) && (CounterY<=ItemPositionY+3*3)

||          (CounterX>=ItemPositionX+3*3) && (CounterX<=ItemPositionX+5*3) && (CounterY>=ItemPositionY+3*3) && (CounterY<=ItemPositionY+4*3)
||          (CounterX>=ItemPositionX+3*3) && (CounterX<=ItemPositionX+4*3) && (CounterY>=ItemPositionY+4*3) && (CounterY<=ItemPositionY+5*3)
||          (CounterX>=ItemPositionX+12*3) && (CounterX<=ItemPositionX+15*3) && (CounterY>=ItemPositionY+3*3) && (CounterY<=ItemPositionY+5*3)
||          (CounterX>=ItemPositionX+11*3) && (CounterX<=ItemPositionX+12*3) && (CounterY>=ItemPositionY+3*3) && (CounterY<=ItemPositionY+4*3)

||          (CounterX>=ItemPositionX+6*3) && (CounterX<=ItemPositionX+10*3) && (CounterY>=ItemPositionY+4*3) && (CounterY<=ItemPositionY+9*3)
||          (CounterX>=ItemPositionX+5*3) && (CounterX<=ItemPositionX+6*3) && (CounterY>=ItemPositionY+5*3) && (CounterY<=ItemPositionY+8*3)
||          (CounterX>=ItemPositionX+10*3) && (CounterX<=ItemPositionX+11*3) && (CounterY>=ItemPositionY+5*3) && (CounterY<=ItemPositionY+8*3)

||          (CounterX>=ItemPositionX+2*3) && (CounterX<=ItemPositionX+3*3) && (CounterY>=ItemPositionY+7*3) && (CounterY<=ItemPositionY+11*3)
||          (CounterX>=ItemPositionX+3*3) && (CounterX<=ItemPositionX+4*3) && (CounterY>=ItemPositionY+8*3) && (CounterY<=ItemPositionY+10*3)

||          (CounterX>=ItemPositionX+13*3) && (CounterX<=ItemPositionX+15*3) && (CounterY>=ItemPositionY+6*3) && (CounterY<=ItemPositionY+10*3)
||          (CounterX>=ItemPositionX+12*3) && (CounterX<=ItemPositionX+13*3) && (CounterY>=ItemPositionY+7*3) && (CounterY<=ItemPositionY+9*3)
||          (CounterX>=ItemPositionX+15*3) && (CounterX<=ItemPositionX+16*3) && (CounterY>=ItemPositionY+7*3) && (CounterY<=ItemPositionY+9*3)

||          (CounterX>=ItemPositionX+5*3) && (CounterX<=ItemPositionX+7*3) && (CounterY>=ItemPositionY+11*3) && (CounterY<=ItemPositionY+13*3)
||          (CounterX>=ItemPositionX+8*3) && (CounterX<=ItemPositionX+10*3) && (CounterY>=ItemPositionY+11*3) && (CounterY<=ItemPositionY+13*3)
||          (CounterX>=ItemPositionX+11*3) && (CounterX<=ItemPositionX+13*3) && (CounterY>=ItemPositionY+11*3) && (CounterY<=ItemPositionY+13*3)
||          (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+5*3) && (CounterY>=ItemPositionY+12*3) && (CounterY<=ItemPositionY+13*3)
||          (CounterX>=ItemPositionX+13*3) && (CounterX<=ItemPositionX+14*3) && (CounterY>=ItemPositionY+12*3) && (CounterY<=ItemPositionY+13*3)

||          (CounterX>=ItemPositionX+4*3) && (CounterX<=ItemPositionX+14*3) && (CounterY>=ItemPositionY+13*3) && (CounterY<=ItemPositionY+14*3)
||          (CounterX>=ItemPositionX+5*3) && (CounterX<=ItemPositionX+13*3) && (CounterY>=ItemPositionY+14*3) && (CounterY<=ItemPositionY+15*3);


StarBlack <= (CounterX>=StarPositionX+7*3) && (CounterX<=StarPositionX+9*3) && (CounterY>=StarPositionY+0*3) && (CounterY<=StarPositionY+1*3)
||          (CounterX>=StarPositionX+6*3) && (CounterX<=StarPositionX+7*3) && (CounterY>=StarPositionY+1*3) && (CounterY<=StarPositionY+3*3)
||          (CounterX>=StarPositionX+9*3) && (CounterX<=StarPositionX+10*3) && (CounterY>=StarPositionY+1*3) && (CounterY<=StarPositionY+3*3)
||          (CounterX>=StarPositionX+5*3) && (CounterX<=StarPositionX+6*3) && (CounterY>=StarPositionY+3*3) && (CounterY<=StarPositionY+4*3)
||          (CounterX>=StarPositionX+10*3) && (CounterX<=StarPositionX+11*3) && (CounterY>=StarPositionY+3*3) && (CounterY<=StarPositionY+4*3)
||          (CounterX>=StarPositionX+0*3) && (CounterX<=StarPositionX+6*3) && (CounterY>=StarPositionY+4*3) && (CounterY<=StarPositionY+5*3)
||          (CounterX>=StarPositionX+10*3) && (CounterX<=StarPositionX+16*3) && (CounterY>=StarPositionY+4*3) && (CounterY<=StarPositionY+5*3)
||          (CounterX>=StarPositionX+0*3) && (CounterX<=StarPositionX+1*3) && (CounterY>=StarPositionY+5*3) && (CounterY<=StarPositionY+6*3)
||          (CounterX>=StarPositionX+15*3) && (CounterX<=StarPositionX+16*3) && (CounterY>=StarPositionY+5*3) && (CounterY<=StarPositionY+6*3)
||          (CounterX>=StarPositionX+1*3) && (CounterX<=StarPositionX+2*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+7*3)
||          (CounterX>=StarPositionX+14*3) && (CounterX<=StarPositionX+15*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+7*3)
||          (CounterX>=StarPositionX+6*3) && (CounterX<=StarPositionX+7*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+9*3)
||          (CounterX>=StarPositionX+9*3) && (CounterX<=StarPositionX+10*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+9*3)
||          (CounterX>=StarPositionX+2*3) && (CounterX<=StarPositionX+3*3) && (CounterY>=StarPositionY+7*3) && (CounterY<=StarPositionY+8*3)
||          (CounterX>=StarPositionX+13*3) && (CounterX<=StarPositionX+14*3) && (CounterY>=StarPositionY+7*3) && (CounterY<=StarPositionY+8*3)
||          (CounterX>=StarPositionX+3*3) && (CounterX<=StarPositionX+4*3) && (CounterY>=StarPositionY+8*3) && (CounterY<=StarPositionY+10*3)
||          (CounterX>=StarPositionX+12*3) && (CounterX<=StarPositionX+13*3) && (CounterY>=StarPositionY+8*3) && (CounterY<=StarPositionY+10*3)
||          (CounterX>=StarPositionX+2*3) && (CounterX<=StarPositionX+3*3) && (CounterY>=StarPositionY+10*3) && (CounterY<=StarPositionY+12*3)
||          (CounterX>=StarPositionX+13*3) && (CounterX<=StarPositionX+14*3) && (CounterY>=StarPositionY+10*3) && (CounterY<=StarPositionY+12*3)
||          (CounterX>=StarPositionX+1*3) && (CounterX<=StarPositionX+2*3) && (CounterY>=StarPositionY+12*3) && (CounterY<=StarPositionY+14*3)
||          (CounterX>=StarPositionX+14*3) && (CounterX<=StarPositionX+15*3) && (CounterY>=StarPositionY+12*3) && (CounterY<=StarPositionY+14*3)
||          (CounterX>=StarPositionX+7*3) && (CounterX<=StarPositionX+9*3) && (CounterY>=StarPositionY+12*3) && (CounterY<=StarPositionY+13*3)
||          (CounterX>=StarPositionX+5*3) && (CounterX<=StarPositionX+7*3) && (CounterY>=StarPositionY+13*3) && (CounterY<=StarPositionY+14*3)
||          (CounterX>=StarPositionX+9*3) && (CounterX<=StarPositionX+11*3) && (CounterY>=StarPositionY+13*3) && (CounterY<=StarPositionY+14*3)
||          (CounterX>=StarPositionX+0*3) && (CounterX<=StarPositionX+1*3) && (CounterY>=StarPositionY+14*3) && (CounterY<=StarPositionY+15*3)
||          (CounterX>=StarPositionX+3*3) && (CounterX<=StarPositionX+5*3) && (CounterY>=StarPositionY+14*3) && (CounterY<=StarPositionY+15*3)
||          (CounterX>=StarPositionX+11*3) && (CounterX<=StarPositionX+13*3) && (CounterY>=StarPositionY+14*3) && (CounterY<=StarPositionY+15*3)
||          (CounterX>=StarPositionX+15*3) && (CounterX<=StarPositionX+16*3) && (CounterY>=StarPositionY+14*3) && (CounterY<=StarPositionY+15*3)
||          (CounterX>=StarPositionX+0*3) && (CounterX<=StarPositionX+3*3) && (CounterY>=StarPositionY+15*3) && (CounterY<=StarPositionY+16*3)
||          (CounterX>=StarPositionX+13*3) && (CounterX<=StarPositionX+16*3) && (CounterY>=StarPositionY+15*3) && (CounterY<=StarPositionY+16*3);
StarYellow <= (CounterX>=StarPositionX+7*3) && (CounterX<=StarPositionX+9*3) && (CounterY>=StarPositionY+1*3) && (CounterY<=StarPositionY+3*3)

||          (CounterX>=StarPositionX+6*3) && (CounterX<=StarPositionX+10*3) && (CounterY>=StarPositionY+3*3) && (CounterY<=StarPositionY+6*3)
||          (CounterX>=StarPositionX+1*3) && (CounterX<=StarPositionX+6*3) && (CounterY>=StarPositionY+5*3) && (CounterY<=StarPositionY+6*3)
||          (CounterX>=StarPositionX+10*3) && (CounterX<=StarPositionX+15*3) && (CounterY>=StarPositionY+5*3) && (CounterY<=StarPositionY+6*3)

||          (CounterX>=StarPositionX+3*3) && (CounterX<=StarPositionX+6*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+8*3)
||          (CounterX>=StarPositionX+10*3) && (CounterX<=StarPositionX+13*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+8*3)
||          (CounterX>=StarPositionX+2*3) && (CounterX<=StarPositionX+3*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+7*3)
||          (CounterX>=StarPositionX+13*3) && (CounterX<=StarPositionX+14*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+7*3)

||          (CounterX>=StarPositionX+7*3) && (CounterX<=StarPositionX+9*3) && (CounterY>=StarPositionY+6*3) && (CounterY<=StarPositionY+9*3)
||          (CounterX>=StarPositionX+4*3) && (CounterX<=StarPositionX+6*3) && (CounterY>=StarPositionY+8*3) && (CounterY<=StarPositionY+9*3)
||          (CounterX>=StarPositionX+10*3) && (CounterX<=StarPositionX+12*3) && (CounterY>=StarPositionY+8*3) && (CounterY<=StarPositionY+9*3)

||          (CounterX>=StarPositionX+4*3) && (CounterX<=StarPositionX+12*3) && (CounterY>=StarPositionY+9*3) && (CounterY<=StarPositionY+10*3)
||          (CounterX>=StarPositionX+3*3) && (CounterX<=StarPositionX+13*3) && (CounterY>=StarPositionY+10*3) && (CounterY<=StarPositionY+12*3)

||          (CounterX>=StarPositionX+2*3) && (CounterX<=StarPositionX+5*3) && (CounterY>=StarPositionY+12*3) && (CounterY<=StarPositionY+14*3)
||          (CounterX>=StarPositionX+11*3) && (CounterX<=StarPositionX+14*3) && (CounterY>=StarPositionY+12*3) && (CounterY<=StarPositionY+14*3)
||          (CounterX>=StarPositionX+5*3) && (CounterX<=StarPositionX+7*3) && (CounterY>=StarPositionY+12*3) && (CounterY<=StarPositionY+13*3)
||          (CounterX>=StarPositionX+9*3) && (CounterX<=StarPositionX+11*3) && (CounterY>=StarPositionY+12*3) && (CounterY<=StarPositionY+13*3)

||          (CounterX>=StarPositionX+1*3) && (CounterX<=StarPositionX+3*3) && (CounterY>=StarPositionY+14*3) && (CounterY<=StarPositionY+15*3)
||          (CounterX>=StarPositionX+13*3) && (CounterX<=StarPositionX+15*3) && (CounterY>=StarPositionY+14*3) && (CounterY<=StarPositionY+15*3);

FlowerBlack <= (CounterX>=FlowerPositionX+7*3) && (CounterX<=FlowerPositionX+9*3) && (CounterY>=FlowerPositionY+0*3) && (CounterY<=FlowerPositionY+1*3)

||          (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+3*3) && (CounterY>=FlowerPositionY+1*3) && (CounterY<=FlowerPositionY+2*3)
||          (CounterX>=FlowerPositionX+6*3) && (CounterX<=FlowerPositionX+7*3) && (CounterY>=FlowerPositionY+1*3) && (CounterY<=FlowerPositionY+2*3)
||          (CounterX>=FlowerPositionX+9*3) && (CounterX<=FlowerPositionX+10*3) && (CounterY>=FlowerPositionY+1*3) && (CounterY<=FlowerPositionY+2*3)
||          (CounterX>=FlowerPositionX+13*3) && (CounterX<=FlowerPositionX+14*3) && (CounterY>=FlowerPositionY+1*3) && (CounterY<=FlowerPositionY+2*3)

||          (CounterX>=FlowerPositionX+1*3) && (CounterX<=FlowerPositionX+2*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+4*3)
||          (CounterX>=FlowerPositionX+14*3) && (CounterX<=FlowerPositionX+15*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+4*3)

||          (CounterX>=FlowerPositionX+3*3) && (CounterX<=FlowerPositionX+4*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+3*3)
||          (CounterX>=FlowerPositionX+5*3) && (CounterX<=FlowerPositionX+6*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+3*3)
||          (CounterX>=FlowerPositionX+10*3) && (CounterX<=FlowerPositionX+11*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+3*3)
||          (CounterX>=FlowerPositionX+12*3) && (CounterX<=FlowerPositionX+13*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+3*3)
||          (CounterX>=FlowerPositionX+4*3) && (CounterX<=FlowerPositionX+5*3) && (CounterY>=FlowerPositionY+3*3) && (CounterY<=FlowerPositionY+4*3)
||          (CounterX>=FlowerPositionX+11*3) && (CounterX<=FlowerPositionX+12*3) && (CounterY>=FlowerPositionY+3*3) && (CounterY<=FlowerPositionY+4*3)

||          (CounterX>=FlowerPositionX+0*3) && (CounterX<=FlowerPositionX+1*3) && (CounterY>=FlowerPositionY+4*3) && (CounterY<=FlowerPositionY+8*3)
||          (CounterX>=FlowerPositionX+15*3) && (CounterX<=FlowerPositionX+16*3) && (CounterY>=FlowerPositionY+4*3) && (CounterY<=FlowerPositionY+8*3)

||          (CounterX>=FlowerPositionX+4*3) && (CounterX<=FlowerPositionX+6*3) && (CounterY>=FlowerPositionY+5*3) && (CounterY<=FlowerPositionY+6*3)
||          (CounterX>=FlowerPositionX+9*3) && (CounterX<=FlowerPositionX+11*3) && (CounterY>=FlowerPositionY+5*3) && (CounterY<=FlowerPositionY+6*3)

||          (CounterX>=FlowerPositionX+3*3) && (CounterX<=FlowerPositionX+4*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)
||          (CounterX>=FlowerPositionX+6*3) && (CounterX<=FlowerPositionX+7*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)
||          (CounterX>=FlowerPositionX+8*3) && (CounterX<=FlowerPositionX+9*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)
||          (CounterX>=FlowerPositionX+11*3) && (CounterX<=FlowerPositionX+12*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)

||          (CounterX>=FlowerPositionX+1*3) && (CounterX<=FlowerPositionX+2*3) && (CounterY>=FlowerPositionY+8*3) && (CounterY<=FlowerPositionY+9*3)
||          (CounterX>=FlowerPositionX+14*3) && (CounterX<=FlowerPositionX+15*3) && (CounterY>=FlowerPositionY+8*3) && (CounterY<=FlowerPositionY+9*3)

||          (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+3*3) && (CounterY>=FlowerPositionY+9*3) && (CounterY<=FlowerPositionY+10*3)
||          (CounterX>=FlowerPositionX+13*3) && (CounterX<=FlowerPositionX+14*3) && (CounterY>=FlowerPositionY+9*3) && (CounterY<=FlowerPositionY+10*3)

||          (CounterX>=FlowerPositionX+3*3) && (CounterX<=FlowerPositionX+5*3) && (CounterY>=FlowerPositionY+10*3) && (CounterY<=FlowerPositionY+11*3)
||          (CounterX>=FlowerPositionX+11*3) && (CounterX<=FlowerPositionX+13*3) && (CounterY>=FlowerPositionY+10*3) && (CounterY<=FlowerPositionY+11*3)

||          (CounterX>=FlowerPositionX+5*3) && (CounterX<=FlowerPositionX+11*3) && (CounterY>=FlowerPositionY+11*3) && (CounterY<=FlowerPositionY+12*3)

||          (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+5*3) && (CounterY>=FlowerPositionY+12*3) && (CounterY<=FlowerPositionY+13*3)
||          (CounterX>=FlowerPositionX+6*3) && (CounterX<=FlowerPositionX+7*3) && (CounterY>=FlowerPositionY+12*3) && (CounterY<=FlowerPositionY+13*3)
||          (CounterX>=FlowerPositionX+9*3) && (CounterX<=FlowerPositionX+13*3) && (CounterY>=FlowerPositionY+12*3) && (CounterY<=FlowerPositionY+13*3)

||          (CounterX>=FlowerPositionX+1*3) && (CounterX<=FlowerPositionX+2*3) && (CounterY>=FlowerPositionY+13*3) && (CounterY<=FlowerPositionY+14*3)
||          (CounterX>=FlowerPositionX+5*3) && (CounterX<=FlowerPositionX+7*3) && (CounterY>=FlowerPositionY+13*3) && (CounterY<=FlowerPositionY+14*3)
||          (CounterX>=FlowerPositionX+9*3) && (CounterX<=FlowerPositionX+10*3) && (CounterY>=FlowerPositionY+13*3) && (CounterY<=FlowerPositionY+14*3)
||          (CounterX>=FlowerPositionX+13*3) && (CounterX<=FlowerPositionX+14*3) && (CounterY>=FlowerPositionY+13*3) && (CounterY<=FlowerPositionY+14*3)

||          (CounterX>=FlowerPositionX+0*3) && (CounterX<=FlowerPositionX+1*3) && (CounterY>=FlowerPositionY+14*3) && (CounterY<=FlowerPositionY+16*3)
||          (CounterX>=FlowerPositionX+6*3) && (CounterX<=FlowerPositionX+7*3) && (CounterY>=FlowerPositionY+14*3) && (CounterY<=FlowerPositionY+16*3)
||          (CounterX>=FlowerPositionX+8*3) && (CounterX<=FlowerPositionX+9*3) && (CounterY>=FlowerPositionY+14*3) && (CounterY<=FlowerPositionY+16*3)
||          (CounterX>=FlowerPositionX+14*3) && (CounterX<=FlowerPositionX+15*3) && (CounterY>=FlowerPositionY+14*3) && (CounterY<=FlowerPositionY+16*3)
||          (CounterX>=FlowerPositionX+7*3) && (CounterX<=FlowerPositionX+8*3) && (CounterY>=FlowerPositionY+15*3) && (CounterY<=FlowerPositionY+16*3)

||          (CounterX>=FlowerPositionX+0*3) && (CounterX<=FlowerPositionX+15*3) && (CounterY>=FlowerPositionY+11*3) && (CounterY<=FlowerPositionY+12*3);

FlowerRed <= (CounterX>=FlowerPositionX+7*3) && (CounterX<=FlowerPositionX+9*3) && (CounterY>=FlowerPositionY+1*3) && (CounterY<=FlowerPositionY+2*3)

||          (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+3*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+3*3)
||          (CounterX>=FlowerPositionX+6*3) && (CounterX<=FlowerPositionX+10*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+3*3)
||          (CounterX>=FlowerPositionX+13*3) && (CounterX<=FlowerPositionX+14*3) && (CounterY>=FlowerPositionY+2*3) && (CounterY<=FlowerPositionY+3*3)

||          (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+4*3) && (CounterY>=FlowerPositionY+3*3) && (CounterY<=FlowerPositionY+6*3)
||          (CounterX>=FlowerPositionX+5*3) && (CounterX<=FlowerPositionX+11*3) && (CounterY>=FlowerPositionY+3*3) && (CounterY<=FlowerPositionY+5*3)
||          (CounterX>=FlowerPositionX+12*3) && (CounterX<=FlowerPositionX+14*3) && (CounterY>=FlowerPositionY+3*3) && (CounterY<=FlowerPositionY+7*3)

||          (CounterX>=FlowerPositionX+1*3) && (CounterX<=FlowerPositionX+2*3) && (CounterY>=FlowerPositionY+4*3) && (CounterY<=FlowerPositionY+8*3)
||          (CounterX>=FlowerPositionX+4*3) && (CounterX<=FlowerPositionX+5*3) && (CounterY>=FlowerPositionY+4*3) && (CounterY<=FlowerPositionY+5*3)
||          (CounterX>=FlowerPositionX+11*3) && (CounterX<=FlowerPositionX+12*3) && (CounterY>=FlowerPositionY+4*3) && (CounterY<=FlowerPositionY+6*3)
||          (CounterX>=FlowerPositionX+14*3) && (CounterX<=FlowerPositionX+15*3) && (CounterY>=FlowerPositionY+4*3) && (CounterY<=FlowerPositionY+8*3)

||          (CounterX>=FlowerPositionX+6*3) && (CounterX<=FlowerPositionX+9*3) && (CounterY>=FlowerPositionY+5*3) && (CounterY<=FlowerPositionY+6*3)
||          (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+3*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)
||          (CounterX>=FlowerPositionX+4*3) && (CounterX<=FlowerPositionX+6*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)
||          (CounterX>=FlowerPositionX+7*3) && (CounterX<=FlowerPositionX+8*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)
||          (CounterX>=FlowerPositionX+9*3) && (CounterX<=FlowerPositionX+11*3) && (CounterY>=FlowerPositionY+6*3) && (CounterY<=FlowerPositionY+7*3)

||          (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+14*3) && (CounterY>=FlowerPositionY+7*3) && (CounterY<=FlowerPositionY+9*3)
||          (CounterX>=FlowerPositionX+3*3) && (CounterX<=FlowerPositionX+13*3) && (CounterY>=FlowerPositionY+9*3) && (CounterY<=FlowerPositionY+10*3)
||          (CounterX>=FlowerPositionX+5*3) && (CounterX<=FlowerPositionX+11*3) && (CounterY>=FlowerPositionY+10*3) && (CounterY<=FlowerPositionY+11*3);

FlowerGreen <= (CounterX>=FlowerPositionX+2*3) && (CounterX<=FlowerPositionX+5*3) && (CounterY>=FlowerPositionY+13*3) && (CounterY<=FlowerPositionY+14*3)

||	    	(CounterX>=FlowerPositionX+7*3) && (CounterX<=FlowerPositionX+9*3) && (CounterY>=FlowerPositionY+12*3) && (CounterY<=FlowerPositionY+14*3)
||          (CounterX>=FlowerPositionX+7*3) && (CounterX<=FlowerPositionX+8*3) && (CounterY>=FlowerPositionY+14*3) && (CounterY<=FlowerPositionY+15*3)

||          (CounterX>=FlowerPositionX+10*3) && (CounterX<=FlowerPositionX+13*3) && (CounterY>=FlowerPositionY+13*3) && (CounterY<=FlowerPositionY+14*3)

||          (CounterX>=FlowerPositionX+1*3) && (CounterX<=FlowerPositionX+6*3) && (CounterY>=FlowerPositionY+14*3) && (CounterY<=FlowerPositionY+16*3)
||          (CounterX>=FlowerPositionX+9*3) && (CounterX<=FlowerPositionX+14*3) && (CounterY>=FlowerPositionY+14*3) && (CounterY<=FlowerPositionY+16*3);



R_Item_on = MushroomWhite | MushroomRed | StarYellow | FlowerRed;
G_Item_on =	MushroomWhite | StarYellow | FlowerGreen;
B_Item_on =	MushroomWhite;

R_Item_off = MushroomBlack | StarBlack | FlowerBlack | FlowerGreen ;
G_Item_off = MushroomBlack | MushroomRed | StarBlack | FlowerBlack | FlowerRed;
B_Item_off = MushroomBlack | MushroomRed | StarBlack | StarYellow | FlowerBlack | FlowerRed | FlowerGreen ;

end
endmodule

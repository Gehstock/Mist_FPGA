`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    05:56:53 04/23/2014 
// Design Name: 
// Module Name:    DrawBird 
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
module DrawBird(input [24:0] Clks,Reset,CounterX,CounterY,Button,Status,output reg R_Bird_on,G_Bird_on,B_Bird_on,R_Bird_off,G_Bird_off,B_Bird_off);
//////////////////////////////////////////////////////////////////////////////////
reg [15:0] BirdPositionX = 100;
reg [15:0] BirdPositionY = 150;
reg [15:0] Gravity = 0;
reg [15:0] ForceUp = 0;
reg [15:0] BirdAnimation = 0;
reg Start = 0;

always @ (posedge Clks[18])
begin
		if (!Reset)
		begin
		BirdPositionX <= 100;
		BirdPositionY <= 150;
		Gravity <= 0;
		ForceUp <= 0;
		Start <= 0;
		end
		else if (Start == 0 && !Button) Start <= 1;
		else if (!Button && BirdPositionY > 8 && Start == 1 && Status == 1) 
			begin
			Gravity <= 0;
			BirdPositionY <= BirdPositionY - ForceUp;
			if (ForceUp<5) ForceUp <= ForceUp + 1;
		end
		else if (BirdPositionY > 385) BirdPositionY <= 390;
		else if ((BirdPositionY < 390 && Start == 1) || Status == 0)
			begin
			ForceUp <= 0;
			BirdPositionY <= BirdPositionY + Gravity;
			if (Gravity<10) Gravity <= Gravity + 1;
			end
		else if(BirdPositionY < 8) BirdPositionY <= 8;
end
//////////////////////////////////////////////////////////////////////////////////
always @ (posedge Clks[20])
begin
		if (BirdAnimation == 2 || !Reset) BirdAnimation <= 0;
		else if (Gravity > 0 && Status == 0) BirdAnimation <= 3;
		else if (Gravity > 0) BirdAnimation <= 0;
		else if (BirdAnimation < 2) BirdAnimation <= BirdAnimation + 1;
end
//////////////////////////////////////////////////////////////////////////////////
reg BirdBlack,BirdWhite,BirdYellow,BirdRed;
always @ (CounterX or CounterY)
begin
if (BirdAnimation == 0)
begin
BirdBlack <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+0) && (CounterY<=BirdPositionY+3)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||	(CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+12) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+21) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||	(CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+21) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+48) && (CounterX<=BirdPositionX+51) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||	(CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||	(CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+45) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||	(CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)

||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+33) && (CounterY<=BirdPositionY+36); 

BirdWhite <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||          (CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||          (CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21);

BirdYellow <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+21) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||          (CounterX>=BirdPositionX+21) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33);

BirdRed <= (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30);
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

else if (BirdAnimation == 1)
begin
BirdBlack <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+0) && (CounterY<=BirdPositionY+3)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||	(CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+12) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||	(CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+21) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||	(CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+21) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+48) && (CounterX<=BirdPositionX+51) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||	(CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||	(CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+45) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||	(CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)

||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+33) && (CounterY<=BirdPositionY+36);

BirdWhite <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||          (CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||          (CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21);

BirdYellow <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+21) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||          (CounterX>=BirdPositionX+21) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33);

BirdRed <= (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30);
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
else if (BirdAnimation==2)begin
BirdBlack <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+0) && (CounterY<=BirdPositionY+3)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||	(CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+12) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||	(CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+21) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+48) && (CounterX<=BirdPositionX+51) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+45) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)

||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+33) && (CounterY<=BirdPositionY+36);

BirdWhite <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||          (CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||          (CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30);

BirdYellow <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||          (CounterX>=BirdPositionX+21) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+12) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33);

BirdRed <= (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30);
end

else if (BirdAnimation==3)begin
BirdBlack <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+0) && (CounterY<=BirdPositionY+3)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+36) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||	(CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+12) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||	(CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||	(CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)
||	(CounterX>=BirdPositionX+42) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+21) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||	(CounterX>=BirdPositionX+48) && (CounterX<=BirdPositionX+51) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+24) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||	(CounterX>=BirdPositionX+0) && (CounterX<=BirdPositionX+3) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||	(CounterX>=BirdPositionX+45) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||	(CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)
||	(CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33)

||	(CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+33) && (CounterY<=BirdPositionY+36);

BirdWhite <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)
||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+36) && (CounterY>=BirdPositionY+3) && (CounterY<=BirdPositionY+6)

||          (CounterX>=BirdPositionX+12) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)
||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+39) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)
||          (CounterX>=BirdPositionX+39) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+42) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+15) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+9) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30);

BirdYellow <= (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+6) && (CounterY<=BirdPositionY+9)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+9) && (CounterY<=BirdPositionY+12)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+12) && (CounterY<=BirdPositionY+15)

||          (CounterX>=BirdPositionX+6) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+15) && (CounterY<=BirdPositionY+18)

||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+18) && (CounterY<=BirdPositionY+21)

||          (CounterX>=BirdPositionX+3) && (CounterX<=BirdPositionX+6) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+18) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)
||          (CounterX>=BirdPositionX+21) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+18) && (CounterX<=BirdPositionX+24) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+9) && (CounterX<=BirdPositionX+12) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)
||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+27) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30)

||          (CounterX>=BirdPositionX+15) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+30) && (CounterY<=BirdPositionY+33);

BirdRed <= (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+48) && (CounterY>=BirdPositionY+21) && (CounterY<=BirdPositionY+24)

||          (CounterX>=BirdPositionX+27) && (CounterX<=BirdPositionX+30) && (CounterY>=BirdPositionY+24) && (CounterY<=BirdPositionY+27)

||          (CounterX>=BirdPositionX+30) && (CounterX<=BirdPositionX+45) && (CounterY>=BirdPositionY+27) && (CounterY<=BirdPositionY+30);
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
R_Bird_on = BirdWhite | BirdRed | BirdYellow;
G_Bird_on =	BirdWhite | BirdYellow;
B_Bird_on =	BirdWhite;

R_Bird_off = BirdBlack;
G_Bird_off = BirdRed | BirdBlack;
B_Bird_off = BirdRed | BirdYellow | BirdBlack;

end
endmodule

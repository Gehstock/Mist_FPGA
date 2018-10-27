`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:01:28 04/23/2014 
// Design Name: 
// Module Name:    DrawPipes 
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
module DrawPipes2 (input [24:0] Clks,Reset,CounterX,CounterY,Button,Status,input [15:0] PipesLong,output reg R_Pipes_on,G_Pipes_on,B_Pipes_on,R_Pipes_off,G_Pipes_off,B_Pipes_off,output reg [15:0] PipesPosition);

reg PipesBlackTop,PipesGreenTop,PipesGreenBodyTop,PipesBlackBodyTop,PipesBlackBot,PipesGreenBot,PipesGreenBodyBot,PipesBlackBodyBot;
reg [15:0] TopPipesPositionX = 960;
reg [15:0] BotPipesPositionX = 960;
reg [15:0] TopPipesPositionY;
reg [15:0] BotPipesPositionY;
reg Start = 0;

always @ (posedge Clks[16])
begin
		if (!Reset)
	begin
	TopPipesPositionX <= 960;
	BotPipesPositionX <= 960;
	Start <= 0;
	end

	if (Start == 0 && !Button) Start <= 1;
	
	if (TopPipesPositionX == 0) TopPipesPositionX <= 640;
	else if (Start && Status) TopPipesPositionX <= TopPipesPositionX - 1;
		
	PipesPosition <= TopPipesPositionX;
	TopPipesPositionY <= PipesLong;
	BotPipesPositionX <= TopPipesPositionX;
	BotPipesPositionY <= TopPipesPositionY + 150;
	
end



always @ (CounterX or CounterY)
begin

PipesGreenBodyTop <= (CounterX>=TopPipesPositionX+12) && (CounterX<=TopPipesPositionX+78) && (CounterY>=0) && (CounterY<=TopPipesPositionY);

PipesBlackBodyTop <= (CounterX>=TopPipesPositionX+9) && (CounterX<=TopPipesPositionX+12) && (CounterY>=0) && (CounterY<=TopPipesPositionY)
|| (CounterX>=TopPipesPositionX+78) && (CounterX<=TopPipesPositionX+81) && (CounterY>=0) && (CounterY<=TopPipesPositionY);

PipesBlackTop <= (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+0) && (CounterY<=TopPipesPositionY+3)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+3) && (CounterY<=TopPipesPositionY+6)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+3) && (CounterY<=TopPipesPositionY+6)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+6) && (CounterY<=TopPipesPositionY+9)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+6) && (CounterY<=TopPipesPositionY+9)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+9) && (CounterY<=TopPipesPositionY+12)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+9) && (CounterY<=TopPipesPositionY+12)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+12) && (CounterY<=TopPipesPositionY+15)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+12) && (CounterY<=TopPipesPositionY+15)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+15) && (CounterY<=TopPipesPositionY+18)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+15) && (CounterY<=TopPipesPositionY+18)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+18) && (CounterY<=TopPipesPositionY+21)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+18) && (CounterY<=TopPipesPositionY+21)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+21) && (CounterY<=TopPipesPositionY+24)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+21) && (CounterY<=TopPipesPositionY+24)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+24) && (CounterY<=TopPipesPositionY+27)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+24) && (CounterY<=TopPipesPositionY+27)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+3) && (CounterY>=TopPipesPositionY+27) && (CounterY<=TopPipesPositionY+30)
||          (CounterX>=TopPipesPositionX+87) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+27) && (CounterY<=TopPipesPositionY+30)
||          (CounterX>=TopPipesPositionX+0) && (CounterX<=TopPipesPositionX+90) && (CounterY>=TopPipesPositionY+30) && (CounterY<=TopPipesPositionY+33);

PipesGreenTop <= (CounterX>=TopPipesPositionX+3) && (CounterX<=TopPipesPositionX+87) && (CounterY>=TopPipesPositionY+3) && (CounterY<=TopPipesPositionY+30);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
PipesGreenBodyBot <= (CounterX>=BotPipesPositionX+12) && (CounterX<=BotPipesPositionX+78) && (CounterY>=BotPipesPositionY) && (CounterY<=428);

PipesBlackBodyBot <= (CounterX>=BotPipesPositionX+9) && (CounterX<=BotPipesPositionX+12) && (CounterY>=BotPipesPositionY+33) && (CounterY<=428)
|| (CounterX>=BotPipesPositionX+78) && (CounterX<=BotPipesPositionX+81) && (CounterY>=BotPipesPositionY+33) && (CounterY<=428);

PipesBlackBot <= (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+0) && (CounterY<=BotPipesPositionY+3)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+3) && (CounterY<=BotPipesPositionY+6)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+3) && (CounterY<=BotPipesPositionY+6)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+6) && (CounterY<=BotPipesPositionY+9)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+6) && (CounterY<=BotPipesPositionY+9)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+9) && (CounterY<=BotPipesPositionY+12)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+9) && (CounterY<=BotPipesPositionY+12)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+12) && (CounterY<=BotPipesPositionY+15)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+12) && (CounterY<=BotPipesPositionY+15)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+15) && (CounterY<=BotPipesPositionY+18)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+15) && (CounterY<=BotPipesPositionY+18)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+18) && (CounterY<=BotPipesPositionY+21)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+18) && (CounterY<=BotPipesPositionY+21)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+21) && (CounterY<=BotPipesPositionY+24)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+21) && (CounterY<=BotPipesPositionY+24)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+24) && (CounterY<=BotPipesPositionY+27)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+24) && (CounterY<=BotPipesPositionY+27)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+3) && (CounterY>=BotPipesPositionY+27) && (CounterY<=BotPipesPositionY+30)
||          (CounterX>=BotPipesPositionX+87) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+27) && (CounterY<=BotPipesPositionY+30)
||          (CounterX>=BotPipesPositionX+0) && (CounterX<=BotPipesPositionX+90) && (CounterY>=BotPipesPositionY+30) && (CounterY<=BotPipesPositionY+33);

PipesGreenBot <= (CounterX>=BotPipesPositionX+3) && (CounterX<=BotPipesPositionX+87) && (CounterY>=BotPipesPositionY+3) && (CounterY<=BotPipesPositionY+30);


G_Pipes_on = PipesGreenTop | PipesGreenBodyTop | PipesGreenBot | PipesGreenBodyBot;


R_Pipes_off = PipesBlackTop | PipesGreenTop | PipesBlackBodyTop | PipesGreenBodyTop | PipesBlackBot | PipesGreenBot | PipesBlackBodyBot | PipesGreenBodyBot;
G_Pipes_off = PipesBlackTop | PipesBlackBodyTop | PipesBlackBot | PipesBlackBodyBot;
B_Pipes_off = PipesBlackTop | PipesGreenTop | PipesBlackBodyTop | PipesGreenBodyTop | PipesBlackBot | PipesGreenBot | PipesBlackBodyBot | PipesGreenBodyBot;

end
endmodule
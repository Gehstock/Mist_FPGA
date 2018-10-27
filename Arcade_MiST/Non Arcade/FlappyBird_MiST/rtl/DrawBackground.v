`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    05:30:00 04/23/2014 
// Design Name: 
// Module Name:    DrawBackground 
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
module DrawBackground(input [24:0] Clks,Status,CounterX,CounterY,output reg R_Background,G_Background,B_Background);
//////////////////////////////////////////////////////////////////////////////////
reg [5:0] GrassPosition;
always @ (posedge Clks[16])
if (GrassPosition[4]==1) GrassPosition <= 0;
else if (Status) GrassPosition <= GrassPosition + 1;

//////////////////////////////////////////////////////////////////////////////////
reg Sky,Dirt,OnGrass,Grass,Ground,Cloud;
always @ (CounterX or CounterY)
begin

Sky <= (CounterX>=0) && (CounterX<=640) && (CounterY>=0) && (CounterY<=428);
Dirt <= (CounterX>=0) && (CounterX<=640) && (CounterY>=429) && (CounterY<=430);
OnGrass <= (CounterY>=430 && CounterY<=450) && ((CounterX + (CounterY/2) + GrassPosition) %16 <= 8);
Grass <= (CounterX>=0) && (CounterX<=640) && (CounterY>=430) && (CounterY<=450);
Ground <= (CounterX>=0) && (CounterX<=640) && (CounterY>=450) && (CounterY<=480);

/*Cloud <= (CounterX>=16*3) && (CounterX<=29*3) && (CounterY>=0*3) && (CounterY<=1*3)

|| (CounterX>=13*3) && (CounterX<=31*3) && (CounterY>=1*3) && (CounterY<=2*3)
|| (CounterX>=11*3) && (CounterX<=35*3) && (CounterY>=2*3) && (CounterY<=3*3)
|| (CounterX>=9*3) && (CounterX<=37*3) && (CounterY>=3*3) && (CounterY<=4*3)
||	(CounterX>=8*3) && (CounterX<=38*3) && (CounterY>=4*3) && (CounterY<=5*3)
||	(CounterX>=6*3) && (CounterX<=40*3) && (CounterY>=5*3) && (CounterY<=6*3)
||	(CounterX>=5*3) && (CounterX<=41*3) && (CounterY>=6*3) && (CounterY<=7*3)
||	(CounterX>=4*3) && (CounterX<=41*3) && (CounterY>=7*3) && (CounterY<=8*3)
||	(CounterX>=4*3) && (CounterX<=42*3) && (CounterY>=8*3) && (CounterY<=9*3)
||	(CounterX>=3*3) && (CounterX<=43*3) && (CounterY>=9*3) && (CounterY<=10*3)
||	(CounterX>=2*3) && (CounterX<=44*3) && (CounterY>=10*3) && (CounterY<=11*3)
||	(CounterX>=2*3) && (CounterX<=44*3) && (CounterY>=11*3) && (CounterY<=12*3)
||	(CounterX>=54*3) && (CounterX<=69*3) && (CounterY>=11*3) && (CounterY<=12*3)
||	(CounterX>=1*3) && (CounterX<=45*3) && (CounterY>=12*3) && (CounterY<=13*3)
||	(CounterX>=52*3) && (CounterX<=73*3) && (CounterY>=12*3) && (CounterY<=13*3)
||	(CounterX>=1*3) && (CounterX<=45*3) && (CounterY>=13*3) && (CounterY<=14*3)
||	(CounterX>=51*3) && (CounterX<=75*3) && (CounterY>=13*3) && (CounterY<=14*3)
||	(CounterX>=1*3) && (CounterX<=46*3) && (CounterY>=14*3) && (CounterY<=15*3)
||	(CounterX>=49*3) && (CounterX<=77*3) && (CounterY>=14*3) && (CounterY<=15*3)
||	(CounterX>=0*3) && (CounterX<=46*3) && (CounterY>=15*3) && (CounterY<=16*3)
||	(CounterX>=49*3) && (CounterX<=78*3) && (CounterY>=15*3) && (CounterY<=16*3)
||	(CounterX>=0*3) && (CounterX<=47*3) && (CounterY>=16*3) && (CounterY<=17*3)
||	(CounterX>=48*3) && (CounterX<=79*3) && (CounterY>=16*3) && (CounterY<=17*3)
||	(CounterX>=0*3) && (CounterX<=79*3) && (CounterY>=17*3) && (CounterY<=18*3)
||	(CounterX>=0*3) && (CounterX<=79*3) && (CounterY>=18*3) && (CounterY<=19*3)
||	(CounterX>=0*3) && (CounterX<=79*3) && (CounterY>=19*3) && (CounterY<=20*3)
||	(CounterX>=0*3) && (CounterX<=79*3) && (CounterY>=20*3) && (CounterY<=21*3);
*/

R_Background = OnGrass | Ground | CounterX^CounterY;
G_Background = Sky | Dirt | Grass | OnGrass | Ground;
B_Background = Sky | OnGrass ;
end
endmodule

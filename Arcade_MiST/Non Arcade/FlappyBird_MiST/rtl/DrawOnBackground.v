`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:25:00 04/28/2014 
// Design Name: 
// Module Name:    DrawOnBackground 
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
module DrawOnBackground(input [24:0] Clks,CounterX,CounterY,output reg R_OnBackground_on,G_OnBackground_on,B_OnBackground_on,R_OnBackground_off,G_OnBackground_off,B_OnBackground_off);

reg [15:0] TownPositionX = 0;
reg [15:0] TownPositionY = 368;

reg [15:0] GlassPositionX = 0;
reg [15:0] GlassPositionY = 398;

reg [15:0] CloudPositionX = 0;
reg [15:0] CloudPositionY = 338;

reg TownBlue,GlassBlack,GlassGreen,Cloud;
always @ (CounterX or CounterY)
begin
Cloud <= 	(CounterX>=0) && (CounterX<=640) && (CounterY>=362) && (CounterY<=428)

||				(CounterX>=CloudPositionX+24*3) && (CounterX<=CloudPositionX+27*3) && (CounterY>=CloudPositionY+0*3) && (CounterY<=CloudPositionY+1*3)
||          (CounterX>=CloudPositionX+13*3) && (CounterX<=CloudPositionX+16*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)
||          (CounterX>=CloudPositionX+22*3) && (CounterX<=CloudPositionX+29*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)

||          (CounterX>=CloudPositionX+11*3) && (CounterX<=CloudPositionX+18*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+21*3) && (CounterX<=CloudPositionX+30*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+36*3) && (CounterX<=CloudPositionX+39*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)

||          (CounterX>=CloudPositionX+4*3) && (CounterX<=CloudPositionX+7*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+10*3) && (CounterX<=CloudPositionX+19*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+20*3) && (CounterX<=CloudPositionX+31*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+34*3) && (CounterX<=CloudPositionX+41*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)

||          (CounterX>=CloudPositionX+3*3) && (CounterX<=CloudPositionX+8*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+9*3) && (CounterX<=CloudPositionX+32*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+33*3) && (CounterX<=CloudPositionX+42*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)

||          (CounterX>=CloudPositionX+2*3) && (CounterX<=CloudPositionX+44*3) && (CounterY>=CloudPositionY+5*3) && (CounterY<=CloudPositionY+6*3)
||          (CounterX>=CloudPositionX+1*3) && (CounterX<=CloudPositionX+45*3) && (CounterY>=CloudPositionY+6*3) && (CounterY<=CloudPositionY+7*3)
||          (CounterX>=CloudPositionX+0*3) && (CounterX<=CloudPositionX+45*3) && (CounterY>=CloudPositionY+7*3) && (CounterY<=CloudPositionY+8*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||				(CounterX>=CloudPositionX+135+24*3) && (CounterX<=CloudPositionX+135+27*3) && (CounterY>=CloudPositionY+0*3) && (CounterY<=CloudPositionY+1*3)
||          (CounterX>=CloudPositionX+135+13*3) && (CounterX<=CloudPositionX+135+16*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)
||          (CounterX>=CloudPositionX+135+22*3) && (CounterX<=CloudPositionX+135+29*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)

||          (CounterX>=CloudPositionX+135+11*3) && (CounterX<=CloudPositionX+135+18*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135+21*3) && (CounterX<=CloudPositionX+135+30*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135+36*3) && (CounterX<=CloudPositionX+135+39*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)

||          (CounterX>=CloudPositionX+135+4*3) && (CounterX<=CloudPositionX+135+7*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135+10*3) && (CounterX<=CloudPositionX+135+19*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135+20*3) && (CounterX<=CloudPositionX+135+31*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135+34*3) && (CounterX<=CloudPositionX+135+41*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)

||          (CounterX>=CloudPositionX+135+3*3) && (CounterX<=CloudPositionX+135+8*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135+9*3) && (CounterX<=CloudPositionX+135+32*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135+33*3) && (CounterX<=CloudPositionX+135+42*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)

||          (CounterX>=CloudPositionX+135+2*3) && (CounterX<=CloudPositionX+135+44*3) && (CounterY>=CloudPositionY+5*3) && (CounterY<=CloudPositionY+6*3)
||          (CounterX>=CloudPositionX+135+1*3) && (CounterX<=CloudPositionX+135+45*3) && (CounterY>=CloudPositionY+6*3) && (CounterY<=CloudPositionY+7*3)
||          (CounterX>=CloudPositionX+135+0*3) && (CounterX<=CloudPositionX+135+45*3) && (CounterY>=CloudPositionY+7*3) && (CounterY<=CloudPositionY+8*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||				(CounterX>=CloudPositionX+135*2+24*3) && (CounterX<=CloudPositionX+135*2+27*3) && (CounterY>=CloudPositionY+0*3) && (CounterY<=CloudPositionY+1*3)
||          (CounterX>=CloudPositionX+135*2+13*3) && (CounterX<=CloudPositionX+135*2+16*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)
||          (CounterX>=CloudPositionX+135*2+22*3) && (CounterX<=CloudPositionX+135*2+29*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)

||          (CounterX>=CloudPositionX+135*2+11*3) && (CounterX<=CloudPositionX+135*2+18*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135*2+21*3) && (CounterX<=CloudPositionX+135*2+30*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135*2+36*3) && (CounterX<=CloudPositionX+135*2+39*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)

||          (CounterX>=CloudPositionX+135*2+4*3) && (CounterX<=CloudPositionX+135*2+7*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*2+10*3) && (CounterX<=CloudPositionX+135*2+19*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*2+20*3) && (CounterX<=CloudPositionX+135*2+31*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*2+34*3) && (CounterX<=CloudPositionX+135*2+41*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)

||          (CounterX>=CloudPositionX+135*2+3*3) && (CounterX<=CloudPositionX+135*2+8*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135*2+9*3) && (CounterX<=CloudPositionX+135*2+32*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135*2+33*3) && (CounterX<=CloudPositionX+135*2+42*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)

||          (CounterX>=CloudPositionX+135*2+2*3) && (CounterX<=CloudPositionX+135*2+44*3) && (CounterY>=CloudPositionY+5*3) && (CounterY<=CloudPositionY+6*3)
||          (CounterX>=CloudPositionX+135*2+1*3) && (CounterX<=CloudPositionX+135*2+45*3) && (CounterY>=CloudPositionY+6*3) && (CounterY<=CloudPositionY+7*3)
||          (CounterX>=CloudPositionX+135*2+0*3) && (CounterX<=CloudPositionX+135*2+45*3) && (CounterY>=CloudPositionY+7*3) && (CounterY<=CloudPositionY+8*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||				(CounterX>=CloudPositionX+135*3+24*3) && (CounterX<=CloudPositionX+135*3+27*3) && (CounterY>=CloudPositionY+0*3) && (CounterY<=CloudPositionY+1*3)
||          (CounterX>=CloudPositionX+135*3+13*3) && (CounterX<=CloudPositionX+135*3+16*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)
||          (CounterX>=CloudPositionX+135*3+22*3) && (CounterX<=CloudPositionX+135*3+29*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)

||          (CounterX>=CloudPositionX+135*3+11*3) && (CounterX<=CloudPositionX+135*3+18*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135*3+21*3) && (CounterX<=CloudPositionX+135*3+30*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135*3+36*3) && (CounterX<=CloudPositionX+135*3+39*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)

||          (CounterX>=CloudPositionX+135*3+4*3) && (CounterX<=CloudPositionX+135*3+7*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*3+10*3) && (CounterX<=CloudPositionX+135*3+19*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*3+20*3) && (CounterX<=CloudPositionX+135*3+31*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*3+34*3) && (CounterX<=CloudPositionX+135*3+41*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)

||          (CounterX>=CloudPositionX+135*3+3*3) && (CounterX<=CloudPositionX+135*3+8*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135*3+9*3) && (CounterX<=CloudPositionX+135*3+32*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135*3+33*3) && (CounterX<=CloudPositionX+135*3+42*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)

||          (CounterX>=CloudPositionX+135*3+2*3) && (CounterX<=CloudPositionX+135*3+44*3) && (CounterY>=CloudPositionY+5*3) && (CounterY<=CloudPositionY+6*3)
||          (CounterX>=CloudPositionX+135*3+1*3) && (CounterX<=CloudPositionX+135*3+45*3) && (CounterY>=CloudPositionY+6*3) && (CounterY<=CloudPositionY+7*3)
||          (CounterX>=CloudPositionX+135*3+0*3) && (CounterX<=CloudPositionX+135*3+45*3) && (CounterY>=CloudPositionY+7*3) && (CounterY<=CloudPositionY+8*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||				(CounterX>=CloudPositionX+135*4+24*3) && (CounterX<=CloudPositionX+135*4+27*3) && (CounterY>=CloudPositionY+0*3) && (CounterY<=CloudPositionY+1*3)
||          (CounterX>=CloudPositionX+135*4+13*3) && (CounterX<=CloudPositionX+135*4+16*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)
||          (CounterX>=CloudPositionX+135*4+22*3) && (CounterX<=CloudPositionX+135*4+29*3) && (CounterY>=CloudPositionY+1*3) && (CounterY<=CloudPositionY+2*3)

||          (CounterX>=CloudPositionX+135*4+11*3) && (CounterX<=CloudPositionX+135*4+18*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135*4+21*3) && (CounterX<=CloudPositionX+135*4+30*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)
||          (CounterX>=CloudPositionX+135*4+36*3) && (CounterX<=CloudPositionX+135*4+39*3) && (CounterY>=CloudPositionY+2*3) && (CounterY<=CloudPositionY+3*3)

||          (CounterX>=CloudPositionX+135*4+4*3) && (CounterX<=CloudPositionX+135*4+7*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*4+10*3) && (CounterX<=CloudPositionX+135*4+19*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*4+20*3) && (CounterX<=CloudPositionX+135*4+31*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)
||          (CounterX>=CloudPositionX+135*4+34*3) && (CounterX<=CloudPositionX+135*4+41*3) && (CounterY>=CloudPositionY+3*3) && (CounterY<=CloudPositionY+4*3)

||          (CounterX>=CloudPositionX+135*4+3*3) && (CounterX<=CloudPositionX+135*4+8*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135*4+9*3) && (CounterX<=CloudPositionX+135*4+32*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)
||          (CounterX>=CloudPositionX+135*4+33*3) && (CounterX<=CloudPositionX+135*4+42*3) && (CounterY>=CloudPositionY+4*3) && (CounterY<=CloudPositionY+5*3)

||          (CounterX>=CloudPositionX+135*4+2*3) && (CounterX<=CloudPositionX+135*4+44*3) && (CounterY>=CloudPositionY+5*3) && (CounterY<=CloudPositionY+6*3)
||          (CounterX>=CloudPositionX+135*4+1*3) && (CounterX<=CloudPositionX+135*4+45*3) && (CounterY>=CloudPositionY+6*3) && (CounterY<=CloudPositionY+7*3)
||          (CounterX>=CloudPositionX+135*4+0*3) && (CounterX<=CloudPositionX+135*4+45*3) && (CounterY>=CloudPositionY+7*3) && (CounterY<=CloudPositionY+8*3);


TownBlue <= (CounterX>=TownPositionX+15+10*3) && (CounterX<=TownPositionX+15+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+15+8*3) && (CounterX<=TownPositionX+15+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+13*3) && (CounterX<=TownPositionX+15+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+8*3) && (CounterX<=TownPositionX+15+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+13*3) && (CounterX<=TownPositionX+15+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+10*3) && (CounterX<=TownPositionX+15+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+10*3) && (CounterX<=TownPositionX+15+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+10*3) && (CounterX<=TownPositionX+15+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+10*3) && (CounterX<=TownPositionX+15+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+15+0*3) && (CounterX<=TownPositionX+15+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+15+3*3) && (CounterX<=TownPositionX+15+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+3*3) && (CounterX<=TownPositionX+15+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+6*3) && (CounterX<=TownPositionX+15+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+15+0*3) && (CounterX<=TownPositionX+15+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+0*3) && (CounterX<=TownPositionX+15+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+2*3) && (CounterX<=TownPositionX+15+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+4*3) && (CounterX<=TownPositionX+15+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+15+14*3) && (CounterX<=TownPositionX+15+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+15*3) && (CounterX<=TownPositionX+15+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+15+14*3) && (CounterX<=TownPositionX+15+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+15+17*3) && (CounterX<=TownPositionX+15+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+15*3) && (CounterX<=TownPositionX+15+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
||			(CounterX>=TownPositionX+99+10*3) && (CounterX<=TownPositionX+99+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+99+8*3) && (CounterX<=TownPositionX+99+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+99+13*3) && (CounterX<=TownPositionX+99+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+99+8*3) && (CounterX<=TownPositionX+99+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+99+13*3) && (CounterX<=TownPositionX+99+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+99+10*3) && (CounterX<=TownPositionX+99+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+99+10*3) && (CounterX<=TownPositionX+99+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+99+10*3) && (CounterX<=TownPositionX+99+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+99+10*3) && (CounterX<=TownPositionX+99+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+99+0*3) && (CounterX<=TownPositionX+99+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+99+3*3) && (CounterX<=TownPositionX+99+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+99+3*3) && (CounterX<=TownPositionX+99+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+99+6*3) && (CounterX<=TownPositionX+99+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+99+0*3) && (CounterX<=TownPositionX+99+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+99+0*3) && (CounterX<=TownPositionX+99+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+99+2*3) && (CounterX<=TownPositionX+99+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+99+4*3) && (CounterX<=TownPositionX+99+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+99+14*3) && (CounterX<=TownPositionX+99+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+99+15*3) && (CounterX<=TownPositionX+99+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+99+14*3) && (CounterX<=TownPositionX+99+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+99+17*3) && (CounterX<=TownPositionX+99+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+99+15*3) && (CounterX<=TownPositionX+99+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
||				(CounterX>=TownPositionX+84*2+15+10*3) && (CounterX<=TownPositionX+84*2+15+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+84*2+15+8*3) && (CounterX<=TownPositionX+84*2+15+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+84*2+15+13*3) && (CounterX<=TownPositionX+84*2+15+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+84*2+15+8*3) && (CounterX<=TownPositionX+84*2+15+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+84*2+15+13*3) && (CounterX<=TownPositionX+84*2+15+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+84*2+15+10*3) && (CounterX<=TownPositionX+84*2+15+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+84*2+15+10*3) && (CounterX<=TownPositionX+84*2+15+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+84*2+15+10*3) && (CounterX<=TownPositionX+84*2+15+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+84*2+15+10*3) && (CounterX<=TownPositionX+84*2+15+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+84*2+15+0*3) && (CounterX<=TownPositionX+84*2+15+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+84*2+15+3*3) && (CounterX<=TownPositionX+84*2+15+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+84*2+15+3*3) && (CounterX<=TownPositionX+84*2+15+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+84*2+15+6*3) && (CounterX<=TownPositionX+84*2+15+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+84*2+15+0*3) && (CounterX<=TownPositionX+84*2+15+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+84*2+15+0*3) && (CounterX<=TownPositionX+84*2+15+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+84*2+15+2*3) && (CounterX<=TownPositionX+84*2+15+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+84*2+15+4*3) && (CounterX<=TownPositionX+84*2+15+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+84*2+15+14*3) && (CounterX<=TownPositionX+84*2+15+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+84*2+15+15*3) && (CounterX<=TownPositionX+84*2+15+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+84*2+15+14*3) && (CounterX<=TownPositionX+84*2+15+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+84*2+15+17*3) && (CounterX<=TownPositionX+84*2+15+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+84*2+15+15*3) && (CounterX<=TownPositionX+84*2+15+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
||			(CounterX>=TownPositionX+15+84*3+10*3) && (CounterX<=TownPositionX+15+84*3+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+15+84*3+8*3) && (CounterX<=TownPositionX+15+84*3+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*3+13*3) && (CounterX<=TownPositionX+15+84*3+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*3+8*3) && (CounterX<=TownPositionX+15+84*3+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*3+13*3) && (CounterX<=TownPositionX+15+84*3+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*3+10*3) && (CounterX<=TownPositionX+15+84*3+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*3+10*3) && (CounterX<=TownPositionX+15+84*3+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*3+10*3) && (CounterX<=TownPositionX+15+84*3+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*3+10*3) && (CounterX<=TownPositionX+15+84*3+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+15+84*3+0*3) && (CounterX<=TownPositionX+15+84*3+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+15+84*3+3*3) && (CounterX<=TownPositionX+15+84*3+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*3+3*3) && (CounterX<=TownPositionX+15+84*3+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*3+6*3) && (CounterX<=TownPositionX+15+84*3+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+15+84*3+0*3) && (CounterX<=TownPositionX+15+84*3+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*3+0*3) && (CounterX<=TownPositionX+15+84*3+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*3+2*3) && (CounterX<=TownPositionX+15+84*3+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*3+4*3) && (CounterX<=TownPositionX+15+84*3+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+15+84*3+14*3) && (CounterX<=TownPositionX+15+84*3+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*3+15*3) && (CounterX<=TownPositionX+15+84*3+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+15+84*3+14*3) && (CounterX<=TownPositionX+15+84*3+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+15+84*3+17*3) && (CounterX<=TownPositionX+15+84*3+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*3+15*3) && (CounterX<=TownPositionX+15+84*3+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
||			(CounterX>=TownPositionX+15+84*4+10*3) && (CounterX<=TownPositionX+15+84*4+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+15+84*4+8*3) && (CounterX<=TownPositionX+15+84*4+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*4+13*3) && (CounterX<=TownPositionX+15+84*4+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*4+8*3) && (CounterX<=TownPositionX+15+84*4+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*4+13*3) && (CounterX<=TownPositionX+15+84*4+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*4+10*3) && (CounterX<=TownPositionX+15+84*4+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*4+10*3) && (CounterX<=TownPositionX+15+84*4+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*4+10*3) && (CounterX<=TownPositionX+15+84*4+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*4+10*3) && (CounterX<=TownPositionX+15+84*4+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+15+84*4+0*3) && (CounterX<=TownPositionX+15+84*4+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+15+84*4+3*3) && (CounterX<=TownPositionX+15+84*4+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*4+3*3) && (CounterX<=TownPositionX+15+84*4+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*4+6*3) && (CounterX<=TownPositionX+15+84*4+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+15+84*4+0*3) && (CounterX<=TownPositionX+15+84*4+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*4+0*3) && (CounterX<=TownPositionX+15+84*4+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*4+2*3) && (CounterX<=TownPositionX+15+84*4+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*4+4*3) && (CounterX<=TownPositionX+15+84*4+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+15+84*4+14*3) && (CounterX<=TownPositionX+15+84*4+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*4+15*3) && (CounterX<=TownPositionX+15+84*4+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+15+84*4+14*3) && (CounterX<=TownPositionX+15+84*4+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+15+84*4+17*3) && (CounterX<=TownPositionX+15+84*4+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*4+15*3) && (CounterX<=TownPositionX+15+84*4+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
||			(CounterX>=TownPositionX+15+84*5+10*3) && (CounterX<=TownPositionX+15+84*5+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+15+84*5+8*3) && (CounterX<=TownPositionX+15+84*5+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*5+13*3) && (CounterX<=TownPositionX+15+84*5+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*5+8*3) && (CounterX<=TownPositionX+15+84*5+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*5+13*3) && (CounterX<=TownPositionX+15+84*5+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*5+10*3) && (CounterX<=TownPositionX+15+84*5+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*5+10*3) && (CounterX<=TownPositionX+15+84*5+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*5+10*3) && (CounterX<=TownPositionX+15+84*5+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*5+10*3) && (CounterX<=TownPositionX+15+84*5+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+15+84*5+0*3) && (CounterX<=TownPositionX+15+84*5+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+15+84*5+3*3) && (CounterX<=TownPositionX+15+84*5+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*5+3*3) && (CounterX<=TownPositionX+15+84*5+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*5+6*3) && (CounterX<=TownPositionX+15+84*5+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+15+84*5+0*3) && (CounterX<=TownPositionX+15+84*5+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*5+0*3) && (CounterX<=TownPositionX+15+84*5+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*5+2*3) && (CounterX<=TownPositionX+15+84*5+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*5+4*3) && (CounterX<=TownPositionX+15+84*5+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+15+84*5+14*3) && (CounterX<=TownPositionX+15+84*5+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*5+15*3) && (CounterX<=TownPositionX+15+84*5+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+15+84*5+14*3) && (CounterX<=TownPositionX+15+84*5+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+15+84*5+17*3) && (CounterX<=TownPositionX+15+84*5+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*5+15*3) && (CounterX<=TownPositionX+15+84*5+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
||			(CounterX>=TownPositionX+15+84*6+10*3) && (CounterX<=TownPositionX+15+84*6+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+15+84*6+8*3) && (CounterX<=TownPositionX+15+84*6+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*6+13*3) && (CounterX<=TownPositionX+15+84*6+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*6+8*3) && (CounterX<=TownPositionX+15+84*6+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*6+13*3) && (CounterX<=TownPositionX+15+84*6+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*6+10*3) && (CounterX<=TownPositionX+15+84*6+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*6+10*3) && (CounterX<=TownPositionX+15+84*6+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*6+10*3) && (CounterX<=TownPositionX+15+84*6+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*6+10*3) && (CounterX<=TownPositionX+15+84*6+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+15+84*6+0*3) && (CounterX<=TownPositionX+15+84*6+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+15+84*6+3*3) && (CounterX<=TownPositionX+15+84*6+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*6+3*3) && (CounterX<=TownPositionX+15+84*6+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*6+6*3) && (CounterX<=TownPositionX+15+84*6+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+15+84*6+0*3) && (CounterX<=TownPositionX+15+84*6+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*6+0*3) && (CounterX<=TownPositionX+15+84*6+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*6+2*3) && (CounterX<=TownPositionX+15+84*6+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*6+4*3) && (CounterX<=TownPositionX+15+84*6+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+15+84*6+14*3) && (CounterX<=TownPositionX+15+84*6+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*6+15*3) && (CounterX<=TownPositionX+15+84*6+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+15+84*6+14*3) && (CounterX<=TownPositionX+15+84*6+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+15+84*6+17*3) && (CounterX<=TownPositionX+15+84*6+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*6+15*3) && (CounterX<=TownPositionX+15+84*6+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
||				(CounterX>=TownPositionX+15+84*7+10*3) && (CounterX<=TownPositionX+15+84*7+14*3) && (CounterY>=TownPositionY+0*3) && (CounterY<=TownPositionY+1*3)

||          (CounterX>=TownPositionX+15+84*7+8*3) && (CounterX<=TownPositionX+15+84*7+11*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*7+13*3) && (CounterX<=TownPositionX+15+84*7+14*3) && (CounterY>=TownPositionY+1*3) && (CounterY<=TownPositionY+2*3)

||          (CounterX>=TownPositionX+15+84*7+8*3) && (CounterX<=TownPositionX+15+84*7+9*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*7+13*3) && (CounterX<=TownPositionX+15+84*7+14*3) && (CounterY>=TownPositionY+2*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*7+10*3) && (CounterX<=TownPositionX+15+84*7+11*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*7+10*3) && (CounterX<=TownPositionX+15+84*7+11*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*7+10*3) && (CounterX<=TownPositionX+15+84*7+11*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*7+10*3) && (CounterX<=TownPositionX+15+84*7+11*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+15+84*7+0*3) && (CounterX<=TownPositionX+15+84*7+18*3) && (CounterY>=TownPositionY+12*3) && (CounterY<=TownPositionY+13*3)

||          (CounterX>=TownPositionX+15+84*7+3*3) && (CounterX<=TownPositionX+15+84*7+6*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+4*3)
||          (CounterX>=TownPositionX+15+84*7+3*3) && (CounterX<=TownPositionX+15+84*7+4*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*7+6*3) && (CounterX<=TownPositionX+15+84*7+7*3) && (CounterY>=TownPositionY+3*3) && (CounterY<=TownPositionY+9*3)

||          (CounterX>=TownPositionX+15+84*7+0*3) && (CounterX<=TownPositionX+15+84*7+6*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)
||          (CounterX>=TownPositionX+15+84*7+0*3) && (CounterX<=TownPositionX+15+84*7+1*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*7+2*3) && (CounterX<=TownPositionX+15+84*7+3*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)
||          (CounterX>=TownPositionX+15+84*7+4*3) && (CounterX<=TownPositionX+15+84*7+5*3) && (CounterY>=TownPositionY+7*3) && (CounterY<=TownPositionY+8*3)

||          (CounterX>=TownPositionX+15+84*7+14*3) && (CounterX<=TownPositionX+15+84*7+16*3) && (CounterY>=TownPositionY+4*3) && (CounterY<=TownPositionY+5*3)
||          (CounterX>=TownPositionX+15+84*7+15*3) && (CounterX<=TownPositionX+15+84*7+16*3) && (CounterY>=TownPositionY+5*3) && (CounterY<=TownPositionY+6*3)

||          (CounterX>=TownPositionX+15+84*7+14*3) && (CounterX<=TownPositionX+15+84*7+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+7*3)
||          (CounterX>=TownPositionX+15+84*7+17*3) && (CounterX<=TownPositionX+15+84*7+18*3) && (CounterY>=TownPositionY+6*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*7+15*3) && (CounterX<=TownPositionX+15+84*7+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


||          (CounterX>=TownPositionX+15+3*3) && (CounterX<=TownPositionX+15+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)
||          (CounterX>=TownPositionX+99+3*3) && (CounterX<=TownPositionX+99+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)
||          (CounterX>=TownPositionX+15+84*2+3*3) && (CounterX<=TownPositionX+15+84*2+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)
||          (CounterX>=TownPositionX+15+84*3+3*3) && (CounterX<=TownPositionX+15+84*3+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)
||          (CounterX>=TownPositionX+15+84*4+3*3) && (CounterX<=TownPositionX+15+84*4+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)
||          (CounterX>=TownPositionX+15+84*5+3*3) && (CounterX<=TownPositionX+15+84*5+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)
||          (CounterX>=TownPositionX+15+84*6+3*3) && (CounterX<=TownPositionX+15+84*6+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)
||          (CounterX>=TownPositionX+15+84*7+3*3) && (CounterX<=TownPositionX+15+84*7+8*3) && (CounterY>=TownPositionY+9*3) && (CounterY<=TownPositionY+10*3)

||          (CounterX>=TownPositionX+15+3*3) && (CounterX<=TownPositionX+15+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+99*3+3*3) && (CounterX<=TownPositionX+99+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*2+3*3) && (CounterX<=TownPositionX+15+84*2+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*3+3*3) && (CounterX<=TownPositionX+15+84*3+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*4+3*3) && (CounterX<=TownPositionX+15+84*4+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*5+3*3) && (CounterX<=TownPositionX+15+84*5+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*6+3*3) && (CounterX<=TownPositionX+15+84*6+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)
||          (CounterX>=TownPositionX+15+84*7+3*3) && (CounterX<=TownPositionX+15+84*7+4*3) && (CounterY>=TownPositionY+10*3) && (CounterY<=TownPositionY+12*3)

||          (CounterX>=TownPositionX+15+84*9+15*3) && (CounterX<=TownPositionX+15+84*9+16*3) && (CounterY>=TownPositionY+8*3) && (CounterY<=TownPositionY+9*3);


GlassBlack <= (CounterX>=GlassPositionX+6*3) && (CounterX<=GlassPositionX+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+20*3) && (CounterX<=GlassPositionX+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+4*3) && (CounterX<=GlassPositionX+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+9*3) && (CounterX<=GlassPositionX+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+18*3) && (CounterX<=GlassPositionX+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+23*3) && (CounterX<=GlassPositionX+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+2*3) && (CounterX<=GlassPositionX+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+11*3) && (CounterX<=GlassPositionX+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+14*3) && (CounterX<=GlassPositionX+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+25*3) && (CounterX<=GlassPositionX+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+1*3) && (CounterX<=GlassPositionX+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+13*3) && (CounterX<=GlassPositionX+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+18*3) && (CounterX<=GlassPositionX+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+27*3) && (CounterX<=GlassPositionX+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+0*3) && (CounterX<=GlassPositionX+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+12*3) && (CounterX<=GlassPositionX+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+19*3) && (CounterX<=GlassPositionX+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84+6*3) && (CounterX<=GlassPositionX+84+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84+20*3) && (CounterX<=GlassPositionX+84+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84+4*3) && (CounterX<=GlassPositionX+84+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84+9*3) && (CounterX<=GlassPositionX+84+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84+18*3) && (CounterX<=GlassPositionX+84+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84+23*3) && (CounterX<=GlassPositionX+84+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84+2*3) && (CounterX<=GlassPositionX+84+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84+11*3) && (CounterX<=GlassPositionX+84+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84+14*3) && (CounterX<=GlassPositionX+84+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84+25*3) && (CounterX<=GlassPositionX+84+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84+1*3) && (CounterX<=GlassPositionX+84+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84+13*3) && (CounterX<=GlassPositionX+84+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84+18*3) && (CounterX<=GlassPositionX+84+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84+27*3) && (CounterX<=GlassPositionX+84+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84+0*3) && (CounterX<=GlassPositionX+84+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84+12*3) && (CounterX<=GlassPositionX+84+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84+19*3) && (CounterX<=GlassPositionX+84+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*2+6*3) && (CounterX<=GlassPositionX+84*2+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*2+20*3) && (CounterX<=GlassPositionX+84*2+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*2+4*3) && (CounterX<=GlassPositionX+84*2+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*2+9*3) && (CounterX<=GlassPositionX+84*2+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*2+18*3) && (CounterX<=GlassPositionX+84*2+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*2+23*3) && (CounterX<=GlassPositionX+84*2+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*2+2*3) && (CounterX<=GlassPositionX+84*2+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*2+11*3) && (CounterX<=GlassPositionX+84*2+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*2+14*3) && (CounterX<=GlassPositionX+84*2+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*2+25*3) && (CounterX<=GlassPositionX+84*2+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*2+1*3) && (CounterX<=GlassPositionX+84*2+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*2+13*3) && (CounterX<=GlassPositionX+84*2+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*2+18*3) && (CounterX<=GlassPositionX+84*2+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*2+27*3) && (CounterX<=GlassPositionX+84*2+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*2+0*3) && (CounterX<=GlassPositionX+84*2+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*2+12*3) && (CounterX<=GlassPositionX+84*2+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*2+19*3) && (CounterX<=GlassPositionX+84*2+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*3+6*3) && (CounterX<=GlassPositionX+84*3+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*3+20*3) && (CounterX<=GlassPositionX+84*3+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*3+4*3) && (CounterX<=GlassPositionX+84*3+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*3+9*3) && (CounterX<=GlassPositionX+84*3+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*3+18*3) && (CounterX<=GlassPositionX+84*3+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*3+23*3) && (CounterX<=GlassPositionX+84*3+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*3+2*3) && (CounterX<=GlassPositionX+84*3+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*3+11*3) && (CounterX<=GlassPositionX+84*3+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*3+14*3) && (CounterX<=GlassPositionX+84*3+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*3+25*3) && (CounterX<=GlassPositionX+84*3+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*3+1*3) && (CounterX<=GlassPositionX+84*3+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*3+13*3) && (CounterX<=GlassPositionX+84*3+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*3+18*3) && (CounterX<=GlassPositionX+84*3+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*3+27*3) && (CounterX<=GlassPositionX+84*3+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*3+0*3) && (CounterX<=GlassPositionX+84*3+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*3+12*3) && (CounterX<=GlassPositionX+84*3+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*3+19*3) && (CounterX<=GlassPositionX+84*3+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*4+6*3) && (CounterX<=GlassPositionX+84*4+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*4+20*3) && (CounterX<=GlassPositionX+84*4+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*4+4*3) && (CounterX<=GlassPositionX+84*4+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*4+9*3) && (CounterX<=GlassPositionX+84*4+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*4+18*3) && (CounterX<=GlassPositionX+84*4+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*4+23*3) && (CounterX<=GlassPositionX+84*4+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*4+2*3) && (CounterX<=GlassPositionX+84*4+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*4+11*3) && (CounterX<=GlassPositionX+84*4+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*4+14*3) && (CounterX<=GlassPositionX+84*4+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*4+25*3) && (CounterX<=GlassPositionX+84*4+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*4+1*3) && (CounterX<=GlassPositionX+84*4+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*4+13*3) && (CounterX<=GlassPositionX+84*4+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*4+18*3) && (CounterX<=GlassPositionX+84*4+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*4+27*3) && (CounterX<=GlassPositionX+84*4+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*4+0*3) && (CounterX<=GlassPositionX+84*4+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*4+12*3) && (CounterX<=GlassPositionX+84*4+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*4+19*3) && (CounterX<=GlassPositionX+84*4+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*5+6*3) && (CounterX<=GlassPositionX+84*5+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*5+20*3) && (CounterX<=GlassPositionX+84*5+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*5+4*3) && (CounterX<=GlassPositionX+84*5+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*5+9*3) && (CounterX<=GlassPositionX+84*5+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*5+18*3) && (CounterX<=GlassPositionX+84*5+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*5+23*3) && (CounterX<=GlassPositionX+84*5+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*5+2*3) && (CounterX<=GlassPositionX+84*5+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*5+11*3) && (CounterX<=GlassPositionX+84*5+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*5+14*3) && (CounterX<=GlassPositionX+84*5+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*5+25*3) && (CounterX<=GlassPositionX+84*5+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*5+1*3) && (CounterX<=GlassPositionX+84*5+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*5+13*3) && (CounterX<=GlassPositionX+84*5+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*5+18*3) && (CounterX<=GlassPositionX+84*5+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*5+27*3) && (CounterX<=GlassPositionX+84*5+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*5+0*3) && (CounterX<=GlassPositionX+84*5+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*5+12*3) && (CounterX<=GlassPositionX+84*5+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*5+19*3) && (CounterX<=GlassPositionX+84*5+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*6+6*3) && (CounterX<=GlassPositionX+84*6+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*6+20*3) && (CounterX<=GlassPositionX+84*6+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*6+4*3) && (CounterX<=GlassPositionX+84*6+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*6+9*3) && (CounterX<=GlassPositionX+84*6+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*6+18*3) && (CounterX<=GlassPositionX+84*6+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*6+23*3) && (CounterX<=GlassPositionX+84*6+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*6+2*3) && (CounterX<=GlassPositionX+84*6+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*6+11*3) && (CounterX<=GlassPositionX+84*6+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*6+14*3) && (CounterX<=GlassPositionX+84*6+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*6+25*3) && (CounterX<=GlassPositionX+84*6+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*6+1*3) && (CounterX<=GlassPositionX+84*6+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*6+13*3) && (CounterX<=GlassPositionX+84*6+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*6+18*3) && (CounterX<=GlassPositionX+84*6+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*6+27*3) && (CounterX<=GlassPositionX+84*6+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*6+0*3) && (CounterX<=GlassPositionX+84*6+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*6+12*3) && (CounterX<=GlassPositionX+84*6+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*6+19*3) && (CounterX<=GlassPositionX+84*6+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*7+6*3) && (CounterX<=GlassPositionX+84*7+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*7+20*3) && (CounterX<=GlassPositionX+84*7+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*7+4*3) && (CounterX<=GlassPositionX+84*7+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*7+9*3) && (CounterX<=GlassPositionX+84*7+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*7+18*3) && (CounterX<=GlassPositionX+84*7+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*7+23*3) && (CounterX<=GlassPositionX+84*7+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*7+2*3) && (CounterX<=GlassPositionX+84*7+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*7+11*3) && (CounterX<=GlassPositionX+84*7+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*7+14*3) && (CounterX<=GlassPositionX+84*7+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*7+25*3) && (CounterX<=GlassPositionX+84*7+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*7+1*3) && (CounterX<=GlassPositionX+84*7+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*7+13*3) && (CounterX<=GlassPositionX+84*7+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*7+18*3) && (CounterX<=GlassPositionX+84*7+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*7+27*3) && (CounterX<=GlassPositionX+84*7+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*7+0*3) && (CounterX<=GlassPositionX+84*7+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*7+12*3) && (CounterX<=GlassPositionX+84*7+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*7+19*3) && (CounterX<=GlassPositionX+84*7+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*8+6*3) && (CounterX<=GlassPositionX+84*8+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*8+20*3) && (CounterX<=GlassPositionX+84*8+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*8+4*3) && (CounterX<=GlassPositionX+84*8+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*8+9*3) && (CounterX<=GlassPositionX+84*8+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*8+18*3) && (CounterX<=GlassPositionX+84*8+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*8+23*3) && (CounterX<=GlassPositionX+84*8+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*8+2*3) && (CounterX<=GlassPositionX+84*8+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*8+11*3) && (CounterX<=GlassPositionX+84*8+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*8+14*3) && (CounterX<=GlassPositionX+84*8+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*8+25*3) && (CounterX<=GlassPositionX+84*8+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*8+1*3) && (CounterX<=GlassPositionX+84*8+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*8+13*3) && (CounterX<=GlassPositionX+84*8+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*8+18*3) && (CounterX<=GlassPositionX+84*8+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*8+27*3) && (CounterX<=GlassPositionX+84*8+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*8+0*3) && (CounterX<=GlassPositionX+84*8+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*8+12*3) && (CounterX<=GlassPositionX+84*8+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*8+19*3) && (CounterX<=GlassPositionX+84*8+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 			

|| 			(CounterX>=GlassPositionX+84*9+6*3) && (CounterX<=GlassPositionX+84*9+9*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*9+20*3) && (CounterX<=GlassPositionX+84*9+23*3) && (CounterY>=GlassPositionY+0*3) && (CounterY<=GlassPositionY+1*3)

||          (CounterX>=GlassPositionX+84*9+4*3) && (CounterX<=GlassPositionX+84*9+6*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*9+9*3) && (CounterX<=GlassPositionX+84*9+11*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*9+18*3) && (CounterX<=GlassPositionX+84*9+20*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*9+23*3) && (CounterX<=GlassPositionX+84*9+25*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*9+2*3) && (CounterX<=GlassPositionX+84*9+4*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*9+11*3) && (CounterX<=GlassPositionX+84*9+13*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*9+14*3) && (CounterX<=GlassPositionX+84*9+18*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*9+25*3) && (CounterX<=GlassPositionX+84*9+27*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)

||          (CounterX>=GlassPositionX+84*9+1*3) && (CounterX<=GlassPositionX+84*9+2*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*9+13*3) && (CounterX<=GlassPositionX+84*9+14*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*9+18*3) && (CounterX<=GlassPositionX+84*9+19*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*9+27*3) && (CounterX<=GlassPositionX+84*9+28*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)

||          (CounterX>=GlassPositionX+84*9+0*3) && (CounterX<=GlassPositionX+84*9+1*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*9+12*3) && (CounterX<=GlassPositionX+84*9+13*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
||          (CounterX>=GlassPositionX+84*9+19*3) && (CounterX<=GlassPositionX+84*9+20*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3);



GlassGreen <=   (CounterX>=GlassPositionX+6*3) && (CounterX<=GlassPositionX+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+4*3) && (CounterX<=GlassPositionX+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+2*3) && (CounterX<=GlassPositionX+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+1*3) && (CounterX<=GlassPositionX+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+14*3) && (CounterX<=GlassPositionX+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+13*3) && (CounterX<=GlassPositionX+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+20*3) && (CounterX<=GlassPositionX+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+18*3) && (CounterX<=GlassPositionX+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+19*3) && (CounterX<=GlassPositionX+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+20*3) && (CounterX<=GlassPositionX+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=0) && (CounterX<=640) && (CounterY>=GlassPositionY+6*3) && (CounterY<=GlassPositionY+10*3)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84+6*3) && (CounterX<=GlassPositionX+84+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84+4*3) && (CounterX<=GlassPositionX+84+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84+2*3) && (CounterX<=GlassPositionX+84+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84+1*3) && (CounterX<=GlassPositionX+84+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84+14*3) && (CounterX<=GlassPositionX+84+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84+13*3) && (CounterX<=GlassPositionX+84+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84+20*3) && (CounterX<=GlassPositionX+84+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84+18*3) && (CounterX<=GlassPositionX+84+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84+19*3) && (CounterX<=GlassPositionX+84+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84+20*3) && (CounterX<=GlassPositionX+84+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*2+6*3) && (CounterX<=GlassPositionX+84*2+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*2+4*3) && (CounterX<=GlassPositionX+84*2+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*2+2*3) && (CounterX<=GlassPositionX+84*2+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*2+1*3) && (CounterX<=GlassPositionX+84*2+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*2+14*3) && (CounterX<=GlassPositionX+84*2+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*2+13*3) && (CounterX<=GlassPositionX+84*2+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*2+20*3) && (CounterX<=GlassPositionX+84*2+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*2+18*3) && (CounterX<=GlassPositionX+84*2+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*2+19*3) && (CounterX<=GlassPositionX+84*2+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*2+20*3) && (CounterX<=GlassPositionX+84*2+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*3+6*3) && (CounterX<=GlassPositionX+84*3+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*3+4*3) && (CounterX<=GlassPositionX+84*3+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*3+2*3) && (CounterX<=GlassPositionX+84*3+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*3+1*3) && (CounterX<=GlassPositionX+84*3+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*3+14*3) && (CounterX<=GlassPositionX+84*3+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*3+13*3) && (CounterX<=GlassPositionX+84*3+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*3+20*3) && (CounterX<=GlassPositionX+84*3+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*3+18*3) && (CounterX<=GlassPositionX+84*3+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*3+19*3) && (CounterX<=GlassPositionX+84*3+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*3+20*3) && (CounterX<=GlassPositionX+84*3+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*4+6*3) && (CounterX<=GlassPositionX+84*4+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*4+4*3) && (CounterX<=GlassPositionX+84*4+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*4+2*3) && (CounterX<=GlassPositionX+84*4+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*4+1*3) && (CounterX<=GlassPositionX+84*4+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*4+14*3) && (CounterX<=GlassPositionX+84*4+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*4+13*3) && (CounterX<=GlassPositionX+84*4+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*4+20*3) && (CounterX<=GlassPositionX+84*4+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*4+18*3) && (CounterX<=GlassPositionX+84*4+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*4+19*3) && (CounterX<=GlassPositionX+84*4+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*4+20*3) && (CounterX<=GlassPositionX+84*4+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*5+6*3) && (CounterX<=GlassPositionX+84*5+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*5+4*3) && (CounterX<=GlassPositionX+84*5+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*5+2*3) && (CounterX<=GlassPositionX+84*5+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*5+1*3) && (CounterX<=GlassPositionX+84*5+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*5+14*3) && (CounterX<=GlassPositionX+84*5+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*5+13*3) && (CounterX<=GlassPositionX+84*5+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*5+20*3) && (CounterX<=GlassPositionX+84*5+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*5+18*3) && (CounterX<=GlassPositionX+84*5+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*5+19*3) && (CounterX<=GlassPositionX+84*5+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*5+20*3) && (CounterX<=GlassPositionX+84*5+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*6+6*3) && (CounterX<=GlassPositionX+84*6+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*6+4*3) && (CounterX<=GlassPositionX+84*6+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*6+2*3) && (CounterX<=GlassPositionX+84*6+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*6+1*3) && (CounterX<=GlassPositionX+84*6+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*6+14*3) && (CounterX<=GlassPositionX+84*6+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*6+13*3) && (CounterX<=GlassPositionX+84*6+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*6+20*3) && (CounterX<=GlassPositionX+84*6+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*6+18*3) && (CounterX<=GlassPositionX+84*6+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*6+19*3) && (CounterX<=GlassPositionX+84*6+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*6+20*3) && (CounterX<=GlassPositionX+84*6+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*7+6*3) && (CounterX<=GlassPositionX+84*7+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*7+4*3) && (CounterX<=GlassPositionX+84*7+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*7+2*3) && (CounterX<=GlassPositionX+84*7+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*7+1*3) && (CounterX<=GlassPositionX+84*7+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*7+14*3) && (CounterX<=GlassPositionX+84*7+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*7+13*3) && (CounterX<=GlassPositionX+84*7+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*7+20*3) && (CounterX<=GlassPositionX+84*7+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*7+18*3) && (CounterX<=GlassPositionX+84*7+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*7+19*3) && (CounterX<=GlassPositionX+84*7+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*7+20*3) && (CounterX<=GlassPositionX+84*7+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*8+6*3) && (CounterX<=GlassPositionX+84*8+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*8+4*3) && (CounterX<=GlassPositionX+84*8+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*8+2*3) && (CounterX<=GlassPositionX+84*8+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*8+1*3) && (CounterX<=GlassPositionX+84*8+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*8+14*3) && (CounterX<=GlassPositionX+84*8+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*8+13*3) && (CounterX<=GlassPositionX+84*8+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*8+20*3) && (CounterX<=GlassPositionX+84*8+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*8+18*3) && (CounterX<=GlassPositionX+84*8+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*8+19*3) && (CounterX<=GlassPositionX+84*8+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*8+20*3) && (CounterX<=GlassPositionX+84*8+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

||			(CounterX>=GlassPositionX+84*9+6*3) && (CounterX<=GlassPositionX+84*9+9*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)

||          (CounterX>=GlassPositionX+84*9+4*3) && (CounterX<=GlassPositionX+84*9+11*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*9+2*3) && (CounterX<=GlassPositionX+84*9+13*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*9+1*3) && (CounterX<=GlassPositionX+84*9+12*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)


||          (CounterX>=GlassPositionX+84*9+14*3) && (CounterX<=GlassPositionX+84*9+18*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*9+13*3) && (CounterX<=GlassPositionX+84*9+19*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3)

||          (CounterX>=GlassPositionX+84*9+20*3) && (CounterX<=GlassPositionX+84*9+23*3) && (CounterY>=GlassPositionY+1*3) && (CounterY<=GlassPositionY+2*3)
||          (CounterX>=GlassPositionX+84*9+18*3) && (CounterX<=GlassPositionX+84*9+25*3) && (CounterY>=GlassPositionY+2*3) && (CounterY<=GlassPositionY+3*3)
||          (CounterX>=GlassPositionX+84*9+19*3) && (CounterX<=GlassPositionX+84*9+27*3) && (CounterY>=GlassPositionY+3*3) && (CounterY<=GlassPositionY+4*3)
||          (CounterX>=GlassPositionX+84*9+20*3) && (CounterX<=GlassPositionX+84*9+28*3) && (CounterY>=GlassPositionY+4*3) && (CounterY<=GlassPositionY+6*3);
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


R_OnBackground_on = Cloud;
G_OnBackground_on = Cloud | TownBlue | GlassGreen;
B_OnBackground_on = Cloud | TownBlue;

R_OnBackground_off = TownBlue | GlassBlack | GlassGreen;
G_OnBackground_off = GlassBlack;
B_OnBackground_off = GlassBlack | GlassGreen;
end
endmodule

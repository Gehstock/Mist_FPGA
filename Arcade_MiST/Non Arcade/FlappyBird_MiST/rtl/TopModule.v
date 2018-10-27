`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:47:12 04/23/2014 
// Design Name: 
// Module Name:    TopModule 
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
module TopModule(Clk,Button,Reset, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B,Speaker);
input Clk,Button,Reset;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B ,Speaker;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;
wire [24:0] Clks;
wire Status;
wire [15:0] Pattern1;
wire [15:0] Pattern2;
wire [15:0] PipesPosition1;
wire [15:0] PipesPosition2;
wire R_Pipes_on,G_Pipes_on,B_Pipes_on,R_Pipes_off,G_Pipes_off,B_Pipes_off;
wire R_Pipes2_on,G_Pipes2_on,B_Pipes2_on,R_Pipes2_off,G_Pipes2_off,B_Pipes2_off;
wire [15:0] R_Bird_on,G_Bird_on,B_Bird_on,R_Bird_off,G_Bird_off,B_Bird_off;
wire Button;
wire R_Background, G_Background, B_Background;
wire R_OnBackground_on, G_OnBackground_on, B_OnBackground_on;
wire R_OnBackground_off, G_OnBackground_off, B_OnBackground_off;

wire R_Board_on,G_Board_on,B_Board_on,R_Board_off,G_Board_off,B_Board_off;
wire R_Score_on,G_Score_on,B_Score_on,R_Score_off,G_Score_off,B_Score_off;
wire R_Item_on,G_Item_on,B_Item_on,R_Item_off,G_Item_off,B_Item_off;

VGAOut syncgen(.Clk(Clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

//Debouncer deb (Clk,Button,Button);

SlowClock s1 (Clk,Reset,Clks);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
StatusChecker s7 (Reset,CounterX,R_Pipes_off,R_Pipes2_off,R_Bird_off,Status);

DrawBackground s2 (Clks,Status,CounterX,CounterY,R_Background,G_Background,B_Background);
DrawOnBackground s22 (Clks,CounterX,CounterY,R_OnBackground_on,G_OnBackground_on,B_OnBackground_on,R_OnBackground_off,G_OnBackground_off,B_OnBackground_off);

DrawBird s3 (Clks,Reset,CounterX,CounterY,Button,Status,R_Bird_on,G_Bird_on,B_Bird_on,R_Bird_off,G_Bird_off,B_Bird_off);

DrawPipes s4 (Clks,Reset,CounterX,CounterY,Button,Status,Pattern1,R_Pipes_on,G_Pipes_on,B_Pipes_on,R_Pipes_off,G_Pipes_off,B_Pipes_off,PipesPosition1);
DrawPipes2 s44 (Clks,Reset,CounterX,CounterY,Button,Status,Pattern2,R_Pipes2_on,G_Pipes2_on,B_Pipes2_on,R_Pipes2_off,G_Pipes2_off,B_Pipes2_off,PipesPosition2);

Pattern p (Clks,Reset,PipesPosition1,PipesPosition2,Button,Pattern1,Pattern2);
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DrawScore s5 (Clks,Reset,PipesPosition1,PipesPosition2,CounterX,CounterY,Button,Status,R_Score_on,G_Score_on,B_Score_on,R_Score_off,G_Score_off,B_Score_off);
Sound so (Clk,PipesPosition1,PipesPosition2,Speaker);


DrawItem s6 (Clks,CounterX,CounterY,Button,R_Item_on,G_Item_on,B_Item_on,R_Item_off,G_Item_off,B_Item_off);

DrawBoard dd (Clks,Reset,CounterX,CounterY,Button,Status,R_Board_on,G_Board_on,B_Board_on,R_Board_off,G_Board_off,B_Board_off);

wire RLayer0 = (R_Background | R_OnBackground_on) & ~R_OnBackground_off;
wire GLayer0 = (G_Background | G_OnBackground_on) & ~G_OnBackground_off;
wire BLayer0 = (B_Background | B_OnBackground_on) & ~B_OnBackground_off;

wire RLayer1 = (RLayer0 & ~R_Pipes_off) & ~R_Pipes2_off;
wire GLayer1 = ((GLayer0 | G_Pipes_on | G_Pipes2_on) & ~G_Pipes_off) & ~G_Pipes2_off;
wire BLayer1 = (BLayer0 & ~B_Pipes_off) & ~B_Pipes2_off;

wire RLayer2 = (RLayer1 | R_Board_on) &~R_Board_off;
wire GLayer2 = (GLayer1 | G_Board_on) &~G_Board_off;
wire BLayer2 = (BLayer1 | B_Board_on) &~B_Board_off;

wire RLayer3 = (RLayer2 | R_Bird_on) & ~R_Bird_off;
wire GLayer3 = (GLayer2 | G_Bird_on) & ~G_Bird_off;
wire BLayer3 = (BLayer2 | B_Bird_on) & ~B_Bird_off;

wire RLayer4 = (RLayer3 | R_Score_on) & ~R_Score_off;
wire GLayer4 = (GLayer3 | G_Score_on) & ~G_Score_off;
wire BLayer4 = (BLayer3 | B_Score_on) & ~B_Score_off;

reg vga_R, vga_G, vga_B;
always @(posedge Clk)
begin
	begin
	vga_R <= RLayer4 & inDisplayArea;
	vga_G <= GLayer4 & inDisplayArea;
	vga_B <= BLayer4 & inDisplayArea;
	end
end
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:29:02 04/24/2014 
// Design Name: 
// Module Name:    Pattern 
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
module Pattern(input [24:0] Clks,Reset,input [15:0] PipesPosition1,input [15:0] PipesPosition2,Button,output reg [15:0] Pattern1,output reg [15:0] Pattern2);

reg  [15:0] i = 1;
reg  [15:0] j = 1;
reg  [15:0] Random = 0;
reg  [15:0] Pattern;
reg  Start = 0;

always @ (posedge Clks[16])
begin
	if (!Reset)
	begin
	i <= 1;
	j <= 1;
	Random <= 0;
	Start <= 0;
	end

	if (Random == 5) Random <= 1;
	else Random <= Random + 1;

	if (Start == 0 && !Button) begin Start <= 1; Pattern <= Random; end
	
	if (PipesPosition1 == 0) i <= i+1;
	if (PipesPosition2 == 0) j <= j+1;
	if (j == 50) begin i <= 0;  j <= 0; end

case (Pattern)
1 : begin
							case (i)
						1	: Pattern1 <=	80	;
						2	: Pattern1 <=	80	;
						3	: Pattern1 <=	110	;
						4	: Pattern1 <=	160	;
						5	: Pattern1 <=	120	;
						6	: Pattern1 <=	140	;
						7	: Pattern1 <=	80	;
						8	: Pattern1 <=	40	;
						9	: Pattern1 <=	80	;
						10	: Pattern1 <=	120	;
						11	: Pattern1 <=	160	;
						12	: Pattern1 <=	140	;
						13	: Pattern1 <=	100	;
						14	: Pattern1 <=	60	;
						15	: Pattern1 <=	160	;
						16	: Pattern1 <=	120	;
						17	: Pattern1 <=	80	;
						18	: Pattern1 <=	40	;
						19	: Pattern1 <=	60	;
						20	: Pattern1 <=	100	;
						21	: Pattern1 <=	140	;
						22	: Pattern1 <=	100	;
						23	: Pattern1 <=	100	;
						24	: Pattern1 <=	60	;
						25	: Pattern1 <=	100	;
						26	: Pattern1 <=	100	;
						27	: Pattern1 <=	140	;
						28	: Pattern1 <=	100	;
						29	: Pattern1 <=	160	;
						30	: Pattern1 <=	160	;
						31	: Pattern1 <=	140	;
						32	: Pattern1 <=	120	;
						33	: Pattern1 <=	140	;
						34	: Pattern1 <=	80	;
						35	: Pattern1 <=	60	;
						36	: Pattern1 <=	140	;
						37	: Pattern1 <=	80	;
						38	: Pattern1 <=	140	;
						39	: Pattern1 <=	80	;
						40	: Pattern1 <=	60	;
						41	: Pattern1 <=	120	;
						42	: Pattern1 <=	140	;
						43	: Pattern1 <=	160	;
						44	: Pattern1 <=	120	;
						45	: Pattern1 <=	100	;
						46	: Pattern1 <=	40	;
						47	: Pattern1 <=	80	;
						48	: Pattern1 <=	160	;
						49	: Pattern1 <=	80	;
						50	: Pattern1 <=	160	;
							endcase
							
							case (j)
						1	: Pattern2 <=	140	;
						2	: Pattern2 <=	40	;
						3	: Pattern2 <=	80	;
						4	: Pattern2 <=	120	;
						5	: Pattern2 <=	40	;
						6	: Pattern2 <=	60	;
						7	: Pattern2 <=	80	;
						8	: Pattern2 <=	60	;
						9	: Pattern2 <=	100	;
						10	: Pattern2 <=	140	;
						11	: Pattern2 <=	160	;
						12	: Pattern2 <=	120	;
						13	: Pattern2 <=	80	;
						14	: Pattern2 <=	40	;
						15	: Pattern2 <=	140	;
						16	: Pattern2 <=	100	;
						17	: Pattern2 <=	60	;
						18	: Pattern2 <=	40	;
						19	: Pattern2 <=	80	;
						20	: Pattern2 <=	120	;
						21	: Pattern2 <=	160	;
						22	: Pattern2 <=	100	;
						23	: Pattern2 <=	60	;
						24	: Pattern2 <=	60	;
						25	: Pattern2 <=	100	;
						26	: Pattern2 <=	140	;
						27	: Pattern2 <=	140	;
						28	: Pattern2 <=	40	;
						29	: Pattern2 <=	40	;
						30	: Pattern2 <=	100	;
						31	: Pattern2 <=	80	;
						32	: Pattern2 <=	80	;
						33	: Pattern2 <=	160	;
						34	: Pattern2 <=	80	;
						35	: Pattern2 <=	80	;
						36	: Pattern2 <=	160	;
						37	: Pattern2 <=	100	;
						38	: Pattern2 <=	60	;
						39	: Pattern2 <=	40	;
						40	: Pattern2 <=	40	;
						41	: Pattern2 <=	60	;
						42	: Pattern2 <=	80	;
						43	: Pattern2 <=	60	;
						44	: Pattern2 <=	40	;
						45	: Pattern2 <=	120	;
						46	: Pattern2 <=	120	;
						47	: Pattern2 <=	60	;
						48	: Pattern2 <=	80	;
						49	: Pattern2 <=	160	;
						50	: Pattern2 <=	395	;
							endcase
							end
2 : begin
					case (i)
					1	: Pattern1 <=	40	;
					2	: Pattern1 <=	60	;
					3	: Pattern1 <=	80	;
					4	: Pattern1 <=	60	;
					5	: Pattern1 <=	40	;
					6	: Pattern1 <=	120	;
					7	: Pattern1 <=	120	;
					8	: Pattern1 <=	60	;
					9	: Pattern1 <=	80	;
					10	: Pattern1 <=	160	;
					11	: Pattern1 <=	140	;
					12	: Pattern1 <=	120	;
					13	: Pattern1 <=	140	;
					14	: Pattern1 <=	80	;
					15	: Pattern1 <=	60	;
					16	: Pattern1 <=	140	;
					17	: Pattern1 <=	80	;
					18	: Pattern1 <=	140	;
					19	: Pattern1 <=	80	;
					20	: Pattern1 <=	60	;
					21	: Pattern1 <=	40	;
					22	: Pattern1 <=	40	;
					23	: Pattern1 <=	100	;
					24	: Pattern1 <=	100	;
					25	: Pattern1 <=	60	;
					26	: Pattern1 <=	60	;
					27	: Pattern1 <=	100	;
					28	: Pattern1 <=	140	;
					29	: Pattern1 <=	140	;
					30	: Pattern1 <=	140	;
					31	: Pattern1 <=	100	;
					32	: Pattern1 <=	60	;
					33	: Pattern1 <=	40	;
					34	: Pattern1 <=	80	;
					35	: Pattern1 <=	120	;
					36	: Pattern1 <=	160	;
					37	: Pattern1 <=	60	;
					38	: Pattern1 <=	100	;
					39	: Pattern1 <=	140	;
					40	: Pattern1 <=	160	;
					41	: Pattern1 <=	120	;
					42	: Pattern1 <=	80	;
					43	: Pattern1 <=	40	;
					44	: Pattern1 <=	140	;
					45	: Pattern1 <=	40	;
					46	: Pattern1 <=	80	;
					47	: Pattern1 <=	120	;
					48	: Pattern1 <=	40	;
					49	: Pattern1 <=	60	;
					50	: Pattern1 <=	80	;
					endcase
					case (j)
					1	: Pattern2 <=	120	;
					2	: Pattern2 <=	140	;
					3	: Pattern2 <=	160	;
					4	: Pattern2 <=	120	;
					5	: Pattern2 <=	100	;
					6	: Pattern2 <=	40	;
					7	: Pattern2 <=	80	;
					8	: Pattern2 <=	160	;
					9	: Pattern2 <=	80	;
					10	: Pattern2 <=	160	;
					11	: Pattern2 <=	80	;
					12	: Pattern2 <=	80	;
					13	: Pattern2 <=	160	;
					14	: Pattern2 <=	80	;
					15	: Pattern2 <=	80	;
					16	: Pattern2 <=	160	;
					17	: Pattern2 <=	100	;
					18	: Pattern2 <=	60	;
					19	: Pattern2 <=	40	;
					20	: Pattern2 <=	100	;
					21	: Pattern2 <=	160	;
					22	: Pattern2 <=	160	;
					23	: Pattern2 <=	100	;
					24	: Pattern2 <=	100	;
					25	: Pattern2 <=	60	;
					26	: Pattern2 <=	100	;
					27	: Pattern2 <=	100	;
					28	: Pattern2 <=	140	;
					29	: Pattern2 <=	160	;
					30	: Pattern2 <=	120	;
					31	: Pattern2 <=	80	;
					32	: Pattern2 <=	40	;
					33	: Pattern2 <=	60	;
					34	: Pattern2 <=	100	;
					35	: Pattern2 <=	140	;
					36	: Pattern2 <=	40	;
					37	: Pattern2 <=	80	;
					38	: Pattern2 <=	120	;
					39	: Pattern2 <=	160	;
					40	: Pattern2 <=	140	;
					41	: Pattern2 <=	100	;
					42	: Pattern2 <=	60	;
					43	: Pattern2 <=	80	;
					44	: Pattern2 <=	80	;
					45	: Pattern2 <=	110	;
					46	: Pattern2 <=	160	;
					47	: Pattern2 <=	120	;
					48	: Pattern2 <=	140	;
					49	: Pattern2 <=	80	;
					50	: Pattern2 <=	395	;
					endcase
	end
	
	
3 : begin

						case (i)
								1	: Pattern1 <=	160;
						2	: Pattern1 <=	120;
						3	: Pattern1 <=	80;
						4	: Pattern1 <=	40;
						5	: Pattern1 <=	60;
						6	: Pattern1 <=	100;
						7	: Pattern1 <=	140;
						8	: Pattern1 <=	100;
						9	: Pattern1 <=	100;
						10	: Pattern1 <=	60;
						11	: Pattern1 <=	100;
						12	: Pattern1 <=	100;
						13	: Pattern1 <=	140;
						14	: Pattern1 <=	140;
						15	: Pattern1 <=	120;
						16	: Pattern1 <=	140;
						17	: Pattern1 <=	80;
						18	: Pattern1 <=	60;
						19	: Pattern1 <=	140;
						20	: Pattern1 <=	80;
						21	: Pattern1 <=	140;
						22	: Pattern1 <=	80;
						23	: Pattern1 <=	60;
						24	: Pattern1 <=	60;
						25	: Pattern1 <=	100;
						26	: Pattern1 <=	140;
						27	: Pattern1 <=	160;
						28	: Pattern1 <=	120;
						29	: Pattern1 <=	80;
						30	: Pattern1 <=	40;
						31	: Pattern1 <=	120;
						32	: Pattern1 <=	140;
						33	: Pattern1 <=	160;
						34	: Pattern1 <=	120;
						35	: Pattern1 <=	100;
						36	: Pattern1 <=	40;
						37	: Pattern1 <=	80;
						38	: Pattern1 <=	160;
						39	: Pattern1 <=	80;
						40	: Pattern1 <=	160;
						41	: Pattern1 <=	140;
						42	: Pattern1 <=	40;
						43	: Pattern1 <=	80;
						44	: Pattern1 <=	120;
						45	: Pattern1 <=	40;
						46	: Pattern1 <=	60;
						47	: Pattern1 <=	80;
						48	: Pattern1 <=	40;
						49	: Pattern1 <=	40;
						50	: Pattern1 <=	100;
						endcase
						case (j)
						1	: Pattern2 <=	140	;
						2	: Pattern2 <=	100	;
						3	: Pattern2 <=	60	;
						4	: Pattern2 <=	40	;
						5	: Pattern2 <=	80	;
						6	: Pattern2 <=	120	;
						7	: Pattern2 <=	160	;
						8	: Pattern2 <=	100	;
						9	: Pattern2 <=	60	;
						10	: Pattern2 <=	60	;
						11	: Pattern2 <=	100	;
						12	: Pattern2 <=	140	;
						13	: Pattern2 <=	140	;
						14	: Pattern2 <=	80	;
						15	: Pattern2 <=	80	;
						16	: Pattern2 <=	160	;
						17	: Pattern2 <=	80	;
						18	: Pattern2 <=	80	;
						19	: Pattern2 <=	160	;
						20	: Pattern2 <=	100	;
						21	: Pattern2 <=	60	;
						22	: Pattern2 <=	40	;
						23	: Pattern2 <=	40	;
						24	: Pattern2 <=	80	;
						25	: Pattern2 <=	120	;
						26	: Pattern2 <=	160	;
						27	: Pattern2 <=	140	;
						28	: Pattern2 <=	100	;
						29	: Pattern2 <=	60	;
						30	: Pattern2 <=	40	;
						31	: Pattern2 <=	60	;
						32	: Pattern2 <=	80	;
						33	: Pattern2 <=	60	;
						34	: Pattern2 <=	40	;
						35	: Pattern2 <=	120	;
						36	: Pattern2 <=	120	;
						37	: Pattern2 <=	60	;
						38	: Pattern2 <=	80	;
						39	: Pattern2 <=	160	;
						40	: Pattern2 <=	80	;
						41	: Pattern2 <=	80	;
						42	: Pattern2 <=	110	;
						43	: Pattern2 <=	160	;
						44	: Pattern2 <=	120	;
						45	: Pattern2 <=	140	;
						46	: Pattern2 <=	80	;
						47	: Pattern2 <=	100	;
						48	: Pattern2 <=	160	;
						49	: Pattern2 <=	160	;
						50	: Pattern2 <=	395	;
						endcase
	end
	
4 : begin
								case (i)
						1	: Pattern1 <=	40	;
						2	: Pattern1 <=	60	;
						3	: Pattern1 <=	80	;
						4	: Pattern1 <=	60	;
						5	: Pattern1 <=	40	;
						6	: Pattern1 <=	120	;
						7	: Pattern1 <=	120	;
						8	: Pattern1 <=	60	;
						9	: Pattern1 <=	80	;
						10	: Pattern1 <=	160	;
						11	: Pattern1 <=	100	;
						12	: Pattern1 <=	100	;
						13	: Pattern1 <=	60	;
						14	: Pattern1 <=	100	;
						15	: Pattern1 <=	100	;
						16	: Pattern1 <=	140	;
						17	: Pattern1 <=	140	;
						18	: Pattern1 <=	120	;
						19	: Pattern1 <=	140	;
						20	: Pattern1 <=	80	;
						21	: Pattern1 <=	60	;
						22	: Pattern1 <=	140	;
						23	: Pattern1 <=	80	;
						24	: Pattern1 <=	140	;
						25	: Pattern1 <=	80	;
						26	: Pattern1 <=	60	;
						27	: Pattern1 <=	140	;
						28	: Pattern1 <=	100	;
						29	: Pattern1 <=	60	;
						30	: Pattern1 <=	40	;
						31	: Pattern1 <=	80	;
						32	: Pattern1 <=	120	;
						33	: Pattern1 <=	160	;
						34	: Pattern1 <=	60	;
						35	: Pattern1 <=	100	;
						36	: Pattern1 <=	140	;
						37	: Pattern1 <=	160	;
						38	: Pattern1 <=	120	;
						39	: Pattern1 <=	80	;
						40	: Pattern1 <=	40	;
						41	: Pattern1 <=	40	;
						42	: Pattern1 <=	40	;
						43	: Pattern1 <=	100	;
						44	: Pattern1 <=	140	;
						45	: Pattern1 <=	40	;
						46	: Pattern1 <=	80	;
						47	: Pattern1 <=	120	;
						48	: Pattern1 <=	40	;
						49	: Pattern1 <=	60	;
						50	: Pattern1 <=	80	;
								endcase
								
								case (j)
								1	: Pattern2 <=	120	;
						2	: Pattern2 <=	140	;
						3	: Pattern2 <=	160	;
						4	: Pattern2 <=	120	;
						5	: Pattern2 <=	100	;
						6	: Pattern2 <=	40	;
						7	: Pattern2 <=	80	;
						8	: Pattern2 <=	160	;
						9	: Pattern2 <=	80	;
						10	: Pattern2 <=	160	;
						11	: Pattern2 <=	100	;
						12	: Pattern2 <=	60	;
						13	: Pattern2 <=	60	;
						14	: Pattern2 <=	100	;
						15	: Pattern2 <=	140	;
						16	: Pattern2 <=	140	;
						17	: Pattern2 <=	80	;
						18	: Pattern2 <=	80	;
						19	: Pattern2 <=	160	;
						20	: Pattern2 <=	80	;
						21	: Pattern2 <=	80	;
						22	: Pattern2 <=	160	;
						23	: Pattern2 <=	100	;
						24	: Pattern2 <=	60	;
						25	: Pattern2 <=	40	;
						26	: Pattern2 <=	160	;
						27	: Pattern2 <=	120	;
						28	: Pattern2 <=	80	;
						29	: Pattern2 <=	40	;
						30	: Pattern2 <=	60	;
						31	: Pattern2 <=	100	;
						32	: Pattern2 <=	140	;
						33	: Pattern2 <=	40	;
						34	: Pattern2 <=	80	;
						35	: Pattern2 <=	120	;
						36	: Pattern2 <=	160	;
						37	: Pattern2 <=	140	;
						38	: Pattern2 <=	100	;
						39	: Pattern2 <=	60	;
						40	: Pattern2 <=	100	;
						41	: Pattern2 <=	160	;
						42	: Pattern2 <=	160	;
						43	: Pattern2 <=	80	;
						44	: Pattern2 <=	80	;
						45	: Pattern2 <=	110	;
						46	: Pattern2 <=	160	;
						47	: Pattern2 <=	120	;
						48	: Pattern2 <=	140	;
						49	: Pattern2 <=	80	;
						50	: Pattern2 <=	395	;

								endcase
	end
	
	
5 : begin
								case (i)
								1	: Pattern1 <=	140	;
						2	: Pattern1 <=	120	;
						3	: Pattern1 <=	140	;
						4	: Pattern1 <=	80	;
						5	: Pattern1 <=	60	;
						6	: Pattern1 <=	140	;
						7	: Pattern1 <=	80	;
						8	: Pattern1 <=	140	;
						9	: Pattern1 <=	80	;
						10	: Pattern1 <=	60	;
						11	: Pattern1 <=	100	;
						12	: Pattern1 <=	60	;
						13	: Pattern1 <=	60	;
						14	: Pattern1 <=	100	;
						15	: Pattern1 <=	140	;
						16	: Pattern1 <=	140	;
						17	: Pattern1 <=	120	;
						18	: Pattern1 <=	140	;
						19	: Pattern1 <=	160	;
						20	: Pattern1 <=	120	;
						21	: Pattern1 <=	100	;
						22	: Pattern1 <=	40	;
						23	: Pattern1 <=	80	;
						24	: Pattern1 <=	160	;
						25	: Pattern1 <=	80	;
						26	: Pattern1 <=	160	;
						27	: Pattern1 <=	140	;
						28	: Pattern1 <=	100	;
						29	: Pattern1 <=	60	;
						30	: Pattern1 <=	40	;
						31	: Pattern1 <=	80	;
						32	: Pattern1 <=	120	;
						33	: Pattern1 <=	160	;
						34	: Pattern1 <=	40	;
						35	: Pattern1 <=	40	;
						36	: Pattern1 <=	100	;
						37	: Pattern1 <=	140	;
						38	: Pattern1 <=	40	;
						39	: Pattern1 <=	80	;
						40	: Pattern1 <=	120	;
						41	: Pattern1 <=	40	;
						42	: Pattern1 <=	60	;
						43	: Pattern1 <=	80	;
						44	: Pattern1 <=	60	;
						45	: Pattern1 <=	100	;
						46	: Pattern1 <=	140	;
						47	: Pattern1 <=	160	;
						48	: Pattern1 <=	120	;
						49	: Pattern1 <=	80	;
						50	: Pattern1 <=	40	;
						endcase
						case (j)
						1	: Pattern2 <=	80	;
						2	: Pattern2 <=	80	;
						3	: Pattern2 <=	160	;
						4	: Pattern2 <=	80	;
						5	: Pattern2 <=	80	;
						6	: Pattern2 <=	160	;
						7	: Pattern2 <=	100	;
						8	: Pattern2 <=	60	;
						9	: Pattern2 <=	40	;
						10	: Pattern2 <=	100	;
						11	: Pattern2 <=	100	;
						12	: Pattern2 <=	60	;
						13	: Pattern2 <=	100	;
						14	: Pattern2 <=	100	;
						15	: Pattern2 <=	140	;
						16	: Pattern2 <=	40	;
						17	: Pattern2 <=	60	;
						18	: Pattern2 <=	80	;
						19	: Pattern2 <=	60	;
						20	: Pattern2 <=	40	;
						21	: Pattern2 <=	120	;
						22	: Pattern2 <=	120	;
						23	: Pattern2 <=	60	;
						24	: Pattern2 <=	80	;
						25	: Pattern2 <=	160	;
						26	: Pattern2 <=	160	;
						27	: Pattern2 <=	120	;
						28	: Pattern2 <=	80	;
						29	: Pattern2 <=	40	;
						30	: Pattern2 <=	60	;
						31	: Pattern2 <=	100	;
						32	: Pattern2 <=	140	;
						33	: Pattern2 <=	100	;
						34	: Pattern2 <=	160	;
						35	: Pattern2 <=	160	;
						36	: Pattern2 <=	80	;
						37	: Pattern2 <=	80	;
						38	: Pattern2 <=	110	;
						39	: Pattern2 <=	160	;
						40	: Pattern2 <=	120	;
						41	: Pattern2 <=	140	;
						42	: Pattern2 <=	80	;
						43	: Pattern2 <=	40	;
						44	: Pattern2 <=	80	;
						45	: Pattern2 <=	120	;
						46	: Pattern2 <=	160	;
						47	: Pattern2 <=	140	;
						48	: Pattern2 <=	100	;
						49	: Pattern2 <=	60	;
						50	: Pattern2 <=	395	;
						endcase
		
	end
								
endcase							
end

endmodule

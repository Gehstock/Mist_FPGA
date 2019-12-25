module ninjakun_adec
(
	input [15:0] CP0AD,
	input			 CP0WR,

	input [15:0] CP1AD,
	input			 CP1WR,

	output		 CS_IN0,
	output		 CS_IN1,

	output		 CS_SH0,
	output		 CS_SH1,

	output		 SYNWR0,
	output		 SYNWR1
);

assign CS_IN0 = (CP0AD[15:2] == 14'b1010_0000_0000_00); 
assign CS_IN1 = (CP1AD[15:2] == 14'b1010_0000_0000_00); 

assign CS_SH0 = (CP0AD[15:11] == 5'b1110_0); 
assign CS_SH1 = (CP1AD[15:11] == 5'b1110_0); 

assign SYNWR0 = CS_IN0 & (CP0AD[1:0]==2) & CP0WR;
assign SYNWR1 = CS_IN1 & (CP1AD[1:0]==2) & CP1WR;

endmodule 
// Copyright (c) 2011 MiSTer-X

module ninjakun_sadec
(
	input [15:0] CPADR,
	output		 CS_PSG,
	output		 CS_FGV,
	output		 CS_BGV,
	output		 CS_SPA,
	output		 CS_PAL
);

assign CS_PSG = ( CPADR[15: 2] == 14'b1000_0000_0000_00 );
assign CS_FGV = ( CPADR[15:11] ==  5'b1100_0 ); 
assign CS_BGV = ( CPADR[15:11] ==  5'b1100_1 ); 
assign CS_SPA = ( CPADR[15:11] ==  5'b1101_0 ); 
assign CS_PAL = ( CPADR[15:11] ==  5'b1101_1 ); 

endmodule 
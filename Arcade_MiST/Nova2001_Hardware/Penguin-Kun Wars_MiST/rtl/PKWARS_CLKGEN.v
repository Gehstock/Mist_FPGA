// Copyright (c) 2012 MiSTer-X 

module PKWARS_CLKGEN
(
	input		MCLK,		// 48MHz

	output	VCLKx4,
	output	VCLK,

	output	VRAMCL,
	output	PCLK,

	output	CLK24M,
	output 	CLK12M,
	output	CLK6M,
	output	CLK3M
);

reg [3:0] CLKDIV;
always @( posedge MCLK ) CLKDIV <= CLKDIV+1;

assign VCLKx4 = CLKDIV[0];	// 24MHz
assign VCLK   = CLKDIV[2];	//  6MHz

assign CLK24M = CLKDIV[0];
assign CLK12M = CLKDIV[1];
assign CLK6M  = CLKDIV[2];
assign CLK3M  = CLKDIV[3];

assign VRAMCL = ~VCLKx4;
assign PCLK   = ~VCLK;

endmodule



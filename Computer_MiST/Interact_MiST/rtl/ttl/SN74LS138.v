module SN74LS138 (
	input			a,			//01
	input			b,			//02
	input			c,			//03	
	input			g2an,		//04
	input			g2bn,		//05
	input			g1,		//06
	output		y7n,		//07
	
	output		y6n,		//09
	output		y5n,		//10
	output		y4n,		//11
	output		y3n,		//12
	output		y2n,		//13
	output		y1n,		//14
	output		y0n		//15
);

wire	en;
assign	en = ~(~g1 | g2bn | g2an);

assign	y0n = ~(~a & ~b & ~c & en);
assign	y1n = ~(a & ~b & ~c & en);
assign	y2n = ~(~a & b & ~c & en);
assign	y3n = ~(a & b & ~c & en);
assign	y4n = ~(~a & ~b & c & en);
assign	y5n = ~(~b & c & a & en);
assign	y6n = ~(~a & c & b & en);
assign	y7n = ~(en & b & a & c);

endmodule

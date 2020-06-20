module gaplus_bg(
   input				clk,
   input  [13:0]	ad,
   output  [7:0]	dt
);

wire [7:0] dt0;
bg bg(
	.clk(clk),
	.addr(ad),
	.data(dt0)
);

reg ad13;
always @( negedge clk ) ad13 <= ad[13];

assign dt = ad13 ? {4'h0,dt0[7:4]} : dt0;


endmodule 
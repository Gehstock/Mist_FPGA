module gaplus_sp(
   input				clk,
   input  [14:0]	ad,
   output [15:0]	dt
);

reg [1:0] _ad;
wire [7:0] dt0, dt1, dt2, dt3;
always @( posedge clk ) _ad <= ad[14:13];

obj1 obj1(
	.clk(clk),
	.addr(ad[12:0]),
	.data(dt0)
);

obj2 obj2(
	.clk(clk),
	.addr(ad[12:0]),
	.data(dt1)
);

obj3 obj3(
	.clk(clk),
	.addr(ad[12:0]),
	.data(dt2)
);

obj4 obj4(
	.clk(clk),
	.addr(ad[12:0]),
	.data(dt3)
);

assign dt = ( _ad == 2'b11 ) ? { 8'h0, dt3 } :
				( _ad == 2'b10 ) ? { 8'h0, dt2 } :
				( _ad == 2'b01 ) ? {  dt3, dt1 } :
			/*	( _ad == 2'b00 )?*/{  dt3, dt0 } ;

endmodule 
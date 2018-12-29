module address_decoder(
input [15:0]	addr,
input				clk,
output reg		absel_n, 
output reg		iosel_n, 
output reg		misel_n, 
output reg		vsel_n, 
output reg		romsel_n, 
output reg		ramsel_n,
output reg		bbsel_n
);

reg [3:0]prom_do;
sprom #(
	.init_file("./rom/prom5c.hex"),
	.widthad_a(7),
	.width_a(8))
c5C(
	.address(addr[15:9]),
	.clock(clk),
	.q(prom_do)
	);

wire spare1, spare2;
ttl_74ls138 c3D(
  	.a(prom_do[1]),
  	.b(prom_do[2]),
  	.c(prom_do[3]),
	.g1(prom_do[0]),
	.g2a_n(1'b0),
	.g2b_n(1'b0),
  	.y_n({spare2, spare1, absel_n, iosel_n, misel_n, vsel_n, romsel_n, ramsel_n}),
	);
	
assign bbsel_n = romsel_n & ramsel_n;

endmodule 
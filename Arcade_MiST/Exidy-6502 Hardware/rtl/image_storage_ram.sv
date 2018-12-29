module image_storage_ram(
input				clock,
input		[9:0]	addr,
input				cs_cg1,
input				cs_cg2,
input				gs_wr_n,
input		[7:0]	vd_in,
output	[7:0]	vd_out
);
wire [7:0] ram1, ram2;
always @(clock)
 vd_out <= 	cs_cg1 ? ram1 :
				cs_cg2 ? ram2 : 8'b00000000;
spram #(
	.widthad_a(10),
	.width_a(4))
c13C(
	.address(addr[9:0]),
	.clken(cs_cg1),
	.clock(clock),
	.data(vd_in[7:4]),
	.wren(~gs_wr_n),
	.q(ram1[7:4])
	);

spram #(
	.widthad_a(10),
	.width_a(4))
c11C(
	.address(addr[9:0]),
	.clken(cs_cg1),
	.clock(clock),
	.data(vd_in[3:0]),
	.wren(~gs_wr_n),
	.q(ram1[3:0])
	);
	
spram #(
	.widthad_a(10),
	.width_a(4))
c14C(
	.address(addr[9:0]),
	.clken(cs_cg2),
	.clock(clock),
	.data(vd_in[7:4]),
	.wren(~gs_wr_n),
	.q(ram2[7:4])
	);

spram #(
	.widthad_a(10),
	.width_a(4))
c12C(
	.address(addr[9:0]),
	.clken(cs_cg2),
	.clock(clock),
	.data(vd_in[3:0]),
	.wren(~gs_wr_n),
	.q(ram2[3:0])
	);	
endmodule 
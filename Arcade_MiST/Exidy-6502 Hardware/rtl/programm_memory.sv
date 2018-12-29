module programm_memory(
input 	[15:0]	addr,
input					clk,
input					write_n,
input					pup3,
input					romsel_n,
output	[7:0]		rom_do
);

wire [7:0]pcs;

always @(clk)
 rom_do <= 	pcs[0] ? rom1_do :
				pcs[1] ? rom2_do :
				pcs[2] ? rom3_do :
				pcs[3] ? rom4_do :
				pcs[4] ? rom5_do :
				pcs[5] ? rom6_do :
				pcs[6] ? rom7_do :
				pcs[7] ? rom8_do :
				8'b00000000;

wire [7:0]rom1_do;
wire [7:0]rom2_do;
wire [7:0]rom3_do;
wire [7:0]rom4_do;
wire [7:0]rom5_do;
wire [7:0]rom6_do;
wire [7:0]rom7_do;
wire [7:0]rom8_do;
	
sprom #(
	.init_file("./rom/hrl6a_1.hex"),
	.widthad_a(10),
	.width_a(8))
c13A(
	.address(addr[9:0]),
	.clock(clk),//pcs[0]
	.q(rom1_do)
	);
	
sprom #(
	.init_file("./rom/hrl7a_1.hex"),
	.widthad_a(10),
	.width_a(8))
c12A(
	.address(addr[9:0]),
	.clock(clk),//pcs[1]
	.q(rom2_do)
	);	
	
sprom #(
	.init_file("./rom/hrl8a_1.hex"),
	.widthad_a(10),
	.width_a(8))
c11A(
	.address(addr[9:0]),
	.clock(clk),//pcs[2]
	.q(rom3_do)
	);
	
sprom #(
	.init_file("./rom/hrl9a_1.hex"),
	.widthad_a(10),
	.width_a(8))
c10A(
	.address(addr[9:0]),
	.clock(clk),//pcs[3]
	.q(rom4_do)
	);		
	
sprom #(
	.init_file("./rom/hrl10a_1.hex"),
	.widthad_a(10),
	.width_a(8))
c9A(
	.address(addr[9:0]),
	.clock(clk),//pcs[4]
	.q(rom5_do)
	);

`ifndef targ	
sprom #(
	.init_file(""),
	.widthad_a(10),
	.width_a(8))
c8A(
	.address(addr[9:0]),
	.clock(clk),//pcs[5]
	.q(rom6_do)
	);
	
sprom #(
	.init_file(""),
	.widthad_a(10),
	.width_a(8))
c8A(
	.address(addr[9:0]),
	.clock(clk),//pcs[6]
	.q(rom7_do)
	);	
	
sprom #(
	.init_file(""),
	.widthad_a(10),
	.width_a(8))
c8A(
	.address(addr[9:0]),
	.clock(clk),//pcs[7]
	.q(rom8_do)
	);	
`endif

//targ
`ifdef targ
wire A =  addr[11];
wire B =  addr[12];
wire C =  addr[13];
wire pap19 = 1'b1;
wire pap20 =  addr[10];
wire pap21 = 1'b0;
`endif

ttl_74ls138 c5B(
  	.a(A),
  	.b(B),
  	.c(C),
	.g1(pup3),
	.g2a_n(romsel_n),
	.g2b_n(romsel_n),
  	.y_n(pcs),
	);
endmodule 
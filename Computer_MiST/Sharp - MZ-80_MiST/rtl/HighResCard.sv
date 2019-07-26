module HighResBoard(
	input 	[7:0]	Din,
	output 	[7:0]	Dout,
	input				CS0_n,
	input				CS1_n,
	input				CS2_n,
	input				WR_n,
	input				Clk,
	output[10:0]	VAin,
	output[10:0]	VAout
);

wire [7:0] IC1_Aout, IC1_Bin;
TTL74LS245 IC1(
	.OE(CS2_n),
	.DIR(1'b0),
	.Ain(Din),
	.Aout(Aout),
	.Bin(),
	.Bout(Dout)
	);
	
LS245 IC1(
	.DIR(1'b0),
   .OE(CS2_n),
   .Ai(Din),
   .Bi(Bin),
	.Ao(Dout),
   .Bo(Bout)
    );	
	
TTL74LS373 IC2(
	.LE(CS0_n),
	.D({Din[4],Din[5],Din[6],1'b0,Din[3],Din[2],Din[1],Din[0]}),
	.OE_n(~CS2_n),//inverted test
	.Q()
);

TTL74LS373 IC3(
	.LE(CS1_n),
	.D({1'b0,1'b0,1'b0,1'b0,1'b0,Din[2],Din[1],Din[0]}),
	.OE_n(~CS2_n),//inverted test
	.Q()
);

wire [9:0]addr;
wire 	ram_we = WR_n | CS2_n;
wire [7:0]din;
wire [7:0]out;
spram #(
	.addr_width_g(10),
	.data_width_g(8))
IC4(
	.clk_i(Clk),
	.we_i(ram_we),
	.addr_i(addr),
	.data_i(din),
	.data_o(out)
	);
	
TTL74LS245 IC5(
	.OE(~VAin[10]),
	.DIR(1'b1),
	.Ain(),
	.Aout(),
	.Bin(),
	.Bout()
	);

TTL74LS245 IC6(
	.OE(CS2_n),
	.DIR(1'b0),
	.Ain(),
	.Aout(),
	.Bin(),
	.Bout()
	);
	
TTL74LS245 IC7(
	.OE(CS2_n),
	.DIR(1'b0),
	.Ain(),
	.Aout(),
	.Bin(),
	.Bout()
	);

endmodule 
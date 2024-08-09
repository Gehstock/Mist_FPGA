
module AttackForce_memory(
input				Clock,
input				RW_n,
input		[15:0]Addr,
input		[15:0]Ram_Addr,
output	 [7:0]Ram_out,
input		 [7:0]Ram_in,
output	 [7:0]Rom_out
);
`ifdef unencrypted
wire [9:0] Addr_enc = Addr[9:0]
`else
wire [9:0] Addr_enc = {Addr[8],Addr[9],Addr[7:0]}
`endif;
wire [7:0]rom_data_0;
wire [7:0]rom_data_1;
wire [7:0]rom_data_2;
wire [7:0]rom_data_3;
wire [7:0]rom_data_4;
wire [7:0]rom_data_5;
wire [7:0]rom_data_6;



`ifdef unencrypted
	egs0 rom0(
`else
	a30a rom0(
`endif
	.clk(Clock),
	.addr(Addr_enc[9:0]),
	.data(rom_data_0)
);

`ifdef unencrypted
	egs1 rom1(
`else
	a36a rom1(
`endif
	.clk(Clock),
	.addr(Addr_enc[9:0]),
	.data(rom_data_1)
);

`ifdef unencrypted
	egs2 rom2(
`else
	a31a rom2(
`endif
	.clk(Clock),
	.addr(Addr_enc[9:0]),
	.data(rom_data_2)
);

`ifdef unencrypted
	egs3 rom3(
`else
	a37a rom3(
`endif
	.clk(Clock),
	.addr(Addr_enc[9:0]),
	.data(rom_data_3)
);

`ifdef unencrypted
	egs4 rom4(
`else
	a32a rom4(
`endif
	.clk(Clock),
	.addr(Addr_enc[9:0]),
	.data(rom_data_4)
);

`ifdef unencrypted
	egs6 rom5(
`else
	a33a rom5(
`endif
	.clk(Clock),
	.addr(Addr_enc[9:0]),
	.data(rom_data_5)
);

`ifdef unencrypted
	egs7 rom6(
`else
	a39a rom6(
`endif
	.clk(Clock),
	.addr(Addr_enc[9:0]),
	.data(rom_data_6)
);

always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5, rom_data_6) begin
	Rom_out = 8'b00000000;
		case (Addr[14:10])
			5'b00000 : Rom_out = rom_data_0;
			5'b00001 : Rom_out = rom_data_1;	//0000 0100 0000 0000		0400
			5'b00010 : Rom_out = rom_data_2;	//0000 1000 0000 0000		0800
			5'b00011 : Rom_out = rom_data_3;	//0000 1100 0000 0000		0C00
			5'b00100 : Rom_out = rom_data_4;	//0001 0000 0000 0000		1000
			5'b00110 : Rom_out = rom_data_5;	//0001 1000 0000 0000		1800
			5'b00111 : Rom_out = rom_data_6;	//0001 1100 0000 0000		1C00
			default : Rom_out = 8'b00000000;
		endcase
end
	
		
spram #(
	.addr_width_g(13),
	.data_width_g(8)) 
u_ram0(
	.address(Ram_Addr[12:0]),
	.clken(1'b1),
	.clock(Clock),
	.data(Ram_in),
	.wren(~RW_n),
	.q(Ram_out)
	);
endmodule 
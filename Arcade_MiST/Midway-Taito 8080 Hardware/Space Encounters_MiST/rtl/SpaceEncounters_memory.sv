module SpaceEncounters_memory(
input				Clock,
input				RW_n,
input		[15:0]Addr,
input		[15:0]Ram_Addr,
output	 [7:0]Ram_out,
input		 [7:0]Ram_in,
output	 [7:0]Rom_out
);

wire [7:0]rom_data_0;
wire [7:0]rom_data_1;
wire [7:0]rom_data_2;
wire [7:0]rom_data_3;
wire [7:0]rom_data_4;
wire [7:0]rom_data_5;
wire [7:0]rom_data_6;
wire [7:0]rom_data_7;

h1 rom0(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_0)
);

g1 rom1(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_1)
);

f1 rom2(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_2)
);

e1 rom3(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_3)
);

d1 rom4(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_4)
);

c1 rom5(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_5)
);

b1 rom6(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_6)
);

a1 rom7(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_7)
);



always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5, rom_data_6, rom_data_7) begin
	Rom_out = 8'b00000000;
		case (Addr[15:11])
			5'b00000 : Rom_out = rom_data_0;
			5'b00001 : Rom_out = rom_data_1;	//0000 1000 0000 0000		0800
			5'b00010 : Rom_out = rom_data_2;	//0001 0000 0000 0000		1000
			5'b00011 : Rom_out = rom_data_3;	//0001 1000 0000 0000		1800
			
			5'b01000 : Rom_out = rom_data_4;	//0100 0000 0000 0000		4000
			5'b01001 : Rom_out = rom_data_5;	//0100 1000 0000 0000		4800
			5'b01010 : Rom_out = rom_data_6;	//0101 0000 0000 0000		5000
			5'b01011 : Rom_out = rom_data_7;	//0101 1000 0000 0000		5800
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
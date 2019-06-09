
module OzmaWars_memory(
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


mw01 mw01 (
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_0)
);

mw02 mw02 (
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_1)
);

mw03 mw03 (
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_2)
);

mw04 mw04 (
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_3)
);

mw05 mw05 (
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_4)
);

mw06 mw06 (
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_5)
);
	
always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5) begin
	Rom_out = 8'b00000000;
		case (Addr[15:11])
			5'b00000 : Rom_out = rom_data_0;
			5'b00001 : Rom_out = rom_data_1;
			5'b00010 : Rom_out = rom_data_2;
			5'b00011 : Rom_out = rom_data_3;
			5'b01000 : Rom_out = rom_data_4;
			5'b01001 : Rom_out = rom_data_5;
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
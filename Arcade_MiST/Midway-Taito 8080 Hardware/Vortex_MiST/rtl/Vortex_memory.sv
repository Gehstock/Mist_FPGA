
module Vortex_memory(
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
wire [10:0]rom_addr = {Addr[11:10],~Addr[9],Addr[8:4],~Addr[3],Addr[2:1],~Addr[0]};

rom1t36 rom1t36 (
	.clk(Clock),
	.addr(rom_addr),
	.data(rom_data_0)
);

rom2t35 rom2t35 (
	.clk(Clock),
	.addr(rom_addr),
	.data(rom_data_1)
);

rom3t34 rom3t34 (
	.clk(Clock),
	.addr(rom_addr),
	.data(rom_data_2)
);

rom4t33 rom4t33 (
	.clk(Clock),
	.addr(rom_addr),
	.data(rom_data_3)
);

rom5t32 rom5t32 (
	.clk(Clock),
	.addr(rom_addr),
	.data(rom_data_4)
);

rom6t31 rom6t31 (
	.clk(Clock),
	.addr(rom_addr),
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
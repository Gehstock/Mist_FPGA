
module invaders_memory(
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
//wire [7:0]rom_data_2;
//wire [7:0]rom_data_3;
//wire [7:0]rom_data_4;
//wire [7:0]rom_data_5;

rom1 rom1(
	.clk(Clock),
	.addr(Addr[12:0]),
	.data(rom_data_0)
);

rom2 rom2(
	.clk(Clock),
	.addr(Addr[10:0]),
	.data(rom_data_1)
);
	
always @(Addr, rom_data_0, rom_data_1) begin
	Rom_out = 8'b00000000;
		case (Addr[15:11])
			5'b00000 : Rom_out = rom_data_0;
			5'b00001 : Rom_out = rom_data_0;//800	2k
			5'b00010 : Rom_out = rom_data_0;//1000 4k
			5'b00011 : Rom_out = rom_data_0;//1800	6k
			5'b00100 : Rom_out = rom_data_0;//2000	8k
			
			5'b01000 : Rom_out = rom_data_1;//0100 0000 0000 0000
			5'b01001 : Rom_out = rom_data_1;
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
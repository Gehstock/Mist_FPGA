
module BowlingAlley_memory(
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


sprom #(
	.init_file("./roms/h.cpu.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_h (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_0)
	);

sprom #(
	.init_file("./roms/g.cpu.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_g (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_1)
	);
	
sprom #(
	.init_file("./roms/f.cpu.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_f (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_2)
	);
	
sprom #(
	.init_file("./roms/e.cpu.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_e (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_3)
	);

sprom #(
	.init_file("./roms/d.cpu.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_d (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_4)
	);
	
always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4) begin
	Rom_out = 8'b00000000;
		case (Addr[15:11])
			5'b00000 : Rom_out = rom_data_0;
			5'b00001 : Rom_out = rom_data_1;
			5'b00010 : Rom_out = rom_data_2;
			5'b00011 : Rom_out = rom_data_3;
			5'b01000 : Rom_out = rom_data_4;
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
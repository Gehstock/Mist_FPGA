
module Checkmate_memory(
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
sprom #(
	.init_file("./roms/checkmat.h.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_h (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_0)
	);

sprom #(
	.init_file("./roms/checkmat.g.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_g (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_1)
	);
	
sprom #(
	.init_file("./roms/checkmat.f.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_f (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_2)
	);	
	
sprom #(
	.init_file("./roms/checkmat.e.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_e (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_3)
	);		

assign Rom_out = Addr[11:10] == 2'b00 ? rom_data_0 ://0000 00	11 1111 1111
					  Addr[11:10] == 2'b01 ? rom_data_1 ://0000 01	11 1111 1111
					  Addr[11:10] == 2'b10 ? rom_data_2 ://0000 10	11 1111 1111
					  Addr[11:10] == 2'b11 ? rom_data_3 ://0000 11  11 1111 1111
					  8'hz;
		
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
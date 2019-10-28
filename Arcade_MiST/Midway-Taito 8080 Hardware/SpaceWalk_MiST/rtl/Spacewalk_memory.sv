
module Spacewalk_memory(
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


sprom #(
	.init_file("./roms/sw.h.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_h (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_0)
	);

sprom #(
	.init_file("./roms/sw.g.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_g (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_1)
	);
	
sprom #(
	.init_file("./roms/sw.f.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_f (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_2)
	);
	
sprom #(
	.init_file("./roms/sw.e.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_e (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_3)
	);

	
	
	
	sprom #(
	.init_file("./roms/sw.d.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_d (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_4)
	);

sprom #(
	.init_file("./roms/sw.c.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_c (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_5)
	);
	
sprom #(
	.init_file("./roms/sw.b.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_b (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_6)
	);
	
sprom #(
	.init_file("./roms/sw.a.hex"),
	.widthad_a(10),
	.width_a(8))
u_rom_a (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_7)
	);
	
always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5, rom_data_6, rom_data_7) begin
	Rom_out = 8'b00000000;
		case (Addr[13:10])
			4'b0000 : Rom_out = rom_data_0;
			4'b0001 : Rom_out = rom_data_1;// 0100 0000 0000
			4'b0010 : Rom_out = rom_data_2;// 1000 0000 0000
			4'b0011 : Rom_out = rom_data_3;
			
			4'b0100 : Rom_out = rom_data_4;
			4'b0101 : Rom_out = rom_data_5;
			4'b0110 : Rom_out = rom_data_6;
			4'b0111 : Rom_out = rom_data_7;
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
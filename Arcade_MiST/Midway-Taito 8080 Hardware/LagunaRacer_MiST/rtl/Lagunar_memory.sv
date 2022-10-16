module Lagunar_memory(
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
	.init_file("./roms/lagunar_h.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_h (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_0)
	);
	
sprom #(
	.init_file("./roms/lagunar_g.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_g (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_1)
	);

sprom #(
	.init_file("./roms/lagunar_f.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_f (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_2)
	);
	
sprom #(
	.init_file("./roms/lagunar_e.hex"),
	.widthad_a(11),
	.width_a(8))
u_rom_e (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_3)
	);

always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3) begin
	Rom_out = 8'b00000000;
	case (Addr[15:11])
		6'b00000 : Rom_out = rom_data_0; //0
		6'b00001 : Rom_out = rom_data_1; //0800
		6'b00010 : Rom_out = rom_data_2; //1000
		6'b00011 : Rom_out = rom_data_3; //1800
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

module D280ZZZAP_memory(
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


sprom #(
	.init_file("./roms/zzzap_h.hex"),
	.widthad_a(10), 
	.width_a(8))
u_rom_h (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_0)
	);
	
sprom #(
	.init_file("./roms/zzzap_g.hex"),
	.widthad_a(10), 
	.width_a(8))
u_rom_g (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_1)
	);	

sprom #(
	.init_file("./roms/zzzap_f.hex"),
	.widthad_a(10), 
	.width_a(8))
u_rom_f (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_2)
	);
	
sprom #(
	.init_file("./roms/zzzap_e.hex"),
	.widthad_a(10), 
	.width_a(8))
u_rom_e (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_3)
	);

sprom #(
	.init_file("./roms/zzzap_d.hex"),
	.widthad_a(10), 
	.width_a(8))
u_rom_d (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_4)
	);
	
sprom #(
	.init_file("./roms/zzzap_c.hex"),
	.widthad_a(10), 
	.width_a(8))
u_rom_c (
	.clock(Clock),
	.Address(Addr[9:0]),
	.q(rom_data_5)
	);

always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5) begin
	Rom_out = 8'b00000000;
		case (Addr[15:10])
			6'b000000 : Rom_out = rom_data_0; //0
			6'b000001 : Rom_out = rom_data_1; //0400
			6'b000010 : Rom_out = rom_data_2; //0800
			6'b000011 : Rom_out = rom_data_3; //0c00		
			6'b000100 : Rom_out = rom_data_4; //1000
			6'b000101 : Rom_out = rom_data_5; //1400

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
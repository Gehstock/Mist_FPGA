
module invaders_memory(
input				Clock,
input				RW_n,
input		[15:0]Addr,
input		[12:0]Ram_Addr,
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
`ifdef sflush	.init_file("./roms/Strightflush/fr01_sc6.hex"), `endif//
`ifdef zzzap280	.init_file("./roms/280zzz/zzzap_c.hex"), `endif//
`ifdef slaser		.init_file("./roms/SpaceLaser/la01.hex"), `endif//working
`ifdef lrescue		.init_file("./roms/LunarRescue/lrescue_1.hex"), `endif//not working
`ifdef invaders	.init_file("./roms/SpaceInvaders/invaders_h.hex"), `endif//working
`ifdef gunfight	.init_file("./roms/Gunfight/7609_e.hex"), `endif//not working
`ifdef supearth	.init_file("./roms/SuperEarthInvasion/earthinv_h.hex"), `endif//working
`ifdef seawolf		.init_file("./roms/Seawolf/sw0041_h.hex"), `endif//not working
`ifdef dogpatch	.init_file("./roms/Dogpatch/dogpatch_h.hex"), `endif//not working
`ifdef jspecter	.init_file("./roms/jspecter/rom_h.hex"), `endif//not working
`ifdef invadrev	.init_file("./roms/InvadersRevenge/invrvnge_e.hex"), `endif//not 
`ifdef blueshark	.init_file("./roms/BlueShark/blueshrk_h.hex"), `endif//
`ifdef zzzap280	.widthad_a(10), `endif//
`ifdef generic	.widthad_a(11), `endif//
//	.widthad_a(11), 
	.width_a(8))
u_rom_h (
	.clock(Clock),
`ifdef zzzap280 .Address(Addr[9:0]), `endif
`ifdef generic	.Address(Addr[10:0]), `endif
	.q(rom_data_0)
	);

sprom #(
`ifdef sflush	.init_file("./roms/Strightflush/fr02_sc5.hex"), `endif//
`ifdef zzzap280	.init_file("./roms/280zzz/zzzap_d.hex"), `endif//
`ifdef slaser		.init_file("./roms/SpaceLaser/la02.hex"), `endif
`ifdef lrescue		.init_file("./roms/LunarRescue/lrescue_2.hex"), `endif
`ifdef invaders	.init_file("./roms/SpaceInvaders/invaders_g.hex"), `endif
`ifdef gunfight	.init_file("./roms/Gunfight/7609_f.hex"), `endif//not working
`ifdef supearth	.init_file("./roms/SuperEarthInvasion/earthinv_g.hex"), `endif//working
`ifdef seawolf		.init_file("./roms/Seawolf/sw0042_g.hex"), `endif//not working
`ifdef dogpatch	.init_file("./roms/Dogpatch/dogpatch_g.hex"), `endif//not working
`ifdef jspecter	.init_file("./roms/jspecter/rom_g.hex"), `endif//not working
`ifdef invadrev	.init_file("./roms/InvadersRevenge/invrvnge_f.hex"), `endif//not working
`ifdef blueshark	.init_file("./roms/BlueShark/blueshrk_g.hex"), `endif//
`ifdef zzzap280	.widthad_a(10), `endif//
`ifdef generic	.widthad_a(11), `endif//
//	.widthad_a(11), 
	.width_a(8))
u_rom_g (
	.clock(Clock),
`ifdef zzzap280 .Address(Addr[9:0]), `endif
`ifdef generic	.Address(Addr[10:0]), `endif
	.q(rom_data_1)
	);
	
sprom #(
`ifdef sflush	.init_file("./roms/Strightflush/fr03_sc4.hex"), `endif//
`ifdef zzzap280	.init_file("./roms/280zzz/zzzap_e.hex"), `endif//
`ifdef slaser		.init_file("./roms/SpaceLaser/la03.hex"), `endif
`ifdef lrescue		.init_file("./roms/LunarRescue/lrescue_3.hex"), `endif
`ifdef invaders	.init_file("./roms/SpaceInvaders/invaders_f.hex"), `endif
`ifdef gunfight	.init_file("./roms/Gunfight/7609_g.hex"), `endif//not working
`ifdef supearth	.init_file("./roms/SuperEarthInvasion/earthinv_f.hex"), `endif//working
`ifdef seawolf		.init_file("./roms/Seawolf/sw0043_f.hex"), `endif//not working
`ifdef dogpatch	.init_file("./roms/Dogpatch/dogpatch_f.hex"), `endif//not working
`ifdef jspecter	.init_file("./roms/jspecter/rom_f.hex"), `endif//not working
`ifdef invadrev	.init_file("./roms/InvadersRevenge/invrvnge_g.hex"), `endif//not working
`ifdef blueshark	.init_file("./roms/BlueShark/blueshrk_f.hex"), `endif//
`ifdef zzzap280	.widthad_a(10), `endif//
`ifdef generic	.widthad_a(11), `endif//
//	.widthad_a(11), 
	.width_a(8))
u_rom_f (
	.clock(Clock),
`ifdef zzzap280 .Address(Addr[9:0]), `endif
`ifdef generic	.Address(Addr[10:0]), `endif
	.q(rom_data_2)
	);
	
`ifndef blueshark
sprom #(
`ifdef sflush	.init_file("./roms/Strightflush/fr04_sc3.hex"), `endif//
`ifdef zzzap280	.init_file("./roms/280zzz/zzzap_f.hex"), `endif//not working
`ifdef slaser		.init_file("./roms/SpaceLaser/la04.hex"), `endif
`ifdef lrescue		.init_file("./roms/LunarRescue/lrescue_4.hex"), `endif
`ifdef invaders	.init_file("./roms/SpaceInvaders/invaders_e.hex"), `endif
`ifdef gunfight	.init_file("./roms/Gunfight/7609_h.hex"), `endif//not working
`ifdef supearth	.init_file("./roms/SuperEarthInvasion/earthinv_e.hex"), `endif//working
`ifdef seawolf		.init_file("./roms/Seawolf/sw0044_e.hex"), `endif//not working
`ifdef dogpatch	.init_file("./roms/Dogpatch/dogpatch_e.hex"), `endif//not working
`ifdef jspecter	.init_file("./roms/jspecter/rom_e.hex"), `endif//not working
`ifdef invadrev	.init_file("./roms/InvadersRevenge/invrvnge_h.hex"), `endif//not working
`ifdef zzzap280	.widthad_a(10), `endif//
`ifdef generic	.widthad_a(11), `endif//
	.width_a(8))
u_rom_e (
	.clock(Clock),
`ifdef zzzap280 .Address(Addr[9:0]), `endif
`ifdef generic	.Address(Addr[10:0]), `endif
	.q(rom_data_3)
	);
	`endif//	
`ifndef generic
sprom #(
`ifdef sflush	.init_file("./roms/Strightflush/fr05_sc2.hex"), `endif//
`ifdef zzzap280	.init_file("./roms/280zzz/zzzap_g.hex"), `endif//
`ifdef lrescue		.init_file("./roms/LunarRescue/lrescue_5.hex"), `endif
`ifdef zzzap280	.widthad_a(10), `endif//
`ifdef generic	.widthad_a(11), `endif//
	.width_a(8))
u_rom_i (
	.clock(Clock),
`ifdef zzzap280 .Address(Addr[9:0]), `endif
`ifdef generic	.Address(Addr[10:0]), `endif
	.q(rom_data_4)
	);

sprom #(
`ifdef zzzap280	.init_file("./roms/280zzz/zzzap_h.hex"), `endif//
`ifdef lrescue		.init_file("./roms/LunarRescue/lrescue_6.hex"), `endif
`ifdef zzzap280	.widthad_a(10), `endif//
`ifdef generic	.widthad_a(11), `endif//
	.width_a(8))
u_rom_j (
	.clock(Clock),
`ifdef zzzap280 .Address(Addr[9:0]), `endif
`ifdef generic	.Address(Addr[10:0]), `endif
	.q(rom_data_5)
	);	
`endif//	
always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5, rom_data_6, rom_data_7) begin
	Rom_out = 8'b00000000;
		case (Addr[13:11])
			3'b000 : Rom_out = rom_data_0;
			3'b001 : Rom_out = rom_data_1;
			3'b010 : Rom_out = rom_data_2;
			3'b011 : Rom_out = rom_data_3;
			3'b100 : Rom_out = rom_data_4;
			3'b101 : Rom_out = rom_data_5;
			3'b110 : Rom_out = rom_data_6;		
			3'b111 : Rom_out = rom_data_7;
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
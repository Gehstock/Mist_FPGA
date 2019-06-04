module CHAR_GEN_ROM
(
	pixel_clock,
	address,
	data
);

input				pixel_clock;
input		[11:0]	address;
output wire [7:0] 	data;

// Character generator
char_rom_4k_altera char_rom(
	.address(address),
	.clock(pixel_clock),
	.q(data)
);

endmodule //CHAR_GEN_ROM

// Copyright (c) 2012,20 MiSTer-X 

module PKWARS_ROMS
(
	input					CLKx2,
	input					CLK,
	input					VCLK,

	output reg	[1:0]	PHASE,
	input	     	[13:0]BGCAD,
	output reg 	[31:0]BGCDT,

	input	     	[13:0]SPCAD,
	output reg 	[31:0]SPCDT,
	output  		[13:0]gfx_rom_addr,
	input	     	[31:0]gfx_rom_do
);


always @( negedge CLK ) PHASE <= PHASE+1;

reg sd;

wire [13:0] AD = sd ? SPCAD : BGCAD;

assign gfx_rom_addr = AD;

always @( negedge CLKx2 ) begin
	if (sd) SPCDT <= gfx_rom_do;
	else    BGCDT <= gfx_rom_do;
	sd <= ~sd;
end

endmodule

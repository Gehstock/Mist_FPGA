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

always @( posedge CLK ) PHASE <= PHASE+1;

/*
wire [7:0] gfx1_do, gfx2_do, gfx3_do;
wire [7:0] gfx4_do = gfx_rom_do[31:24];
wire [31:0] gfx_do = {gfx4_do,gfx3_do,gfx2_do,gfx1_do};
gfx1 gfx1(
	.clk(CLKx2),
	.addr(AD),
	.data(gfx1_do)
);

gfx2 gfx2(
	.clk(CLKx2),
	.addr(AD),
	.data(gfx2_do)
);

gfx3 gfx3(
	.clk(CLKx2),
	.addr(AD),
	.data(gfx3_do)
);*/

wire [13:0] AD = sd ? SPCAD : BGCAD;
reg sd;
assign gfx_rom_addr = AD;

always @( negedge CLKx2 ) begin
	if (sd) SPCDT <= gfx_rom_do;
	else    BGCDT <= gfx_rom_do;
	sd <= ~sd;
end

endmodule

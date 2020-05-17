// Copyright (c) 2017,19 MiSTer-X

module System1_Video
(
	input				VCLKx8,
	input				VCLKx4,
	input				VCLKx2,
	input				VCLK,

	input		[8:0]	PH,
	input		[8:0]	PV,

	output			VBLK,
	output   [7:0]	RGB8,

	input				PALDSW,

	input				cpu_cl,
	input	  [15:0]	cpu_ad,
	input				cpu_wr,
	input		[7:0]	cpu_dw,
	output			cpu_rd,
	output	[7:0]	cpu_dr,
	output  [15:0] spr_rom_addr,
	input	  [7:0]	spr_rom_do,	
	output  [13:0] tile_rom_addr,
	input	  [23:0]	tile_rom_do
);

// CPU Interface
wire [10:0] palno;
wire  [7:0] palout;

wire  [9:0] sprad;
wire [15:0] sprdt;

wire  [9:0] vram0ad;
wire [15:0] vram0dt;
wire  [9:0] vram1ad;
wire [15:0] vram1dt;

wire  [5:0]	mixcoll_ad;
wire 			mixcoll;
wire  [9:0]	sprcoll_ad;
wire 			sprcoll;

wire [15:0]	scrx;
wire  [7:0] scry;

VIDCPUINTF intf(
	cpu_cl,
	cpu_ad, cpu_wr, cpu_dw,
	cpu_rd, cpu_dr,

	VCLKx4, VCLK,
	palno, palout,
	sprad, sprdt,
	vram0ad, vram0dt,
	vram1ad, vram1dt,
	mixcoll_ad, mixcoll,
	sprcoll_ad, sprcoll,
	scrx, scry
);


// HV Coordinate Generator
wire [8:0] HPOS,  VPOS;
wire [8:0] BG0HP, BG0VP;
wire [8:0] BG1HP, BG1VP;
VIDHVGEN hv(
	PH,    PV,
	scrx,  scry,
	HPOS,  VPOS,
	BG0HP, BG0VP,
	BG1HP, BG1VP,
	VBLK
);
	

// Sprite Engine
wire [10:0] SPRPX;
wire [15:0] sprchad;
wire  [7:0] sprchdt;
//DLROM #(15,8) sprchr(VCLKx8,sprchad,sprchdt, ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:15]==2'b0_1));	// $08000-$0FFFF
//spr_rom spr_rom(
//	.clk(VCLKx8),
//	.addr(sprchad),
//	.data(sprchdt)
//);
assign  spr_rom_addr = sprchad;
assign sprchdt = spr_rom_do;


System1_Sprite System1_Sprite(
	.VCLKx4(VCLKx4),
	.VCLK(VCLK),
	.PH(HPOS),
	.PV(VPOS),
	.sprad(sprad),
	.sprdt(sprdt),
	.sprchad(sprchad),
	.sprchdt(sprchdt),
	.sprcoll(sprcoll),
	.sprcoll_ad(sprcoll_ad),
	.sprpx(SPRPX)
);


// BG Scanline Generator
wire [10:0] BG0PX, BG1PX;
wire [13:0]	tile0ad, tile1ad, tilead;
wire [23:0] tile0dt, tile1dt, tiledt;
TileChrMUX tilemux(VCLKx8, tile0ad, tile0dt, tile1ad, tile1dt, tilead, tiledt);
//TILES
//FlickyTileChr tilechr(VCLKx8, tilead, tiledt, ROMCL,ROMAD,ROMDT,ROMEN );
assign tile_rom_addr = tilead;
assign tiledt = tile_rom_do;
BGGEN bg0(VCLK,BG0HP,BG0VP,vram0ad,vram0dt,tile0ad,tile0dt,BG0PX);
BGGEN bg1(VCLK,BG1HP,BG1VP,vram1ad,vram1dt,tile1ad,tile1dt,BG1PX);


// Color Mixer & RGB Output
wire [7:0] cltidx,cltval;
//DLROM #(8,8) clut(VCLKx2, cltidx, cltval, ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:8]==9'b1_1110_0000) ); // $1E000-$1E0FF
clut clut(
	.clk(VCLKx2),
	.addr(cltidx),
	.data(cltval)
);

COLMIX cmix(
	VCLK,
	BG0PX, BG1PX, SPRPX,
	PALDSW, HPOS, VPOS,
	cltidx, cltval,
	mixcoll, mixcoll_ad,
	palno, palout,
	RGB8
);

endmodule


//----------------------------------
//  CPU Interface
//----------------------------------
module VIDCPUINTF
(
	input				cpu_cl,
	input	  [15:0]	cpu_ad,
	input				cpu_wr,
	input		[7:0]	cpu_dw,
	output			cpu_rd,
	output	[7:0]	cpu_dr,

	input				VCLKx4,
	input				VCLK,

	input	  [10:0] palno,
	output   [7:0] palout,

	input		[9:0] sprad,
	output  [15:0] sprdt,

	input	   [9:0] vram0ad,
	output  [15:0] vram0dt,

	input    [9:0] vram1ad,
	output  [15:0]	vram1dt,

	input    [5:0]	mixcoll_ad,
	input				mixcoll,

	input    [9:0]	sprcoll_ad,
	input				sprcoll,
	
	output reg [15:0] scrx,
	output reg  [7:0] scry
);

// CPU Address Decoders
wire cpu_cs_palram;
wire cpu_cs_spram;
wire cpu_cs_mixcoll;
wire cpu_cs_sprcoll;
wire cpu_cs_vram0;
wire cpu_cs_vram1;

wire cpu_wr_palram;
wire cpu_wr_spram;
wire cpu_wr_mixcoll;
wire cpu_wr_mixcollclr;
wire cpu_wr_sprcoll;
wire cpu_wr_sprcollclr;
wire cpu_wr_vram0;
wire cpu_wr_vram1;
wire cpu_wr_scrreg;

VIDADEC adecs(
	cpu_ad,
	cpu_wr,

	cpu_cs_palram,
	cpu_cs_spram,
	cpu_cs_mixcoll,
	cpu_cs_sprcoll,
	cpu_cs_vram0,
	cpu_cs_vram1,
	
	cpu_wr_palram,
	cpu_wr_spram,
	cpu_wr_mixcoll,
	cpu_wr_mixcollclr,
	cpu_wr_sprcoll,
	cpu_wr_sprcollclr,
	cpu_wr_vram0,
	cpu_wr_vram1,
	cpu_wr_scrreg,

	cpu_rd
);

// Scroll Register
always @ ( posedge cpu_cl ) begin
	if (cpu_wr_scrreg) begin
		case({cpu_ad[6],cpu_ad[0]})
		2'b11: scrx[15:8] <= cpu_dw;
		2'b10: scrx[ 7:0] <= cpu_dw;
		2'b01: scry <= cpu_dw;
		2'b00: ;
		endcase
	end
end


// Palette RAM
wire  [7:0] cpu_rd_palram;
DPRAM2048 palram(
	cpu_cl, cpu_ad[10:0], cpu_dw, cpu_wr_palram,
	VCLK, palno, palout, cpu_rd_palram
);


// Sprite Attribute RAM
wire  [7:0] cpu_rd_spram;
DPRAM2048_8_16 sprram(
	cpu_cl, cpu_ad[10:0], cpu_dw, cpu_wr_spram,
	VCLKx4, sprad, sprdt, cpu_rd_spram
);


// Collision RAM (Mixer & Sprite)
wire			noclip = 1'b1;
wire [7:0]	cpu_rd_mixcoll;
wire [7:0]	cpu_rd_sprcoll;
COLLRAM_M mixc(
	cpu_cl,cpu_ad[5:0],cpu_wr_mixcoll,cpu_wr_mixcollclr,cpu_rd_mixcoll,
	VCLKx4,mixcoll_ad,mixcoll & noclip
);
COLLRAM_S sprc(
	cpu_cl,cpu_ad[9:0],cpu_wr_sprcoll,cpu_wr_sprcollclr,cpu_rd_sprcoll,
	VCLKx4,sprcoll_ad,sprcoll & noclip
);


// VRAM
wire  [7:0] cpu_rd_vram0, cpu_rd_vram1;
VRAM vram0(
	cpu_cl, cpu_ad[10:0], cpu_rd_vram0, cpu_dw, cpu_wr_vram0,
	VCLKx4, vram0ad, vram0dt
);
VRAM vram1(
	cpu_cl, cpu_ad[10:0], cpu_rd_vram1, cpu_dw, cpu_wr_vram1,
	VCLKx4, vram1ad, vram1dt
);


// CPU Read Data Selector
dataselector6 videodsel(
	cpu_dr,
	cpu_cs_palram,  cpu_rd_palram,
	cpu_cs_vram0,   cpu_rd_vram0,
	cpu_cs_vram1,   cpu_rd_vram1,
	cpu_cs_spram,   cpu_rd_spram,
	cpu_cs_sprcoll, cpu_rd_sprcoll,
	cpu_cs_mixcoll, cpu_rd_mixcoll,
	8'hFF
);

endmodule


//----------------------------------
//  Tile ROM
//----------------------------------
module TileChrMUX
(
	input					VCLKx8,

	input [13:0]		tile0ad,
	output reg [23:0]	tile0dt,

	input [13:0]		tile1ad,
	output reg [23:0]	tile1dt,

	output [13:0]		tilead,
	input  [23:0]		tiledt
);

reg			tphase;
always @(negedge VCLKx8) begin
	if (tphase) tile1dt <= tiledt;
	else tile0dt <= tiledt;
	tphase <= ~tphase;
end
assign tilead = tphase ? tile1ad : tile0ad;

endmodule
/*
module FlickyTileChr
(
	input				clk,
	input  [13:0]	adr,
	output [23:0]	dat,
	
	input				ROMCL,		// Downloaded ROM image
	input   [24:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire [23:0]	t0dt,t1dt;
assign dat = adr[13] ? t1dt : t0dt;

//DLROM #(13,8) t00( clk, adr[12:0], t0dt[7:0]  ,ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:13]==4'b1_000)); // $10000-$11FFF
//tile1 tile1(
//	.clk(clk),
//	.addr(adr[12:0]),
//	.data(t0dt[7:0])
//);


//DLROM #(13,8) t01( clk, adr[12:0], t0dt[15:8] ,ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:13]==4'b1_001)); // $12000-$13FFF
//DLROM #(13,8) t02( clk, adr[12:0], t0dt[23:16],ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:13]==4'b1_010)); // $14000-$15FFF

//DLROM #(13,8) t10( clk, adr[12:0], t1dt[7:0]  ,ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:13]==4'b1_011)); // $16000-$17FFF
//DLROM #(13,8) t11( clk, adr[12:0], t1dt[15:8] ,ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:13]==4'b1_100)); // $18000-$19FFF
//DLROM #(13,8) t12( clk, adr[12:0], t1dt[23:16],ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:13]==4'b1_101)); // $1A000-$1BFFF

endmodule*/


//----------------------------------
//  HV Coordinate Generator
//----------------------------------
module VIDHVGEN
(
	input	 [8:0]	PH,
	input	 [8:0]	PV,

	input [15:0]	scrx,
	input  [7:0]	scry,

	output [8:0]	HPOS,
	output [8:0]	VPOS,

	output [8:0]	BG0HP,
	output [8:0]	BG0VP,

	output [8:0]	BG1HP,
	output [8:0]	BG1VP,

	output			VBLK
);
	
assign VBLK = (PV == 8'd224) & (PH <= 8'd64);

assign HPOS = PH+1;
assign VPOS = PV;

wire [8:0] BGHSCR = (511-scrx[9:1])-10;
wire [8:0] BGVSCR = { 1'b0, scry };

assign BG0HP = BGHSCR+HPOS;
assign BG0VP = BGVSCR+VPOS;

assign BG1HP = HPOS+3;
assign BG1VP = VPOS;

endmodule


//----------------------------------
//  CPU Address Decoders
//----------------------------------
module VIDADEC
(
	input	[15:0] cpu_ad,
	input			 cpu_wr,

	output		 cpu_cs_palram,
	output		 cpu_cs_spram,
	output		 cpu_cs_mixcoll,
	output		 cpu_cs_sprcoll,
	output		 cpu_cs_vram0,
	output		 cpu_cs_vram1,
	
	output		 cpu_wr_palram,
	output		 cpu_wr_spram,
	output		 cpu_wr_mixcoll,
	output		 cpu_wr_mixcollclr,
	output		 cpu_wr_sprcoll,
	output		 cpu_wr_sprcollclr,
	output		 cpu_wr_vram0,
	output		 cpu_wr_vram1,
	output		 cpu_wr_scrreg,

	output		 cpu_rd
);

assign cpu_cs_palram		 = ( cpu_ad[15:11] ==  5'b1101_1  );
assign cpu_cs_spram		 = ( cpu_ad[15:11] ==  5'b11010   );
assign cpu_cs_mixcoll    = ( cpu_ad[15:10] ==  6'b1111_00 );
wire	 cpu_cs_mixcollclr = ( cpu_ad[15:10] ==  6'b1111_01 );
assign cpu_cs_sprcoll    = ( cpu_ad[15:10] ==  6'b1111_10 );
wire   cpu_cs_sprcollclr = ( cpu_ad[15:10] ==  6'b1111_11 );
assign cpu_cs_vram0		 = ( cpu_ad[15:11] ==  5'b11100   );
assign cpu_cs_vram1		 = ( cpu_ad[15:11] ==  5'b11101   );
wire   cpu_cs_scrreg     = ((cpu_ad[15: 0] & 16'b1111_1111_1011_1110) == 16'b1110_1111_1011_1100);


assign cpu_wr_palram 	 = cpu_cs_palram 		& cpu_wr;
assign cpu_wr_spram  	 = cpu_cs_spram  		& cpu_wr;
assign cpu_wr_mixcoll    = cpu_cs_mixcoll    & cpu_wr;
assign cpu_wr_mixcollclr = cpu_cs_mixcollclr & cpu_wr;
assign cpu_wr_sprcoll    = cpu_cs_sprcoll    & cpu_wr;
assign cpu_wr_sprcollclr = cpu_cs_sprcollclr & cpu_wr;
assign cpu_wr_vram0		 = cpu_cs_vram0 		& cpu_wr;
assign cpu_wr_vram1		 = cpu_cs_vram1 		& cpu_wr;
assign cpu_wr_scrreg     = cpu_cs_scrreg		& cpu_wr;


assign cpu_rd = cpu_cs_palram  |
					 cpu_cs_vram0   |
					 cpu_cs_vram1   |
					 cpu_cs_spram   |
					 cpu_cs_sprcoll |
					 cpu_cs_mixcoll ;

endmodule


//----------------------------------
//  BG Scanline Generator
//----------------------------------
module BGGEN
(
	input				VCLK,

	input   [8:0]	HP,
	input   [8:0]	VP,

	output  [9:0]	VRAMAD,
	input	 [15:0]	VRAMDT,

	output [13:0]	TILEAD,
	input	 [23:0]	TILEDT,

	output [10:0]	OPIX
);

assign VRAMAD = { VP[7:3], HP[7:3] };
assign TILEAD = { VRAMDT[15], VRAMDT[10:0], VP[2:0] };

reg  [31:0] BGREG;
wire [23:0] BGCD = BGREG[23:0];
wire  [7:0] BGPN = BGREG[31:24];

wire [31:0] BGPIX;
always @( posedge VCLK ) BGREG <= BGPIX;

dataselector1_32 pixsft(
	BGPIX,
	( HP[2:0] != 2 ),{ BGPN, BGCD[22:0], 1'b0 },
						  { VRAMDT[12:5],   TILEDT }
);

assign OPIX = { BGPN, BGCD[7], BGCD[15], BGCD[23] }; 

endmodule


//----------------------------------
//  Color Mixer & RGB Output
//----------------------------------
module COLMIX
(
	input				VCLK,

	input	 [10:0]	BG0PX,
	input  [10:0]	BG1PX,
	input	 [10:0]	SPRPX,

	input				PALDSW,
	input   [8:0]	HPOS,
	input	  [8:0]	VPOS,

	output  [7:0]	cltidx,
	input   [7:0]	cltval,

	output			mixcoll,
	output  [5:0]	mixcoll_ad,

	output [10:0]	palno,
	input   [7:0]  palout,
	
	output reg [7:0] RGB8
);

assign cltidx = { 1'b0,
	 BG0PX[10:9],(BG0PX[2:0]==0),
	 BG1PX[10:9],(BG1PX[2:0]==0),
	(SPRPX[3:0]==0)
};
	
assign mixcoll    = ~(cltval[2]);
assign mixcoll_ad = { cltval[3], SPRPX[8:4] };

wire [10:0] palno_i;
dataselector2_11 colsel(
	palno_i,
	cltval[1], ( 11'h400 | BG0PX[8:0] ),
	cltval[0], ( 11'h200 | BG1PX[8:0] ),
	           ( 11'h000 | SPRPX[8:0] )
);

wire [10:0] palno_d = {HPOS[7],VPOS[7:2],HPOS[6:3]};

assign palno = PALDSW ? palno_d : palno_i;

always @( negedge VCLK ) RGB8 <= palout;

endmodule


//----------------------------------
//  Collision RAM
//----------------------------------
module COLLRAM_M
(
	input				cpu_cl,
	input  [5:0] 	cpu_ad,
	input				cpu_wr_coll,
	input				cpu_wr_collclr,
	output [7:0]	cpu_rd_coll,
	
	input				VCLKx4,
	input  [5:0] 	coll_ad,
	input				coll
);

reg [63:0] core;
reg coll_rd, coll_sm;

always @(posedge cpu_cl) coll_rd <= core[cpu_ad];

always @(posedge VCLKx4) begin
	if (cpu_cl) begin
		if (cpu_wr_coll) core[cpu_ad] <= 1'b0;
		if (cpu_wr_collclr) coll_sm <= 1'b0;
	end
	else coll_sm <= coll;
	if (coll) core[coll_ad] <= 1'b1;
end

assign cpu_rd_coll = { coll_sm, 6'b111111, coll_rd };

endmodule

module COLLRAM_S
(
	input				cpu_cl,
	input  [9:0] 	cpu_ad,
	input				cpu_wr_coll,
	input				cpu_wr_collclr,
	output [7:0]	cpu_rd_coll,
	
	input				VCLKx4,
	input  [9:0] 	coll_ad,
	input				coll
);

reg [1023:0] core;
reg coll_rd, coll_sm;

always @(posedge cpu_cl) coll_rd <= core[cpu_ad];

always @(posedge VCLKx4) begin
	if (cpu_cl) begin
		if (cpu_wr_coll) core[cpu_ad] <= 1'b0;
		if (cpu_wr_collclr) coll_sm <= 1'b0;
	end
	else coll_sm <= coll;
	if (coll) core[coll_ad] <= 1'b1;
end

assign cpu_rd_coll = { coll_sm, 6'b111111, coll_rd };

endmodule


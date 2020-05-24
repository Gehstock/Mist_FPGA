/********************************************************************
           FPGA Implimentation of "FLICKY" (Top Module)

											Copyright (c) 2017,19 MiSTer-X
*********************************************************************/
module System1_Top
(
	input				clk48M,
	input				reset,
	input				crypt,
	input   [7:0]	INP0,
	input   [7:0]	INP1,
	input   [7:0]	INP2,

	input   [7:0]	DSW0,
	input   [7:0]	DSW1,
	output  [2:0] 	video_r,
	output  [2:0] 	video_g,  	
	output  [1:0] 	video_b,
	output			video_hs,
	output			video_vs,
	output			video_hb,
	output			video_vb,

	output  [15:0] SOUT,			// Sound Out (PCM)
	output  [15:0] cpu_rom_addr,
	input	  [7:0]	cpu_rom_do,
	output  [15:0] spr_rom_addr,
	input	  [7:0]	spr_rom_do,
	output  [12:0] snd_rom_addr,
	input	  [7:0]	snd_rom_do,
	output  [13:0] tile_rom_addr,
	input	  [23:0]	tile_rom_do,
	input   [17:0] dl_addr,
	input	  [7:0]	dl_data,
	input				dl_wr,
	input				dl_clk
);

// Clocks
wire                 clk24M, clk12M, clk6M, clk3M, clk8M ;
CLKGEN clks( clk48M, clk24M, clk12M, clk6M, clk3M, clk8M );

// CPU
wire 			CPUCLn;
wire [15:0] CPUAD;
wire  [7:0] CPUDO,VIDDO;
wire			CPUWR,VIDCS,VBLK;
wire			SNDRQ;

System1_Main System1_Main(
	.RESET(reset),
	.crypt(crypt),
	.INP0(INP0),
	.INP1(INP1),
	.INP2(INP2),
	.DSW0(DSW0),
	.DSW1(DSW1),
	.CLK48M(clk48M),
	.CLK3M(clk3M),
	.CPUCLn(CPUCLn),
	.CPUAD(CPUAD),
	.CPUDO(CPUDO),
	.CPUWR(CPUWR),
	.VBLK(VBLK),
	.VIDCS(VIDCS),
	.VIDDO(VIDDO),
	.SNDRQ(SNDRQ),
	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_do),
	.dl_addr(dl_addr),
	.dl_data(dl_data),
	.dl_wr(dl_wr),
	.dl_clk(dl_clk)
);

System1_Video System1_Video(
	.VCLKx8(clk48M),
	.VCLKx4(clk24M),
	.VCLKx2(clk12M),
	.VCLK(clk6M),
	.PH(HPOS),
	.PV(VPOS),
	.VBLK(VBLK),
	.RGB8(POUT),
	.PALDSW(1'b0),
	.cpu_cl(CPUCLn),
	.cpu_ad(CPUAD),
	.cpu_wr(CPUWR),
	.cpu_dw(CPUDO),
	.cpu_rd(VIDCS),
	.cpu_dr(VIDDO),
	.spr_rom_addr(spr_rom_addr),
	.spr_rom_do(spr_rom_do),
	.tile_rom_addr(tile_rom_addr),
	.tile_rom_do(tile_rom_do),
	.dl_addr(dl_addr),
	.dl_data(dl_data),
	.dl_wr(dl_wr),
	.dl_clk(dl_clk)	
);
assign PCLK = clk6M;

System1_Sound System1_Sound(
   .clk8M(clk8M),
	.reset(reset),
	.sndno(CPUDO),
   .sndstart(SNDRQ),
	.sndout(SOUT),
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_do)	
);

wire [8:0]  HPOS;
wire [8:0]  VPOS;
wire        PCLK;
wire [7:0]	POUT;

System1_Hvgen System1_Hvgen(
	.HPOS(HPOS),
	.VPOS(VPOS),
	.PCLK(PCLK),
	.iRGB(POUT),
	.oRGB({video_b,video_g,video_r}),
	.HBLK(video_hb),
	.VBLK(video_vb),
	.HSYN(video_hs),
	.VSYN(video_vs)
);


endmodule


//----------------------------------
//  Clock Generator
//----------------------------------
module CLKGEN
(
	input	 clk48M,

	output clk24M,
	output clk12M,
	output clk6M,
	output clk3M,

	output reg clk8M
);

reg [4:0] clkdiv;
always @( posedge clk48M ) clkdiv <= clkdiv+1;
assign clk24M = clkdiv[0];
assign clk12M = clkdiv[1];
assign clk6M  = clkdiv[2];
assign clk3M  = clkdiv[3];

reg [1:0] count;
always @( posedge clk48M ) begin
	if (count > 2'd2) begin
		count <= count - 2'd2;
      clk8M <= ~clk8M;
   end
   else count <= count + 2'd1;
end

endmodule


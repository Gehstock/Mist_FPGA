// Copyright (c) 2017,19 MiSTer-X

module System1_Sound
(
   input				clk48M,
	input				reset,

   input   [7:0]	sndno,
   input				sndstart,

   output [15:0]	sndout,
	output  [12:0] snd_rom_addr,
	input	  [7:0]	snd_rom_do	
);

//----------------------------------
//  ClockGen
//----------------------------------
wire clk8M,clk4M,clk2M;
SndClkGen clkgen(clk48M,clk8M,clk4M,clk2M);

wire cpuclkx2 = clk8M;
wire cpu_clk  = clk4M;


//----------------------------------
//  Z80 (1.5625MHz)
//----------------------------------
wire [15:0] cpu_ad;
wire  [7:0] cpu_di, cpu_do;
wire        cpu_mreq, cpu_iorq, cpu_rd, cpu_wr;
wire			cpu_irq,  cpu_nmi;
wire			cpu_irqa, cpu_nmia;

wire cpu_mw, cpu_cs_rom, cpu_cs_ram, cpu_wr_ram, cpu_cs_psg0, cpu_cs_psg1, cpu_cs_com;
SndADec adec(
	cpu_mreq, cpu_wr, cpu_mw,
	cpu_ad, cpu_cs_rom, cpu_cs_ram, cpu_wr_ram, cpu_cs_psg0, cpu_cs_psg1, cpu_cs_com
);

Z80IP cpu(
	.clk(cpu_clk),
	.reset(reset),
	.adr(cpu_ad),
	.data_in(cpu_di),
	.data_out(cpu_do),
	.intreq(cpu_irq),
	.intack(cpu_irqa),
	.nmireq(cpu_nmi),
	.nmiack(cpu_nmia),
	.mx(cpu_mreq),
	.ix(cpu_iorq),
	.rd(cpu_rd),
	.wr(cpu_wr)
);

wire  [7:0]		rom_dt;		// ROM
wire  [7:0]		ram_do;		// RAM
wire  [7:0]		comlatch;	// Sound Command Latch

//DLROM #(13,8) subir( cpuclkx2, cpu_ad[12:0], rom_dt, ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:13]==4'b1_110)); // $1C000-$1DFFF
//snd_rom snd_rom(
//	.clk(cpuclkx2),
//	.addr(cpu_ad[12:0]),
//	.data(rom_dt)
//);
assign snd_rom_addr = cpu_ad[12:0];
assign rom_dt = snd_rom_do;

SRAM_2048 wram( cpuclkx2, cpu_ad[10:0], ram_do, cpu_wr_ram, cpu_do );

dataselector3 scpudisel(
	cpu_di,
	cpu_cs_rom, rom_dt,
	cpu_cs_ram, ram_do,
	cpu_cs_com, comlatch,
	8'hFF
);

SndPlayReq sndreq (
	clk8M, reset,
	sndno, sndstart,
	cpu_irq, cpu_irqa,
	cpu_nmi, cpu_nmia,
	comlatch
);


//----------------------------------
//  PSGs
//----------------------------------
wire [7:0] psg0out, psg1out;

SN76496	psg0(
	clk2M,
	cpu_clk,
	reset,
	cpu_cs_psg0,
	cpu_mw,
	cpu_do,
	4'b1111,
	psg0out
);

SN76496	psg1(
	clk4M,
	cpu_clk,
	reset,
	cpu_cs_psg1,
	cpu_mw,
	cpu_do,
	4'b1111,
	psg1out
);

wire [8:0] psgout = psg0out + psg1out;
assign sndout = { psgout, 6'h0 };

endmodule


module SndClkGen
(
	input			clk48M,
	output reg 	clk8M,
	output		clk4M,
	output		clk2M
);

reg [1:0] count;
always @( posedge clk48M ) begin
	if (count > 2'd2) begin
		count <= count - 2'd2;
      clk8M <= ~clk8M;
   end
   else count <= count + 2'd1;
end

reg [1:0] clkdiv;
always @ ( posedge clk8M ) clkdiv <= clkdiv+1;

assign clk4M = clkdiv[0];
assign clk2M = clkdiv[1];

endmodule


module SndADec
(
	input				cpu_mx,
	input				cpu_wr,

	output			cpu_mw,

	input	 [15:0]	cpu_ad,
	output 			cpu_cs_rom,
	output			cpu_cs_ram,
	output			cpu_wr_ram,
	output			cpu_cs_psg0,
	output			cpu_cs_psg1,
	output			cpu_cs_com
);

assign cpu_mw = cpu_mx & cpu_wr;

assign cpu_cs_rom  = ( cpu_ad[15]    == 1'b0 );
assign cpu_cs_psg0 = ( cpu_ad[15:12] == 4'HA );
assign cpu_cs_psg1 = ( cpu_ad[15:12] == 4'HC );
assign cpu_cs_com  = ( cpu_ad[15:12] == 4'HE );

assign cpu_cs_ram  = ( cpu_ad[15:12] == 4'h8 );
assign cpu_wr_ram  = cpu_cs_ram & cpu_mw;

endmodule


//----------------------------------
//  Play Request & IRQ Generator
//----------------------------------
module SndPlayReq
(
	input			clk8M,
	input			reset,

	input	[7:0]	sndno,
	input			sndstart,

	output reg	cpu_irq,
	input			cpu_irqa,

	output reg	cpu_nmi,
	input			cpu_nmia,

	output reg [7:0] comlatch
);

reg [16:0]	timercnt;
reg			psndstart;

always @( posedge clk8M or posedge reset ) begin
	if ( reset ) begin
		cpu_nmi   <= 0;
		cpu_irq   <= 0;
		comlatch  <= 0;
		timercnt  <= 0;
		psndstart <= 0;
	end
	else begin
		if ( cpu_irqa ) cpu_irq <= 1'b0;
		if ( cpu_nmia ) cpu_nmi <= 1'b0;

		if ( ( psndstart ^ sndstart ) & sndstart ) begin
			comlatch <= sndno;
			cpu_nmi  <= 1'b1;
		end
		psndstart <= sndstart;

		if ( timercnt == 33333 ) cpu_irq <= 1'b1;
		if ( timercnt == 66666 ) cpu_irq <= 1'b1;

		timercnt <= ( timercnt == 66666 ) ? 0 : (timercnt+1);	// 1/60sec
	end
end

endmodule 
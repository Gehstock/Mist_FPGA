// Copyright (c) 2017,19 MiSTer-X

`define EN_SCPU	(ROMAD[17:13]==5'b00_110)	// $0C000-$0DFFF

module SEGASYS1_SOUND
(
	input         clk48M,
	input         reset,

	input   [7:0] sndno,
	input         sndstart,

	output [15:0] sndout,

	output [12:0] snd_rom_addr,
	input   [7:0] snd_rom_do
);


//----------------------------------
//  ClockGen
//----------------------------------
wire clk8M_en,clk4M_en,clk2M_en;
SndClkGen clkgen(clk48M,clk8M_en,clk4M_en,clk2M_en);

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
	.clk(clk48M),
	.clk_en(clk4M_en & cpuwait_n),
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

assign snd_rom_addr = cpu_ad[12:0];
assign rom_dt = snd_rom_do;

//DLROM #(13,8) subir( cpuclkx2, cpu_ad[12:0], rom_dt, ROMCL,ROMAD,ROMDT,ROMEN & `EN_SCPU );
SRAM_2048 wram( clk48M, cpu_ad[10:0], ram_do, cpu_wr_ram, cpu_do );

dataselector3 scpudisel(
	cpu_di,
	cpu_cs_rom, rom_dt,
	cpu_cs_ram, ram_do,
	cpu_cs_com, comlatch,
	8'hFF
);


SndPlayReq sndreq (
	clk48M, clk8M_en, reset,
	sndno, sndstart,
	cpu_irq, cpu_irqa,
	cpu_nmi, cpu_nmia,
	comlatch
);


//----------------------------------
//  PSGs
//----------------------------------
wire [7:0] psg0out, psg1out;
wire       psg0wait, psg1wait;
wire       cpuwait_n = psg0wait & psg1wait;

sn76489_top psg0(
	.clock_i(clk48M),
	.clock_en_i(clk2M_en),
	.res_n_i(~reset),
	.ce_n_i(~(cpu_cs_psg0 & cpu_mreq)),
	.we_n_i(~cpu_wr),
	.d_i(cpu_do),
	.ready_o(psg0wait),
	.aout_o(psg0out)
);

sn76489_top psg1(
	.clock_i(clk48M),
	.clock_en_i(clk4M_en),
	.res_n_i(~reset),
	.ce_n_i(~(cpu_cs_psg1 & cpu_mreq)),
	.we_n_i(~cpu_wr),
	.d_i(cpu_do),
	.ready_o(psg1wait),
	.aout_o(psg1out)
);

wire [8:0] psgout = psg0out + psg1out;
assign sndout = { psgout, 6'h0 };

endmodule


module SndClkGen
(
	input     clk48M,
	output    clk8M_en,
	output    clk4M_en,
	output    clk2M_en
);

reg [4:0] count;
always @( posedge clk48M ) begin
	count <= count + 1'd1;
	if (count == 23) count <= 0;
end

assign clk2M_en = count == 0;
assign clk4M_en = count == 0 || count == 12;
assign clk8M_en = count == 0 || count == 6 || count == 12 || count == 18;

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
	input			clk,
	input     clk8_en,
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

always @( posedge clk or posedge reset ) begin
	if ( reset ) begin
		cpu_nmi   <= 0;
		cpu_irq   <= 0;
		comlatch  <= 0;
		timercnt  <= 0;
		psndstart <= 0;
	end
	else if (clk8_en) begin
		if ( cpu_irqa ) cpu_irq <= 1'b0;
		if ( cpu_nmia ) cpu_nmi <= 1'b0;

		if ( ( psndstart ^ sndstart ) & sndstart ) begin
			comlatch <= sndno;
			cpu_nmi  <= 1'b1;
		end
		psndstart <= sndstart;

		if ( timercnt == 33333 ) cpu_irq <= 1'b1;
		if ( timercnt == 66666 ) cpu_irq <= 1'b1;

		timercnt <= ( timercnt == 66666 ) ? 17'd0 : (timercnt+1'd1);	// 1/60sec
	end
end

endmodule

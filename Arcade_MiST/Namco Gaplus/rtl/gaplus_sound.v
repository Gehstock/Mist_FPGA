/*******************************************
	Sound Module for "FPGA Gaplus"

			Copyright (c) 2007,2019 MiSTer-X
********************************************/
module gaplus_sound
(
	input RESET,

	input CPUCLK,
	input CLK24M,

	input VB,

	input			 com_clk,
	input [10:0] com_adrs,
	input  [7:0] com_wd,
	output [7:0] com_rd,
	input com_we,

	input  pcm_kick,

	output [7:0] SND,
	input  SND_ENABLE
);

wire			wave_c;
wire  [7:0] wave_a;
wire  [7:0] wave_d;
wave wave(
	.clk(wave_c),
	.addr(wave_a),
	.data(wave_d)
);
wire [12:0]	sndrom_a;
wire	[7:0]	sndrom_d;
sound sound (
	.clk(CPUCLK),
	.addr(sndrom_a),
	.data(sndrom_d)
);
wire	[15:0]	SNDCPU_ADRS;
wire				SNDCPU_VMA;
wire				SNDCPU_RW;

wire 				SNDCPU_WE  = ( ~SNDCPU_RW );
wire				SNDCPU_RE  = (  SNDCPU_RW );

assign			sndrom_a   = SNDCPU_ADRS[12:0];
wire	[7:0]		sndram_d;

wire				sndreg_cs = ( ( SNDCPU_ADRS[15:6]  == 10'b0000000000 ) & SNDCPU_VMA );			// $0000-$003F
wire				sndram_cs = ( ( SNDCPU_ADRS[15:13] == 3'b000 ) & (~sndreg_cs) & SNDCPU_VMA );	// $0000-$1FFF ($400 image)
wire				sndrom_cs = ( ( SNDCPU_ADRS[15:14] == 2'b11  ) & SNDCPU_VMA );						// $C000-$FFFF
wire				sndirq_cs = ( ( SNDCPU_ADRS[15:14] == 2'b01  ) & SNDCPU_VMA );						// $4000

wire				SNDCPU_RESET  = RESET;

reg				SNDCPU_IRQEN;
wire				SNDCPU_IRQ    = VB & ( ~SNDCPU_IRQEN );

wire				SNDCPU_IRQWE  = ( sndirq_cs & SNDCPU_WE );

always @( negedge CPUCLK or posedge RESET ) begin
	if ( RESET ) begin
		SNDCPU_IRQEN <= 1'b1;
	end
	else begin
		if ( SNDCPU_IRQWE ) SNDCPU_IRQEN <= SNDCPU_ADRS[13];
	end
end

wire	[7:0]		SNDCPU_DO;
wire	[7:0]		SNDCPU_DI;

dataselector2	sndcpu_disel( SNDCPU_DI, sndram_cs, sndram_d, sndrom_cs, sndrom_d, 8'hFF );

cpu6809 sndcpu (
	.clkx2(CPUCLK),
	.rst(SNDCPU_RESET),
	.rw(SNDCPU_RW),
	.vma(SNDCPU_VMA),
	.address(SNDCPU_ADRS),
	.data_in(SNDCPU_DI),
	.data_out(SNDCPU_DO),
	.halt(1'b0),
	.hold(1'b0),
	.irq(SNDCPU_IRQ),
	.firq(1'b0),
	.nmi(1'b0)
);

dpram2#(11,8)sndram(
	.address_a(com_adrs),
	.address_b(SNDCPU_ADRS[10:0]),
	.clock_a(com_clk),
	.clock_b(CPUCLK),
	.data_a(com_wd),
	.data_b(SNDCPU_DO),
	.wren_a(com_we),
	.wren_b(sndram_cs & SNDCPU_WE),
	.q_a(com_rd),
	.q_b(sndram_d)
	);


wire			pcmclk;
wire [7:0]	pcmdat;
pcmplayer   pcmplay( pcmclk, RESET, pcm_kick, pcmdat);


WSG_8CH_AUX wsg (
	CLK24M,
	RESET,
	SNDCPU_ADRS[5:0], SNDCPU_DO, sndreg_cs & SNDCPU_WE,
	wave_c, wave_a, wave_d,
	pcmclk, pcmdat,
	SND_ENABLE,
	SND
);


endmodule


module pcmplayer
(
	input pcm_clk,
	input RESET,
	input pcm_kick,

	output reg [7:0] sepcm
);

reg			sekick;
reg [15:0]	seadrs;

wire [7:0] pcm_data;
//DLROM #(15,8) pcm( pcm_clk, seadrs, pcm_data, ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[17:15]==3'b01_1) );
//pcm pcm (
//	.clk(pcm_clk),
//	.addr(seadrs),
//	.data(pcm_data)
//);
always @ ( posedge pcm_clk or posedge RESET ) begin

	if ( RESET ) begin
		sekick <= 0;
		sepcm  <= 0;
	end
	else begin
		if ( sekick ) begin
			if ( seadrs >= 16'h8000 ) begin
				sekick <= 0;
			end
			else begin
				sepcm  <= { 1'b0, pcm_data[7:1] };
				seadrs <= seadrs + 1;
			end
		end else begin
			sekick <= pcm_kick;
			seadrs <= 0;
		end
	end

end

endmodule 
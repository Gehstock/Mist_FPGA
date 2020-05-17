// Copyright (c) 2017,19 MiSTer-X

module System1_Main
(
	input				CLK48M,
	input				CLK3M,

	input				RESET,
	input				crypt,
	input   [7:0]	INP0,
	input   [7:0]	INP1,
	input   [7:0]	INP2,

	input   [7:0]	DSW0,
	input   [7:0]	DSW1,

	input				VBLK,
	input				VIDCS,
	input   [7:0]	VIDDO,

	output			CPUCLn,
	output [15:0]	CPUAD,
	output  [7:0]	CPUDO,
	output		  	CPUWR,
	
	output			SNDRQ,
	output [15:0]	cpu_rom_addr,
	input   [7:0]	cpu_rom_do
);

wire			AXSCL   = CLK48M;
wire			CPUCL   = CLK3M;
assign 		CPUCLn  = ~CPUCL;

wire  [7:0]	CPUDI;
wire			CPURD;

wire			cpu_cs_video;
wire  [7:0]	cpu_rd_video;

wire	cpu_m1;
wire	cpu_mreq, cpu_iorq;
wire	_cpu_rd, _cpu_wr;

Z80IP maincpu(
	.reset(RESET),
	.clk(CPUCL),
	.adr(CPUAD),
	.data_in(CPUDI),
	.data_out(CPUDO),
	.m1(cpu_m1),
	.mx(cpu_mreq),
	.ix(cpu_iorq),
	.rd(_cpu_rd),
	.wr(_cpu_wr),
	.intreq(VBLK),
	.nmireq(1'b0)
);

assign		CPUWR = _cpu_wr & cpu_mreq;
assign		CPURD = _cpu_rd & cpu_mreq;

assign		SNDRQ = (CPUAD[4:0] == 5'b1_1000) & cpu_iorq & _cpu_wr;

wire			cpu_cs_port1 =  (CPUAD[4:2] == 3'b0_00) & cpu_iorq;
wire			cpu_cs_port2 =  (CPUAD[4:2] == 3'b0_01) & cpu_iorq;
wire			cpu_cs_portS =  (CPUAD[4:2] == 3'b0_10) & cpu_iorq;
wire			cpu_cs_portA =  (CPUAD[4:2] == 3'b0_11) & ~CPUAD[0] & cpu_iorq;
wire			cpu_cs_portB =(((CPUAD[4:2] == 3'b0_11) &  CPUAD[0]) | (CPUAD[4:0] == 5'b1_0000)) & cpu_iorq;
wire			cpu_cs_portI =  (CPUAD[4:2] == 3'b1_10) & cpu_iorq;

wire [7:0]	cpu_rd_port1 = INP0; 
wire [7:0]	cpu_rd_port2 = INP1; 
wire [7:0]	cpu_rd_portS = INP2; 

wire [7:0]	cpu_rd_portA = DSW0;
wire [7:0]	cpu_rd_portB = DSW1;

wire [7:0]	cpu_rd_mrom;
wire			cpu_cs_mrom = (CPUAD[15:12] < 4'b1100);
PRGROM prom(AXSCL, cpu_m1, CPUAD[14:0], cpu_rd_mrom, cpu_rom_addr,cpu_rom_do );

wire [7:0]	cpu_rd_mram;
wire			cpu_cs_mram = (CPUAD[15:12] == 4'b1100);
SRAM_4096 mainram(CPUCLn, CPUAD[11:0], cpu_rd_mram, cpu_cs_mram & CPUWR, CPUDO );

reg [7:0] vidmode;
always @(posedge CPUCLn) begin
	if ((CPUAD[4:0] == 5'b1_1001) & cpu_iorq & _cpu_wr) begin
		vidmode <= CPUDO;
	end
end

dataselector8 mcpudisel(
	CPUDI,
	VIDCS, VIDDO,
	cpu_cs_port1, cpu_rd_port1,
	cpu_cs_port2, cpu_rd_port2,
	cpu_cs_portS, cpu_rd_portS,
	cpu_cs_portA, cpu_rd_portA,
	cpu_cs_portB, cpu_rd_portB,
	cpu_cs_mram,  cpu_rd_mram,
	cpu_cs_mrom,  (crypt == 1'b1) ? cpu_rd_mrom : cpu_rom_do,
	8'hFF
);

endmodule


//----------------------------------
//  Program ROM with Decryptor 
//----------------------------------
module PRGROM
(
	input 				clk,

	input					mrom_m1,
	input     [14:0]	mrom_ad,
	output reg [7:0]	mrom_dt,
	output 	[14:0]	cpu_rom_addr,
	input   	 [7:0]	cpu_rom_do
);

reg  [15:0] madr;
wire  [7:0] mdat;

wire			f		  = mdat[7];
wire  [7:0] xorv    = { f, 1'b0, f, 1'b0, f, 3'b000 }; 
wire  [7:0] andv    = ~(8'hA8);
wire  [1:0] decidx0 = { mdat[5],  mdat[3] } ^ { f, f };
wire  [6:0] decidx  = { madr[12], madr[8], madr[4], madr[0], ~madr[15], decidx0 };
wire  [7:0] dectbl;
wire  [7:0] mdec    = ( mdat & andv ) | ( dectbl ^ xorv );

//DLROM #( 7,8) decrom( clk, decidx,   dectbl, ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16: 7]==10'b1_1110_0001_0) );	// $1E100-$1E17F
dec_rom dec_rom(//only 32k are encrypted  todo
	.clk(clk),
	.addr(decidx),
	.data(dectbl)
);

//DLROM #(15,8) mainir( clk, madr[14:0], mdat, ROMCL,ROMAD,ROMDT,ROMEN & (ROMAD[16:15]==2'b0_0) );				// $00000-$07FFF
//prg_rom pgr_rom(
//	.clk(clk),
//	.addr(madr[14:0]),
//	.data(mdat)
//);
assign cpu_rom_addr = madr[15:0];
assign mdat = cpu_rom_do;

reg phase = 1'b0;
always @( negedge clk ) begin
	if ( phase ) mrom_dt <= mdec;
	else madr <= { mrom_m1, mrom_ad };
	phase <= ~phase;
end

endmodule

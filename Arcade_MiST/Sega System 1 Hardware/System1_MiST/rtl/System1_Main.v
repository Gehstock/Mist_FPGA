// Copyright (c) 2017,19 MiSTer-X

`define EN_MCPU0		(dl_addr[17:15]==3'b00_0 ) //todo
`define EN_MCPU8		(dl_addr[17:14]==4'b00_10)  //todo

module System1_Main
(
	input				CLK48M,

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
	output reg [7:0] VIDMD,
	output			CPUCLn,
	output [15:0]	CPUAD,
	output  [7:0]	CPUDO,
	output		  	CPUWR,
	
	output reg		SNDRQ,
	output reg [7:0] SNDNO,
	output [15:0]	cpu_rom_addr,
	input   [7:0]	cpu_rom_do,
	input   [17:0] dl_addr,
	input	  [7:0]	dl_data,
	input				dl_wr,
	input				dl_clk
);

reg [3:0] clkdiv;
always @(posedge CLK48M) clkdiv <= clkdiv+1;
wire CLK3M = clkdiv[3];

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

// Input Port
wire			cpu_cs_port;
wire [7:0]	cpu_rd_port;
SEGASYS1_IPORT port(CPUAD,cpu_iorq, INP0,INP1,INP2, DSW0,DSW1, cpu_cs_port,cpu_rd_port);

wire			cpu_cs_mrom0 = (CPUAD[15]    == 1'b0 ) & cpu_mreq;
wire			cpu_cs_mrom1 = (CPUAD[15:14] == 2'b10) & cpu_mreq;
wire [7:0]	cpu_rd_mrom0;
wire [7:0]	cpu_rd_mrom1;
wire [14:0] rad;
wire  [7:0] rdt;
System1_Decoder decr(AXSCL,cpu_m1,CPUAD,cpu_rd_mrom0, cpu_rom_addr,cpu_rom_do,dl_addr,dl_data,dl_wr,dl_clk );
//PRGROM prom(AXSCL, cpu_m1, CPUAD[14:0], cpu_rd_mrom, cpu_rom_addr[14:0],cpu_rom_do,dl_addr,dl_data,dl_wr,dl_clk );
//DLROM #(15,8) rom0(AXSCL,   rad,         rdt, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU0);	// ($0000-$7FFF encrypted)
//DLROM #(14,8) rom1(CPUCLn,CPUAD,cpu_rd_mrom1, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU8);	// ($8000-$BFFF non-encrypted)

wire rom2_we = (dl_addr >=  16'h8000) & (dl_addr <  16'hC000);
dpram#(8,14)rom2(
	.clk_a(CPUCLn),
	.addr_a(CPUAD),
	.q_a(cpu_rd_mrom1),
	.clk_b(dl_clk),
	.addr_b(dl_addr[7:0]),
	.we_b(rom2_we & dl_wr),
	.d_b(dl_data)
	);
	
// Work RAM
wire [7:0]	cpu_rd_mram;
wire			cpu_cs_mram = (CPUAD[15:12] == 4'b1100) & cpu_mreq;
SRAM_4096 mainram(CPUCLn, CPUAD[11:0], cpu_rd_mram, cpu_cs_mram & CPUWR, CPUDO );

// Video mode latch & Sound Request
wire cpu_cs_sreq = ((CPUAD[7:0] == 8'h14)|(CPUAD[7:0] == 8'h18)) & cpu_iorq;
wire cpu_cs_vidm = ((CPUAD[7:0] == 8'h15)|(CPUAD[7:0] == 8'h19)) & cpu_iorq;

wire cpu_wr_sreq = cpu_cs_sreq & _cpu_wr;
wire cpu_wr_vidm = cpu_cs_vidm & _cpu_wr;

always @(posedge CPUCLn or posedge RESET) begin
	if (RESET) begin
		VIDMD <= 0;
		SNDRQ <= 0;
		SNDNO <= 0;
	end
	else begin
		if (cpu_wr_vidm) VIDMD <= CPUDO;
		if (cpu_wr_sreq) begin SNDNO <= CPUDO; SNDRQ <= 1'b1; end else SNDRQ <= 1'b0;
	end
end

// CPU data selector
dataselector6 mcpudisel(
	CPUDI,
	VIDCS,		  VIDDO,
	cpu_cs_vidm,  VIDMD,
	cpu_cs_port,  cpu_rd_port,
	cpu_cs_mram,  cpu_rd_mram,
	cpu_cs_mrom0, (crypt == 1'b1) ? cpu_rd_mrom0 : cpu_rom_do,
	cpu_cs_mrom1, cpu_rd_mrom1,
	8'hFF
);

endmodule

module SEGASYS1_IPORT
(
	input [15:0]	CPUAD,
	input				CPUIO,

	input  [7:0]	INP0,
	input  [7:0]	INP1,
	input  [7:0]	INP2,

	input  [7:0]	DSW0,
	input  [7:0]	DSW1,

	output			DV,
	output [7:0]	OD
);

wire cs_port1 =  (CPUAD[4:2] == 3'b0_00) & CPUIO;
wire cs_port2 =  (CPUAD[4:2] == 3'b0_01) & CPUIO;
wire cs_portS =  (CPUAD[4:2] == 3'b0_10) & CPUIO;
wire cs_portA =  (CPUAD[4:2] == 3'b0_11) & ~CPUAD[0] & CPUIO;
wire cs_portB =(((CPUAD[4:2] == 3'b0_11) &  CPUAD[0]) | (CPUAD[4:2] == 3'b1_00)) & CPUIO;

wire [7:0] inp;
dataselector5 dsel(
	inp,
	cs_port1,INP0,
	cs_port2,INP1,
	cs_portS,INP2,
	cs_portA,DSW0,
	cs_portB,DSW1,
	8'hFF
);

assign DV = cs_port1|cs_port2|cs_portS|cs_portA|cs_portB;
assign OD = inp;

endmodule 
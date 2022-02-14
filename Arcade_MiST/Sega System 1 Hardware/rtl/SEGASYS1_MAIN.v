// Copyright (c) 2017,19 MiSTer-X

`define EN_MCPU0_PRG (ROMAD[18:15]==4'b000_1)   // $08000-$0ffff
`define EN_MCPU8_PRG (ROMAD[18:16]==3'b001)     // $10000-$1ffff
`define EN_KEY       (ROMAD[18:13]==6'b110_001) // $62000-$63fff

module SEGASYS1_MAIN
(
	input				CLK40M,

	input				RESET,

	input   [7:0]	INP0,
	input   [7:0]	INP1,
	input   [7:0]	INP2,

	input   [7:0]	DSW0,
	input   [7:0]	DSW1,
	input           SYSTEM2,

	input				VBLK,
	input				VIDCS,
	input   [7:0]	VIDDO,

	output [15:0]	CPUAD,
	output  [7:0]	CPUDO,
	output		  	CPUWR,
	
	output reg		  SNDRQ,
	output reg [7:0] SNDNO,
	
	output reg [7:0] VIDMD,
	output reg [7:0] SNDCTL,

	output [16:0] cpu_rom_addr,
	input   [7:0] cpu_rom_do,

	input				ROMCL,		// Downloaded ROM image
	input   [24:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

reg [4:0] clkdiv;
reg       CLK4M_EN;
always @(posedge CLK40M) begin
	clkdiv <= clkdiv+1'd1;
	CLK4M_EN <= 0;
	if (clkdiv == 9) begin
		clkdiv <= 0;
		CLK4M_EN <= 1;
	end
end
wire      CPUCL_EN = CLK4M_EN;

wire  [7:0]	CPUDI;
//wire			CPURD;

wire	cpu_m1;
wire	cpu_mreq, cpu_iorq;
wire	_cpu_rd, _cpu_wr;

Z80IP maincpu(
	.reset(RESET),
	.clk(CLK40M),
	.clk_en(CPUCL_EN),
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

assign CPUWR = _cpu_wr & cpu_mreq;
//assign CPURD = _cpu_rd & cpu_mreq;


// Input Port
wire			cpu_cs_port;
wire [7:0]	cpu_rd_port;
SEGASYS1_IPORT port(CPUAD,cpu_iorq, INP0,INP1,INP2, DSW0,DSW1, cpu_cs_port,cpu_rd_port);


// Program ROM
wire        cpu_cs_mrom0 = (CPUAD[15]    == 1'b0 ) & cpu_mreq;
wire        cpu_cs_mrom8 = (CPUAD[15:14] == 2'b10) & cpu_mreq;

wire  [7:0] cpu_rd_mrom0_prg;
wire  [7:0] cpu_rd_mrom8;
wire  [7:0] cpu_rd_mc8123;
wire [14:0] rad;
wire  [7:0] rdt;
wire [12:0] key_a;
wire  [7:0] key_d;

assign cpu_rom_addr = CPUAD[15] ? {3'd2 + cpu_bank, CPUAD[13:0]} : {1'b0, has_mc8123_key ? CPUAD[14:0] : rad};
assign rdt = cpu_rom_do;
assign cpu_rd_mrom8 = cpu_rom_do;

// CPU Region $0000-$7fff ROM
//DLROM #(15,8) rom0_prg(CLK40M, has_mc8123_key ? CPUAD : rad, rdt, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU0_PRG);

// CPU Region $8000-$bfff, 4 ROM banks
// No BRAM for separate opcode memory banks, they may be not needed though
wire [1:0] cpu_bank = {SYSTEM2 ? VIDMD[3] : VIDMD[6], VIDMD[2]};
//DLROM #(16,8) rom8_prg(CLK40M, {cpu_bank,CPUAD[13:0]}, cpu_rd_mrom8, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU8_PRG);

// 315-5xxx CPU decryption for selected SEGA System 1 titles
SEGASYS1_PRGDEC decr(CLK40M,cpu_m1,CPUAD,cpu_rd_mrom0_prg, rad,rdt, ROMCL,ROMAD,ROMDT,ROMEN);

// MC-8123 CPU decryption for selected SEGA System 2 titles
MC8123_rom_decrypt mc8123_decrypt(CLK40M, cpu_m1, CPUAD, cpu_rd_mc8123,
                                 !CPUAD[15] ? rdt : cpu_rd_mrom8, key_a, key_d);
DLROM #(13,8) rom_keys(CLK40M, key_a, key_d,
                       ROMCL, ROMAD, ROMDT, ROMEN & `EN_KEY);

// Detect if we have mc8123 keys or opcode roms
//reg has_opcode_roms = 0;
reg has_mc8123_key = 0;
always @(posedge CLK40M) begin
	if (ROMEN & `EN_KEY)
		has_mc8123_key <= has_mc8123_key | ~(!ROMDT);
end

// Work RAM
wire  [7:0] cpu_rd_mram;
wire        cpu_cs_mram = (CPUAD[15:12] == 4'b1100) & cpu_mreq;
SRAM_4096 mainram(CLK40M, CPUAD[11:0], cpu_rd_mram, cpu_cs_mram & CPUWR, CPUDO );


// Video mode latch & Sound Request
wire cpu_cs_sreq = ((CPUAD[7:0] == 8'h14)|(CPUAD[7:0] == 8'h18)) & cpu_iorq;
wire cpu_cs_vidm = ((CPUAD[7:0] == 8'h15)|(CPUAD[7:0] == 8'h19)) & cpu_iorq;
wire cpu_cs_sctl = (CPUAD[7:0] == 8'h16) & cpu_iorq;

wire cpu_wr_sreq = cpu_cs_sreq & _cpu_wr;
wire cpu_wr_vidm = cpu_cs_vidm & _cpu_wr;
wire cpu_wr_sctl = cpu_cs_sctl & _cpu_wr;

always @(posedge CLK40M or posedge RESET) begin
	if (RESET) begin
		VIDMD <= 0;
		SNDRQ <= 0;
		SNDNO <= 0;
		SNDCTL <= 0;
	end
	else begin
		if (cpu_wr_vidm) VIDMD <= CPUDO;
		if (cpu_wr_sctl) SNDCTL <= CPUDO;
		if (cpu_wr_sreq) begin SNDNO <= CPUDO; SNDRQ <= 1'b1; end else SNDRQ <= 1'b0;
	end
end


// CPU data selector
assign CPUDI = (VIDCS & cpu_mreq) ? VIDDO :
	           cpu_cs_vidm        ? VIDMD :
	           cpu_cs_sctl        ? SNDCTL :
	           cpu_cs_port        ? cpu_rd_port :
	           cpu_cs_mram        ? cpu_rd_mram :
	           cpu_cs_mrom0       ? (has_mc8123_key ? cpu_rd_mc8123 : cpu_rd_mrom0_prg) :
	           cpu_cs_mrom8       ? (has_mc8123_key ? cpu_rd_mc8123 : cpu_rd_mrom8) : 8'hFF;

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

assign inp = cs_port1 ? INP0 :
             cs_port2 ? INP1 :
             cs_portS ? INP2 :
             cs_portA ? DSW0 :
             cs_portB ? DSW1 : 8'hFF;

assign DV = cs_port1|cs_port2|cs_portS|cs_portA|cs_portB;
assign OD = inp;

endmodule


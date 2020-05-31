/************************************************************************
  "FPGA Penguin-Kun Wars" - Penguin-Kun Wars board compatible circuit

													  Copyright (c) 2012,20 MiSTer-X
*************************************************************************/
module FPGA_PKWARS
(
	input				clk48M,
	input				RESET,
	
	input				EXCITE,	// Excite Mode (Double the CPU clock)
	
	input  [7:0]	CTR1,
	input	 [7:0]	CTR2,
	input	 [7:0]	DSW,

	input  [8:0]	PH,
	input  [8:0]	PV,
	
	output			PCLK,
	output [11:0]	POUT,

	output [15:0]	SND,
	
	output [15:0]	cpu_rom_addr,
	input  [7:0]	cpu_rom_do,
	output [13:0]	gfx_rom_addr,
	input  [31:0]	gfx_rom_do
);

wire VBLK = (PV == 9'd194);

wire VCLKx4, VCLK;
wire VRAMCL, CLK24M, CLK12M, CLK6M, CLK3M;
PKWARS_CLKGEN clkgen
(
	clk48M,
	VCLKx4, VCLK,
	VRAMCL, PCLK,
	CLK24M, CLK12M, CLK6M, CLK3M
);


wire [13:0] BGCAD, SPCAD;
wire [31:0] BGCDT, SPCDT;
//wire  [4:0] PALAD;
//ire  [7:0]	PALDT;
wire [15:0] CPUAD;

wire	[1:0] PHASE;

PKWARS_ROMS roms
(
	clk48M, VCLKx4, VCLK, PHASE,
	BGCAD, BGCDT,
	SPCAD, SPCDT,
	gfx_rom_addr,gfx_rom_do
);
wire SPCFT   = (PHASE==0)|(PHASE==2);
wire CPUCLx2 = EXCITE ? CLK12M : CLK6M;

wire  [9:0] BGVAD;
wire [15:0] BGVDT;
wire [10:0] SPAAD;
wire  [7:0] SPADT;

PKWARS_VIDEO video
(
	RESET, VCLKx4, VCLK, 
	PH, PV, POUT,
	BGVAD, BGVDT, BGCAD, BGCDT,
	SPAAD, SPADT, SPCAD, SPCDT, SPCFT
);

reg CPUCL;
always @( posedge CPUCLx2 ) CPUCL <= ~CPUCL;

wire [7:0]  CPUID, CPUOD;
wire			CPURD, CPUWR;

reg  CPUIRQ, pVBLK;
wire eVBLK = (VBLK^pVBLK) & VBLK;
wire IRQFETCH = (CPURD&(CPUAD==16'h38))|RESET;
always @( posedge CPUCL ) begin
	pVBLK <= VBLK;
	if (IRQFETCH) CPUIRQ <= 0;
	else begin
		if (eVBLK) CPUIRQ <= 1;
	end
end

Z80IP cpu( RESET, CPUCL, CPUAD, CPUID, CPUOD, CPURD, CPUWR, CPUIRQ );

wire 			RAMDV, SNDDV, VIDDV;
wire [7:0]	RAMDT, SNDDT, VIDDT;

wire CPRDV = (~CPUAD[15])|(CPUAD[15:13]==3'b111);
assign cpu_rom_addr = CPUAD;


DSEL4D_8B cpudsel(
	CPUID,
	CPRDV, cpu_rom_do,
	RAMDV, RAMDT,
	VIDDV, VIDDT,
	SNDDV, SNDDT
);

PKWARS_WRAM wram( CPUCLx2, CPUAD, CPUOD, CPUWR, CPURD, RAMDT, RAMDV );
PKWARS_VRAM vram( CPUCLx2, CPUAD, CPUOD, CPUWR, CPURD, VIDDT, VIDDV, VRAMCL, SPAAD, SPADT, BGVAD, BGVDT, eVBLK );


PKWARS_SND snd( CPUCLx2, CPUAD, CPUOD, CPUWR, CPURD, SNDDT, SNDDV, RESET, CLK3M, CTR1, CTR2, DSW, VBLK, SND );


endmodule


module PKWARS_WRAM
(
	input			 		CPUCL,
	input [15:0] 		CPUAD,
	input  [7:0] 		CPUOD,
	input        		CPUWR,
	input        		CPURD,
	output reg [7:0]	RAMDT,
	output		 		RAMDV
);

wire DV = (CPUAD[15:12]==4'hC);

wire [10:0] AD = CPUAD[10:0];
reg   [7:0] ramcore[0:2047];

always @( posedge CPUCL ) begin
	if (DV) begin
		if (CPUWR) ramcore[AD] <= CPUOD;
		RAMDT <= ramcore[AD];
	end
end

assign RAMDV = DV & CPURD;

endmodule


module PKWARS_VRAM
(
	input					CPUCL,
	input  [15:0]		CPUAD,
	input	  [7:0]		CPUOD,
	input					CPUWR,
	input					CPURD,

	output  [7:0]		VIDDT,
	output				VIDDV,
	
	input					VIDCL,

	input  [10:0]		SPAAD,
	output  [7:0]		SPADT,
	
	input   [9:0]		BGVAD,
	output [15:0]		BGVDT,
	
	input					eVBLK
);

wire VRDV = (CPUAD[15:12]==4'h8);
wire SPDV = VRDV & (~CPUAD[11]);
wire BGDV = VRDV &   CPUAD[11];

wire [7:0] SPDT, BGDT, dum;

VDPRAM400x2 bgvram(
	CPUCL, CPUAD[10:0], BGDV & CPUWR, CPUOD, BGDT,
	VIDCL, BGVAD, BGVDT
);

wire DMACL = CPUCL;
reg  [1:0] DMAPH = 0;
reg [10:0] DMAAD = 0;
reg		  DMAWR = 0;
wire [7:0] DMADT;
always @(posedge DMACL) begin
	case (DMAPH)
	0: begin DMAWR <= 0; DMAAD <= 0; DMAPH <= eVBLK ? (DMAPH+1) : DMAPH; end
	1: begin DMAWR <= 1; DMAPH <= DMAPH+1; end
	2: begin DMAWR <= 0; DMAAD <= DMAAD+1; DMAPH <= (DMAAD==11'h7FF) ? (DMAPH+1) : (DMAPH-1); end
	3: if (~eVBLK) begin DMAWR <= 0; DMAPH <= DMAPH+1; end 
	default: ;
	endcase
end

DPRAM800 sparam0(
	CPUCL, CPUAD[10:0], SPDV & CPUWR, CPUOD, SPDT,
  ~DMACL, DMAAD, 1'b0, 8'h0, DMADT
);
	
DPRAM800 sparam(
  ~DMACL, DMAAD, DMAWR, DMADT, dum,
	VIDCL, SPAAD, 1'b0, 8'h0, SPADT
);

assign VIDDT = BGDV ? BGDT : SPDT;
assign VIDDV = (SPDV|BGDV) & CPURD; 

endmodule


module DSEL4D_8B
(
	output [7:0] out,

	input			 en0,
	input	 [7:0] dt0,
	input			 en1,
	input	 [7:0] dt1,
	input			 en2,
	input	 [7:0] dt2,
	input			 en3,
	input	 [7:0] dt3
);

assign out = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 en3 ? dt3 :
				 8'h00;

endmodule



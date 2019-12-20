/******************************************************
	FPGA Implimentation of "Green Beret" (Main Part)
*******************************************************/
// Copyright (c) 2013,19 MiSTer-X

module MAIN
(
	input				MCLK,
	input				CLKEN,
	input				RESET,

	input   [8:0]	PH,
	input   [8:0]	PV,

	input   [5:0]	INP0,
	input   [5:0]	INP1,
	input   [2:0]	INP2,

	input	  [7:0]	DSW0,
	input	  [7:0]	DSW1,
	input	  [7:0]	DSW2,

	output			CPUMX,
	output [15:0]	CPUAD,
	output			CPUWR,
	output  [7:0]	CPUWD,

	input				VIDDV,
	input   [7:0]	VIDRD,

	output [15:0] ROMA,
	input   [7:0] ROMDT,

	input				DLCL,
	input  [17:0]  DLAD,
	input   [7:0]	DLDT,
	input				DLEN
);

//
// Z80 SoftCore
//
wire [7:0] CPUID;
wire cpu_irq, cpu_nmi;
wire iCPUMX,iCPUWR;

T80se z80(
	.CLK_n(MCLK),
	.CLKEN(CLKEN),
	.RESET_n(~RESET),
	.A(CPUAD),
	.DI(CPUID),
	.DO(CPUWD),
	.INT_n(~cpu_irq),
	.NMI_n(~cpu_nmi),
	.MREQ_n(iCPUMX),
	.WR_n(iCPUWR),
	.BUSRQ_n(1'b1),
	.WAIT_n(1'b1)
);

assign CPUMX = ~iCPUMX;
assign CPUWR = ~iCPUWR;


//
// Instruction ROMs (Banked)
//
wire [2:0] ROMBK;
//wire [7:0] ROMDT;
wire 		  ROMDV;

wire [14:0] AD1 = (CPUAD[15:11] == 5'b11111) ? {1'b1,ROMBK,CPUAD[10:0]} : {1'b0,CPUAD[13:0]};

//wire  [7:0] DT0, DT1;
//DLROM #(15,8) r0(CL,AD[14:0],DT0, DLCL,DLAD,DLDT,DLEN & (DLAD[17:15]==3'b00_0));
//DLROM #(15,8) r1(CL,     AD1,DT1, DLCL,DLAD,DLDT,DLEN & (DLAD[17:15]==3'b00_1));
//assign ROMDT = CPUAD[15] ? DT1 : DT0;

assign ROMDV = ((CPUAD[15:11] == 5'b11111)|(CPUAD[15:14] != 2'b11)) & CPUMX;
assign ROMA = CPUAD[15] ? {1'b1, AD1} : {1'b0, CPUAD[14:0]};
//
//
// Input Ports (HID & DIPSWs)
//
wire CS_ISYS = (CPUAD[15:0] == 16'hF603) & CPUMX;
wire CS_IP01 = (CPUAD[15:0] == 16'hF602) & CPUMX;
wire CS_IP02 = (CPUAD[15:0] == 16'hF601) & CPUMX;
wire CS_DSW2 = (CPUAD[15:0] == 16'hF600) & CPUMX;
wire CS_DSW0 = (CPUAD[15:8] ==  8'hF2  ) & CPUMX;
wire CS_DSW1 = (CPUAD[15:8] ==  8'hF4  ) & CPUMX;

`include "HIDDEF.i"
wire [7:0]	ISYS = ~{`none,`none,`none,`P2ST,`P1ST,`none,`none,`COIN};
wire [7:0]	IP01 = ~{`none,`none,`P1TB,`P1TA,`P1DW,`P1UP,`P1RG,`P1LF};
wire [7:0]	IP02 = ~{`none,`none,`P2TB,`P2TA,`P2DW,`P2UP,`P2RG,`P2LF};

//
// CPU Input Data Selector
//
DSEL9 dsel(
	CPUID,
	VIDDV,VIDRD,
	ROMDV,ROMDT,
	CS_ISYS,ISYS, 
	CS_IP01,IP01,
	CS_IP02,IP02,
	CS_DSW0,DSW0,
	CS_DSW1,DSW1,
	CS_DSW2,DSW2
);


//
// Interrupt Generator & ROM Bank Selector
//
IRQGEN irqg(
	RESET,PH,PV,
	MCLK,CLKEN,CPUAD,CPUWD,CPUMX & CPUWR,
	cpu_irq,cpu_nmi,
	ROMBK
);


endmodule


module IRQGEN
(
	input 			RESET,
	input	 [8:0]	PH,
	input	 [8:0]	PV,

	input				MCLK,
	input				CLKEN,
	input [15:0]	CPUAD,
	input  [7:0]	CPUWD,
	input				CPUWE,

	output reg		cpu_irq,
	output reg		cpu_nmi,

	output reg [2:0] ROMBK
);
	

wire CS_FSCW = (CPUAD[15:0] == 16'hE044) & CPUWE;
wire CS_CCTW = (CPUAD[15:0] == 16'hF000) & CPUWE;

reg  [2:0] irqmask;
reg  [8:0] tick;
wire [8:0] irqs = (~tick) & (tick+9'd1);
reg  [8:0] pPV;
reg		  sync;

always @( posedge MCLK ) begin
	if (RESET) begin
		ROMBK   <= 0;
		irqmask <= 0;
		cpu_nmi <= 0;
		cpu_irq <= 0;
		tick    <= 0;
		pPV     <= 1;
		sync    <= 1;
	end
	else if (CLKEN) begin
		if ( CS_CCTW ) ROMBK <= CPUWD[7:5];
		if ( CS_FSCW ) begin
			irqmask <= CPUWD[2:0];
			if (~CPUWD[0]) cpu_nmi <= 0;
			if (~CPUWD[1]) cpu_irq <= 0;
			else if (~CPUWD[2]) cpu_irq <= 0;
		end
		else if (pPV != PV) begin
			if (PV[3:0]==0) begin
				if (sync & (PV==9'd0)) begin tick <= 9'd0; sync <= 0; end
				else tick <= (tick+9'd1);
				cpu_nmi <= irqs[0] & irqmask[0];
				cpu_irq <=(irqs[3] & irqmask[1]) | (irqs[4] & irqmask[2]);
				pPV <= PV;
			end
		end
	end
end

endmodule


module DSEL9
(
	output [7:0] out,
	input en0, input [7:0] in0,
	input en1, input [7:0] in1,
	input en2, input [7:0] in2,
	input en3, input [7:0] in3,
	input en4, input [7:0] in4,
	input en5, input [7:0] in5,
	input en6, input [7:0] in6,
	input en7, input [7:0] in7,
	input en8, input [7:0] in8
);

assign out = en0 ? in0 :
				 en1 ? in1 :
				 en2 ? in2 :
				 en3 ? in3 :
				 en4 ? in4 :
				 en5 ? in5 :
				 en6 ? in6 :
				 en7 ? in7 :
				 en8 ? in8 :
				 8'h00;

endmodule


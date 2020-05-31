// Copyright (c) 2012 MiSTer-X 

module PKWARS_SND
(
	input				CPUCL,
	input [15:0]	CPUAD,
	input  [7:0]	CPUOD,
	input				CPUWR,
	input				CPURD,
	output [7:0]	SNDDT,
	output			SNDDV,

	input				RESET,
	input				CLK3M,
	input  [7:0]	CTR1,
	input	 [7:0]	CTR2,
	input	 [7:0]	DSW,
	input				VBLK,

	output [15:0]	SNDOUT
);

wire      DV = (CPUAD[15:12]==4'hA);
assign SNDDV = CPURD & DV;

reg PSGCL;
always @( posedge CLK3M ) PSGCL <= ~PSGCL;

wire [7:0] IN0 = {~VBLK,CTR1[6:0]};
wire [7:0] IN1 = CTR2;

PKWARS_PSG psgs(
	CPUCL, PSGCL,
	CPUAD[1:0], DV, CPUWR, CPUOD, SNDDT,
	RESET, CPURD, 
	IN0, IN1, DSW,
	SNDOUT
);

endmodule

module PKWARS_PSG
(
	input				AXSCLK,
	input				CLK,
	input	 [1:0]	ADR,
	input				CS,
	input				WR,
	input	 [7:0]	ID,
	output [7:0]	OD,

	input				RESET,
	input				RD,

	input	 [7:0]	IN0,
	input	 [7:0]	IN1,
	input	 [7:0]	DSW,

	output [15:0]	SNDOUT
);

wire [7:0] IN2 = 8'hFF;
wire [7:0] OD0, OD1;

wire [9:0] S0, S1;

PSG psg1(RESET, AXSCLK, CLK, ~ADR[0], CS & (~ADR[1]), WR, RD, ID, OD0, S0, IN0, IN1);
PSG psg2(RESET, AXSCLK, CLK, ~ADR[0], CS & ( ADR[1]), WR, RD, ID, OD1, S1, IN2, DSW);

wire [12:0] SMIX = S0+S1;
wire [11:0] SCLP = SMIX[11:0]|{12{SMIX[12]}};
assign SNDOUT = {SCLP,4'h0};

assign OD = ADR[1] ? OD1 : OD0;

endmodule


module PSG
(
	input					RST,
	input					ACLK,
	input					CLK,

	input					AS,
	input					CS,
	input					WR,
	input					RD,

	input  [7:0]		ID,
	output [7:0]		OD,

	output [9:0]		SO,

	input  [7:0]		IA,
	input  [7:0]		IB
);

wire [7:0] Sx;
wire [1:0] Sc;
reg  [7:0] SA,SB,SC;
always @(negedge CLK or posedge RST) begin
	if (RST) begin
		SA <= 0;
		SB <= 0;
		SC <= 0;
	end
	else case (Sc)
	2'd0: SA <= Sx;
	2'd1: SB <= Sx;
	2'd2: SC <= Sx;
	default:;
	endcase
end

wire bd = CS & (WR|AS);
wire bc = CS & ((~WR)|AS);

YM2149m sg
(
	.I_DA(ID),.O_DA(OD),.I_A9_L(~CS),.I_BC1(bc),.I_BDIR(bd),
	.I_A8(1'b1),.I_BC2(1'b1),.I_SEL_L(1'b1),
	.O_AUDIO(Sx),.O_CHAN(Sc),
	.I_IOA(IA),.I_IOB(IB),
	.ENA(1'b1),.RESET_L(~RST),.CLK(CLK),.ACLK(ACLK)
);

assign SO = SA+SB+SC;

endmodule


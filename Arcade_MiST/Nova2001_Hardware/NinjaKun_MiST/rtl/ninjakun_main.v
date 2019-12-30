module ninjakun_main(
	input				RESET,
	input       MCLK,
	input				VBLK,

	input	  [7:0]	CTR1,
	input	  [7:0]	CTR2,

	output [15:0]	CPADR,
	output  [7:0]	CPODT,
	input	  [7:0]	CPIDT,
	output			CPRED,
	output			CPWRT,

	output [14:0]	CPU1ADDR,
	input  [7:0]	CPU1DT,
	output [14:0]	CPU2ADDR,
	input  [7:0]	CPU2DT
);


wire	CP0IQ, CP0IQA;
wire	CP1IQ, CP1IQA;
ninjakun_irqgen ninjakun_irqgen( 
	.MCLK(MCLK),
	.VBLK(VBLK),
	.IRQ0_ACK(CP0IQA),
	.IRQ1_ACK(CP1IQA),
	.IRQ0(CP0IQ),
	.IRQ1(CP1IQ)
);

wire			CP0CE_P, CP0CE_N, CP1CE_P, CP1CE_N;
wire [15:0]	CP0AD, CP1AD;
wire  [7:0]	CP0OD, CP1OD;
wire  [7:0] CP0DT, CP1DT;
wire  [7:0]	CP0ID, CP1ID;
wire			CP0RD, CP1RD;
wire			CP0WR, CP1WR;
Z80IP cpu0(
	.reset_in(RESET),
	.clk(MCLK),
	.clken_p(CP0CE_P),
	.clken_n(CP0CE_N),
	.adr(CP0AD),
	.data_in(CP0DT),
	.data_out(CP0OD),
	.rd(CP0RD),
	.wr(CP0WR),
	.intreq(CP0IQ),
	.intack(CP0IQA)
);

Z80IP cpu1(
	.reset_in(RESET),
	.clk(MCLK),
	.clken_p(CP1CE_P),
	.clken_n(CP1CE_N),
	.adr(CP1AD),
	.data_in(CP1DT),
	.data_out(CP1OD),
	.rd(CP1RD),
	.wr(CP1WR),
	.intreq(CP1IQ),
	.intack(CP1IQA)
);

ninjakun_cpumux ioshare(
	.MCLK(MCLK),
	.CPADR(CPADR),
	.CPODT(CPODT),
	.CPIDT(CPIDT),
	.CPRED(CPRED),
	.CPWRT(CPWRT),
	.CP0CE_P(CP0CE_P),
	.CP0CE_N(CP0CE_N),
	.CP0AD(CP0AD),
	.CP0OD(CP0OD),
	.CP0ID(CP0ID),
	.CP0RD(CP0RD),
	.CP0WR(CP0WR),
	.CP1CE_P(CP1CE_P),
	.CP1CE_N(CP1CE_N),
	.CP1AD(CP1AD),
	.CP1OD(CP1OD),
	.CP1ID(CP1ID),
	.CP1RD(CP1RD),
	.CP1WR(CP1WR)
);

wire CS_SH0, CS_SH1, CS_IN0, CS_IN1;
wire SYNWR0, SYNWR1;
ninjakun_adec adec(
	.CP0AD(CP0AD), 
	.CP0WR(CP0WR),
	.CP1AD(CP1AD), 
	.CP1WR(CP1WR),
	.CS_IN0(CS_IN0), 
	.CS_IN1(CS_IN1),
	.CS_SH0(CS_SH0), 
	.CS_SH1(CS_SH1),
	.SYNWR0(SYNWR0), 
	.SYNWR1(SYNWR1)
);


wire [7:0] ROM0D, ROM1D;
assign CPU1ADDR = CP0AD[14:0];
assign ROM0D = CPU1DT;
assign CPU2ADDR = CP1AD[14:0];
assign ROM1D = CPU2DT;

wire [7:0] SHDT0, SHDT1;

dpram #(8,11) shmem(
	MCLK, CS_SH0 & CP0WR, { CP0AD[10] ,CP0AD[9:0]}, CP0OD, SHDT0,
	MCLK, CS_SH1 & CP1WR, {~CP1AD[10], CP1AD[9:0]}, CP1OD, SHDT1);

wire [7:0] INPD0, INPD1;
ninjakun_input inps(
	.MCLK(MCLK),
	.RESET(RESET),
	.CTR1i(CTR1),	// Control Panel (Negative Logic)
	.CTR2i(CTR2),
	.VBLK(VBLK), 
	.AD0(CP0AD[1:0]),
	.OD0(CP0OD[7:6]),
	.WR0(SYNWR0),
	.AD1(CP1AD[1:0]),
	.OD1(CP1OD[7:6]),
	.WR1(SYNWR1),
	.INPD0(INPD0),
	.INPD1(INPD1)
);

dataselector_3D_8B cdt0(
	.out(CP0DT),  
	.df(CP0ID),
	.en0(CS_IN0), 
	.dt0(INPD0),
	.en1(CS_SH0), 
	.dt1(SHDT0),
	.en2(~CP0AD[15]), 
	.dt2(ROM0D)
);

dataselector_3D_8B cdt1(
	.out(CP1DT),  
	.df(CP1ID),
	.en0(CS_IN1), 
	.dt0(INPD1),
	.en1(CS_SH1), 
	.dt1(SHDT1),
	.en2(~CP1AD[15]), 
	.dt2(ROM1D)
);

endmodule 
/***********************************************
	FPGA Atari-Tetris

					Copyright (c) 2019 MiSTer-X
					
	Converted to clock-enable & SDRAM by Slingshot
	  
************************************************/
module FPGA_ATetris
(
	input 			MCLK,		// 14.318MHz
	input				RESET,
	
	input  [10:0]	INP,		// Negative Logic

	input   [8:0]	HPOS,
	input   [8:0]	VPOS,
	output			PCLK,
	output			PCLK_EN,
	output  [7:0]	POUT,	
	output [15:0]	AOUT,
	
	output [15:0]  PRAD,
	input   [7:0]  PRDT,

	output [15:0]  CRAD,
	input  [15:0]  CRDT,

	input        NVRAM_CLK,
	input  [8:0] NVRAM_A,
	input  [7:0] NVRAM_D,
	input        NVRAM_WE,
	output [7:0] NVRAM_Q
);

// INP = {`SELFT,`COIN2,`COIN1,`P2LF,`P2RG,`P2DW,`P2RO,`P1LF,`P1RG,`P1DW,`P1RO};


// Reset Line
wire 			WDRST;
wire			RST = WDRST|RESET;


// CPU-Bus
wire [15:0] CPUAD;
wire  [7:0] CPUDO,CPUDI;
wire			CPUWR,CPUIRQ;


// Clock Generator
wire PCLKx2,CPUCE;
ATETRIS_CLKGEN cgen(MCLK,PCLKx2,PCLK,PCLK_EN,CPUCE);


// ROMs
//wire [15:0] PRAD;
//wire  [7:0] PRDT;

wire			CRCL;
//wire [15:0] CRAD;
//wire  [7:0] CRDT;

//DLROM #(16,8) prom(DEVCL,PRAD,PRDT, ROMCL,ROMAD,ROMDT,ROMEN & ~ROMAD[16]);
//DLROM #(16,8) crom( CRCL,CRAD,CRDT, ROMCL,ROMAD,ROMDT,ROMEN &  ROMAD[16]);


// ROM Bank Control
wire			PRDV;
ATETRIS_ROMAXS romaxs(RST,MCLK,CPUCE,CPUAD,PRAD,PRDV);


// RAMs
wire [7:0]  RMDT;
wire		   RMDV;
ATETRIS_RAMS rams(MCLK,CPUAD,CPUWR,CPUDO,RMDT,RMDV,NVRAM_CLK,NVRAM_A,NVRAM_D,NVRAM_WE,NVRAM_Q);


// Video
wire [7:0]	VDDT;
wire			VDDV;
wire			VBLK;
ATETRIS_VIDEO video(
	MCLK,PCLK_EN,HPOS,VPOS,
	POUT,VBLK,
	CRCL,CRAD,CRDT,
	CPUAD,CPUDO,CPUWR,VDDT,VDDV
);


// Sound & Input port
wire [7:0]	P0 = {INP[10],VBLK,4'b1111,INP[8],INP[9]};
wire [7:0]	P1 =  INP[7:0];

wire [7:0]	SNDT;
wire			SNDV;

ATETRIS_SOUND sound(
	RST,P0,P1,
	AOUT,
	MCLK,CPUCE,CPUAD,CPUDO,CPUWR,SNDT,SNDV
);


// IRQ Generator & Watch-Dog Timer
ATETRIS_IRQWDT irqwdt(RST,VPOS, MCLK,CPUCE,CPUAD,CPUWR, CPUIRQ,WDRST);


// CPU data selector
wire dum;
DSEL4x8 dsel(dum,CPUDI,
	SNDV,SNDT,
	VDDV,VDDT,
	RMDV,RMDT,
	PRDV,PRDT
);

// CPU
CPU6502W cpu(RST,MCLK,CPUCE,CPUAD,CPUWR,CPUDO,CPUDI,CPUIRQ);

endmodule


module ATETRIS_CLKGEN
(
	input				MCLK,		//  14.318MHz

	output			PCLKx2,	//  14.318MHz
	output			PCLK,		//  7.1590MHz
	output			PCLK_EN,//  7.1590MHz

	output      CPUCE		//  1.1789MHz
);

reg [2:0] clkdiv;
always @(posedge MCLK) clkdiv <= clkdiv+1'd1;

assign PCLKx2 = MCLK;
assign PCLK   = clkdiv[0];
assign PCLK_EN= ~clkdiv[0];

assign CPUCE  = clkdiv == 3'b011;

endmodule


module ATETRIS_ROMAXS
(
	input				RESET,
	input				MCLK,
	input				CE,
	input  [15:0]	CPUAD,
	
	output [15:0]	PRAD,
	output 			PRDV
);

wire [1:0] BS;
ATARI_SLAPSTIK1 bnkctr(RESET,MCLK,CE,(CPUAD[15:13]==3'b011),CPUAD[12:0],BS);

assign PRAD = {CPUAD[15],(CPUAD[15] ? CPUAD[14] : BS[0]),CPUAD[13:0]};
assign PRDV = (CPUAD[15]|(CPUAD[15:14]==2'b01));

endmodule


module ATETRIS_RAMS
(
	input				MCLK,
	input  [15:0]	CPUAD,
	input				CPUWR,
	input   [7:0]	CPUDO,
	output  [7:0]	RMDT,
	output			RMDV,

	input        NVRAM_CLK,
	input  [8:0] NVRAM_A,
	input  [7:0] NVRAM_D,
	input        NVRAM_WE,
	output [7:0] NVRAM_Q
);

// WorkRAM
wire			WRDV = (CPUAD[15:12]==4'b0000);				// $0000-$0FFF
wire  [7:0] WRDT;
//RAM_B #(12)	wram(DEVCL,CPUAD,WRDV,CPUWR,CPUDO,WRDT);
	
spram#(			
	.widthad_a(12),
	.width_a(8))
wram(
	.address(CPUAD),
	.clock(MCLK),
	.data(CPUDO),
	.wren(CPUWR & WRDV),
	.q(WRDT)
	);	

// NVRAM
wire			NVDV = (CPUAD[15:10]==6'b0010_01);			// $24xx-$27xx
wire  [7:0] NVDT;
//RAM_B #(9,255)	nvram(DEVCL,CPUAD,NVDV,CPUWR,CPUDO,NVDT);

dpram#(
	.init_file("rtl/nvinit.mif"),
	.data_width_g(8),
	.addr_width_g(9))
nvram(
	// CPU side
	.clk_a_i(MCLK),
	.en_a_i(1'b1),
	.addr_a_i(CPUAD),
	.data_a_i(CPUDO),
	.we_i(CPUWR & NVDV),
	.data_a_o(NVDT),
	// IO Controller side
	.clk_b_i(NVRAM_CLK),
	.addr_b_i(NVRAM_A),
	.data_b_o(NVRAM_Q),
	.data_b_i(NVRAM_D),
	.we_b_i(NVRAM_WE)
	);

DSEL4x8 dsel(RMDV,RMDT,
	WRDV,WRDT,
	NVDV,NVDT
);

endmodule


module ATETRIS_IRQWDT
(
	input				RESET,
	input	  [8:0]	VP,

	input				MCLK,
	input       CE,
	input  [15:0]	CPUAD,
	input				CPUWR,

	output reg		IRQ = 0,
	output			WDRST
);

wire tWDTR = (CPUAD[15:10]==6'b0011_00) & CPUWR;	// $3000-$33FF
wire tIRQA = (CPUAD[15:10]==6'b0011_10) & CPUWR;	// $3800-$3BFF

// IRQ Generator
reg [8:0] pVP;
always @(posedge MCLK) begin
	if (RESET) begin
		IRQ <= 0;
		pVP <= 0;
	end
	else if (CE) begin
		if (tIRQA) IRQ <= 0;
		else if (pVP!=VP) begin
			case (VP)
				48,112,176,240: IRQ <= 1;
				80,144,208, 16: IRQ <= 0;
				default:;
			endcase
			pVP <= VP;
		end
	end
end

// Watch-Dog Timer
reg [3:0] WDT = 0;
assign WDRST = WDT[3];

reg [8:0] pVPT;
always @(posedge MCLK) begin
	if (tWDTR) WDT <= 0;
	else if (pVPT!=VP) begin
		if (VP==0) WDT <= (WDT==8) ? 4'd14 : (WDT+1);
		pVPT <= VP;
	end
end

endmodule


module ATETRIS_VIDEO
(
	input				MCLK,
	input				PCLK_EN,
	input	  [8:0]	HPOS,
	input	  [8:0]	VPOS,

	output  [7:0]	POUT,
	output			VBLK,

	output			CRCL,
	output reg [15:0]	CRAD,
	input  [15:0]	CRDT,

	input  [15:0]	CPUAD,
	input   [7:0]	CPUDO,
	input				CPUWR,
	output  [7:0]	VDDT,
	output			VDDV
);

wire [8:0] HP = HPOS+1'd1;
wire [8:0] VP = VPOS;
// PlayField scanline generator
wire [10:0] VRAD = {VP[7:3],HP[8:3]};
wire [15:0] VRDT;
reg  [15:0] VRDT_LATCH, VRDT_LATCHD;
reg [7:0] CRDT_REG;
//(* preserve *) reg [5:0] CH;
wire [5:0] CH = {VP[2:0],HP[2:0]};
always @(posedge MCLK) begin
	if (PCLK_EN) begin
		CRAD <= {VRDT[10:0],CH[5:1]};
	end
end

assign CRCL = ~MCLK;

reg [3:0] OPIX;
always @(*) begin
	case (HPOS[1:0])
		2'b01: OPIX = CRDT[ 7: 4];
		2'b10: OPIX = CRDT[ 3: 0];
		2'b11: OPIX = CRDT[15:12];
		2'b00: OPIX = CRDT[11: 8];
	endcase
end

reg   [7:0] PALT;
always @(posedge MCLK) begin
	if (PCLK_EN) begin
		VRDT_LATCH <= VRDT;
		VRDT_LATCHD <= VRDT_LATCH;
		PALT <= {VRDT_LATCHD[15:12],OPIX};
	end
end

assign VBLK = (VPOS>=240);


// CPU interface
wire csP = (CPUAD[15:10]==6'b0010_00);	// $2000-$23FF
wire csV = (CPUAD[15:12]==4'b0001);		// $1000-$1FFF
wire csH = csV &  CPUAD[0];
wire csL = csV & ~CPUAD[0];

wire wrH = csH & CPUWR;
wire wrL = csL & CPUWR;
wire wrP = csP & CPUWR;

wire [7:0] vdtH,vdtL,palD;

DSEL4x8 dsel(VDDV,VDDT,
	csP,palD,
   csH,vdtH,
	csL,vdtL
);

		
// VideoRAMs
//DPRAMrw #(11,8) vrmH(PCLK,VRAD,VRDT[15:8], CPUCL,CPUAD[11:1],CPUDO,wrH,vdtH);

dpram #(11,8) vrmH (
	.clk_a_i(MCLK),
	.en_a_i(1),
	.we_i(wrH),
	.addr_a_i(CPUAD[11:1]),
	.data_a_i(CPUDO),
	.data_a_o(vdtH),
	
	.clk_b_i(MCLK),
	.addr_b_i(VRAD),
	.data_b_o(VRDT[15:8])
	);

//DPRAMrw #(11,8) vrmL(PCLK,VRAD,VRDT[ 7:0], CPUCL,CPUAD[11:1],CPUDO,wrL,vdtL);

dpram #(11,8) vrmL (
	.clk_a_i(MCLK),
	.en_a_i(1),
	.we_i(wrL),
	.addr_a_i(CPUAD[11:1]),
	.data_a_i(CPUDO),
	.data_a_o(vdtL),
	
	.clk_b_i(MCLK),
	.addr_b_i(VRAD),
	.data_b_o(VRDT[7:0])
	);

	
//DPRAMrw #(8,8)  palt(MCLK,PALT,POUT,    MCLK,CPUAD[ 7:0],CPUDO,wrP,palD);

dpram #(8,8) palt (
	.clk_a_i(MCLK),
	.en_a_i(1),
	.we_i(wrP),
	.addr_a_i(CPUAD[ 7:0]),
	.data_a_i(CPUDO),
	.data_a_o(palD),
	
	.clk_b_i(MCLK),
	.addr_b_i(PALT),
	.data_b_o(POUT)
	);

endmodule


module ATETRIS_SOUND
(
	input				RESET,
	input   [7:0]	INP0,
	input   [7:0]	INP1,

	output [15:0]	AOUT,

	input				MCLK,
	input				CE,
	input  [15:0]	CPUAD,
	input   [7:0]	CPUDO,
	input				CPUWR,
	output  [7:0]	SNDT,
	output			SNDV
);

wire csPx = (CPUAD[15:10]==6'b0010_10);
wire csP0 = (CPUAD[5:4]==2'b00) & csPx;	// $280x
wire csP1 = (CPUAD[5:4]==2'b01) & csPx;	// $281x

wire [7:0] rdt0,rdt1;
wire [7:0] snd0,snd1;
PokeyW p0(MCLK,CE,RESET, CPUAD,csP0,CPUWR,CPUDO,rdt0, INP0,snd0);
PokeyW p1(MCLK,CE,RESET, CPUAD,csP1,CPUWR,CPUDO,rdt1, INP1,snd1);

DSEL4x8 dsel(SNDV,SNDT,
	csP0,rdt0,
	csP1,rdt1
);

wire [8:0] snd = snd0+snd1;
assign AOUT = {snd,7'h0};

endmodule


// CPU-IP wrapper
module CPU6502W
(
	input				RST,
	input				CLK,
	input				CE,

	output [15:0]	AD,
	output 			WR,
	output  [7:0]	DO,
	input	  [7:0]	DI,

	input				IRQ
);

wire   rw;
assign WR = ~rw;

T65 cpu
(
	.mode(2'b01),
//	.BCD_en(1'b1),
	.res_n(~RST),
	.enable(CE),
	.clk(CLK),
	.rdy(1'b1),
	.abort_n(1'b1),
	.irq_n(~IRQ),
	.nmi_n(1'b1),
	.so_n(1'b1),
	.r_w_n(rw),
	.a(AD),
	.di(DI),
	.do(DO)
);

endmodule


// Pokey-IP wrapper
module PokeyW
(
	input				CLK,
	input       CE,

	input				RST,
	input  [3:0]	AD,
	input				CS,
	input				WE,
	input  [7:0]	WD,
	output [7:0]	RD,

	input  [7:0]	P,
	output [7:0]	SND
);

wire [3:0] ch0,ch1,ch2,ch3;

pokey core (
	.RESET_N(~RST),
	.CLK(CLK),
	.ADDR(AD),
	.DATA_IN(WD),
	.DATA_OUT(RD),
	.WR_EN(WE & CS),
	.ENABLE_179(CE),
	.POT_IN(P),
	
	.CHANNEL_0_OUT(ch0),
	.CHANNEL_1_OUT(ch1),
	.CHANNEL_2_OUT(ch2),
	.CHANNEL_3_OUT(ch3)
);

assign SND = ch0+ch1+ch2+ch3;

endmodule


// Data selector
module DSEL4x8
(
	output		 odv,
	output [7:0] odt,

	input en0, input [7:0] dt0,
	input en1, input [7:0] dt1,
	input en2, input [7:0] dt2,
	input en3, input [7:0] dt3
);

assign odv = en0|en1|en2|en3;

assign odt = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 en3 ? dt3 :
				 8'h00;

endmodule


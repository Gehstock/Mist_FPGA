/*******************************************************
	FPGA Implimentation of "Green Beret" (Video Part)
********************************************************/
// Copyright (c) 2013,19 MiSTer-X

module VIDEO
(
	input         VCLKx8,
	input         VCLK,
	input         VCLK_EN,

	input   [8:0] HP,
	input	  [8:0] VP,

	input         PALD,
	input         CPUD,

	output        PCLK,
	output        PCLK_EN,
	output [11:0]	POUT,

	input				CPUMX,
	input	 [15:0]	CPUAD,
	input				CPUWR,
	input	  [7:0]	CPUWD,
	output			CPUDV,
	output  [7:0]	CPURD,

	output [15:1] SP_ROMA,
	input  [15:0] SP_ROMD,

	input				DLCL,
	input  [17:0]  DLAD,
	input   [7:0]	DLDT,
	input				DLEN
);

// Video RAMs
wire				CS_CRAM = ( CPUAD[15:11] ==  5'b1100_0              ) & CPUMX;	// $C000-$C7FF
wire				CS_VRAM = ( CPUAD[15:11] ==  5'b1100_1              ) & CPUMX;	// $C800-$CFFF
wire				CS_MRAM = ( CPUAD[15:12] ==  4'b1101                ) & CPUMX;	// $D000-$DFFF
wire				CS_ZRM0 = ( CPUAD[15: 5] == 11'b1110_0000_000       ) & CPUMX;	// $E000-$E01F
wire				CS_ZRM1 = ( CPUAD[15: 5] == 11'b1110_0000_001       ) & CPUMX;	// $E020-$E03F
wire				CS_SPRB = ( CPUAD[15: 0] == 16'b1110_0000_0100_0011 ) & CPUMX;	// $E043

wire  [7:0]		OD_CRAM, OD_VRAM;
wire  [7:0]		OD_MRAM;
wire  [7:0]		OD_ZRM0, OD_ZRM1;

assign CPUDV = CS_CRAM | CS_VRAM | CS_MRAM | CS_ZRM0 | CS_ZRM1 ;

assign CPURD = CS_CRAM ? OD_CRAM :
					CS_VRAM ? OD_VRAM :
					CS_MRAM ? OD_MRAM :
					CS_ZRM0 ? OD_ZRM0 :
					CS_ZRM1 ? OD_ZRM1 :
					8'h0;


wire [10:0]	BGVA;
wire  [7:0]	BGCR, BGVR;

reg			SPRB;
wire  [7:0] SATA;
wire  [7:0] SATD;
wire [11:0] SAAD = {3'b000,SPRB,SATA};
always @( posedge VCLKx8 ) if ( CS_SPRB & CPUWR ) SPRB <= ~CPUWD[3];

wire  [4:0] ZRMA;
wire  [7:0] ZRM0, ZRM1;
wire [15:0] ZRMD = {ZRM1,ZRM0};

dpram #(8,11) cram (.clk_a(VCLKx8), .we_a(CS_CRAM & CPUWR), .addr_a(CPUAD[10:0]), .d_a(CPUWD), .q_a(OD_CRAM), .clk_b(VCLKx8), .addr_b(BGVA), .q_b(BGCR));
dpram #(8,11) vram (.clk_a(VCLKx8), .we_a(CS_VRAM & CPUWR), .addr_a(CPUAD[10:0]), .d_a(CPUWD), .q_a(OD_VRAM), .clk_b(VCLKx8), .addr_b(BGVA), .q_b(BGVR));
dpram #(8,12) mram (.clk_a(VCLKx8), .we_a(CS_MRAM & CPUWR), .addr_a(CPUAD[11:0]), .d_a(CPUWD), .q_a(OD_MRAM), .clk_b(VCLKx8), .addr_b(SAAD), .q_b(SATD));
dpram #(8, 5) zrm0 (.clk_a(VCLKx8), .we_a(CS_ZRM0 & CPUWR), .addr_a(CPUAD[ 4:0]), .d_a(CPUWD), .q_a(OD_ZRM0), .clk_b(VCLKx8), .addr_b(ZRMA), .q_b(ZRM0));
dpram #(8, 5) zrm1 (.clk_a(VCLKx8), .we_a(CS_ZRM1 & CPUWR), .addr_a(CPUAD[ 4:0]), .d_a(CPUWD), .q_a(OD_ZRM1), .clk_b(VCLKx8), .addr_b(ZRMA), .q_b(ZRM1));

// BG Scanline Generator
wire  [8:0] BGVP = VP+9'd16;
wire  [8:0] BGHP = HP+9'd8+(ZRMD[8:0]);

assign		ZRMA = BGVP[7:3];
assign		BGVA = {BGVP[7:3],BGHP[8:3]};
wire  [8:0] BGCH = {BGCR[6],BGVR};
wire  [3:0] BGCL = BGCR[3:0];
wire  [1:0] BGFL = BGCR[5:4];

wire  [2:0] BGHH = BGHP[2:0]^{3{BGFL[0]}};
wire  [2:0] BGVV = BGVP[2:0]^{3{BGFL[1]}};
wire [13:0] BGCA = {BGCH,BGVV[2:0],BGHH[2:1]};
wire  [0:7] BGCD;
dpram #(8,14) bgchip(.clk_a(DLCL), .we_a(DLEN && DLAD[17:14]==4'b10_00), .addr_a(DLAD[13:0]), .d_a(DLDT), .clk_b(VCLKx8), .addr_b(BGCA), .q_b(BGCD));

wire  [7:0] BGCT = {BGCL,(BGHH[0] ? BGCD[4:7]:BGCD[0:3])};
wire  [3:0] BGPT;
dpram #(8,8) bgclut(.clk_a(DLCL), .we_a(DLEN && DLAD[17:8]==10'b10_0100_0001), .addr_a(DLAD[7:0]), .d_a(DLDT), .clk_b(VCLKx8), .addr_b(BGCT), .q_b(BGPT));

reg			BGHI;
always @(posedge VCLKx8) if (VCLK_EN) BGHI <= ~BGCR[7];


// Sprite Scanline Generator
wire [8:0]	SPHP = HP+9'd9;
wire [8:0]	SPVP = VP+9'd18;
wire [3:0]  SPPT;
SPRRENDER	spr( VCLKx8,VCLK_EN, SPHP,SPVP,SATA,SATD, SPPT, SP_ROMA, SP_ROMD,DLCL,DLAD,DLDT,DLEN );


// Color Mixer
wire [4:0] COLMIX = (BGHI & (|BGPT)) ? {1'b1,BGPT} : (|SPPT) ? {1'b0,SPPT} : {1'b1,BGPT}; 


// Palette
reg  [4:0] PALIN;
wire [7:0] PALET;
always @(posedge VCLKx8) if (VCLK_EN) PALIN <= PALD ? VP[6:2] : COLMIX;
dpram #(8,5) palet(.clk_a(DLCL), .we_a(DLAD[17:5]==13'b10_0100_0010_000), .addr_a(DLAD[7:0]), .d_a(DLDT), .clk_b(VCLKx8), .addr_b(PALIN), .q_b(PALET));
wire [7:0] PALOT = PALD ? ( (|VP[8:7]) ? 8'h0 : PALET ) : PALET;


// Pixel Output
assign PCLK = ~VCLK;
assign PCLK_EN = VCLK_EN;
assign POUT = {PALOT[7:6],2'b00,PALOT[5:3],1'b0,PALOT[2:0],1'b0}; 

endmodule


//----------------------------------
//  Sprite Render
//----------------------------------
module SPRRENDER
(
	input					VCLKx8,
	input					VCLK_EN,

	input  [8:0]		SPHP,
	input	 [8:0]		SPVP,

	output [7:0]		SATA,
	input  [7:0]		SATD,
	
	output reg [3:0]	SPPT,

	output [15:1] SP_ROMA,
	input  [15:0] SP_ROMD,

	input					DLCL,
	input  [17:0]  	DLAD,
	input   [7:0]		DLDT,
	input					DLEN
);

reg  [3:0]	memwait;
reg  [5:0]	sano;
reg  [1:0]	saof;
reg  [7:0]	sat0, sat1, sat2, sat3;

reg  [3:0]	phase;

wire [8:0]	px    = {1'b0,sat2} - {sat1[7],8'h0};
wire [7:0]	py    = (phase==2) ? SATD : sat3;
wire			fx		= sat1[4];
wire			fy		= sat1[5];
wire [8:0] 	code  = {sat1[6],sat0};
wire [3:0]	color = sat1[3:0];

wire [8:0]	ht    = {1'b0,py}-SPVP;
wire			hy    = (py!=0) & (ht[8:4]==5'b11111);

reg  [4:0]	xcnt;
wire [3:0]	lx		= xcnt[3:0]^{4{ fx}};
wire [3:0]	ly		=   ht[3:0]^{4{~fy}};

wire [15:0] SPCA	= {code,ly[3],lx[3],ly[2:0],lx[2:1]};
wire  [0:7] SPCD;
assign SP_ROMA = SPCA[15:1];
assign SPCD = SPCA[0] ? SP_ROMD[15:8] : SP_ROMD[7:0];
//SPCHIP_ROM	spchip( ~VCLKx8, SPCA, SPCD, DLCL,DLAD,DLDT,DLEN );

wire [7:0]	pix	= {color,(lx[0] ? SPCD[4:7]:SPCD[0:3])};

`define SPRITES 8'h30

always @( posedge VCLKx8 ) begin
	if (SPHP==0) begin
		xcnt  <= 0;
		wre   <= 0;
		sano  <= 0;
		saof  <= 3;
		phase <= 2;
	end
	else case (phase)
		0: /* empty */ ;

		1: phase <= phase + 1'd1;

		2: begin
				if (sano >= `SPRITES) phase <= 0;
				else begin
					if (hy) begin
						sat3  <= SATD;
						saof  <= 2;
						phase <= phase+1'd1;
					end	else begin
						sano <= sano+1'd1;
						phase <= 4'd1;
					end
				end
			end

		3: phase <= phase+1'd1;

		4: begin
				sat2  <= SATD;
				saof  <= 1;
				phase <= phase+1'd1;
			end
		
		5: phase <= phase+1'd1;
		
		6: begin
				sat1  <= SATD;
				saof  <= 0;
				phase <= phase+1'd1;
			end

		7: phase <= phase+1'd1;

		8: begin
				sat0  <= SATD;
				saof  <= 3;
				sano  <= sano+1'd1;
				xcnt  <= 0;
				wre   <= 0;
				phase <= phase+1'd1;
				memwait  <= 0;
			end

		9: begin
				memwait <= memwait + 1'd1;
				if (&memwait) begin
					phase <= phase + 1'd1;
					wre <= 1;
				end
			end

		10: begin
					xcnt  <= xcnt+1'd1;
					if (xcnt[1:0] == 2'b11) begin
						wre <= 0;
						phase <= (xcnt[3:0] == 4'hf) ? 4'd1 : 4'd9;
					end
				end

		default:;
	endcase
end

assign SATA = {sano,saof};


reg         wre; // write enable to line buffer
wire        sid = SPVP[0];
wire  [8:0] wpx = px+xcnt[3:0];

// CLUT
reg  [9:0] lbad;
reg  [3:0] lbdt;
reg        lbwe;
always @(posedge VCLKx8) begin
	lbad <= {~sid,wpx};
	lbwe <= wre;
end
wire [3:0] opix;

dpram #(8,8) spclut(.clk_a(DLCL), .we_a(DLEN && DLAD[17:8]==10'b10_0100_0000), .addr_a(DLAD[7:0]), .d_a(DLDT), .clk_b(VCLKx8), .addr_b(pix), .q_b(opix));

// Line-Buffer
reg  [9:0] radr0=0,radr1=1;
wire [3:0] ispt;

always @(posedge VCLKx8) begin
	radr0 <= {sid,SPHP}; 
	if (VCLK_EN) begin
		if (radr0!=radr1) SPPT <= ispt;
		radr1 <= radr0;
	end
end

dpram #(4,10) lbuf(.clk_a(VCLKx8), .we_a(lbwe & (opix!=0)), .addr_a(lbad), .d_a(opix), .clk_b(VCLKx8), .addr_b(radr0), .we_b(radr0==radr1), .q_b(ispt));

endmodule


//--------------------------------------------
// FPGA DigDug (I/O device part)
//
//					Copyright (c) 2017 MiSTer-X
//--------------------------------------------
module DIGDUG_IODEV
(
	input				RESET,

	input  [7:0]	INP0,
	input  [7:0]	INP1,
	input  [7:0]	DSW0,
	input  [7:0]	DSW1,

	input	  			VBLK,			// V-BLANK

	input				CL,			// CPU Interface
	input  [15:0]	AD,
	input				WR,
	input   [7:0]	DI,
	input				RD,
	output			DV,
	output  [7:0]	DO,
	
	output  [2:0]	RSTS,			// CPU Reset Ctrl & Interrupt
	output  [2:0]	IRQS,
	output  [2:0]	NMIS,

	input				CLK48M,
	output			PCMCLK,
	output  [7:0]	PCMOUT,

	output			WAVECL,		// Wave ROM
	output  [7:0]	WAVEAD,
	input   [3:0]	WAVEDT,

	input				FGSCCL,		// FG VRAM
	input   [9:0]	FGSCAD,
	output  [7:0]	FGSCDT,

	input				SPATCL,		// SP ARAM
	input	  [6:0]	SPATAD,
	output [23:0]	SPATDT,

	output  [1:0]	BG_SELECT,	// Video Ctrl.
	output  [1:0]	BG_COLBNK,
	output 			BG_CUTOFF,
	output 			FG_CLMODE

);

// Work & Video Memory
wire CSM0 = (AD[15:11] == 5'b1000_0);	// $8000-$87FF
wire CSM1 = (AD[15:11] == 5'b1000_1);	// $8800-$8FFF
wire CSM2 = (AD[15:11] == 5'b1001_0);	// $9000-$97FF
wire CSM3 = (AD[15:11] == 5'b1001_1);	// $9800-$9FFF

wire [10:0] MAD = AD[10:0];
wire  [7:0] DOM0, DOM1, DOM2, DOM3;
DPR2KV ram0( CL, MAD, CSM0, WR, DI, DOM0, FGSCCL, {1'b0,FGSCAD}, FGSCDT );				// (FGTX) $8000-$8300
DPR2KV ram1( CL, MAD, CSM1, WR, DI, DOM1, SPATCL, {4'h7,SPATAD}, SPATDT[ 7: 0] );	// (SPA0) $8B80-$8BFF
DPR2KV ram2( CL, MAD, CSM2, WR, DI, DOM2, SPATCL, {4'h7,SPATAD}, SPATDT[15: 8] );	// (SPA1) $9380-$93FF
DPR2KV ram3( CL, MAD, CSM3, WR, DI, DOM3, SPATCL, {4'h7,SPATAD}, SPATDT[23:16] );	// (SPA2) $9B80-$9BFF


// NAMCO WSG
wire WSGWR =( AD[15:5] == 11'b0110_1000_000 ) & WR;	// $6800-$681F
WSG_3CH wsg( CLK48M, RESET, CL, AD[4:0], DI[3:0], WSGWR, WAVECL, WAVEAD, WAVEDT, PCMCLK, PCMOUT );


// NAMCO Custom I/O Chip
wire CSCUSIO = (AD[15:9] == 7'b0111_000);					// $70xx-$71xx
wire [7:0] DOCUSIO;
wire NMI0;
DIGDUG_CUSIO cusio( RESET, VBLK, INP0, INP1, DSW0, DSW1, CL, CSCUSIO, WR, {AD[8],AD[3:0]}, DI, DOCUSIO, NMI0 );


// Video Ctrl Latches
wire VLWR = (AD[15:3] == 13'b1010_0000_0000_0) & WR;	// $A000-$A007
DIGDUG_VLATCH vlats( RESET, CL, AD[2:0], VLWR, DI[0], BG_SELECT, BG_COLBNK, BG_CUTOFF, FG_CLMODE );


// CPU Ctrl Latches
wire CLWR = (AD[15:3] == 13'b0110_1000_0010_0) & WR;	// $6820-$6827
wire NMI2;
DIGDUG_CLATCH clats( RESET, CL, AD[2:0], CLWR, DI[0], VBLK, RSTS, IRQS, NMI2 );


// To CPU
assign DV = CSM0|CSM1|CSM2|CSM3|CSCUSIO;
assign DO = CSM0 ? DOM0 : CSM1 ? DOM1 : CSM2 ? DOM2 : CSM3 ? DOM3 : CSCUSIO ? DOCUSIO : 8'hFF;
assign NMIS = {NMI2,1'b0,NMI0};

endmodule


module DIGDUG_VLATCH
(
	input					RESET,
	input					CL,
	input	[2:0]			AD,
	input					WR,
	input					DI,
	
	output reg [1:0]	BG_SELECT,
	output reg [1:0]	BG_COLBNK,
	output reg			BG_CUTOFF,
	output reg			FG_CLMODE
);

always @( posedge CL or posedge RESET ) begin
	if (RESET) begin
		BG_SELECT <= 2'b00;
		BG_COLBNK <= 2'b00;
		BG_CUTOFF <= 1'b0;
		FG_CLMODE <= 1'b0;
	end
	else begin
		if (WR) case(AD)
			3'h0: BG_SELECT[0] <= DI;
			3'h1: BG_SELECT[1] <= DI;
			3'h2: FG_CLMODE    <= DI;
			3'h3: BG_CUTOFF    <= DI;
			3'h4: BG_COLBNK[0] <= DI;
			3'h5: BG_COLBNK[1] <= DI;
			default:;
		endcase
	end
end

endmodule


module DIGDUG_CLATCH
(
	input					RESET,
	input					CL,		// 24MHz
	input	 [2:0]		AD,
	input					WR,
	input					DI,
	
	input	 				VBLK,
	output [2:0]		RSTS,
	output [2:0]		IRQS,
	output 				NMI2
);

// OSC 120Hz
`define H120FLOW	(12500)
reg  [3:0] clkdiv;
always @( posedge CL ) clkdiv <= clkdiv+1;
reg [13:0] H120CNT;
always @( posedge clkdiv[3] or posedge RESET ) begin
	if (RESET) H120CNT <= 0;
	else H120CNT <= (H120CNT==`H120FLOW) ? 0 : (H120CNT+1);
end
wire H120 = ( H120CNT >= (`H120FLOW-200) ) ? 1'b1 : 0;


reg IRQ0EN, IRQ0LC;
reg IRQ1EN, IRQ1LC;
reg NMI2EN, NMI2LC;
reg			NMI0LC;

reg C12RST = 1'b1;
reg pH120;

always @( posedge CL or posedge RESET ) begin
	if (RESET) begin
		IRQ0EN <= 1'b0; IRQ0LC <= 1'b0;
		IRQ1EN <= 1'b0; IRQ1LC <= 1'b0;
		NMI2EN <= 1'b0; NMI2LC <= 1'b0;
		C12RST <= 1'b1; NMI0LC <= 1'b0;
		pH120  <= 1'b0;
	end
	else begin
		if (WR) begin
			case(AD)
				3'h0: begin IRQ0EN <= DI; if (~DI) IRQ0LC <= 1'b0; end
				3'h1: begin IRQ1EN <= DI; if (~DI) IRQ1LC <= 1'b0; end
				3'h2: begin NMI2EN <=~DI; if ( DI) NMI2LC <= 1'b0; end
				3'h3: C12RST <= ~DI;
				default:;
			endcase
		end
		if (VBLK) begin IRQ0LC <= 1'b1; IRQ1LC <= 1'b1; end
		if ((pH120^H120)&H120) NMI2LC <= 1'b1;
		pH120 <= H120;
	end
end

assign RSTS = {{2{C12RST}},RESET};
assign IRQS = {1'b0,(IRQ1EN & IRQ1LC),(IRQ0EN & IRQ0LC)};
assign NMI2 = (NMI2EN & NMI2LC);

endmodule


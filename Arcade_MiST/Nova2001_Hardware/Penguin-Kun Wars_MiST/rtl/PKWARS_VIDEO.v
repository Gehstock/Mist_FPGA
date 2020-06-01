// Copyright (c) 2012,20 MiSTer-X 

module PKWARS_VIDEO
(
	input					RESET,
	input					VCLKx4,
	input					VCLK,
	
	input   [8:0]		PH,
	input   [8:0]		PV,

	output [11:0]		POUT,

	output  [9:0]		BGVAD,	// BG
	input  [15:0]		BGVDT,
	output [13:0]		BGCAD,
	input  [31:0]		BGCDT,

	output [10:0]		SPAAD,	// Sprite
	input   [7:0]		SPADT,
	output [13:0]		SPCAD,
	input  [31:0]		SPCDT,
	input					SPCFT
);



// BackGround Scanline Generator
wire [4:0] BGOUT;
PKWARS_BG BG(
	VCLK,
	PH, PV,
	BGVAD, BGVDT,
	BGCAD, BGCDT,
	BGOUT
);

// Sprite Scanline Generator
wire [3:0] SPOUT;
PKWARS_SP SP(
	VCLKx4, VCLK,
	PH, PV,
	SPAAD, SPADT,
	SPCAD, SPCDT, SPCFT,
	SPOUT
);

// Plane Mixer
wire [4:0] PALDS = {PV[3],PH[7:4]};

wire		  BGHPR = (BGOUT[4])&(BGOUT[3:0]!=0);
wire [4:0] BGCOL = {1'b1,BGOUT[3:0]};

wire       SPOPQ = (SPOUT!=0);
wire [4:0] SPCOL = {1'b0,SPOUT};

assign 	  PALAD = //DBGPD ? PALDS : 
						 BGHPR ? BGCOL :
					    SPOPQ ? SPCOL :
						         BGCOL ;

// Color Palette
wire [3:0] ro = {PALDT[3:2],PALDT[1:0]};
wire [3:0] go = {PALDT[5:4],PALDT[1:0]};
wire [3:0] bo = {PALDT[7:6],PALDT[1:0]};

assign POUT = {bo,go,ro};

wire [4:0]		PALAD;
wire [7:0]		PALDT;

col col(
	.clk(VCLK),
	.addr(PALAD),
	.data(PALDT)
);

endmodule


// BackGround Scanline Generator
module PKWARS_BG
(
	input					VCLK,

	input   [8:0]		PH,		// CRTC
	input	  [8:0]		PV,

	output  [9:0]		BGVAD,	// VRAM
	input	 [15:0]		BGVDT,

	output reg [13:0]	BGCAD,	// CHR-ROM
	input   [31:0]		BGCDT,

	output  [4:0]		BGOUT		// OUTPUT
);

wire  [8:0] POSH  = PH+2;
wire  [8:0] POSV  = PV+32;

reg   [4:0] PALET;
wire [10:0] CHRNO = BGVDT[10:0];
wire  [3:0] PIXEL = POSH[0] ? BGCDT[3:0] : BGCDT[7:4];

reg   [8:0] POUT;
always @( posedge VCLK ) begin
	BGCAD <= {CHRNO,POSV[2:0]};
	PALET <= {BGVDT[11],BGVDT[15:12]};
	case(POSH[2:0])
	 1: POUT <= {PALET,BGCDT[7:4]  };
	 2: POUT <= {PALET,BGCDT[3:0]  };
	 3: POUT <= {PALET,BGCDT[15:12]};
	 4: POUT <= {PALET,BGCDT[11:8] };
	 5: POUT <= {PALET,BGCDT[23:20]};
	 6: POUT <= {PALET,BGCDT[19:16]};
	 7: POUT <= {PALET,BGCDT[31:28]};
	 0: POUT <= {PALET,BGCDT[27:24]};
	endcase
end

wire [3:0] OTHP = (POUT[3:0]==1) ? POUT[7:4] : POUT[3:0];

assign BGVAD = {POSV[7:3],POSH[7:3]};
assign BGOUT = {POUT[8],OTHP};

endmodule


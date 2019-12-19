/***********************************
	FPGA Druaga ( Video Part )

	  Copyright (c) 2007 MiSTer-X
************************************/
module DRUAGA_VIDEO
(
	input				VCLKx8,
	input				VCLK,
	input				VCLK_EN,

	input  [8:0]	PH,
	input  [8:0]	PV,
	output			PCLK,
	output			PCLK_EN,
	output [7:0]	POUT,
	output			VB,

	output [10:0]	VRAM_A,
	input	 [15:0]	VRAM_D,

	output [6:0]	SPRA_A,
	input	 [23:0]	SPRA_D,

	input	 [8:0]	SCROLL,

	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire [8:0] HPOS = PH-8'd16;
wire [8:0] VPOS = PV;

wire  oHB = (PH>=290) & (PH<492);

assign VB = (PV==224);


reg  [4:0]	PALT_A;
wire [7:0]	PALT_D;

wire [7:0]	CLT0_A;
wire [3:0]	CLT0_D;

wire [11:0]	BGCH_A;
wire [7:0]	BGCH_D;


//
// BG scroll registers
//
reg  [8:0] BGVSCR;
wire [8:0] BGVPOS = BGVSCR + VPOS;
always @(posedge VCLKx8) if (PH == 290) BGVSCR <= SCROLL;


//----------------------------------------
//  BG scanline generator
//----------------------------------------
reg	 [7:0] BGPN;
reg			 BGH;

wire	 [5:0] COL  = HPOS[8:3];
wire	 [5:0] ROW  = VPOS[8:3];
wire	 [5:0] ROW2 = ROW + 6'h02;

wire	 [7:0] CHRC = VRAM_D[7:0];
wire	 [5:0] BGPL = VRAM_D[13:8];

wire	 [8:0] HP    = HPOS;
wire	 [8:0] VP    = COL[5] ? VPOS : BGVPOS;
wire	[11:0] CHRA  = { CHRC, ~HP[2], VP[2:0] };
wire	 [7:0] CHRO  = BGCH_D;

always @ ( posedge VCLKx8 ) begin
	if (VCLK_EN)
	case ( HP[1:0] )
		2'b00: begin BGPN <= { BGPL, CHRO[7], CHRO[3] }; BGH <= VRAM_D[14]; end
		2'b01: begin BGPN <= { BGPL, CHRO[6], CHRO[2] }; BGH <= VRAM_D[14]; end
		2'b10: begin BGPN <= { BGPL, CHRO[5], CHRO[1] }; BGH <= VRAM_D[14]; end
		2'b11: begin BGPN <= { BGPL, CHRO[4], CHRO[0] }; BGH <= VRAM_D[14]; end
	endcase
end

wire	[10:0] VRAMADRS = COL[5] ? { 4'b1111, COL[1:0], ROW[4], ROW2[3:0] } : { VP[8:3], HP[7:3] };

assign CLT0_A = BGPN;
assign BGCH_A = CHRA;
assign VRAM_A = VRAMADRS;

wire			BGHI  = BGH & (CLT0_D!=4'd15);
wire	[4:0]	BGCOL = { 1'b1, CLT0_D };


//----------------------------------------
//  Sprite scanline generator
//----------------------------------------
wire	[4:0] SPCOL;

DRUAGA_SPRITE spr
(
	VCLKx8, VCLK_EN,
	HPOS, VPOS, oHB,
	SPRA_A, SPRA_D,
	SPCOL,
	ROMAD,ROMDT,ROMEN
);

//----------------------------------------
//  Color mixer & Final output
//----------------------------------------
always @(posedge VCLKx8) if (VCLK_EN) PALT_A <= BGHI ? BGCOL : ((SPCOL[3:0]==4'd15) ? BGCOL : SPCOL );
assign POUT = oHB ? 8'd0 : PALT_D;
assign PCLK = VCLK;
assign PCLK_EN = VCLK_EN;

//----------------------------------------
//  ROMs
//----------------------------------------
dpram #(8,12) bgchr(.clk_a(VCLKx8), .addr_a(BGCH_A), .q_a(BGCH_D),
                    .clk_b(VCLKx8), .addr_b(ROMAD[11:0]), .we_b(ROMEN & (ROMAD[16:12]=={1'b1,4'h2})), .d_b(ROMDT));
dpram #(4,8) clut0(.clk_a(VCLKx8), .addr_a(CLT0_A^8'h03), .q_a(CLT0_D),
                   .clk_b(VCLKx8), .addr_b(ROMAD[7:0]), .we_b(ROMEN & (ROMAD[16:8]=={1'b1,8'h34})), .d_b(ROMDT[3:0]));
dpram #(8,5) pelet(.clk_a(VCLKx8), .addr_a(PALT_A), .q_a(PALT_D),
                   .clk_b(VCLKx8), .addr_b(ROMAD[4:0]), .we_b(ROMEN & (ROMAD[16:5]=={1'b1,8'h36,3'b000})), .d_b(ROMDT));
endmodule

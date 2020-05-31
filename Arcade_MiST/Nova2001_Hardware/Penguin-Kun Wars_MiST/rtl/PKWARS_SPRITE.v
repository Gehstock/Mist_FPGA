// Copyright (c) 2012,20 MiSTer-X 

module PKWARS_SP
(
	input				VCLKx4,
	input				VCLK,

	input   [8:0]	PH,
	input	  [8:0]	PV,

	output [10:0]	SPAAD,
	input   [7:0]	SPADT,

	output [13:0]	SPCAD,
	input  [31:0]	SPCDT,
	input				SPCFT,

	output  [3:0]	SPOUT
);

wire 		  WPEN;
wire [8:0] WPAD;
wire [7:0] WPIX;

reg  [7:0] POUT;
wire [3:0] OTHP = (POUT[3:0]==1) ? POUT[7:4] : POUT[3:0];

wire [8:0] WP = {1'b0,WPAD[7:0]};


wire [7:0] PO;
wire [9:0] rad = {~PV[0], PH};
reg  [9:0] pad = 1;
always @(posedge VCLK) begin
	if (pad!=rad) begin
		pad <= rad;
		POUT <= PO;
	end
end

LineDBuf ldbuf(
	 VCLKx4, rad, PO, (pad==rad),
	~VCLKx4, { PV[0], WP}, WPIX, WPEN
);

PKWARS_SPENG eng (
	VCLKx4, PH, PV,
	SPAAD, SPADT,
	SPCAD, SPCDT, SPCFT,
	 WPAD,  WPIX, WPEN
);

assign SPOUT = OTHP;

endmodule


module PKWARS_SPENG
(
	input				VCLKx4,

	input	 [8:0]	PH,
	input  [8:0]	PV,

	output [10:0]	SPAAD,
	input  [7:0]	SPADT,

	output [13:0]	SPCAD,
	input  [31:0]	SPCDT,
	input				SPCFT,

	output [8:0]	WPAD,
	output [7:0]	WPIX,
	output			WPEN
);

reg  [5:0] SPRNO;
reg  [1:0] SPRIX;
assign	  SPAAD = {SPRNO, 3'h0, SPRIX};

reg  [7:0] PTNO;
reg  [7:0] ATTR;
wire [3:0] PALNO = ATTR[7:4];
wire 		  FLIPH = PTNO[0];
wire 		  FLIPV = PTNO[1];
wire 		  XPOSH = 1'b0;
wire 		  DSABL = ATTR[3];

reg  [7:0] YPOS;
reg  [7:0] NV;
wire [7:0] HV   = NV-YPOS;
wire [3:0] LV   = {4{FLIPV}}^(HV[3:0]);
wire       YHIT = (HV[7:4]==4'b1111) & (~DSABL);

reg  [7:0] XPOS;
reg  [4:0] WP;
wire [3:0] WOFS = {4{FLIPH}}^(WP[3:0]);
assign 	  WPAD = {1'b0,XPOS}-{XPOSH,8'h0}+WOFS-1;
assign 	  WPEN = ~(WP[4]|(WPIX[3:0]==0));

reg		  CRS;
wire [8:0] PATNO = {ATTR[2:0],PTNO[7:2]};
assign	  SPCAD = {PATNO, LV[3], CRS, LV[2:0]};

function [3:0] XOUT;
input  [2:0] N;
input [31:0] CDT;
	case(N)
	 0: XOUT = CDT[7:4];
	 1: XOUT = CDT[3:0];
	 2: XOUT = CDT[15:12];
	 3: XOUT = CDT[11:8];
	 4: XOUT = CDT[23:20];
	 5: XOUT = CDT[19:16];
	 6: XOUT = CDT[31:28];
	 7: XOUT = CDT[27:24];
	endcase
endfunction
reg [31:0] CDT0, CDT1;
assign	  WPIX = {PALNO, XOUT(WP[2:0],WP[3] ? CDT1 : CDT0)};


`define WAIT	0
`define FETCH0	1
`define FETCH1	2
`define FETCH2	3
`define FETCH3	4
`define FETCH4	5
`define DRAW	6
`define NEXT	7

reg  [2:0] STATE;
always @( posedge VCLKx4 ) begin
	case (STATE)

	 `WAIT: begin
			WP <= 16;
			if (~PH[8]) begin
				NV <= PV+17;
				SPRNO <= 0;
				SPRIX <= 2;
				STATE <= `FETCH0;
			end
		end

	 `FETCH0: begin
			YPOS  <= SPADT;
			SPRIX <= 3;
			STATE <= `FETCH1;
		end
	 `FETCH1: begin
			ATTR   = SPADT; /* ATTR must block assign */
			SPRIX <= 0;
			STATE <= YHIT ? `FETCH2 : `NEXT;
		end

	 `FETCH2: begin
			PTNO  <= SPADT;
			SPRIX <= 1;
			STATE <= `FETCH3;
		end
	 `FETCH3: begin
		   if (SPCFT) begin		// Wait for CHRROM fetch cycle
				XPOS  <= SPADT;
				CRS   <= 0;
				STATE <= `FETCH4;
			end
		end
	 `FETCH4: begin
			if (SPCFT) begin		// Fetch CHRROM data (16pixels)
				if (~CRS) begin
					CDT0  <= SPCDT;
					CRS   <= 1;
				end
				else begin
					CDT1  <= SPCDT;
					WP    <= 0;
					STATE <= `DRAW;
				end
			end
		end

	 `DRAW: begin
			WP <= WP+1;
			if (WP[4]) STATE <= `NEXT;
 	   end

	 `NEXT: begin
			CDT0  <= 0; CDT1 <= 0;
			SPRNO <= SPRNO+1;
			SPRIX <= 2;
			STATE <= (SPRNO==63) ? `WAIT : `FETCH0;
	   end

	endcase
end

endmodule


module LineDBuf
(
	input 		 rC,
	input  [9:0] rA,
	output [7:0] rD,
	input			 rE,

	input			 wC,
	input	 [9:0] wA,
	input  [7:0] wD,
	input			 wE
);

DPRAM1024 mem(
	rA, wA,
	rC, wC,
	 0, wD,
	rE, wE,
	rD
);

endmodule

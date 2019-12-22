// Copyright (c) 2011 MiSTer-X

module NINJAKUN_ROMARB
(
	input					CLK,

	input	     [12:0]	FGCAD,
	output 	  [31:0]	FGCDT,

	input	     [12:0]	BGCAD,
	output 	  [31:0]	BGCDT,

	input	     [12:0]	SPCAD,
	output 	  [31:0]	SPCDT,

	output reg	[2:0]	PHASE,

	input	     [14:0]	CP0AD,
	output      [7:0]	CP0DT,

	input	     [14:0]	CP1AD,
	output      [7:0]	CP1DT
);

wire CL = ~CLK;

always @( posedge CL ) PHASE <= PHASE+1;

NJFGROM sprom( CL, SPCAD, SPCDT );
NJFGROM fgrom( CL, FGCAD, FGCDT );
NJBGROM bgrom( CL, BGCAD, BGCDT );

NJCPU0I cpu0i( CL, CP0AD, CP0DT );
NJCPU1I cpu1i( CL, {(CP1AD[14]|CP1AD[13]),CP1AD[12:0]}, CP1DT );

endmodule

module NINJAKUN_CPUMUX
(
	input				 CLK24M,
	input   [2:0]	 PHASE,

	input  [15:0]	 CP0AD,
	input   [7:0]	 CP0OD,
	output  [7:0]	 CP0ID,
	input    		 CP0RD,
	input    		 CP0WR,

	input  [15:0]	 CP1AD,
	input   [7:0]	 CP1OD,
	output  [7:0]	 CP1ID,
	input    		 CP1RD,
	input    		 CP1WR,

	output [15:0]	 CPADR,
	output  [7:0]	 CPODT,
	input	  [7:0]	 CPIDT,
	output  			 CPRED,
	output  			 CPWRT
);

reg CSIDE;
reg [7:0] CP0D, CP1D;
always @( posedge CLK24M ) begin
	case (PHASE)
		4: begin CP1D <= CPIDT; CSIDE <= 0; end
		0: begin CP0D <= CPIDT; CSIDE <= 1; end
		default:;
	endcase
end

assign CPADR = CSIDE ? CP1AD : CP0AD;
assign CPODT = CSIDE ? CP1OD : CP0OD;
assign CPRED = CSIDE ? CP1RD : CP0RD;
assign CPWRT = CSIDE ? CP1WR : CP0WR;

assign CP0ID = CSIDE ? CP0D  : CPIDT;
assign CP1ID = CSIDE ? CPIDT : CP1D;

endmodule

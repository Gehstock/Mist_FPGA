/*********************************************
   StarField Generator for "FPGA Gaplus"

				Copyright (c) 2007,2019 MiSTer-X
**********************************************/
module gaplus_stargen
(
	input       VCLK,
	input       RESET,

	input       VB,

	input [4:0]	C1,
	input [4:0]	C2,
	input [4:0]	C3,

	output reg [7:0] OUT
);

reg        vbtrig;

reg [11:0] sp1,  sp2,  sp3;
reg        sp1d, sp2d, sp3d;

reg [15:0] sLFSR1 = 16'hACE1, LFSR1;
reg [15:0] sLFSR2 = 16'hACE1, LFSR2;
reg [15:0] sLFSR3 = 16'hACE1, LFSR3;

wire [7:0] oSTAR1 = ( LFSR1[15:8] == 8'h80 ) ? LFSR1[7:0] : 0;
wire [7:0] oSTAR2 = ( LFSR2[15:8] == 8'h90 ) ? LFSR2[7:0] : 0;
wire [7:0] oSTAR3 = ( LFSR3[15:8] == 8'hA0 ) ? LFSR3[7:0] : 0;


function [15:0] LFSR;
input [15:0] in;
input			 dir;
	if ( dir ) LFSR = { in[14:0], ((in[15]^in[4])^in[2])^in[1] }; // backward
	else		  LFSR = { ((in[0]^in[2])^in[3])^in[5],  in[15:1] }; // forward
endfunction

always @ ( posedge VCLK or posedge RESET ) begin

	if ( RESET ) begin

		sLFSR1 <= 16'hACE1;
		sLFSR2 <= 16'hACE1;
		sLFSR3 <= 16'hACE1;

		OUT    <= 0;

		vbtrig <= 0;

	end
	else begin

		if ( VB & (~vbtrig) ) begin

			sp1 <= C1[4] ? (12'd384 * C1[2:0]) : C1[2:0]; sp1d <= C1[3];
			sp2 <= C2[4] ? (12'd384 * C2[2:0]) : C2[2:0]; sp2d <= C2[3];
			sp3 <= C3[4] ? (12'd384 * C3[2:0]) : C3[2:0]; sp3d <= C3[3];

			LFSR1 <= sLFSR1;
			LFSR2 <= sLFSR2;
			LFSR3 <= sLFSR3;

			vbtrig  <= 1;

		end
		else begin

			if ( ~VB ) begin
				OUT   <= ( oSTAR1 ? oSTAR1 : ( oSTAR2 ? oSTAR2 : oSTAR3 ) );

				LFSR1 <= LFSR(LFSR1,0);
				LFSR2 <= LFSR(LFSR2,0);
				LFSR3 <= LFSR(LFSR3,0);

				vbtrig <= 0;
			end

			if ( sp1 ) begin sLFSR1 <= LFSR(sLFSR1,~sp1d); sp1 <= sp1-1; end
			if ( sp2 ) begin sLFSR2 <= LFSR(sLFSR2,~sp2d); sp2 <= sp2-1; end
			if ( sp3 ) begin sLFSR3 <= LFSR(sLFSR3,~sp3d); sp3 <= sp3-1; end

		end

	end

end

endmodule


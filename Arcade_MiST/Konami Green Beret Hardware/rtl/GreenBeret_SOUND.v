/********************************************************
	FPGA Implimentation of "Green Beret"  (Sound Part)
*********************************************************/
// Copyright (c) 2013 MiSTer-X

module SOUND
(
	input				MCLK,
	input				reset,

	output  [7:0]	SNDOUT,

	input				CPUMX,
	input	 [15:0]	CPUAD,
	input				CPUWR,
	input	  [7:0]	CPUWD
);

wire CS_SNDLC = ( CPUAD[15:8] == 8'hF2 ) & CPUMX & CPUWR;
wire CS_SNDWR = ( CPUAD[15:8] == 8'hF4 ) & CPUMX;

reg [7:0] SNDLATCH;
always @( posedge MCLK or posedge reset ) begin
	if (reset) SNDLATCH <= 0;
	else begin
		if ( CS_SNDLC ) SNDLATCH <= CPUWD;
	end
end

wire sndclk, sndclk_en;
sndclkgen scgen( MCLK, sndclk, sndclk_en );

SN76496 sgn( MCLK, sndclk_en, reset, CS_SNDWR, CPUWR, SNDLATCH, 4'b1111, SNDOUT );

endmodule


/*
   Clock Generator
     in: 50000000Hz -> out: 1600000Hz
*/
module sndclkgen( input in, output reg out, output reg out_en );
reg [6:0] count;
always @( posedge in ) begin
				out_en <= 0;
        if (count > 7'd117) begin
                count <= count - 7'd117;
                out <= ~out;
								if (~out) out_en <= 1;
        end
        else count <= count + 7'd8;
end
endmodule

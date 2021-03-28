// Copyright (c) 2010 MiSTer-X

module SN76496
(
	input			     clk,
	input				  cpuclk,
	input				  reset,
	input				  ce,
	input	 		     we,
	input	     [7:0] data,
	input      [3:0] chmsk,
	output reg [7:0] sndout,
	output reg [3:0] chactv,
	output reg [2:0] lreg
);

`define RNGINI	16'h0F35
`define RNGFB0	16'h4000
`define RNGFB1 16'h8100

function [5:0] voltbl;
input [3:0] idx;
	case (idx)
	4'h0: voltbl = 63;
	4'h1: voltbl = 50;
	4'h2: voltbl = 40;
	4'h3: voltbl = 32;
	4'h4: voltbl = 25;
	4'h5: voltbl = 20;
	4'h6: voltbl = 16;
	4'h7: voltbl = 13;
	4'h8: voltbl = 10;
	4'h9: voltbl = 8;
	4'hA: voltbl = 6;
	4'hB: voltbl = 5;
	4'hC: voltbl = 4;
	4'hD: voltbl = 3;
	4'hE: voltbl = 2;
	4'hF: voltbl = 0;
	endcase
endfunction

reg  [3:0]	clks;

reg  [2:0]	nzc;
reg  [9:0]	fq0, fq1, fq2;
reg  [9:0]	fc0, fc1, fc2;
reg  [5:0]	fv0, fv1, fv2, fv3;
reg  [5:0] _fv0,_fv1,_fv2,_fv3;
reg			fo0, fo1, fo2;

reg  [15:0] rng = `RNGINI;
wire [15:0] rfb = rng[0] ? ( nzc[2] ? `RNGFB1 : `RNGFB0 ) : 16'h0;

wire  [1:0] nfq = nzc[1:0];
wire [10:0] fq3 = ( nfq == 2'b00 ) ? 11'd64  :
				 	   ( nfq == 2'b01 ) ? 11'd128 :
					   ( nfq == 2'b10 ) ? 11'd256 : fq2;
reg  [10:0] fc3;
wire			fo3 = rng[0];

wire [7:0]	o0 = ( fo0 & chmsk[0] ) ? { 1'b0, fv0, 1'b0 } : 8'h0;
wire [7:0]	o1 = ( fo1 & chmsk[1] ) ? { 1'b0, fv1, 1'b0 } : 8'h0;
wire [7:0]	o2 = ( fo2 & chmsk[2] ) ? { 1'b0, fv2, 1'b0 } : 8'h0;
wire [7:0]	o3 = ( fo3 & chmsk[3] ) ? { 1'b0, fv3, 1'b0 } : 8'h0;

wire [8:0]	sndmix = o0 + o1 + o2 + o3;

always @( posedge cpuclk or posedge reset ) begin
	if ( reset ) begin
		lreg <= 0;
		_fv0 <= 0;
		_fv1 <= 0;
		_fv2 <= 0;
		_fv3 <= 0;
		fq0 <= 0;
		fq1 <= 0;
		fq2 <= 0;
		nzc <= 0;
		chactv <= 0;
	end
	else begin
		// Register write
		if ( ce & we ) begin
			if ( data[7] ) begin
				lreg <= data[6:4];
				case ( data[6:4] )
				3'h0: fq0[3:0] <= data[3:0]; 
				3'h2: fq1[3:0] <= data[3:0]; 
				3'h4: fq2[3:0] <= data[3:0]; 
				3'h1: begin _fv0 <= voltbl(data[3:0]); chactv[0] <= (~data[3]); end
				3'h3: begin _fv1 <= voltbl(data[3:0]); chactv[1] <= (~data[3]); end
				3'h5: begin _fv2 <= voltbl(data[3:0]); chactv[2] <= (~data[3]); end
				3'h7: begin _fv3 <= voltbl(data[3:0]); chactv[3] <= (~data[3]); end
				3'h6: begin nzc <= data[2:0]; end
				endcase
			end
			else begin
				case ( lreg )
				3'h0: fq0[9:4] <= data[5:0]; 
				3'h2: fq1[9:4] <= data[5:0]; 
				3'h4: fq2[9:4] <= data[5:0]; 
				default: begin end
				endcase
			end
		end
	end
end
	

always @( posedge clk or posedge reset ) begin
	// Reset
	if ( reset ) begin
		sndout <= 0;
		fv0 <= 0;
		fv1 <= 0;
		fv2 <= 0;
		fv3 <= 0;
		fc0 <= 0;
		fc1 <= 0;
		fc2 <= 0;
		fc3 <= 0;
		fo0 <= 0;
		fo1 <= 0;
		fo2 <= 0;
		clks <= 0;
		rng  <= `RNGINI;
	end
	else begin

		// OSCs update
		clks <= clks+3'd1;
		if ( clks == 0 ) begin

			fv0 <= _fv0;
			fv1 <= _fv1;
			fv2 <= _fv2;
			fv3 <= _fv3;

			if ( fc0 == 0 ) begin
				fc0 <=  fq0;
				fo0 <= ~fo0;
			end
			else fc0 <= fc0-10'd1;
			
			if ( fc1 == 0 ) begin
				fc1 <=  fq1;
				fo1 <= ~fo1;
			end
			else fc1 <= fc1-10'd1;

			if ( fc2 == 0 ) begin
				fc2 <=  fq2;
				fo2 <= ~fo2;
			end
			else fc2 <= fc2-10'd1;

			// NoiseGen update
			if ( fc3 == 0 ) begin
				fc3 <= fq3;
				rng <= { 1'b0, rng[15:1] } ^ rfb;
			end
			else fc3 <= fc3-11'd1;

			// Sound update
			sndout <= {8{sndmix[8]}}|(sndmix[7:0]);

		end

	end

end

endmodule

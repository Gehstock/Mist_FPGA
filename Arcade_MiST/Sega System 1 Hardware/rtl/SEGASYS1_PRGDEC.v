// Copyright (c) 2017,19 MiSTer-X

`define DECTBLADRS	(25'h60400)

`define EN_DEC1TBL	(ROMAD[18:7]==12'b110_0000_0100_0)	// $60400

`define EN_DEC2XOR	(ROMAD[18:7]==12'b110_0000_0100_0) 	// $60400
`define EN_DEC2SWP	(ROMAD[18:7]==12'b110_0000_0100_1)	// $60480


module SEGASYS1_PRGDEC
(
	input 				clk,

	input					mrom_m1,		// connect to CPU
	input     [14:0]	mrom_ad,
	output     [7:0]	mrom_dt,

	output    [14:0]	rad,			// connect to ROM
	input		  [7:0]	rdt,

	input					ROMCL,		// Downloaded ROM image
	input     [24:0]	ROMAD,
	input	     [7:0]	ROMDT,
	input					ROMEN
);

wire  [7:0] od0,od1;
wire [14:0] dum;

SEGASYS1_DECT1 t1(clk,mrom_m1,mrom_ad, od0, rad,rdt, ROMCL,ROMAD,ROMDT,ROMEN);
SEGASYS1_DECT2 t2(clk,mrom_m1,mrom_ad, od1, dum,rdt, ROMCL,ROMAD,ROMDT,ROMEN);

// Type Detect and switch
reg [15:0] cnt0,cnt2;
always @(posedge ROMCL) begin
	if (ROMEN) begin
		if (ROMAD>=`DECTBLADRS) begin
			cnt2 <= (ROMDT>=8'd24) ? 16'd0 : (cnt2+1'd1);
			cnt0 <= (ROMDT!=8'd0 ) ? 16'd0 : (cnt0+1'd1);
		end
		else begin
			cnt2 <= 0;
			cnt0 <= 0;
		end
	end
end
assign mrom_dt = (cnt0>=128) ? rdt : (cnt2>=128) ? od1 : od0;

endmodule


//----------------------------------------
//  Program ROM Decryptor (Type 1)
//----------------------------------------
module SEGASYS1_DECT1
(
	input 				clk,

	input					mrom_m1,		// connect to CPU
	input     [14:0]	mrom_ad,
	output reg [7:0]	mrom_dt,

	output    [14:0]	rad,			// connect to ROM
	input		  [7:0]	rdt,

	input					ROMCL,		// Downloaded ROM image
	input     [24:0]	ROMAD,
	input	     [7:0]	ROMDT,
	input					ROMEN
);

reg  [15:0] madr;
wire  [7:0] mdat = rdt;

wire			f		  = mdat[7];
wire  [7:0] xorv    = { f, 1'b0, f, 1'b0, f, 3'b000 }; 
wire  [7:0] andv    = ~(8'hA8);
wire  [1:0] decidx0 = { mdat[5],  mdat[3] } ^ { f, f };
wire  [6:0] decidx  = { madr[12], madr[8], madr[4], madr[0], ~madr[15], decidx0 };
wire  [7:0] dectbl;
wire  [7:0] mdec    = ( mdat & andv ) | ( dectbl ^ xorv );

DLROM #(7,8) dect( clk, decidx, dectbl, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC1TBL );

reg phase = 1'b0;
always @( negedge clk ) begin
	if ( phase ) mrom_dt <= mdec;
	else madr <= { mrom_m1, mrom_ad };
	phase <= ~phase;
end

assign rad = madr[14:0];

endmodule


//----------------------------------------
//  Program ROM Decryptor (Type 2)
//----------------------------------------
module SEGASYS1_DECT2
(
	input 				clk,

	input					mrom_m1,		// connect to CPU
	input     [14:0]	mrom_ad,
	output reg [7:0]	mrom_dt,

	output    [14:0]	rad,			// connect to ROM
	input		  [7:0]	rdt,

	input					ROMCL,		// Downloaded ROM image
	input     [24:0]	ROMAD,
	input	     [7:0]	ROMDT,
	input					ROMEN
);

`define bsw(A,B,C,D)	{v[7],v[A],v[5],v[B],v[3],v[C],v[1],v[D]}

function [7:0] bswp;
input [4:0] m;
input [7:0] v;

   case (m)

	  0: bswp = `bsw(6,4,2,0);
	  1: bswp = `bsw(4,6,2,0);
     2: bswp = `bsw(2,4,6,0);
     3: bswp = `bsw(0,4,2,6);
	  4: bswp = `bsw(6,2,4,0);
     5: bswp = `bsw(6,0,2,4);
     6: bswp = `bsw(6,4,0,2);
	  7: bswp = `bsw(2,6,4,0);
	  8: bswp = `bsw(4,2,6,0);
     9: bswp = `bsw(4,6,0,2);
    10: bswp = `bsw(6,0,4,2);
    11: bswp = `bsw(0,6,4,2);
	 12: bswp = `bsw(4,0,6,2);
    13: bswp = `bsw(0,4,6,2);
    14: bswp = `bsw(6,2,0,4);
    15: bswp = `bsw(2,6,0,4);
    16: bswp = `bsw(0,6,2,4);
    17: bswp = `bsw(2,0,6,4);
    18: bswp = `bsw(0,2,6,4);
    19: bswp = `bsw(4,2,0,6);
	 20: bswp = `bsw(2,4,0,6);
    21: bswp = `bsw(4,0,2,6);
    22: bswp = `bsw(2,0,4,6);
    23: bswp = `bsw(0,2,4,6);

    default: bswp = 0;
   endcase

endfunction

reg [15:0] madr;

wire [7:0] sd,xd;
wire [6:0] ix = {madr[14],madr[12],madr[9],madr[6],madr[3],madr[0],~madr[15]};

DLROM #(7,8) xort(clk,ix,xd, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC2XOR);
DLROM #(7,8) swpt(clk,ix,sd, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC2SWP);

reg phase = 1'b0;
always @( negedge clk ) begin
	if ( phase ) mrom_dt <= (bswp(sd,rdt) ^ xd);
	else madr <= { mrom_m1, mrom_ad };
	phase <= ~phase;
end

assign rad = madr[14:0];

endmodule


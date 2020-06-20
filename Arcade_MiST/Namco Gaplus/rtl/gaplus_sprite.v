/**********************************************
   Sprite Engine for "FPGA Gaplus"

				Copyright (c) 2007,2019 MiSTer-X
***********************************************/
module gaplus_sprite
(
	input         VCLKx4,
	input         VCLK,

	input  [8:0]  HPOS,
	input  [8:0]  VPOS,

	input         HB,
	input			  VB,

	output [14:0] SPCH_A,
	input  [15:0] SPCH_D,

	output [6:0]  SPRA_A,
	input  [23:0] SPRA_D,

	output [8:0]  CLUT_A
);

wire wwclk, wrwe, vpr;
wire [5:0]  wrwad;
wire [28:0] wrwd0;
wire [23:0] wrwd1;

wire wrclk, lwe, vpw;
wire [5:0]  wrrad;
wire [28:0] spra0;
wire [23:0] spra1;
wire [8:0]  lwp;
wire [8:0]  lwd;

wire [8:0]	dout;

GAPLUS_SPRITE_REGSCAN scan( VCLKx4, HB, VPOS, SPRA_A, SPRA_D, wwclk, wrwad, wrwd0, wrwd1, wrwe, vpr ); 
GAPLUS_SPRITE_WRAM    wram( wwclk, wrwad, wrwd0, wrwd1, wrwe, wrclk, wrrad, spra0, spra1 );
GAPLUS_SPRITE_REND    rend( VCLK, HB, vpr, spra0, spra1, wrclk, wrrad, SPCH_A, SPCH_D, vpw, lwp, lwd, lwe );
GAPLUS_SPRITE_LBUF    lbuf( VCLK, vpw, lwe, lwp, lwd, HPOS, dout );

assign CLUT_A = dout;

endmodule


//----------------------------------------
//  Scanline Renderer
//----------------------------------------
module GAPLUS_SPRITE_REND
(
	input         VCLK,
	input         HB,
	input         vpr,
	input  [28:0] spra0,
	input  [23:0] spra1,
	output        wrclk,
	output  [5:0] wrrad,
	output [14:0] SPCH_A,
	input  [15:0] SPCH_D,

	output        vpw,
	output  [8:0] wp,
	output  [8:0] wd,
	output        we
);

reg  [7:0] phase;
reg  [5:0] hc;

wire       xf = spra0[16];
wire       yf = spra0[17];

wire       xs = spra0[19];
wire       ys = spra0[21];

wire       dp = spra0[23];

wire [1:0] coffs  = dp ? 0 : { (~spra0[28])^((~yf)&ys), hc[4]^(xf&xs) };

wire [8:0] chipno = { spra0[22], spra0[7:0] } + { 7'h0, coffs };
wire [5:0] paltno = { spra1[5:0] };

wire [3:0] va = spra0[27:24]^{yf,yf,yf,yf};
wire [1:0] pdp = ( hc[1:0]^{xf,xf} );

wire [2:0] pixd = ( pdp == 0 ) ? { chipno[7] ? SPCH_D[11] : SPCH_D[15], SPCH_D[7], SPCH_D[3] } :
						( pdp == 1 ) ? { chipno[7] ? SPCH_D[10] : SPCH_D[14], SPCH_D[6], SPCH_D[2] } :
						( pdp == 2 ) ? { chipno[7] ? SPCH_D[ 9] : SPCH_D[13], SPCH_D[5], SPCH_D[1] } :
											{ chipno[7] ? SPCH_D[ 8] : SPCH_D[12], SPCH_D[4], SPCH_D[0] };

assign		we = xs ? ( hc < 32 ) : ( hc < 16 );
assign		wd = { paltno, pixd };

reg hbedge2;
always @ ( posedge VCLK ) begin
	if ( HB & (~hbedge2) ) begin
		phase <= 0;
		hbedge2 <= 1;
	end
	else begin
		if (~HB) hbedge2 <= 0;
		if (~phase[7]) begin
			case ( phase[1:0] )
				2'h0: begin
					hc    <= 0;
					phase <= phase + 1;
				end
				2'h1: phase <= phase + 1;
				2'h2: if (~we) phase <= phase + 2; else hc <= hc + 1;
				default: begin end
			endcase
		end
	end

end

assign 		wrclk  = VCLK;
assign 		wrrad  = { vpr, phase[6:2] };
assign      SPCH_A = { chipno, va[3], hc[3:2]^{2{xf}}, va[2:0] };

assign      vpw = ~vpr;
assign		wp = ( spra1[16:8] - 88 ) + hc;

endmodule

//----------------------------------------
//  Attribute Register Scanner
//----------------------------------------
module GAPLUS_SPRITE_REGSCAN
(
	input			  VCLKx4,
	input         HB,
	input  [7:0]  VPOS,
	output [6:0]  SPRA_A,
	input [23:0]  SPRA_D,
	output		  wwclk,
	output [5:0]  wrwad,
	output [28:0] wrwd0,
	output [23:0] wrwd1,
	output        wrwe,
	output        vpr
); 

reg [11:0] hcntx4;
reg        hbedge, vpf;

always @ ( posedge VCLKx4 ) begin

	if ( HB & (~hbedge) ) begin
		hcntx4 <= 0;
		vpf <= ~vpf;
		hbedge <= 1;
	end else begin
		if (~HB) hbedge <= 0;
		hcntx4 <= hcntx4 + 1;
	end

end

assign vpr =  vpf;
wire   vpw = ~vpf;

reg [23:0] nspra0;
reg [23:0] nspra1;

reg  [7:0] nvpos;
reg  [5:0] hramad;

reg        wrwe0;

//wire [8:0] nxt = nspra1[16:8] - 87;
wire [7:0] nyt = nspra0[15:8] + 27;

wire       nys = nspra0[21];
wire [7:0] nvt = nvpos + nyt;
wire       nvh = nys ? ( nvt[7:5] == 3'b111 ) : ( nvt[7:4] == 4'b1111 );

wire       son = (~nspra1[17]) & ( nspra0[15:8] != 8'hF0 ) & ( nspra1[16:8] != 9'h00 );

wire [11:0] _hcntx4 = hcntx4 - 32;

wire			wrclr = ( hcntx4 < 32 );
assign 		wwclk = VCLKx4;
assign		wrwd0 = wrclr ? 0 : { nvt[4:0], nspra0 };
assign		wrwd1 = wrclr ? 0 : nspra1;
assign		wrwad = wrclr ? { vpw, hcntx4[4:0] } : { vpw, hramad[4:0] };
assign       wrwe = wrclr ? 1 : wrwe0;

always @ ( posedge VCLKx4 ) begin

	if ( hcntx4 == 0 ) begin
		hramad <= 0;
		nvpos <= VPOS[7:0];
		wrwe0 <= 0;
	end
	else begin
		if ( ( hcntx4 < 544 ) & ( hramad < 32 ) ) begin
			case ( hcntx4[2:0] )
				3'h0: nspra0 <= SPRA_D;
				3'h1: nspra1 <= SPRA_D;
				3'h4: wrwe0  <= nvh & son;
				3'h5: begin
					if ( wrwe0 ) hramad <= hramad + 1;
					wrwe0 <= 0;
				end
				default: begin end
			endcase
		end
	end
end

assign SPRA_A = { _hcntx4[8:3], _hcntx4[0] };

endmodule

//----------------------------------------
//  Work RAM
//----------------------------------------
module GAPLUS_SPRITE_WRAM( CLKw, ADRSw, Dw0, Dw1, we, CLKr, ADRSr, Dr0, Dr1 );

input				CLKw;
input [5:0]		ADRSw;
input	[28:0]	Dw0;
input	[23:0]	Dw1;
input				we;

input				CLKr;
input  [5:0]	ADRSr;
output [28:0]	Dr0;
output [23:0]	Dr1;

BUF64_53 mem (
	{Dw1,Dw0},ADRSr,CLKr,
	ADRSw,CLKw,we,{Dr1,Dr0}
);

endmodule


//----------------------------------------
//  Line Double Buffer
//----------------------------------------
module GAPLUS_SPRITE_LBUF( CLK, SIDE1, WEN, ADRSW, IN, ADRSR, OUT );

input				CLK;
input				SIDE1;
input				WEN;
input		[8:0]	ADRSW;
input		[8:0]	IN;
input		[8:0]	ADRSR;
output	[8:0]	OUT;

wire		[8:0]	OUT0, OUT1;

wire				SIDE0  = ~SIDE1;
wire				OPAQUE = ( IN[2:0] != 0 );

assign			OUT = SIDE1 ? OUT1 : OUT0;

LINEBUF	buf0( CLK, SIDE0 ? 1 : ( WEN & SIDE1 & OPAQUE ), SIDE0 ? ADRSR-1 : ADRSW, SIDE0 ? 0 : IN, CLK, SIDE0, ADRSR, OUT0 );
LINEBUF	buf1( CLK, SIDE1 ? 1 : ( WEN & SIDE0 & OPAQUE ), SIDE1 ? ADRSR-1 : ADRSW, SIDE1 ? 0 : IN, CLK, SIDE1, ADRSR, OUT1 );

endmodule


module LINEBUF( CLKW, WEN, ADRSW, IN, CLKR, REN, ADRSR, OUT );

input				CLKW;
input				WEN;
input		[8:0]	ADRSW;
input		[8:0]	IN;
input				CLKR;
input				REN;
input		[8:0]	ADRSR;
output	[8:0]	OUT;

wire [8:0] dum;

LBUF512_9 mem (
	ADRSR,ADRSW,
	CLKR,CLKW,
	9'h0,IN,
	REN,1'b0,
	1'b0,WEN,
	OUT,dum
);


endmodule


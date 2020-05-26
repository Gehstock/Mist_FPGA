// Copyright (c) 2017,19 MiSTer-X

`define DECTBLADRS	(25'h2E100)

`define EN_DEC1TBL	(dl_addr[17:7]==11'b10111000010;//2E100	 

`define EN_DEC2XOR	(dl_addr[17:7]==11'b10111000010;//2E100
`define EN_DEC2SWP	(dl_addr[17:7]==11'b10111000011;//2E180

module System1_Decoder
(
	input 				clk,

	input					mrom_m1,		// connect to CPU
	input     [14:0]	mrom_ad,
	output     [7:0]	mrom_dt,

	output    [14:0]	rad,			// connect to ROM
	input		  [7:0]	rdt,

	input   [17:0] dl_addr,
	input	  [7:0]	dl_data,
	input				dl_wr,
	input				dl_clk
);

wire  [7:0] od0,od1;
wire [14:0] dum;

SEGASYS1_DECT1 t1(clk,mrom_m1,mrom_ad, od0, rad,rdt, dl_addr,dl_data,dl_wr,dl_clk);
SEGASYS1_DECT2 t2(clk,mrom_m1,mrom_ad, od1, dum,rdt, dl_addr,dl_data,dl_wr,dl_clk);

// Type Detect and switch
reg [15:0] cnt0,cnt2;
always @(posedge dl_clk) begin
	if (~dl_wr) begin
		if (dl_addr>=`DECTBLADRS) begin
			cnt2 <= (dl_data>=8'd24) ? 0 : (cnt2+1);
			cnt0 <= (dl_data!=8'd0 ) ? 0 : (cnt0+1);
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

	input   [17:0] dl_addr,
	input	  [7:0]	dl_data,
	input				dl_wr,
	input				dl_clk
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

//DLROM #(7,8) dect( clk, decidx, dectbl, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC1TBL );
wire dec_we = dl_addr[17:7] == 11'b10111000010;//2E100
dpram#(8,7)decrom(
	.clk_a(clk),
	.addr_a(decidx),
	.q_a(dectbl),
	.clk_b(dl_clk),
	.addr_b(dl_addr[6:0]),
	.we_b(dec_we & dl_wr),
	.d_b(dl_data)
	);
	
assign rad = madr[14:0];
assign mdat = rdt;	
	
reg phase = 1'b0;
always @( negedge clk ) begin
	if ( phase ) mrom_dt <= mdec;
	else madr <= { mrom_m1, mrom_ad };
	phase <= ~phase;
end

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

	input   [17:0] dl_addr,
	input	  [7:0]	dl_data,
	input				dl_wr,
	input				dl_clk
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

//DLROM #(7,8) xort(clk,ix,xd, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC2XOR);
wire dec_we = dl_addr[17:7] == 11'b10111000010;//2E100
dpram#(8,7)decrom(
	.clk_a(clk),
	.addr_a(ix),
	.q_a(xd),
	.clk_b(dl_clk),
	.addr_b(dl_addr[6:0]),
	.we_b(dec_we & dl_wr),
	.d_b(dl_data)
	);
	
assign rad = madr[14:0];
//assign mdat = rdt;		
	
//DLROM #(7,8) swpt(clk,ix,sd, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC2SWP);
wire dec2_we = dl_addr[17:7] == 11'b10111000011;//2E180 10 1110 0001 1000 0000
dpram#(8,7)decrom2(
	.clk_a(clk),
	.addr_a(ix),
	.q_a(sd),
	.clk_b(dl_clk),
	.addr_b(dl_addr[6:0]),
	.we_b(dec2_we & dl_wr),
	.d_b(dl_data)
	);
	
reg phase = 1'b0;
always @( negedge clk ) begin
	if ( phase ) mrom_dt <= (bswp(sd,rdt) ^ xd);
	else madr <= { mrom_m1, mrom_ad };
	phase <= ~phase;
end

endmodule


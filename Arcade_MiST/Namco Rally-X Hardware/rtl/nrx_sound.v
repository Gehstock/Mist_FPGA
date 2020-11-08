/**************************************************************
	FPGA New Rally-X (Sound Part)
***************************************************************/


module nrx_sound
(
	input					CLK24M,
	output reg [7:0]	SND,
	input	 [15:0]	AD,
	input  [3:0]	DI,
	input				WR,

	input				BANG,

	input         ROMCL,
	input  [15:0] ROMAD,
	input   [7:0] ROMDT,
	input         ROMEN
);

reg [11:0] ccnt;
always @( posedge CLK24M ) ccnt <= ccnt+1;

wire	CLK6K   = ccnt[11];
wire  SCLKx8  = ccnt[4];
wire	SCLK    = ccnt[7];

wire  [7:0]		wa0, wa1, wa2;
wire  [3:0]		wd0, wd1, wd2;

NPSG_WAV waverom(
        SCLKx8, wa0, wa1, wa2, wd0, wd1, wd2,
        ROMCL,ROMAD[7:0],ROMDT[3:0],ROMEN & (ROMAD[15:8]==8'hA1)
);

reg		  		bWavPlay = 1'b0;
reg  [13:0] 	wap = 14'h0000;
wire  [7:0] 	wdp;
wire  [7:0]		wo = bWavPlay ? wdp : 8'h80;

dpram #(8,14) bangpcm(
	.clk_a(CLK6K),
	.addr_a(wap),
	.we_a(1'b0),
	.d_a(),
	.q_a(wdp),

	.clk_b(ROMCL),
	.addr_b(ROMAD[13:0]),
	.d_b(ROMDT),
	.we_b(ROMEN & (ROMAD[15:14]==2'b01)),
	.q_b()
	);

always @( posedge CLK6K ) begin
	if ( BANG && (~bWavPlay) ) bWavPlay <= 1'b1;
	if ( bWavPlay ) begin
		wap <= wap+1;
		if ( wap == 14'h29FF ) begin
			wap <= 14'h0000;
			bWavPlay <= 1'b0;
		end
	end
end

reg	[19:0]	f0;
reg	[15:0]	fq1, fq2;
reg	[3:0]		v0, v1, v2;
reg	[2:0]		n0, n1, n2;

wire	[19:0]	f1 = { fq1, 4'b0000 };
wire	[19:0]	f2 = { fq2, 4'b0000 };

wire	[3:0]		o0,  o1,  o2;

nrx_psg_voice voice0( 
	.clk(SCLK), 
	.out(o0), 
	.freq(f0), 
	.vol(v0), 
	.vn(n0), 
	.waveaddr(wa0), 
	.wavedata(wd0) 
	);
	
nrx_psg_voice voice1( 
	.clk(SCLK), 
	.out(o1), 
	.freq(f1), 
	.vol(v1), 
	.vn(n1), 
	.waveaddr(wa1), 
	.wavedata(wd1) 
	);

nrx_psg_voice voice2( 
	.clk(SCLK), 
	.out(o2), 
	.freq(f2), 
	.vol(v2), 
	.vn(n2), 
	.waveaddr(wa2), 
	.wavedata(wd2) 
	);	

reg [7:0] wout;
always @( posedge SCLK ) SND <= ( { 2'b0, wo } ) + ( o0 + o1 + o2 );

always @( posedge CLK24M ) begin
	if ( WR ) case ( AD[4:0] )

		5'h05:	n0         <= DI[2:0];
		5'h0A:	n1         <= DI[2:0];
		5'h0F:	n2         <= DI[2:0];

		5'h10:	f0[3:0]    <= DI;
		5'h11:	f0[7:4]    <= DI;
		5'h12:	f0[11:8]   <= DI;
		5'h13:	f0[15:12]  <= DI;
		5'h14:	f0[19:16]  <= DI;
		5'h15:   v0         <= DI;

		5'h16:	fq1[3:0]   <= DI;
		5'h17:	fq1[7:4]   <= DI;
		5'h18:	fq1[11:8]  <= DI;
		5'h19:	fq1[15:12] <= DI;
		5'h1A:   v1         <= DI;

		5'h1B:	fq2[3:0]   <= DI;
		5'h1C:	fq2[7:4]   <= DI;
		5'h1D:	fq2[11:8]  <= DI;
		5'h1E:	fq2[15:12] <= DI;
		5'h1F:   v2         <= DI;

		default: ;

	endcase
end

endmodule

module NPSG_WAV
(
        input                   clk,
        input [7:0] a0,
        input   [7:0] a1,
        input   [7:0] a2,
                
        output reg [3:0] d0,
        output reg [3:0] d1,
        output reg [3:0] d2,
        
        input                    ROMCL,
        input  [7:0] ROMAD,
        input  [3:0] ROMDT,
        input            ROMEN
);

reg  [1:0] ph=0;

reg  [7:0] ad;  
wire [3:0] dt;

dpram #(4,8) wrom(
	.clk_a(clk),
	.addr_a(ad),
	.we_a(1'b0),
	.d_a(),
	.q_a(dt),

	.clk_b(ROMCL),
	.addr_b(ROMAD),
	.we_b(ROMEN),
	.d_b(ROMDT),
	.q_b()
	);

always @(negedge clk) begin
        case (ph)
        0: begin d2 <= dt; ad <= a0; ph <= 1; end
        1: begin d0 <= dt; ad <= a1; ph <= 2; end
        2: begin d1 <= dt; ad <= a2; ph <= 0; end
        default:;
        endcase
end

endmodule
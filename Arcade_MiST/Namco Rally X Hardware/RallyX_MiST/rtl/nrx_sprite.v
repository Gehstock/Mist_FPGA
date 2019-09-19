
module NRX_SPRITE
(
	input					VCLKx4,
	input					HBLK,

	input	 [8:0]		HPOS,
	input	 [8:0]		VPOS,

	output reg [10:0]	SPRAADRS,
	input  [15:0]		SPRADATA,

	output [3:0]		ARAMADRS,
	input	 [7:0]		ARAMDATA,

	output [11:0]		SPCHRADR,
	input	 [7:0]		SPCHRDAT,

	output [7:0]		DROMAD,
	input  [7:0]		DROMDT,

	output reg [8:0]	SPCOL
);

reg [1:0] clkcnt;
always @( posedge VCLKx4 ) clkcnt<=clkcnt+1;
wire VCLKx2 = clkcnt[0];
wire VCLK	= clkcnt[1];

wire SIDE = VPOS[0];


reg  [19:0] SPATR0;
reg  [36:0] SPATRS[0:31];
reg	[3:0] WWADR;
reg			bHit;

assign ARAMADRS = SPRAADRS[3:0];


reg	[7:0] WRADR;
reg	[8:0] HPOSW;
reg	[8:0] SPWCL;

wire [36:0] SPA  = SPATRS[{~SIDE,WRADR[7:4]}];

wire	[3:0] SH	 = WRADR[3:0]+4'h4;
wire	[3:0] SV	 = SPA[35:32];

wire	[2:0] SPFY = { 3{SPA[1]} };
wire	[1:0] SPFX = { 1'b0, SPA[0] };
wire	[5:0] SPPL = SPA[29:24];

assign SPCHRADR  = { SPA[7:2], ( SV[3] ^ SPA[1] ), ( SH[3:2] ^ SPFX ), ( SV[2:0] ^ SPFY ) };
wire	[7:0] CHRO = SPCHRDAT;


wire	[8:0] YM =  ( SPRADATA[15:8] + 8'h10 ) + VPOS[7:0];

assign DROMAD = { 1'b0, (~SPA[19:17]), SPA[33:32], WRADR[3:2] };

always @ ( posedge VCLKx2 ) begin

	// in H-BLANK
	if ( HBLK ) begin

		// Sprite V-hit check & list-up
		if ( SPRAADRS < 10'h20 ) begin
			if ( SPRAADRS[0] ) begin
				if ( bHit ) begin
					SPATRS[{SIDE,WWADR}] <= { 1'b1, SPATR0[3:0], SPRADATA, SPATR0[19:4] };
					WWADR <= WWADR+1;
				end
			end
			else begin
				if ( YM[7:4] == 4'b1111 ) begin
					bHit	<= 1;
					SPATR0 <= { SPRADATA, YM[3:0] };
				end
				else bHit <= 0;
			end
			SPRAADRS <= ( SPRAADRS == 10'h1F ) ? 10'h34 : (SPRAADRS+1);
		end
		// Rader-dot V-hit check & list-up
		else begin
			if ( SPRAADRS < 10'h40 ) begin
				if ( YM[7:2] == 6'b111111 ) begin
					SPATRS[{SIDE,WWADR}] <= { 1'b0, 2'b00, YM[1:0], 8'h0, ARAMDATA, SPRADATA };
					WWADR <= WWADR+1;
				end
				SPRAADRS <= SPRAADRS+1;
			end
			else SPATRS[{SIDE,WWADR}] <= 0;
		end

		if ( SPA ) begin
			// Rend Sprite
			if ( SPA[36] ) begin
				HPOSW <= ( WRADR[3:0] ) ? (HPOSW+1) : { SPA[31], SPA[23:16] };
				case ( SH[1:0] ^ {2{SPFX[0]}} )
					2'b00: SPWCL <= { 1'b0, SPPL, CHRO[7], CHRO[3] };
					2'b01: SPWCL <= { 1'b0, SPPL, CHRO[6], CHRO[2] };
					2'b10: SPWCL <= { 1'b0, SPPL, CHRO[5], CHRO[1] };
					2'b11: SPWCL <= { 1'b0, SPPL, CHRO[4], CHRO[0] };
				endcase
				WRADR <= WRADR+1;
			end
			// Rend Rader-dot
			else begin
				HPOSW <= ( WRADR[3:0] ) ? (HPOSW+1) : ({ (~SPA[16]), SPA[7:0] });
				SPWCL <= ( DROMDT[1:0] != 2'b11 ) ? { 1'b1, 6'b000100, DROMDT[1:0] } : 0;
				WRADR <= WRADR+4;
			end
		end
		else SPWCL <= 0;

	end

	// in H-DISP
	else begin
		SPRAADRS <= 10'h14;
		WWADR <= 0;
		WRADR <= 0;
		SPWCL <= 0;
	end

end


reg  [9:0] radr0=0,radr1=1;
wire [8:0] SPCOLi;

LINEBUF1024_9 linedbuf(VCLKx2,{SIDE,HPOS},(radr0==radr1),SPCOLi, VCLKx2,{~SIDE,HPOSW},(SPWCL[0]|SPWCL[1]),SPWCL);
//GLINEBUF #(10,9) linedbuf(VCLKx2,{SIDE,HPOS},(radr0==radr1),SPCOLi, VCLKx2,{~SIDE,HPOSW},(SPWCL[0]|SPWCL[1]),SPWCL);

always @(posedge VCLK) radr0 <= {SIDE,HPOS};
always @(negedge VCLK) begin 
	if (radr0!=radr1) SPCOL <= SPCOLi;
	radr1 <= radr0;
end

endmodule

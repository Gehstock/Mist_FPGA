
module NRX_SPRITE
(
	input             VCLKx4,
	input             VCLKx2_EN,
	input             VCLK_EN,
	input					    HBLK,
	input             mod_jungler,
	input             mod_loco,
	input             mod_tact,
	input             mod_comm,

	input       [8:0] HPOS,
	input       [8:0] VPOS,

	output reg [10:0] SPRAADRS,
	input      [15:0] SPRADATA,

	output      [3:0] ARAMADRS,
	input       [7:0] ARAMDATA,

	output     [12:0] SPCHRADR,
	input       [7:0] SPCHRDAT,

	output      [7:0] DROMAD,
	input       [7:0] DROMDT,

	output reg  [8:0] SPCOL
);

wire SIDE = VPOS[0];


reg  [19:0] SPATR0;
reg  [36:0] SPATRS[0:31];
reg   [3:0] WWADR;
reg         bHit;

assign ARAMADRS = SPRAADRS[3:0];

reg   [7:0] WRADR;
reg   [8:0] HPOSW;
reg   [8:0] SPWCL;

wire [36:0] SPA  = SPATRS[{~SIDE,WRADR[7:4]}];

wire  [3:0] SH   = WRADR[3:0] + (mod_jungler ? 4'h0 : 4'h4);
wire  [3:0] SV   = SPA[35:32];

wire  [2:0] SPFY = { 3{SPA[1]} };
wire  [1:0] SPFX = {2{mod_tact}} ^ { mod_loco ? ~SPA[1] : mod_jungler, mod_loco ? SPA[1] : SPA[0] };
wire  [5:0] SPPL = SPA[29:24];

assign SPCHRADR  = { mod_loco ? {SPA[7], SPA[0], SPA[6:2]} : {1'b0, SPA[7:2]},
                     mod_jungler ^ SV[3] ^ SPA[1],
										 SH[3:2] ^ SPFX,
										 {3{mod_jungler}} ^ SV[2:0] ^ SPFY };

wire	[7:0] CHRO = SPCHRDAT;


wire  [8:0] YM  = ((mod_jungler & ~mod_tact) ? (9'd258 - SPRADATA[15:8]) : (SPRADATA[15:8] + 8'h10)) + VPOS[7:0];
wire  [8:0] YM2 = ((mod_jungler & ~mod_tact) ? (9'd270 - SPRADATA[15:8]) : (SPRADATA[15:8] + 8'h10)) + VPOS[7:0];

assign DROMAD = { 1'b0, (mod_jungler ? ~SPA[18:16] : ~SPA[19:17]), SPA[33:32], WRADR[3:2] };

reg HBLK_D;

always @ ( posedge VCLKx4 ) begin

	HBLK_D <= HBLK;
	if (VCLKx2_EN) begin

	// in H-BLANK
	if (HBLK_D) begin

		// Sprite V-hit check & list-up
		if ( SPRAADRS < 10'h20 ) begin
			if ( SPRAADRS[0] ) begin
				if ( bHit ) begin
					SPATRS[{SIDE,WWADR}] <= { 1'b1, SPATR0[3:0], SPRADATA, SPATR0[19:4] };
					WWADR <= WWADR+1'd1;
				end
			end
			else begin
				if ( YM[7:4] == 4'b1111 ) begin
					bHit	<= 1;
					SPATR0 <= { SPRADATA, YM[3:0] };
				end
				else bHit <= 0;
			end
			SPRAADRS <= ( SPRAADRS == 10'h1F ) ? (mod_comm ? 10'h20 : 10'h34) : (SPRAADRS+1'd1);
		end
		// Rader-dot V-hit check & list-up
		else begin
			if ( SPRAADRS < 10'h40 ) begin
				if ( YM2[7:2] == 6'b111111 ) begin
					SPATRS[{SIDE,WWADR}] <= { 1'b0, 2'b00, YM2[1:0], 8'h0, ARAMDATA, SPRADATA };
					WWADR <= WWADR+1'd1;
				end
				SPRAADRS <= SPRAADRS+1'd1;
			end
			else SPATRS[{SIDE,WWADR}] <= 0;
		end

		if ( SPA ) begin
			// Rend Sprite
			if ( SPA[36] ) begin
				HPOSW <= WRADR[3:0] ? (HPOSW+1'd1) : ((mod_jungler & ~mod_tact) ? ((mod_loco ? 9'd242 : 9'd278)-{ SPA[31], SPA[23:16] }) : ({ SPA[31], SPA[23:16] } + 2'd3));

				case ({ mod_jungler, {2{mod_jungler}} ^ SH[1:0] ^ {2{SPFX[0]}} } )
					3'b000: SPWCL <= { 1'b0, SPPL, CHRO[7], CHRO[3] };
					3'b001: SPWCL <= { 1'b0, SPPL, CHRO[6], CHRO[2] };
					3'b010: SPWCL <= { 1'b0, SPPL, CHRO[5], CHRO[1] };
					3'b011: SPWCL <= { 1'b0, SPPL, CHRO[4], CHRO[0] };

					3'b100: SPWCL <= { 1'b0, SPPL, CHRO[3], CHRO[7] };
					3'b101: SPWCL <= { 1'b0, SPPL, CHRO[2], CHRO[6] };
					3'b110: SPWCL <= { 1'b0, SPPL, CHRO[1], CHRO[5] };
					3'b111: SPWCL <= { 1'b0, SPPL, CHRO[0], CHRO[4] };
				endcase
				WRADR <= WRADR+1'd1;
			end
			// Rend Rader-dot
			else begin
				HPOSW <=
					WRADR[3:0] ? 
						(HPOSW+1'd1) : 
						(mod_tact    ? { 1'b0,  SPA[7:0] } :
						 mod_loco    ? { 1'b0, ~SPA[7:0] } :
						 mod_jungler ? { SPA[19], ~SPA[7:0] + 8'd35 } :
						 ({ ~SPA[16], SPA[7:0] } + 2'd3));
				SPWCL <= ( DROMDT[1:0] != 2'b11 ) ? { 1'b1, 6'b000100, DROMDT[1:0] } : 9'd0;
				WRADR <= WRADR+4'd4;
			end
		end
		else SPWCL <= 0;

	end

	// in H-DISP
	else begin
		SPRAADRS <= mod_comm ? 10'h0 : 10'h14;
		WWADR <= 0;
		WRADR <= 0;
		SPWCL <= 0;
	end
	end
end


reg  [9:0] radr0=0,radr1=1;
wire [8:0] SPCOLi;

dpram #(9,10)
linebuffer(
	.clk_a(VCLKx4),
	.addr_a(radr0),
	.we_a(radr0==radr1),
	.d_a(9'h0),
	.q_a(SPCOLi),

	.clk_b(VCLKx4),
	.addr_b({~SIDE,HPOSW}),
	.d_b(SPWCL),
	.we_b((SPWCL[0]|SPWCL[1])),
	.q_b()
	);

always @(posedge VCLKx4) begin
	radr0 <= {SIDE,HPOS};
	if (VCLK_EN) begin
		if (radr0!=radr1) SPCOL <= SPCOLi;
		radr1 <= radr0;
	end
end

endmodule

// Copyright (c) 2017,19 MiSTer-X

module SEGASYS1_SPRITE
(
	input          VCLKx8,
	input          VCLKx4,
	input          VCLK,
	input          VCLKx4_EN,
	input          VCLK_EN,

	input          SYSTEM2,

	input  	[8:0]		PH,
	input  	[8:0]		PV,

	output 	[9:0]		sprad,
	input   [15:0]		sprdt,

	output  [17:0]		sprchad,
	input    [7:0]		sprchdt,

	output reg		 	sprcoll,
	output reg [9:0]	sprcoll_ad,

	output reg [10:0]	sprpx
);

wire [8:0] HPOS = PH;
wire [8:0] VPOS = PV;

wire		  HB = HPOS[8];

reg  [5:0] spr_num;
reg  [2:0] spr_ofs;

reg  [1:0] phaseHB;
reg  [7:0] svpos;
reg  [5:0] hitsprnum [0:31];
reg  [7:0] hitsprvps [0:31];
reg  [4:0] hits;

reg  [3:0] phaseHD;
reg  [4:0] hitr;
reg  [7:0] yofs;
reg  [8:0] xpos;
reg  [2:0] bank;
reg [15:0] stride;
reg [15:0] srcadrs;
reg  [3:0] waitcnt;
reg  [7:0] rdat;
reg [10:0] wdat;
reg		  hflip;
reg		  nowflip;
reg		  we;

wire [15:0] srca = sprdt[15:0] + (stride * yofs);

wire [10:0] col0 = { 2'b00, spr_num[4:0], nowflip ? rdat[3:0] : rdat[7:4] };
wire [10:0] col1 = { 2'b00, spr_num[4:0], nowflip ? rdat[7:4] : rdat[3:0] };

wire [10:0] _prevpix;
reg  [10:0]  prevpix;
wire side = VPOS[0];

wire [10:0] opix;
reg   [9:0] rad0,rad1=1;
LineBuf lbuf(
	VCLKx8, rad0, (rad0==rad1), opix, 
	VCLKx8, {~side,xpos}, wdat, we & (wdat[3:0] != 4'h0), _prevpix
);
always @(posedge VCLKx8) begin
	rad0 <= {side,HPOS};
	if (VCLK_EN) begin
		sprpx <= opix;
		rad1  <= rad0;
	end
end

assign sprad   = { spr_num, spr_ofs };
assign sprchad = { bank, srcadrs[14:0] };

wire [9:0] sprcoll_adr = { spr_num[4:0], prevpix[8:4] };


`define SPSTART	 0
`define SPEND		31

always @ ( posedge VCLKx8 ) if (VCLKx4_EN) begin

	// in H-Blank
	if ( HB ) begin

		phaseHD <= 0;
		we      <= 1'b0;
		sprcoll <= 1'b0;

		case ( phaseHB )

			// initialize
			2'h0: begin
				svpos   <= VPOS+1'd1;
				spr_num <= `SPSTART;
				spr_ofs <= 0;
				hits    <= 0;
				phaseHB <= 2'h1;
			end

			// check v-hit
			2'h1: begin
				if ( sprdt[7:0] != 8'hFF ) begin
					if ( ( svpos >= sprdt[7:0] ) & ( svpos < sprdt[15:8] ) ) begin
						hitsprnum[hits] <= spr_num;
						hitsprvps[hits] <= (svpos-sprdt[7:0])+1'd1;
						hits <= hits+1'd1;
					end	
				end
				phaseHB <= ( spr_num == `SPEND ) ? 2'h2 : 2'h1;
				spr_num <= spr_num+1'd1;
			end

			default:;

		endcase 

	end

	// in H-Disp
	else begin

		phaseHB <= 0;

		case ( phaseHD )

			// initialize
			0: begin
				hitr    <= 0;
				we      <= 1'b0;
				sprcoll <= 1'b0;
				phaseHD <= ( hits > 0 ) ? 1 : 15;
			end

			// get hit sprite number
			1: begin
				spr_num <= hitsprnum[hitr];
				spr_ofs <= 1;
				phaseHD <= 2;
			end

			// get yofs/xpos/bank
			2: begin
				yofs <= hitsprvps[hitr];
				xpos <= ((sprdt[8:0]+1)>>1) + (SYSTEM2 ? 8'd22 : 8'd14);
				bank <= { sprdt[13], sprdt[14], sprdt[15] };
				spr_ofs <= 2;
				phaseHD <= 3;
			end

			// get stride
			3: begin
				stride  <= sprdt;
				spr_ofs <= 3;
				phaseHD <= 4;
			end

			// get srcadrs & calc chiprom address
			4: begin
				srcadrs <= srca;
				hflip   <= srca[15];
				waitcnt <= 8; // wait for sprite data after address setup
				phaseHD <= 6;
			end
			
			// rendering to linebuf
			6: begin
				if (waitcnt == 0) begin
					sprcoll <= 1'b0;
					we      <= 1'b0;
					rdat    <= sprchdt;
					nowflip <= srcadrs[15];
					srcadrs <= hflip ? (srcadrs-1'd1) : (srcadrs+1'd1);
					if ((hflip && !srcadrs[0]) || (!hflip && srcadrs[0])) waitcnt <= 6; // assume 16 bit words are cached
					phaseHD <= 7;
				end else
					waitcnt <= waitcnt - 1'd1;
			end
			7: begin
				prevpix <= _prevpix;
				if ( col0[3:0] != 4'hF ) begin
					wdat <= col0;
					we   <= 1'b1;
					phaseHD <= 8;
				end
				else begin
					we      <= 1'b0;
					phaseHD <= 14;
				end
			end
			8: begin
				// sprite collide process
				we <= 1'b0;
				if ( col0[3:0] != 4'h0 ) begin
					if ( prevpix[3:0] != 4'h0 ) begin
						sprcoll    <= 1'b1;
						sprcoll_ad <= sprcoll_adr;
					end
				end
				xpos <= xpos+1'd1;
				phaseHD <= 9;
			end
			9: begin
				prevpix <= _prevpix;
				sprcoll <= 1'b0;
				if ( col1[3:0] != 4'hF ) begin
					wdat <= col1;
					we   <= 1'b1;
					phaseHD <= 10;
				end
				else begin
					we      <= 1'b0;
					phaseHD <= 14;
				end
			end
			10: begin
				// sprite collide process
				we <= 1'b0;
				if ( col1[3:0] != 4'h0 ) begin
					if ( prevpix[3:0] != 4'h0 ) begin
						sprcoll    <= 1'b1;
						sprcoll_ad <= sprcoll_adr;
					end
				end
				xpos <= xpos+1'd1;
				//waitcnt <= 5;
				phaseHD <= 6;
			end

			// process next hit sprite
			14: begin
				sprcoll <= 1'b0;
				we <= 1'b0;
				phaseHD <= ( hitr == (hits-1) ) ? 15 : 1;
				hitr <= hitr+1'd1;
			end
			
			default: begin
				we      <= 1'b0;
				sprcoll <= 1'b0;
			end

		endcase
		
	end
end

endmodule

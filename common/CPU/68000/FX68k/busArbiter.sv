//
// DMA/BUS Arbitration
//

module busArbiter( input s_clks Clks,
		input BRi, BgackI, Halti, bgBlock,
		output busAvail,
		output logic BGn);
		
	enum int unsigned { DRESET = 0, DIDLE, D1, D_BR, D_BA, D_BRA, D3, D2} dmaPhase, next;

	always_comb begin
		case(dmaPhase)
		DRESET:	next = DIDLE;
		DIDLE:	begin
				if( bgBlock)
					next = DIDLE;
				else if( ~BgackI)
					next = D_BA;
				else if( ~BRi)
					next = D1;
				else
					next = DIDLE;
				end

		D_BA:	begin							// Loop while only BGACK asserted, BG negated here
				if( ~BRi & !bgBlock)
					next = D3;
				else if( ~BgackI & !bgBlock)
					next = D_BA;
				else
					next = DIDLE;
				end
				
		D1:		next = D_BR;							// Loop while only BR asserted
		D_BR:	next = ~BRi & BgackI ? D_BR : D_BA;		// No direct path to IDLE !
		
		D3:		next = D_BRA;
		D_BRA:	begin						// Loop while both BR and BGACK asserted
				case( {BgackI, BRi} )
				2'b11:	next = DIDLE;		// Both deasserted
				2'b10:	next = D_BR;		// BR asserted only
				2'b01:	next = D2;			// BGACK asserted only
				2'b00:	next = D_BRA;		// Stay here while both asserted
				endcase
				end
				
		// Might loop here if both deasserted, should normally don't arrive here anyway?
		// D2:		next = (BgackI & BRi) | bgBlock ? D2: D_BA;

		D2:		next = D_BA;
		
		default:	next = DIDLE;			// Should not reach here normally		
		endcase
	end
		
	logic granting;
	always_comb begin
		unique case( next)
		D1, D3, D_BR, D_BRA:	granting = 1'b1;
		default:				granting = 1'b0;
		endcase
	end
	
	reg rGranted;
	assign busAvail = Halti & BRi & BgackI & ~rGranted;
		
	always_ff @( posedge Clks.clk) begin
		if( Clks.extReset) begin
			dmaPhase <= DRESET;
			rGranted <= 1'b0;
		end
		else if( Clks.enPhi2) begin
			dmaPhase <= next;
			// Internal signal changed on PHI2
			rGranted <= granting;
		end

		// External Output changed on PHI1
		if( Clks.extReset)
			BGn <= 1'b1;
		else if( Clks.enPhi1)
			BGn <= ~rGranted;
		
	end
			
endmodule 
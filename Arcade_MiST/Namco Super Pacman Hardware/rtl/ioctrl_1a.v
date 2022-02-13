//------------------------------------------
//	 I/O Chip for "Motos"
//
//         Copyright (c) 2007,19 MiSTer-X
//------------------------------------------

	case ( mema[4'h8] )

		4'h1: begin
			mema[4'h0] <= { 3'd0, CSTART12[2] };
			mema[4'h1] <= STKTRG12[3:0];
			mema[4'h2] <= STKTRG12[9:6];
			mema[4'h3] <= { CSTART12[1], CSTART12[0], STKTRG12[10], STKTRG12[4] };
			mema[4'h4] <= STKTRG12[9:6];
			mema[4'h5] <= STKTRG12[9:6];
			mema[4'h6] <= STKTRG12[9:6];
			mema[4'h7] <= STKTRG12[9:6];
			mema[4'h9] <= 0;
		end

		// credit management
		4'h4: begin
			credit_add = 0;
			credit_sub = 0;

			if ( iCSTART12[2] & ( credits < 99 ) ) begin
				credit_add = 8'h01;
				credits = credits + 1'd1;
			end

			if ( mema[4'h9] == 0 ) begin
				if ( ( credits >= 2 ) && iCSTART12[1] ) begin
					credit_sub = 8'h02;
					credits = credits - 2'd2;
				end else if ( ( credits >= 1 ) && iCSTART12[0] ) begin
					credit_sub = 8'h01;
					credits = credits - 1'd1;
				end
			end

			mema[4'h0] <= credit_add;
			mema[4'h1] <= credit_sub | {3'd0,CSTART12[0]};
			mema[4'h2] <= CREDIT_TENS;
			mema[4'h3] <= CREDIT_ONES;
			mema[4'h4] <= STKTRG12[3:0];
			mema[4'h5] <= { CSTART12[0], iCSTART12[0], STKTRG12[4], iSTKTRG12[4] };
			mema[4'h6] <= STKTRG12[9:6];
			mema[4'h7] <= { CSTART12[1], iCSTART12[1], STKTRG12[10], iSTKTRG12[10] };
		end

		4'h8: begin	// Boot up check, expected values by
			// the software (Super Pacman, Motos $69,  Phozon $1C)
			mema[4'h0] <= 4'h6;
			mema[4'h1] <= 4'h9;
		end

		default:;

	endcase

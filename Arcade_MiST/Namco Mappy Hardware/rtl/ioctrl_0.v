//------------------------------------------
//	 I/O Chip for "Mappy/Druaga/DigDug2"
//
//        Copyright (c) 2007,19 MiSTer-X
//------------------------------------------

		case ( mema[4'h8] )

		4'h1,4'h3: begin
			credit_add = 0;
			credit_sub = 0;

			if ( iCSTART12[2] & ( credits < 99 ) ) begin
				credit_add = 8'h01;
				credits = credits + 1;
			end
	
			if ( mema[4'h9] == 0 ) begin
				if ( ( credits >= 2 ) & iCSTART12[1] ) begin
					credit_sub = 8'h02;
					credits = credits - 2;
				end else if ( ( credits >= 1 ) & iCSTART12[0] ) begin
					credit_sub = 8'h01;
					credits = credits - 1;
				end
			end

			mema[4'h0] <= credit_add;
			mema[4'h1] <= credit_sub | {7'd0,CSTART12[0]};
			mema[4'h2] <= CREDIT_TENS;
			mema[4'h3] <= CREDIT_ONES;
			mema[4'h4] <= STKTRG12[3:0]; 
			mema[4'h5] <= { CSTART12[0], iCSTART12[0], STKTRG12[4], iSTKTRG12[4] };
			mema[4'h6] <= STKTRG12[9:6];				
			mema[4'h7] <= { CSTART12[1], iCSTART12[1], STKTRG12[10], iSTKTRG12[10] };
		end
	
		4'h4: begin
			mema[4'h0] <= 0;
			mema[4'h1] <= 0;
			mema[4'h2] <= 0;
			mema[4'h3] <= 0;
			mema[4'h4] <= 0;
			mema[4'h5] <= 0;
			mema[4'h6] <= { CSTART12[1], CSTART12[0], 2'b00 };
			mema[4'h7] <= { CSTART12[1], CSTART12[0], 2'b00 };
		end

		4'h5: begin
			mema[4'h0] <= 4'h0;
			mema[4'h1] <= 4'h8; 
			mema[4'h2] <= 4'h4; 
			mema[4'h3] <= 4'h6; 
			mema[4'h4] <= 4'hE; 
			mema[4'h5] <= 4'hD; 
			mema[4'h6] <= 4'h9; 
			mema[4'h7] <= 4'hD; 
		end

		default:;
	
		endcase


		case ( memb[4'h8] )
	
		4'h1,4'h3: begin
			memb[4'h0] <= 0;
			memb[4'h1] <= 0;
			memb[4'h2] <= 0;
			memb[4'h3] <= 0;
			memb[4'h4] <= 0;
			memb[4'h5] <= 0;
			memb[4'h6] <= 0;
			memb[4'h7] <= 0;
		end
	
		4'h4: begin
			memb[4'h0] <= DIPSW[11: 8];										// (P0) DSW1 Mappy
			memb[4'h1] <= DIPSW[15:12];

			memb[4'h2] <= DIPSW[ 3: 0];										// (P1) DSW0
			memb[4'h4] <= DIPSW[ 7: 4];

			memb[4'h5] <={DIPSW[15:14],STKTRG12[ 5],iSTKTRG12[ 5]};	// (P2) DSW1 Druaga/DigDug2
			memb[4'h6] <= DIPSW[23:20];										//           IsMappy ? DIPSW[19:16] : DIPSW[11:8]

			memb[4'h7] <={DIPSW[19:18],STKTRG12[11],iSTKTRG12[11]};	// (P3) DSW2

			memb[4'h3] <= 0;
		end

		4'h5: begin
			memb[4'h0] <= 4'h0;
			memb[4'h1] <= 4'h8; 
			memb[4'h2] <= 4'h4; 
			memb[4'h3] <= 4'h6; 
			memb[4'h4] <= 4'hE; 
			memb[4'h5] <= 4'hD; 
			memb[4'h6] <= 4'h9; 
			memb[4'h7] <= 4'hD; 
		end

		default:;

		endcase


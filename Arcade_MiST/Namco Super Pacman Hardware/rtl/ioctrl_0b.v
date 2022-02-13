//------------------------------------------
//	 I/O Chip for "Mappy/Druaga/DigDug2"
//
//        Copyright (c) 2007,19 MiSTer-X
//------------------------------------------

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


//------------------------------------------
//	 I/O Chip for "Motos"
//
//          Copyright (c) 2007 MiSTer-X
//------------------------------------------
// TODO: DSW2 = DIPSW[23:16]

		case ( mema[4'h8] )

		4'h1: begin
			mema[4'h0] <= { 3'b00, CSTART12[2] };
			mema[4'h1] <= STKTRG12[3:0];
			mema[4'h2] <= STKTRG12[9:6];
			mema[4'h3] <= { CSTART12[1], CSTART12[0], STKTRG12[10], STKTRG12[4] };
		end
	
		4'h8: begin
			mema[4'h0] <= 4'h6;
			mema[4'h1] <= 4'h9; 
		end

		default: begin end
	
		endcase


		case ( memb[4'h8] )
	
		4'h8: begin
			memb[4'h0] <= 4'h6;
			memb[4'h1] <= 4'h9; 
		end

		4'h9: begin
			memb[4'h0] <= 0;
			memb[4'h1] <= 0;
			memb[4'h2] <= 0;
			memb[4'h3] <= 0;
			memb[4'h4] <= 0;
			memb[4'h5] <= 0;
			memb[4'h6] <= 0;
			memb[4'h7] <= 0;
		end

		default: begin end

		endcase


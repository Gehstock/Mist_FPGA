//------------------------------------------
//	 I/O Chip for "Motos"
//   Namco 56xx
//
//         Copyright (c) 2007,19 MiSTer-X
//------------------------------------------
	case ( memb[4'h8] )

		4'h8: begin
			memb[4'h0] <= 4'h6;
			memb[4'h1] <= 4'h9;
		end

		4'h9: begin
			memb[4'h2] <= DIPSW[3:0];
			memb[4'h4] <= DIPSW[7:4];
			memb[4'h6] <= DIPSW[15:12];

			memb[4'h0] <= DIPSW[19:16];
			memb[4'h1] <= DIPSW[23:20];
			memb[4'h3] <= 0;
			memb[4'h5] <= 0;
			memb[4'h7] <= 0;
		end

		default:;

	endcase


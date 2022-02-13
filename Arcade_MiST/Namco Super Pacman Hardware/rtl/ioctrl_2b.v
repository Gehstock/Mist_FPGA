//------------------------------------------
//	 I/O Chip for "Pac & Pal"
//   Namco 59xx
//
//         Copyright (c) 2007,19 MiSTer-X
//         Copyright (c) 2022 Slingshot
//------------------------------------------
	case ( memb[4'h8] )

		4'h3: begin
			memb[4'h4] <= DIPSW[3:0]; //0
			memb[4'h5] <= DIPSW[23:20]; //2
			memb[4'h6] <= DIPSW[19:16]; //1
			memb[4'h7] <= DIPSW[15:12]; //3

			memb[4'h0] <= 0;
			memb[4'h1] <= 0;
			memb[4'h2] <= 0;
			memb[4'h3] <= 0;
		end

		default:;

	endcase


// Row/col CCR update table
module ccrTable( 
	input [2:0] col, input [15:0] row, input finish,
	output logic [MASK_NBITS-1:0] ccrMask);
    
	localparam
		KNZ00 = 5'b01111,   // ok coz operators clear them
		KKZKK = 5'b00100,
		KNZKK = 5'b01100,
		KNZ10 = 5'b01111,	// Used by OP_EXT on divison overflow
		KNZ0C = 5'b01111,	// Used by DIV. V should be 0, but it is ok:
							// DIVU: ends with quotient - 0, so V & C always clear.
							// DIVS: ends with 1i (AND), again, V & C always clear.

		KNZVC	= 5'b01111,
		CUPDALL = 5'b11111,
		CUNUSED = 5'bxxxxx;
    

	logic [MASK_NBITS-1:0] ccrMask1;

	always_comb begin
		unique case( col)
		1:			ccrMask = ccrMask1;
		
		2,3:
			unique case( 1'b1)
			row[1]:		ccrMask = KNZ0C;		// DIV, used as 3n in col3
			row[2],
			row[3],								// ABCD
			row[5],
			row[9],								// SBCD/NBCD
			row[10],							// SUBX/NEGX
			row[12]:	ccrMask = CUPDALL;		// ADDX
			row[6],								// CMP
			row[7],								// MUL		
			row[11]:	ccrMask = KNZVC;		// NOT
			row[4],
			row[8],								// Not used in col 3
			row[13],
			row[14]:	ccrMask = KNZ00;
			row[15]:	ccrMask = 5'b0;			// TAS/Scc, not used in col 3
			// default:	ccrMask = CUNUSED;
			endcase			
			
		4:
			unique case( row)
			// 1: DIV, only n (4n & 6n)
			// 14: BCLR 4n
			// 6,12,13,15	// not used
			`ALU_ROW_02,
			`ALU_ROW_03,							// ASL    (originally ANZVA)
			`ALU_ROW_04,
			`ALU_ROW_05:	ccrMask = CUPDALL;		// Shifts (originally ANZ0A)
			
			`ALU_ROW_07:	ccrMask = KNZ00;		// MUL (originally KNZ0A)
			`ALU_ROW_09,
			`ALU_ROW_10:	ccrMask = KNZ00;		// RO[lr] (originally KNZ0A)
			`ALU_ROW_11:	ccrMask = CUPDALL;		// ROXL (originally ANZ0A)
			default:	ccrMask = CUNUSED;
			endcase
		
		5:			ccrMask = row[1] ? KNZ10 : 5'b0;
		default:	ccrMask = CUNUSED;
		endcase
	end

	// Column 1 (AND)      
	always_comb begin
		if( finish)
			ccrMask1 = row[7] ? KNZ00 : KNZKK;
		else
			ccrMask1 = row[13] | row[14] ? KKZKK : KNZ00;
	end
    
endmodule 
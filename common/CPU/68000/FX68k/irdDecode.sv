//
// IRD execution decoder. Complements nano code decoder
//
// IRD updated on T1, while ncode still executing. To avoid using the next IRD,
// decoded signals must be registered on T3, or T4 before using them.
//
module irdDecode( input [15:0] ird,
			output s_irdecod Irdecod);

	wire [3:0] line = ird[15:12];
	logic [15:0] lineOnehot;

	// This can be registered and pipelined from the IR decoder !
	onehotEncoder4 irdLines( line, lineOnehot);
	
	wire isRegShift = (lineOnehot['he]) & (ird[7:6] != 2'b11);
	wire isDynShift = isRegShift & ird[5];
					
	assign Irdecod.isPcRel = (& ird[ 5:3]) & ~isDynShift & !ird[2] & ird[1];		
	assign Irdecod.isTas = lineOnehot[4] & (ird[11:6] == 6'b101011);
	
	assign Irdecod.rx = ird[11:9];
	assign Irdecod.ry = ird[ 2:0];

	wire isPreDecr = (ird[ 5:3] == 3'b100);
	wire eaAreg = (ird[5:3] == 3'b001);
		
	// rx is A or D
	// movem
	always_comb begin
		unique case( 1'b1)
		lineOnehot[1],
		lineOnehot[2],
		lineOnehot[3]:
					// MOVE: RX always Areg except if dest mode is Dn 000
					Irdecod.rxIsAreg = (| ird[8:6]);

		lineOnehot[4]:		Irdecod.rxIsAreg = (& ird[8:6]);		// not CHK (LEA)

		lineOnehot['h8]:	Irdecod.rxIsAreg = eaAreg & ird[8] & ~ird[7];	// SBCD
		lineOnehot['hc]:	Irdecod.rxIsAreg = eaAreg & ird[8] & ~ird[7];	// ABCD/EXG An,An				
		
		lineOnehot['h9],
		lineOnehot['hb],
		lineOnehot['hd]:	Irdecod.rxIsAreg =
							(ird[7] & ird[6]) |								// SUBA/CMPA/ADDA
							(eaAreg & ird[8] & (ird[7:6] != 2'b11));		// SUBX/CMPM/ADDX		
		default:
				Irdecod.rxIsAreg = Irdecod.implicitSp;
		endcase
	end	

	// RX is movem
	always_comb begin
		Irdecod.rxIsMovem = lineOnehot[4] & ~ird[8] & ~Irdecod.implicitSp;
	end
	assign Irdecod.movemPreDecr = Irdecod.rxIsMovem & isPreDecr;
	
	// RX is DT.
	// but SSP explicit or pc explicit has higher priority!
	// addq/subq (scc & dbcc also, but don't use rx)
	// Immediate including static bit
	assign Irdecod.rxIsDt = lineOnehot[5] | (lineOnehot[0] & ~ird[8]);
	
	// RX is USP
	assign Irdecod.rxIsUsp = lineOnehot[4] & (ird[ 11:4] == 8'he6);
	
	// RY is DT
	// rz or PC explicit has higher priority
	
	wire eaImmOrAbs = (ird[5:3] == 3'b111) & ~ird[1];
	assign Irdecod.ryIsDt = eaImmOrAbs & ~isRegShift;
		
	// RY is Address register
	always_comb begin
		logic eaIsAreg;
		
		// On most cases RY is Areg expect if mode is 000 (DATA REG) or 111 (IMM, ABS,PC REL)
		eaIsAreg = (ird[5:3] != 3'b000) & (ird[5:3] != 3'b111);
		
		unique case( 1'b1)
				// MOVE: RY always Areg expect if mode is 000 (DATA REG) or 111 (IMM, ABS,PC REL)
				// Most lines, including misc line 4, also.
		default:		Irdecod.ryIsAreg = eaIsAreg;

		lineOnehot[5]:	// DBcc is an exception
						Irdecod.ryIsAreg = eaIsAreg & (ird[7:3] != 5'b11001);

		lineOnehot[6],
		lineOnehot[7]:	Irdecod.ryIsAreg = 1'b0;

		lineOnehot['he]:
						Irdecod.ryIsAreg = ~isRegShift;
		endcase
	end	

	// Byte sized instruction
		
	// Original implementation sets this for some instructions that aren't really byte size
	// but doesn't matter because they don't have a byte transfer enabled at nanocode, such as MOVEQ
		
	wire xIsScc = (ird[7:6] == 2'b11) & (ird[5:3] != 3'b001); 
	wire xStaticMem = (ird[11:8] == 4'b1000) & (ird[5:4] == 2'b00);		// Static bit to mem
	always_comb begin
		unique case( 1'b1)
		lineOnehot[0]:
				Irdecod.isByte = 
				( ird[8] & (ird[5:4] != 2'b00)					) |	// Dynamic bit to mem
				( (ird[11:8] == 4'b1000) & (ird[5:4] != 2'b00)	) |	// Static bit to mem
				( (ird[8:7] == 2'b10) & (ird[5:3] == 3'b001)	) |	// Movep from mem only! For byte mux
				( (ird[8:6] == 3'b000) & !xStaticMem );				// Immediate byte
								
		lineOnehot[1]:			Irdecod.isByte = 1'b1;		// MOVE.B
	
		
		lineOnehot[4]:			Irdecod.isByte = (ird[7:6] == 2'b00) | Irdecod.isTas;		
		lineOnehot[5]:			Irdecod.isByte = (ird[7:6] == 2'b00) | xIsScc;
		
		lineOnehot[8],
		lineOnehot[9],
		lineOnehot['hb],
		lineOnehot['hc],
		lineOnehot['hd],
		lineOnehot['he]:		Irdecod.isByte = (ird[7:6] == 2'b00);
		
		default:				Irdecod.isByte = 1'b0;
		endcase
	end	
	
	// Need it for special byte size. Bus is byte, but whole register word is modified.
	assign Irdecod.isMovep = lineOnehot[0] & ird[8] & eaAreg;
	
	
	// rxIsSP implicit use of RX for actual SP transfer
	//
	// This logic is simple and will include some instructions that don't actually reference SP.
	// But doesn't matter as long as they don't perform any RX transfer.
	
	always_comb begin
		unique case( 1'b1)
		lineOnehot[6]:		Irdecod.implicitSp = (ird[11:8] == 4'b0001);		// BSR
		lineOnehot[4]:
			// Misc like RTS, JSR, etc
			Irdecod.implicitSp = (ird[11:8] == 4'b1110) | (ird[11:6] == 6'b1000_01);
		default:			Irdecod.implicitSp = 1'b0;
		endcase
	end
	
	// Modify CCR (and not SR)
	// Probably overkill !! Only needs to distinguish SR vs CCR
	// RTR, MOVE to CCR, xxxI to CCR
	assign Irdecod.toCcr =	( lineOnehot[4] & ((ird[11:0] == 12'he77) | (ird[11:6] == 6'b010011)) ) |
							( lineOnehot[0] & (ird[8:6] == 3'b000));
	
	// FTU constants
	// This should not be latched on T3/T4. Latch on T2 or not at all. FTU needs it on next T3.
	// Note: Reset instruction gets constant from ALU not from FTU!
	logic [15:0] ftuConst;
	wire [3:0] zero28 = (ird[11:9] == 0) ? 4'h8 : { 1'b0, ird[11:9]};		// xltate 0,1-7 into 8,1-7

	always_comb begin
		unique case( 1'b1)
		lineOnehot[6],														// Bcc short
		lineOnehot[7]:		ftuConst = { { 8{ ird[ 7]}}, ird[ 7:0] };		// MOVEQ
		
		lineOnehot['h5],													// addq/subq/static shift double check this
		lineOnehot['he]:	ftuConst = { 12'b0, zero28};
		
		// MULU/MULS DIVU/DIVS
		lineOnehot['h8],
		lineOnehot['hc]:	ftuConst = 16'h0f;

		lineOnehot[4]:		ftuConst = 16'h80;								// TAS

		default:			ftuConst = '0;
		endcase	
	end	
	assign Irdecod.ftuConst = ftuConst;
	
	//
	// TRAP Vector # for group 2 exceptions
	//
	
	always_comb begin
		if( lineOnehot[4]) begin
			case ( ird[6:5])
			2'b00,2'b01:	Irdecod.macroTvn = 6;					// CHK
			2'b11:			Irdecod.macroTvn = 7;					// TRAPV
			2'b10:			Irdecod.macroTvn = {2'b10, ird[3:0]};	// TRAP
			endcase
		end
		else
							Irdecod.macroTvn = 5;					// Division by zero
	end
	
	
	wire eaAdir = (ird[ 5:3] == 3'b001);
	wire size11 = ird[7] & ird[6];
	
	// Opcodes variants that don't affect flags
	// ADDA/SUBA ADDQ/SUBQ MOVEA

	assign Irdecod.inhibitCcr =
		( (lineOnehot[9] | lineOnehot['hd]) & size11) |				// ADDA/SUBA
		( lineOnehot[5] & eaAdir) |									// ADDQ/SUBQ to An (originally checks for line[4] as well !?)
		( (lineOnehot[2] | lineOnehot[3]) & ird[8:6] == 3'b001);	// MOVEA
		
endmodule 
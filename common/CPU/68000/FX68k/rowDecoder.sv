// Decodes IRD into ALU row (1-15)
// Slow, but no need to optimize for speed since IRD is latched at least two CPU cycles before it is used
// We also register the result after combining with column from nanocode
//
// Many opcodes are not decoded because they either don't do any ALU op,
// or use only columns 1 and 5 that are the same for all rows.

module rowDecoder( input [15:0] ird,
	output logic [15:0] row, output noCcrEn, output logic isArX);


	// Addr or data register direct
	wire eaRdir = (ird[ 5:4] == 2'b00);
	// Addr register direct
	wire eaAdir = (ird[ 5:3] == 3'b001);
	wire size11 = ird[7] & ird[6];
	
	always_comb begin
		case( ird[15:12])
		'h4,
		'h9,
		'hd:
			isArX = row[10] | row[12];
		default:
			isArX = 1'b0;
		endcase
	end

	always_comb begin
		unique case( ird[15:12])

		'h4:  begin
				if( ird[8])
					row = `ALU_ROW_06;			// chk (or lea)
				else case( ird[11:9])
					'b000: row = `ALU_ROW_10;	// negx
					'b001: row = `ALU_ROW_04;	// clr
					'b010: row = `ALU_ROW_05;	// neg
					'b011: row = `ALU_ROW_11;	// not
					'b100: row = (ird[7]) ? `ALU_ROW_08 : `ALU_ROW_09;	// nbcd/swap/ext(or pea)
					'b101: row = `ALU_ROW_15;	// tst & tas
					default: row = 0;
				endcase
			end

		'h0: begin
				if( ird[8])                       // dynamic bit
					row = ird[7] ? `ALU_ROW_14 : `ALU_ROW_13;
				else case( ird[ 11:9])
					'b000:   row = `ALU_ROW_14;	// ori
					'b001:   row = `ALU_ROW_04;	// andi
					'b010:   row = `ALU_ROW_05;	// subi
					'b011:   row = `ALU_ROW_02;	// addi
					'b100:   row = ird[7] ? `ALU_ROW_14 : `ALU_ROW_13;   // static bit
					'b101:   row = `ALU_ROW_13;	// eori
					'b110:   row = `ALU_ROW_06;	// cmpi
					default: row = 0;
					endcase
				end
				
		// MOVE
		// move.b originally also rows 5 & 15. Only because IRD bit 14 is not decoded.
		// It's the same for move the operations performed by MOVE.B

		'h1,'h2,'h3:   row = `ALU_ROW_02;
		
		'h5:
			if( size11)										
               row = `ALU_ROW_15;								// As originally and easier to decode
			else
				row = ird[8] ? `ALU_ROW_05 : `ALU_ROW_02;     // addq/subq
		'h6:	row = 0;						//bcc/bra/bsr
		'h7:	row = `ALU_ROW_02;				// moveq
		'h8:
			if( size11)						// div
				row = `ALU_ROW_01;
			else if( ird[8] & eaRdir)		// sbcd
				row = `ALU_ROW_09;
			else
				row = `ALU_ROW_14;			// or
		'h9:
			if( ird[8] & ~size11 & eaRdir)
				row = `ALU_ROW_10;			// subx
			else
				row = `ALU_ROW_05;			// sub/suba
		'hb:
			if( ird[8] & ~size11 & ~eaAdir)
				row = `ALU_ROW_13;			// eor
			else
				row = `ALU_ROW_06;			// cmp/cmpa/cmpm
		'hc:
			if( size11)
				row = `ALU_ROW_07;			// mul
			else if( ird[8] & eaRdir)		// abcd
				row = `ALU_ROW_03;
			else
				row = `ALU_ROW_04;			// and
		'hd:
			if( ird[8] & ~size11 & eaRdir)
				row = `ALU_ROW_12;			// addx
			else
				row = `ALU_ROW_02;			// add/adda
		'he:
			begin
				reg [1:0] stype;
				
				if( size11)					// memory shift/rotate
					stype = ird[ 10:9];
				else						// register shift/rotate
					stype = ird[ 4:3];

				case( {stype, ird[8]})
				0: row = `ALU_ROW_02;	// ASR
				1: row = `ALU_ROW_03;	// ASL
				2: row = `ALU_ROW_05;	// LSR
				3: row = `ALU_ROW_04;	// LSL
				4: row = `ALU_ROW_08;	// ROXR
				5: row = `ALU_ROW_11;	// ROXL
				6: row = `ALU_ROW_10;	// ROR
				7: row = `ALU_ROW_09;	// ROL
				endcase
			end
			
		default:	row = 0;
		endcase
	end
   
	// Decode opcodes that don't affect flags
	// ADDA/SUBA ADDQ/SUBQ MOVEA

	assign noCcrEn =
		// ADDA/SUBA
		( ird[15] & ~ird[13] & ird[12] & size11) |
		// ADDQ/SUBQ to An
		( (ird[15:12] == 4'h5) & eaAdir) |
		// MOVEA
		( (~ird[15] & ~ird[14] & ird[13]) & ird[8:6] == 3'b001);
        
endmodule 
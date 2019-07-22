// Microcode sequencer

module sequencer( input s_clks Clks, input enT3,
	input [UROM_WIDTH-1:0] microLatch,
	input A0Err, BerrA, busAddrErr, Spuria, Avia,
	input Tpend, intPend, isIllegal, isPriv, excRst, isLineA, isLineF,
	input [15:0] psw,
	input prenEmpty, au05z, dcr4, ze, i11,
	input [1:0] alue01,
	input [15:0] Ird,
	input [UADDR_WIDTH-1:0] a1, a2, a3,
	output logic [3:0] tvn,
	output logic [UADDR_WIDTH-1:0] nma);
	
	logic [UADDR_WIDTH-1:0] uNma;
	logic [UADDR_WIDTH-1:0] grp1Nma;	
	logic [1:0] c0c1;
	reg a0Rst;
	wire A0Sel;
	wire inGrp0Exc;
	
	// assign nma = Clks.extReset ? RSTP0_NMA : (A0Err ? BSER1_NMA : uNma);
	// assign nma = A0Err ? (a0Rst ? RSTP0_NMA : BSER1_NMA) : uNma;
	
    // word type I: 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
    // NMA :        .. .. 09 08 01 00 05 04 03 02 07 06 .. .. .. .. ..
	
	wire [UADDR_WIDTH-1:0] dbNma = { microLatch[ 14:13], microLatch[ 6:5], microLatch[ 10:7], microLatch[ 12:11]};

	// Group 0 exception.
	// Separated block from regular NMA. Otherwise simulation might depend on order of assigments.
	always_comb begin
		if( A0Err) begin
			if( a0Rst)					// Reset
				nma = RSTP0_NMA;
			else if( inGrp0Exc)			// Double fault
				nma = HALT1_NMA;
			else						// Bus or address error
				nma = BSER1_NMA;
		end
		else
			nma = uNma;
	end

	always_comb begin
		// Format II (conditional) or I (direct branch)
		if( microLatch[1])
			uNma = { microLatch[ 14:13], c0c1, microLatch[ 10:7], microLatch[ 12:11]};		
		else
			case( microLatch[ 3:2])
			0:   uNma = dbNma;   // DB
			1:   uNma = A0Sel ? grp1Nma : a1;
			2:   uNma = a2;
			3:   uNma = a3;
			endcase			
	end

	// Format II, conditional, NMA decoding
	wire [1:0] enl = { Ird[6], prenEmpty};		// Updated on T3
	
	wire [1:0] ms0 = { Ird[8], alue01[0]};
	wire [3:0] m01 = { au05z, Ird[8], alue01};
	wire [1:0] nz1 = { psw[ NF], psw[ ZF]};
	wire [1:0] nv  = { psw[ NF], psw[ VF]};
	
	logic ccTest;
	wire [4:0] cbc = microLatch[ 6:2];			// CBC bits
	
	always_comb begin
		unique case( cbc)
		'h0:    c0c1 = {i11, i11};						// W/L offset EA, from IRC

		'h1:    c0c1 = (au05z) ? 2'b01 : 2'b11;			// Updated on T3
		'h11:   c0c1 = (au05z) ? 2'b00 : 2'b11;

		'h02:   c0c1 = { 1'b0, ~psw[ CF]};				// C used in DIV
		'h12:   c0c1 = { 1'b1, ~psw[ CF]};

		'h03:   c0c1 = {psw[ ZF], psw[ ZF]};			// Z used in DIVU
		
		'h04:											// nz1, used in DIVS
			case( nz1)
               'b00:         c0c1 = 2'b10;
               'b10:         c0c1 = 2'b01;
               'b01,'b11:    c0c1 = 2'b11;
            endcase		

		'h05:   c0c1 = {psw[ NF], 1'b1};				// N used in CHK and DIV
		'h15:   c0c1 = {1'b1, psw[ NF]};
		
		// nz2, used in DIVS (same combination as nz1)
		'h06:   c0c1 = { ~nz1[1] & ~nz1[0], 1'b1};
		
		'h07:											// ms0 used in MUL
		case( ms0)
		 'b10, 'b00: c0c1 = 2'b11;
		 'b01: c0c1 = 2'b01;
		 'b11: c0c1 = 2'b10;
		endcase		
		
		'h08:											// m01 used in MUL
		case( m01)
		'b0000,'b0001,'b0100,'b0111:  c0c1 = 2'b11;
		'b0010,'b0011,'b0101:         c0c1 = 2'b01;
		'b0110:                       c0c1 = 2'b10;
		default:                      c0c1 = 2'b00;
		endcase

		// Conditional		
		'h09:   c0c1 = (ccTest) ? 2'b11 : 2'b01;
		'h19:   c0c1 = (ccTest) ? 2'b11 : 2'b10;
		
		// DCR bit 4 (high or low word)
		'h0c:   c0c1 = dcr4 ? 2'b01: 2'b11;
		'h1c:   c0c1 = dcr4 ? 2'b10: 2'b11;		
		
		// DBcc done
		'h0a:   c0c1 = ze ? 2'b11 : 2'b00;
		
		// nv, used in CHK
		'h0b:   c0c1 = (nv == 2'b00) ? 2'b00 : 2'b11;
		
		// V, used in trapv
		'h0d:   c0c1 = { ~psw[ VF], ~psw[VF]};		
		
		// enl, combination of pren idle and word/long on IRD
		'h0e,'h1e:
			case( enl)
			2'b00:	c0c1 = 'b10;
			2'b10:	c0c1 = 'b11;
			// 'hx1 result 00/01 depending on condition 0e/1e
			2'b01,2'b11:
					c0c1 = { 1'b0, microLatch[ 6]};
			endcase
			
		default: 				c0c1 = 'X;
		endcase
	end
	
	// CCR conditional
	always_comb begin
		unique case( Ird[ 11:8])		
		'h0: ccTest = 1'b1;						// T
		'h1: ccTest = 1'b0;						// F
		'h2: ccTest = ~psw[ CF] & ~psw[ ZF];	// HI
		'h3: ccTest = psw[ CF] | psw[ZF];		// LS
		'h4: ccTest = ~psw[ CF];				// CC (HS)
		'h5: ccTest = psw[ CF];					// CS (LO)
		'h6: ccTest = ~psw[ ZF];				// NE
		'h7: ccTest = psw[ ZF];					// EQ
		'h8: ccTest = ~psw[ VF];				// VC
		'h9: ccTest = psw[ VF];					// VS
		'ha: ccTest = ~psw[ NF];				// PL
		'hb: ccTest = psw[ NF];					// MI
		'hc: ccTest = (psw[ NF] & psw[ VF]) | (~psw[ NF] & ~psw[ VF]);				// GE
		'hd: ccTest = (psw[ NF] & ~psw[ VF]) | (~psw[ NF] & psw[ VF]);				// LT
		'he: ccTest = (psw[ NF] & psw[ VF] & ~psw[ ZF]) |
				 (~psw[ NF] & ~psw[ VF] & ~psw[ ZF]);								// GT
		'hf: ccTest = psw[ ZF] | (psw[ NF] & ~psw[VF]) | (~psw[ NF] & psw[VF]);		// LE
		endcase
	end
	
	// Exception logic
	logic rTrace, rInterrupt;
	logic rIllegal, rPriv, rLineA, rLineF;
	logic rExcRst, rExcAdrErr, rExcBusErr;
	logic rSpurious, rAutovec;
	wire grp1LatchEn, grp0LatchEn;
			
	// Originally control signals latched on T4. Then exception latches updated on T3
	assign grp1LatchEn = microLatch[0] & (microLatch[1] | !microLatch[4]);
	assign grp0LatchEn = microLatch[4] & !microLatch[1];
	
	assign inGrp0Exc = rExcRst | rExcBusErr | rExcAdrErr;
	
	always_ff @( posedge Clks.clk) begin
		if( grp0LatchEn & enT3) begin
			rExcRst <= excRst;
			rExcBusErr <= BerrA;
			rExcAdrErr <= busAddrErr;
			rSpurious <= Spuria;
			rAutovec <= Avia;
		end
		
		// Update group 1 exception latches
		// Inputs from IR decoder updated on T1 as soon as IR loaded
		// Trace pending updated on T3 at the start of the instruction
		// Interrupt pending on T2
		if( grp1LatchEn & enT3) begin
			rTrace <= Tpend;
			rInterrupt <= intPend;
			rIllegal <= isIllegal & ~isLineA & ~isLineF;
			rLineA <= isLineA;
			rLineF <= isLineF;
			rPriv <= isPriv & !psw[ SF];
		end
	end

	// exception priority
	always_comb begin
		grp1Nma = TRAC1_NMA;
		if( rExcRst)
			tvn = '0;							// Might need to change that to signal in exception
		else if( rExcBusErr | rExcAdrErr)
			tvn = { 1'b1, rExcAdrErr};
			
		// Seudo group 0 exceptions. Just for updating TVN
		else if( rSpurious | rAutovec)
			tvn = rSpurious ? TVN_SPURIOUS : TVN_AUTOVEC;
		
		else if( rTrace)
			tvn = 9;
		else if( rInterrupt) begin
			tvn = TVN_INTERRUPT;
			grp1Nma = ITLX1_NMA;
		end
		else begin
			unique case( 1'b1)					// Can't happen more than one of these
			rIllegal:			tvn = 4;
			rPriv:				tvn = 8;
			rLineA:				tvn = 10;
			rLineF:				tvn = 11;
			default:			tvn = 1;		// Signal no group 0/1 exception
			endcase
		end
	end
	
	assign A0Sel = rIllegal | rLineF | rLineA | rPriv | rTrace | rInterrupt;
	
	always_ff @( posedge Clks.clk) begin
		if( Clks.extReset)
			a0Rst <= 1'b1;
		else if( enT3)
			a0Rst <= 1'b0;
	end
	
endmodule 
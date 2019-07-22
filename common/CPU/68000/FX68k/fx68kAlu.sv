//
// FX 68K
//
// M68K cycle accurate, fully synchronous
// Copyright (c) 2018 by Jorge Cwik
//
// ALU
//

`timescale 1 ns / 1 ns

localparam MASK_NBITS = 5;

localparam
		OP_AND = 1,
		OP_SUB = 2, OP_SUBX = 3, OP_ADD = 4,
		OP_EXT = 5, OP_SBCD = 6, OP_SUB0 = 7,
		OP_OR = 8, OP_EOR = 9,
		OP_SUBC = 10, OP_ADDC = 11, OP_ADDX = 12,
		OP_ASL = 13,
		OP_ASR = 14,
		OP_LSL = 15,
		OP_LSR = 16,
		OP_ROL = 17,
		OP_ROR = 18,
		OP_ROXL = 19,
		OP_ROXR = 20,
		OP_SLAA = 21,
		OP_ABCD = 22;

module fx68kAlu ( input clk, pwrUp, enT1, enT3, enT4,
	input [15:0] ird,
	input [2:0] aluColumn,
	input [1:0] aluDataCtrl,
	input aluAddrCtrl, alueClkEn, ftu2Ccr, init, finish, aluIsByte,
	input [15:0] ftu,
	input [15:0] alub,
	input [15:0] iDataBus, input [15:0] iAddrBus,
	output ze,
	output reg [15:0] alue,
	output reg [7:0] ccr,
	output [15:0] aluOut);


`define ALU_ROW_01		16'h0002
`define ALU_ROW_02		16'h0004
`define ALU_ROW_03		16'h0008
`define ALU_ROW_04		16'h0010
`define ALU_ROW_05		16'h0020
`define ALU_ROW_06		16'h0040
`define ALU_ROW_07		16'h0080
`define ALU_ROW_08		16'h0100
`define ALU_ROW_09		16'h0200
`define ALU_ROW_10		16'h0400
`define ALU_ROW_11		16'h0800
`define ALU_ROW_12		16'h1000
`define ALU_ROW_13		16'h2000
`define ALU_ROW_14		16'h4000
`define ALU_ROW_15		16'h8000
	
	
	// Bit positions for flags in CCR
	localparam CF = 0, VF = 1, ZF = 2, NF = 3, XF = 4;

	reg [15:0] aluLatch;
	reg [4:0] pswCcr;
	reg [4:0] ccrCore;
	
	logic [15:0] result;
	logic [4:0] ccrTemp;
	reg coreH;		// half carry latch

	logic [15:0] subResult;
	logic subHcarry;
	logic subCout, subOv;

	assign aluOut = aluLatch;
	assign ze = ~ccrCore[ ZF];		// Check polarity !!!

	//
	// Control
	//	Signals derived from IRD *must* be registered on either T3 or T4
	//  Signals derived from nano rom can be registered on T4.

	reg [15:0] row;
	reg isArX;									// Don't set Z
	reg noCcrEn;
	reg isByte;
	
	reg [4:0] ccrMask;
	reg [4:0] oper;
	
	logic [15:0] aOperand, dOperand;
	wire isCorf = ( aluDataCtrl == 2'b10);

	wire [15:0] cRow;
	wire cIsArX;
	wire cNoCcrEn;
	rowDecoder rowDecoder( 
		.ird		( ird), 
		.row		( cRow), 
		.noCcrEn	( cNoCcrEn), 
		.isArX	( cIsArX)
		);
	
	// Get Operation & CCR Mask from row/col
	// Registering them on T4 increase performance. But slowest part seems to be corf !
	wire [4:0] cMask;
	wire [4:0] aluOp;

	aluGetOp aluGetOp( 
		.row		( row),
		.col		( aluColumn),
		.isCorf	( isCorf),
		.aluOp	( aluOp)
		);	
		
	ccrTable ccrTable( 
		.col		( aluColumn),
		.row		( row),
		.finish	( finish), 
		.ccrMask	( cMask)
		);

	// Inefficient, uCode could help !
	wire shftIsMul = row[7];
	wire shftIsDiv = row[1];

	wire [31:0] shftResult;
	reg [7:0] bcdLatch;
	reg bcdCarry, bcdOverf;
		
	reg isLong;
	reg rIrd8;
	logic isShift;
	logic shftCin, shftRight, addCin;
	
	// Register some decoded signals	
	always_ff @( posedge clk) begin
		if( enT3) begin
			row <= cRow;
			isArX <= cIsArX;
			noCcrEn <= cNoCcrEn;
			rIrd8 <= ird[8];
			isByte <= aluIsByte;
		end
		
		if( enT4) begin
			// Decode if long shift
			// MUL and DIV are long (but special !)
			isLong <= (ird[7] & ~ird[6]) | shftIsMul | shftIsDiv;			
			
			ccrMask <= cMask;
			oper <= aluOp;
		end
	end
	
	
	always_comb begin
		// Dest (addr) operand source
		// If aluCsr (depends on column/row) addrbus is shifted !!
		aOperand = (aluAddrCtrl ? alub : iAddrBus);
		
		// Second (data,source) operand mux
		case( aluDataCtrl)
			2'b00:				dOperand = iDataBus;
			2'b01:				dOperand = 'h0000;
			2'b11:				dOperand = 'hffff;
			// 2'b10:				dOperand = bcdResult;
			2'b10:				dOperand = 'X;
		endcase
	end
	
	// Execution
	   
	// shift operand MSB. Input in ASR/ROL. Carry in right.
	// Can't be registered because uses bus operands that aren't available early !
	wire shftMsb = isLong ? alue[15] : (isByte ? aOperand[7] : aOperand[15]);
	   
	aluShifter shifter( 
		.data			( { alue, aOperand}),
		.swapWords	( shftIsMul | shftIsDiv),
		.cin			( shftCin), 
		.dir			( shftRight), 
		.isByte		( isByte), 
		.isLong		( isLong),
		.result		( shftResult)
		);
				
	wire [7:0] bcdResult;
	wire bcdC, bcdV;
	aluCorf aluCorf( 
		.binResult	( aluLatch[7:0]), 
		.hCarry		( coreH),
		.bAdd			( (oper != OP_SBCD) ), 
		.cin			( pswCcr[ XF]),
		.bcdResult	( bcdResult), 
		.dC			( bcdC), 
		.ov			( bcdV));

	// BCD adjust is among the slowest processing on ALU !
	// Precompute and register BCD result on T1
	// We don't need to wait for execution buses because corf is always added to ALU previous result
	always_ff @( posedge clk)
		if( enT1) begin
			bcdLatch <= bcdResult;
			bcdCarry <= bcdC;
			bcdOverf <= bcdV;
		end
		
	// Adder carry in selector
	always_comb
	begin
		case( oper)
			OP_ADD, OP_SUB:   addCin = 1'b0;
			OP_SUB0:          addCin = 1'b1;			// NOT = 0 - op - 1
			OP_ADDC,OP_SUBC:  addCin = ccrCore[ CF];
			OP_ADDX,OP_SUBX:  addCin = pswCcr[ XF];
			default: addCin = 1'bX;
		endcase
	end
   	
	// Shifter carry in and direction selector
	always_comb begin
		case( oper)
		OP_LSL, OP_ASL, OP_ROL, OP_ROXL, OP_SLAA:   shftRight = 1'b0;
		OP_LSR, OP_ASR, OP_ROR, OP_ROXR:            shftRight = 1'b1;
		default:									shftRight = 1'bX;
		endcase
		
		case( oper)
		OP_LSR,
		OP_ASL,
		OP_LSL:		shftCin = 1'b0;
		OP_ROL,
		OP_ASR:		shftCin = shftMsb;
		OP_ROR:		shftCin = aOperand[0];
		OP_ROXL,
		OP_ROXR:
			if( shftIsMul)
				shftCin = rIrd8 ? pswCcr[NF] ^ pswCcr[VF] : pswCcr[ CF];
			else
				shftCin = pswCcr[ XF];
				
		OP_SLAA:	shftCin = aluColumn[1];   // col4 -> 0, col 6-> 1
		default:	shftCin = 'X;
		endcase
	end
	
	// ALU operation selector
	always_comb begin	      

		// sub is DATA - ADDR	    
		mySubber( aOperand, dOperand, addCin,
			(oper == OP_ADD) | (oper == OP_ADDC) | (oper == OP_ADDX),
			isByte, subResult, subCout, subOv);
			
		isShift = 1'b0;
		case( oper)
		OP_AND: result = aOperand & dOperand;
		OP_OR:  result = aOperand | dOperand;
		OP_EOR: result = aOperand ^ dOperand;
		
		OP_EXT: result = { {8{aOperand[7]}}, aOperand[7:0]};
		
		OP_SLAA,
		OP_ASL, OP_ASR,
		OP_LSL, OP_LSR,
		OP_ROL, OP_ROR,
		OP_ROXL, OP_ROXR:
			begin
				result = shftResult[15:0];
				isShift = 1'b1;
			end
			
		OP_ADD,
		OP_ADDC,
		OP_ADDX,
		OP_SUB,
		OP_SUBC,
		OP_SUB0,
		OP_SUBX:	result = subResult;
		
		OP_ABCD,
		OP_SBCD:	result = { 8'hXX, bcdLatch};

		default:	result = 'X;
		endcase	   
	end
	
	task mySubber;
		input [15:0] inpa, inpb;
		input cin, bAdd, isByte;
		output reg [15:0] result;
		output cout, ov;

		// Not very efficient!
		logic [16:0] rtemp;
		logic rm,sm,dm,tsm;

		begin
			if( isByte)
			begin
				rtemp = bAdd ? { 1'b0, inpb[7:0]} + { 1'b0, inpa[7:0]} + cin:
								{ 1'b0, inpb[7:0] } - { 1'b0, inpa[7:0]} - cin;
				result = { {8{ rtemp[7]}}, rtemp[7:0]};
				cout = rtemp[8];
			end
			else begin
				rtemp = bAdd ? { 1'b0, inpb } + { 1'b0, inpa} + cin:
								{ 1'b0, inpb } - { 1'b0, inpa} - cin;
				result = rtemp[ 15:0];
				cout = rtemp[16];
			end
	        
			rm  = isByte ? rtemp[7] : rtemp[15];
			dm  = isByte ? inpb[ 7] : inpb[ 15];
			tsm = isByte ? inpa[ 7] : inpa[ 15];
			sm  = bAdd ? tsm : ~tsm;

			ov = (sm & dm & ~rm) | (~sm & ~dm & rm);
			
			// Store half carry for bcd correction
			subHcarry = inpa[4] ^ inpb[4] ^ rtemp[4];
		
		end
	endtask
	
	
	// CCR flags process
	always_comb begin
		
		ccrTemp[XF] = pswCcr[XF];     ccrTemp[CF] = 0;     ccrTemp[VF] = 0;	

		// Not on all operators !!!
		ccrTemp[ ZF] = isByte ? ~(| result[7:0]) : ~(| result);
		ccrTemp[ NF] = isByte ? result[7] : result[15];

		unique case( oper)
		
		OP_EXT:
			// Division overflow.
			if( aluColumn == 5) begin
				ccrTemp[VF] = 1'b1;		ccrTemp[NF] = 1'b1;
			end

		OP_SUB0,				// used by NOT
		OP_OR,
		OP_EOR:
			begin
				ccrTemp[CF] = 0;      ccrTemp[VF] = 0;
			end

		OP_AND:
			begin
				// ROXL/ROXR indeed copy X to C in column 1 (OP_AND), executed before entering the loop.
				// Needed when rotate count is zero, the ucode with the ROX operator never reached.
				// 	C must be set to the value of X, X remains unaffected.
				if( (aluColumn == 1) & (row[11] | row[8]))
					ccrTemp[CF] = pswCcr[XF];
				else
					ccrTemp[CF] = 0;
				ccrTemp[VF] = 0;
			end
			
		// Assumes col 3 of DIV use C and not X !
		// V will be set in other cols (2/3) of DIV
		OP_SLAA:   ccrTemp[ CF] = aOperand[15];
		
		OP_LSL,OP_ROXL:
			begin
				ccrTemp[ CF] = shftMsb;
				ccrTemp[ XF] = shftMsb;
				ccrTemp[ VF] = 1'b0;
			end
			
		OP_LSR,OP_ROXR:
			begin
				// 0 Needed for mul, or carry gets in high word
				ccrTemp[ CF] = shftIsMul ? 1'b0 : aOperand[0];
				ccrTemp[ XF] = aOperand[0];
				// Not relevant for MUL, we clear it at mulm6 (1f) anyway.
				// Not that MUL can never overlow!
				ccrTemp[ VF] = 0;
				// Z is checking here ALU (low result is actually in ALUE).
				// But it is correct, see comment above.
			end
			
		OP_ASL:
			begin
				ccrTemp[ XF] = shftMsb;			ccrTemp[ CF] = shftMsb;
				// V set if msb changed on any shift.
				// Otherwise clear previously on OP_AND (col 1i).
				ccrTemp[ VF] = pswCcr[VF] | (shftMsb ^
					(isLong ? alue[15-1] : (isByte ? aOperand[7-1] : aOperand[15-1])) );
			end
		OP_ASR:
			begin
				ccrTemp[ XF] = aOperand[0];		ccrTemp[ CF] = aOperand[0];
				ccrTemp[ VF] = 0;
			end
      
		// X not changed on ROL/ROR !
		OP_ROL:		ccrTemp[ CF] = shftMsb;
		OP_ROR:		ccrTemp[ CF] = aOperand[0];

		OP_ADD,
		OP_ADDC,
		OP_ADDX,
		OP_SUB,
		OP_SUBC,
		OP_SUBX:
			begin
				ccrTemp[ CF] = subCout;
				ccrTemp[ XF] = subCout;
				ccrTemp[ VF] = subOv;
			end

		OP_ABCD,
		OP_SBCD:
			begin
				ccrTemp[ XF] = bcdCarry;
				ccrTemp[ CF] = bcdCarry;
				ccrTemp[ VF] = bcdOverf;
			end
		
		endcase
				
	end
	
	// Core and psw latched at the same cycle
	
	// CCR filter
	// CCR out mux for Z & C flags
	// Z flag for 32-bit result
	// Not described, but should be used also for instructions
	//   that clear but not set Z (ADDX/SUBX/ABCD, etc)!
	logic [4:0] ccrMasked;
	always_comb begin
		ccrMasked = (ccrTemp & ccrMask) | (pswCcr & ~ccrMask);
		if( finish | isCorf | isArX)
			ccrMasked[ ZF] = ccrTemp[ ZF] & pswCcr[ ZF];
	end
		
	always_ff @( posedge clk) begin
		if( enT3) begin
			// Update latches from ALU operators
			if( (| aluColumn)) begin
				aluLatch <= result;
				
				coreH <= subHcarry;
			   
				// Update CCR core
				if( (| aluColumn))
					ccrCore <= ccrTemp;		// Most bits not really used
			end

			if( alueClkEn)
				alue <= iDataBus;
			else if( isShift & (| aluColumn))
				alue <= shftResult[31:16];
		end
				
		// CCR
		// Originally on T3-T4 edge pulse !!
		// Might be possible to update on T4 (but not after T0) from partial result registered on T3, it will increase performance!
		if( pwrUp)
			pswCcr <= '0;
		else if( enT3 & ftu2Ccr)
			pswCcr <= ftu[4:0];	
		else if( enT3 &	~noCcrEn & (finish | init))
			pswCcr <= ccrMasked;
	end
	assign ccr = { 3'b0, pswCcr};	

	      
endmodule



//
// FX68K
//
// M68000 cycle accurate, fully synchronous
// Copyright (c) 2018 by Jorge Cwik
// 
// TODO:
// - Everything except bus retry already implemented.

`timescale 1 ns / 1 ns

// Define this to run a self contained compilation test build
// `define FX68K_TEST

localparam CF = 0, VF = 1, ZF = 2, NF = 3, XF = 4, SF = 13;

localparam UADDR_WIDTH = 10;
localparam UROM_WIDTH = 17;
localparam UROM_DEPTH = 1024;

localparam NADDR_WIDTH = 9;
localparam NANO_WIDTH = 68;
localparam NANO_DEPTH = 336;

localparam BSER1_NMA = 'h003;
localparam RSTP0_NMA = 'h002;
localparam HALT1_NMA = 'h001;
localparam TRAC1_NMA = 'h1C0;
localparam ITLX1_NMA = 'h1C4;

localparam TVN_SPURIOUS = 12;
localparam TVN_AUTOVEC = 13;
localparam TVN_INTERRUPT = 15;

localparam NANO_DOB_DBD = 2'b01;
localparam NANO_DOB_ADB = 2'b10;
localparam NANO_DOB_ALU = 2'b11;


// Clocks, phases and resets
typedef struct {
	logic clk;
	logic extReset;			// External sync reset on emulated system
	logic pwrUp;			// Asserted together with reset on emulated system coldstart
	logic enPhi1, enPhi2;	// Clock enables. Next cycle is PHI1 or PHI2
} s_clks;

// IRD decoded signals
typedef struct {
	logic isPcRel;
	logic isTas;
	logic implicitSp;
	logic toCcr;
	logic rxIsDt, ryIsDt;
	logic rxIsUsp, rxIsMovem, movemPreDecr;
	logic isByte;
	logic isMovep;
	logic [2:0] rx, ry;
	logic rxIsAreg, ryIsAreg;
	logic [15:0] ftuConst;
	logic [5:0] macroTvn;
	logic inhibitCcr;
} s_irdecod;

// Nano code decoded signals
typedef struct {
	logic permStart;
	logic waitBusFinish;
	logic isWrite;
	logic busByte;
	logic isRmc;
	logic noLowByte, noHighByte;
	
	logic updTpend, clrTpend;
	logic tvn2Ftu, const2Ftu;
	logic ftu2Dbl, ftu2Abl;
	logic abl2Pren, updPren;
	logic inl2psw, ftu2Sr, sr2Ftu, ftu2Ccr, pswIToFtu;
	logic ird2Ftu, ssw2Ftu;
	logic initST;
	logic Ir2Ird;
	
	logic auClkEn, noSpAlign;
	logic [2:0] auCntrl;
	logic todbin, toIrc;
	logic dbl2Atl, abl2Atl, atl2Abl, atl2Dbl;
	logic abh2Ath, dbh2Ath;
	logic ath2Dbh, ath2Abh;
	
	logic db2Aob, ab2Aob, au2Aob;
	logic aob2Ab, updSsw;
	// logic adb2Dob, dbd2Dob, alu2Dob;
	logic [1:0] dobCtrl;
	
	logic abh2reg, abl2reg;
	logic reg2abl, reg2abh;
	logic dbh2reg, dbl2reg;
	logic reg2dbl, reg2dbh;
	logic ssp, pchdbh, pcldbl, pclabl, pchabh;
	
	logic rxh2dbh, rxh2abh;
	logic dbl2rxl, dbh2rxh;
	logic rxl2db, rxl2ab;
	logic abl2rxl, abh2rxh;
	logic dbh2ryh, abh2ryh;
	logic ryl2db, ryl2ab;
	logic ryh2dbh, ryh2abh;
	logic dbl2ryl, abl2ryl;
	logic rz;
	logic rxlDbl;
	
	logic [2:0] aluColumn;
	logic [1:0] aluDctrl;
	logic aluActrl;
	logic aluInit, aluFinish;
	logic abd2Dcr, dcr2Dbd;
	logic dbd2Alue, alue2Dbd;
	logic dbd2Alub, abd2Alub;
	
	logic alu2Dbd, alu2Abd;
	logic au2Db, au2Ab, au2Pc;
	logic dbin2Abd, dbin2Dbd;
	logic extDbh, extAbh;
	logic ablAbd, ablAbh;
	logic dblDbd, dblDbh;
	logic abdIsByte;
} s_nanod;

module fx68k(
	input clk,
	
	// These two signals don't need to be registered. They are not async reset.
	input extReset,			// External sync reset on emulated system
	input pwrUp,			// Asserted together with reset on emulated system coldstart	
	input enPhi1, enPhi2,	// Clock enables. Next cycle is PHI1 or PHI2

	output eRWn, output ASn, output LDSn, output UDSn,
	output logic E, output VMAn,	
	output FC0, output FC1, output FC2,
	output BGn,
	output oRESETn, output oHALTEDn,
	input DTACKn, input VPAn,
	input BERRn,
	input BRn, BGACKn,
	input IPL0n, input IPL1n, input IPL2n,
	input [15:0] iEdb, output [15:0] oEdb,
	output [23:1] eab
	);
	
	// wire clock = Clks.clk;
	s_clks Clks;
	
	assign Clks.clk = clk;	
	assign Clks.extReset = extReset;
	assign Clks.pwrUp = pwrUp;	
	assign Clks.enPhi1 = enPhi1;
	assign Clks.enPhi2 = enPhi2;
	
	wire wClk;
	
	// Internal sub clocks T1-T4
	enum int unsigned { T0 = 0, T1, T2, T3, T4} tState;
	wire enT1 = Clks.enPhi1 & (tState == T4) & ~wClk;
	wire enT2 = Clks.enPhi2 & (tState == T1);
	wire enT3 = Clks.enPhi1 & (tState == T2);
	wire enT4 = Clks.enPhi2 & ((tState == T0) | (tState == T3));
	
	// T4 continues ticking during reset and group0 exception.
	// We also need it to erase ucode output latched on T4.
	always_ff @( posedge Clks.clk) begin
		if( Clks.pwrUp)
			tState <= T0;
		else begin
		case( tState)
		T0: if( Clks.enPhi2) tState <= T4;
		T1: if( Clks.enPhi2) tState <= T2;
		T2: if( Clks.enPhi1) tState <= T3;
		T3: if( Clks.enPhi2) tState <= T4;
		T4: if( Clks.enPhi1) tState <= wClk ? T0 : T1;
		endcase
		end
	end
	
	// The following signals are synchronized with 3 couplers, phi1-phi2-phi1.
	// Will be valid internally one cycle later if changed at the rasing edge of the clock.
	//
	// DTACK, BERR
		
	// DTACK valid at S6 if changed at the rasing edge of S4 to avoid wait states.
	// SNC (sncClkEn) is deasserted together (unless DTACK asserted too early).
	//	
	// We synchronize some signals half clock earlier. We compensate later
	reg rDtack, rBerr;
	reg [2:0] rIpl, iIpl;
	reg Vpai, BeI, BRi, BgackI, BeiDelay;
	// reg rBR;
	wire BeDebounced = ~( BeI | BeiDelay);

	always_ff @( posedge Clks.clk) begin
		if( Clks.pwrUp) begin
			rBerr <= 1'b0;
			BeI <= 1'b0;
		end
		else if( Clks.enPhi2) begin
			rDtack <= DTACKn;
			rBerr <= BERRn;
			rIpl <= ~{ IPL2n, IPL1n, IPL0n};
			iIpl <= rIpl;
			
			// rBR <= BRn;			// Needed for cycle accuracy but only if BR is changed on the wrong edge of the clock
		end
		else if( Clks.enPhi1) begin
			Vpai <= VPAn;
			BeI <= rBerr;
			BeiDelay <= BeI;
			
			BRi <= BRn;
			BgackI <= BGACKn;
			// BRi <= rBR;
		end	
	end

	// Instantiate micro and nano rom
	logic [NANO_WIDTH-1:0] nanoLatch;
	logic [NANO_WIDTH-1:0] nanoOutput;
	logic [UROM_WIDTH-1:0] microLatch;
	logic [UROM_WIDTH-1:0] microOutput;
	
	logic [UADDR_WIDTH-1:0] microAddr, nma; 
	logic [NADDR_WIDTH-1:0] nanoAddr, orgAddr;
	wire rstUrom;

	// For the time being, address translation is done for nanorom only. 
	microToNanoAddr microToNanoAddr( 
		.uAddr	( nma), 
		.orgAddr	( orgAddr)
		);
	
	// Output of these modules will be updated at T2 at the latest (depending on clock division)
	
	nanoRom nanoRom( 
		.clk			( Clks.clk), 
		.nanoAddr	(nanoAddr), 
		.nanoOutput	(nanoOutput)
		);
		
	uRom uRom( 
		.clk			( Clks.clk), 
		.microAddr	( microAddr), 
		.microOutput( microOutput));
	
	always_ff @( posedge Clks.clk) begin
		// uaddr originally latched on T1, except bits 6 & 7, the conditional bits, on T2
		// Seems we can latch whole address at either T1 or T2

		// Originally it's invalid on hardware reset, and forced later when coming out of reset
		if( Clks.pwrUp) begin
			microAddr <= RSTP0_NMA;
			nanoAddr <= RSTP0_NMA;
		end
		else if( enT1) begin
			microAddr <= nma;
			nanoAddr <= orgAddr;				// Register translated uaddr to naddr
		end
			
		if( Clks.extReset) begin
			microLatch <= '0;
			nanoLatch <= '0;
		end
		else if( rstUrom) begin
			// Originally reset these bits only. Not strictly needed like this.
			// Can reset the whole register if it is important.
			{ microLatch[16], microLatch[15], microLatch[0]} <= '0;
			nanoLatch <= '0;
		end
		else if( enT3) begin
			microLatch <= microOutput;
			nanoLatch <= nanoOutput;
		end
					
	end
	

	// Decoded nanocode signals
	s_nanod Nanod;
	// IRD decoded control signals
	s_irdecod Irdecod;

	//	
	reg Tpend;
	reg intPend;											// Interrupt pending
	reg pswT, pswS;
	reg [ 2:0] pswI;
	wire [7:0] ccr;
	
	wire [15:0] psw = { pswT, 1'b0, pswS, 2'b00, pswI, ccr};

	reg [15:0] ftu;
	reg [15:0] Irc, Ir, Ird;
	
	wire [15:0] alue;
	wire [15:0] Abl;
	wire prenEmpty, au05z, dcr4, ze;
	
	wire [UADDR_WIDTH-1:0] a1, a2, a3;
	wire isPriv, isIllegal, isLineA, isLineF;
	

	// IR & IRD forwarding
	always_ff @( posedge Clks.clk) begin
		if( enT1) begin
			if( Nanod.Ir2Ird)
				Ird <= Ir;
			else if(microLatch[0])		// prevented by IR => IRD !
				Ir <= Irc;
		end
	end
	
	wire [3:0] tvn;
	wire waitBusCycle, busStarting;
	wire BusRetry = 1'b0;
	wire busAddrErr;
	wire bciWrite;						// Last bus cycle was write
	wire bgBlock, busAvail;
	wire addrOe;

	wire busIsByte = Nanod.busByte & (Irdecod.isByte | Irdecod.isMovep);
	wire aob0;
	
	reg iStop;								// Internal signal for ending bus cycle
	reg A0Err;								// Force bus/address error ucode
	reg excRst;								// Signal reset exception to sequencer
	reg BerrA;
	reg Spuria, Avia;
	wire Iac;
	
	reg rAddrErr, iBusErr, Err6591;
	wire iAddrErr = rAddrErr & addrOe;		// To simulate async reset
	wire enErrClk;

	// Reset micro/nano latch after T4 of the current ublock.
	assign rstUrom = Clks.enPhi1 & enErrClk;

	uaddrDecode uaddrDecode( .opcode( Ir), .a1, .a2, .a3, .isPriv, .isIllegal, .isLineA, .isLineF, .lineBmap());

	sequencer sequencer( .Clks, .enT3, .microLatch, .Ird,
		.A0Err, .excRst, .BerrA, .busAddrErr, .Spuria, .Avia,
		.Tpend, .intPend, .isIllegal, .isPriv, .isLineA, .isLineF,
		.nma, .a1, .a2, .a3, .tvn,
		.psw, .prenEmpty, .au05z, .dcr4, .ze, .alue01( alue[1:0]), .i11( Irc[ 11]) );

	excUnit excUnit( .Clks, .Nanod, .Irdecod, .enT1, .enT2, .enT3, .enT4,
		.Ird, .ftu, .iEdb, .pswS,
		.prenEmpty, .au05z, .dcr4, .ze, .AblOut( Abl), .eab, .aob0, .Irc, .oEdb,
		.alue, .ccr);

	nDecoder3 nDecoder( .Clks, .Nanod, .Irdecod, .enT2, .enT4, .microLatch, .nanoLatch);
	
	irdDecode irdDecode( .ird( Ird), .Irdecod);
	
	busControl busControl( .Clks, .enT1, .enT4, .permStart( Nanod.permStart), .permStop( Nanod.waitBusFinish), .iStop,
		.aob0, .isWrite( Nanod.isWrite), .isRmc( Nanod.isRmc), .isByte( busIsByte), .busAvail,
		.bciWrite, .addrOe, .bgBlock, .waitBusCycle, .busStarting, .busAddrErr,
		.rDtack, .BeDebounced, .Vpai,
		.ASn, .LDSn, .UDSn, .eRWn);
		
	busArbiter busArbiter( .Clks, .BRi, .BgackI, .Halti( 1'b1), .bgBlock, .busAvail, .BGn);
		
		
	// Output reset & halt control
	wire [1:0] uFc = microLatch[ 16:15];
	logic oReset, oHalted;
	assign oRESETn = !oReset;
	assign oHALTEDn = !oHalted;
	
	// FC without permStart is special, either reset or halt
	always_ff @( posedge Clks.clk) begin
		if( Clks.pwrUp) begin
			oReset <= 1'b0;
			oHalted <= 1'b0;
		end
		else if( enT1) begin
			oReset <= (uFc == 2'b01) & !Nanod.permStart;
			oHalted <= (uFc == 2'b10) & !Nanod.permStart;
		end
	end
		
	logic [2:0] rFC;
	assign { FC2, FC1, FC0} = rFC;					// ~rFC;
	assign Iac = {rFC == 3'b111};					// & Control output enable !!

	always_ff @( posedge Clks.clk) begin
		if( Clks.extReset)
			rFC <= '0;
		else if( enT1 & Nanod.permStart) begin		// S0 phase of bus cycle
			rFC[2] <= pswS;
			// PC relativ access is marked as FC type 'n' (0) at ucode.
			// We don't care about RZ in this case. Those uinstructions with RZ don't start a bus cycle.
			rFC[1] <= microLatch[ 16] | ( ~microLatch[ 15] & ~Irdecod.isPcRel);
			rFC[0] <= microLatch[ 15] | ( ~microLatch[ 16] & Irdecod.isPcRel);
		end
	end
	
		
	// IPL interface
	reg [2:0] inl;							// Int level latch
	reg updIll;
	reg prevNmi;
	
	wire nmi = (iIpl == 3'b111);
	wire iplStable = (iIpl == rIpl);
	wire iplComp = iIpl > pswI;

	always_ff @( posedge Clks.clk) begin
		if( Clks.extReset) begin
			intPend <= 1'b0;
			prevNmi <= 1'b0;
		end
		else begin
			if( Clks.enPhi2)
				prevNmi <= nmi;
				
			// Originally async RS-Latch on PHI2, followed by a transparent latch on T2
			// Tricky because they might change simultaneously
			// Syncronous on PHI2 is equivalent as long as the output is read on T3!
			
			// Set on stable & NMI edge or compare
			// Clear on: NMI Iack or (stable & !NMI & !Compare)

			if( Clks.enPhi2) begin
				if( iplStable & ((nmi & ~prevNmi) | iplComp) )
					intPend <= 1'b1;
				else if( ((inl == 3'b111) & Iac) | (iplStable & !nmi & !iplComp) )
					intPend <= 1'b0;
			end			
		end
		
		if( Clks.extReset) begin
			inl <= '1;
			updIll <= 1'b0;
		end
		else if( enT4)
			updIll <= microLatch[0];		// Update on any IRC->IR
		else if( enT1 & updIll)
			inl <= iIpl;					// Timing is correct.
			
		// Spurious interrupt, BERR on Interrupt Ack.
		// Autovector interrupt. VPA on IACK.
		// Timing is tight. Spuria is deasserted just after exception exception is recorded.
		if( enT4) begin
			Spuria <= ~BeiDelay & Iac;
			Avia <= ~Vpai & Iac;
		end
			
	end
		
	assign enErrClk = iAddrErr | iBusErr;
	assign wClk = waitBusCycle | ~BeI | iAddrErr | Err6591;
	
	// E clock and counter, VMA
	reg [3:0] eCntr;
	reg rVma;
	
	assign VMAn = rVma;
	
	// Internal stop just one cycle before E falling edge
	wire xVma = ~rVma & (eCntr == 8);
	
	always_ff @( posedge Clks.clk) begin
		if( Clks.pwrUp) begin
			E <= 1'b0;
			eCntr <='0;
			rVma <= 1'b1;
		end
		if( Clks.enPhi2) begin
			if( eCntr == 9)
				E <= 1'b0;
			else if( eCntr == 5)
				E <= 1'b1;

			if( eCntr == 9)
				eCntr <= '0;
			else
				eCntr <= eCntr + 1'b1;
		end
		
		if( Clks.enPhi2 & addrOe & ~Vpai & (eCntr == 3))
			rVma <= 1'b0;
		else if( Clks.enPhi1 & eCntr == '0)
			rVma <= 1'b1;
	end
		
	always_ff @( posedge Clks.clk) begin
	
		// This timing is critical to stop the clock phases at the exact point on bus/addr error.
		// Timing should be such that current ublock completes (up to T3 or T4).
		// But T1 for the next ublock shouldn't happen. Next T1 only after resetting ucode and ncode latches.
		
		if( Clks.extReset)
			rAddrErr <= 1'b0;
		else if( Clks.enPhi1) begin
			if( busAddrErr & addrOe)		// Not on T1 ?!
				rAddrErr <= 1'b1;
			else if( ~addrOe)				// Actually async reset!
				rAddrErr <= 1'b0;
		end
		
		if( Clks.extReset)
			iBusErr <= 1'b0;
		else if( Clks.enPhi1) begin
			iBusErr <= ( BerrA & ~BeI & ~Iac & !BusRetry);
		end

		if( Clks.extReset)
			BerrA <= 1'b0;
		else if( Clks.enPhi2) begin
			if( ~BeI & ~Iac & addrOe)
				BerrA <= 1'b1;
			// else if( BeI & addrOe)			// Bad, async reset since addrOe raising edge
			else if( BeI & busStarting)			// So replaced with this that raises one cycle earlier
				BerrA <= 1'b0;
		end

		// Signal reset exception to sequencer.
		// Originally cleared on 1st T2 after permstart. Must keep it until TVN latched.
		if( Clks.extReset)
			excRst <= 1'b1;
		else if( enT2 & Nanod.permStart)
			excRst <= 1'b0;
		
		if( Clks.extReset)
			A0Err <= 1'b1;								// A0 Reset
		else if( enT3)									// Keep set until new urom words are being latched
			A0Err <= 1'b0;
		else if( Clks.enPhi1 & enErrClk & (busAddrErr | BerrA))		// Check bus error timing
			A0Err <= 1'b1;
		
		if( Clks.extReset) begin
			iStop <= 1'b0;
			Err6591 <= 1'b0;
		end
		else if( Clks.enPhi1)
			Err6591 <= enErrClk;
		else if( Clks.enPhi2)
			iStop <= xVma | (Vpai & (iAddrErr | ~rBerr));
	end
	
	// PSW
	logic irdToCcr_t4;
	always_ff @( posedge Clks.clk) begin				
		if( Clks.pwrUp) begin
			Tpend <= 1'b0;
			{pswT, pswS, pswI } <= '0;
			irdToCcr_t4 <= '0;
		end
		
		else if( enT4) begin
			irdToCcr_t4 <= Irdecod.toCcr;
		end
		
		else if( enT3) begin
		
			// UNIQUE IF !!	
			if( Nanod.updTpend)
				Tpend <= pswT;
			else if( Nanod.clrTpend)
				Tpend <= 1'b0;
			
			// UNIQUE IF !!	
			if( Nanod.ftu2Sr & !irdToCcr_t4)
				{pswT, pswS, pswI } <= { ftu[ 15], ftu[13], ftu[10:8]};
			else begin
				if( Nanod.initST) begin
					pswS <= 1'b1;
					pswT <= 1'b0;
				end
				if( Nanod.inl2psw)
					pswI <= inl;
			end
				
		end
	end
		
	// FTU
	reg [4:0] ssw;
	reg [3:0] tvnLatch;
	logic [15:0] tvnMux;
	reg inExcept01;
	
	// Seems CPU has a buglet here.
	// Flagging group 0 exceptions from TVN might not work because some bus cycles happen before TVN is updated.
	// But doesn't matter because a group 0 exception inside another one will halt the CPU anyway and won't save the SSW.
		
	always_ff @( posedge Clks.clk) begin
	
		// Updated at the start of the exception ucode
		if( Nanod.updSsw & enT3) begin
			ssw <= { ~bciWrite, inExcept01, rFC};
		end
	
		// Update TVN on T1 & IR=>IRD
		if( enT1 & Nanod.Ir2Ird) begin
			tvnLatch <= tvn;
			inExcept01 <= (tvn != 1);
		end
			
		if( Clks.pwrUp)
			ftu <= '0;
		else if( enT3) begin
			unique case( 1'b1)
			Nanod.tvn2Ftu:				ftu <= tvnMux;
			
			// 0 on unused bits seem to come from ftuConst PLA previously clearing FBUS
			Nanod.sr2Ftu:				ftu <= {pswT, 1'b0, pswS, 2'b00, pswI, 3'b000, ccr[4:0] };
			
			Nanod.ird2Ftu:				ftu <= Ird;
			Nanod.ssw2Ftu:				ftu[4:0] <= ssw;						// Undoc. Other bits must be preserved from IRD saved above!
			Nanod.pswIToFtu:			ftu <= { 12'hFFF, pswI, 1'b0};			// Interrupt level shifted
			Nanod.const2Ftu:			ftu <= Irdecod.ftuConst;
			Nanod.abl2Pren:				ftu <= Abl;								// From ALU or datareg. Used for SR modify
			default:					ftu <= ftu;
			endcase
		end
	end
	
	always_comb begin
		if( inExcept01) begin
			// Unique IF !!!
			if( tvnLatch == TVN_SPURIOUS)
				tvnMux = {9'b0, 5'd24, 2'b00};
			else if( tvnLatch == TVN_AUTOVEC)
				tvnMux = {9'b0, 2'b11, pswI, 2'b00};				// Set TVN PLA decoder
			else if( tvnLatch == TVN_INTERRUPT)
				tvnMux = {6'b0, Ird[7:0], 2'b00};					// Interrupt vector was read and transferred to IRD
			else
				tvnMux = {10'b0, tvnLatch, 2'b00};
		end
		else
			tvnMux = { 8'h0, Irdecod.macroTvn, 2'b00};
	end
				
endmodule 
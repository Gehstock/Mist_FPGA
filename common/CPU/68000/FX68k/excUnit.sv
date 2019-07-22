/*
 Execution unit

 Executes register transfers set by the microcode. Originally through a set of bidirectional buses.
 Most sources are available at T3, but DBIN only at T4! CCR also might be updated at T4, but it is not connected to these buses.
 We mux at T1 and T2, then transfer to the destination at T3. The exception is AOB that need to be updated earlier.

*/

module excUnit( input s_clks Clks,
	input enT1, enT2, enT3, enT4,
	input s_nanod Nanod, input s_irdecod Irdecod,
	input [15:0] Ird,			// ALU row (and others) decoder needs it	
	input pswS,
	input [15:0] ftu,
	input [15:0] iEdb,
	
	output logic [7:0] ccr,
	output [15:0] alue,
	
	output prenEmpty, au05z,
	output logic dcr4, ze,
	output logic aob0,
	output [15:0] AblOut,
	output logic [15:0] Irc,
	output logic [15:0] oEdb,
	output logic [23:1] eab);

localparam REG_USP = 15;
localparam REG_SSP = 16;
localparam REG_DT = 17;

	// Register file
	reg [15:0] regs68L[ 18];
	reg [15:0] regs68H[ 18];

// synthesis translate off
	/*
		It is bad practice to initialize simulation registers that the hardware doesn't.
		There is risk that simulation would be different than the real hardware. But in this case is the other way around.
		Some ROM uses something like sub.l An,An at powerup which clears the register
		Simulator power ups the registers with 'X, as they are really undetermined at the real hardware.
		But the simulator doesn't realize (it can't) that the same value is substracting from itself,
		and that the result should be zero even when it's 'X - 'X.
	*/
	
	initial begin
		for( int i = 0; i < 18; i++) begin
			regs68L[i] <= '0;
			regs68H[i] <= '0;
		end
	end
	
	// For simulation display only
	wire [31:0] SSP = { regs68H[REG_SSP], regs68L[REG_SSP]};
	
// synthesis translate on
	

	wire [15:0] aluOut;
	wire [15:0] dbin;
	logic [15:0] dcrOutput;

	reg [15:0] PcL, PcH;

	reg [31:0] auReg, aob;

	reg [15:0] Ath, Atl;

	// Bus execution
	reg [15:0] Dbl, Dbh;
	reg [15:0] Abh, Abl;
	reg [15:0] Abd, Dbd;
	
	assign AblOut = Abl;
	assign au05z = (~| auReg[5:0]);
	
	logic [15:0] dblMux, dbhMux;
	logic [15:0] abhMux, ablMux;
	logic [15:0] abdMux, dbdMux;
	
	logic abdIsByte;
		
	logic Pcl2Dbl, Pch2Dbh;
	logic Pcl2Abl, Pch2Abh;
	
	
	// RX RY muxes	
	// RX and RY actual registers
	logic [4:0] actualRx, actualRy;
	logic [3:0] movemRx;
	logic byteNotSpAlign;			// Byte instruction and no sp word align
	
	// IRD decoded signals must be latched. See comments on decoder
	// But nanostore decoding can't be latched before T4.
	//
	// If we need this earlier we can register IRD decode on T3 and use nano async

	logic [4:0] rxMux, ryMux;
	logic [3:0] rxReg, ryReg;
	logic rxIsSp, ryIsSp;
	logic rxIsAreg, ryIsAreg;
	
	always_comb begin
	
		// Unique IF !!
		if( Nanod.ssp) begin
			rxMux = REG_SSP;
			rxIsSp = 1'b1;
			rxReg = 1'bX;
		end
		else if( Irdecod.rxIsUsp) begin
			rxMux = REG_USP;
			rxIsSp = 1'b1;
			rxReg = 1'bX;
		end
		else if( Irdecod.rxIsDt & !Irdecod.implicitSp) begin
			rxMux = REG_DT;
			rxIsSp = 1'b0;
			rxReg = 1'bX;
		end
		else begin
			if( Irdecod.implicitSp)
				rxReg = 15;
			else if( Irdecod.rxIsMovem)
				rxReg = movemRx;
			else
				rxReg = { Irdecod.rxIsAreg, Irdecod.rx};
				
			if( (& rxReg)) begin
				rxMux = pswS ? REG_SSP : 15;
				rxIsSp = 1'b1;
			end
			else begin
				rxMux = { 1'b0, rxReg};
				rxIsSp = 1'b0;
			end
		end

		// RZ has higher priority!		
		if( Irdecod.ryIsDt & !Nanod.rz) begin
			ryMux = REG_DT;
			ryIsSp = 1'b0;
			ryReg = 'X;
		end
		else begin
			ryReg = Nanod.rz ? Irc[15:12] : {Irdecod.ryIsAreg, Irdecod.ry};
			ryIsSp = (& ryReg);
			if( ryIsSp & pswS)			// No implicit SP on RY
				ryMux = REG_SSP;
			else
				ryMux = { 1'b0, ryReg};
		end
					
	end	
	
	always_ff @( posedge Clks.clk) begin
		if( enT4) begin
			byteNotSpAlign <= Irdecod.isByte & ~(Nanod.rxlDbl ? rxIsSp : ryIsSp);
				
			actualRx <= rxMux;
			actualRy <= ryMux;
			
			rxIsAreg <= rxIsSp | rxMux[3];
			ryIsAreg <= ryIsSp | ryMux[3];			
		end
		
		if( enT4)
			abdIsByte <= Nanod.abdIsByte & Irdecod.isByte;
	end
			
	// Set RX/RY low word to which bus segment is connected.
		
	wire ryl2Abl = Nanod.ryl2ab & (ryIsAreg | Nanod.ablAbd);
	wire ryl2Abd = Nanod.ryl2ab & (~ryIsAreg | Nanod.ablAbd);
	wire ryl2Dbl = Nanod.ryl2db & (ryIsAreg | Nanod.dblDbd);
	wire ryl2Dbd = Nanod.ryl2db & (~ryIsAreg | Nanod.dblDbd);

	wire rxl2Abl = Nanod.rxl2ab & (rxIsAreg | Nanod.ablAbd);
	wire rxl2Abd = Nanod.rxl2ab & (~rxIsAreg | Nanod.ablAbd);
	wire rxl2Dbl = Nanod.rxl2db & (rxIsAreg | Nanod.dblDbd);
	wire rxl2Dbd = Nanod.rxl2db & (~rxIsAreg | Nanod.dblDbd);
	
	// Buses. Main mux
	
	logic abhIdle, ablIdle, abdIdle;
	logic dbhIdle, dblIdle, dbdIdle;
	
	always_comb begin
		{abhIdle, ablIdle, abdIdle} = '0;
		{dbhIdle, dblIdle, dbdIdle} = '0;

		unique case( 1'b1)
		ryl2Dbd:				dbdMux = regs68L[ actualRy];
		rxl2Dbd:				dbdMux = regs68L[ actualRx];
		Nanod.alue2Dbd:			dbdMux = alue;
		Nanod.dbin2Dbd:			dbdMux = dbin;
		Nanod.alu2Dbd:			dbdMux = aluOut;
		Nanod.dcr2Dbd:			dbdMux = dcrOutput;
		default: begin			dbdMux = 'X;	dbdIdle = 1'b1;				end
		endcase
	
		unique case( 1'b1)
		rxl2Dbl:				dblMux = regs68L[ actualRx];
		ryl2Dbl:				dblMux = regs68L[ actualRy];
		Nanod.ftu2Dbl:			dblMux = ftu;
		Nanod.au2Db:			dblMux = auReg[15:0];
		Nanod.atl2Dbl:			dblMux = Atl;
		Pcl2Dbl:				dblMux = PcL;
		default: begin			dblMux = 'X;	dblIdle = 1'b1;				end
		endcase
			
		unique case( 1'b1)
		Nanod.rxh2dbh:			dbhMux = regs68H[ actualRx];
		Nanod.ryh2dbh:			dbhMux = regs68H[ actualRy];
		Nanod.au2Db:			dbhMux = auReg[31:16];
		Nanod.ath2Dbh:			dbhMux = Ath;
		Pch2Dbh:				dbhMux = PcH;
		default: begin			dbhMux = 'X;	dbhIdle = 1'b1;				end
		endcase

		unique case( 1'b1)
		ryl2Abd:				abdMux = regs68L[ actualRy];
		rxl2Abd:				abdMux = regs68L[ actualRx];
		Nanod.dbin2Abd:			abdMux = dbin;
		Nanod.alu2Abd:			abdMux = aluOut;
		default: begin			abdMux = 'X;	abdIdle = 1'b1;				end
		endcase

		unique case( 1'b1)
		Pcl2Abl:				ablMux = PcL;
		rxl2Abl:				ablMux = regs68L[ actualRx];
		ryl2Abl:				ablMux = regs68L[ actualRy];
		Nanod.ftu2Abl:			ablMux = ftu;
		Nanod.au2Ab:			ablMux = auReg[15:0];
		Nanod.aob2Ab:			ablMux = aob[15:0];
		Nanod.atl2Abl:			ablMux = Atl;
		default: begin			ablMux = 'X;	ablIdle = 1'b1;				end
		endcase
			
		unique case( 1'b1)		
		Pch2Abh:				abhMux = PcH;
		Nanod.rxh2abh:			abhMux = regs68H[ actualRx];
		Nanod.ryh2abh:			abhMux = regs68H[ actualRy];
		Nanod.au2Ab:			abhMux = auReg[31:16];
		Nanod.aob2Ab:			abhMux = aob[31:16];
		Nanod.ath2Abh:			abhMux = Ath;
		default: begin			abhMux = 'X;	abhIdle = 1'b1;				end
		endcase
			
	end
	
	// Source starts driving the bus on T1. Bus holds data until end of T3. Destination latches at T3.

	// These registers store the first level mux, without bus interconnections.
	// Even when this uses almost to 100 registers, it saves a lot of comb muxing and it is much faster.
	reg [15:0] preAbh, preAbl, preAbd;
	reg [15:0] preDbh, preDbl, preDbd;
	
	always_ff @( posedge Clks.clk) begin

		// Register first level mux at T1		
		if( enT1) begin
			{preAbh, preAbl, preAbd} <= { abhMux, ablMux, abdMux};
			{preDbh, preDbl, preDbd} <= { dbhMux, dblMux, dbdMux};			
		end
		
		// Process bus interconnection at T2. Many combinations only used on DIV
		// We use a simple method. If a specific bus segment is not driven we know that it should get data from a neighbour segment.
		// In some cases this is not true and the segment is really idle without any destination. But then it doesn't matter.
		
		if( enT2) begin
			if( Nanod.extAbh)
				Abh <= { 16{ ablIdle ? preAbd[ 15] : preAbl[ 15] }};
			else if( abhIdle)
				Abh <= ablIdle ? preAbd : preAbl;
			else
				Abh <= preAbh;

			if( ~ablIdle)
				Abl <= preAbl;
			else
				Abl <= Nanod.ablAbh ? preAbh : preAbd;

			Abd <= ~abdIdle ? preAbd : ablIdle ? preAbh : preAbl;

			if( Nanod.extDbh)
				Dbh <= { 16{ dblIdle ? preDbd[ 15] : preDbl[ 15] }};
			else if( dbhIdle)
				Dbh <= dblIdle ? preDbd : preDbl;
			else
				Dbh <= preDbh;

			if( ~dblIdle)
				Dbl <= preDbl;
			else
				Dbl <= Nanod.dblDbh ? preDbh : preDbd;

			Dbd <= ~dbdIdle ? preDbd: dblIdle ? preDbh : preDbl;
			
			/*
			Dbl <= dblMux;			Dbh <= dbhMux;
			Abd <= abdMux;			Dbd <= dbdMux;
			Abh <= abhMux;			Abl <= ablMux; */
		end
	end

	// AOB
	//
	// Originally change on T1. We do on T2, only then the output is enabled anyway.
	//
	// AOB[0] is used for address error. But even when raises on T1, seems not actually used until T2 or possibly T3.
	// It is used on T1 when deasserted at the BSER exception ucode. Probably deassertion timing is not critical. 
	// But in that case (at BSER), AOB is loaded from AU, so we can safely transfer on T1.

	// We need to take directly from first level muxes that are updated and T1
			
	wire au2Aob = Nanod.au2Aob | (Nanod.au2Db & Nanod.db2Aob);
	
	always_ff @( posedge Clks.clk) begin
		// UNIQUE IF !
		
		if( enT1 & au2Aob)		// From AU we do can on T1
			aob <= auReg;
		else if( enT2) begin
			if( Nanod.db2Aob)
				aob <= { preDbh, ~dblIdle ? preDbl : preDbd};
			else if( Nanod.ab2Aob)
				aob <= { preAbh, ~ablIdle ? preAbl : preAbd};
		end
	end

	assign eab = aob[23:1];
	assign aob0 = aob[0];
				
	// AU
	logic [31:0] auInpMux;

	// `ifdef ALW_COMB_BUG
	// Old Modelsim bug. Doesn't update ouput always. Need excplicit sensitivity list !?
	// always @( Nanod.auCntrl) begin
	
	always_comb begin
		unique case( Nanod.auCntrl)
		3'b000:		auInpMux = 0;
		3'b001:		auInpMux = byteNotSpAlign | Nanod.noSpAlign ? 1 : 2;		// +1/+2
		3'b010:		auInpMux = -4;
		3'b011:		auInpMux = { Abh, Abl};
		3'b100:		auInpMux = 2;
		3'b101:		auInpMux = 4;
		3'b110:		auInpMux = -2;
		3'b111:		auInpMux = byteNotSpAlign | Nanod.noSpAlign ? -1 : -2;	// -1/-2
		default:	auInpMux = 'X;
		endcase
	end

	// Simulation problem
	// Sometimes (like in MULM1) DBH is not set. AU is used in these cases just as a 6 bits counter testing if bits 5-0 are zero.
	// But when adding something like 32'hXXXX0000, the simulator (incorrectly) will set *all the 32 bits* of the result as X.

// synthesis translate_off 
	`define SIMULBUGX32 1
	wire [16:0] aulow = Dbl + auInpMux[15:0];
	wire [31:0] auResult = {Dbh + auInpMux[31:16] + aulow[16], aulow[15:0]};
// synthesis translate_on

	always_ff @( posedge Clks.clk) begin
		if( Clks.pwrUp)
			auReg <= '0;
		else if( enT3 & Nanod.auClkEn)
			`ifdef SIMULBUGX32
				auReg <= auResult;
			`else
				auReg <= { Dbh, Dbl } + auInpMux;
			`endif
	end
	
	
	// Main A/D registers
	
	always_ff @( posedge Clks.clk) begin
		if( enT3) begin
			if( Nanod.dbl2rxl | Nanod.abl2rxl) begin
				if( ~rxIsAreg) begin
					if( Nanod.dbl2rxl)			regs68L[ actualRx] <= Dbd;
					else if( abdIsByte)			regs68L[ actualRx][7:0] <= Abd[7:0];
					else						regs68L[ actualRx] <= Abd;
				end
				else
					regs68L[ actualRx] <= Nanod.dbl2rxl ? Dbl : Abl;
			end
				
			if( Nanod.dbl2ryl | Nanod.abl2ryl) begin
				if( ~ryIsAreg) begin
					if( Nanod.dbl2ryl)			regs68L[ actualRy] <= Dbd;
					else if( abdIsByte)			regs68L[ actualRy][7:0] <= Abd[7:0];
					else						regs68L[ actualRy] <= Abd;				
				end
				else
					regs68L[ actualRy] <= Nanod.dbl2ryl ? Dbl : Abl;
			end
			
			// High registers are easier. Both A & D on the same buses, and not byte ops.
			if( Nanod.dbh2rxh | Nanod.abh2rxh)
				regs68H[ actualRx] <= Nanod.dbh2rxh ? Dbh : Abh;
			if( Nanod.dbh2ryh | Nanod.abh2ryh)
				regs68H[ actualRy] <= Nanod.dbh2ryh ? Dbh : Abh;
				
		end	
	end
		
	// PC & AT
	reg dbl2Pcl, dbh2Pch, abh2Pch, abl2Pcl;
		
	always_ff @( posedge Clks.clk) begin
		if( Clks.extReset) begin
			{ dbl2Pcl, dbh2Pch, abh2Pch, abl2Pcl } <= '0;
			
			Pcl2Dbl <= 1'b0;
			Pch2Dbh <= 1'b0;
			Pcl2Abl <= 1'b0;
			Pch2Abh <= 1'b0;
		end
		else if( enT4) begin				// Must latch on T4 !
			dbl2Pcl <= Nanod.dbl2reg & Nanod.pcldbl;
			dbh2Pch <= Nanod.dbh2reg & Nanod.pchdbh;
			abh2Pch <= Nanod.abh2reg & Nanod.pchabh;
			abl2Pcl <= Nanod.abl2reg & Nanod.pclabl;
			
			Pcl2Dbl <= Nanod.reg2dbl & Nanod.pcldbl;
			Pch2Dbh <= Nanod.reg2dbh & Nanod.pchdbh;
			Pcl2Abl <= Nanod.reg2abl & Nanod.pclabl;
			Pch2Abh <= Nanod.reg2abh & Nanod.pchabh;
		end
		
		// Unique IF !!!
		if( enT1 & Nanod.au2Pc)
			PcL <= auReg[15:0];
		else if( enT3) begin
			if( dbl2Pcl)
				PcL <= Dbl;
			else if( abl2Pcl)
				PcL <= Abl;
		end
			
		// Unique IF !!!
		if( enT1 & Nanod.au2Pc)
			PcH <= auReg[31:16];
		else if( enT3) begin
			if( dbh2Pch)
				PcH <= Dbh;
			else if( abh2Pch)
				PcH <= Abh;
		end

		// Unique IF !!!
		if( enT3) begin
			if( Nanod.dbl2Atl)
				Atl <= Dbl;
			else if( Nanod.abl2Atl)
				Atl <= Abl;
		end

		// Unique IF !!!
		if( enT3) begin
			if( Nanod.abh2Ath)
				Ath <= Abh;
			else if( Nanod.dbh2Ath)
				Ath <= Dbh;
		end

	end

	// Movem reg mask priority encoder
	
	wire rmIdle;
	logic [3:0] prHbit;
	logic [15:0] prenLatch;
	
	// Invert reg order for predecrement mode
	assign prenEmpty = (~| prenLatch);	
	pren rmPren( .mask( prenLatch), .hbit (prHbit));

	always_ff @( posedge Clks.clk) begin
		// Cheating: PREN always loaded from DBIN
		// Must be on T1 to branch earlier if reg mask is empty!
		if( enT1 & Nanod.abl2Pren)
			prenLatch <= dbin;
		else if( enT3 & Nanod.updPren) begin
			prenLatch [prHbit] <= 1'b0;
			movemRx <= Irdecod.movemPreDecr ? ~prHbit : prHbit;
		end
	end
	
	// DCR
	wire [15:0] dcrCode;

	wire [3:0] dcrInput = abdIsByte ? { 1'b0, Abd[ 2:0]} : Abd[ 3:0];
	onehotEncoder4 dcrDecoder( .bin( dcrInput), .bitMap( dcrCode));
	
	always_ff @( posedge Clks.clk) begin
		if( Clks.pwrUp)
			dcr4 <= '0;
		else if( enT3 & Nanod.abd2Dcr) begin
			dcrOutput <= dcrCode;
			dcr4 <= Abd[4];
		end
	end
	
	// ALUB
	reg [15:0] alub;
	
	always_ff @( posedge Clks.clk) begin
		if( enT3) begin
			// UNIQUE IF !!
			if( Nanod.dbd2Alub)
				alub <= Dbd;
			else if( Nanod.abd2Alub)
				alub <= Abd;				// abdIsByte affects this !!??
		end
	end
	
	wire alueClkEn = enT3 & Nanod.dbd2Alue;

	// DOB/DBIN/IRC
	
	logic [15:0] dobInput;
	wire dobIdle = (~| Nanod.dobCtrl);
	
	always_comb begin
		unique case (Nanod.dobCtrl)
		NANO_DOB_ADB:		dobInput = Abd;
		NANO_DOB_DBD:		dobInput = Dbd;
		NANO_DOB_ALU:		dobInput = aluOut;
		default:			dobInput = 'X;
		endcase
	end

	dataIo dataIo( .Clks, .enT1, .enT2, .enT3, .enT4, .Nanod, .Irdecod,
			.iEdb, .dobIdle, .dobInput, .aob0,
			.Irc, .dbin, .oEdb);

	fx68kAlu alu(
		.clk( Clks.clk), .pwrUp( Clks.pwrUp), .enT1, .enT3, .enT4,
		.ird( Ird),
		.aluColumn( Nanod.aluColumn), .aluAddrCtrl( Nanod.aluActrl),
		.init( Nanod.aluInit), .finish( Nanod.aluFinish), .aluIsByte( Irdecod.isByte),
		.ftu2Ccr( Nanod.ftu2Ccr),
		.alub, .ftu, .alueClkEn, .alue,
		.aluDataCtrl( Nanod.aluDctrl), .iDataBus( Dbd), .iAddrBus(Abd),
		.ze, .aluOut, .ccr);

endmodule 

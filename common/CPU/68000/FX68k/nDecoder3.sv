// Nanorom (plus) decoder for die nanocode
module nDecoder3( input s_clks Clks, input s_irdecod Irdecod, output s_nanod Nanod,
	input enT2, enT4,
	input [UROM_WIDTH-1:0] microLatch,
	input [NANO_WIDTH-1:0] nanoLatch);

localparam NANO_IR2IRD = 67;
localparam NANO_TOIRC = 66;
localparam NANO_ALU_COL = 63;		// ALU operator column order is 63-64-65 !
localparam NANO_ALU_FI = 61;	// ALU finish-init 62-61
localparam NANO_TODBIN = 60;
localparam NANO_ALUE = 57;			// 57-59 shared with DCR control
localparam NANO_DCR = 57;			// 57-59 shared with ALUE control
localparam NANO_DOBCTRL_1 = 56;		// Input to control and permwrite
localparam NANO_LOWBYTE = 55;		// Used by MOVEP
localparam NANO_HIGHBYTE = 54;
localparam NANO_DOBCTRL_0 = 53;		// Input to control and permwrite
localparam NANO_ALU_DCTRL = 51;	// 52-51 databus input mux control
localparam NANO_ALU_ACTRL = 50;	// addrbus input mux control
localparam NANO_DBD2ALUB = 49;
localparam NANO_ABD2ALUB = 48;
localparam NANO_DBIN2DBD = 47;
localparam NANO_DBIN2ABD = 46;
localparam NANO_ALU2ABD = 45;
localparam NANO_ALU2DBD = 44;
localparam NANO_RZ = 43;
localparam NANO_BUSBYTE = 42;		// If *both* this set and instruction is byte sized, then bus cycle is byte sized.
localparam NANO_PCLABL = 41;
localparam NANO_RXL_DBL = 40;		// Switches RXL/RYL on DBL/ABL buses
localparam NANO_PCLDBL = 39;
localparam NANO_ABDHRECHARGE = 38;
localparam NANO_REG2ABL = 37;		// register to ABL
localparam NANO_ABL2REG = 36;		// ABL to register
localparam NANO_ABLABD = 35;
localparam NANO_DBLDBD = 34;
localparam NANO_DBL2REG = 33;		// DBL to register
localparam NANO_REG2DBL = 32;		// register to DBL
localparam NANO_ATLCTRL = 29;		// 31-29
localparam NANO_FTUCONTROL = 25;
localparam NANO_SSP = 24;
localparam NANO_RXH_DBH = 22;		// Switches RXH/RYH on DBH/ABH buses
localparam NANO_AUOUT = 20;			// 21-20
localparam NANO_AUCLKEN = 19;
localparam NANO_AUCTRL = 16;		// 18-16
localparam NANO_DBLDBH = 15;
localparam NANO_ABLABH = 14;
localparam NANO_EXT_ABH = 13;
localparam NANO_EXT_DBH = 12;
localparam NANO_ATHCTRL = 9;		// 11-9
localparam NANO_REG2ABH = 8;		// register to ABH
localparam NANO_ABH2REG = 7;		// ABH to register
localparam NANO_REG2DBH = 6;		// register to DBH
localparam NANO_DBH2REG = 5;		// DBH to register
localparam NANO_AOBCTRL = 3;		// 4-3
localparam NANO_PCH = 0;			// 1-0 PchDbh PchAbh
localparam NANO_NO_SP_ALGN = 0;		// Same bits as above when both set

localparam NANO_FTU_UPDTPEND = 1;		// Also loads FTU constant according to IRD !
localparam NANO_FTU_INIT_ST = 15;		// Set S, clear T (but not TPEND)
localparam NANO_FTU_CLRTPEND = 14;
localparam NANO_FTU_TVN = 13;
localparam NANO_FTU_ABL2PREN = 12;		// ABL => FTU & ABL => PREN. Both transfers enabled, but only one will be used depending on uroutine.
localparam NANO_FTU_SSW = 11;
localparam NANO_FTU_RSTPREN = 10;
localparam NANO_FTU_IRD = 9;
localparam NANO_FTU_2ABL = 8;
localparam NANO_FTU_RDSR = 7;
localparam NANO_FTU_INL = 6;
localparam NANO_FTU_PSWI = 5;		// Read Int Mask into FTU
localparam NANO_FTU_DBL = 4;
localparam NANO_FTU_2SR = 2;
localparam NANO_FTU_CONST = 1;

	reg [3:0] ftuCtrl;	
	
	logic [2:0] athCtrl, atlCtrl;
	assign athCtrl = nanoLatch[ NANO_ATHCTRL+2: NANO_ATHCTRL];
	assign atlCtrl = nanoLatch[ NANO_ATLCTRL+2: NANO_ATLCTRL];
	wire [1:0] aobCtrl = nanoLatch[ NANO_AOBCTRL+1:NANO_AOBCTRL];
	wire [1:0] dobCtrl = {nanoLatch[ NANO_DOBCTRL_1], nanoLatch[NANO_DOBCTRL_0]};
	
	always_ff @( posedge Clks.clk) begin
		if( enT4) begin
			// Reverse order!
			ftuCtrl <= { nanoLatch[ NANO_FTUCONTROL+0], nanoLatch[ NANO_FTUCONTROL+1], nanoLatch[ NANO_FTUCONTROL+2], nanoLatch[ NANO_FTUCONTROL+3]} ;
				
			Nanod.auClkEn <= !nanoLatch[ NANO_AUCLKEN];
			Nanod.auCntrl <= nanoLatch[ NANO_AUCTRL+2 : NANO_AUCTRL+0];
			Nanod.noSpAlign <= (nanoLatch[ NANO_NO_SP_ALGN + 1:NANO_NO_SP_ALGN] == 2'b11);			
			Nanod.extDbh <= nanoLatch[ NANO_EXT_DBH];
			Nanod.extAbh <= nanoLatch[ NANO_EXT_ABH];
			Nanod.todbin <= nanoLatch[ NANO_TODBIN];
			Nanod.toIrc <=  nanoLatch[ NANO_TOIRC];
			
			// ablAbd is disabled on byte transfers (adbhCharge plus irdIsByte). Not sure the combination makes much sense.
			// It happens in a few cases but I don't see anything enabled on abL (or abH) section anyway.
			
			Nanod.ablAbd <= nanoLatch[ NANO_ABLABD];
			Nanod.ablAbh <= nanoLatch[ NANO_ABLABH];
			Nanod.dblDbd <= nanoLatch[ NANO_DBLDBD];
			Nanod.dblDbh <= nanoLatch[ NANO_DBLDBH];
			
			Nanod.dbl2Atl <= (atlCtrl == 3'b010);
			Nanod.atl2Dbl <= (atlCtrl == 3'b011);
			Nanod.abl2Atl <= (atlCtrl == 3'b100);
			Nanod.atl2Abl <= (atlCtrl == 3'b101);

			Nanod.aob2Ab <= (athCtrl == 3'b101);		// Used on BSER1 only
			
			Nanod.abh2Ath <= (athCtrl == 3'b001) | (athCtrl == 3'b101);
			Nanod.dbh2Ath <= (athCtrl == 3'b100);
			Nanod.ath2Dbh <= (athCtrl == 3'b110);
			Nanod.ath2Abh <= (athCtrl == 3'b011);			

			Nanod.alu2Dbd <= nanoLatch[ NANO_ALU2DBD];
			Nanod.alu2Abd <= nanoLatch[ NANO_ALU2ABD];
			
			Nanod.abd2Dcr <= (nanoLatch[ NANO_DCR+1:NANO_DCR] == 2'b11);
			Nanod.dcr2Dbd <= (nanoLatch[ NANO_DCR+2:NANO_DCR+1] == 2'b11);
			Nanod.dbd2Alue <= (nanoLatch[ NANO_ALUE+2:NANO_ALUE+1] == 2'b10);
			Nanod.alue2Dbd <= (nanoLatch[ NANO_ALUE+1:NANO_ALUE] == 2'b01);

			Nanod.dbd2Alub <= nanoLatch[ NANO_DBD2ALUB];
			Nanod.abd2Alub <= nanoLatch[ NANO_ABD2ALUB];			
			
			// Originally not latched. We better should because we transfer one cycle later, T3 instead of T1.
			Nanod.dobCtrl <= dobCtrl;
			// Nanod.adb2Dob <= (dobCtrl == 2'b10);			Nanod.dbd2Dob <= (dobCtrl == 2'b01);			Nanod.alu2Dob <= (dobCtrl == 2'b11);
							
		end
	end
	
	// Update SSW at the start of Bus/Addr error ucode
	assign Nanod.updSsw = Nanod.aob2Ab;

	assign Nanod.updTpend = (ftuCtrl == NANO_FTU_UPDTPEND);
	assign Nanod.clrTpend = (ftuCtrl == NANO_FTU_CLRTPEND);
	assign Nanod.tvn2Ftu = (ftuCtrl == NANO_FTU_TVN);
	assign Nanod.const2Ftu = (ftuCtrl == NANO_FTU_CONST);
	assign Nanod.ftu2Dbl = (ftuCtrl == NANO_FTU_DBL) | ( ftuCtrl == NANO_FTU_INL);	
	assign Nanod.ftu2Abl = (ftuCtrl == NANO_FTU_2ABL);	
	assign Nanod.inl2psw = (ftuCtrl == NANO_FTU_INL);
	assign Nanod.pswIToFtu = (ftuCtrl == NANO_FTU_PSWI);
	assign Nanod.ftu2Sr = (ftuCtrl == NANO_FTU_2SR);
	assign Nanod.sr2Ftu = (ftuCtrl == NANO_FTU_RDSR);
	assign Nanod.ird2Ftu = (ftuCtrl == NANO_FTU_IRD);		// Used on bus/addr error
	assign Nanod.ssw2Ftu = (ftuCtrl == NANO_FTU_SSW);
	assign Nanod.initST = (ftuCtrl == NANO_FTU_INL) | (ftuCtrl == NANO_FTU_CLRTPEND) | (ftuCtrl == NANO_FTU_INIT_ST);
	assign Nanod.abl2Pren = (ftuCtrl == NANO_FTU_ABL2PREN);
	assign Nanod.updPren = (ftuCtrl == NANO_FTU_RSTPREN);
	
	assign Nanod.Ir2Ird = nanoLatch[ NANO_IR2IRD];

	// ALU control better latched later after combining with IRD decoding
		
	assign Nanod.aluDctrl = nanoLatch[ NANO_ALU_DCTRL+1 : NANO_ALU_DCTRL];
	assign Nanod.aluActrl = nanoLatch[ NANO_ALU_ACTRL];
	assign Nanod.aluColumn = { nanoLatch[ NANO_ALU_COL], nanoLatch[ NANO_ALU_COL+1], nanoLatch[ NANO_ALU_COL+2]};
	wire [1:0] aluFinInit = nanoLatch[ NANO_ALU_FI+1:NANO_ALU_FI];
	assign Nanod.aluFinish = (aluFinInit == 2'b10);
	assign Nanod.aluInit = (aluFinInit == 2'b01);

	// FTU 2 CCR encoded as both ALU Init and ALU Finish set.
	// In theory this encoding allows writes to CCR without writing to SR
	// But FTU 2 CCR and to SR are both set together at nanorom.
	assign Nanod.ftu2Ccr = ( aluFinInit == 2'b11);

	assign Nanod.abdIsByte = nanoLatch[ NANO_ABDHRECHARGE];
	
	// Not being latched on T4 creates non unique case warning!
	assign Nanod.au2Db = (nanoLatch[ NANO_AUOUT + 1: NANO_AUOUT] == 2'b01);
	assign Nanod.au2Ab = (nanoLatch[ NANO_AUOUT + 1: NANO_AUOUT] == 2'b10);
	assign Nanod.au2Pc = (nanoLatch[ NANO_AUOUT + 1: NANO_AUOUT] == 2'b11);
	
	assign Nanod.db2Aob = (aobCtrl == 2'b10);
	assign Nanod.ab2Aob = (aobCtrl == 2'b01);
	assign Nanod.au2Aob = (aobCtrl == 2'b11);
	
	assign Nanod.dbin2Abd = nanoLatch[ NANO_DBIN2ABD];
	assign Nanod.dbin2Dbd = nanoLatch[ NANO_DBIN2DBD];
	
	assign Nanod.permStart = (| aobCtrl);
	assign Nanod.isWrite  = ( | dobCtrl);
	assign Nanod.waitBusFinish = nanoLatch[ NANO_TOIRC] | nanoLatch[ NANO_TODBIN] | Nanod.isWrite;
	assign Nanod.busByte = nanoLatch[ NANO_BUSBYTE];
	
	assign Nanod.noLowByte = nanoLatch[ NANO_LOWBYTE];
	assign Nanod.noHighByte = nanoLatch[ NANO_HIGHBYTE];	
			
	// Not registered. Register at T4 after combining
	// Might be better to remove all those and combine here instead of at execution unit !!
	assign Nanod.abl2reg = nanoLatch[ NANO_ABL2REG];
	assign Nanod.abh2reg = nanoLatch[ NANO_ABH2REG];
	assign Nanod.dbl2reg = nanoLatch[ NANO_DBL2REG];
	assign Nanod.dbh2reg = nanoLatch[ NANO_DBH2REG];
	assign Nanod.reg2dbl = nanoLatch[ NANO_REG2DBL];
	assign Nanod.reg2dbh = nanoLatch[ NANO_REG2DBH];
	assign Nanod.reg2abl = nanoLatch[ NANO_REG2ABL];
	assign Nanod.reg2abh = nanoLatch[ NANO_REG2ABH];
	
	assign Nanod.ssp = nanoLatch[ NANO_SSP];
	
	assign Nanod.rz = nanoLatch[ NANO_RZ];
	
	// Actually DTL can't happen on PC relative mode. See IR decoder.
	
	wire dtldbd = 1'b0;
	wire dthdbh = 1'b0;
	wire dtlabd = 1'b0;
	wire dthabh = 1'b0;
	
	wire dblSpecial = Nanod.pcldbl | dtldbd;
	wire dbhSpecial = Nanod.pchdbh | dthdbh;
	wire ablSpecial = Nanod.pclabl | dtlabd;
	wire abhSpecial = Nanod.pchabh | dthabh;
			
	//
	// Combine with IRD decoding
	// Careful that IRD is updated only on T1! All output depending on IRD must be latched on T4!
	//
	
	// PC used instead of RY on PC relative instuctions
	
	assign Nanod.rxlDbl = nanoLatch[ NANO_RXL_DBL];
	wire isPcRel = Irdecod.isPcRel & !Nanod.rz;
	wire pcRelDbl = isPcRel & !nanoLatch[ NANO_RXL_DBL];
	wire pcRelDbh = isPcRel & !nanoLatch[ NANO_RXH_DBH];
	wire pcRelAbl = isPcRel & nanoLatch[ NANO_RXL_DBL];
	wire pcRelAbh = isPcRel & nanoLatch[ NANO_RXH_DBH];
	
	assign Nanod.pcldbl = nanoLatch[ NANO_PCLDBL] | pcRelDbl;
	assign Nanod.pchdbh = (nanoLatch[ NANO_PCH+1:NANO_PCH] == 2'b01) | pcRelDbh;
	
	assign Nanod.pclabl = nanoLatch[ NANO_PCLABL] | pcRelAbl;
	assign Nanod.pchabh = (nanoLatch[ NANO_PCH+1:NANO_PCH] == 2'b10) | pcRelAbh;

	// Might be better not to register these signals to allow latching RX/RY mux earlier!
	// But then must latch Irdecod.isPcRel on T3!

	always_ff @( posedge Clks.clk) begin
		if( enT4) begin
			Nanod.rxl2db <= Nanod.reg2dbl & !dblSpecial & nanoLatch[ NANO_RXL_DBL];
			Nanod.rxl2ab <= Nanod.reg2abl & !ablSpecial & !nanoLatch[ NANO_RXL_DBL];
			
			Nanod.dbl2rxl <= Nanod.dbl2reg & !dblSpecial & nanoLatch[ NANO_RXL_DBL];	
			Nanod.abl2rxl <= Nanod.abl2reg & !ablSpecial & !nanoLatch[ NANO_RXL_DBL];	

			Nanod.rxh2dbh <= Nanod.reg2dbh & !dbhSpecial & nanoLatch[ NANO_RXH_DBH];			
			Nanod.rxh2abh <= Nanod.reg2abh & !abhSpecial & !nanoLatch[ NANO_RXH_DBH];			
				
			Nanod.dbh2rxh <= Nanod.dbh2reg & !dbhSpecial & nanoLatch[ NANO_RXH_DBH];
			Nanod.abh2rxh <= Nanod.abh2reg & !abhSpecial & !nanoLatch[ NANO_RXH_DBH];	

			Nanod.dbh2ryh <= Nanod.dbh2reg & !dbhSpecial & !nanoLatch[ NANO_RXH_DBH];
			Nanod.abh2ryh <= Nanod.abh2reg & !abhSpecial & nanoLatch[ NANO_RXH_DBH];	

			Nanod.dbl2ryl <= Nanod.dbl2reg & !dblSpecial & !nanoLatch[ NANO_RXL_DBL];	
			Nanod.abl2ryl <= Nanod.abl2reg & !ablSpecial & nanoLatch[ NANO_RXL_DBL];	

			Nanod.ryl2db <= Nanod.reg2dbl & !dblSpecial & !nanoLatch[ NANO_RXL_DBL];
			Nanod.ryl2ab <= Nanod.reg2abl & !ablSpecial & nanoLatch[ NANO_RXL_DBL];

			Nanod.ryh2dbh <= Nanod.reg2dbh & !dbhSpecial & !nanoLatch[ NANO_RXH_DBH];			
			Nanod.ryh2abh <= Nanod.reg2abh & !abhSpecial & nanoLatch[ NANO_RXH_DBH];					
		end
		
		// Originally isTas only delayed on T2 (and seems only a late mask rev fix)
		// Better latch the combination on T4
		if( enT4)
			Nanod.isRmc <= Irdecod.isTas & nanoLatch[ NANO_BUSBYTE];
	end
			
	
endmodule 
module busControl( input s_clks Clks, input enT1, input enT4,
		input permStart, permStop, iStop,
		input aob0,
		input isWrite, isByte, isRmc,
		input busAvail,
		output bgBlock,
		output busAddrErr,
		output waitBusCycle,
		output busStarting,			// Asserted during S0
		output logic addrOe,		// Asserted from S1 to the end, whole bus cycle except S0
		output bciWrite,			// Used for SSW on bus/addr error
		
		input rDtack, BeDebounced, Vpai,
		output ASn, output LDSn, output UDSn, eRWn);

	reg rAS, rLDS, rUDS, rRWn;
	assign ASn = rAS;
	assign LDSn = rLDS;
	assign UDSn = rUDS;
	assign eRWn = rRWn;

	reg dataOe;
		
	reg bcPend;
	reg isWriteReg, bciByte, isRmcReg, wendReg;
	assign bciWrite = isWriteReg;
	reg addrOeDelay;
	reg isByteT4;

	wire canStart, busEnd;
	wire bcComplete, bcReset;
	
	wire isRcmReset = bcComplete & bcReset & isRmcReg;
	
	assign busAddrErr = aob0 & ~bciByte;
	
	// Bus retry not really supported.
	// It's BERR and HALT and not address error, and not read-modify cycle.
	wire busRetry = ~busAddrErr & 1'b0;
	
	enum int unsigned { SRESET = 0, SIDLE, S0, S2, S4, S6, SRMC_RES} busPhase, next;

	always_ff @( posedge Clks.clk) begin
		if( Clks.extReset)
			busPhase <= SRESET;
		else if( Clks.enPhi1)
			busPhase <= next;
	end
	
	always_comb begin
		case( busPhase)
		SRESET:		next = SIDLE;
		SRMC_RES:	next = SIDLE;			// Single cycle special state when read phase of RMC reset
		S0:			next = S2;
		S2:			next = S4;
		S4:			next = busEnd ? S6 : S4;
		S6:			next = isRcmReset ? SRMC_RES : (canStart ? S0 : SIDLE);
		SIDLE:		next = canStart ? S0 : SIDLE;
		default:	next = SIDLE;
		endcase
	end	
	
	// Idle phase of RMC bus cycle. Might be better to just add a new state
	wire rmcIdle = (busPhase == SIDLE) & ~ASn & isRmcReg;
		
	assign canStart = (busAvail | rmcIdle) & (bcPend | permStart) & !busRetry & !bcReset;
		
	wire busEnding = (next == SIDLE) | (next == S0);
	
	assign busStarting = (busPhase == S0);
		
	// term signal (DTACK, BERR, VPA, adress error)
	assign busEnd = ~rDtack | iStop;
				
	// bcComplete asserted on raising edge of S6 (together with SNC).
	assign bcComplete = (busPhase == S6);
	
	// Clear bus info latch on completion (regular or aborted) and no bus retry (and not PHI1).
	// bciClear asserted half clock later on PHI2, and bci latches cleared async concurrently
	wire bciClear = bcComplete & ~busRetry;
	
	// Reset on reset or (berr & berrDelay & (not halt or rmc) & not 6800 & in bus cycle) (and not PHI1)
	assign bcReset = Clks.extReset | (addrOeDelay & BeDebounced & Vpai);
		
	// Enable uclock only on S6 (S8 on Bus Error) or not bciPermStop
	assign waitBusCycle = wendReg & !bcComplete;
	
	// Block Bus Grant when starting new bus cycle. But No need if AS already asserted (read phase of RMC)
	// Except that when that RMC phase aborted on bus error, it's asserted one cycle later!
	assign bgBlock = ((busPhase == S0) & ASn) | (busPhase == SRMC_RES);
	
	always_ff @( posedge Clks.clk) begin
		if( Clks.extReset) begin
			addrOe <= 1'b0;
		end
		else if( Clks.enPhi2 & ( busPhase == S0))			// From S1, whole bus cycle except S0
				addrOe <= 1'b1;
		else if( Clks.enPhi1 & (busPhase == SRMC_RES))
			addrOe <= 1'b0;
		else if( Clks.enPhi1 & ~isRmcReg & busEnding)
			addrOe <= 1'b0;
			
		if( Clks.enPhi1)
			addrOeDelay <= addrOe;
		
		if( Clks.extReset) begin
			rAS <= 1'b1;
			rUDS <= 1'b1;
			rLDS <= 1'b1;
			rRWn <= 1'b1;
			dataOe <= '0;
		end
		else begin

			if( Clks.enPhi2 & isWriteReg & (busPhase == S2))
				dataOe <= 1'b1;
			else if( Clks.enPhi1 & (busEnding | (busPhase == SIDLE)) )
				dataOe <= 1'b0;
						
			if( Clks.enPhi1 & busEnding)
				rRWn <= 1'b1;
			else if( Clks.enPhi1 & isWriteReg) begin
				// Unlike LDS/UDS Asserted even in address error
				if( (busPhase == S0) & isWriteReg)
					rRWn <= 1'b0;
			end

			// AS. Actually follows addrOe half cycle later!
			if( Clks.enPhi1 & (busPhase == S0))
				rAS <= 1'b0;
			else if( Clks.enPhi2 & (busPhase == SRMC_RES))		// Bus error on read phase of RMC. Deasserted one cycle later
				rAS <= 1'b1;			
			else if( Clks.enPhi2 & bcComplete & ~SRMC_RES)
				if( ~isRmcReg)									// Keep AS asserted on the IDLE phase of RMC
					rAS <= 1'b1;
			
			if( Clks.enPhi1 & (busPhase == S0)) begin
				if( ~isWriteReg & !busAddrErr) begin
					rUDS <= ~(~bciByte | ~aob0);
					rLDS <= ~(~bciByte | aob0);
				end
			end
			else if( Clks.enPhi1 & isWriteReg & (busPhase == S2) & !busAddrErr) begin
					rUDS <= ~(~bciByte | ~aob0);
					rLDS <= ~(~bciByte | aob0);
			end		
			else if( Clks.enPhi2 & bcComplete) begin
				rUDS <= 1'b1;
				rLDS <= 1'b1;
			end
			
		end
		
	end
	
	// Bus cycle info latch. Needed because uinstr might change if the bus is busy and we must wait.
	// Note that urom advances even on wait states. It waits *after* updating urom and nanorom latches.
	// Even without wait states, ublocks of type ir (init reading) will not wait for bus completion.
	// Originally latched on (permStart AND T1).
	
	// Bus cycle info latch: isRead, isByte, read-modify-cycle, and permStart (bus cycle pending). Some previously latched on T4?
	// permStop also latched, but unconditionally on T1
	
	// Might make more sense to register this outside this module
	always_ff @( posedge Clks.clk) begin
		if( enT4) begin
			isByteT4 <= isByte;
		end
	end
	
	// Bus Cycle Info Latch
	always_ff @( posedge Clks.clk) begin
		if( Clks.pwrUp) begin
			bcPend <= 1'b0;
			wendReg <= 1'b0;	
			isWriteReg <= 1'b0;
			bciByte <= 1'b0;
			isRmcReg <= 1'b0;		
		end
		
		else if( Clks.enPhi2 & (bciClear | bcReset)) begin
			bcPend <= 1'b0;
			wendReg <= 1'b0;
		end
		else begin
			if( enT1 & permStart) begin
				isWriteReg <= isWrite;
				bciByte <= isByteT4;
				isRmcReg <= isRmc & ~isWrite;	// We need special case the end of the read phase only.
				bcPend <= 1'b1;
			end
			if( enT1)
				wendReg <= permStop;
		end
	end
			
endmodule 
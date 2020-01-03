//
// Data bus I/O
// At a separate module because it is a bit complicated and the timing is special.
// Here we do the low/high byte mux and the special case of MOVEP.
//
// Original implementation is rather complex because both the internal and external buses are bidirectional.
// Input is latched async at the EDB register.
// We capture directly from the external data bus to the internal registers (IRC & DBIN) on PHI2, starting the external S7 phase, at a T4 internal period.

module dataIo( input s_clks Clks,
	input enT1, enT2, enT3, enT4,
	input s_nanod Nanod, input s_irdecod Irdecod,
	input [15:0] iEdb,
	input aob0,

	input dobIdle,
	input [15:0] dobInput,
	
	output logic [15:0] Irc,	
	output logic [15:0] dbin,
	output logic [15:0] oEdb
	);

	reg [15:0] dob;
	
	// DBIN/IRC
	
	// Timing is different than any other register. We can latch only on the next T4 (bus phase S7).
	// We need to register all control signals correctly because the next ublock will already be started.
	// Can't latch control on T4 because if there are wait states there might be multiple T4 before we latch.
	
	reg xToDbin, xToIrc;
	reg dbinNoLow, dbinNoHigh;
	reg byteMux, isByte_T4;
	
	always_ff @( posedge Clks.clk) begin
	
		// Byte mux control. Can't latch at T1. AOB might be not ready yet.
		// Must latch IRD decode at T1 (or T4). Then combine and latch only at T3.

		// Can't latch at T3, a new IRD might be loaded already at T1.	
		// Ok to latch at T4 if combination latched then at T3
		if( enT4)
			isByte_T4 <= Irdecod.isByte;	// Includes MOVEP from mem, we could OR it here

		if( enT3) begin
			dbinNoHigh <= Nanod.noHighByte;
			dbinNoLow <= Nanod.noLowByte;
			byteMux <= Nanod.busByte & isByte_T4 & ~aob0;
		end
		
		if( enT1) begin
			// If on wait states, we continue latching until next T1
			xToDbin <= 1'b0;
			xToIrc <= 1'b0;			
		end
		else if( enT3) begin
			xToDbin <= Nanod.todbin;
			xToIrc <= Nanod.toIrc;
		end

		// Capture on T4 of the next ucycle
		// If there are wait states, we keep capturing every PHI2 until the next T1
		
		if( xToIrc & Clks.enPhi2)
			Irc <= iEdb;
		if( xToDbin & Clks.enPhi2) begin
			// Original connects both halves of EDB.
			if( ~dbinNoLow)
				dbin[ 7:0] <= byteMux ? iEdb[ 15:8] : iEdb[7:0];
			if( ~dbinNoHigh)
				dbin[ 15:8] <= ~byteMux & dbinNoLow ? iEdb[ 7:0] : iEdb[ 15:8];
		end
	end
	
	// DOB
	logic byteCycle;	
	
	always_ff @( posedge Clks.clk) begin
		// Originaly on T1. Transfer to internal EDB also on T1 (stays enabled upto the next T1). But only on T4 (S3) output enables.
		// It is safe to do on T3, then, but control signals if derived from IRD must be registered.
		// Originally control signals are not registered.
		
		// Wait states don't affect DOB operation that is done at the start of the bus cycle. 

		if( enT4)
			byteCycle <= Nanod.busByte & Irdecod.isByte;		// busIsByte but not MOVEP
		
		// Originally byte low/high interconnect is done at EDB, not at DOB.
		if( enT3 & ~dobIdle) begin
			dob[7:0] <= Nanod.noLowByte ? dobInput[15:8] : dobInput[ 7:0];
			dob[15:8] <= (byteCycle | Nanod.noHighByte) ? dobInput[ 7:0] : dobInput[15:8];
		end
	end
	assign oEdb = dob;

endmodule 
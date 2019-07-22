
//
// For compilation test only
//

module fx68k_tb( input clk32, 
	input extReset,
	// input pwrUp,

	input DTACKn, input VPAn,
	input BERRn,
	input BRn, BGACKn,
	input IPL0n, input IPL1n, input IPL2n,
	input [15:0] iEdb,
	
	output [15:0] oEdb,
	output eRWn, output ASn, output LDSn, output UDSn,
	output logic E, output VMAn,	
	output FC0, output FC1, output FC2,
	output BGn,
	output oRESETn, output oHALTEDn,
	output [23:1] eab
	);

	// Clock must be at least twice the desired frequency. A 32 MHz clock means a maximum 16 MHz effective frequency.
	// In this example we divide the clock by 4. Resulting on an effective processor running at 8 MHz.
	
	reg [1:0] clkDivisor = '0;
	always @( posedge clk32) begin
		clkDivisor <= clkDivisor + 1'b1;
	end
		
	/*
	These two signals must be a single cycle pulse. They don't need to be registered.
	Same signal can't be asserted twice in a row. Other than that there are no restrictions.
	There can be any number of cycles, or none, even variable non constant cycles, between each pulse.
	*/
	
	wire enPhi1 = (clkDivisor == 2'b11);
	wire enPhi2 = (clkDivisor == 2'b01);
		
		
	fx68k fx68k( .clk( clk32),
		.extReset, .pwrUp( extReset), .enPhi1, .enPhi2,
	
		.DTACKn, .VPAn, .BERRn, .BRn, .BGACKn,
		.IPL0n, .IPL1n, .IPL2n,
		.iEdb,
		
		.oEdb,
		.eRWn, .ASn, .LDSn, .UDSn,
		.E, .VMAn,	
		.FC0, .FC1, .FC2,
		.BGn,
		.oRESETn, .oHALTEDn, .eab);

endmodule 
`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
//
// Create Date:    21:05:44 04/24/2018
// Design Name:    LS139
// Module Name:    system86/src/ttl/ls139_tb.v
// Project Name:   Namco System86 simulation
//// Target Device:  
// Tool versions:  
// Description:    LS139 - Dual 2-Line To 4-Line Decoder/Demultiplexer - test bench
//
// Verilog Test Fixture created by ISE for module: LS139
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License:        https://www.apache.org/licenses/LICENSE-2.0
// 
////////////////////////////////////////////////////////////////////////////////

module LS139_tb;

	// Inputs
	reg Ea;
	reg A0a;
	reg A1a;
	reg Eb;
	reg A0b;
	reg A1b;

	// Outputs
	wire O0a;
	wire O1a;
	wire O2a;
	wire O3a;
	wire O0b;
	wire O1b;
	wire O2b;
	wire O3b;

	// Instantiate the Unit Under Test (UUT)
	LS139 uut (
		.Ea(Ea), 
		.A0a(A0a), 
		.A1a(A1a), 
		.Eb(Eb), 
		.A0b(A0b), 
		.A1b(A1b), 
		.O0a(O0a), 
		.O1a(O1a), 
		.O2a(O2a), 
		.O3a(O3a), 
		.O0b(O0b), 
		.O1b(O1b), 
		.O2b(O2b), 
		.O3b(O3b)
	);

	integer e;
	integer i;
	
	initial begin
		// Initialize Inputs
		Ea = 0;
		A0a = 0;
		A1a = 0;
		Eb = 0;
		A0b = 0;
		A1b = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		$display("A0\tA1\tEa\tEb\tO0a\tO1a\tO2a\tO3a\tO0b\tO1b\tO2b\tO3b");
		
		for (e = 0; e < 4; e=e+1) begin
			Ea = e[0];
			Eb = e[1];
			for (i = 0; i < 16; i=i+1) begin
				A0a = i[0];
				A1a = i[1];
				A0b = i[0];
				A1b = i[1];
				#4
				$display("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s", 
					i[0] ? "H" : "L", 
					i[1] ? "H" : "L", 
					Ea ? "H" : "L", 
					Eb ? "H" : "L", 
					O0a ? "H" : "L",
					O1a ? "H" : "L",
					O2a ? "H" : "L",
					O3a ? "H" : "L",
					O0b ? "H" : "L",
					O1b ? "H" : "L",
					O2b ? "H" : "L",
					O3b ? "H" : "L",);
			end
		end

		$finish;
	end
      
endmodule


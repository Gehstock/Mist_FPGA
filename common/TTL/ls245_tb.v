`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:      Paul Wightmore
//
// Create Date:   19:38:32 05/01/2018
// Design Name:   LS245
// Module Name:   System86/LS245_tb.v
// Project Name:  Namco System86 simulation
// Target Device:  
// Tool versions:  
// Description:   LS245 - Octal Bus Transceiver - test bench
//
// Verilog Test Fixture created by ISE for module: LS245
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License:        https://www.apache.org/licenses/LICENSE-2.0
// 
////////////////////////////////////////////////////////////////////////////////

module LS245_tb;

	// Inputs
	reg DIR;
	reg OE;

	// Bidirs
	wire [7:0] A;
	wire [7:0] B;

	reg [7:0] AIn = 'h99;	
	reg [7:0] BIn = 'h66;
	
	assign A = DIR ? AIn : 8'bZ;
	assign B = ~DIR ? BIn : 8'bZ;
	
	// Instantiate the Unit Under Test (UUT)
	LS245 uut (
		.DIR(DIR), 
		.OE(OE), 
		.A(A),
		.B(B)
	);

	integer e;
	integer d;

	initial begin
		// Initialize Inputs
		DIR = 0;
		OE = 0;
		
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		$display("OE\tDIR\tAIn\tBIn\tAOut\tBOut");
		
		for (e = 0; e <= 1; e=e+1) begin
			OE <= e[0];
			
			for (d = 0; d <= 1; d=d+1) begin
				
				DIR <= d[0];
					
				#4
				$display("%s\t%s\t0x%x\t0x%x\t0x%x\t0x%x", 
					OE ? "H" : "L",
					DIR ? "H" : "L", 
					AIn,
					BIn,
					A, 
					B);
				end
			end
			
			$finish;
		end
      
endmodule


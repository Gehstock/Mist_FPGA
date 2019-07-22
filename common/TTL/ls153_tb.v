`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
//
// Create Date:    20:24:08 04/24/2018
// Design Name:    LS153
// Module Name:    system86/src/ttl/ls153_tb.v
// Project Name:   Namco System86 simulation
//// Target Device:  
// Tool versions:  
// Description:    LS153 - Dual 4-Input Multiplexer - test bench
//
// Verilog Test Fixture created by ISE for module: LS153
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License:        https://www.apache.org/licenses/LICENSE-2.0
// 
////////////////////////////////////////////////////////////////////////////////

module LS153_tb;

	// Inputs
	reg S0;
	reg S1;
	reg Ea;
	reg I0a;
	reg I1a;
	reg I2a;
	reg I3a;
	reg Eb;
	reg I0b;
	reg I1b;
	reg I2b;
	reg I3b;

	// Outputs
	wire Za;
	wire Zb;

	// Instantiate the Unit Under Test (UUT)
	LS153 uut (
		.S0(S0), 
		.S1(S1), 
		.Ea(Ea), 
		.I0a(I0a), 
		.I1a(I1a), 
		.I2a(I2a), 
		.I3a(I3a), 
		.Eb(Eb), 
		.I0b(I0b), 
		.I1b(I1b), 
		.I2b(I2b), 
		.I3b(I3b), 
		.Za(Za), 
		.Zb(Zb)
	);

	integer e;
	integer s;
	integer i;
	
	initial begin
		// Initialize Inputs
		S0 = 0;
		S1 = 0;
		Ea = 0;
		I0a = 0;
		I1a = 0;
		I2a = 0;
		I3a = 0;
		Eb = 0;
		I0b = 0;
		I1b = 0;
		I2b = 0;
		I3b = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		$display("S0\tS1\tI0\tI1\tI2\tI3\tEa\tEb\tZa\tZb");
		
		for (e = 0; e < 4; e=e+1) begin
			Ea = e[0];
			Eb = e[1];
			for (s = 0; s < 4; s=s+1) begin
				S0 = s[0];
				S1 = s[1];
				for (i = 0; i < 16; i=i+1) begin
					I0a = i[0];
					I1a = i[1];
					I2a = i[2];
					I3a = i[3];
					I0b = i[0];
					I1b = i[1];
					I2b = i[2];
					I3b = i[3];
					#4
					$display("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s", 
						S0 ? "H" : "L",
						S1 ? "H" : "L", 
						i[0] ? "H" : "L", 
						i[1] ? "H" : "L", 
						i[2] ? "H" : "L", 
						i[3] ? "H" : "L", 
						Ea ? "H" : "L", 
						Eb ? "H" : "L", 
						Za ? "H" : "L",
						Zb ? "H" : "L");
				end
			end
		end

		$finish;
	end
      
endmodule


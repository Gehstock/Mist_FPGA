/*MIT License

Copyright (c) 2019 Gregory Hogan (Soltan_G42)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

//This is a variation of Gregory Hogan's MISTer Genesis core low-pass filter
//tuned to match the heaviest low-pass filter on Time Pilot.

module tp_lpf_heavy(
	input clk,
	input reset,
	input signed [15:0] in,
	output signed [15:0] out);
	
	reg [9:0] div = 220; //Sample at 49.152/220 = 223418Hz
	
	//Coefficients computed with Octave/Matlab/Online filter calculators.
	//or with scipy.signal.bessel or similar tools
	
	//0.0041276697, 0.0041276697
	//1.0000000, -0.99174466
	reg signed [17:0] A2;
	reg signed [17:0] B2;
	reg signed [17:0] B1;
	
	wire signed [15:0] audio_post_lpf1;
		
	always @ (*) begin
		A2 = -18'd32498;
		B1 = 18'd135;
		B2 = 18'd135;
	end
	
	iir_1st_order lpf6db(.clk(clk),
								.reset(reset),
								.div(div),
								.A2(A2),
								.B1(B1),
								.B2(B2),
								.in(in),
								.out(audio_post_lpf1)); 
	 
	assign out = audio_post_lpf1;

endmodule

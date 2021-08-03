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
//tuned to low-pass filter the YM2151 on Jackal.

module jackal_lpf(
	input clk,
	input reset,
	input select,
	input signed [15:0] in1,
	input signed [15:0] in2,
	output signed [15:0] out);
	
	localparam div = 10'd64; //Sample at 49.152MHz/64 = 768000Hz
	
	//Coefficients computed with Octave/Matlab/Online filter calculators.
	//or with scipy.signal.bessel or similar tools
	
	//0.015398864, 0.015398864
	//1.0000000, -0.96920227
	reg signed [17:0] lpf1_A2;
	reg signed [17:0] lpf1_B2;
	reg signed [17:0] lpf1_B1;
	
	//0.018668513, 0.018668513
	//1.0000000, -0.96266297
	reg signed [17:0] lpf2_A2;
	reg signed [17:0] lpf2_B2;
	reg signed [17:0] lpf2_B1;
	
	wire signed [15:0] audio_pre_lpf1 = select ? in1 : in2;
	wire signed [15:0] audio_post_lpf1, audio_post_lpf2;
		
	always @ (*) begin
		lpf1_A2 = -18'd31758;
		lpf1_B1 = 18'd505;
		lpf1_B2 = 18'd505;
		lpf2_A2 = -18'd31544;
		lpf2_B1 = 18'd612;
		lpf2_B2 = 18'd612;
	end
	
	iir_1st_order lpf1_6db(.clk(clk),
								.reset(reset),
								.div(div),
								.A2(lpf1_A2),
								.B1(lpf1_B1),
								.B2(lpf1_B2),
								.in(audio_pre_lpf1),
								.out(audio_post_lpf1)); 
	
	iir_1st_order lpf2_6db(.clk(clk),
								.reset(reset),
								.div(div),
								.A2(lpf2_A2),
								.B1(lpf2_B1),
								.B2(lpf2_B2),
								.in(audio_post_lpf1),
								.out(audio_post_lpf2)); 
	 
	assign out = select ? audio_post_lpf1 : audio_post_lpf2;

endmodule

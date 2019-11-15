//============================================================================
// DAC Discharge Circuit
// 
// Author: gaz68 (https://github.com/gaz68)
// October 2019
//
// Simulation of capacitor discharge circuit to pin 14 input of DAC-08.
// Components R20, C32 and Q4 on schematics.
// Adds decay to some sounds and background tunes.
//============================================================================

module dkongjr_dac
(
	input		I_CLK,
	input		I_DECAY_EN,
	input  	I_RESET_n,
	input		signed [15:0]I_SND_DAT,
	output	signed [15:0]O_SND_DAT
);

// Exponential decay. Timing of decay steps calculated using: 
// 	v = exp(-(t / (r * c)))
// Where:
//		t = 1 / sample rate (48,000Hz)
// 	r = 10,000 (10KOhm)
// 	c = 0.00001 (10uf)
// for v scaled up to 8-bit values.
wire [14:0] exp_lut[0:255] = 
'{
	15'h000A, 15'h001D, 15'h0030, 15'h0043, 15'h0056, 15'h0069, 15'h007C, 15'h0090,
	15'h00A3, 15'h00B7, 15'h00CA, 15'h00DE, 15'h00F2, 15'h0106, 15'h011A, 15'h012E,
	15'h0142, 15'h0156, 15'h016A, 15'h017E, 15'h0193, 15'h01A7, 15'h01BC, 15'h01D1,
	15'h01E5, 15'h01FA, 15'h020F, 15'h0224, 15'h0239, 15'h024F, 15'h0264, 15'h0279,
	15'h028F, 15'h02A5, 15'h02BA, 15'h02D0, 15'h02E6, 15'h02FC, 15'h0312, 15'h0328,
	15'h033F, 15'h0355, 15'h036C, 15'h0382, 15'h0399, 15'h03B0, 15'h03C7, 15'h03DE,
	15'h03F5, 15'h040C, 15'h0424, 15'h043B, 15'h0453, 15'h046B, 15'h0483, 15'h049B,
	15'h04B3, 15'h04CB, 15'h04E3, 15'h04FC, 15'h0514, 15'h052D, 15'h0546, 15'h055F,
	15'h0578, 15'h0591, 15'h05AB, 15'h05C4, 15'h05DE, 15'h05F8, 15'h0612, 15'h062C,
	15'h0646, 15'h0661, 15'h067B, 15'h0696, 15'h06B1, 15'h06CC, 15'h06E7, 15'h0702,
	15'h071D, 15'h0739, 15'h0755, 15'h0771, 15'h078D, 15'h07A9, 15'h07C5, 15'h07E2,
	15'h07FF, 15'h081C, 15'h0839, 15'h0856, 15'h0873, 15'h0891, 15'h08AF, 15'h08CD,
	15'h08EB, 15'h0909, 15'h0928, 15'h0947, 15'h0966, 15'h0985, 15'h09A4, 15'h09C4,
	15'h09E4, 15'h0A04, 15'h0A24, 15'h0A44, 15'h0A65, 15'h0A86, 15'h0AA7, 15'h0AC8,
	15'h0AEA, 15'h0B0C, 15'h0B2E, 15'h0B50, 15'h0B72, 15'h0B95, 15'h0BB8, 15'h0BDC,
	15'h0BFF, 15'h0C23, 15'h0C47, 15'h0C6B, 15'h0C90, 15'h0CB5, 15'h0CDA, 15'h0D00,
	15'h0D25, 15'h0D4B, 15'h0D72, 15'h0D99, 15'h0DC0, 15'h0DE7, 15'h0E0F, 15'h0E37,
	15'h0E5F, 15'h0E88, 15'h0EB1, 15'h0EDA, 15'h0F04, 15'h0F2E, 15'h0F58, 15'h0F83,
	15'h0FAE, 15'h0FDA, 15'h1006, 15'h1033, 15'h105F, 15'h108D, 15'h10BA, 15'h10E9,
	15'h1117, 15'h1146, 15'h1176, 15'h11A6, 15'h11D6, 15'h1207, 15'h1239, 15'h126B,
	15'h129D, 15'h12D0, 15'h1304, 15'h1338, 15'h136D, 15'h13A2, 15'h13D8, 15'h140F,
	15'h1446, 15'h147E, 15'h14B6, 15'h14EF, 15'h1529, 15'h1564, 15'h159F, 15'h15DB,
	15'h1618, 15'h1655, 15'h1694, 15'h16D3, 15'h1713, 15'h1754, 15'h1795, 15'h17D8,
	15'h181C, 15'h1860, 15'h18A6, 15'h18EC, 15'h1934, 15'h197D, 15'h19C7, 15'h1A12,
	15'h1A5E, 15'h1AAB, 15'h1AFA, 15'h1B4A, 15'h1B9B, 15'h1BEE, 15'h1C42, 15'h1C98,
	15'h1CEF, 15'h1D48, 15'h1DA3, 15'h1DFF, 15'h1E5D, 15'h1EBD, 15'h1F1F, 15'h1F83,
	15'h1FE9, 15'h2052, 15'h20BC, 15'h2129, 15'h2199, 15'h220B, 15'h2280, 15'h22F8,
	15'h2373, 15'h23F2, 15'h2473, 15'h24F9, 15'h2582, 15'h260F, 15'h26A1, 15'h2737,
	15'h27D1, 15'h2871, 15'h2917, 15'h29C2, 15'h2A74, 15'h2B2D, 15'h2BED, 15'h2CB5,
	15'h2D86, 15'h2E60, 15'h2F45, 15'h3035, 15'h3131, 15'h323C, 15'h3356, 15'h3483,
	15'h35C3, 15'h371A, 15'h388B, 15'h3A1B, 15'h3BD0, 15'h3DB0, 15'h3FC6, 15'h421F,
	15'h44CE, 15'h47F0, 15'h4BB3, 15'h5069, 15'h56B8, 15'h604C, 15'h74E6, 15'h7FFF
};

parameter div = 512; // 24.576MHz/512 = 48KHz
reg   [11:0]sample;
reg   sample_pls;

always@(posedge I_CLK or negedge I_RESET_n)
begin
  if(! I_RESET_n) begin
    sample <= 0;
    sample_pls <= 0;
  end else begin
    sample <= (sample == div-1) ? 1'b0 : sample + 1'b1;
    sample_pls <= (sample == div-1)? 1'b1 : 1'b0 ;
  end
end


reg	signed [8:0]expval;
reg	[7:0]index;
reg	[14:0]count;
reg 	signed [23:0]snd_out;

always@(posedge I_CLK or negedge I_RESET_n)
begin
	if(!I_RESET_n) begin
		expval <= 9'sd255;
		count <= 0;
		index <= 0;
	end
	else begin
		
		if (sample_pls) begin
		
			if (I_DECAY_EN) begin
			
				count <= (count == 15'h7FF0) ? 15'h7FF0 : count + 1'b1;

				if (count == exp_lut[index]) begin
					index <= (index == 8'd255) ? 8'd255 : index + 1'b1;
					expval <= (expval == 0) ? 1'b0 : expval - 1'b1;
				end
			end
			else begin

				expval <= (expval == 9'sd255) ? 9'sd255 : expval + 1'b1;
				count <= 0;
				index <= 0;
			end

			snd_out <= I_SND_DAT * expval;

		end
	end
end

assign O_SND_DAT = snd_out[23:8];

endmodule


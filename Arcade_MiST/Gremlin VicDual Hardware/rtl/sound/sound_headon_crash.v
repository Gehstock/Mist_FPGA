`timescale 1 ps / 1 ps

module sound_headon_crash
(
	input clk,
	input clk_48KHz_en,
	input crash_en,
	output reg[15:0] out
);

	reg[15:0] crash_sample[26144];
	reg[14:0] sample_counter = 15'd26145;
	reg crash_en_last;

	always @(posedge clk)
	begin
		crash_en_last <= crash_en;
		if (crash_en && !crash_en_last)
		begin
			sample_counter <= 0;
		end

		if (clk_48KHz_en)
		begin
			if(sample_counter < 15'd26144)
			begin
				out <= crash_sample[sample_counter];
				sample_counter <= sample_counter + 1'b1;
			end
			else
			begin
				out <= 0;
			end
		end
	end

	// initial begin
	// `include "sound_headon_crash_sample.v"
	// end

endmodule
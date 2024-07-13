`timescale 1 ps / 1 ps

module sound_headon_bonus
(
	input clk,
	input clk_48KHz_en,
	input bonus_en,
	output reg[15:0] out = 0
);
/* verilator lint_off WIDTH */
	localparam [68:0] MAX_AMPLITUDE = 1 << 18 << 14;
	wire[1:0] WAVEFORM_SLOW[131:0];
	wire[1:0] WAVEFORM_FAST[98:0];
	assign WAVEFORM_SLOW[97] = 1;
	assign WAVEFORM_SLOW[131] = 1;
	assign WAVEFORM_FAST[57] = 1;
	assign WAVEFORM_FAST[78] = 1;

	genvar i;
	generate
		for (i = 0; i <= 96; i = i + 1) begin:wavslow1
			assign WAVEFORM_SLOW[i] = 2;
		end
		for (i = 98; i <= 130; i = i + 1) begin:wavslow2
			assign WAVEFORM_SLOW[i] = 0;
		end
	endgenerate

	genvar j;
	generate
		for (j = 0; j <= 56; j = j + 1) begin:wavfast1
			assign WAVEFORM_FAST[j] = 2;
		end
		for (j = 58; j <= 77; j = j + 1) begin:wavfast2
			assign WAVEFORM_FAST[j] = 0;
		end
	endgenerate
	

	localparam [68:0] AMPLITUDE_RATIO_PER_TIMESTEP_18 = 69'd262008; // z^(28ms*48khz) = 0.5, so z = 0.99948, 0.99948 * 2^18 = 262008

	reg[32:0] current_sample = 0;
	reg[68:0] amplitude = 0;

	reg last_bonus_en = 0;
	reg[15:0] bonus_en_ago = 0;

	localparam [15:0] SLOW_TO_FAST_RATIO_16 = 16'd39222; // 79/132 * 2 ^ 16 = 39222.3030303
	wire[32:0] map_slow_to_fast;
	assign map_slow_to_fast = ((current_sample * SLOW_TO_FAST_RATIO_16) >> 16);

	reg[32:0] bonus_en_length = 0;

	always @(posedge clk) begin
		if(clk_48KHz_en)begin
			if(bonus_en || bonus_en_ago < (11 * 132))begin
				bonus_en_length <= bonus_en_length + 1;

                if(current_sample == 131)begin
                    current_sample <= 0;
                end else begin
                    current_sample <= current_sample + 1;
                end

                if(bonus_en_length >= 55 * 132)begin
                    if(current_sample >= 78)begin
                        current_sample <= 0;
                        out <= (amplitude * WAVEFORM_FAST[0]) >> 18;
                    end else begin
                        current_sample <= current_sample + 1;
                        out <= (amplitude * WAVEFORM_FAST[current_sample]) >> 18;
                    end
                    if(bonus_en_length == 75 * 132) begin
                        bonus_en_length <= 0;
                    end
                end else begin
                    out <= (amplitude * WAVEFORM_SLOW[current_sample]) >> 18;
                end

			// $display("current_sample: %d   out: %d   amp: %d", current_sample, out, amplitude);
                if(~bonus_en)begin
                    bonus_en_ago <= bonus_en_ago + 1;
                    last_bonus_en <= 1;
                    amplitude <= (AMPLITUDE_RATIO_PER_TIMESTEP_18 * amplitude) >> 18;
                end else begin
                    amplitude <= MAX_AMPLITUDE;
                    bonus_en_ago <= 0;
                end
            end else begin
                if(last_bonus_en)begin
                    bonus_en_length <= 0;
                    last_bonus_en <= 0;
                    current_sample <= map_slow_to_fast;
                    out <= (amplitude * WAVEFORM_FAST[map_slow_to_fast]) >> 18;
                end else begin
                    if(current_sample >= 78)begin
                        current_sample <= 0;
                    end else begin
                        current_sample <= current_sample + 1;
                    end
                    out <= (amplitude * WAVEFORM_FAST[current_sample]) >> 18;
                end
                amplitude <= (AMPLITUDE_RATIO_PER_TIMESTEP_18 * amplitude) >> 18;
            end

		end 
	end
/* verilator lint_on WIDTH */
endmodule
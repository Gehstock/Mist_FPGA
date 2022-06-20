module audio (
	input               clk, // clk_sys
	input               ce,
	input               reset,
	input               snd_cs,
	input               cpu_rwn,
	input  [5:0]        AB,
	input  [7:0]        dbus_in,
	input  [15:0]       prescaler,
	input               adma_irq_en,

	output reg [15:0]   adma_addr,
	output reg          adma_irq_n,
	output reg          adma_read,
	output [2:0]        adma_bank,

	output [3:0]        CH1,
	output [3:0]        CH2
);

typedef enum bit[5:0] {
	CH1_FREQ_LOW     = 6'h10,
	CH1_FREQ_HIGH    = 6'h11,
	CH1_VDUTY        = 6'h12,
	CH1_FRAME_LEN    = 6'h13,
	CH2_FREQ_LOW     = 6'h14,
	CH2_FREQ_HIGH    = 6'h15,
	CH2_VDUTY        = 6'h16,
	CH2_FRAME_LEN    = 6'h17,
	ADMA_ADDR_LO     = 6'h18,
	ADMA_ADDR_HI     = 6'h19,
	ADMA_LENGTH      = 6'h1A,
	ADMA_CONFIG      = 6'h1B,
	ADMA_REQ         = 6'h1C,
	ADMA_ACK         = 6'h25,
	NOISE_VDIV       = 6'h28,
	NOISE_LENGTH     = 6'h29,
	NOISE_CONFIG     = 6'h2A
} apu_reg_t;

reg [23:0] clk_cnt;
reg pulse;
reg ch1_mute, ch2_mute, noise_mute;
reg [14:0] lfsr;
reg [10:0] ch1_freq, ch2_freq;
reg [3:0] adma_phase;
reg [7:0] adma_config, adma_length, adma_sample;
reg adma_sample_pending, adma_active;
reg CH1_sw, CH2_sw; // square wave
reg [7:0] noise_vdiv, noise_timer, noise_config, ch1_vdiv, ch2_vdiv;
reg [7:0] CH1_dlength, CH2_dlength, ch1_timer, ch2_timer;
reg [16:0] CH1_sum, CH2_sum, noise_sum, adma_sum;

wire [3:0] CH1_dc, CH2_dc; // duty cycle
wire [3:0] adma_out = adma_sample_pending ? adma_sample[7:4] : adma_sample[3:0];
wire [16:0] noise_div = (17'd8 << noise_vdiv[7:4]) - 1'd1;
wire lfsr_next = noise_config[0] ? (lfsr[14] ^ lfsr[13]) : (lfsr[6] ^ lfsr[5]);

wire [3:0] CH1_out = CH1_sw ? ch1_vdiv[3:0] : 4'd0;
wire [3:0] CH2_out = CH2_sw ? ch2_vdiv[3:0] : 4'd0;
wire [3:0] noise_out = lfsr_next ? noise_vdiv[3:0] : 4'd0;

wire CH1_en = ~ch1_mute || ch1_vdiv[6] ? 1'b1 : 1'b0;
wire CH2_en = ~ch2_mute || ch2_vdiv[6] ? 1'b1 : 1'b0;
wire noise_en = ~noise_mute || noise_config[1] ? noise_config[4] : 1'b0;

// Clamp to 4 bits (real system had a 4 bit dac and did this)
wire [5:0] ch1_unclamped = (CH1_en ? CH1_out : 6'd0) + (adma_active && adma_config[2] ? adma_out : 6'd0) + (noise_en && noise_config[2] ? noise_out : 6'd0);
wire [5:0] ch2_unclamped = (CH2_en ? CH2_out : 6'd0) + (adma_active && adma_config[3] ? adma_out : 6'd0) + (noise_en && noise_config[3] ? noise_out : 6'd0);

assign CH1 = |ch1_unclamped[5:4] ? 4'hF : ch1_unclamped[3:0];
assign CH2 = |ch2_unclamped[5:4] ? 4'hF : ch2_unclamped[3:0];

assign adma_bank = adma_config[6:4];

always_comb begin
	case (ch1_vdiv[5:4])
		2'b00: CH1_dc = 4'd1;  // 12.5%
		2'b01: CH1_dc = 4'd3;  // 25%
		2'b10: CH1_dc = 4'd7;  // 50%
		2'b11: CH1_dc = 4'd11; // 75%
	endcase

	case (ch2_vdiv[5:4])
		2'b00: CH2_dc = 4'd1;  // 12.5%
		2'b01: CH2_dc = 4'd3;  // 25%
		2'b10: CH2_dc = 4'd7;  // 50%
		2'b11: CH2_dc = 4'd11; // 75%
	endcase
end

always_ff @(posedge clk) begin : audio_clock

	reg sys_div;
	reg ch1_clk;
	reg ch2_clk;
	reg [3:0] ch1_phase;
	reg [3:0] ch2_phase;
	reg old_ps15;

	if (ce) begin // CPU CLK

		sys_div <= ~sys_div;
		old_ps15 <= prescaler[15];

		if (old_ps15 && ~prescaler[15]) begin
			if (|ch1_timer)
				ch1_timer <= ch1_timer - 8'd1;
			if (~|ch1_timer[7:1])
				ch1_mute <= 1;

			if (|ch2_timer > 8'd0)
				ch2_timer <= ch2_timer - 8'd1;
			if (~|ch2_timer[7:1])
				ch2_mute <= 1;

			if (|noise_timer > 8'd0)
				noise_timer <= noise_timer - 8'd1;
			if (~|noise_timer[7:1])
				noise_mute <= 1;
		end

		noise_sum <= noise_sum + 1'd1;
		if (noise_sum >= noise_div) begin
			lfsr <= {lfsr[13:0], lfsr_next};
			noise_sum <= 0;
		end

		if (sys_div) begin
			CH1_sum <= CH1_sum + 1'd1;
			CH2_sum <= CH2_sum + 1'd1;

			if (CH1_sum == ch1_freq) begin
				CH1_sum <= 0;
				ch1_phase <= ch1_phase + 1'd1;
				if (ch1_phase == CH1_dc)
					CH1_sw <= 0;
				else if (ch1_phase == 15)
					CH1_sw <= 1;
			end
			if (CH2_sum == ch2_freq) begin
				CH2_sum <= 0;
				ch2_phase <= ch2_phase + 1'd1;
				if (ch2_phase == CH2_dc)
					CH2_sw <= 0;
				else if (ch2_phase == 15)
					CH2_sw <= 1;
			end
		end

		if (adma_read) begin
			adma_read <= 0;
			adma_sample <= dbus_in;
		end

		if (adma_active) begin
			adma_sum <= adma_sum + 1'd1;
			if (adma_sum >= ((17'd256 << adma_config[1:0]) - 1'd1)) begin
				adma_sum <= 0;
				if (adma_sample_pending) begin
					adma_sample_pending <= 0;
				end else begin
					adma_addr <= adma_addr + 1'd1;
					adma_sample_pending <= 1;
					adma_read <= 1;
					adma_phase <= adma_phase - 1'd1;
					if (~|adma_phase) begin
						adma_length <= adma_length - 1'd1;
						if (adma_length == 1) begin
							adma_read <= 0;
							adma_irq_n <= 0;
							adma_active <= 0;
						end
					end
				end
			end
		end

		if (snd_cs) begin
			if (~cpu_rwn) begin
				case (AB)
					CH1_FREQ_LOW:  begin ch1_freq[7:0]    <= dbus_in; CH1_sum <= 0; end
					CH1_FREQ_HIGH: begin ch1_freq[10:8]   <= dbus_in[2:0]; CH1_sum <= 0; end
					CH1_VDUTY:     begin ch1_vdiv         <= dbus_in; if (dbus_in[6] && ch1_timer > 0) CH1_sum <= 0; end
					CH1_FRAME_LEN: begin ch1_timer        <= dbus_in; if (dbus_in != 0) ch1_mute <= 0; end
					CH2_FREQ_LOW:  begin ch2_freq[7:0]    <= dbus_in; CH2_sum <= 0; end
					CH2_FREQ_HIGH: begin ch2_freq[10:8]   <= dbus_in[2:0]; CH2_sum <= 0; end
					CH2_VDUTY:     begin ch2_vdiv         <= dbus_in; if (dbus_in[6] && ch2_timer > 0) CH2_sum <= 0; end
					CH2_FRAME_LEN: begin ch2_timer        <= dbus_in; if (dbus_in != 0) ch2_mute <= 0; end
					ADMA_ADDR_LO:  begin adma_addr[7:0]   <= dbus_in; end
					ADMA_ADDR_HI:  begin adma_addr[15:8]  <= dbus_in; end
					ADMA_LENGTH:   begin adma_length      <= dbus_in;
							if (adma_active) begin
								if (dbus_in == 0) begin
									adma_length <= 0;
									adma_active <= 0;
									adma_irq_n <= 0;
								end
							end
						end
					ADMA_CONFIG:   begin adma_config      <= dbus_in; end
					ADMA_REQ:      begin adma_active      <= dbus_in[7]; adma_phase <= 4'd15; adma_sample <= 0; adma_read <= 1; adma_sample_pending <= 1; end
					ADMA_ACK:      begin adma_irq_n       <= 1; end
					NOISE_VDIV, 6'h2c:    begin noise_vdiv       <= dbus_in; end
					NOISE_LENGTH, 6'h2d:  begin noise_timer      <= dbus_in; if (dbus_in != 0) noise_mute <= 0; end
					NOISE_CONFIG, 6'h2E:  begin noise_config     <= dbus_in; lfsr <= 15'h7FFF; noise_sum <= 0; end
				endcase
			end else begin
				if (AB == ADMA_ACK)
					adma_irq_n <= 1;
			end
		end
	end

	if (reset) begin
		adma_sample_pending <= 0;
		adma_sample <= 0;
		adma_read <= 0;
		ch1_mute <= 0;
		ch2_mute <= 0;
		noise_mute <= 0;
		adma_active <= 0;
		adma_irq_n <= 1;
		noise_config <= 0;
		noise_timer <= 0;
		noise_vdiv <= 0;
		ch1_vdiv <= 0;
		ch2_vdiv <= 0;
		ch1_freq <= 0;
		ch2_freq <= 0;
		ch1_timer <= 0;
		ch2_timer <= 0;
	end
end

endmodule

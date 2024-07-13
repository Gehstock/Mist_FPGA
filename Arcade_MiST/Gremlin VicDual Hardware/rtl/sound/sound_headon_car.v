`timescale 1 ps / 1 ps

module sound_headon_car
(
	input clk,
	input reset,
	input enable,
	input high_speed,
	output signed [15:0] out
);

	wire [23:0] ramp_out;
	freq_ramp #(
		.FREQ_NORMAL(24'd90000),
		.FREQ_HIGH(24'd20000),
		.FREQ_COUNTER_MAX(8'd150)
	) freq_ramp (
		.clk(clk),
		.reset(reset),
		.high(high_speed),
		.out(ramp_out)
	);

	wire freq_out;
	reg freq_out_last;
	variable_555 #( 
		.PERIOD_WIDTH(24)
	) variable_555
	(
		.clk(clk),
		.reset(reset),
		.high_period(ramp_out),
		.low_period(ramp_out),
		.out(freq_out)
	);

	reg u8_1_q;
	wire u8_1_qn = ~u8_1_q;
	reg u8_1_qn_last;
	reg u8_2_q;
	wire u8_2_qn = ~u8_2_q;
	reg u7_1_q;
	reg u7_2_q;

	wire u11_q = ~u7_1_q & ~u7_2_q;

	always @(posedge clk)
	begin
		if(reset)
		begin
			freq_out_last <= 1'b0;
			u8_1_q <= 1'b0;
			u8_1_qn_last <= 1'b0;
			u8_2_q <= 1'b0;
			u7_1_q <= 1'b0;
			u7_2_q <= 1'b0;
		end
		else
		begin
			freq_out_last <= freq_out;
			u8_1_qn_last <= u8_1_qn;
			if(freq_out && !freq_out_last)
			begin
				u8_1_q <= u8_1_qn;
				u7_1_q <= u11_q;
				u7_2_q <= u7_1_q;
			end
			if(u8_1_qn && !u8_1_qn_last) u8_2_q <= u8_2_qn;
		end
	end

	wire [6:0] wave = {6'b0, u8_1_q} + {6'b0, u8_2_q} + {6'b0, u7_2_q};
	assign out = enable ? ((wave * 6000) - 9000) : 0;

endmodule
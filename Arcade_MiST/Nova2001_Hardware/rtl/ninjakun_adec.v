module ninjakun_adec
(
	input    [1:0] HWTYPE,
	input   [15:0] CP0AD,
	input          CP0WR,

	input  [15:0] CP1AD,
	input         CP1WR,

	output        CS_IN0,
	output        CS_IN1,

	output        CS_SH0,
	output        CS_SH1,

	output        SYNWR0,
	output        SYNWR1
);

`include "rtl/defs.v"

always @(*) begin
	CS_IN0 = (CP0AD[15:2] == 14'b1010_0000_0000_00);
	CS_IN1 = (CP1AD[15:2] == 14'b1010_0000_0000_00);

	CS_SH0 = (CP0AD[15:11] == 5'b1110_0);
	CS_SH1 = (CP1AD[15:11] == 5'b1110_0);

	SYNWR0 = CS_IN0 & (CP0AD[1:0]==2) & CP0WR;
	SYNWR1 = CS_IN1 & (CP1AD[1:0]==2) & CP1WR;

	if (HWTYPE == `HW_RAIDERS5) begin
		CS_IN0 = 0;
		CS_IN1 = 0;

		CS_SH0 = (CP0AD[15:11] == 5'b1110_0);
		CS_SH1 = (CP1AD[15:11] == 5'b1010_0);

		SYNWR0 = 0;
		SYNWR1 = 0;
	end else if (HWTYPE == `HW_NOVA2001) begin
		CS_IN0 = (CP0AD[15:4] == 12'hC00 && (CP0AD[3:1] == 3'b011 || CP0AD[3:1] == 3'b111));
		CS_IN1 = 0;

		CS_SH0 = (CP0AD[15:11] == 5'b1110_0);
		CS_SH1 = 0;

		SYNWR0 = 0;
		SYNWR1 = 0;
	end else if (HWTYPE == `HW_PKUNWAR) begin
		CS_IN0 = 0;
		CS_IN1 = 0;

		CS_SH0 = (CP0AD[15:11] == 5'b1100_0);
		CS_SH1 = 0;

		SYNWR0 = 0;
		SYNWR1 = 0;
	end
end

endmodule 
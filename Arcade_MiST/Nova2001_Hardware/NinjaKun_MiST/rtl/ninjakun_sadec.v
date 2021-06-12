// Copyright (c) 2011 MiSTer-X

module ninjakun_sadec
(
	input        RAIDERS5,
	input [15:0] CPADR,
	input        CPSEL,
	output       CS_SCRX,
	output       CS_SCRY,
	output       CS_PSG,
	output       CS_FGV,
	output       CS_BGV,
	output       CS_SPA,
	output       CS_PAL
);

always @(*) begin
	CS_PSG = ( CPADR[15: 2] == 14'b1000_0000_0000_00 );
	CS_FGV = ( CPADR[15:11] ==  5'b1100_0 );
	CS_BGV = ( CPADR[15:11] ==  5'b1100_1 );
	CS_SPA = ( CPADR[15:11] ==  5'b1101_0 );
	CS_PAL = ( CPADR[15:11] ==  5'b1101_1 );
	CS_SCRX = 0;
	CS_SCRY = 0;

	if (RAIDERS5) begin
		if (CPSEL) begin
			CS_SCRX = ( CPADR == 16'he000 );
			CS_SCRY = ( CPADR == 16'he001 );
			CS_PSG = ( CPADR[15: 2] == 14'b1000_0000_0000_00 );
			CS_FGV = 0;
			CS_BGV = 0;
			CS_SPA = 0;
			CS_PAL = 0;
		end else begin
			CS_SCRX = ( CPADR == 16'ha000 );
			CS_SCRY = ( CPADR == 16'ha001 );
			CS_PSG = ( CPADR[15: 2] == 14'b1100_0000_0000_00 );
			CS_FGV = ( CPADR[15:11] ==  5'b1000_1 );
			CS_BGV = ( CPADR[15:11] ==  5'b1001_0 );
			CS_SPA = ( CPADR[15:11] ==  5'b1000_0 );
			CS_PAL = ( CPADR[15:11] ==  5'b1101_0 );
		end
	end
end

endmodule 
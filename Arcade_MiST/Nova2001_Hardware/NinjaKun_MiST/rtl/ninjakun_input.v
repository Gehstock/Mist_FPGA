// Copyright (c) 2011 MiSTer-X

module ninjakun_input
(
	input        MCLK,
	input        RESET,
	input  [1:0] HWTYPE,

	input  [7:0] CTR1i,	// Control Panel (Negative Logic)
	input  [7:0] CTR2i,
	input  [7:0] CTR3i,
	input        VBLK, 

	input  [1:0] AD0,
	input  [1:0] OD0,
	input        WR0,

	input  [1:0] AD1,
	input  [1:0] OD1,
	input        WR1,

	output [7:0] INPD0,
	output [7:0] INPD1
);

reg [1:0] SYNCFLG;
reg [7:0] CTR1,CTR2,CTR3;
always @( posedge MCLK or posedge RESET ) begin
	if (RESET) begin
		SYNCFLG = 0;
	end
	else begin
		CTR1 <= CTR1i;
		CTR2 <= CTR2i;
		CTR3 <= CTR3i;
		if (WR0) begin
			if (OD0[1]) SYNCFLG[0] = 1;
			if (OD0[0]) SYNCFLG[1] = 0;
		end
		if (WR1) begin
			if (OD1[1]) SYNCFLG[0] = 0;
			if (OD1[0]) SYNCFLG[1] = 1;
		end
	end
end

wire [7:0] INPORT0 = CTR1;
wire [7:0] INPORT1 = CTR2;
wire [7:0] INPORT2 = HWTYPE[1] ? {~VBLK, CTR3[6:0]} : { 4'b0000, SYNCFLG, ~VBLK,1'b0 };

assign INPD0 = ( AD0 == 0 ) ? INPORT0 :
               ( AD0 == 1 ) ? INPORT1 :
               ( AD0 == 2 ) ? INPORT2 : 8'hFF;

assign INPD1 = ( AD1 == 0 ) ? INPORT0 :
               ( AD1 == 1 ) ? INPORT1 :
               ( AD1 == 2 ) ? INPORT2 : 8'hFF;

endmodule

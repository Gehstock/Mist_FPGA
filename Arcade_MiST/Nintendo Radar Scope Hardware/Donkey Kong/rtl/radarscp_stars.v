//===============================================================================
// FPGA DONKEY KONG  Radar Scope grid/star generator
//
// Version : 1.00
//
// Copyright(c) 2021 Gyorgy Szombathelyi
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
//================================================================================
//-----------------------------------------------------------------------------------------
// H_CNT[0],H_CNT[1],H_CNT[2],H_CNT[3],H_CNT[4],H_CNT[5],H_CNT[6],H_CNT[7],H_CNT[8],H_CNT[9]  
//   1/2 H     1 H     2 H      4H       8H       16 H     32H      64 H     128 H   256 H
//-----------------------------------------------------------------------------------------

module radarscp_stars(
	input        CLK_24M,
	input        CLK_EN,
	input        RESETn,
	output       O_RADARn,
	output       O_STARn,
	output       O_NOISE,
	output       O_DISPLAY,
	input        I_DISPLAY,
	input        I_VBLKn,
	input  [9:0] I_H_CNT,
	input        I_FLIPn,
	input        I_SOU2,

	input [15:0] DL_ADDR,
	input        DL_WR,
	input  [7:0] DL_DATA
	);

reg [7:0] RADAR_SHIFT;
reg [19:0] CNT_30HZ;
reg NOISE;
reg [15:0] NOISE_LFSR;

always @(posedge CLK_24M, negedge RESETn) begin
	if (!RESETn) begin
		RADAR_SHIFT <= 0;
		CNT_30HZ <= 0;
	end else begin
		CNT_30HZ <= CNT_30HZ + 1'd1;
		if (CNT_30HZ == 20'd799999) begin
			RADAR_SHIFT <= {RADAR_SHIFT[6:0], ~^RADAR_SHIFT[7:6]};
			CNT_30HZ <= 0;

			NOISE_LFSR <= {NOISE_LFSR[14:0], (NOISE ^ NOISE_LFSR[4])};
			NOISE <= ~NOISE_LFSR[15]; // originally generated on the sound board - used for stars dimming
		end
	end
end
wire W_RFLIP = (RADAR_SHIFT[5] & I_SOU2) ^ I_FLIPn; // does the radar flipping when destroyed

assign O_DISPLAY = I_DISPLAY; // TODO: grid slow drawing effect

reg  [10:0] STARS_A;
wire  [7:0] STARS_DO;
reg   [3:0] W_1E_D;

assign O_NOISE = NOISE;
assign O_STARn = ~(W_1E_D[2] & W_1E_D[1] & W_1E_D[0]);
assign O_RADARn = ~(~W_1E_D[2] & W_1E_D[1] & W_1E_D[0]);
wire [3:0] W_1E_D_next = { 1'b1, STARS_DO[7], W_1E_D[0], {1'b0, STARS_DO[6:0]} == {I_H_CNT[2], I_H_CNT[9:3]} };

`ifdef SIM
always @(posedge I_H_CNT[0]) begin
	W_1E_D <= W_1E_D_next;
end

wire W_1G_2E_CLK = ~&W_1E_D[1:0];
always @(posedge W_1G_2E_CLK, negedge I_VBLKn) begin
	if (!I_VBLKn)
		STARS_A <= {W_RFLIP, 10'd0};
	else
		STARS_A <= STARS_A + 1'd1;
end
`else
always @(posedge CLK_24M) begin
	if (CLK_EN & ~I_H_CNT[0])
		W_1E_D <= W_1E_D_next;
end

always @(posedge CLK_24M, negedge I_VBLKn) begin
	if (!I_VBLKn)
		STARS_A <= 0;
	else if (CLK_EN) begin
		if (&W_1E_D[1:0] & ~&W_1E_D_next[1:0]) STARS_A <= {W_RFLIP, STARS_A[9:0] + 1'd1};
	end
end
`endif

dpram #(11,8) U_3E (
	.clock_a(CLK_24M),
	.address_a(STARS_A),
	.q_a(STARS_DO),

	.clock_b(CLK_24M),
	.address_b(DL_ADDR[10:0]),
	.wren_b(DL_WR && DL_ADDR[15:11] == {4'hF, 1'b1}),
	.data_b(DL_DATA)
	);

endmodule

module ninjakun_psg
(
	input         MCLK,
	input   [1:0] HWTYPE,
	input   [1:0] ADR,
	input         CS,
	input         WR,
	input   [7:0] ID,
	output  [7:0] OD,
	input         RESET,
	input         RD,
	input   [7:0] DSW1,
	input   [7:0] DSW2,
	input   [7:0] CTR1,
	input   [7:0] CTR2,
	input         VBLK,
	output  [7:0] SCRPX,
	output  [7:0] SCRPY,
	output [15:0] SNDO
);

`include "rtl/defs.v"

wire [7:0] OD0, OD1;
assign OD = psg1cs ? OD1 : OD0;

reg [7:0] SA0, SB0, SC0; wire [7:0] S0x; wire [1:0] S0c;
reg [7:0] SA1, SB1, SC1; wire [7:0] S1x; wire [1:0] S1c;

reg [3:0] encnt;
reg ENA;
always @(posedge MCLK) begin
	ENA <= (encnt==0);
	encnt <= encnt+1'd1;
	case (HWTYPE)
	`HW_NINJAKUN, `HW_RAIDERS5:
		if (encnt == 7) encnt <= 0; // 6 MHz
	`HW_NOVA2001:
		if (encnt == 11) encnt <= 0; // 4 MHz
	default: ; // 3 MHz
	endcase

	case (S0c)
	2'd0: SA0 <= S0x;
	2'd1: SB0 <= S0x;
	2'd2: SC0 <= S0x;
	default:;
	endcase
	case (S1c)
	2'd0: SA1 <= S1x;
	2'd1: SB1 <= S1x;
	2'd2: SC1 <= S1x;
	default:;
	endcase
end

wire psgxad = HWTYPE == `HW_NOVA2001 ? ADR[1] : ~ADR[0];
wire psg0cs = CS & (HWTYPE == `HW_NOVA2001 ? ~ADR[0] : ~ADR[1]);
wire psg0bd = psg0cs & (WR|psgxad);
wire psg0bc = psg0cs & ((~WR)|psgxad);

wire psg1cs = CS & (HWTYPE == `HW_NOVA2001 ? ADR[0] : ADR[1]);
wire psg1bd = psg1cs & (WR|psgxad);
wire psg1bc = psg1cs & ((~WR)|psgxad);

wire [7:0] IOA_PSG0, IOB_PSG0;
wire [7:0] IOA_PSG1, IOB_PSG1;
assign SCRPX = HWTYPE == `HW_NOVA2001 ? IOA_PSG0 : IOA_PSG1;
assign SCRPY = HWTYPE == `HW_NOVA2001 ? IOB_PSG0 : IOB_PSG1;

wire IO_TYPE = HWTYPE == `HW_RAIDERS5 || HWTYPE == `HW_PKUNWAR;

YM2149 psg0(
	.I_DA(ID),
	.O_DA(OD0),
	.I_A9_L(~psg0cs),
	.I_BDIR(psg0bd),
	.I_BC1(psg0bc),
	.I_A8(1'b1),
	.I_BC2(1'b1),
	.I_SEL_L(1'b0),
	.O_AUDIO(S0x),
	.O_CHAN(S0c),
	.I_IOA(IO_TYPE ? {~VBLK, CTR1[6:0]} : DSW1),
	.I_IOB(IO_TYPE ? CTR2 : DSW2),
	.O_IOA(IOA_PSG0),
	.O_IOB(IOB_PSG0),
	.ENA(ENA),
	.RESET_L(~RESET),
	.CLK(MCLK)
);

YM2149 psg1(
	.I_DA(ID),
	.O_DA(OD1),
	.I_A9_L(~psg1cs),
	.I_BDIR(psg1bd),
	.I_BC1(psg1bc),
	.I_A8(1'b1),
	.I_BC2(1'b1),
	.I_SEL_L(1'b0),
	.O_AUDIO(S1x),
	.O_CHAN(S1c),
	.I_IOA(HWTYPE == `HW_NINJAKUN ? 8'd0 : DSW1),
	.I_IOB(HWTYPE == `HW_NINJAKUN ? 8'd0 : DSW2),
	.O_IOA(IOA_PSG1),
	.O_IOB(IOB_PSG1),
	.ENA(ENA),
	.RESET_L(~RESET),
	.CLK(MCLK)
);

wire [11:0] SND = SA0+SB0+SC0+SA1+SB1+SC1;
assign SNDO = {SND,SND[3:0]};

endmodule 
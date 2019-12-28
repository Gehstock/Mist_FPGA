module ninjakun_psg
(
	input				MCLK,
	input	 [1:0]	ADR,
	input				CS,
	input				WR,
	input	 [7:0]	ID,
	output [7:0]	OD,
	input				RESET,
	input				RD,
	input	 [7:0]	DSW1,
	input	 [7:0]	DSW2,
	output [7:0]	SCRPX,
	output [7:0]	SCRPY,
	output [15:0]	SNDO
);

wire [7:0] OD0, OD1;
assign OD = ADR[1] ? OD1 : OD0;

reg [7:0] SA0, SB0, SC0; wire [7:0] S0x; wire [1:0] S0c;
reg [7:0] SA1, SB1, SC1; wire [7:0] S1x; wire [1:0] S1c;

reg [2:0] encnt;
reg ENA;
always @(posedge MCLK) begin
	ENA <= (encnt==0);
	encnt <= encnt+1'd1;
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

wire psgxad = ~ADR[0];
wire psg0cs = CS & (~ADR[1]);
wire psg0bd = psg0cs & (WR|psgxad);
wire psg0bc = psg0cs & ((~WR)|psgxad);

wire psg1cs = CS & ADR[1];
wire psg1bd = psg1cs & (WR|psgxad);
wire psg1bc = psg1cs & ((~WR)|psgxad);

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
	.I_IOA(DSW1),
	.I_IOB(DSW2),
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
	.I_IOA(8'd0),
	.I_IOB(8'd0),
	.O_IOA(SCRPX),
	.O_IOB(SCRPY),
	.ENA(ENA),
	.RESET_L(~RESET),
	.CLK(MCLK)
);

wire [11:0] SND = SA0+SB0+SC0+SA1+SB1+SC1;
assign SNDO = {SND,SND[3:0]};

endmodule 
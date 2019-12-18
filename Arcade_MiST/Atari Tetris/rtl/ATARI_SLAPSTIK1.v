// Copyright (c) 2019 MiSTer-X

`define INIT_BS	2'd3

`define BS_BANK0	(AD==13'h0080)
`define BS_BANK1	(AD==13'h0090)
`define BS_BANK2	(AD==13'h00A0)
`define BS_BANK3	(AD==13'h00B0)

`define AT_1		((AD & 13'h007F)==13'hFFFF)
`define AT_2		((AD & 13'h1FFF)==13'h1DFF)
`define AT_3		((AD & 13'h1FFC)==13'h1B5C)
`define AT_4		((AD & 13'h1FCF)==13'h0080)

`define BW_1		((AD & 13'h1FF0)==13'h1540)
`define BW_2C0		((AX & 13'h1FF3)==13'h1540)
`define BW_2S0		((AX & 13'h1FF3)==13'h1541)
`define BW_2C1		((AX & 13'h1FF3)==13'h1542)
`define BW_2S1		((AX & 13'h1FF3)==13'h1543)
`define BW_3		((AD & 13'h1FF8)==13'h1550)


module ATARI_SLAPSTIK1
(
	input					RST,
	input					CLK,
	input					CLKEN,
	input					CS,
	input 	 [12:0]	AD,

	output reg [1:0]	BS = `INIT_BS
);

`define SS_RESET	(AD==13'h0000)
`define BS_BANKx	(`BS_BANK0|`BS_BANK1|`BS_BANK2|`BS_BANK3)

`define S_DI	0
`define S_EN	1	
`define S_AT1	2
`define S_AT2	3
`define S_AT3	4
`define S_BW1	5
`define S_BW2	6
`define S_BW3	7

reg			bwa;
reg   [1:0] ta,tb;
wire [12:0] AX = AD^{11'h0,bwa,bwa};

reg   [2:0] state = `S_DI;
always @(posedge CLK) begin
	if (RST) begin
		state <= `S_DI;
		BS <= `INIT_BS;
	end
	else if (CLKEN & CS) begin
		if (`SS_RESET) state <= `S_EN;
		else case (state)
		`S_DI:;

		`S_EN:  if `BS_BANKx begin BS <= AD[5:4]; state <= `S_DI; end else
				  if `AT_1 begin state <= `S_AT1; end else
				  if `AT_2 begin state <= `S_AT2; end else
				  if `BW_1 begin state <= `S_BW1; end

		`S_AT1: if `AT_2 begin state <= `S_AT2; end else state <= `S_EN;
		`S_AT2: if `AT_3 begin ta <= AD[1:0]; state <= `S_AT3; end else state <= `S_EN;
		`S_AT3: if `AT_4 begin BS <= ta; state <= `S_DI; end

		`S_BW1: if `BS_BANKx begin bwa <= 0;  tb <= BS; state <= `S_BW2; end
		`S_BW2: if `BW_2C0 begin bwa <= ~bwa; tb[0] <= 1'b0; end else
				  if `BW_2S0 begin bwa <= ~bwa; tb[0] <= 1'b1; end else
				  if `BW_2C1 begin bwa <= ~bwa; tb[1] <= 1'b0; end else
				  if `BW_2S1 begin bwa <= ~bwa; tb[1] <= 1'b1; end else
				  if `BW_3   begin state <= `S_BW3; end
		`S_BW3: if `BS_BANKx begin BS <= tb; state <= `S_DI; end

		default:;
		endcase
	end
end

endmodule


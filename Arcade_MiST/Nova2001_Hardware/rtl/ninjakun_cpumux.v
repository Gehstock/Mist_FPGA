module ninjakun_cpumux
(
	input				MCLK,
	output [15:0]	CPADR,
	output  [7:0]	CPODT,
	input   [7:0]	CPIDT,
	output    		CPRED,
	output    		CPWRT,
	output          CPSEL,

	output reg		CP0CL,
	output reg		CP0CE_P,
	output reg		CP0CE_N,
	input  [15:0]	CP0AD,
	input   [7:0]	CP0OD,
	output  [7:0]	CP0ID,
	input    		CP0RD,
	input    		CP0WR,

	output reg		CP1CL,
	output reg		CP1CE_P,
	output reg		CP1CE_N,
	input  [15:0]	CP1AD,
	input   [7:0]	CP1OD,
	output  [7:0]	CP1ID,
	input    		CP1RD,
	input    		CP1WR
);

assign     CPSEL = CSIDE;
reg  [7:0] CP0DT, CP1DT;
reg  [3:0] PHASE;
reg		  CSIDE;
always @( posedge MCLK ) begin	// 48MHz
	CP0CE_P <= 0; CP0CE_N <= 0;
	CP1CE_P <= 0; CP1CE_N <= 0;
	case (PHASE)
	0: begin CP0DT <= CPIDT; CP0CE_P <= 1; CP1CE_N <= 1; end
	1: CSIDE <= 0;
	8: begin CP1DT <= CPIDT; CP1CE_P <= 1; CP0CE_N <= 1; end
	9: CSIDE <= 1;
	default:;
	endcase
end
always @( posedge MCLK ) begin
	case (PHASE)
	1: begin CP0CL <= 1; CP1CL <= 0; end
	9: begin CP1CL <= 1; CP0CL <= 0; end
	default:;
	endcase
	PHASE <= PHASE+1'd1;
end

assign CPADR = CSIDE ? CP1AD : CP0AD;
assign CPODT = CSIDE ? CP1OD : CP0OD;
assign CPRED = CSIDE ? CP1RD : CP0RD;
assign CPWRT = CSIDE ? CP1WR : CP0WR;
assign CP0ID = CSIDE ? CP0DT : CPIDT;
assign CP1ID = CSIDE ? CPIDT : CP1DT;

endmodule 
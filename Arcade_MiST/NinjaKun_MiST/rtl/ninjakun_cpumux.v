module ninjakun_cpumux
(
	input				SHCLK,
	output [15:0]	CPADR,
	output  [7:0]	CPODT,
	input   [7:0]	CPIDT,
	output    		CPRED,
	output    		CPWRT,

	output reg		CP0CL,
	input  [15:0]	CP0AD,
	input   [7:0]	CP0OD,
	output  [7:0]	CP0ID,
	input    		CP0RD,
	input    		CP0WR,

	output reg		CP1CL,
	input  [15:0]	CP1AD,
	input   [7:0]	CP1OD,
	output  [7:0]	CP1ID,
	input    		CP1RD,
	input    		CP1WR
);

reg  [7:0] CP0DT, CP1DT;
reg  [2:0] PHASE;
reg		  CSIDE;
always @( posedge SHCLK ) begin	// 24MHz
	case (PHASE)
	0: begin CP0DT <= CPIDT; CSIDE <= 1'b0; end
	4: begin CP1DT <= CPIDT; CSIDE <= 1'b1; end
	default:;
	endcase
end
always @( negedge SHCLK ) begin
	case (PHASE)
	0: CP0CL <= 1'b1;
	2: CP0CL <= 1'b0;
	4: CP1CL <= 1'b1;
	6: CP1CL <= 1'b0;
	default:;
	endcase
	PHASE <= PHASE+1;
end

assign CPADR = CSIDE ? CP1AD : CP0AD;
assign CPODT = CSIDE ? CP1OD : CP0OD;
assign CPRED = CSIDE ? CP1RD : CP0RD;
assign CPWRT = CSIDE ? CP1WR : CP0WR;
assign CP0ID = CSIDE ? CP0DT : CPIDT;
assign CP1ID = CSIDE ? CPIDT : CP1DT;

endmodule 
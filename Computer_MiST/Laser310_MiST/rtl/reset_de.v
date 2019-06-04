module RESET_DE(
	CLK,			// 50MHz
	SYS_RESET_N,
	RESET_N,		// 50MHz/32/65536
	RESET_AHEAD_N	// 提前恢复，可以接 FLASH_RESET_N
);


input				CLK;
input				SYS_RESET_N;
output				RESET_N;
output				RESET_AHEAD_N;


wire	RESET_N;
wire	RESET_AHEAD_N;

reg		[5:0]		CLK_CNT;
reg		[16:0]		RESET_COUNT;

wire	RESET_COUNT_CLK;
wire	RESET_DE_N;
wire	RESET_AHEAD_DE_N;

assign RESET_COUNT_CLK = CLK_CNT[5];

assign RESET_DE_N = RESET_COUNT[16]!=1'b0;
assign RESET_N = SYS_RESET_N && RESET_DE_N;

assign RESET_AHEAD_DE_N = RESET_COUNT[16:15]!=2'b00;
assign RESET_AHEAD_N = SYS_RESET_N && RESET_AHEAD_DE_N;

`ifdef SIMULATE
initial
	begin
		CLK_CNT = 6'b0;
	end
`endif

// 50MHz/32 = 1.5625MHz
always @ (posedge CLK)
	CLK_CNT <= CLK_CNT+1;

// 50MHz/32/65536 = 23.84HZ
always @ (posedge RESET_COUNT_CLK or negedge SYS_RESET_N)
begin
	if(~SYS_RESET_N)
	begin
		RESET_COUNT <= 17'h00000;
	end
	else
	begin
		if(RESET_COUNT!=17'h10000)
			RESET_COUNT <= RESET_COUNT+1;

	end
end

endmodule

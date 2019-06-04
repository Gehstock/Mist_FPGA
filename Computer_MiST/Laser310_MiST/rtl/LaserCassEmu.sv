module LaserCassEmu(
input wire	[15:0]	CPU_A,
input wire				CPU_RD,
input wire				CPU_WR
);
// cassette

(*keep*)wire	[1:0]	CASS_OUT;
(*keep*)wire			CASS_IN;
(*keep*)wire			CASS_IN_L;
(*keep*)wire			CASS_IN_R;

reg		[7:0]		LATCHED_IO_DATA_WR;
// 用于外部磁带仿真计数
//(*keep*)reg				EMU_CASS_CLK;

(*keep*)wire			EMU_CASS_EN;
(*keep*)wire	[1:0]	EMU_CASS_DAT;

`ifdef CASS_EMU

wire			CASS_BUF_RD;
wire	[15:0]	CASS_BUF_A;
wire			CASS_BUF_WR;
wire	[7:0]	CASS_BUF_DAT;
wire	[7:0]	CASS_BUF_Q;

// F9    CASS PLAY
// F10   CASS STOP

EMU_CASS_KEY	EMU_CASS_KEY(
	KEY_Fxx[8],
	KEY_Fxx[9],
	// cass emu
	CASS_BUF_RD,
	//
	CASS_BUF_A,
	CASS_BUF_WR,
	CASS_BUF_DAT,
	CASS_BUF_Q,
	//	Control Signals
	EMU_CASS_EN,
	EMU_CASS_DAT,

	// key emu
	EMU_KEY,
	EMU_KEY_EX,
	EMU_KEY_EN,
    /*
     * UART: 115200 bps, 8N1
     */
    UART_RXD,
    UART_TXD,

	// System
	TURBO_SPEED,
	// Clock: 10MHz
	CLK10MHZ,
	RESET_N
);


`ifdef CASS_EMU_16K

cass_ram_16k_altera cass_buf(
	.address(CASS_BUF_A[13:0]),
	.clock(CLK10MHZ),
	.data(CASS_BUF_DI),
	.wren(CASS_BUF_WR),
	.q(CASS_BUF_Q)
);

`endif


`ifdef CASS_EMU_8K

cass_ram_8k_altera cass_buf(
	.address(CASS_BUF_A[12:0]),
	.clock(CLK10MHZ),
	.data(CASS_BUF_DI),
	.wren(CASS_BUF_WR),
	.q(CASS_BUF_Q)
);

`endif


`ifdef CASS_EMU_4K

cass_ram_4k_altera cass_buf(
	.address(CASS_BUF_A[11:0]),
	.clock(CLK10MHZ),
	.data(CASS_BUF_DAT),
	.wren(CASS_BUF_WR),
	.q(CASS_BUF_Q)
);

`endif


`ifdef CASS_EMU_2K

cass_ram_2k_altera cass_buf(
	.address(CASS_BUF_A[10:0]),
	.clock(CLK10MHZ),
	.data(CASS_BUF_DAT),
	.wren(CASS_BUF_WR),
	.q(CASS_BUF_Q)
);

`endif

`endif



assign	CASS_OUT = EMU_CASS_EN ? EMU_CASS_DAT : {LATCHED_IO_DATA_WR[2], 1'b0};

(*keep*)wire trap = (CPU_RD|CPU_WR) && (CPU_A[15:12] == 4'h0);

endmodule 
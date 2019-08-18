/*****************************************************************************
* Floppy
******************************************************************************/

// POLLING after Clock

// vz dsk Parameter
// 154 * 16  * 40 = 98560 = 0x18100
// 154 * 16 = 2464 = 0x9A0 = 0x4D0 * 2
`define	FD_MAX_LEN		17'h18100
`define	FD_TRACK_LEN	12'h9A0
`define	FD_TRACK_STEP	8'h4D

// 40*2		0 --- 78
`define	FD_MAX_TRACK_NO	8'd78


module FDC_IF (
	FDC_CLK,
	RESET_N,
	SW,
	DBG,

	FDC_RAM_R,
	FDC_RAM_W,
	FDC_RAM_ADDR_R,
	FDC_RAM_ADDR_W,
	FDC_RAM_DATA_R,
	FDC_RAM_DATA_W,

	FDC_IO,
	FDC_IO_POLL,
	FDC_IO_DATA,
	FDC_IO_CT,

	FDC_SIG,
	FDC_SIG_CLK,

	FDC_CT,
	FDC_DATA,
	FDC_POLL,
	FDC_WP,

	FLOPPY_SECTOR_BYTE,
	TRACK1_NO,
	TRACK2_NO,
	DRIVE1,
	DRIVE2,
	MOTOR
);


input						FDC_CLK;
input						RESET_N;
input			[1:0]		SW;
input			[3:0]		DBG;

output			[17:0]		FDC_RAM_ADDR_R;
output			[17:0]		FDC_RAM_ADDR_W;
output	reg					FDC_RAM_R;
output	reg					FDC_RAM_W;
input			[7:0]		FDC_RAM_DATA_R;
output			[7:0]		FDC_RAM_DATA_W;


input						FDC_IO;
input						FDC_IO_POLL;
input						FDC_IO_DATA;
input						FDC_IO_CT;

output						FDC_SIG;
output	reg					FDC_SIG_CLK;

input			[7:0]		FDC_CT;

output			[7:0]		FDC_DATA;
output						FDC_POLL;
output						FDC_WP;


reg		[11:0]		FLOPPY_BYTE;
output	reg		[7:0]		FLOPPY_SECTOR_BYTE;	// Count Sector Bytes

reg		[6:0]		CLK_CNT;
reg		[6:0]		CLK_CNT_W;

reg		[18:0]		SYNC_CNT;
reg		[7:0]		FLOPPY_SECTOR_DELAY;	// Delay on Sector End


reg					FD_REC1;
reg					FDC_POLL1;
reg					FDC_REC_DATA_BIT1;
reg					FDC_DATA_BIT1;
reg		[7:0]		FDC_DATA1;
reg		[7:0]		LATCHED_FDC_DATA1;
reg					FDC_DATA_SET1;

reg					FD_REC2;
reg					FDC_POLL2;
reg					FDC_REC_DATA_BIT2;
reg					FDC_DATA_BIT2;
reg		[7:0]		FDC_DATA2;
reg		[7:0]		LATCHED_FDC_DATA2;

reg		[3:0]		BIT_CNT_W;
reg		[2:0]		BIT_CNT;

wire				FDC_RAM_DATA_R_BIT;


reg		[1:0]		STEPPER1;
reg		[1:0]		STEPPER2;
output	reg		[7:0]		TRACK1_NO;
output	reg		[7:0]		TRACK2_NO;
reg		[12:0]		TRACK1;
reg		[12:0]		TRACK2;
(*keep*)wire	[13:0]		TRACK;
wire	[12:0]		TRACK1_UP;
wire	[12:0]		TRACK1_DOWN;
wire	[12:0]		TRACK2_UP;
wire	[12:0]		TRACK2_DOWN;
reg		[17:0]		FLOPPY_ADDRESS_R;
reg		[17:0]		FLOPPY_ADDRESS_W;
//reg		[7:0]		FLOPPY_WRITE_DATA;

reg					WRITE_WAIT_FIRST_OP;
reg					WRITE_DATA_BIT_VAL;

reg		[7:0]		WRITE_DATA1;
reg					WRITE_DATA_MODI1;
reg		[7:0]		WRITE_DATA2;
reg					WRITE_DATA2_MODI;


(*keep*)wire	[7:0]		FLOPPY_RD_DATA;
(*keep*)wire	[7:0]		FLOPPY_DATA;
(*keep*)wire				FLOPPY_READ;
(*keep*)wire				FLOPPY_WRITE;
wire				FLOPPY_WP_READ;
reg					PHASE0;
reg					PHASE0_1;
reg					PHASE0_2;
reg					PHASE1;
reg					PHASE1_1;
reg					PHASE1_2;
reg					PHASE2;
reg					PHASE2_1;
reg					PHASE2_2;
reg					PHASE3;
reg					PHASE3_1;
reg					PHASE3_2;
output	reg					DRIVE1;
output	reg					DRIVE2;
output	reg					MOTOR;

reg					WRITE_REQUEST_N;
reg					WRITE_DATA_BIT;

reg					Q6;
reg					Q7;
wire				DRIVE1_EN;
wire				DRIVE2_EN;
wire				DRIVE1_X;
wire				DRIVE2_X;
wire				DRIVE_SWAP;
wire				DRIVE1_FLOPPY_WP;
wire				DRIVE2_FLOPPY_WP;

reg					MODIFY_DRIVE1;
reg					MODIFY_DRIVE2;

assign	FDC_RAM_ADDR_R	=	FLOPPY_ADDRESS_R;
assign	FDC_RAM_ADDR_W	=	FLOPPY_ADDRESS_W;


(*preserve*)reg	[7:0]	FDC_CNT;
(*preserve*)reg	[7:0]	FDC_CNT_POLL;
(*preserve*)reg	[7:0]	FDC_CNT_DATA;
(*preserve*)reg	[19:0]	FDC_CNT_CT;

always @(posedge FDC_CLK or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		FDC_CNT			<=	8'hFF;
		FDC_CNT_POLL	<=	8'hFF;
		FDC_CNT_DATA	<=	8'hFF;
		FDC_CNT_CT		<=	20'hFFFFF;
	end
	else
	begin
		if(FDC_IO)
			FDC_CNT	<=	0;
		else if(~FDC_CNT[7])
			FDC_CNT	<=	FDC_CNT + 1;

		if(FDC_IO_POLL)
			FDC_CNT_POLL	<=	0;
		else if(~FDC_CNT_POLL[7])
			FDC_CNT_POLL	<=	FDC_CNT_POLL + 1;

		if(FDC_IO_DATA)
			FDC_CNT_DATA	<=	0;
		else if(~FDC_CNT_DATA[7])
			FDC_CNT_DATA	<=	FDC_CNT_DATA + 1;

		if(FDC_IO_CT)
			FDC_CNT_CT		<=	0;
		else if(~FDC_CNT_CT[19])
			FDC_CNT_CT		<=	FDC_CNT_CT + 1;
	end
end



assign	FDC_POLL	=	(DRIVE1_EN)?FDC_POLL1:
						(DRIVE2_EN)?FDC_POLL2:
									1'b0;


assign	FDC_DATA	=	(DRIVE1_EN)?FDC_DATA1:
						(DRIVE2_EN)?FDC_DATA2:
									8'hFF;



assign	FDC_RAM_DATA_R_BIT	=	(BIT_CNT==3'd7)?FDC_RAM_DATA_R[7]:
								(BIT_CNT==3'd6)?FDC_RAM_DATA_R[6]:
								(BIT_CNT==3'd5)?FDC_RAM_DATA_R[5]:
								(BIT_CNT==3'd4)?FDC_RAM_DATA_R[4]:
								(BIT_CNT==3'd3)?FDC_RAM_DATA_R[3]:
								(BIT_CNT==3'd2)?FDC_RAM_DATA_R[2]:
								(BIT_CNT==3'd1)?FDC_RAM_DATA_R[1]:
												FDC_RAM_DATA_R[0];


// 读取

reg		LATCHED_FD_REC1;
reg		LATCHED_FDC_IO_DATA1;
reg		GET_FDC_POLLING;

reg		[5:0]		FDC_POLL1_CNT;

reg		[5:0]		GET_FDC_POLL1_CNT;


always @(posedge FDC_CLK or negedge RESET_N)
	if(~RESET_N)
	begin
		FDC_DATA_BIT1			<=	1'b0;

		LATCHED_FD_REC1			<=	1'b0;
		LATCHED_FDC_IO_DATA1	<=	1'b0;
	end
	else
	begin
		// 磁道记录信号上沿，翻转 DATA_BIT
		if({LATCHED_FD_REC1, FD_REC1}==2'b01)
		begin
			FDC_DATA_BIT1	<=	FDC_POLL1;
		end

		if(FDC_DATA_SET1)
			LATCHED_FDC_DATA1	<=	{LATCHED_FDC_DATA1[6:0], FDC_DATA_BIT1};

		// 读取DATA信号上沿
		if({LATCHED_FDC_IO_DATA1, FDC_IO_DATA}==2'b01)
		begin
			FDC_DATA1		<=	LATCHED_FDC_DATA1;
		end

		LATCHED_FD_REC1			<=	FD_REC1;
		LATCHED_FDC_IO_DATA1	<=	FDC_IO_DATA;
	end
		
////////////////////////////////////////
// 物理软驱模拟
////////////////////////////////////////

//WRITE_REQUEST_N
(*preserve*)reg	[9:0]	WRITE_DATA_CNT;

assign	FDC_RAM_DATA_W	=	WRITE_DATA1;

// 对写入操作计数
always @(posedge FDC_CLK or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		WRITE_DATA_CNT		<=	0;
	end
	else
	begin
		if( (~FDC_CT[6]) && (FDC_CT[5]==LATCHED_FDC_CT[5]) )
		begin
			if(~WRITE_DATA_CNT[9])
				WRITE_DATA_CNT		<=	WRITE_DATA_CNT+1;
		end
		else
		begin
			WRITE_DATA_CNT		<=	0;
		end
	end
end


// 模拟磁道信号

// 等待第1个写入数据变化
always @(posedge FDC_CLK or negedge RESET_N)
	if(~RESET_N)
	begin
		WRITE_WAIT_FIRST_OP	<=	1'b0;
	end
	else
	begin
		if( LATCHED_FDC_CT[6]!=FDC_CT[6] )
		begin
			// 信号下拉，开始写入，并等待第1个写入数据变化。
			WRITE_WAIT_FIRST_OP		<=	({LATCHED_FDC_CT[6],FDC_CT[6]}==2'b10);
		end
		else
		begin
			// 找到第1个写入数据变化
			if( ({LATCHED_FDC_CT[6],FDC_CT[6]}==2'b00) && (FDC_CT[5]!=LATCHED_FDC_CT[5]) )
				WRITE_WAIT_FIRST_OP		<=	1'b0;
		end
	end

// 判断是否有写入数据产生
always @(posedge FDC_CLK or negedge RESET_N)
	if(~RESET_N)
	begin
		WRITE_DATA_MODI1		<=	1'b0;
	end
	else
	begin
		// 写入信号变化
		if( ({LATCHED_FDC_CT[6],FDC_CT[6]}==2'b00) && (FDC_CT[5]!=LATCHED_FDC_CT[5]) )
		begin
			WRITE_DATA_MODI1		<=	1'b1;
		end
		else
		begin
			if(FDC_RAM_W)
				WRITE_DATA_MODI1		<=	1'b0;
		end
	end


// 判断写入的值
always @(posedge FDC_CLK or negedge RESET_N)
	if(~RESET_N)
	begin
		WRITE_DATA_BIT_VAL	<=	1'b0;
	end
	else
	begin
		// 写入信号变化
		if( ({LATCHED_FDC_CT[6],FDC_CT[6]}==2'b00) && (FDC_CT[5]!=LATCHED_FDC_CT[5]) )
		begin
			//	9'h01B 9'h056 9'h072
			if(WRITE_DATA_CNT==10'h01B)
			begin
				WRITE_DATA_BIT_VAL	<=	1'b1;
			end
			else
			begin
				WRITE_DATA_BIT_VAL	<=	1'b0;
			end
		end
	end


// 模拟磁盘数据位
always @(posedge FDC_CLK or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		SYNC_CNT			<=	19'b0;

		BIT_CNT				<=	3'd0;

		FDC_RAM_R			<=	1'b0;
		FDC_RAM_W			<=	1'b0;
		
		FDC_DATA_SET1		<=	1'b0;

		FDC_POLL1			<=	1'b0;
		FDC_POLL2			<=	1'b0;

		FLOPPY_BYTE			<=	12'h000;
		FLOPPY_SECTOR_BYTE	<=	8'h00;
		FLOPPY_SECTOR_DELAY	<=	8'h00;
		FLOPPY_ADDRESS_R	<=	18'b0;
		FLOPPY_ADDRESS_W	<=	18'b0;

		WRITE_DATA1			<=	8'b0;

		FD_REC1				<=	1'b0;
		CLK_CNT				<=	7'h00;
	end
	else
	begin
		begin
			if( ({LATCHED_FDC_CT[6],FDC_CT[6]}==2'b00) && (FDC_CT[5]!=LATCHED_FDC_CT[5]) && WRITE_DATA_CNT[9] )
			begin
				// INIT 磁道空白区，约1/10圈空白。
				// 找到第1个时钟位
				BIT_CNT					<=	3'd7;

				// 下一个需要读取的位置
				FLOPPY_BYTE				<=	12'h001;
				FLOPPY_SECTOR_BYTE		<=	8'h00;

				FLOPPY_ADDRESS_R		<=	{TRACK, 4'b0};
				SYNC_CNT				<=	19'b0;
				FDC_RAM_R				<=	1'b1;

				FDC_RAM_W				<=	1'b0;

				FDC_DATA_SET1			<=	1'b0;

				FD_REC1					<=	1'b1;
				FDC_POLL1				<=	1'b0;
				FDC_POLL2				<=	1'b0;
				CLK_CNT					<=	7'h03;
			end
			else
			begin
				if( ({LATCHED_FDC_CT[6],FDC_CT[6]}==2'b00) && (FDC_CT[5]!=LATCHED_FDC_CT[5]) && WRITE_DATA_CNT==10'h02F )
				begin
					// 格式化时，数据区之前无空白。数据存盘时，写入数据区留有50个左右的时钟周期空白。
					// 写入扇区定位，写入扇区前有约0x28个时钟周期的空白。
					FDC_RAM_W				<=	1'b0;

					FDC_DATA_SET1			<=	1'b0;

					FD_REC1					<=	1'b1;
					FDC_POLL1				<=	1'b0;
					FDC_POLL2				<=	1'b0;
					CLK_CNT					<=	7'h03;
				end
				else
				begin
					case(CLK_CNT)
					7'h00:	// 同步信号 324 * 8 * 0x70 = 290304
						begin
							FD_REC1			<=	1'b0;
							SYNC_CNT		<=	SYNC_CNT+1;

							FDC_RAM_R		<=	1'b0;
							FDC_RAM_W		<=	1'b0;

							if(SYNC_CNT[18])
							//if(SYNC_CNT[10])
							begin
								CLK_CNT		<=	CLK_CNT + 1;
							end
						end

					7'h01:
						begin
							FDC_RAM_R	<=	1'b0;
							FDC_RAM_W	<=	1'b0;

							// 如果是写入，等待时钟沿的变化
							if( ({LATCHED_FDC_CT[6],FDC_CT[6]}==2'b00) && ({LATCHED_FDC_CT[5],FDC_CT[5]}==2'b01) )
							begin
								CLK_CNT			<=	CLK_CNT;
							end
							else
							begin
								CLK_CNT			<=	CLK_CNT + 1;
							end
						end

					// CLOCK DOMAIN
					7'h02:
						begin
							BIT_CNT				<=	BIT_CNT-1;

							// 读取
							if(BIT_CNT==3'd0)
							begin
								begin
									FLOPPY_BYTE			<=	FLOPPY_BYTE + 1'b1;

									FLOPPY_ADDRESS_R	<=	{TRACK, 4'b0} + {6'b000000, FLOPPY_BYTE};
								end

								FDC_RAM_R		<=	1'b1;
							end

							FD_REC1				<=	1'b1;

							CLK_CNT				<=	CLK_CNT + 1;
						end


					// POOLING
					// 从读取POLLING成功（值为1），到读取DATA中间间隔了0x43 个时钟周期。
					7'h03:
						begin
							FDC_RAM_R			<=	1'b0;
							FDC_RAM_W			<=	1'b0;

							FDC_POLL1			<=	1'b1;
							FDC_POLL2			<=	1'b1;
							CLK_CNT				<=	CLK_CNT + 1;
						end

					7'h06:	// 1us
						begin
							FD_REC1			<=	1'b0;
							CLK_CNT			<=	CLK_CNT + 1;
						end

					// DATA DOMAIN
					7'h1E:
						begin
							FD_REC1			<=	FDC_RAM_DATA_R_BIT;
							CLK_CNT			<=	CLK_CNT + 1;
						end

					7'h1F:
						begin
							FDC_DATA_SET1	<=	1'b1;
							CLK_CNT			<=	CLK_CNT + 1;
						end

					7'h20:
						begin
							FDC_DATA_SET1	<=	1'b0;
							CLK_CNT			<=	CLK_CNT + 1;
						end

					7'h22:
						begin
							FD_REC1			<=	1'b0;
							CLK_CNT			<=	CLK_CNT + 1;
						end

					7'h25:
						begin
							FDC_POLL1		<=	1'b0;
							FDC_POLL2		<=	1'b0;
							CLK_CNT			<=	CLK_CNT + 1;
						end

					// 扇区结束延时
					7'h70:
						begin
							// 写入
							WRITE_DATA1		<=	{WRITE_DATA1[6:0],WRITE_DATA_BIT_VAL};

							if(BIT_CNT==3'd0)
							begin
								FLOPPY_ADDRESS_W	<=	FLOPPY_ADDRESS_R;
								FDC_RAM_W			<=	WRITE_DATA_MODI1;
							end

							CLK_CNT			<=	CLK_CNT + 1;
						end

					7'h71:
						begin
							// 写入结束
							FDC_RAM_W			<=	1'b0;

							FDC_SIG_CLK			<=	WRITE_DATA_MODI1;

							// 扇区结束时的延时
							if(BIT_CNT==3'd0 && FLOPPY_SECTOR_BYTE==8'h99)
							begin
								FLOPPY_SECTOR_DELAY	<=	8'hA5;
							end
							else
							begin
								FLOPPY_SECTOR_DELAY	<=	8'h00;
							end

							CLK_CNT			<=	CLK_CNT + 1;
						end

					// 扇区结束时的延时
					7'h72:
						begin
							FDC_SIG_CLK			<=	1'b0;

							// 扇区结束时的延时
							if(FLOPPY_SECTOR_DELAY==8'h00)
							begin
								CLK_CNT		<=	CLK_CNT + 1;
							end
							else
							begin
								FLOPPY_SECTOR_DELAY	<=	FLOPPY_SECTOR_DELAY-1;
							end
						end

					7'h73:
						begin
							if(BIT_CNT==3'd0)
							begin
								if(FLOPPY_BYTE==`FD_TRACK_LEN||FLOPPY_SECTOR_BYTE==8'h99)
								begin
									FLOPPY_SECTOR_BYTE	<=	8'h00;
								end
								else
								begin
									FLOPPY_SECTOR_BYTE	<=	FLOPPY_SECTOR_BYTE+1;
								end
							end

							if(BIT_CNT==3'd0 && FLOPPY_BYTE==`FD_TRACK_LEN)
							begin
								FLOPPY_BYTE			<=	12'h000;
								//FLOPPY_SECTOR_BYTE	<=	8'h00;

								FLOPPY_ADDRESS_R	<=	{TRACK, 4'b0};
								SYNC_CNT			<=	19'b0;

								CLK_CNT				<=	7'h00;
							end
							else
							begin
								CLK_CNT		<=	7'h01;
							end
						end

					default:
						begin
							FDC_RAM_R	<=	1'b0;
							FDC_RAM_W	<=	1'b0;
							CLK_CNT		<=	CLK_CNT + 1;
						end
					endcase
				end
			end
		end
	end
end


always @(posedge FDC_CLK or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		PHASE0	<=	1'b0;
		PHASE1	<=	1'b0;
		PHASE2	<=	1'b0;
		PHASE3	<=	1'b0;
		MOTOR	<=	1'b0;
		DRIVE1	<=	1'b0;
		DRIVE2	<=	1'b0;
		WRITE_REQUEST_N	<=	1'b1;
		WRITE_DATA_BIT	<=	1'b0;
	end
	else
	begin
		PHASE0	<=	FDC_CT[0];
		PHASE1	<=	FDC_CT[1];
		PHASE2	<=	FDC_CT[2];
		PHASE3	<=	FDC_CT[3];
		DRIVE1	<=	FDC_CT[4];
		DRIVE2	<=	FDC_CT[7];
		MOTOR	<=	(FDC_CT[4])|(FDC_CT[7]);
		WRITE_REQUEST_N	<=	FDC_CT[6];
		WRITE_DATA_BIT	<=	FDC_CT[5];
	end
end

//assign DRIVE1_X =  DRIVE1 & MOTOR;
//assign DRIVE2_X = !DRIVE1 & MOTOR;

assign DRIVE1_X =	DRIVE1 & MOTOR;
assign DRIVE2_X =	DRIVE2 & MOTOR;

assign DRIVE1_FLOPPY_WP	=	~SW[0];
assign DRIVE2_FLOPPY_WP	=	~SW[1];

assign FDC_WP	=	DRIVE1?DRIVE1_FLOPPY_WP:
					DRIVE2?DRIVE2_FLOPPY_WP:
					1'b1;


assign DRIVE1_EN =	(DRIVE1) & MOTOR;
assign DRIVE2_EN =	(DRIVE2) & MOTOR;


assign TRACK		=	(DRIVE1_EN)		?	{1'b0,TRACK1}:
						(DRIVE2_EN)		?	{1'b1,TRACK2}:
											14'b0;

assign TRACK1_UP	= TRACK1 + `FD_TRACK_STEP;
assign TRACK1_DOWN	= TRACK1 - `FD_TRACK_STEP;
assign TRACK2_UP	= TRACK2 + `FD_TRACK_STEP;
assign TRACK2_DOWN	= TRACK2 - `FD_TRACK_STEP;


//assign FLOPPY_ADDRESS_R = {TRACK, 4'b0} + {5'b00000, FLOPPY_BYTE};


//always @ (posedge PH_2)
always @(negedge FDC_CLK)
begin
	PHASE0_1 <= PHASE0;
	PHASE0_2 <= PHASE0_1;					// Delay 2 clock cycles
	PHASE1_1 <= PHASE1;
	PHASE1_2 <= PHASE1_1;					// Delay 2 clock cycles
	PHASE2_1 <= PHASE2;
	PHASE2_2 <= PHASE2_1;					// Delay 2 clock cycles
	PHASE3_1 <= PHASE3;
	PHASE3_2 <= PHASE3_1;					// Delay 2 clock cycles
end

always @(posedge FDC_CLK or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		STEPPER1	<=	2'b00;
		STEPPER2	<=	2'b00;
		TRACK1		<=	13'd0;
		TRACK2		<=	13'd0;

		TRACK1_NO	<=	8'd0;
		TRACK2_NO	<=	8'd0;
	end
	else
	begin
//		if(DRIVE1^DRIVE_SWAP)
		if(DRIVE1)
		begin
			case ({PHASE0_2, PHASE1_2, PHASE2_2, PHASE3_2})
			4'b1000:
			begin
				if(STEPPER1 == 2'b11)
				begin
					//if(TRACK1 != `FD_MAX_LEN)
					if(TRACK1_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK1 <= TRACK1_UP;
						TRACK1_NO <= TRACK1_NO+1;
						STEPPER1 <= 2'b00;
					end
				end
				else
				if(STEPPER1 == 2'b01)
				begin
					//if(TRACK1 != 17'h0)
					if(TRACK1_NO != 8'd0)
					begin
						TRACK1 <= TRACK1_DOWN;
						TRACK1_NO <= TRACK1_NO-1;
						STEPPER1 <= 2'b00;
					end
				end
			end
			4'b0100:
			begin
				if(STEPPER1 == 2'b00)
				begin
					//if(TRACK1 != `FD_MAX_LEN)
					if(TRACK1_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK1 <= TRACK1_UP;
						TRACK1_NO <= TRACK1_NO+1;
						STEPPER1 <= 2'b01;
					end
				end
				else
				if(STEPPER1 == 2'b10)
				begin
					//if(TRACK1 != 17'h0)
					if(TRACK1_NO != 8'd0)
					begin
						TRACK1 <= TRACK1_DOWN;
						TRACK1_NO <= TRACK1_NO-1;
						STEPPER1 <= 2'b01;
					end
				end
			end
			4'b0010:
			begin
				if(STEPPER1 == 2'b01)
				begin
					//if(TRACK1 != `FD_MAX_LEN)
					if(TRACK1_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK1 <= TRACK1_UP;
						TRACK1_NO <= TRACK1_NO+1;
						STEPPER1 <= 2'b10;
					end
				end
				else
				if(STEPPER1 == 2'b11)
				begin
					//if(TRACK1 != 17'h0)
					if(TRACK1_NO != 8'd0)
					begin
						TRACK1 <= TRACK1_DOWN;
						TRACK1_NO <= TRACK1_NO-1;
						STEPPER1 <= 2'b10;
					end
				end
			end
			4'b0001:
			begin
				if(STEPPER1 == 2'b10)
				begin
					//if(TRACK1 != `FD_MAX_LEN)
					if(TRACK1_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK1 <= TRACK1_UP;
						TRACK1_NO <= TRACK1_NO+1;
						STEPPER1 <= 2'b11;
					end
				end
				else
				if(STEPPER1 == 2'b00)
				begin
					//if(TRACK1 != 17'h0)
					if(TRACK1_NO != 8'd0)
					begin
						TRACK1 <= TRACK1_DOWN;
						TRACK1_NO <= TRACK1_NO-1;
						STEPPER1 <= 2'b11;
					end
				end
			end
			endcase
		end

		else

		begin
			case ({PHASE0_2, PHASE1_2, PHASE2_2, PHASE3_2})
			4'b1000:
			begin
				if(STEPPER2 == 2'b11)
				begin
					//if(TRACK2 != `FD_MAX_LEN)
					if(TRACK2_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK2 <= TRACK2_UP;
						TRACK2_NO <= TRACK2_NO+1;
						STEPPER2 <= 2'b00;
					end
				end
				else
				if(STEPPER2 == 2'b01)
				begin
					//if(TRACK2 != 17'h0)
					if(TRACK2_NO != 8'd0)
					begin
						TRACK2 <= TRACK2_DOWN;
						TRACK2_NO <= TRACK2_NO-1;
						STEPPER2 <= 2'b00;
					end
				end
			end
			4'b0100:
			begin
				if(STEPPER2 == 2'b00)
				begin
					//if(TRACK2 != `FD_MAX_LEN)
					if(TRACK2_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK2 <= TRACK2_UP;
						TRACK2_NO <= TRACK2_NO+1;
						STEPPER2 <= 2'b01;
					end
				end
				else
				if(STEPPER2 == 2'b10)
				begin
					//if(TRACK2 != 17'h0)
					if(TRACK2_NO != 8'd0)
					begin
						TRACK2 <= TRACK2_DOWN;
						TRACK2_NO <= TRACK2_NO-1;
						STEPPER2 <= 2'b01;
					end
				end
			end
			4'b0010:
			begin
				if(STEPPER2 == 2'b01)
				begin
					//if(TRACK2 != `FD_MAX_LEN)
					if(TRACK2_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK2 <= TRACK2_UP;
						TRACK2_NO <= TRACK2_NO+1;
						STEPPER2 <= 2'b10;
					end
				end
				else
				if(STEPPER2 == 2'b11)
				begin
					//if(TRACK2 != 17'h0)
					if(TRACK2_NO != 8'd0)
					begin
						TRACK2 <= TRACK2_DOWN;
						TRACK2_NO <= TRACK2_NO-1;
						STEPPER2 <= 2'b10;
					end
				end
			end
			4'b0001:
			begin
				if(STEPPER2 == 2'b10)
				begin
					//if(TRACK2 != `FD_MAX_LEN)
					if(TRACK2_NO != `FD_MAX_TRACK_NO)
					begin
						TRACK2 <= TRACK2_UP;
						TRACK2_NO <= TRACK2_NO+1;
						STEPPER2 <= 2'b11;
					end
				end
				else
				if(STEPPER2 == 2'b00)
				begin
					//if(TRACK2 != 17'h0)
					if(TRACK2_NO != 8'd0)
					begin
						TRACK2 <= TRACK2_DOWN;
						TRACK2_NO <= TRACK2_NO-1;
						STEPPER2 <= 2'b11;
					end
				end
			end
			endcase
		end
	end
end



reg	[19:0]	LATCHED_FDC_CNT_CT;
reg	[7:0]	LATCHED_FDC_CT;


always @(posedge FDC_CLK or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		LATCHED_FDC_CT		<=	8'hFF;
		//FDC_SIG_CLK			<=	1'b0;
		LATCHED_FDC_CNT_CT	<=	20'hFFFFF;
	end
	else
	begin
		LATCHED_FDC_CT		<=	FDC_CT;
		LATCHED_FDC_CNT_CT	<=	FDC_CNT_CT;
		//FDC_SIG_CLK			<=	(LATCHED_FDC_CT!=FDC_CT);
	end
end

assign FDC_SIG = (FDC_CNT[7]|FDC_CNT_POLL[7]|FDC_CNT_DATA[7]|FDC_CNT_CT[19]|(LATCHED_FDC_CNT_CT==0));


endmodule 

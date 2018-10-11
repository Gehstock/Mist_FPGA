// DottoriLog: A Verilog implementation of Sega's Dottori-Kun
// 2017 Furrtek - Public domain
// Written based on information from Chris Covell

module dottori(
	input CLK_4M,
	input [1:0] GAME,
	output RED,
	output GREEN,
	output BLUE,
	output vSYNC,
	output hSYNC,
	input nRESET,
	input [7:0] BUTTONS
);

wire [7:0] DATA_BUS;				// Z80
wire [15:0] ADDRESS_BUS;		// Z80
wire [7:0] ROM_DATA1;
wire [7:0] ROM_DATA2;
wire [7:0] ROM_DATA3;
reg [7:0] ROM_DATA_OUT;
wire [7:0] RAM_DATA_OUT;
wire [10:0] RAM_ADDRESS_BUS;	// Multiplexed (Z80 and render)

wire nZ80MEMRD;					// Low when Z80 reads any memory
wire nLD;							// Pulse low @2MHz when Z80 is stalled (read from VRAM)
wire nVRAMWREN;					// Low when Z80 is running, allows writing
wire nRAM_RD;						// Gated Z80 RAM read
wire nINPUTS_RD;					// Low when Z80 reads inputs (port read)
wire nRD, nMREQ, nWR, nIORQ;	// Z80
wire nCLK_4M, n4M_4, n4M_8, n4M_16, n4M_32, n4M_64, CLK_4M_128, n4M_128, n4M_1024, n4M_2048;
wire n4M_4096, n4M_8192, CLK_4M_16384, n4M_16384, CLK_4M_32768, n4M_32768;
wire nH_SYNC, V_SYNC;
wire IC16_11, LS08_6, PIXEL;
wire LS10_12, IC4_4, IC10_14;

reg [5:0] PAL_LATCH;				// Foreground and background colors
reg [7:0] SHIFT_REG;				// 8-pixel line
reg VRAMWREN;
reg nINT;							// Z80
reg [3:0] COUNT_IC10;			// 4-bit counters
reg [3:0] COUNT_IC11;
reg [3:0] COUNT_IC12;
reg [3:0] COUNT_IC13;

// Half clock delay (125ns)
ROM1 ROM1(ADDRESS_BUS[13:0], ~CLK_4M, ROM_DATA1);
ROM2 ROM2(ADDRESS_BUS[13:0], ~CLK_4M, ROM_DATA2);
ROM3 ROM3(ADDRESS_BUS[13:0], ~CLK_4M, ROM_DATA3);

// Half clock delay (125ns)
RAM MEM_RAM(RAM_ADDRESS_BUS, CLK_4M, DATA_BUS, ~nRAM_WR, RAM_DATA_OUT);

assign DATA_BUS = (~nRAM_RD & nRAM_WR & nLD & ADDRESS_BUS[15] & ~nZ80MEMRD) ? RAM_DATA_OUT :		// RAM read
								(~ADDRESS_BUS[15] & ~nZ80MEMRD) ? ROM_DATA_OUT :			// ROM read
								(~nINPUTS_RD) ? BUTTONS : 8'bzzzzzzzz;					// Inputs read	

// IC5, IC4: RAM/VRAM write decode and gate
assign nRAM_WR = ~&{ADDRESS_BUS[15], VRAMWREN, ~|{nMREQ, nWR}};

// IC14, IC15, IC16: RAM Z80/Render address switch
assign RAM_ADDRESS_BUS = nLD ? ADDRESS_BUS[10:0] :
											{IC16_11, CLK_4M_32768, n4M_16384, n4M_8192, n4M_4096,
											n4M_2048, n4M_1024, n4M_128, n4M_64, n4M_32, n4M_16};

// IC16: Z80 RAM read gate
assign nRAM_RD = nLD ? nZ80MEMRD : 1'b0;

// IC6: V-Sync generation
assign V_SYNC = LS08_6 & n4M_4096 & n4M_8192;

// IC3: Z80 memory and port access
assign nZ80MEMRD = nRD | nMREQ;
assign nINPUTS_RD = nRD | nIORQ;
assign nIOWR = nWR | nIORQ;

// IC17: Front/back color latch
always @(posedge nIOWR or negedge nRESET)
begin
	if (!nRESET)
		PAL_LATCH <= 6'd0;
	else
		PAL_LATCH <= DATA_BUS[5:0];
end

always @(posedge nCLK_4M)
begin
case (GAME)
  2'b10 : ROM_DATA_OUT = ROM_DATA2;
  2'b11 : ROM_DATA_OUT = ROM_DATA3;
  default : ROM_DATA_OUT = ROM_DATA1;
endcase
end


// IC21: Pixel and sync gate
assign {BLUE, GREEN, RED} = !nH_SYNC ? 3'b000 : PIXEL ? PAL_LATCH[2:0] : PAL_LATCH[5:3];	// 3'd7 : 3'd0;
assign vSYNC = V_SYNC;// ? 1'b0 : nH_SYNC;
assign hSYNC = !nH_SYNC;
// IC22: Pixel line serializer
always @(posedge nCLK_4M)
begin
	if (!nLD)
		SHIFT_REG <= RAM_DATA_OUT;
	else
		SHIFT_REG <= {SHIFT_REG[6:0], 1'b0};
end
assign PIXEL = SHIFT_REG[7];

// IC7, IC5: H-Sync generation
assign nH_SYNC = ~(CLK_4M_128 & ~LS10_12);

// IC3: Z80 clock gate during VRAM read
assign CLK_Z80 = CLK_4M | nVRAMWREN;

// IC9B: VRAM write allow signal generation
always @(posedge CLK_4M or negedge nRESET)
begin
	if (!nRESET)
		VRAMWREN <= 1'b0;
	else
		VRAMWREN <= ~(~(n4M_8 | n4M_4) & IC4_4);
end
assign nVRAMWREN = ~VRAMWREN;

// IC7: Pixel line load signal
assign nLD = ~(nVRAMWREN & IC10_14);

// IC10: Pixel counter 1
always @(posedge nCLK_4M or negedge nRESET)
begin
	if (!nRESET)
		COUNT_IC10 <= 4'd0;
	else
		COUNT_IC10 <= COUNT_IC10 + 1'b1;
end
assign IC10_14 = COUNT_IC10[0];
assign n4M_4 = COUNT_IC10[1];
assign n4M_8 = COUNT_IC10[2];
assign n4M_16 = COUNT_IC10[3];
assign CARRY_A = &{COUNT_IC10};

// IC11: Pixel counter 2
always @(posedge nCLK_4M or negedge nRESET)
begin
	if (!nRESET)
		COUNT_IC11 <= 4'd0;
	else
		if (CARRY_A) COUNT_IC11 <= COUNT_IC11 + 1'b1;
end
assign n4M_32 = COUNT_IC11[0];
assign n4M_64 = COUNT_IC11[1];
assign n4M_128 = COUNT_IC11[2];
assign n4M_256 = COUNT_IC11[3];

// IC12: Line counter 1
always @(posedge n4M_128 or negedge nRESET)
begin
	if (!nRESET)
		COUNT_IC12 <= 4'd0;
	else
		if (n4M_256) COUNT_IC12 <= COUNT_IC12 + 1'b1;
end
//assign n4M_512 = COUNT_IC12[0];
assign n4M_1024 = COUNT_IC12[1];
assign n4M_2048 = COUNT_IC12[2];
assign n4M_4096 = COUNT_IC12[3];
assign CARRY_B = &{COUNT_IC12, n4M_256};

// IC13: Line counter 2
always @(posedge n4M_128 or negedge nRESET)
begin
	if (!nRESET)
		COUNT_IC13 <= 4'd0;
	else
		if (CARRY_B) COUNT_IC13 <= COUNT_IC13 + 1'b1;
end
assign n4M_8192 = COUNT_IC13[0];
assign n4M_16384 = COUNT_IC13[1];
assign n4M_32768 = COUNT_IC13[2];
assign n4M_65536 = COUNT_IC13[3];
assign CARRY_C = &{COUNT_IC13, CARRY_B};

// IC9A: Z80 interrupt (V-Blank) generator
always @(posedge n4M_128)
	nINT <= ~CARRY_C;

// IC6 (wrong name, "IC16_11" should be "IC6_11")
assign IC16_11 = n4M_32768 & n4M_65536;

// IC8
assign nCLK_4M = ~CLK_4M;
assign CLK_4M_128 = ~n4M_128;
assign CLK_4M_16384 = ~n4M_16384;
assign CLK_4M_32768 = ~n4M_32768;

// IC4
assign IC4_1 = ~(n4M_32768 | n4M_65536);
assign IC4_4 = ~(IC4_1 | n4M_256);

// IC5: Used for H-Sync
assign LS10_12 = ~&{n4M_32, n4M_64, n4M_256};

// IC6: Used for V-Sync
assign LS08_6 = IC4_1 & CLK_4M_16384;

// IC1: Best CPU :)
cpu_z80 CPU(CLK_Z80, nRESET,
	DATA_BUS,
	ADDRESS_BUS,
	nIORQ, nMREQ,
	nRD, nWR,
	nINT, 1'b1);

endmodule

module mems
(
	input 			CPUCLKx2,
	output [14:0]  rom_addr,
	input	  [7:0]	rom_data,
	input [15:0]	MCPU_ADRS,
	input				MCPU_VMA,
	input				MCPU_WE,
	input	 [7:0]	MCPU_DO,
	output [7:0]	MCPU_DI,
	output			IO_CS,
	input  [7:0]	IO_O,

	input [15:0]	SCPU_ADRS,
	input				SCPU_VMA,
	input				SCPU_WE,
	input	 [7:0]	SCPU_DO,
	output [7:0]	SCPU_DI,
	output			SCPU_WSG_WE,

	input				VCLKx4,
	input	 [10:0]	vram_a,
	output [15:0]	vram_d,
	input   [6:0]	spra_a,
	output [23:0]	spra_d,
	

	input				ROMCL,	// Downloaded ROM image
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

//wire [7:0] mrom_d; 
wire [7:0] srom_d;
assign rom_addr = MCPU_ADRS[14:0];
//assign mrom_d = rom_data;

scpui_rom scpui_rom(
	.clk(CPUCLKx2),
	.addr(SCPU_ADRS[12:0]),
	.data(srom_d)
);


wire				mram_cs0 = ( MCPU_ADRS[15:11] == 5'b00000  ) & MCPU_VMA;	// $0000-$07FF
wire				mram_cs1 = ( MCPU_ADRS[15:11] == 5'b00001  ) & MCPU_VMA;	// $0800-$0FFF
wire				mram_cs2 = ( MCPU_ADRS[15:11] == 5'b00010  ) & MCPU_VMA;	// $1000-$17FF
wire				mram_cs3 = ( MCPU_ADRS[15:11] == 5'b00011  ) & MCPU_VMA;	// $1800-$1FFF
wire				mram_cs4 = ( MCPU_ADRS[15:11] == 5'b00100  ) & MCPU_VMA;	// $2000-$27FF
wire				mram_cs5 = ( MCPU_ADRS[15:10] == 6'b010000 ) & MCPU_VMA;	// $4000-$43FF
assign 			IO_CS    = ( MCPU_ADRS[15:11] == 5'b01001  ) & MCPU_VMA;	// $4800-$4FFF
wire				mrom_cs  =                 ( MCPU_ADRS[15] ) & MCPU_VMA;	// $8000-$FFFF

wire				mram_w0  = ( mram_cs0 & MCPU_WE );
wire				mram_w1  = ( mram_cs1 & MCPU_WE );
wire				mram_w2  = ( mram_cs2 & MCPU_WE );
wire				mram_w3  = ( mram_cs3 & MCPU_WE );
wire				mram_w4  = ( mram_cs4 & MCPU_WE );
wire				mram_w5  = ( mram_cs5 & MCPU_WE );

wire	[7:0]		mram_o0, mram_o1, mram_o2, mram_o3, mram_o4, mram_o5;

assign 			MCPU_DI  = mram_cs0 ? mram_o0 :
								  mram_cs1 ? mram_o1 :
								  mram_cs2 ? mram_o2 :
								  mram_cs3 ? mram_o3 :
								  mram_cs4 ? mram_o4 :
								  mram_cs5 ? mram_o5 :
								  mrom_cs  ? rom_data ://mrom_d  :
								  IO_CS    ? IO_O    :
								  8'h0;

wire	[10:0]	mram_ad = MCPU_ADRS[10:0];

DPRAM_2048V		main_ram0( CPUCLKx2, mram_ad, MCPU_DO, mram_o0, mram_w0, VCLKx4, vram_a, vram_d[7:0]   );
DPRAM_2048V		main_ram1( CPUCLKx2, mram_ad, MCPU_DO, mram_o1, mram_w1, VCLKx4, vram_a, vram_d[15:8]  );

DPRAM_2048V		main_ram2( CPUCLKx2, mram_ad, MCPU_DO, mram_o2, mram_w2, VCLKx4, { 4'b1111, spra_a }, spra_d[7:0]   );
DPRAM_2048V		main_ram3( CPUCLKx2, mram_ad, MCPU_DO, mram_o3, mram_w3, VCLKx4, { 4'b1111, spra_a }, spra_d[15:8]  );
DPRAM_2048V		main_ram4( CPUCLKx2, mram_ad, MCPU_DO, mram_o4, mram_w4, VCLKx4, { 4'b1111, spra_a }, spra_d[23:16] );


																								// (SCPU ADRS)
wire	 			SCPU_CS_SREG = ( ( SCPU_ADRS[15:13] == 3'b000 ) & ( SCPU_ADRS[9:6] == 4'b0000 ) ) & SCPU_VMA;
wire				srom_cs  = ( SCPU_ADRS[15:13] == 3'b111 ) & SCPU_VMA;		// $E000-$FFFF
wire				sram_cs0 = (~SCPU_CS_SREG) & (~srom_cs) & SCPU_VMA;		// $0000-$03FF
wire	[7:0]		sram_o0;

assign 			SCPU_DI  =	sram_cs0 ? sram_o0 :
									srom_cs  ? srom_d  :
									8'h0;

assign			SCPU_WSG_WE = SCPU_CS_SREG & SCPU_WE;

DPRAM_2048 share_ram
(
	CPUCLKx2, mram_ad, MCPU_DO, mram_o5, mram_w5,
	CPUCLKx2, { 1'b0, SCPU_ADRS[9:0] }, SCPU_DO, sram_o0, sram_cs0 & SCPU_WE
);

endmodule 
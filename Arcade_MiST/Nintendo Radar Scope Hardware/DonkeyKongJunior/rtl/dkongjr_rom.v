//============================================================================
// ROMS + Sound samples for analogur sounds.
// 
// Author: gaz68 (https://github.com/gaz68)
// October 2019
//
//============================================================================
//
// Contents of A.DKONGJR.ROM file:
//
// 0x00000 - 0x01FFF 5B PROGRAM ROM (8KB)
// 0x02000 - 0x03FFF 5C PROGRAM ROM (8KB)
// 0x04000 - 0x05FFF 5E PROGRAM ROM (8KB)
// 0x06000 - 0x06FFF 3P GFX ROM (4KB)
// 0x07000 - 0x07FFF 3N GFX ROM (4KB)
// 0x08000 - 0x09FFF 5B PROGRAM ROM REPEAT (8KB)
// 0x0A000 - 0x0A7FF 7C GFX ROM (2KB) 
// 0x0A800 - 0x0AFFF 7C GFX ROM REPEAT (2KB) 
// 0x0B000 - 0x0B7FF 7D GFX ROM (2KB) 
// 0x0B800 - 0x0BFFF 7D GFX ROM REPEAT (2KB) 
// 0x0C000 - 0x0C7FF 7E GFX ROM (2KB) 
// 0x0C800 - 0x0CFFF 7E GFX ROM REPEAT (2KB) 
// 0x0D000 - 0x0D7FF 7F GFX ROM (2KB) 
// 0x0D800 - 0x0DFFF 7F GFX ROM REPEAT (2KB) 
// 0x0E000 - 0x0EFFF 3H SOUND ROM (4KB) 
// 0x0F000 - 0x0F0FF 2E PROM (256B) 
// 0x0F100 - 0x0F1FF 2F PROM (256B) 
// 0x0F200 - 0x0F2FF 2N PROM (256B) 
// 0x0F300 - 0x0FFFF EMPTY
//--------------------------------------------
// 0x10000 - 0x10FFF WALK SOUND SAMPLE 0 (4KB)
// 0x11000 - 0x11FFF WALK SOUND SAMPLE 1 (4KB)
// 0x12000 - 0x12FFF WALK SOUND SAMPLE 2 (4KB)
// 0x13000 - 0x13FFF CLIMB SOUND SAMPLE 0 (4KB)
// 0x14000 - 0x14FFF CLIMB SOUND SAMPLE 1 (4KB)
// 0x15000 - 0x15FFF CLIMB SOUND SAMPLE 2 (4KB)
// 0x16000 - 0x19FFF JUMP SOUND SAMPLE (16KB)
// 0x1A000 - 0x1DFFF LAND SOUND SAMPLE (16KB)
// 0x1E000 - 0x27FFF FALL SOUND SAMPLE (40KB)

module dkongjr_rom
(
	input		I_CLKA,I_CLKB,
	input		[17:0]I_ADDRA,
	input		[16:0]I_ADDRB,
	input		[15:0]I_ADDRC,
	input		[7:0]I_DA,
	input		I_WEA,
	output	[7:0]O_DB,
	output	[15:0]O_DC
);

reg [16:0] W_ADDRB;

// Program ROM address translation (0x0000 - 0x5FFF).
// Program ROMs are addressed as follows:
// 0x0000 - 0x0FFF   ROM 5B [0x0000 - 0x0FFF] (4KB)
// 0x1000 - 0x17FF   ROM 5C [0x1000 - 0x17FF] (2KB)
// 0x1800 - 0x1FFF   ROM 5E [0x1800 - 0x1FFF] (2KB)
// 0x2000 - 0x27FF   ROM 5C [0x0000 - 0x07FF] (2KB)
// 0x2800 - 0x2FFF   ROM 5E [0x0800 - 0x0FFF] (2KB)
// 0x3000 - 0x3FFF   ROM 5B [0x1000 - 0x1FFF] (4KB)
// 0x4000 - 0x47FF   ROM 5E [0x0000 - 0x07FF] (2KB)
// 0x4800 - 0x4FFF   ROM 5C [0x0800 - 0x0FFF] (2KB)
// 0x5000 - 0x57FF   ROM 5E [0x1000 - 0x17FF] (2KB)
// 0x5800 - 0x5FFF   ROM 5C [0x1800 - 0x1FFF] (2KB)

always @(*) begin
    case(I_ADDRB[16:11])
        6'h02: W_ADDRB = {6'h06,I_ADDRB[10:0]}; // 0x1000-0x17FF -> 0x3000-0x37FF in ROM file 
        6'h03: W_ADDRB = {6'h0B,I_ADDRB[10:0]}; // 0x1800-0x1FFF -> 0x5800-0x5FFF in ROM file
        6'h05: W_ADDRB = {6'h09,I_ADDRB[10:0]}; // 0x2800-0x2FFF -> 0x4800-0x4FFF in ROM file
        6'h06: W_ADDRB = {6'h02,I_ADDRB[10:0]}; // 0x3000-0x37FF -> 0x1000-0x17FF in ROM file
        6'h07: W_ADDRB = {6'h03,I_ADDRB[10:0]}; // 0x3800-0x3FFF -> 0x1800-0x1FFF in ROM file
        6'h09: W_ADDRB = {6'h05,I_ADDRB[10:0]}; // 0x4800-0x4FFF -> 0x2800-0x2FFF in ROM file
        6'h0B: W_ADDRB = {6'h07,I_ADDRB[10:0]}; // 0x5800-0x5FFF -> 0x3800-0x3FFF in ROM file
        default: W_ADDRB = I_ADDRB;
    endcase
end

dpram #(16) roms
(
	.clock_a(I_CLKA),
	.wren_a(I_WEA && (I_ADDRA[17:16] == 2'b0)),
	.address_a(I_ADDRA[15:0]),
	.data_a(I_DA),

	.clock_b(I_CLKB),
	.address_b(W_ADDRB),
	.q_b(O_DB)
);

// Write 8-bit download stream to wave ROM as 16-bit words.
reg	[15:0]WAV_ADDR = 0;
reg	[7:0]DA_L = 0;
reg	[15:0]DA16 = 0;

always @(posedge I_CLKA) begin

	if (I_ADDRA[17:16] > 0) begin
		if (I_ADDRA[0] == 1'b0) begin
				DA_L <= I_DA;		
		end else begin	
			DA16 <= {I_DA, DA_L};
			WAV_ADDR <= I_ADDRA[17:1] - 17'h08000;
		end
	end
end

// 16-bit sound samples for analogue sounds. 
dpram #(16, 16) wav_rom
(
	.clock_a(I_CLKA),
	.wren_a(I_WEA),
	.address_a(WAV_ADDR),
	.data_a(DA16),

	.clock_b(I_CLKB),
	.address_b(I_ADDRC),
	.q_b(O_DC)
);

endmodule

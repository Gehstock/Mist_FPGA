//============================================================================
//
//  Tutankham main PCB model (based on Time Pilot core)
//  Copyright (C) 2021 Ace, Artemio Urbina & RTLEngineering
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

//Module declaration, I/O ports
module Tutankham_CPU
(
	input         reset,
	input         clk_49m,          //Actual frequency: 49.152MHz
	input			  juno,
	output  [4:0] red, green, blue, //15-bit RGB, 5 bits per color
	output        video_hsync, video_vsync, video_csync, //CSync not needed for MISTer
	output        video_hblank, video_vblank,
	output        ce_pix,

	input   [7:0] controls_dip,
	input  [15:0] dip_sw,
	input   [2:0] p1_fire_ext,    // {flash_bomb, fire_right, fire_left}
	input   [2:0] p2_fire_ext,    // {flash_bomb, fire_right, fire_left}
	input   [3:0] p1_joy,         // {down, up, right, left} active-HIGH
	input   [3:0] p2_joy,         // {down, up, right, left} active-HIGH
	output  [7:0] cpubrd_Dout,
	output reg   [15:0] CPU_Addr,	
	input   [7:0] CPU_Rom_Data,
	input   [7:0] GFX_Rom_Data,
	output        cs_sounddata, irq_trigger,
	output        cs_dip2, cs_controls_dip1,

	//Screen centering (alters HSync, VSync and VBlank timing in the Konami 082 to reposition the video output)
	input   [3:0] h_center, v_center,

	//ROM chip selects for main program ROMs (6x 4KB)
	input         rom_m1_cs_i, rom_m2_cs_i, rom_m3_cs_i,
	input         rom_m4_cs_i, rom_m5_cs_i, rom_m6_cs_i,
	//ROM chip selects for banked graphics ROMs (9x 4KB)
	input         bank0_cs_i, bank1_cs_i, bank2_cs_i,
	input         bank3_cs_i, bank4_cs_i, bank5_cs_i,
	input         bank6_cs_i, bank7_cs_i, bank8_cs_i,
	input  [24:0] ioctl_addr,
	input   [7:0] ioctl_data,
	input         ioctl_wr,

	input         pause,

	input  [15:0] hs_address,
	input   [7:0] hs_data_in,
	output  [7:0] hs_data_out,
	input         hs_write
);

//------------------------------------------------------- Signal outputs -------------------------------------------------------//

//Assign active high HBlank and VBlank outputs
assign video_hblank = hblk;
assign video_vblank = vblk;

//Output pixel clock enable
assign ce_pix = cen_6m;

//Output select lines for player inputs and DIP switches to sound board
assign cs_controls_dip1 = cs_in0 | cs_in1 | cs_in2 | cs_dsw1;
assign cs_dip2 = cs_dsw2;

//Output primary MC6809E address lines A5 and A6 to sound board
// Swap A5/A6 so the sound board's {A6,A5} mux matches Tutankham's address map:
// 0x8180 (IN0): A[6:5]=00 → mux 00 = coins/start  ✓
// 0x81A0 (IN1): A[6:5]=01 → need mux 01 for P1, so swap: output A5=A[6], A6=A[5]
// 0x81C0 (IN2): A[6:5]=10 → need mux 10 for P2, so swap: output A5=A[6], A6=A[5]
// 0x81E0 (DSW1): A[6:5]=11 → mux 11 = dip_sw  ✓ (swap doesn't matter for 00/11)
//assign cpubrd_A5 = cpu_A[6];
//assign cpubrd_A6 = cpu_A[5];

// Latch CPU data when writing sound commands — the data bus changes
// on the next cycle but sound board needs it held for cen_3m sampling.
reg [7:0] sound_data_latch = 8'd0;
always_ff @(posedge clk_49m) begin
	if(!reset)
		sound_data_latch <= 8'd0;
	else if(cs_soundcmd)
		sound_data_latch <= cpu_Dout;
end
assign cpubrd_Dout = sound_data_latch;

// Latch sound command strobe — hold until sound board's cen_3m can sample it
// The CPU write is brief; the sound board samples on cen_3m which is every 16 clocks.
// We need to stretch the pulse so it's guaranteed to be seen.
reg cs_sounddata_latch = 0;
reg [3:0] snd_data_hold = 0;
always_ff @(posedge clk_49m) begin
    if(!reset) begin
        cs_sounddata_latch <= 0;
        snd_data_hold <= 0;
    end
    else begin
        if(cs_soundcmd) begin
            cs_sounddata_latch <= 1;
            snd_data_hold <= 4'd15;  // Hold for 16 clocks (guarantees one cen_3m)
        end
        else if(snd_data_hold > 0)
            snd_data_hold <= snd_data_hold - 4'd1;
        else
            cs_sounddata_latch <= 0;
    end
end
assign cs_sounddata = cs_sounddata_latch;

// Sound IRQ trigger — stretch pulse so sound board's cen_3m can catch it
reg sound_irq = 0;
reg [3:0] snd_irq_hold = 0;
always_ff @(posedge clk_49m) begin
    if(!reset) begin
        sound_irq <= 0;
        snd_irq_hold <= 0;
    end
    else begin
        if(cs_soundon) begin
            sound_irq <= 1;
            snd_irq_hold <= 4'd15;
        end
        else if(snd_irq_hold > 0)
            snd_irq_hold <= snd_irq_hold - 4'd1;
        else
            sound_irq <= 0;
    end
end
assign irq_trigger = sound_irq;

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 6.144MHz and 3.072MHz clock enables
reg [3:0] div = 4'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 4'd1;
end
wire cen_6m = !div[2:0];
wire cen_3m = !div;

//MC6809E E and Q clock generation from existing div[3:0] counter
//div rolls over every 16 clocks: E toggles at 49.152MHz/16 = 3.072MHz, E freq = 1.536MHz
//Q leads E by 90 degrees (4 system clocks)
reg cpu_E = 0;
reg cpu_Q = 0;
always_ff @(posedge clk_49m) begin
	if(~pause) begin
		case(div[3:0])
			4'd0:  begin cpu_E <= 1; cpu_Q <= 0; end
			4'd4:  begin cpu_E <= 1; cpu_Q <= 1; end
			4'd8:  begin cpu_E <= 0; cpu_Q <= 1; end
			4'd12: begin cpu_E <= 0; cpu_Q <= 0; end
			default: ;
		endcase
	end
end

//------------------------------------------------------------ CPUs ------------------------------------------------------------//

//Primary CPU - Motorola MC6809E ( Konami1 for Juno First)
wire [15:0] cpu_A;
wire [7:0] cpu_Dout;
wire cpu_RnW;
mc6809e E3
(
	.D(cpu_Din),
	.DOut(cpu_Dout),
	.ADDR(cpu_A),
	.RnW(cpu_RnW),
	.E(cpu_E),
	.Q(cpu_Q),
	.nIRQ(n_irq),
	.nFIRQ(1'b1),
	.nNMI(1'b1),
	.BS(),
	.BA(),
	.AVMA(),
	.BUSY(),
	.LIC(),
	.nHALT(1'b1),
	.nRESET(reset)
);

//------------------------------------------------------ Address decoding ------------------------------------------------------//
//  tutankham
//  
//    -- DIPS2 $8160
//    dip2_cs <=		'1' when STD_MATCH(cpu_a, X"816"&"----") else '0';
//    -- IN0 $8180
//    in0_cs <=			'1' when STD_MATCH(cpu_a, X"818"&"----") else '0';
//    -- IN1 $81A0
//    in1_cs <=			'1' when STD_MATCH(cpu_a, X"81A"&"----") else '0';
//    -- IN2 $81C0
//    in2_cs <=			'1' when STD_MATCH(cpu_a, X"81C"&"----") else '0';
//    -- DIPS1 $81E0
//    dip1_cs <=		'1' when STD_MATCH(cpu_a, X"81E"&"----") else '0';
//    -- Interrupt Enable $8200
//    intena_cs <= 	'1' when STD_MATCH(cpu_a, X"8200") else '0';
//    -- RAM $8800-$8FFF
//    wram_cs <=		'1' when STD_MATCH(cpu_a, X"8"&"1-----------") else '0';
//

  
//  junofrst
//
//    -- DIPS2 $8010
//    dip2_cs <=		'1' when STD_MATCH(cpu_a, X"8010") else '0';
//    -- IN0 $8020
//    in0_cs <=			'1' when STD_MATCH(cpu_a, X"8020") else '0';
//    -- IN1 $8024
//    in1_cs <=			'1' when STD_MATCH(cpu_a, X"8024") else '0';
//    -- IN2 $8028
//    in2_cs <=			'1' when STD_MATCH(cpu_a, X"8028") else '0';
//    -- DIPS1 $802C
//    dip1_cs <=		'1' when STD_MATCH(cpu_a, X"802C") else '0';
//    -- Interrupt Enable $8030
//    intena_cs <= 	'1' when STD_MATCH(cpu_a, X"8030") else '0';
//    -- blitter
//    blitter_cs <= '1' when STD_MATCH(cpu_a, X"807" & "00--") else '0';
//    -- RAM $8100-$8FFF
//    wram_cs <=		'1' when STD_MATCH(cpu_a, X"8"&"------------") else '0';

//Tutankham memory map
wire n_cs_videoram = ~(cpu_A[15] == 1'b0);               // 0x0000-0x7FFF (32KB video RAM)
// NOTE: There is no general work RAM at 0x8000-0x87FF in Tutankham.
// That region is entirely I/O (palette, scroll, controls, mainlatch, etc.)
// The only RAM in the 0x8xxx range is at 0x8800-0x8FFF (workram2).
// Keeping this wire for hiscore compatibility but it should never be used in the data mux.
wire n_cs_workram  = 1'b1;  // Disabled — no work RAM at 0x8000-0x87FF
wire n_cs_workram2 = ~(cpu_A[15:11] == 5'b10001);         // 0x8800-0x8FFF (2KB work RAM expansion)
wire n_cs_bankrom  = ~(cpu_A[15:12] == 4'b1001);          // 0x9000-0x9FFF (4KB banked ROM window)
wire n_cs_mainrom  = ~(cpu_A[15:13] == 3'b101 |
                       cpu_A[15:13] == 3'b110 |
                       cpu_A[15:13] == 3'b111);            // 0xA000-0xFFFF (24KB main ROM)

//Tutankham I/O decoding (memory-mapped in 0x8000-0x87FF region)
wire cs_palette    = (cpu_A[15:4] == 12'h800);             // 0x8000-0x800F (palette RAM)
wire cs_scroll     = (cpu_A[15:4] == 12'h810);             // 0x8100-0x810F (scroll register)
wire cs_watchdog   = (cpu_A[15:4] == 12'h812);             // 0x8120 (watchdog)
wire cs_dsw2       = (cpu_A[15:4] == 12'h816);             // 0x8160 (DIP SW2)
wire cs_in0        = (cpu_A[15:4] == 12'h818);             // 0x8180 (IN0: coins, start)
wire cs_in1        = (cpu_A[15:4] == 12'h81A);             // 0x81A0 (IN1: P1 controls)
wire cs_in2        = (cpu_A[15:4] == 12'h81C);             // 0x81C0 (IN2: P2 controls)
wire cs_dsw1       = (cpu_A[15:4] == 12'h81E);             // 0x81E0 (DIP SW1)
wire cs_mainlatch  = (cpu_A[15:3] == 13'h1040) & ~cpu_RnW; // 0x8200-0x8207 (main latch)
wire cs_banksel_wr = (cpu_A[15:8] == 8'h83) & ~cpu_RnW;    // 0x8300 (bank select)	 (8060 for Juno First)
wire cs_soundon    = (cpu_A[15:8] == 8'h86) & ~cpu_RnW;    // 0x8600 (sound enable)
wire cs_soundcmd   = (cpu_A[15:8] == 8'h87) & ~cpu_RnW;    // 0x8700 (sound command)

//ROM bank select register (0x8300)
reg [3:0] rom_bank = 4'd0;
always_ff @(posedge clk_49m) begin
	if(!reset)
		rom_bank <= 4'd0;
	else if(cen_3m && cs_banksel_wr)
		rom_bank <= cpu_Dout[3:0];
end

//------------------------------------------------------ CPU data input mux ---------------------------------------------------//

// Controls and DIP switch data comes from the sound board via controls_dip input.
// The sound board muxes the correct data based on cs_controls_dip1, cs_dip2,
// cpubrd_A5, and cpubrd_A6 signals.

// I/O registers must be checked first (they're in the 0x8000-0x87FF range)
// Controls/DIP data comes from the sound board via controls_dip
wire [7:0] cpu_Din = cs_palette                              ? palette_D :
                     cs_scroll                               ? scroll_reg :
                     cs_watchdog                             ? 8'hFF :
                     cs_in1          ? {1'b1, ~p1_fire_ext[2], ~p1_fire_ext[1], ~p1_fire_ext[0],
                                        ~p1_joy[3], ~p1_joy[2], ~p1_joy[1], ~p1_joy[0]} :
                     cs_in2          ? {1'b1, ~p2_fire_ext[2], ~p2_fire_ext[1], ~p2_fire_ext[0],
                                        ~p2_joy[3], ~p2_joy[2], ~p2_joy[1], ~p2_joy[0]} :
                     (cs_dsw2 | cs_in0 | cs_dsw1)            ? controls_dip :
                     ~n_cs_workram2                          ? workram2_D :
                     ~n_cs_bankrom                           ? bank_rom_D :
                     ~n_cs_mainrom                           ? mainrom_D :
                     ~n_cs_videoram                          ? videoram_D :
                     8'hFF;

//------------------------------------------------------- Main program ROMs ----------------------------------------------------//

//Main program ROMs (m1.1h through j6.6h, 6x 4KB = 24KB at 0xA000-0xFFFF)
//wire [7:0] rom_m1_D, rom_m2_D, rom_m3_D, rom_m4_D, rom_m5_D, rom_m6_D;
//
wire [7:0] mainrom_D = CPU_Rom_Data;
//wire [7:0] mainrom_D = (cpu_A[15:12] == 4'hA) ? rom_m1_D :
//                       (cpu_A[15:12] == 4'hB) ? rom_m2_D :
//                       (cpu_A[15:12] == 4'hC) ? rom_m3_D :
//                       (cpu_A[15:12] == 4'hD) ? rom_m4_D :
//                       (cpu_A[15:12] == 4'hE) ? rom_m5_D :
//                       (cpu_A[15:12] == 4'hF) ? rom_m6_D :
//                       8'hFF;

//eprom_4k rom_m1 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(rom_m1_D),
//                 .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
//                 .CS_DL(rom_m1_cs_i), .WR(ioctl_wr));
//eprom_4k rom_m2 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(rom_m2_D),
//                 .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
//                 .CS_DL(rom_m2_cs_i), .WR(ioctl_wr));
//eprom_4k rom_m3 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(rom_m3_D),
//                 .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
//                 .CS_DL(rom_m3_cs_i), .WR(ioctl_wr));
//eprom_4k rom_m4 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(rom_m4_D),
//                 .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
//                 .CS_DL(rom_m4_cs_i), .WR(ioctl_wr));
//eprom_4k rom_m5 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(rom_m5_D),
//                 .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
//                 .CS_DL(rom_m5_cs_i), .WR(ioctl_wr));
//eprom_4k rom_m6 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(rom_m6_D),
//                 .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
//                 .CS_DL(rom_m6_cs_i), .WR(ioctl_wr));

//------------------------------------------------------ Banked graphics ROMs --------------------------------------------------//

//Banked graphics ROMs (c1.1i through c9.9i, 9x 4KB)
//Bank select register chooses which 4KB bank is visible at 0x9000-0x9FFF
wire [7:0] bank0_D, bank1_D, bank2_D, bank3_D, bank4_D;
wire [7:0] bank5_D, bank6_D, bank7_D, bank8_D;
wire [7:0] bank_rom_D = GFX_Rom_Data;//todo bank handling
//wire [7:0] bank_rom_D = (rom_bank == 4'd0) ? bank0_D :
//                        (rom_bank == 4'd1) ? bank1_D :
//                        (rom_bank == 4'd2) ? bank2_D :
//                        (rom_bank == 4'd3) ? bank3_D :
//                        (rom_bank == 4'd4) ? bank4_D :
//                        (rom_bank == 4'd5) ? bank5_D :
//                        (rom_bank == 4'd6) ? bank6_D :
//                        (rom_bank == 4'd7) ? bank7_D :
//                        (rom_bank == 4'd8) ? bank8_D :
//                        8'hFF;

eprom_4k bank0 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank0_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank0_cs_i), .WR(ioctl_wr));
eprom_4k bank1 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank1_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank1_cs_i), .WR(ioctl_wr));
eprom_4k bank2 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank2_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank2_cs_i), .WR(ioctl_wr));
eprom_4k bank3 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank3_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank3_cs_i), .WR(ioctl_wr));
eprom_4k bank4 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank4_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank4_cs_i), .WR(ioctl_wr));
eprom_4k bank5 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank5_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank5_cs_i), .WR(ioctl_wr));
eprom_4k bank6 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank6_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank6_cs_i), .WR(ioctl_wr));
eprom_4k bank7 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank7_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank7_cs_i), .WR(ioctl_wr));
eprom_4k bank8 (.ADDR(cpu_A[11:0]), .CLK(clk_49m), .DATA(bank8_D),
                .ADDR_DL(ioctl_addr), .CLK_DL(clk_49m), .DATA_IN(ioctl_data),
                .CS_DL(bank8_cs_i), .WR(ioctl_wr));
					 
//Blitter ToDo		

//blitter blitter_inst
//(
//	.clk(clk_49m),   
//	.rst(reset),
//	.clk_1M5_en(clk_1M5_en_sig) ,	// input  clk_1M5_en_sig
//	.blitter_cs(blitter_cs_sig) ,	// input  blitter_cs_sig
//	.cpu_a(cpu_a_sig) ,	// input [1:0] cpu_a_sig
//	.cpu_d_o(cpu_d_o_sig) ,	// input [7:0] cpu_d_o_sig
//	.cpu_rw(cpu_rw_sig) ,	// input  cpu_rw_sig
//	.cpu_ba(cpu_ba_sig) ,	// input  cpu_ba_sig
//	.cpu_bs(cpu_bs_sig) ,	// input  cpu_bs_sig
//	.vram_cs(vram_cs_sig) ,	// input  vram_cs_sig
//	.blitter_copy(blitter_copy_sig) ,	// input  blitter_copy_sig
//	.blitter_d_o(blitter_d_o_sig) ,	// input [7:0] blitter_d_o_sig
//	.cpu_halt(cpu_halt_sig) ,	// output  cpu_halt_sig
//	.vram_a(vram_a_sig) ,	// output [15:0] vram_a_sig
//	.vram_d_i(vram_d_i_sig) ,	// output [7:0] vram_d_i_sig
//	.vram_wr(vram_wr_sig) 	// output [1:0] vram_wr_sig
//);			 

//------------------------------------------------------------ RAM ------------------------------------------------------------//

// Work RAM at 0x8000-0x87FF does not exist in Tutankham hardware.
// Hiscore support uses the 0x8800-0x8FFF work RAM (workram2) instead.

//Work RAM (0x8800-0x8FFF, 2KB) — the only general-purpose RAM in the I/O region
wire [7:0] workram2_D;
dpram_dc #(.widthad_a(11)) workram2
(
	.clock_a(clk_49m),
	.wren_a(~n_cs_workram2 & ~cpu_RnW),
	.address_a(cpu_A[10:0]),
	.data_a(cpu_Dout),
	.q_a(workram2_D),

	.clock_b(clk_49m),
	.wren_b(hs_write),
	.address_b(hs_address[10:0]),
	.data_b(hs_data_in),
	.q_b(hs_data_out)
);

// Scroll register (0x8100, 1 byte readable/writable)
reg [7:0] scroll_reg = 8'd0;
always_ff @(posedge clk_49m) begin
	if(cen_6m && cs_scroll && ~cpu_RnW)
		scroll_reg <= cpu_Dout;
end

// Palette register file (0x8000-0x800F, 16 entries × 8 bits)
// Uses registers instead of SPRAM so video scanout can read simultaneously with CPU
reg [7:0] palette_regs [0:15];
initial begin
	integer i;
	for (i = 0; i < 16; i = i + 1)
		palette_regs[i] = 8'd0;
end
always_ff @(posedge clk_49m) begin
	if(cs_palette && ~cpu_RnW)
		palette_regs[cpu_A[3:0]] <= cpu_Dout;
end
wire [7:0] palette_D = palette_regs[cpu_A[3:0]];  // CPU read-back path

//Video RAM (0x0000-0x7FFF, 32KB) - dual port: A=CPU, B=video scanout
wire [7:0] videoram_D;
wire [7:0] videoram_vout;
// Apply flip and scroll to VRAM read coordinates (matching MAME screen_update)
wire [7:0] eff_x = pix_x ^ {8{flip_x}};
wire [7:0] scroll_y = (eff_x < 8'd192) ? scroll_reg : 8'd0;
wire [7:0] eff_y = (v_cnt[7:0] ^ {8{flip_y}}) + scroll_y;
wire [14:0] vram_rd_addr = {eff_y, eff_x[7:1]};

dpram_dc #(.widthad_a(15)) videoram
(
	.clock_a(clk_49m),
	.address_a(cpu_A[14:0]),
	.data_a(cpu_Dout),
	.wren_a(~n_cs_videoram & ~cpu_RnW),
	.q_a(videoram_D),

	.clock_b(clk_49m),
	.address_b(vram_rd_addr),
	.q_b(videoram_vout)
);

//--------------------------------------------------------- Main latch ---------------------------------------------------------//

reg irq_enable = 0;
reg flip_x = 0;
reg flip_y = 0;
reg stars_enable = 0;
reg sound_mute = 0;
always_ff @(posedge clk_49m) begin
	if(!reset) begin
		irq_enable <= 0;
		flip_x <= 0;
		flip_y <= 0;
		stars_enable <= 0;
		sound_mute <= 0;
	end
	else if(cen_3m) begin
		if(cs_mainlatch)
			case(cpu_A[2:0])
				3'b000: irq_enable <= cpu_Dout[0];   // LS259 Q0: IRQ enable
				3'b001: ;  // PAY OUT - unused
				3'b010: ;  // Coin counter 2
				3'b011: ;  // Coin counter 1
				3'b100: stars_enable <= cpu_Dout[0];  // Stars enable (LS259 Q4)
				3'b101: sound_mute <= cpu_Dout[0];    // Sound mute (LS259 Q5)
				3'b110: flip_x <= cpu_Dout[0];        // Flip screen X (LS259 Q6)
				3'b111: flip_y <= cpu_Dout[0];        // Flip screen Y (LS259 Q7)
			endcase
	end
end

//Generate VBlank IRQ for MC6809E
// MAME: IRQ fires every other vblank frame when irq_enable is set.
//       IRQ is cleared when irq_enable is written to 0.
// ALL n_irq logic is in this single always_ff to avoid multiple-driver errors.
reg n_irq = 1;
reg irq_toggle = 0;
reg vblank_irq_en_last = 0;
always_ff @(posedge clk_49m) begin
	if(!reset) begin
		n_irq <= 1;
		irq_toggle <= 0;
		vblank_irq_en_last <= 0;
	end
	else if(cen_6m) begin
		vblank_irq_en_last <= vblank_irq_en;
		// Clear IRQ when irq_enable is turned off (matches MAME irq_enable_w)
		if(!irq_enable)
			n_irq <= 1;
		// Detect rising edge of vblank_irq_en pulse from k082
		else if(vblank_irq_en && !vblank_irq_en_last) begin
			irq_toggle <= ~irq_toggle;
			if(!irq_toggle)  // Fire on every other vblank
				n_irq <= 0;
		end
	end
end

//-------------------------------------------------------- Video timing --------------------------------------------------------//

//Konami 082 custom chip - responsible for all video timings
wire vblk, vblank_irq_en, h256;
wire [8:0] h_cnt;
wire [7:0] v_cnt;
k082 F5
(
	.reset(1),
	.clk(clk_49m),
	.cen(cen_6m),
	.h_center(h_center),
	.v_center(v_center),
	.n_vsync(video_vsync),
	.sync(video_csync),
	.n_hsync(video_hsync),
	.vblk(vblk),
	.vblk_irq_en(vblank_irq_en),
	.h1(h_cnt[0]),
	.h2(h_cnt[1]),
	.h4(h_cnt[2]),
	.h8(h_cnt[3]),
	.h16(h_cnt[4]),
	.h32(h_cnt[5]),
	.h64(h_cnt[6]),
	.h128(h_cnt[7]),
	.n_h256(h_cnt[8]),
	.h256(h256),
	.v1(v_cnt[0]),
	.v2(v_cnt[1]),
	.v4(v_cnt[2]),
	.v8(v_cnt[3]),
	.v16(v_cnt[4]),
	.v32(v_cnt[5]),
	.v64(v_cnt[6]),
	.v128(v_cnt[7])
);

//--------------------------------------------------------- Starfield ----------------------------------------------------------//

// MC_STARS expects real clock signals, not narrow clock enables.
// div[2] = ~6.144 MHz square wave (49.152/8), div[1] = ~12.288 MHz (49.152/4)
// These have proper 50% duty cycle, matching Moon Cresta's 6/12 MHz clocks.

wire [1:0] star_r, star_g, star_b;
MC_STARS stars_gen
(
	.I_CLK_12M(div[1]),
	.I_CLK_6M(div[2]),
	.I_H_FLIP(flip_x),
	.I_V_SYNC(~video_vsync),
//	.I_8HF(h_cnt[3] ^ flip_x),
//	.I_256HnX(h256),
	.I_8HF(pix_x[3] ^ flip_x),
	.I_256HnX(1'b1),
//  .I_256HnX(pix_x[7]),
	.I_1VF(v_cnt[0] ^ flip_y),
	.I_2V(v_cnt[1]),
	.I_STARS_ON(stars_enable),
	.I_STARS_OFFn(1'b1),
	.I_PAUSEn(~pause),
	.O_R(star_r),
	.O_G(star_g),
	.O_B(star_b),
	.O_NOISE()
);

//----------------------------------------------------- Final video output -----------------------------------------------------//

//Generate HBlank (active high) while the horizontal counter is between 141 and 268
wire hblk = (h_cnt > 140 && h_cnt < 269);

// Generate a 0-255 pixel X counter synchronized to the visible window
// Visible pixels: h_cnt 269-511 (243 px), then 128-140 (13 px) = 256 total
// Use h_cnt offset so pixel 0 aligns with h_cnt=269
// Visible pixels: h_cnt 269-511 (243 px), then 128-140 (13 px) = 256 total
// Must produce continuous pix_x 0-255 across the wrap at h_cnt 511→128
// h_cnt 269-511: h_cnt[8]=1 (for 269-511), pix_x = h_cnt - 269
// h_cnt 128-140: h_cnt[8]=0, pix_x = h_cnt - 128 + 243 = h_cnt + 115
wire [7:0] pix_x = h_cnt[8] ? (h_cnt[7:0] - 8'd13) : (h_cnt[7:0] + 8'd115);

// Framebuffer pixel extraction: 4-bit packed pixels, 2 per byte
wire [3:0] pixel_index = eff_x[0] ? videoram_vout[7:4] : videoram_vout[3:0];

// Palette lookup — convert 4-bit pixel index to RGB via palette registers
// Palette byte format (Galaxian/Konami standard): BBGGGRRR
//   bits [2:0] = Red   (3 bits, through 1K/470/220 ohm resistors)
//   bits [5:3] = Green (3 bits, through 1K/470/220 ohm resistors)
//   bits [7:6] = Blue  (2 bits, through 470/220 ohm resistors)
wire [7:0] pal_byte = palette_regs[pixel_index];

// Expand to 5-bit per channel for MiSTer output
// Blank output during HBlank and VBlank to prevent ghost pixels
wire active_video = ~hblk & ~vblk;

wire pixel_is_bg = (pixel_index == 4'd0);
wire show_stars = active_video & pixel_is_bg & stars_enable;

assign red   = show_stars  ? {star_r, star_r[1], 2'b00}                    :
               active_video ? {pal_byte[2:0], pal_byte[2:1]}              : 5'd0;
assign green = show_stars  ? {star_g, star_g[1], 2'b00}                    :
               active_video ? {pal_byte[5:3], pal_byte[5:4]}              : 5'd0;
assign blue  = show_stars  ? {star_b, star_b[1], 2'b00}                    :
               active_video ? {pal_byte[7:6], pal_byte[7:6], pal_byte[7]} : 5'd0;

endmodule

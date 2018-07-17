`timescale 1ns / 1ps
`include "atari7800.vh"


module maria(
   // Busses ("tristate")
   input  logic [15:0] AB_in,
   output logic [15:0] AB_out,
   output logic        drive_AB,

   input  logic  [7:0] read_DB_in,
   input  logic  [7:0] write_DB_in,
   output logic  [7:0] DB_out,
   // inout wire [15:0]  AB,
   // inout wire [ 7:0]  DB,
   //inout wire [7:0]   DB,
   //inout wire [15:0]  AB,

   // Clocking
   input logic        reset,
   input logic        sysclk, pclk_2,
   output logic       tia_clk, pclk_0, sel_slow_clock,

   // Memory Map Select lines
   output `chipselect  CS,
   input logic        bios_en,
   input logic        tia_en,
   //output logic       ram0_b, ram1_b, p6532_b, tia_b,
   //output logic       riot_ram_b,

   // Maria configuration
   input logic        RW, enable,

   // VGA Interface
   input logic [9:0]  vga_row, vga_col,
   output logic [7:0] UV_out,

   // Outputs to 6502
   output logic       int_b, halt_b, ready, core_latch_data
);

   // Bus interface
   // Defined as ports.
   //logic        drive_AB;
   //logic [15:0] AB_in, AB_out;
   //logic        drive_DB;
   //logic  [7:0] DB_in, DB_out;
   //assign DB = drive_DB ? DB_out : 'bz;
   //assign AB = drive_AB ? AB_out : 'bz;
   //assign DB_in = DB;
   //assign AB_in = AB;
   
   // For testing DMA. 
   //assign DB_in = DB;
   //assign AB = AB_out;
   //assign AB_in = AB_out;

   //// Memory Mapped Registers
   // Control register format:
   // {CK, DM1, DM0, CW, BC, KM, RM1, RM0}
   // CK: Color Kill
   // {DM1, DM0}: DMA Control. 0: Test A. 1: Test B.
   //                          2: Normal DMA. 3: No DMA.
   // CW: Character Width (For indirect mode). 0=>2bytes. 1=>1byte.
   // BC: Border Control: 0=>Background Color. 1=>Black Border.
   // KM: Kangaroo Mode: 0=>Transparency, 1=>No transparency
   // {RM1, RM0}: Read mode.
   logic [7:0]       ctrl;
   logic [24:0][7:0] color_map;
   logic [7:0]       char_base;
   logic [15:0]      ZP;

   //// Signals from memory_map to timing_ctrl
   logic             deassert_ready, zp_written;

   // Write enables for internal Display List registers
   logic             palette_w, input_w, pixels_w, wm_w;

   //// Control signals between timing_ctrl and dma_ctrl
   logic             zp_dma_start, dp_dma_start;
   logic             zp_dma_done, dp_dma_done;
   // When dp_dma_done is asserted, use this signal to specify
   // whether timing_ctrl needs to raise a display list interrupt
   logic             dp_dma_done_dli;
   // If a DMA is taking too long (too many objects,) kill it
   logic             dp_dma_kill;
   // Next-line ZP DMA not needed at end of DP DMA
   logic             last_line;

   //// Control signals between timing_ctrl and line_ram
   logic             lram_swap;
   
   logic             VBLANK;
   
   line_ram line_ram_inst(
      .SYSCLK(sysclk), .RESET(reset),
      .PLAYBACK(UV_out),
      // Databus inputs
      .INPUT_ADDR(read_DB_in), .PALETTE(read_DB_in[7:5]), .PIXELS(read_DB_in),
      .WM(read_DB_in[7]),
      // Write enable for databus inputs
      .PALETTE_W(palette_w), .INPUT_W(input_w), .PIXELS_W(pixels_w),
      .WM_W(wm_w),
      // Memory mapped registers
      .COLOR_MAP(color_map),
      .READ_MODE(ctrl[1:0]),
      .KANGAROO_MODE(ctrl[2]),
      .BORDER_CONTROL(ctrl[3]),
      .COLOR_KILL(ctrl[7]),
      // Control signals from timing_ctrl
      .LRAM_SWAP(lram_swap),
      .LRAM_OUT_COL(vga_col[9:1])
   );

   timing_ctrl timing_ctrl_inst(
      // Enabled only if men is asserted and display mode is 10
      .enable(enable & ctrl[6] & ~ctrl[5]),
      // Clocking
      .sysclk(sysclk), .reset(reset), .pclk_2(pclk_2),
      .pclk_0(pclk_0), .tia_clk(tia_clk),
      // Signals needed to slow pclk_0
      .sel_slow_clock(sel_slow_clock),
      // Outputs to 6502
      .halt_b(halt_b), .int_b(int_b), .ready(ready), .core_latch_data(core_latch_data),
      .VBLANK(VBLANK),
      // Signals to/from dma_ctrl
      .zp_dma_start(zp_dma_start), .dp_dma_start(dp_dma_start),
      .zp_dma_done(zp_dma_done), .dp_dma_done(dp_dma_done),
      .dp_dma_done_dli(dp_dma_done_dli),
      .dp_dma_kill(dp_dma_kill), .last_line(last_line),
      // Signals to/from line_ram
      .lram_swap(lram_swap),
      // Signals to/from VGA
      .vga_row(vga_row), .vga_col(vga_col),
      // Signals from memory map
      .deassert_ready(deassert_ready),
      .zp_written(zp_written)
   );

   memory_map memory_map_inst(
      .maria_en(enable),
      .tia_en(tia_en),
      .AB(AB_in),
      .DB_in(write_DB_in), .DB_out(DB_out),
      //.drive_DB(drive_DB),
      .halt_b(halt_b), .we_b(RW),
      //.tia_b(tia_b), .p6532_b(p6532_b),
      //.ram0_b(ram0_b), .ram1_b(ram1_b),
      //.riot_ram_b(riot_ram_b),
      .cs(CS), .bios_en(bios_en),
      .drive_AB(drive_AB),
      .ctrl(ctrl),
      .color_map(color_map),
      .status_read({VBLANK, 7'b0}),
      .char_base(char_base),
      .ZP(ZP),
      .sel_slow_clock(sel_slow_clock),
      .deassert_ready(deassert_ready),
      .zp_written(zp_written),
      .sysclock(sysclk), .reset_b(~reset),
      .pclk_0(pclk_0), .pclk_2(pclk_2)
   );

   dma_ctrl dma_ctrl_inst (
      .AddrB(AB_out), .drive_AB(drive_AB),
      .DataB(read_DB_in), .ZP(ZP),
      .palette_w(palette_w), .input_w(input_w), .pixels_w(pixels_w),
      .wm_w(wm_w),
      .zp_dma_start(zp_dma_start), .dp_dma_start(dp_dma_start),
      .dp_dma_kill(dp_dma_kill),
      .zp_dma_done(zp_dma_done), .dp_dma_done(dp_dma_done),
      .dp_dma_done_dli(dp_dma_done_dli),
      .sysclk(sysclk), .reset(reset),
      .last_line(last_line),
      .character_width(ctrl[4]), .char_base(char_base)
   );

endmodule 
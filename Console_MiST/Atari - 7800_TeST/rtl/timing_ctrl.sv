`timescale 1ns / 1ps

// Number of sysclk cycles needed for the halt signal to take on the CPU
`define DMA_STARTUP_CYCLES 9

// Number of sysclk cycles that the cpu gets at the start of a line
`define START_OF_LINE_CYCLES 24

// At which column we terminate DP DMA
`define DP_DMA_KILL_COL 435

// Column to start the ZP DMA, given that about 29 cycles are needed
// and there are 452 columns total. Plus some slack cycles.
// 9 for startup, 7 for access, 13 for shutdown
`define ZP_READY_COL 420

// VGA Row to start the ZP DMA. Rows 0-1 are the first visible line,
// rows 523-524 are the virst invisible line, rows 521-522 are buffering
// for the first invisible line, so ZP needs to be fetched by row 521.
`define ZP_READY_ROW 520

`define VGA_VISIBLE_COLS 640

`define NTSC_SCANLINE_COUNT 242

`define COOLDOWN_CYCLES 1

//`define OVERCLOCK



module timing_ctrl (
   input  logic       enable,

   // Clocking
   input  logic       sysclk, reset, pclk_2,
   output logic       pclk_0, tia_clk,
   input  logic       sel_slow_clock,

   // Outputs to 6502
   output logic       halt_b, int_b, ready, core_latch_data,
   output logic       VBLANK,

   // Signals to/from dma_ctrl
   output logic       zp_dma_start, dp_dma_start,
   input  logic       zp_dma_done, dp_dma_done,
   input  logic       dp_dma_done_dli,
   output logic       dp_dma_kill,
   output logic       last_line,

   // Signals to/from line_ram
   output logic       lram_swap,

   // VGA Status
   input  logic [9:0] vga_row, vga_col,
   
   // Signals from memory map
   input  logic       deassert_ready, zp_written
);

   // Output buffers
   logic [5:0] int_b_sr;
   assign int_b = &int_b_sr;

   // Current NTSC row and col
   logic [8:0]        row, col;

   logic [9:0]        vga_row_prev, vga_row_prev_prev;

   // Each ntsc line is two vga lines. Asserted => we are on second one
   logic              second_vga_line;

   // vga_row has changed in the last cycle
   logic              vga_line_delta;

   // Clock division
   `ifndef OVERCLOCK
   logic              fast_ctr;
   `endif
   
   logic [1:0]        slow_ctr;
   logic              fast_clk, slow_clk;

   logic              ready_for_lswap, ready_for_lswap_prev;

   // Ready to move to ZP_DMA_STARTUP
   logic              zp_ready;

   // interrupt on next cycle
   logic              dli_next, raise_dli;

   logic [4:0]        startup_ctr;
   logic              cooldown_count;

   enum logic [31:0] {
      VWAIT = 'h0,           // Waiting for VSYNC to complete before starting ZP DMA
      HWAIT = 'h1,           // Waiting for HSYNC to complete before starting DP DMA
      ZP_DMA_STARTUP = 'h2,  // Waiting for HALT to reach CPU before starting ZP DMA
      ZP_DMA = 'h3,          // Waiting for DMA CTRL to finish ZP DMA
      START_OF_LINE = 'h4,   // Waiting for first 7 CPU cycles of line before DP DMA
      DP_DMA_STARTUP = 'h5,  // Waiting for HALT to reach CPU before starting DP DMA
      DP_DMA = 'h6,          // Waiting for DMA CTRL to finish DP DMA
      DP_DMA_WAITSWAP = 'h7, // Done with DP DMA, but not ready to swap linerams yet
      VWAIT_COOLDOWN = 'h8,
      HWAIT_COOLDOWN = 'h9
   } state;
   
   assign vga_line_delta = vga_row_prev_prev != vga_row_prev;

   // In general, we are on the second row if the row number is odd (vga_row[0])
   // However, above 512 (521/522, 523/524) we are on the second row if the row
   // number is even.
   assign second_vga_line = vga_row[9] ^ vga_row[0];

   assign dp_dma_kill = ((enable) &
                         (state == DP_DMA) &
                         (second_vga_line) &
                         (col == `DP_DMA_KILL_COL));

   assign zp_ready = ((enable) & (vga_row == `ZP_READY_ROW) &
                      (col == `ZP_READY_COL));

   assign last_line = (row == (`NTSC_SCANLINE_COUNT - 1));
   
   assign VBLANK = (row >= 9'd241);

   assign pclk_0 = sel_slow_clock ? slow_clk : fast_clk;
   
   assign ready_for_lswap = ((enable) & second_vga_line &
                             (vga_col > `VGA_VISIBLE_COLS));
   assign lram_swap = (ready_for_lswap & 
                      (((state == DP_DMA) & (dp_dma_done | dp_dma_kill)) || 
                       (state == DP_DMA_WAITSWAP)));


   always @(posedge sysclk, posedge reset) begin
      if (reset) begin
         state <= VWAIT;
         row <= 9'b0;
         col <= 9'b0;
         vga_row_prev <= 10'd0;
         fast_clk <= 1'b0;
         cooldown_count <= 1'b0;
         slow_clk <= 1'b0;
         `ifndef OVERCLOCK
         fast_ctr <= 1'b0;
         `endif
         slow_ctr <= 2'b0;
         int_b_sr <= 6'b111111;
         raise_dli <= 1'b0;
         startup_ctr <= 4'd0;
         dli_next <= 1'b0;
         halt_b <= 1'b1;
         zp_dma_start <= 1'b0;
         dp_dma_start <= 1'b0;
         core_latch_data <= 1'b0;
         ready_for_lswap_prev <= 1'b0;
         ready <= 1'b1;
         tia_clk <= 1'b0;
      end else begin
         // Clock generation
         tia_clk <= ~tia_clk;
         core_latch_data <= 1'b0;
         if (sel_slow_clock) begin
            `ifndef OVERCLOCK
            fast_ctr <= 1'b0;
            `endif
            
            fast_clk <= 1'b1; 
            if (slow_ctr == 2'd2) begin
                slow_ctr <= 2'b0;
                slow_clk <= ~slow_clk;
                if (slow_clk == 1'b0)
                    core_latch_data <= 1'b1;
            end
            else
                slow_ctr <= slow_ctr + 2'b01;
         end
         else begin
            slow_ctr <= 2'b00;
            slow_clk <= 1'b1;
            `ifdef OVERCLOCK
            fast_clk <= ~fast_clk;
            `else
            fast_ctr <= ~fast_ctr;
            if (fast_ctr) begin
               fast_clk <= ~fast_clk;
               if (fast_clk == 1'b0)
                  core_latch_data <= 1'b1;
            end
            `endif
         end

         // Interrupt generation
         int_b_sr <= {int_b_sr[4:0], ~(dli_next & enable)};
         //int_b_reg <= ~(dli_next & enable);

         vga_row_prev <= vga_row;
         vga_row_prev_prev <= vga_row_prev;
         ready_for_lswap_prev <= ready_for_lswap;

         // Column counting
         if (vga_line_delta & ~second_vga_line) // Just changed to first line
           col <= 0;
         else
           col <= col + 1;

         // Row counting
         if (vga_line_delta & ~second_vga_line) begin
            if (vga_row == 10'd521)
              row <= 0;
            else
              row <= row + 1;
         end

         // Ready signal
         if (enable & deassert_ready)
            ready <= 1'b0;
         else if (ready_for_lswap & ~ready_for_lswap_prev)
            ready <= 1'b1;

         // Next state logic
         case (state)
           VWAIT: begin
              if (zp_ready & zp_written) begin
                 halt_b <= 1'b0;
                 raise_dli <= 1'b0;
                 dli_next <= 1'b0;
                 state <= ZP_DMA_STARTUP;
                 startup_ctr <= 1;
              end
           end
           HWAIT: begin
              if (~enable) begin
                 state <= VWAIT_COOLDOWN;
                 halt_b <= 1'b0;
                 raise_dli <= 1'b0;
                 dli_next <= 1'b0;
                 cooldown_count <= `COOLDOWN_CYCLES;
              end else if (vga_line_delta) begin
                 state <= START_OF_LINE;
                 startup_ctr <= 1;
              end
           end
           ZP_DMA_STARTUP: begin
              startup_ctr <= startup_ctr + 1;
              if (~enable) begin
                 state <= VWAIT_COOLDOWN;
                 raise_dli <= 1'b0;
                 halt_b <= 1'b0;
                 cooldown_count <= `COOLDOWN_CYCLES;
              end else if (startup_ctr == `DMA_STARTUP_CYCLES) begin
                 zp_dma_start <= 1'b1;
                 state <= ZP_DMA;
              end
           end
           ZP_DMA: begin
              zp_dma_start <= 1'b0;
              if (~enable) begin
                 state <= VWAIT_COOLDOWN;
                 raise_dli <= 1'b0;
                 halt_b <= 1'b0;
                 cooldown_count <= `COOLDOWN_CYCLES;
              end else if (zp_dma_done) begin
                 state <= HWAIT_COOLDOWN;
                 raise_dli <= dp_dma_done_dli;
                 raise_dli <= 1'b0;
                 halt_b <= 1'b0;
                 cooldown_count <= `COOLDOWN_CYCLES;
              end
           end
           START_OF_LINE: begin
              startup_ctr <= startup_ctr + 1;
              if (~enable) begin
                 state <= VWAIT_COOLDOWN;
                 raise_dli <= 1'b0;
                 halt_b <= 1'b0;
                 cooldown_count <= `COOLDOWN_CYCLES;
              end else if (startup_ctr == `START_OF_LINE_CYCLES) begin
                 halt_b <= 1'b0;
                 state <= DP_DMA_STARTUP;
                 startup_ctr <= 1;
              end
           end
           DP_DMA_STARTUP: begin
              startup_ctr <= startup_ctr + 1;
              if (~enable) begin
                 state <= VWAIT_COOLDOWN;
                 raise_dli <= 1'b0;
                 halt_b <= 1'b0;
                 cooldown_count <= `COOLDOWN_CYCLES;
              end else if (startup_ctr == `DMA_STARTUP_CYCLES) begin
                 dp_dma_start <= 1'b1;
                 raise_dli <= 1'b0;
                 state <= DP_DMA;
              end
           end
           DP_DMA: begin
              dp_dma_start <= 1'b0;
              if (~enable) begin
                 state <= VWAIT_COOLDOWN;
                 halt_b <= 1'b0;
                 cooldown_count <= `COOLDOWN_CYCLES;
              end else if (dp_dma_done | dp_dma_kill) begin
                 halt_b <= 1'b0;
                 raise_dli <= dp_dma_done_dli;
                 cooldown_count <= `COOLDOWN_CYCLES;
                 if (ready_for_lswap) begin
                    state <= last_line ? VWAIT_COOLDOWN : HWAIT_COOLDOWN;
                 end else begin
                    state <= DP_DMA_WAITSWAP;
                 end
              end
           end
           DP_DMA_WAITSWAP: begin
              if (~enable) begin
                 state <= VWAIT_COOLDOWN;
              end else if (cooldown_count == 0) begin
                 if ((sel_slow_clock && slow_ctr != 2'b10) ||
                     (~sel_slow_clock && fast_clk == 1'b1)) begin
                    halt_b <= 1'b1;
                    raise_dli <= 1'b0;
                    dli_next <= raise_dli;
                 end
              end else begin
                 cooldown_count <= cooldown_count - 1;
              end
              if (ready_for_lswap) begin
                 state <= last_line ? VWAIT_COOLDOWN : HWAIT_COOLDOWN;
              end
           end
           VWAIT_COOLDOWN: begin
              if (cooldown_count == 0) begin
                 if ((sel_slow_clock && slow_ctr != 2'b10) ||
                     (~sel_slow_clock && fast_clk == 1'b1)) begin
                    halt_b <= 1'b1;
                    raise_dli <= 1'b0;
                    dli_next <= raise_dli;
                    state <= VWAIT;
                 end
              end else begin
                 cooldown_count <= cooldown_count - 1;
              end
           end
           HWAIT_COOLDOWN: begin
              if (cooldown_count == 0) begin
                 if ((sel_slow_clock && slow_ctr != 2'b10) ||
                     (~sel_slow_clock && fast_clk == 1'b1)) begin
                    halt_b <= 1'b1;
                    raise_dli <= 1'b0;
                    dli_next <= raise_dli;
                    state <= HWAIT;
                 end
              end else begin
                 cooldown_count <= cooldown_count - 1;
              end
           end
       endcase
    end
  end
endmodule
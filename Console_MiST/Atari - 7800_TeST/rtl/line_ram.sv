`timescale 1ns / 1ps

// Graphics Mode Definitions
`define GM_160A 3'b000
`define GM_160B 3'b100
`define GM_320A 3'b011
`define GM_320B 3'b110
`define GM_320C 3'b111
`define GM_320D 3'b010

module line_ram(
    input  logic SYSCLK, RESET,
    output logic [7:0]  PLAYBACK,
    // Databus inputs
    input  logic [7:0]         INPUT_ADDR,
    input  logic [2:0]         PALETTE,
    input  logic [7:0]         PIXELS,
    input  logic               WM,
    // Write enable for databus inputs
    input  logic PALETTE_W, INPUT_W, PIXELS_W, WM_W,
    // Memory mapped registers
    input  logic [24:0][7:0]   COLOR_MAP,
    input  logic [1:0]         READ_MODE,
    input  logic               KANGAROO_MODE, BORDER_CONTROL,
    input  logic               COLOR_KILL,
    input  logic               LRAM_SWAP,
    // VGA Control signal
    input  logic [8:0]         LRAM_OUT_COL
);

   logic [159:0][4:0]          lram_in, lram_out;
   logic rm_in, rm_out;

   logic [7:0]                 input_addr;
   logic [2:0]                 palette;
   logic                       wm;

   logic [2:0]               display_mode;
   assign display_mode = {wm, READ_MODE};

   logic [2:0]               playback_palette;
   logic [1:0]               playback_color;
   logic [4:0]               playback_cell;
   logic [8:0]               playback_ix;
   logic [7:0]               lram_ix;

   assign playback_ix = (LRAM_OUT_COL < 9'd320) ? LRAM_OUT_COL : 9'd0;

  always_comb begin
      if (playback_color == 2'b0) begin
         PLAYBACK = COLOR_MAP[0];
      end else begin
         PLAYBACK = COLOR_MAP[3 * playback_palette + playback_color];
      end
   end
   
   logic [4:0] cell1, cell2, cell3, cell4;
   logic [4:0] pcell1, pcell2, pcell3, pcell4;
   
   assign cell1 = lram_in[input_addr];
   assign cell2 = lram_in[input_addr+1];
   assign cell3 = lram_in[input_addr+2];
   assign cell4 = lram_in[input_addr+3];

   assign pcell1 = lram_in[input_addr-4];
   assign pcell2 = lram_in[input_addr-3];
   assign pcell3 = lram_in[input_addr-2];
   assign pcell4 = lram_in[input_addr-1];

   // Assign playback_color and playback_palette based on
   // lram_in and playback_ix and display_mode
   always_comb begin
      lram_ix = playback_ix[8:1]; // 2 pixels per lram cell
      playback_cell = lram_out[lram_ix];
      playback_palette = playback_cell[4:2]; // Default to 160A/B
      playback_color = playback_cell[1:0];
      casex (rm_out)
        2'b0x: begin
            // 160A is read as four double-pixels per byte:
            //      <P2 P1 P0> <D7 D6>
            //      <P2 P1 P0> <D5 D4>
            //      <P2 P1 P0> <D3 D2>
            //      <P2 P1 P0> <D1 D0>
            // 160B is read as two double-pixels per byte:
            //      <P2 D3 D2> <D7 D6>
            //      <P2 D1 D0> <D5 D4>
            // In both cases, the lineram cells are stored in
            // exactly the order specified above. They can be
            // read directly.
            playback_palette = playback_cell[4:2];
            playback_color = playback_cell[1:0];
        end
        2'b10: begin
            // 320B is read as four pixels per byte:
            //      <P2  0  0> <D7 D3>
            //      <P2  0  0> <D6 D2>
            //      <P2  0  0> <D5 D1>
            //      <P2  0  0> <D4 D0>
            // 320B is stored as two cells per byte (wm=1):
            //      [P2 D3 D2 D7 D6]
            //      [P2 D1 D0 D5 D4]
            //
            // 320D is read as eight pixels per byte:
            //      <P2  0  0> <D7 P1>
            //      <P2  0  0> <D6 P0>
            //      <P2  0  0> <D5 P1>
            //      <P2  0  0> <D4 P0>
            //      <P2  0  0> <D3 P1>
            //      <P2  0  0> <D2 P0>
            //      <P2  0  0> <D1 P1>
            //      <P2  0  0> <D0 P0>
            // 320D is stored as four cells per byte (wm=0):
            //      [P2 P1 P0 D7 D6]
            //      [P2 P1 P0 D5 D4]
            //      [P2 P1 P0 D3 D2]
            //      [P2 P1 P0 D1 D0]
            //
            // In both cases, the palette is always <cell[4], 0, 0>
            // For a given pair of pixels, the color selectors
            // are, from left to right, <cell[1], cell[3]> and <cell[0], cell[2]>
            // Example: Either D7,D3:D6,D2 (320B) or D7,P1:D6,P0 (320D)
            playback_palette = {playback_cell[4], 2'b0};
            if (playback_ix[0]) begin
                // Right pixel
                playback_color = {playback_cell[0], playback_cell[2]};
            end else begin
                // Left pixel
                playback_color = {playback_cell[1], playback_cell[3]};
            end
        end
        2'b11: begin
            // 320A is read as eight pixels per byte:
            //      <P2 P1 P0> <D7  0>
            //      <P2 P1 P0> <D6  0>
            //      <P2 P1 P0> <D5  0>
            //      <P2 P1 P0> <D4  0>
            //      <P2 P1 P0> <D3  0>
            //      <P2 P1 P0> <D2  0>
            //      <P2 P1 P0> <D1  0>
            //      <P2 P1 P0> <D0  0>
            // 320A is stored as four cells per byte (wm=0):
            //      [P2 P1 P0 D7 D6]
            //      [P2 P1 P0 D5 D4]
            //      [P2 P1 P0 D3 D2]
            //      [P2 P1 P0 D1 D0]
            //
            // 320C is read as four pixels per byte:
            //      <P2 D3 D2> <D7  0>
            //      <P2 D3 D2> <D6  0>
            //      <P2 D1 D0> <D5  0>
            //      <P2 D1 D0> <D4  0>
            // 320C is stored as two cells per byte (wm=1):
            //      [P2 D3 D2 D7 D6]
            //      [P2 D1 D0 D5 D4]
            //
            // In both cases, the palette is always <cell[4], cell[3], cell[2]>
            // For a given pair of pixels, the color selectors
            // are, from left to right, <cell[1], 0> and <cell[0], 0>
            playback_palette = playback_cell[4:2];
            if (playback_ix[0]) begin
                // Right pixel
                playback_color = {playback_cell[0], 1'b0};
            end else begin
                // Left pixel
                playback_color = {playback_cell[1], 1'b0};
            end
        end
      endcase
   end

   always_ff @(posedge SYSCLK, posedge RESET) begin
      if (RESET) begin
         input_addr <= 8'b0;
         palette <= 3'b0;
         wm <= 1'b0;
         lram_in <= 800'd0;
         lram_out <= 800'd0;
      end else begin
         input_addr <= INPUT_W ? INPUT_ADDR : input_addr;
         palette <= PALETTE_W ? PALETTE : palette;
         wm <= WM_W ? WM : wm;
         if (LRAM_SWAP) begin
            lram_in <= 800'd0; // All background color
            lram_out <= lram_in;
            rm_out <= rm_in;
         end
         if (PIXELS_W) begin
            // Load PIXELS byte into lram_in
            rm_in <= READ_MODE;
            case (wm)
            1'b0: begin
                // "When wm = 0, each byte specifies four pixel cells
                //  of the lineram"
                // This encompasses:
                // 160A:
                //      [P2 P1 P0 D7 D6]
                //      [P2 P1 P0 D5 D4]
                //      [P2 P1 P0 D3 D2]
                //      [P2 P1 P0 D1 D0]
                // 320A:
                //      [P2 P1 P0 D7  0]
                //      [P2 P1 P0 D6  0]
                //      [P2 P1 P0 D5  0]
                //      [P2 P1 P0 D4  0]
                //      [P2 P1 P0 D3  0]
                //      [P2 P1 P0 D2  0]
                //      [P2 P1 P0 D1  0]
                //      [P2 P1 P0 D0  0]
                // 320D:
                //      [P2  0  0 D7 P1]
                //      [P2  0  0 D6 P0]
                //      [P2  0  0 D5 P1]
                //      [P2  0  0 D4 P0]
                //      [P2  0  0 D3 P1]
                //      [P2  0  0 D2 P0]
                //      [P2  0  0 D1 P1]
                //      [P2  0  0 D0 P0]
                // These can all be written into the cells using
                // the same format and read out differently.
                input_addr <= input_addr + 4;
                if (|PIXELS[7:6])
                    lram_in[input_addr+0] <= {palette, PIXELS[7:6]};
                if (|PIXELS[5:4])
                    lram_in[input_addr+1] <= {palette, PIXELS[5:4]};
                if (|PIXELS[3:2])
                    lram_in[input_addr+2] <= {palette, PIXELS[3:2]};
                if (|PIXELS[1:0])
                    lram_in[input_addr+3] <= {palette, PIXELS[1:0]};
            end
            1'b1: begin
                // "When wm = 1, each byte specifies two cells within the lineram."
                // This encompasses:
                // 160B:
                //      [P2 D3 D2 D7 D6]
                //      [P2 D1 D0 D5 D4]
                // 320B:
                //      [P2  0  0 D7 D3]
                //      [P2  0  0 D6 D2]
                //      [P2  0  0 D5 D1]
                //      [P2  0  0 D4 D0]
                // 320C:
                //      [P2 D3 D2 D7  0]
                //      [P2 D3 D2 D6  0]
                //      [P2 D1 D0 D5  0]
                //      [P2 D1 D0 D4  0]
                // Again, these can be written into the cells in
                // the same format and read out differently. Note:
                // transparency may not be correct in 320B mode here
                // since the color bits are different than 160B and 320C.
                input_addr <= input_addr + 2;
                if (|PIXELS[7:6])
                    lram_in[input_addr+0] <= {palette[2], PIXELS[3:2], PIXELS[7:6]};
                if (|PIXELS[5:4])
                    lram_in[input_addr+1] <= {palette[2], PIXELS[1:0], PIXELS[5:4]};
            end
            endcase
         end
      end
   end

endmodule

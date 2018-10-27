`timescale 1ns / 1ps

`include "atari7800.vh"

module memory_map (
   input  logic             maria_en,
   input  logic             tia_en,
   input  logic [15:0]      AB,
   input  logic [7:0]       DB_in,
   output logic [7:0]       DB_out,
   input  logic             halt_b, we_b,
   
   output `chipselect       cs,
   input  logic             bios_en,
   input  logic             drive_AB,
   
   output logic [7:0]       ctrl,
   output logic [24:0][7:0] color_map,
   input  logic [7:0]       status_read,
   output logic [7:0]       char_base,
   output logic [15:0]      ZP,

   // whether to slow pclk_0 for slow memory accesses
   output logic             sel_slow_clock,

   // when wait_sync is written to, ready is deasserted
   output logic             deassert_ready, zp_written,

   input logic              sysclock, reset_b, pclk_0, pclk_2
);

   logic [3:0]              signals_out;
   
   // Internal Memory Mapped Registers
   logic [7:0]              ZPH, ZPL;
   logic [7:0]              wait_sync;
   
   logic [7:0]              read_addr_found, write_addr_found;
   
   (* KEEP = "true" *)
   logic [7:0] ctrl_kept;

   assign sel_slow_clock = (drive_AB) ? 1'b0 : ((tia_en) ? 1'b1 : ((cs == `CS_TIA) || (cs == `CS_RIOT_IO) || (cs == `CS_RIOT_RAM)));   

   assign ZP = {ZPH, ZPL};
   logic [1:0] zp_byte_written;
   
   assign zp_written = &zp_byte_written;

   always_comb begin
      // Generate Chip Select (cs) Signal
      cs = `CS_CART;
      
      if (~tia_en) casex (AB)
            // RIOT RAM: "Do Not Use" in 7800 mode.
            16'b0000_010x_1xxx_xxxx: cs = `CS_RIOT_RAM;
            16'b0000_0010_1xxx_xxxx: cs = `CS_RIOT_IO;
            
            // 1800-1FFF: 2K RAM.
            16'b0001_1xxx_xxxx_xxxx: cs = `CS_RAM1;
            
            // 0040-00FF: Zero Page (Local variable space)
            // 0140-01FF: Stack
            16'b0000_000x_01xx_xxxx,
            16'b0000_000x_1xxx_xxxx,
            
            // 2000-27FF: 2K RAM. Zero Page and Stack mirrored from here.
            16'b001x_xxxx_xxxx_xxxx: cs = `CS_RAM0;

            // TIA Registers:
            // 0000-001F, 0100-001F, 0200-021F, 0300-031F
            // All mirrors are ranges of the same registers
            16'b0000_00xx_000x_xxxx: cs = `CS_TIA;
            
            // MARIA Registers:
            // 0020-003F, 0120-003F, 0220-023F, 0320-033F
            // All ranges are mirrors of the same registers
            16'b0000_00xx_001x_xxxx: cs = `CS_MARIA;
            
      endcase else casex (AB)
            16'bxxx0_xx0x_1xxx_xxxx: cs = `CS_RIOT_RAM;
            16'bxxx0_xx1x_1xxx_xxxx: cs = `CS_RIOT_IO;
            16'bxxx0_xxxx_0xxx_xxxx: cs = `CS_TIA;
      endcase
      
      if (bios_en & AB[15])
         cs = `CS_BIOS; 
      
      // If MARIA is selected, handle memory mapped registers
      if (cs == `CS_MARIA) begin
        if (we_b) begin
            read_addr_found = AB[7:0];
            write_addr_found = 8'h0;
        end
        else begin 
            write_addr_found = AB[7:0];
            read_addr_found = 8'h0;
        end
      end else begin
         read_addr_found = 8'h0;
         write_addr_found = 8'h0;
      end

      /*
      //Find write addresses on bus to latch data on next tick
      casex ({AB, we_b})
        {16'b0000_00xx_001x_xxxx,1'b0}: wr_addr_found = AB[7:0];
        default: wr_addr_found = 8'b0;
      endcase
      
      casex ({AB, we_b})
        {16'b0000_00xx_001x_xxxx,1'b1}: read_addr_found = AB[7:0];
        default: read_addr_found = 8'b0;
      endcase
      */
      
      
   end // always_comb

   always_ff @(posedge pclk_0, negedge reset_b) begin
      if (~reset_b) begin
         ctrl <= {1'b0, 2'b10, 1'b0, 1'b0, 1'b0, 2'b00}; // 8'b0
         ctrl_kept <= 8'b0;
         //color_map <= 200'b0;
         //////// TESTING COLOR MAP /////////
         // Background
         color_map[0] <= 8'h0c;
         // Palette 0
         color_map[3:1] <= {8'h32, 8'h55, 8'h55};
         // Palette 1
         color_map[6:4] <= {8'h83, 8'h55, 8'h55};
         // Palette 2
         color_map[9:7] <= {8'h1c, 8'h55, 8'h55};
         // Palette 3
         color_map[12:10] <= {8'h25, 8'h55, 8'h55};
         // Palette 4
         color_map[15:13] <= {8'hda, 8'h55, 8'h55};
         
         color_map[24:16] <= 'b0;
                  
         wait_sync <= 8'b0;
         char_base <= 8'b0;
         {ZPH,ZPL} <= {8'h18, 8'h20};
         zp_byte_written <= 2'b0;
      end
      
      else begin
         ctrl_kept <= ctrl;
         deassert_ready <= 1'b0;
         //Handle writes to mem mapped regs
         case(write_addr_found)
           8'h20: color_map[0] <= DB_in;
           8'h21: color_map[1] <= DB_in;
           8'h22: color_map[2] <= DB_in;
           8'h23: color_map[3] <= DB_in;
           8'h24: begin
              wait_sync <= DB_in;
              deassert_ready <= 1'b1;
           end
           8'h25: color_map[4] <= DB_in;
           8'h26: color_map[5] <= DB_in;
           8'h27: color_map[6] <= DB_in;
           //8'h28: status_read <= DB_in; Read only
           8'h29: color_map[7] <= DB_in;
           8'h2a: color_map[8] <= DB_in;
           8'h2b: color_map[9] <= DB_in;
           8'h2c: begin
              ZPH <= DB_in;
              zp_byte_written[1] <= 1'b1;
           end
           8'h2d: color_map[10] <= DB_in;
           8'h2e: color_map[11] <= DB_in;
           8'h2f: color_map[12] <= DB_in;
           8'h30: begin
              ZPL <= DB_in;
              zp_byte_written[0] <= 1'b1;
           end
           8'h31: color_map[13] <= DB_in;
           8'h32: color_map[14] <= DB_in;
           8'h33: color_map[15] <= DB_in;
           8'h34: char_base <= DB_in;
           8'h35: color_map[16] <= DB_in;
           8'h36: color_map[17] <= DB_in;
           8'h37: color_map[18] <= DB_in;
           //8'h38: NOT USED
           8'h39: color_map[19] <= DB_in;
           8'h3a: color_map[20] <= DB_in;
           8'h3b: color_map[21] <= DB_in;
           8'h3c: ctrl <= DB_in;
           8'h3d: color_map[22] <= DB_in;
           8'h3e: color_map[23] <= DB_in;
           8'h3f: color_map[24] <= DB_in;
           default: ;
         endcase // case (wr_addr_found)
         
         case(read_addr_found)
            8'h20: DB_out <= color_map[0];
            8'h21: DB_out <= color_map[1];
            8'h22: DB_out <= color_map[2];
            8'h23: DB_out <= color_map[3];
            8'h25: DB_out <= color_map[4];
            8'h26: DB_out <= color_map[5];
            8'h27: DB_out <= color_map[6];
            8'h28: DB_out <= status_read;
            8'h29: DB_out <= color_map[7];
            8'h2a: DB_out <= color_map[8];
            8'h2b: DB_out <= color_map[9];
            8'h2c: DB_out <= ZPH;
            8'h2d: DB_out <= color_map[10];
            8'h2e: DB_out <= color_map[11];
            8'h2f: DB_out <= color_map[12];
            8'h30: DB_out <= ZPL;
            8'h31: DB_out <= color_map[13];
            8'h32: DB_out <= color_map[14];
            8'h33: DB_out <= color_map[15];
            8'h34: DB_out <= char_base;
            8'h35: DB_out <= color_map[16];
            8'h36: DB_out <= color_map[17];
            8'h37: DB_out <= color_map[18];
            //8'h38: NOT USED
            8'h39: DB_out <= color_map[19];
            8'h3a: DB_out <= color_map[20];
            8'h3b: DB_out <= color_map[21];
            8'h3c: DB_out <= ctrl;
            8'h3d: DB_out <= color_map[22];
            8'h3e: DB_out <= color_map[23];
            8'h3f: DB_out <= color_map[24];
            default: DB_out <= 8'hbe;
          endcase // case (wr_addr_found)
      end // else: !if(~reset_b)
   end // always_ff @
endmodule

module er_decode(
  input [15:0] cpu_addr,
  output reg sram_cs,
  output reg vram_cs,
  output reg cram_cs,
  output reg rom_cs,
  output reg ds0_read,
  output reg ds1_read,
  output reg in1_read,
  output reg in2_read,
  output reg nmi_clear,
  output reg snd_write,
  output reg flp_write,
  output reg dma_swap,
  output reg bg_sel,
  output reg pdat_read,
  output reg psta_read,
  output reg pdat_write,
  output reg scx_write,
  output reg scy_write
);

always @* begin

  sram_cs    = 0;
  vram_cs    = 0;
  cram_cs    = 0;
  rom_cs     = 0;
  ds0_read   = 0;
  ds1_read   = 0;
  in1_read   = 0;
  in2_read   = 0;
  nmi_clear  = 0;
  snd_write  = 0;
  flp_write  = 0;
  dma_swap   = 0;
  bg_sel     = 0;
  pdat_read  = 0;
  psta_read  = 0;
  pdat_write = 0;
  scx_write  = 0;
  scy_write  = 0;

  case (cpu_addr[15:14])
    0: begin
      case (cpu_addr[13:12])
        0: begin
          case (cpu_addr[11:9])
            3: sram_cs = 1;
            4, 5: vram_cs = 1;
            6, 7: cram_cs = 1;
          endcase
        end
        1: begin
          case (cpu_addr[1:0])
            0: ds0_read = 1;
            1: in1_read = 1;
            2: in2_read = 1;
            3: ds1_read = 1;
          endcase
        end
        2: begin
          if (~cpu_addr[11]) begin
            case (cpu_addr[1:0])
              0: nmi_clear = 1;
              1: snd_write = 1;
              2: flp_write = 1;
              3: dma_swap  = 1;
            endcase
          end
          else begin
            if (~cpu_addr[2]) bg_sel = 1;
            case (cpu_addr[2:0])
              0: pdat_read = 1;
              1: psta_read = 1;
              4: scy_write = 1;
              5, 6: scx_write = 1;
              7: pdat_write = 1;
            endcase
          end
        end
      endcase
    end
    1, 2, 3: rom_cs = 1;
  endcase

end

endmodule

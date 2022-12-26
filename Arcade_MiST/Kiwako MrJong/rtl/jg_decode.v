
// I/O is not fully decoded yet
//
// CPU writes the following bits on port 0:
// ....xx.x = ?
// ......x. = horizontal flip
//
// Port 3: ???
//

module jg_decode(
  input [15:0] cpu_ab,
  input cpu_io,
  input cpu_m1,
  input cpu_wr,

  output reg rom_cs,
  output reg ram1_cs,
  output reg ram2_cs,
  output reg vram_cs,
  output reg cram_cs,
  output reg p1_cs,
  output reg p2_cs,
  output reg dsw_cs,
  output reg flip_wr,
  output reg sn1_wr,
  output reg sn2_wr
);

//reg unmap;

always @* begin
//  unmap = 1'b0;

  rom_cs   = 0;
  ram1_cs  = 0;
  ram2_cs  = 0;
  vram_cs  = 0;
  cram_cs  = 0;
  p1_cs    = 0;
  p2_cs    = 0;
  dsw_cs   = 0;
  flip_wr  = 0;
  sn1_wr   = 0;
  sn2_wr   = 0;

  if (cpu_io) begin
    case (cpu_ab[7:0])
      8'd0:
        if (cpu_wr)
          flip_wr = 1'b1;
        else
          p2_cs  = 1'b1;
      8'd1:
        if (cpu_wr)
          sn1_wr = 1'b1;
        else
          p1_cs  = 1'b1;
      8'd2:
        if (cpu_wr)
          sn2_wr = 1'b1;
        else
          dsw_cs = 1'b1;
      8'd3: /* ?? */;
      default: ;//unmap = 1'b1;
    endcase
  end
  else begin
    if (~cpu_ab[15]) begin
      rom_cs = 1'b1;
    end
    else begin
      case (cpu_ab[15:11])
        5'b10000: ram1_cs = 1'b1;
        5'b10100: ram2_cs = 1'b1;
        5'b11100:
          if (cpu_ab[10]) begin // $E400-$E7FF
            cram_cs = 1'b1;
          end
          else begin // $E000-$E3FF
            vram_cs = 1'b1;
          end
        default: ;//unmap = 1'b1;
      endcase
    end
  end

end


endmodule

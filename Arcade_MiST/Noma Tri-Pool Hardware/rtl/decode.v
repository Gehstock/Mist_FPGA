
module decode(
  input [15:0] mcpu_ab,
  input [15:0] scpu_ab,
  input        scpu_io_en,

  output reg mcpu_rom1_en,
  output reg mcpu_rom2_en,
  output reg mcpu_ram_en,
  output reg mcpu_spram_en,
  output reg mcpu_sndlatch_en,
  output reg mcpu_dsw1_en,
  output reg mcpu_dsw2_en,
  output reg mcpu_in0_en,
  output reg mcpu_in1_en,
  output reg mcpu_in2_en,
  output reg mcpu_in3_en,
  output reg mcpu_flip_en,
  output reg mcpu_pal_en,
  output reg mcpu_vram_en,
  output reg mcpu_cram_en,
  output reg scpu_rom_en,
  output reg scpu_ram_en,
  output reg scpu_ay_data_en,
  output reg scpu_ay_addr_en

);

always @* begin

  mcpu_rom1_en     = 1'b0;
  mcpu_rom2_en     = 1'b0;
  mcpu_ram_en      = 1'b0;
  mcpu_spram_en    = 1'b0;
  mcpu_sndlatch_en = 1'b0;
  mcpu_dsw1_en     = 1'b0;
  mcpu_dsw2_en     = 1'b0;
  mcpu_in0_en      = 1'b0;
  mcpu_in1_en      = 1'b0;
  mcpu_in2_en      = 1'b0;
  mcpu_in3_en      = 1'b0;
  mcpu_flip_en     = 1'b0;
  mcpu_pal_en      = 1'b0;
  mcpu_vram_en     = 1'b0;
  mcpu_cram_en     = 1'b0;
  scpu_rom_en      = 1'b0;
  scpu_ram_en      = 1'b0;
  scpu_ay_data_en  = 1'b0;
  scpu_ay_addr_en  = 1'b0;

  if (mcpu_ab < 16'h4000) begin
    mcpu_rom1_en = 1'b1;
  end else if (mcpu_ab >= 16'h4000 && mcpu_ab < 16'h6000) begin
    mcpu_ram_en = 1'b1;
  end else if (mcpu_ab >= 16'hb000 && mcpu_ab < 16'hb080) begin
    mcpu_spram_en = 1'b1;
  end else if (mcpu_ab == 16'hb400) begin
    mcpu_sndlatch_en = 1'b1;
  end else if (mcpu_ab == 16'hb500) begin
    mcpu_dsw1_en = 1'b1;
  end else if (mcpu_ab == 16'hb501) begin
    mcpu_dsw2_en = 1'b1;
  end else if (mcpu_ab == 16'hb502) begin
    mcpu_in0_en = 1'b1;
  end else if (mcpu_ab == 16'hb503) begin
    mcpu_in1_en = 1'b1;
  end else if (mcpu_ab == 16'hb504) begin
    mcpu_in2_en = 1'b1;
  end else if (mcpu_ab == 16'hb505) begin
    mcpu_in3_en = 1'b1;
  end else if (mcpu_ab >= 16'hb506 && mcpu_ab < 16'hb508) begin
    mcpu_flip_en = 1'b1;
  end else if (mcpu_ab >= 16'hb600 && mcpu_ab < 16'hb620) begin
    mcpu_pal_en = 1'b1;
  end else if (mcpu_ab >= 16'hb800 && mcpu_ab < 16'hbc00) begin
    mcpu_vram_en = 1'b1;
  end else if (mcpu_ab >= 16'hbc00 && mcpu_ab < 16'hc000) begin
    mcpu_cram_en = 1'b1;
  end else if (mcpu_ab >= 16'hc000) begin
    mcpu_rom2_en = 1'b1;
  end

  if (scpu_io_en) begin
    if (scpu_ab[7:0] == 8'h40) begin
      scpu_ay_data_en = 1'b1;
    end else if (scpu_ab[7:0] == 8'h80) begin
      scpu_ay_addr_en = 1'b1;
    end
  end
  else begin
    if (scpu_ab < 16'h2000) begin
      scpu_rom_en = 1'b1;
    end else if (scpu_ab >= 16'h4000 && scpu_ab < 16'h6000) begin
      scpu_ram_en = 1'b1;
    end
  end

end


endmodule

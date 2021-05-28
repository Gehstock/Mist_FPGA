
module rom (
  input clk,
  input [15:0] addr,
  output reg [7:0] dout,
  input cs,
  input rom_init,
  input rom_init_clk,
  input [15:0] rom_init_address,
  input [7:0] rom_init_data
);

reg [7:0] memory[65535:0];

always @(posedge clk)
  if (~cs) dout <= memory[addr];

always @(posedge rom_init_clk)
  if (rom_init)
    memory[rom_init_address] <= rom_init_data;

endmodule

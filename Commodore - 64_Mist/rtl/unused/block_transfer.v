// memory block transfer routine
// L.C.Ashmore feb17
//
// PRG T64 CRT TAP files load to intermediate buffer 0x200000 (2m)
//
// this routine reads 1st 16bytes to determine file type then either:
// 1, if CRT or TAP move to 0x100000 (1m) and sets cartridge or tap attached flags
// 2, if PRG or T64 moves directly into c64 memory map (injection)
// T64 format pain in the arse so only basic function !!

module block_transfer 
(
input clk32,
input [31:0] addr_total_size,
input sdram_we,
input sdram_data_out,
output cart_attached,
output reg [24:0] sdram_read_addr,
output reg [24:0] sdram_write_addr,
inout reg [7:0] sdram_data
);

localparam buffer_address2m      = 'h200000;
localparam buffer_address1m      = 'h100000;

reg [24:0] block_addr;
//reg [24:0] sdram_read_addr;
//reg [24:0] sdram_write_addr;
//reg [7:0] sdram_data;
reg transfer_active;
reg read_flag;

always @(negedge clk32)
	begin
		if (sdram_we == 1 && transfer_active && !read_flag)										//sdram in read cycle - not yet read
			begin	
				sdram_read_addr <= block_addr + buffer_address2m;
				sdram_data <= sdram_data_out;
				read_flag = 1;
			end	
		if (sdram_we == 0 && read_flag)
			begin
				sdram_write_addr <= block_addr +buffer_address1m;
			end	
	end
endmodule

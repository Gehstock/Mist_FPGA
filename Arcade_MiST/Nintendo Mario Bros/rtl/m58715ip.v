//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// M58715 module.
// The M58715 chip produces the digital sounds (music and most
// of the sound effects). It is an 8039 with embedded RAM and ROM.
// The embedded ROM appears to only be used for protection.
// see mario_roms.v for more information.
//----------------------------------------------------------------------------

module M58715IP(
	input  			I_CLK,
	input  			I_CLK_EN,
	input  			I_RSTn,
	input  			I_INTn,
	input  			I_EA,
	output 			O_PSENn,
	output 			O_RDn,
	output 			O_WRn,
	output 			O_ALE,
	output 			O_PROGn,
	input  			I_T0,
	output 			O_T0,
	input  			I_T1,
	input  [7:0]	I_DB,
	output [7:0]	O_DB,
	input  [7:0]	I_P1,
	output [7:0]	O_P1,
	input  [7:0]	I_P2,
	output [7:0]	O_P2
);



wire   W_PSENn;
assign O_PSENn = W_PSENn ;

//----------------------------------
// M58715 has 128-Byte internal RAM
//----------------------------------

wire   [7:0]t48_ram_a;
wire   t48_ram_we;
wire   [7:0]t48_ram_do;
wire   [7:0]t48_ram_di;

ram_128_8 t48_ram
(
   .I_CLK(I_CLK),
   .I_ADDR(t48_ram_a[6:0]),
   .I_D(t48_ram_di),
   .I_CE(1'b1),
   .I_WE(t48_ram_we),
   .O_D(t48_ram_do)
);

//-----------------------------------
// M58715 has 2KB internal ROM
// 
// * Using the 8039 hack to bypass 
//   the internal ROM until the pmem
//   interface can be made to work.
//   All ROM accesses are external.
//------------------------------------

//wire  [10:0]t48_int_rom_a;
//wire   [7:0]t48_int_rom_do;
//
//SUB_INT_ROM bootrom
//(
//   .CLK(I_CLK), 
//   .AD(t48_int_rom_a), 
//   .DO(t48_int_rom_do)
//);

//----------
// T48 Core
//----------

wire   xtal3_s;

t48_core t48_core
(
   .xtal_i(I_CLK),
	.xtal_en_i(I_CLK_EN),
   .reset_i(I_RSTn),
   .t0_i(I_T0),
   .t0_o(O_T0),
   .t0_dir_o(),
   .int_n_i(I_INTn),
   //.ea_i(I_EA),
   .ea_i(1'b1), // 8039 hack
   .rd_n_o(O_RDn),
   .psen_n_o(W_PSENn),
   .wr_n_o(O_WRn),
   .ale_o(O_ALE),
   .db_i(I_DB),
   .db_o(O_DB),
   .db_dir_o(),
   .t1_i(I_T1),
   .p2_i(I_P2),
   .p2_o(O_P2),
   .p2_low_imp_o(),
   .p1_i(I_P1),
   .p1_o(O_P1),
   .p1_low_imp_o(),
   .prog_n_o(O_PROGn),
   .clk_i(I_CLK),
   .en_clk_i(xtal3_s),
   .xtal3_o(xtal3_s),
   .dmem_addr_o(t48_ram_a),
   .dmem_we_o(t48_ram_we),
   .dmem_data_i(t48_ram_do),
   .dmem_data_o(t48_ram_di),
   .pmem_addr_o(),
   .pmem_data_i(8'h00)
);

endmodule









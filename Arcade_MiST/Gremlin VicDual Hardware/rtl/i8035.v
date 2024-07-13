`timescale 1 ps / 1 ps

module i8035(
	input	clk,
	input	ce,
	input	I_RSTn,
	input	I_INTn,
	input	I_EA,
	output	O_PSENn,
	output	O_RDn,
	output	O_WRn,
	output	O_ALE,
	output	O_PROGn,
	input	I_T0,
	output	O_T0,
	input	I_T1,
	input	[7:0]	I_DB,
	output	[7:0]	O_DB,
	input	[7:0]	I_P1,
	output	[7:0]	O_P1,
	input	[7:0]	I_P2,
	output	[7:0]	O_P2
);


//   64 Byte RAM  ------------------------------------------
wire [7:0]	t48_ram_a;
wire		t48_ram_we;
wire [7:0]	t48_ram_do;
wire [7:0]	t48_ram_di;

spram #(6,8) ram 
(
	.clock(clk),
	.address(t48_ram_a[5:0]),
	.wren(t48_ram_we),
	.data(t48_ram_di),
	.q(t48_ram_do)
);

//----------------------------------------------------------

wire   xtal3_s;

t48_core t48_core(
	.clk_i(clk),
	.xtal_i(clk),
	.reset_i(I_RSTn),
	.en_clk_i(xtal3_s),
	.xtal_en_i(ce),
	.t0_i(I_T0),
	.t0_o(O_T0),
	.t0_dir_o(),
	.int_n_i(I_INTn),
	.ea_i(I_EA),
	.rd_n_o(O_RDn),
	.psen_n_o(O_PSENn),
	.wr_n_o(O_WRn),
	.ale_o(O_ALE),
	.db_i(I_DB),
	.db_o(O_DB),
	.db_dir_o(),
	.t1_i(I_T1),
	.p2_i(I_P2),
	.p2_o(O_P2),
	.p2l_low_imp_o(),
	.p2h_low_imp_o(),
	.p1_i(I_P1),
	.p1_o(O_P1),
	.p1_low_imp_o(),
	.prog_n_o(O_PROGn),
	.xtal3_o(xtal3_s),
	.dmem_addr_o(t48_ram_a),
	.dmem_we_o(t48_ram_we),
	.dmem_data_i(t48_ram_do),
	.dmem_data_o(t48_ram_di),
	.pmem_addr_o(),
	.pmem_data_i(8'h00)
);

endmodule
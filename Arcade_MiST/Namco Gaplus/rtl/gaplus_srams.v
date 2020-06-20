/**********************************************
   Share memory module for "FPGA Gaplus"

				Copyright (c) 2007,2019 MiSTer-X
***********************************************/
module gaplus_sharemem
(
	input         clk,
	input			  vclk,

	input         sel,

	input  [15:0] ad0,
	output  [7:0] rd0,
	input   [7:0] wd0,
	input         we0,

	input  [15:0] ad1,
	output  [7:0] rd1,
	input   [7:0] wd1,
	input         we1,

	input   [9:0] vram_a,
	output [15:0] vram_d,

	input   [6:0] spra_a,
	output [23:0] spra_d
);

wire  [6:0] dum;
wire [15:0] ad;
wire  [7:0] wd;
wire        we;

gaplus_busdriver arb( 1'b1,
	sel,
	{ 7'h0, ad0[15:0], wd0[7:0], we0 },
	{ 7'h0, ad1[15:0], wd1[7:0], we1 },
	{  dum,  ad[15:0],  wd[7:0], we  }
);

wire	[7:0] o3I, o3J, o3M, o3K, o3L;

wire	e3I = ( ad[15:10] == 6'b000000 );
wire	e3J = ( ad[15:10] == 6'b000001 );
wire	e3M = ( ad[15:11] == 5'b00001  );
wire	e3K = ( ad[15:11] == 5'b00010  );
wire	e3L = ( ad[15:11] == 5'b00011  );

wire [7:0] rd = e3I ? o3I :
					 e3J ? o3J :
					 e3M ? o3M :
					 e3K ? o3K :
					 e3L ? o3L :
					 8'hFF;

//DPRAM_1024V sram3I( clk, ad[9:0],  wd, o3I, we & e3I, vclk, vram_a, vram_d[7:0]  );
dpram #(10,8) sram3I(
	.clk_a_i(clk),
	.en_a_i(1),
	.we_i(we & e3I),
	.addr_a_i(ad[9:0]),
	.data_a_i(wd),
	.data_a_o(o3I),
	.clk_b_i(vclk),
	.addr_b_i(vram_a),
	.data_b_o(vram_d[7:0])
);

//DPRAM_1024V sram3J( clk, ad[9:0],  wd, o3J, we & e3J, vclk, vram_a, vram_d[15:8] );
dpram #(10,8) sram3J(
	.clk_a_i(clk),
	.en_a_i(1),
	.we_i(we & e3J),
	.addr_a_i(ad[9:0]),
	.data_a_i(wd),
	.data_a_o(o3J),
	.clk_b_i(vclk),
	.addr_b_i(vram_a),
	.data_b_o(vram_d[15:8])
);

//DPRAM_2048V sram3M( clk, ad[10:0], wd, o3M, we & e3M, vclk, { 4'b1111, spra_a }, spra_d[7:0]   );
dpram #(11,8) sram3M(
	.clk_a_i(clk),
	.en_a_i(1),
	.we_i(we & e3M),
	.addr_a_i(ad[10:0]),
	.data_a_i(wd),
	.data_a_o(o3M),
	.clk_b_i(vclk),
	.addr_b_i({ 4'b1111, spra_a }),
	.data_b_o(spra_d[7:0])
);
//DPRAM_2048V sram3K( clk, ad[10:0], wd, o3K, we & e3K, vclk, { 4'b1111, spra_a }, spra_d[15:8]  );
dpram #(11,8) sram3K(
	.clk_a_i(clk),
	.en_a_i(1),
	.we_i(we & e3K),
	.addr_a_i(ad[10:0]),
	.data_a_i(wd),
	.data_a_o(o3K),
	.clk_b_i(vclk),
	.addr_b_i({ 4'b1111, spra_a }),
	.data_b_o(spra_d[15:8])
);
//DPRAM_2048V sram3L( clk, ad[10:0], wd, o3L, we & e3L, vclk, { 4'b1111, spra_a }, spra_d[23:16] );
dpram #(11,8) sram3L(
	.clk_a_i(clk),
	.en_a_i(1),
	.we_i(we & e3L),
	.addr_a_i(ad[10:0]),
	.data_a_i(wd),
	.data_a_o(o3L),
	.clk_b_i(vclk),
	.addr_b_i({ 4'b1111, spra_a }),
	.data_b_o(spra_d[23:16])
);

assign rd0 = rd;
assign rd1 = rd;

endmodule


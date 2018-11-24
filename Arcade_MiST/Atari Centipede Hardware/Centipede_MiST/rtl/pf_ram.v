module pf_ram(
		  input 	clk_a,
		  input 	clk_b,
		  input 	reset,
		  input [7:0] 	addr_a,
		  input [7:0] 	din_a,
		  output [7:0] 	dout_a,
		  input [3:0] 	ce_a,
		  input [3:0] 	we_a,
		  input [7:0] 	addr_b,
		  output [31:0] dout_b,
		  input [3:0] 	ce_b
);

   assign dout_a =
	     ~ce_a[3] ? d_a3 :
	     ~ce_a[2] ? d_a2 :
	     ~ce_a[1] ? d_a1 :
	     ~ce_a[0] ? d_a0 :
		  8'b0;
		  
	assign dout_b = { d_b3, d_b2, d_b1, d_b0 };	
wire [7:0] 	d_a0, d_a1, d_a2, d_a3;		
wire [7:0] 	d_b0, d_b1, d_b2, d_b3;

dpram #(
	.addr_width_g(8),
	.data_width_g(8))
ram0(
	.clk_a_i(clk_a & ~ce_a[0]),
	.we_i(~we_a[0]),
	.addr_a_i(addr_a),	
	.data_a_i(din_a),
	.data_a_o(d_a0),
	.clk_b_i(clk_b & ~ce_b[0]),
	.addr_b_i(addr_b),
	.data_b_o(d_b0)
	);
	
dpram #(
	.addr_width_g(8),
	.data_width_g(8))
ram1(
	.clk_a_i(clk_a & ~ce_a[1]),
	.we_i(~we_a[1]),
	.addr_a_i(addr_a),	
	.data_a_i(din_a),
	.data_a_o(d_a1),
	.clk_b_i(clk_b & ~ce_b[1]),
	.addr_b_i(addr_b),
	.data_b_o(d_b1)
	);

dpram #(
	.addr_width_g(8),
	.data_width_g(8))
ram2(
	.clk_a_i(clk_a & ~ce_a[2]),
	.we_i(~we_a[2]),
	.addr_a_i(addr_a),	
	.data_a_i(din_a),
	.data_a_o(d_a2),
	.clk_b_i(clk_b & ~ce_b[2]),
	.addr_b_i(addr_b),
	.data_b_o(d_b2)
	);

dpram #(
	.addr_width_g(8),
	.data_width_g(8))
ram3(
	.clk_a_i(clk_a & ~ce_a[3]),
	.we_i(~we_a[3]),
	.addr_a_i(addr_a),	
	.data_a_i(din_a),
	.data_a_o(d_a3),
	.clk_b_i(clk_b & ~ce_b[3]),
	.addr_b_i(addr_b),
	.data_b_o(d_b3)
	);	

endmodule 
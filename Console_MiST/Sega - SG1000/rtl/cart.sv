module cart(
input					clk_cpu,
	input 			DSRAM_n,
	input 			EXM1_n,
	input 			RD_n,
	input 			WR_n,
	input				RFSH_n,
	input				MREQ_n,
	output			CON,
	input 			EXM2_n,
	input 			M1_n,
	input   [14:0]	Cart_Addr,
	input		[7:0]	Cart_In,
	input		[7:0]	Cart_Ram_In,
	output	[7:0]	Cart_Ram_Out,
	output	[7:0]	Cart_Rom_Out,
	input 			Cart_We
);
/*
wire [5:0]bank0;
wire [5:0]bank1;
wire [5:0]bank2;

always @(clk_cpu, WR_n) begin
	if (~WR_n & Cart_Addr[14:2] == "1111111111111")
		case (Cart_Addr[1:0])
			2'b01 : bank0 = Cart_In[5:0];
			2'b10 : bank1 = Cart_In[5:0];
			2'b11 : bank2 = Cart_In[5:0];
			default : ;
		endcase;
end*/

spram #(
	.init_file("/roms/[BIOS]OthelloMultivision.hex"),
	.widthad_a(14),//16k for test
	.width_a(8))
ROM (
	.address(Cart_Addr),
	.clock(clk_cpu),
	.data(Cart_In),
	.wren(~WR_n),
	.q(Cart_Rom_Out)
	);
/*	
	spram #(
	.init_file(""),
	.widthad_a(11),//2k for test
	.width_a(8))
RAM (
	.address(Cart_Addr),
	.clock(clk_cpu),
	.data(Cart_Ram_In),
	.wren(~WR_n),
	.q(Cart_Ram_Out)
	);*/
	
endmodule 
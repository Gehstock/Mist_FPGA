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
	input   [14:0]	Addr,
	output	[7:0]	Cart_Out,
	output	[7:0]	Cart_Ram_Out,
	input 	[7:0]	Cart_In
);

wire [5:0]bank0;
wire [5:0]bank1;
wire [5:0]bank2;

always @(clk_cpu) begin
	if (~WR_n & Addr[14:2] == "1111111111111")
		case (Addr[1:0])
			2'b01 : bank0 = Cart_In[5:0];
			2'b10 : bank1 = Cart_In[5:0];
			2'b11 : bank2 = Cart_In[5:0];
			default : ;
		endcase;
end

endmodule 
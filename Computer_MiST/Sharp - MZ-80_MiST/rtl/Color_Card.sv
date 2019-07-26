module Color_Card(
input     CLK,
input     CSX_n,
input     WR_n,
input     CSD_n,
input     Sync,
input     RD_n,
input     Video,
input     [7:0] Din,
input     [7:0] Dout,
input     [9:0]  Addr,
output    CSDo,
output    Synco_n,
output    [1:0] R,
output    [1:0] G,
output    [1:0] B
);

assign Synco_n = ~Sync;
assign CSDo = CSX_n & CSD_n;

assign R = {Bout[7] & Video & ~Video, Bout[1] & Video};
assign G = {Bout[6] & Video & ~Video, Bout[2] & Video};
assign B = {Bout[5] & Video & ~Video, Bout[3] & Video};

wire [7:0] Bin, Bout;
	
LS245 LS245(
	.DIR(~RD_n),
   .OE(CSX_n),
   .Ai(Din),
   .Bi(Bin),
	.Ao(Dout),
   .Bo(Bout)
    );
	
spram #(
	.addr_width_g(10),
	.data_width_g(4))
IC1 (
	.clk_i(CLK),
	.we_i(~CSX_n | ~WR_n),
	.addr_i(Addr),
	.data_i({Bout[0],Bout[1],Bout[2],Bout[3]}),
	.data_o({Bin[0],Bin[1],Bin[2],Bin[3]}),
	);
	
spram #(
	.addr_width_g(10),
	.data_width_g(4))
IC3 (
	.clk_i(CLK),
	.we_i(~CSX_n | ~WR_n),
	.addr_i(Addr),
	.data_i({Bout[4],Bout[5],Bout[6],Bout[7]}),
	.data_o({Bin[4],Bin[5],Bin[6],Bin[7]}),
	);	



endmodule 
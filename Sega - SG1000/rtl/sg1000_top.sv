module sg1000_top(
input				RESET_n,
input				sys_clk,
input				clk_vdp,
input				pause,
input 	[7:0]	Cart_In,
output 	[7:0]	Cart_Out,
output  [14:0]	Cart_Addr,
output 			x,
output 		 	y,
output 			vblank, 
output 			hblank,
output 	[7:0] color,
input 	[7:0]	Joy_A,
input 	[7:0]	Joy_B
);

wire WAIT_n, MREQ_n, M1_n, IORQ_n, RFSH_n, INT_n;
wire NMI_n = pause;//go to M1_n and generate CS_PSG_n
wire RD_n, WR_n;
wire [7:0]D_in, D_out, RAM_D_out;
wire [15:0]Addr;

T80se #(
	.Mode(0),
	.T2Write(0),
	.IOWait(1))
CPU (
	.RESET_n(RESET_n),
	.CLK_n(sys_clk),
	.CLKEN(1'b1),
	.WAIT_n(1'b1),
	.INT_n(INT_n),
	.NMI_n(NMI_n),
	.BUSRQ_n(),//?
	.M1_n(M1_n),
	.MREQ_n(MREQ_n),
	.IORQ_n(IORQ_n),
	.RD_n(RD_n),
	.WR_n(WR_n),
	.RFSH_n(RFSH_n),
	.HALT_n(WAIT_n),
	.BUSAK_n(),
	.A(Addr),
	.DI(D_in),
	.DO(D_out)
	);
	
spram #(
	.widthad_a(10),
	.width_a(8))
MRAM (
	.address(Addr[9:0]),
	.clock(sys_clk),
	.data(D_out),
	.wren(WR_n),
	.q(RAM_D_out)
	);
	
assign Cart_Addr = Addr[14:0];	
	
spram #(
	.widthad_a(15),
	.width_a(8))
CART (
	.address(Cart_Addr),
	.clock(sys_clk),
	.data(Cart_In),
	.wren(WR_n),
	.q(Cart_Out)
	);	

wire [5:0]audio;

psg PSG (
	.clk(sys_clk),
	.WR_n(WR_n),
	.D_in(D_out),
	.outputs(audio)
	);
	
wire [7:0]vdp_D_out;


vdp vdp (
	.cpu_clk(sys_clk),
	.vdp_clk(clk_vdp),
	.RD_n(VDP_RD_n),
	.WR_n(VDP_WR_n),
	.IRQ_n(IORQ_n),
	.A(Addr[7:0]),
	.D_in(D_out),
	.D_out(vdp_D_out),
	.x(x),
	.y(y),
	.vblank(vblank),
	.hblank(hblank),
	.color(color)
	);

	
wire CS_WRAM_n = (~MREQ_n & Addr[15:14] == "11") ? 1'b0 : 1'b1;
wire EXM1_n = (~MREQ_n & Addr[15:14] == "10") ? 1'b0 : 1'b1;
wire EXM2_n = (~MREQ_n | Addr[15]) ? 1'b0 : 1'b1;
wire CS_PSG_n = (~IORQ_n & Addr[7:6] == "01") ? 1'b0 : 1'b1;

wire VDP_RD_n = (~IORQ_n & Addr[7:6] == "10") | RD_n ? 1'b0 : 1'b1;
wire VDP_WR_n = (~IORQ_n & Addr[7:6] == "10") | WR_n ? 1'b0 : 1'b1;
wire JOY_SEL_n = (~IORQ_n & Addr[7:6] == "11") | RD_n ? 1'b0 : 1'b1;
wire KB_SEL_n = (~IORQ_n & Addr[7:6] == "11") ? 1'b0 : 1'b1;

assign D_in = 	~CS_WRAM_n ? RAM_D_out :
					~VDP_RD_n ? vdp_D_out  :
					"00000000";	

endmodule 
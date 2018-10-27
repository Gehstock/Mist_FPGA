module sg1000_top(
input				RESET_n,
input				sys_clk,//8
input				clk_vdp,//16
input				pause,
input 	[7:0]	Cart_Out,
output 	[7:0]	Cart_In,
output  [14:0]	Cart_Addr,
output 	[5:0] audio,
output 			vblank, 
output 			hblank,
output 			vga_hs,
output 			vga_vs,
output 	[1:0]	vga_r,
output 	[1:0]	vga_g,
output 	[1:0]	vga_b,
input 	[7:0]	Joy_A,
input 	[7:0]	Joy_B
);

wire WAIT_n, MREQ_n, M1_n, IORQ_n, RFSH_n, INT_n;
wire NMI_n = pause;
wire RD_n, WR_n;
wire [7:0]D_in, D_out, RAM_D_out;
wire [7:0]Cart_ram_Out = 8'h00000000; 
wire [7:0]Joy_Out = 8'h00000000; 
wire [7:0]Kb_Out = 8'h00000000;
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
	.widthad_a(11),//2k
	.width_a(8))
MRAM (
	.address(Addr[10:0]),
	.clock(sys_clk),
	.data(D_out),
	.wren(~WR_n),
	.q(RAM_D_out)
	);
	
assign Cart_Addr = Addr[14:0];	
/*wire 	[7:0]	Cart_Out, Cart_In;
wire [14:0] Cart_Addr = Addr[14:0];	

sprom #(
	.init_file("roms/32.hex"),
	.widthad_a(15),
	.width_a(8))
CART (
	.address(Cart_Addr),
	.clock(sys_clk),
	.q(Cart_Out)
	);	*/

psg PSG (
	.clk(sys_clk),
	.WR_n(WR_n),
	.D_in((CS_PSG_n == 1'b0) ? D_out : 8'b00000000),
	.outputs(audio)
	);
	
wire [7:0]vdp_D_out;
wire [8:0]x;
wire [7:0]y;
wire [5:0] color;

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
	
vga_video vga_video (
	.clk16(clk_vdp),
	.x(x),
	.y(y),
	.vblank(vblank),
	.hblank(hblank),
	.color(color),
	.hsync(vga_hs),
	.vsync(vga_vs),
	.red(vga_r),
	.green(vga_g),
	.blue(vga_b)
	);


	
wire CS_WRAM_n = (~MREQ_n & Addr[15:14] == "11") ? 1'b0 : 1'b1;
wire EXM1_n = (~MREQ_n & Addr[15:14] == "10") ? 1'b0 : 1'b1;
wire EXM2_n = (~MREQ_n | Addr[15]) ? 1'b0 : 1'b1;
wire CS_PSG_n = (~IORQ_n & Addr[7:6] == "01") ? 1'b0 : 1'b1;

wire VDP_RD_n = (~IORQ_n & Addr[7:6] == "10") | RD_n ? 1'b0 : 1'b1;
wire VDP_WR_n = (~IORQ_n & Addr[7:6] == "10") | WR_n ? 1'b0 : 1'b1;
wire JOY_SEL_n = (~IORQ_n & Addr[7:6] == "11") | RD_n ? 1'b0 : 1'b1;
wire KB_SEL_n = (~IORQ_n & Addr[7:6] == "11") ? 1'b0 : 1'b1;

always @(sys_clk) begin

		D_in <= 	(CS_WRAM_n == 1'b0) ? RAM_D_out :
					(VDP_RD_n == 1'b0) ? vdp_D_out  :
					(EXM1_n == 1'b0) ? Cart_Out  :
					(EXM2_n == 1'b0) ? Cart_ram_Out  :
					(JOY_SEL_n == 1'b0) ? Joy_Out  :
					(KB_SEL_n == 1'b0) ? Kb_Out  :
					8'b00000000;	
end
endmodule 



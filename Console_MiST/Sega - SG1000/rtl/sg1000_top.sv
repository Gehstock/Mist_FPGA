module sg1000_top(
input				RESET_n,
input				sys_clk,//8
input				vdp_clk,//16
input				vid_clk,//64
input				pal,
input				pause,
input  			ps2_kbd_clk,
input  			ps2_kbd_data,
input 	[7:0]	Cart_In,
output  [14:0]	Cart_Addr,
output 			Cart_We, 
output 	[5:0] audio,
output 			vblank, 
output 			hblank,
output 			vga_hs,
output 			vga_vs,
output 	[1:0]	vga_r,
output 	[1:0]	vga_g,
output 	[1:0]	vga_b,
output 	[1:0]	rgb_r,
output 	[1:0]	rgb_g,
output 	[1:0]	rgb_b,
output 			csync,
input 	[5:0]	Joy_A,
input 	[5:0]	Joy_B
);

wire DSRAM_n = CS_WRAM_n;
wire CS_WRAM_n = (~MREQ_n) & (Addr[15:14] == "11") ? 1'b0 : 1'b1;
wire M1_n;
wire MREQ_n;
wire IORQ_n;
wire RD_n;
wire WR_n;
wire RFSH_n;
wire WAIT_n; 
wire INT_n;
wire NMI_n = pause;//todo
wire [15:0]Addr;
wire [7:0]D_in; 
wire [7:0]D_out;



T80se #(
	.Mode(0),
	.T2Write(0),
	.IOWait(1))
CPU (
	.RESET_n(RESET_n),
	.CLK_n(sys_clk),
	.CLKEN(1'b1),
	.INT_n(INT_n),
	.NMI_n(NMI_n),
	.BUSRQ_n(1'b1),
	.M1_n(M1_n),
	.MREQ_n(MREQ_n),
	.IORQ_n(IORQ_n),
	.RD_n(RD_n),
	.WR_n(WR_n),
	.RFSH_n(RFSH_n),
	.HALT_n(WAIT_n),
	.A(Addr),
	.DI(D_in),
	.DO(D_out)
	);
	
wire	[7:0]RAM_D_out;

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
	
wire CS_PSG_n = (~IORQ_n) & (Addr[7:6] == "01") ? 1'b0 : 1'b1;
psg PSG (
	.clk(sys_clk),
	.CS_n(CS_PSG_n),
	.WR_n(WR_n),
	.D_in(D_out),
	.outputs(audio)
	);
	
wire [7:0]vdp_D_out;
wire [8:0]x;
wire [7:0]y;
wire [5:0] color;
wire VDP_RD_n = (~IORQ_n) & (Addr[7:6] == "10") | RD_n ? 1'b0 : 1'b1;
wire VDP_WR_n = (~IORQ_n) & (Addr[7:6] == "10") | WR_n ? 1'b0 : 1'b1;

vdp vdp (
	.cpu_clk(sys_clk),
	.vdp_clk(vdp_clk),
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
	.clk16(vdp_clk),
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
	/*
tv_video tv_video (
	.clk8(sys_clk),
	.clk64(vid_clk),
	.pal(pal),
	.x(x),
	.y(y),
	.vblank(vblank),
	.hblank(hblank),
	.csync(csync),
	.color(color),
	.video({rgb_b,rgb_g,rgb_r})
	);*/

	
wire [7:0]Joy_Out;
wire JOY_SEL_n = (~IORQ_n) & (Addr[7:6] == "11") | RD_n ? 1'b0 : 1'b1;
wire CON;
TTL74_257 IC18(
	.GN(JOY_SEL_n),
	.SEL(Addr[0]),
	.B4(Joy_B[5]),
	.A4(Joy_A[2]),
	.B3(Joy_B[4]),
	.A3(Joy_A[3]),
	.B2(Joy_B[3]),
	.A2(Joy_A[5]),
	.B1(Joy_B[2]),
	.A1(Joy_A[4]),
	.Y4(Joy_Out[3]),
	.Y3(Joy_Out[2]),
	.Y2(Joy_Out[1]),
	.Y1(Joy_Out[0])
);
	
TTL74_257 IC21(
	.GN(JOY_SEL_n),
	.SEL(Addr[0]),
	.B4(),
	.A4(Joy_B[1]),
	.B3(),
	.A3(Joy_B[0]),
	.B2(),
	.A2(Joy_A[0]),
	.B1(CON),
	.A1(Joy_A[1]),
	.Y4(Joy_Out[7]),
	.Y3(Joy_Out[6]),
	.Y2(Joy_Out[5]),
	.Y1(Joy_Out[4])
);

wire KB_SEL_n = (~IORQ_n) & (Addr[7:6] == "11") ? 1'b0 : 1'b1;
wire [7:0]Kb_Out;

keyboard keyboard(
	.Addr(Addr[2:0]),
	.JOY_SEL_n(JOY_SEL_n),
	.KB_SEL_n(KB_SEL_n),
	.Kb_Out(Kb_Out),
	.RD_n(RD_n),
	.WR_n(WR_n),
	.CON(CON),
	.IORQ_n(IORQ_n),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data)
);

wire EXM1_n = (~MREQ_n) & (Addr[15:14] == "10") ? 1'b0 : 1'b1;
wire EXM2_n = (~MREQ_n) | (Addr[15]) ? 1'b0 : 1'b1;
wire [7:0]Cart_Rom_Out, Cart_Ram_Out; 

cart cart(
	.DSRAM_n(DSRAM_n),
	.EXM1_n(EXM1_n),
	.RD_n(RD_n),
	.WR_n(WR_n),
	.RFSH_n(RFSH_n),
	.MREQ_n(MREQ_n),
	.CON(CON),
	.EXM2_n(EXM2_n),
	.M1_n,
	.Cart_Addr(Addr[14:0]),
	.Cart_Rom_Out(Cart_Rom_Out),
	.Cart_Ram_Out(Cart_Ram_Out),
	.Cart_In(Cart_In),
	.Cart_We(Cart_We)
);

//todo
always @(sys_clk) begin
		D_in = 	~CS_WRAM_n ? RAM_D_out :
					~VDP_RD_n ? vdp_D_out  :
					~EXM1_n ? Cart_Rom_Out  :
					~EXM2_n ? Cart_Ram_Out  :
					~JOY_SEL_n ? Joy_Out  :
					~KB_SEL_n ? Kb_Out  :
					1'hz;	
end

endmodule 



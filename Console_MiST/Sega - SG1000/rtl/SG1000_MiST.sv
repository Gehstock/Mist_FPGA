module SG1000_MiST(
	input				CLOCK_27,
	output			LED,
	output			VGA_HS,
	output			VGA_VS,
	output [5:0]	VGA_R,
	output [5:0]	VGA_G,
	output [5:0]	VGA_B,
	inout          SPI_DO,
	input          SPI_DI,
	input          SPI_SCK,
	input          SPI_SS2,
	input          SPI_SS3,
	input          SPI_SS4,
	input          CONF_DATA0,
	output			AUDIO_L,
	output			AUDIO_R
);

assign LED = ~ioctl_download;
`include "build_id.v"
localparam CONF_STR = 
{
	"SG1000;BINSG ;",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O5,Pause,Off,On;",
	"T6,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire [1:0] buttons, switches;
wire [31:0] status;
wire ypbpr;
wire scandoubler_disable;
wire ps2_kbd_data, ps2_kbd_clk;
wire 			ioctl_ce;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire [1:0] r, g, b;
wire hb, vb, hs, vs;
wire blankn = ~(hb | vb);
wire [5:0] audio;
wire  [7:0] joystick_0, joystick_1;
wire clk_8, clk_16, clk_64;

pll pll (
	.inclk0(CLOCK_27),
	.c0(clk_64),
	.c1(clk_16),
	.c2(clk_8)
	);

mist_io #(
	.STRLEN($size(CONF_STR)>>3)) 
user_io (
	.clk_sys(clk_64),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SCK(SPI_SCK),
	.SPI_DI(SPI_DI),
	.SPI_DO(SPI_DO),
	.SPI_SS2(SPI_SS2),	
	.conf_str(CONF_STR),
	.ypbpr(ypbpr),
	.status(status),
	.scandoubler_disable(scandoubler_disable),
	.buttons(buttons),
	.switches(switches),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick_0(joystick_0[5:0]),
	.joystick_1(joystick_1[5:0]),
	.ioctl_ce(1'b1),
	.ioctl_wr(ioctl_wr),
	.ioctl_index(ioctl_index),
	.ioctl_download(ioctl_download),	
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout)
	);
	
video_mixer #(
	.LINE_LENGTH(480), 
	.HALF_DEPTH(0)) 
video_mixer (
	.clk_sys			( clk_64			),
	.ce_pix			( clk_16			),
	.ce_pix_actual	( clk_16			),
	.SPI_SCK			( SPI_SCK		),
	.SPI_SS3			( SPI_SS3		),
	.SPI_DI			( SPI_DI			),
	.R					(blankn ? {r,r,r} : "000000" ),
	.G					(blankn ? {g,g,g} : "000000" ),
	.B					(blankn ? {b,b,b} : "000000" ),
	.HSync			( hs				),
	.VSync			( vs	   		),
	.VGA_R			( VGA_R			),
	.VGA_G			( VGA_G			),
	.VGA_B			( VGA_B			),
	.VGA_VS			( VGA_VS			),
	.VGA_HS			( VGA_HS			),
	.scanlines		(scandoubler_disable ? 2'b00 : {status[3:2] == 3, status[3:2] == 2}),
	.scandoubler_disable(1'b1),//scandoubler_disable),
	.hq2x				(status[3:2]==1),
	.ypbpr			( ypbpr			),
	.ypbpr_full		( 1				),
	.line_start		( 0				),
	.mono				( 0				)
	);


sg1000_top sg1000_top (
	.RESET_n(~(status[0] | status[6] | buttons[1])),
	.sys_clk(clk_8),
	.clk_vdp(clk_16),
	.pause(status[5]),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	//.Cart_In(Cart_In),
	//.Cart_Out(Cart_Out),
	//.Cart_Addr(Cart_Addr),
	.audio(audio),
	.vblank(vb), 
	.hblank(hb),
	.vga_hs(hs),
	.vga_vs(vs),
	.vga_r(r),
	.vga_g(g),
	.vga_b(b),
	.Joy_A(),
	.Joy_B()
);

wire 	[7:0]	Cart_Out;
wire 	[7:0]	Cart_In;
wire [14:0] Cart_Addr;

spram #(
	.init_file("roms/32.hex"),//Test
	.widthad_a(15),
	.width_a(8))
CART (
	.address(ioctl_download ? ioctl_addr[14:0] : Cart_Addr),
	.clock(clk_64),
	.data(ioctl_dout),
	.wren(ioctl_wr),
	.q(Cart_Out)
	);	

dac #(
	.msbi_g(5))
dac (
	.clk_i(clk_64),
	.res_i(1'b0),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
	
assign AUDIO_R = AUDIO_L;	

endmodule 
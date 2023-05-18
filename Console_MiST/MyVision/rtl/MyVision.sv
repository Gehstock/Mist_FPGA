module MyVision(
	output        LED,						
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        AUDIO_L,
	output        AUDIO_R,	
	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         CONF_DATA0,
	input         CLOCK_27	
);

`include "rtl\build_id.v"

localparam CONF_STR = {
	"MYVISION;bin;",
	"O1,Joystick Swap,On,Off;",
//	"O2,Joystick Control,Upright,Normal;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
//	"O5,Service,On,Off;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire clk_sys, clk_3m58, pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),//42.954545
	.c1(clk_3m58),//3.579545
	.locked(pll_locked)
);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [31:0] joystick_0;
wire  [31:0] joystick_1;
wire        scandoublerD;
wire [1:0] scanlines = status[4:3];
wire [9:0] audio;
wire hsync,vsync;
assign LED = ~ioctl_downl;
wire blankn = ~(hb | vb);
wire hb, vb, hs, vs;
wire [7:0] r,b,g;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;
wire			key_extended;

mist_video #(
	.COLOR_DEPTH(6),
	.SD_HCNT_WIDTH(10)) 
mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r[7:2] : 0),
	.G(blankn ? g[7:2] : 0),
	.B(blankn ? b[7:2] : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b0),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ypbpr(ypbpr)
	);

user_io #(
	.STRLEN($size(CONF_STR)>>3))
user_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.key_extended	 (key_extended	  ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(16) dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({audio,6'd0}),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

wire [14:0] ram_a;
wire        ram_we_n, ram_ce_n;
wire  [7:0] ram_di;
wire  [7:0] ram_do;

spram #(15, 8) ram//32k system uses only max 24k
(
	.clock(clk_sys),
	.address(ioctl_downl ? ioctl_addr[14:0] : ram_a),
	.wren(ioctl_wr | ~ram_we_n),
	.data(ioctl_downl ? ioctl_dout : ram_do),
	.q(ram_di)
);

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_sys     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire reset = status[0] | buttons[1] | ioctl_downl;

MyVision_top console(
	.clk_3m58(clk_3m58),
	.clk_sys(clk_sys),
	.reset(reset),	
	.audio(audio),	
	////////////// CPU RAM Interface //////////////
	.cpu_ram_a_o(ram_a),
	.cpu_ram_ce_n_o(ram_ce_n),
	.cpu_ram_we_n_o(ram_we_n),
	.cpu_ram_d_i(ram_di),
	.cpu_ram_d_o(ram_do),
	.joy0(joystick_0),
	.joy1(joystick_1),
	.ps2_key({key_strobe,key_pressed,key_extended,key_code}),
	.HBlank(hb),
	.HSync(hs),
	.VBlank(vb),
	.VSync(vs),
	.ce_pix(),
	.rgb_r_o(r),
	.rgb_g_o(g),
	.rgb_b_o(b)
);

endmodule 
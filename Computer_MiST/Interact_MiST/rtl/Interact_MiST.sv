module Interact_MiST(
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
	"Interact;CINK7;",
	"T8,Play;",
	"T9,Stop & Rewind;",

	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O7,Test Pattern,Off,On;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};


wire [1:0] scanlines = status[4:3];
wire           blend = status[5];
assign 		LED = ~tape_playing;
assign 		AUDIO_R = AUDIO_L;

wire clk_cas, clk_sys, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_cas),//57.272727 MHz
	.c1(clk_sys),//14.318181 MHz	14.38180
	.locked(pll_locked)
	);
	
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire [15:0] joystick_analog_0;
wire [15:0] joystick_analog_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [15:0] audio;
wire 			hsn, vsn;
wire 			hbn, vbn;
wire 			blankn = hbn | vbn;
wire [7:0] 	r, g, b;
wire 			key_strobe;
wire 			key_pressed;
wire 			key_extended;
wire  [7:0] key_code;
wire 			tape_playing;

Interact_top Interact_top(
	.clk_cas(clk_cas),
	.clk_sys(clk_sys),
	.reset(status[0] | buttons[1]),
	.ps2_key({key_strobe,key_pressed,key_extended,key_code}),
	.joystick_0(joystick_0[15:0]),
	.joystick_1(joystick_1[15:0]),
	.joystick_analog_0(joystick_analog_0),
	.joystick_analog_1(joystick_analog_1),
	.hblank_n(hbn),
	.vblank_n(vbn),
	.hsync_n(hsn),
	.vsync_n(vsn),
	.R(r),
	.G(g),
	.B(b),
	.audio(audio),
	.test_sw(status[7]),
	.tape_play(status[8]),
	.tape_rewind(status[9]),
	.ioctl_data(ioctl_dout),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr[14:0]),
	.ioctl_download(ioctl_downl),
	.tape_playing(tape_playing)
);

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io data_io(
	.clk_sys       ( clk_cas      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   ),
	.ioctl_din     ( ioctl_din    )
);


mist_video #(.COLOR_DEPTH(6), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_cas          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r[7:2]           ),
	.G              ( g[7:2]  		  	  ),
	.B              ( b[7:2]        	  ),
	.HSync          ( hsn              ),
	.VSync          ( vsn              ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);
	
user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clk_cas        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_extended	 (key_extended	  ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.joystick_analog_0(joystick_analog_0),
	.joystick_analog_1(joystick_analog_1),
	.status         (status         )
	);

dac #(.C_bits(16))dac_l(
	.clk_i(clk_cas),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);
	

endmodule 
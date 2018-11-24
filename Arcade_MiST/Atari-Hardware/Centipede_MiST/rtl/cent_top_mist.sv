module cent_top_mist(
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
	"Centipede;;",
//	"T1,Add Coin       (ESC);",
//	"T2,Player 1 Start (1);",
//	"T3,Player 2 Start (2);",
//	"O1,Test,off,on;",
//	"O2,Cocktail,off,on;",
//	"O3,Slam,off,on;",
	"O45,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};



wire 	clk24, clk12, clk6, clk1p5;
	
	pll pll(
	.inclk0(CLOCK_27),
	.c0(clk24),
	.c1(clk12),
	.c2(clk6),
	.c3(clk1p5)
	);
	
	reg 	[3:0]	reset_reg;	
	initial reset_reg = 4'b1111;
	
   always @ (posedge clk24)
     reset_reg <= {reset_reg[2:0],1'b0};
	  
	assign LED = 1'b1;
	wire [31:0] status;
	wire  [1:0] buttons;
	wire  [1:0] switches;
	wire        scandoubler_disable;
	wire        ypbpr;
	wire        ps2_kbd_clk, ps2_kbd_data;
	wire 	[7:0] kb_joy, joystick_0, joystick_1;
		
mist_io #(
	.STRLEN(($size(CONF_STR)>>3))) 
mist_io(
	.clk_sys        		(clk24         				),
	.conf_str       		(CONF_STR       				),
	.SPI_SCK        		(SPI_SCK        				),
	.CONF_DATA0     		(CONF_DATA0     				),
	.SPI_SS2			 		(SPI_SS2        				),
	.SPI_DO         		(SPI_DO         				),
	.SPI_DI         		(SPI_DI         				),
	.buttons        		(buttons        				),
	.joystick_0				(joystick_0						),
	.joystick_1				(joystick_1						),
	.switches   	 		(switches       				),
	.scandoubler_disable	(scandoubler_disable			),
	.ypbpr          		(ypbpr          				),
	.ps2_kbd_clk    		(ps2_kbd_clk    				),
	.ps2_kbd_data   		(ps2_kbd_data   				),
	.status         		(status         				)
	);
	
keyboard keyboard(
	.clk(clk24),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kb_joy)
	);

	wire 			hs, vs;
   wire 			hb, vb;
   wire 	[2:0] r, g, b;

video_mixer #(
	.LINE_LENGTH(480), 
	.HALF_DEPTH(1))//to dark if 0
video_mixer(
	.clk_sys(clk24),
	.ce_pix(clk6),
	.ce_pix_out(),
	.R({r,r}),
	.G({g,g}),
	.B({b,b}),
	.HSync(hs),
	.VSync(vs),
	.HBlank(hb),
	.VBlank(vb),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.scandoubler(~scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[5:4] == 3, status[5:4] == 2}),
	.hq2x(status[5:4]==1),
	.mono(0)
	);

   wire 	[7:0] audio_o;
	assign AUDIO_R = AUDIO_L;
	
sigma_delta_dac #(
	.MSBI(7))
sigma_delta_dac(
	.CLK(clk24),
	.RESET(1'b0),
	.DACin(audio_o),
	.DACout(AUDIO_L)
	);	
	
	wire 			coin_r, coin_c, coin_l, self_test, cocktail, slam, start1, start2, fire2, fire1;	
   wire 	[9:0] playerinput_i = { coin_r, coin_c, coin_l, self_test, cocktail, slam, start1, start2, fire2, fire1 };
//ACTIVE LOW
   assign coin_r = ~kb_joy[3];
   assign coin_c = 1;
   assign coin_l = 1;
   assign self_test = 1;//status[1];
   assign cocktail = 1;//status[2];
   assign slam = 1;//status[3];
   assign start1 = ~kb_joy[2];//
   assign start2 = ~kb_joy[1];//this is ok
   assign fire2 =  ~kb_joy[0];
   assign fire1 =  ~kb_joy[0];
	 
	 //Note Cennected Joysticks breaks Controls
centipede centipede(
	.clk_12mhz(clk12),
	.clk_1p5mhz(clk1p5),
 	.reset(/*reset_reg[3] |*/ status[0] | buttons[1] | status[6]),
	.playerinput_i(playerinput_i),
	.trakball_i(),
//	.joystick_i({joystick_0[1],joystick_0[0],joystick_0[3],joystick_0[2], joystick_1[1],joystick_1[0],joystick_1[3],joystick_1[2]}),
	.joystick_i({~kb_joy[7], ~kb_joy[6], ~kb_joy[5], ~kb_joy[4], ~kb_joy[7], ~kb_joy[6], ~kb_joy[5], ~kb_joy[4]}),
	.sw1_i(8'h54),//"01010100"),//Credit Minimum, Difficulty, Bonus Life, Bonus Life, Lives, Lives, Language, Language;
	.sw2_i(8'b0),//"11101010"),//Bonus Coins, Bonus Coins, Bonus Coins, Left Coin, Right Coin, Right Coin, Coinage, Coinage;
	.led_o(),
	.audio_o(audio_o),
	.rgb_o({b,g,r}),
	.sync_o(),
	.hsync_o(hs),
	.vsync_o(vs),
	.hblank_o(hb),
	.vblank_o(vb)
	);

endmodule 
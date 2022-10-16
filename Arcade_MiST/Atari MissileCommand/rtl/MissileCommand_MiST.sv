module MissileCommand_MiST(
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
	input         CLOCK_27,
	output        SDRAM_CKE
);

`include "rtl/build_id.v"

localparam CONF_STR = {
	"MissileC;rom;",
	"O1,Pause,Off,On;",
	
	"O45,Coinage ,1C_1C,2C_1C,Free_Play,1C_2C;",
	"O6,Service,Off,On;",
	"O78,Language ,English,French,German,Spanish;",
	"O9A,Cities ,6,4,5,7;",
	"OB,Bonus Credit for 4 Coins,On,Off;",
	
	"OC,Trackbal Size,Mini,Large;",
	"ODE,Bonus City,None,8000,20000,18000,15000,14000,12000,10000;",
	"OF,Cabinet,Upright,Cocktail;",
	
	"OGH,Mouse/trackball speed,25%,50%,100%,200%;",
	"OIJ,Button order,LMR,LRM,MRL;",
	"O3,Joystick mode,Digital,Analog;",
	"O2,Joystick speed,Low,High;",
	
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire 			pause  = status[1];
//wire 			blend  = status[3];
wire 			service = status[6];
wire [1:0]	coinage = status[5:4];
wire [1:0]	language = status[8:7];
wire [1:0]	cities = status[10:9];
wire 			bonus = status[11];
wire 			size = status[12];
wire [2:0]	bonuscity = status[15:13];
wire 			cabinet = status[16];
assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;
assign SDRAM_CKE = 0;

wire clk_sys, clk_core;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),//20
	.c1(clk_core),//10
	.locked(pll_locked)
	);
	
reg clk_vid = 1'b0;	
always @(posedge clk_core) clk_vid <= !clk_vid;

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

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire [31:0] joystick_analog_0;
wire [31:0] joystick_analog_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_sys        ),
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
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.joystick_analog_0(joystick_analog_0),
	.joystick_analog_1(joystick_analog_1),
	.status         (status         )
	);

wire [5:0] audio;
wire        hs, vs, hb, vb;
wire        blankn = ~(hb | vb);
wire			g, r, b;

missile missile_inst(
	.clk_10M					(clk_core),
	.ce_5M					(clk_vid),
	.reset					(status[0] | buttons[1]),
	.pause					(pause),
	.vtb_dir1				(vtb_dir1),
	.vtb_clk1				(vtb_clk1),
	.htb_dir1				(htb_dir1),
	.htb_clk1				(htb_clk1),


	.coin						(m_coin1),
	.p1_start				(m_one_player),
	.p2_start				(m_two_players),
	
	.p1_fire_l				(m_fireA),
	.p1_fire_c				(m_fireB),
	.p1_fire_r				(m_fireC),
	
	.p2_fire_l				(m_fire2A),
	.p2_fire_c				(m_fire2B),
	.p2_fire_r				(m_fire2C),
	
	.in2						({1'b0,language,1'b0,2'b00,coinage}),
	.switches				({cabinet,bonuscity,bonuscity,bonuscity,size,bonus,cities,cities}),
	.self_test				(service),
	.slam						(m_tilt),
	.flip						(flip),
	
	.r							(r),
	.g							(g),
	.b							(b),
	.h_sync					(hs),
	.v_sync					(vs),
	.h_blank					(hb),
	.v_blank					(vb),
	.audio_o					(audio),
	.dn_addr					(ioctl_addr[15:0]),
	.dn_data					(ioctl_dout),
	.dn_wr					(ioctl_wr && ioctl_index == 0)
);

//Trackball
wire 		TB_horiz, TB_vert;
wire		flip;
wire		vtb_dir1;
wire		vtb_clk1;
wire		htb_dir1;
wire		htb_clk1;
wire [24:0]	ps2_mouse;
trackball trackball
(
	.clk(clk_core),
	.flip(flip),
	.joystick({m_up, m_down, m_left, m_right}),
	.joystick_mode(status[3]),
	.joystick_analog(joystick_analog_0 !=0 ? joystick_analog_0 : joystick_analog_1),
	.joystick_sensitivity(status[13]),
	.mouse_speed(status[15:14]),
	.ps2_mouse(ps2_mouse),
	.v_dir(vtb_dir1),
	.v_clk(vtb_clk1),
	.h_dir(htb_dir1),
	.h_clk(htb_clk1)
);


mist_video #(.COLOR_DEPTH(1), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scandoubler_disable(scandoublerD ),
	.ypbpr          ( ypbpr            )
	);

dac #(
	.C_bits(6))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
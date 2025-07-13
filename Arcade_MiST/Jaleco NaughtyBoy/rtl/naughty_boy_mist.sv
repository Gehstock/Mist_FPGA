module naughty_boy_mist(
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
	"NBOY;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Joystick Swap,Off,On;",
	"OF,Flip Screen,Off,On;",
	
	"O89,Lives,2,3,4,5;",
	"OA,Difficulty,Easier,Harder;",
	"ODE,Bonus Life,10k,30k,50k,70k;",
	"OC,Cabinet,Upright,Cocktail;",
	
	"T0,Reset;",
	"V,v1.15.",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];
//wire [1:0] lives = status[7:6];
//wire       bonus = status[8];
//wire [2:0] difficulty = status[11:9];
//wire       demosnd = status[12];

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clock_24, clock_12, pll_locked;
pll pll(
        .inclk0(CLOCK_27),
        .c0(clock_24),//48
        .c1(clock_12),//12
        .locked(pll_locked)
        );

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [15:0] joystick_0;
wire  [15:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(
	.STRLEN($size(CONF_STR)>>3),
	.ROM_DIRECT_UPLOAD(0))
user_io(
	.clk_sys        (clock_24       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.core_mod		 (game_mod),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clock_12     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

// reset generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_12) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire [11:0] audio;
wire [1:0] game_mod;
wire        hs, vs, cs;
wire			hb, vb;
wire        blankn = ~(hb | vb);
wire [1:0] 	r, g, b;

wire [7:0] dip_switch = { status[12],status[10],1'b0,1'b1,status[14:13],status[9:8]};
wire [4:0]buttons1, buttons2;
always @ (posedge clock_12) begin
	case (game_mod) 
		2'b00 : 	begin	//Naughty Boy
							buttons1 = {m_left,m_right,m_down,m_up,m_fireA};
							buttons2 = {m_left2,m_right2,m_down2,m_up2,m_fire2A};
					end
		2'b01 :	begin	//Pop Flamer
							buttons1 = {m_left,m_right,m_down,m_up,m_fireA};
							buttons2 = {m_left2,m_right2,m_down2,m_up2,m_fire2A};	
					end
		2'b10 :	begin	//Trivia Master
							buttons1 = {m_fireD,m_fireC,m_fireB,m_fireA,1'b0};
							buttons2 = {m_fire2D,m_fire2C,m_fire2B,m_fire2A,1'b0};		
					end			
		default : 	begin	
							buttons1 = {m_left,m_right,m_down,m_up,m_fireA};
							buttons2 = {m_left2,m_right2,m_down2,m_up2,m_fire2A};
						end
	endcase
end


naughty_boy naughty_boy_inst(
	.clock_12			(clock_12) ,
	.reset				(reset) ,
	.game_mod         (game_mod) ,
	.dn_addr				(ioctl_addr) ,
	.dn_data				(ioctl_dout) ,
	.dn_wr				(ioctl_wr) ,
	.dip_switch			(dip_switch) ,
	.flip_screen		(status[6]) ,
	.coin					(m_coin1) ,
	.starts				({m_two_players, m_one_player}) ,
	.player1_btns		(buttons1),
	.player2_btns		(buttons2),
	.video_r				(r) ,
	.video_g				(g) ,
	.video_b				(b) ,
	.video_csync		(cs) ,
	.video_hs			(hs) ,
	.video_vs			(vs) ,
	.video_hblank		(hb) ,
	.video_vblank		(vb) ,
	.ce_pix				() ,
	.audio				(audio)
);

mist_video #(.COLOR_DEPTH(2), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( clock_24         ),
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
	.rotate         ( { 1'b1, rotate } ),
	.scandoubler_disable( scandoublerD ),
	.blend          ( blend            ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

dac #(.C_bits(16))dac(
	.clk_i(clock_24),
	.res_n_i(1),
	.dac_i({audio, 4'b0000}),
	.dac_o(AUDIO_L)
	);

// Arcade inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_12    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b11       ),
	.joyswap     ( status[5]   ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

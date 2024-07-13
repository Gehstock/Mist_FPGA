module VicDual_MiST(
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
	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE

);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"Carnival;ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"T0,Reset;",
	"V,v0.00.",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;

wire clk_mem, clk_vid, clk_sys, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_mem),//92.810880
	.c1(clk_vid),//30.936960
	.c2(clk_sys),//15.468480
	.locked(pll_locked)
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clk_sys        ),
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
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

//wire [24:0] sdram_addr_sig;

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

reg	 [15:0] audio;
wire        hs, vs, hb, vb;
wire blankn = ~(vb | hb);
wire  [7:0] r,g,b;

system system_inst(
	.clk					(clk_sys),
	.clk_sfx				(clk_mem),
	.reset				(reset),
	.game_mode			(game_mode),
	.pause				(btn_pause),
	.coin					(btn_coin),
	.dual_game_toggle	(btn_dual_game_toggle),
	.in_p1				(IN_P1),
	.in_p2				(IN_P2),
	.in_p3				(IN_P3),
	.in_p4				(IN_P4),
	.rgb					({b,g,r}),
	.vsync				(vs),
	.hsync				(hs),
	.vblank				(vb),
	.hblank				(hb),
	.audio				(audio),
	.dn_addr				(ioctl_addr),
	.dn_index			(ioctl_index),
	.dn_download		(ioctl_downl),
	.dn_wr				(ioctl_wr),
	.dn_data				(ioctl_dout),
	.sdram_addr			(sdram_addr),
	.sdram_rd			(sdram_rd),
	.sdram_ack			(sdram_ack),
	.sdram_dout			(sdram_dout)
);

mist_video #(.COLOR_DEPTH(6), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_vid          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r[7:2] : 0),
	.G              ( blankn ? g[7:2] : 0),
	.B              ( blankn ? b[7:2] : 0),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b0             ),
	.rotate         ( { 1'b0, rotate } ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

dac #(.C_bits(16))dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);

// Arcade inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
        
arcade_inputs inputs (
	.clk         ( clk_sys    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b01       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

///////////////////   CONTROLS   ////////////////////
wire [9:0] Controls1 = {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right}; 
wire [9:0] Controls2 = {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2};
wire [9:0] joy = Controls1 | Controls2;
reg simultaneous2player;
wire p1_right = simultaneous2player ? Controls1[0] : joy[0];
wire p2_right = simultaneous2player ? Controls2[0] : joy[0];
wire p1_left = simultaneous2player ? Controls1[1] : joy[1];
wire p2_left = simultaneous2player ? Controls2[1] : joy[1];
wire p1_down = simultaneous2player ? Controls1[2] : joy[2];
wire p2_down = simultaneous2player ? Controls2[2] : joy[2];
wire p1_up = simultaneous2player ? Controls1[3] : joy[3];
wire p2_up = simultaneous2player ? Controls2[3] : joy[3];
wire p1_fire1 = simultaneous2player ? Controls1[4] : joy[4];
wire p2_fire1 = simultaneous2player ? Controls2[4] : joy[4];
wire p1_fire2 = simultaneous2player ? Controls1[5] : joy[5];
wire p2_fire2 = simultaneous2player ? Controls2[5] : joy[5];
wire p1_fire3 = simultaneous2player ? Controls1[6] : joy[6];
//wire p2_fire3 = simultaneous2player ? Controls2[6] : joy[6];	//unused

wire start_p1 = m_one_player;
wire start_p2 = m_two_players;
wire btn_coin = m_coin1;
wire btn_pause = 1'b0;
wire btn_dual_game_toggle = m_tilt;

///////////////////   DIPS   ////////////////////
reg [7:0] sw[8];
always @(posedge clk_sys)
begin
	if (ioctl_wr && (ioctl_index==8'd254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;
end

// Game metadata
`include "rtl/games.v"

// Extract per-game DIPs
// - Alpha Fighter / Head On
wire dip_alphafighter_headon_lives = sw[0][0];
wire [1:0] dip_alphafighter_lives = sw[0][2:1];
wire dip_alphafighter_bonuslifeforfinalufo = sw[0][3];
wire dip_alphafighter_bonuslife = sw[0][4];
// - Borderline
wire dip_borderline_cabinet = sw[0][0];
wire dip_borderline_bonuslife = sw[0][1];
wire [2:0] dip_borderline_lives = sw[0][4:2];
// - Car Hunt / Deep Scan (France) & Invinco + Car Hunt (Germany)
wire [1:0] dip_carhunt_dual_game1_lives = sw[0][1:0];
wire [1:0] dip_carhunt_dual_game2_lives = sw[0][3:2];
// - Carnival
wire dip_carnival_demosounds = sw[0][0];
// - Digger
wire [1:0] dip_digger_lives = sw[0][1:0];
// - Frogs
wire dip_frogs_demosounds = sw[0][0];
wire dip_frogs_freegame = sw[0][1];
wire dip_frogs_gametime = sw[0][2];
wire dip_frogs_coinage = sw[0][3];
// - Head On
wire dip_headon_demosounds = sw[0][0];
wire [1:0] dip_headon_lives = sw[0][2:1];
// - Head On 2
wire dip_headon2_demosounds = sw[0][0];
wire [1:0] dip_headon2_lives = sw[0][2:1];
// - Heiankyo Alien
wire dip_heiankyo_2player = sw[0][0];
wire dip_heiankyo_lives = sw[0][1];
// - Invinco
wire [1:0] dip_invinco_lives = sw[0][1:0];
// - Invinco / Deep Scan
wire [1:0] dip_invinco_deepscan_game1_lives = sw[0][1:0];
wire [1:0] dip_invinco_deepscan_game2_lives = sw[0][3:2];
// - Invinco / Head On 2
wire [1:0] dip_invinco_headon2_game1_lives = sw[0][1:0];
wire [1:0] dip_invinco_headon2_game2_lives = sw[0][3:2];
// - N-Sub

// - Pulsar
wire [1:0] dip_pulsar_lives = sw[0][1:0];
// - Safari

// - Samurai
wire dip_samurai_lives = sw[0][0];
// - Space Attack
wire dip_spaceattack_bonuslifeforfinalufo = sw[0][0];
wire [2:0] dip_spaceattack_lives = (sw[0][2:1] == 2'd0) ? DIP_SPACEATTACK_LIVES_3 :
									(sw[0][2:1] == 2'd1) ? DIP_SPACEATTACK_LIVES_4 :
									(sw[0][2:1] == 2'd2) ? DIP_SPACEATTACK_LIVES_5 :
									DIP_SPACEATTACK_LIVES_6;
wire dip_spaceattack_bonuslife = sw[0][3]; 
wire dip_spaceattack_creditsdisplay = sw[0][4];
// - Space Attack + Head On
wire dip_spaceattack_headon_bonuslifeforfinalufo = sw[0][0];
wire [1:0] dip_spaceattack_headon_game1_lives = sw[0][2:1];
wire dip_spaceattack_headon_bonuslife = sw[0][3]; 
wire dip_spaceattack_headon_creditsdisplay = sw[0][4];
wire dip_spaceattack_headon_game2_lives = sw[0][5];
// - Space Trek
wire dip_spacetrek_lives = sw[0][0];
wire dip_spacetrek_bonuslife = sw[0][1];
// - Star Raker
wire dip_starraker_cabinet = sw[0][0];
wire dip_starraker_bonuslife = sw[0][1];
// - Sub Hunt

// - Tranquilizer Gun
// N/A
// - Wanted
wire dip_wanted_cabinet = sw[0][0];
wire dip_wanted_bonuslife = sw[0][1];
wire [1:0] dip_wanted_lives = sw[0][3:2];


///////////////////   CORE INPUTS   ////////////////////
reg [4:0] game_mode /*verilator public_flat*/;
reg	[7:0]	IN_P1;
reg	[7:0]	IN_P2;
reg	[7:0]	IN_P3;
reg	[7:0]	IN_P4;
reg			landscape;

always @(posedge clk_sys) 
begin
	// Set game mode
	if (ioctl_wr && (ioctl_index==8'd1)) game_mode <= ioctl_dout[4:0];

	// Set defaults
	landscape <= 1'b0;
	simultaneous2player <= 1'b0;

	IN_P1 <= 8'hFF;
	IN_P2 <= 8'hFF;
	IN_P3 <= 8'hFF;
	IN_P4 <= 8'hFF;

	// Game specific inputs
	case (game_mode)
		GAME_ALPHAFIGHTER:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, dip_alphafighter_headon_lives, dip_alphafighter_lives[0], ~p2_fire1, ~p2_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_alphafighter_lives[1], 1'b1, ~p2_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_alphafighter_bonuslife, 1'b1, ~p2_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_alphafighter_bonuslifeforfinalufo, 1'b1, ~p2_left };
		end
		GAME_BORDERLINE:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, dip_borderline_cabinet, dip_borderline_lives[0], ~p1_fire1, ~p1_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_borderline_lives[1], ~p1_fire1, ~p1_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_borderline_lives[2], 1'b1, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_borderline_bonuslife, 1'b1, ~p1_left };
		end
		GAME_CARHUNT_DUAL:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_carhunt_dual_game1_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_carhunt_dual_game1_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_carhunt_dual_game2_lives[0], 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_carhunt_dual_game2_lives[1], 2'b11 };
		end
		GAME_CARNIVAL:
		begin
			IN_P1 <= { 3'b111, dip_carnival_demosounds, 4'b1111 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 4'b1011 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 4'b1111 };
			IN_P4 <= { 2'b11, ~start_p2, 5'b11111 };
		end
		GAME_DIGGER:
		begin
			IN_P1 <= { ~p1_up, ~p1_left, ~p1_down, ~p1_right, ~p1_fire2, ~p1_fire1, ~start_p2, ~start_p1 };
			IN_P3 <= { 6'b111111, dip_digger_lives };
		end
		GAME_FROGS:
		begin
			IN_P1 <= { ~p1_fire1, dip_frogs_coinage, dip_frogs_gametime, dip_frogs_freegame, dip_frogs_demosounds, ~p1_left, ~p1_up, ~p1_right };
			landscape <= 1'b1;
		end
		GAME_HEADON:
		begin
			IN_P1 <= { ~p1_up, ~p1_left, ~p1_down, ~p1_right, ~p1_fire1, dip_headon_demosounds, dip_headon_lives };
			landscape <= 1'b1;
		end
		GAME_HEADON2:
		begin
			IN_P1 <= { ~p1_up, ~p1_left, ~p1_down, ~p1_right, ~p1_fire1, 1'b1, ~start_p2, ~start_p1 };
			IN_P3 <= { 3'b111, dip_headon2_lives, 3'b111 };
			IN_P4 <= { 6'b111111, dip_headon2_demosounds, 1'b1 };
			landscape <= 1'b1;
		end
		GAME_HEIANKYO:
		begin
			IN_P1 <= { 2'b11, ~p1_fire1, ~p1_up, dip_heiankyo_2player, 1'b1, ~p2_fire2, ~p2_up };
			IN_P2 <= { 2'b11, ~p1_fire2, ~p1_right, 2'b01, ~p2_fire2, ~p2_right };
			IN_P3 <= { 3'b110, ~p1_down, 3'b110, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p1, ~p1_left, 1'b1, dip_heiankyo_lives, ~start_p2, ~p2_left };
			simultaneous2player <= ~dip_heiankyo_2player;
		end
		GAME_INVINCO:
		begin
			IN_P1 <= { 1'b1, ~p1_left, 1'b1, ~p1_right, ~p1_fire1, 1'b1, ~start_p2, ~start_p1 };
			IN_P3 <= { 6'b11, dip_invinco_lives };
		end
		GAME_INVINCO_DEEPSCAN:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_invinco_deepscan_game1_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_invinco_deepscan_game1_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_invinco_deepscan_game2_lives[0], 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_invinco_deepscan_game2_lives[1], 2'b11 };
		end
		GAME_INVINCO_HEADON2:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_invinco_headon2_game1_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_invinco_headon2_game1_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_invinco_headon2_game2_lives[0], 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_invinco_headon2_game2_lives[1], 2'b11 };
		end
		GAME_NSUB:
		begin
			IN_P1 <= ~{ p1_up, p1_left, p1_down, p1_right, p1_fire2, p1_fire1, start_p2, start_p1 };
		end
		GAME_PULSAR:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_pulsar_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_pulsar_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 4'b1111 };
			IN_P4 <= { 2'b11, ~start_p2, 5'b11111 };
		end
		GAME_SAFARI:
		begin
			IN_P1 <= { ~p1_fire1, 1'b0, ~p1_fire3, ~p1_fire2, ~p1_left, ~p1_right, ~p1_down, ~p1_up };
			landscape <= 1'b1;
		end
		GAME_SAMURAI:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_samurai_lives, 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 4'b1111 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 4'b1111 };
			IN_P4 <= { 2'b11, ~start_p2, 5'b11111 };
		end
		GAME_SPACEATTACK:
		begin
			IN_P1 <= { ~p1_left, ~p2_left, ~p2_right, ~p2_fire1, ~start_p2, ~start_p1, ~p1_fire1, ~p1_right };
			IN_P3 <= { dip_spaceattack_creditsdisplay, 2'b11, dip_spaceattack_bonuslife, dip_spaceattack_lives, dip_spaceattack_bonuslifeforfinalufo };
		end
		GAME_SPACEATTACK_HEADON:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, dip_spaceattack_headon_game2_lives, dip_spaceattack_headon_game1_lives[0], ~p2_fire1, ~p2_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_spaceattack_headon_game1_lives[1], 1'b1, ~p2_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_spaceattack_headon_bonuslife, 1'b1, ~p2_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_spaceattack_headon_bonuslifeforfinalufo, 1'b1, ~p2_left };
		end
		GAME_SPACETREK:
		begin
			IN_P1 <= { 2'b11, ~p1_left, ~p1_right, 1'b1, dip_spacetrek_lives, 2'b11 };
			IN_P2 <= { 2'b11, ~p1_up, ~p1_down, 4'b1111 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_spacetrek_bonuslife, 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 4'b1111 };
		end
		GAME_STARRAKER:
		begin
			IN_P1 <= { 2'b11, ~p1_left, ~p1_right, dip_starraker_cabinet, 1'b1, ~p1_fire1, ~p1_up };
			IN_P2 <= { 2'b11, ~p1_up, ~p1_down, 2'b11, ~p1_fire1, ~p1_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 3'b111, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_starraker_bonuslife, 1'b1, ~p1_left };
		end
		GAME_SUBHUNT:
		begin
			// IN_P1 <= ~{ 2'b0, p1_left, p1_right, 2'b0, p1_fire1, p1_up };
			// IN_P2 <= ~{ 2'b0, p1_up, p1_down, 2'b0, p1_fire1, p1_right };
			// IN_P3 <= ~{ 2'b0, p1_fire1, start_p1, 3'b0, p1_down };
			// IN_P4 <= ~{ 2'b0, start_p2, 4'b0, p1_left };
		end
		GAME_TRANQUILIZERGUN:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 2'b11, ~p1_fire1, ~p1_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 3'b111, ~p1_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 3'b111, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p2, 4'b1111, ~p1_left };
		end
		GAME_WANTED:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_wanted_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_wanted_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_wanted_cabinet, 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_wanted_bonuslife, 2'b11 };
		end
	endcase
end

///////////////////   WAVE AUDIO STORAGE   ///////////////////
wire [7:0]  sdram_dout;
wire [24:0] sdram_addr;
reg         sdram_ack;
reg         sdram_rd;
wire sdram_ready;
reg  [15:0] wav_data_o;
wire sdram_download = ioctl_downl && ioctl_wr && ioctl_index == 8'd2;

sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(clk_mem),

	.addr(sdram_download ? ioctl_addr : sdram_addr[24:0]),
	.we(sdram_download),
	.rd(~sdram_download & sdram_rd),
	.din(ioctl_dout),
	.dout(wav_data_o),
	.ready(sdram_ready)
);

always @(posedge clk_mem)
begin
	reg sdram_ready_last;
	sdram_ready_last <= sdram_ready;
	// Latch upper/lower SDRAM data out when data is ready
	if(sdram_ready && ~sdram_ready_last) 
	begin
		sdram_dout <= !sdram_addr[0] ? wav_data_o[7:0] : wav_data_o[15:8];
		sdram_ack <= ~sdram_ack;
	end
end

endmodule 
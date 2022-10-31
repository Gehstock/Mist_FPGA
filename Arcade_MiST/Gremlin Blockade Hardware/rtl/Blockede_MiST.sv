module Blockede_MiST(
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
	"BLOCKADE;;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O7,Pause,Off,On;",
	"OGJ,Analog Video H-Pos,0,-1,-2,-3,-4,-5,-6,-7,8,7,6,5,4,3,2,1;",
	"OKN,Analog Video V-Pos,0,-1,-2,-3,-4,-5,-6,-7,8,7,6,5,4,3,2,1;",
	"DIP;",
	"T0,Reset;",
	"V,v1.50.",`BUILD_DATE
};

wire [1:0] scanlines 			= status[4:3];
wire       blend     			= status[5];
wire       btn_pause   			= status[7];
assign LED = ~(ioctl_downl);
assign AUDIO_R = AUDIO_L;

wire clk_sys;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys)
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

wire  [6:0] core_mod;

wire   		vid;wire  [2:0] video_rgb = {3{vid}} & overlay_mask;
wire  [5:0] rgb_out;
wire        scandoublerD;
wire        hs, vs, vb, hb;
wire        blankn = ~(hb | vb);
wire        ypbpr;
wire        no_csync;

wire [15:0] audio;

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io data_io(
	.clk_sys       ( clk_sys      ),
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

mist_video #(.COLOR_DEPTH(2), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? rgb_out[5:4] : 0 ),
	.G              ( blankn ? rgb_out[3:2] : 0 ),
	.B              ( blankn ? rgb_out[1:0] : 0 ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scanlines      ( scanlines        ),
	.ce_divider     ( 1'b0             ),
	.scandoubler_disable(scandoublerD  ),
	.no_csync       ( no_csync         ),
	.ypbpr          ( ypbpr            )
	);
	
// H/V offset
wire [3:0]  voffset = status[23:20];
wire [3:0]  hoffset = status[19:16];
wire hs_original, vs_original;
wire ce_pix;
jtframe_resync jtframe_resync
(
	.clk(clk_sys),
	.pxl_cen(ce_pix),
	.hs_in(hs_original),
	.vs_in(vs_original),
	.LVBL(~vb),
	.LHBL(~hb),
	.hoffset(hoffset),
	.voffset(voffset),
	.hs_out(hs),
	.vs_out(vs)
);
	

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
	.scandoubler_disable (scandoublerD ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
   .core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.C_bits(16))
dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

///////////////////   DIPS   ////////////////////

reg [2:0] dip_blockade_lives;
reg dip_comotion_lives;
reg [1:0] dip_hustle_coin;
reg [7:0] dip_hustle_freegame;
reg dip_hustle_time;
reg [1:0] dip_blasto_coin;
reg dip_blasto_demosounds;
reg dip_blasto_time;
reg dip_boom;
reg [2:0] dip_minesweeper_lives;
reg dip_minesweeper_cabinet;
reg [1:0] dip_overlay_type;
reg [2:0] overlay_mask;
wire [7:0] sw = status[15:8];
reg [7:0] IN_1;
reg [7:0] IN_2;
reg [7:0] IN_4;
always @(posedge clk_sys)
begin
 	case(core_mod)
	7'h0: // GAME_BLOCKADE
	begin
		// The lives DIP behaves strangely in Blockade, so it is remapped here
		case(sw[1:0])
		2'd0: dip_blockade_lives <= 3'b011; // 3 lives
		2'd1: dip_blockade_lives <= 3'b110; // 4 lives
		2'd2: dip_blockade_lives <= 3'b100; // 5 lives
		2'd3: dip_blockade_lives <= 3'b000; // 6 lives		
		endcase
		dip_boom <= sw[4];
		dip_overlay_type <= sw[3:2];
		IN_1 <= ~{m_coin1, dip_blockade_lives, 1'b0, dip_boom, 2'b00};
		IN_2 <= ~{m_left, m_down, m_right, m_up, m_left2, m_down2, m_right2, m_up2};
		IN_4 <= ~{8'b00000000}; // Unused		
	end
	7'h1: // GAME_COMOTION
	begin
		dip_comotion_lives <= sw[0];
		dip_overlay_type <= sw[2:1];
		dip_boom <= sw[3];		
		IN_1 <= ~{m_coin1, 2'b0, m_one_player, dip_comotion_lives, dip_boom, 2'b00}; 
		IN_2 <= ~{m_left3, m_down3, m_right3, m_up3, m_left, m_down, m_right, m_up};
		IN_4 <= ~{m_left4, m_down4, m_right4, m_up4, m_left4, m_down4, m_right4, m_up4};
	end
	7'h2: // GAME_HUSTLE
	begin
		dip_hustle_coin <= sw[1:0];
		case(sw[3:2])
		2'd0: dip_hustle_freegame <= 8'b11100001;
		2'd1: dip_hustle_freegame <= 8'b11010001;
		2'd2: dip_hustle_freegame <= 8'b10110001;
		2'd3: dip_hustle_freegame <= 8'b01110001;		
		endcase
		dip_hustle_time <= sw[4];
		dip_overlay_type <= sw[6:5];
		IN_1 <= ~{m_coin1, 2'b0, m_two_players, m_one_player, dip_hustle_time, dip_hustle_coin};
		IN_2 <= ~{m_left, m_down, m_right, m_up, m_left2, m_down2, m_right2, m_up2};
		IN_4 <= dip_hustle_freegame; // Extra DIPS
	end
	7'h3: // GAME_BLASTO
	begin
		dip_blasto_coin <= sw[1:0];
		dip_blasto_demosounds <= sw[2];
		dip_blasto_time = sw[3];		
		dip_overlay_type <= sw[5:4];
		IN_1 <= ~{m_coin1, 3'b0, dip_blasto_time, dip_blasto_demosounds, dip_blasto_coin};
		IN_2 <= ~{m_fireA, m_two_players, m_one_player, 4'b0000, m_fire2A}; 
		IN_4 <= ~{m_up, m_left, m_down, m_right, m_up2, m_left2, m_down2, m_right2};		
	end
	7'h4: // GAME_Minesweeper
	begin
		dip_minesweeper_cabinet <= sw[0];
		dip_boom <= sw[1];
		dip_minesweeper_lives <= sw[3:2];
		dip_overlay_type <= sw[5:4];
		IN_1 <= ~{m_coin1, dip_minesweeper_lives, 1'b0, dip_boom, 1'b0/*dip_minesweeper_cabinet*/, 1'b0};
		IN_2 <= ~{m_left2, m_down2, m_right2, m_up2, m_left, m_down, m_right, m_up}; 
		IN_4 <= ~{8'b00000000};		
	end
	7'h5: // GAME_Minesweeper (4-Player)
	begin
		dip_minesweeper_cabinet <= sw[0];
		dip_boom <= sw[1];
		dip_minesweeper_lives <= sw[3:2];
		dip_overlay_type <= sw[5:4];
		IN_1 <= ~{m_coin1, dip_minesweeper_lives, 1'b0, dip_boom, 1'b0/*dip_minesweeper_cabinet*/, 1'b0};
		IN_2 <= ~{m_left2, m_down2, m_right2, m_up2, m_left, m_down, m_right, m_up}; 
		IN_4 <= ~{m_left4, m_down4, m_right4, m_up4, m_left3, m_down3, m_right3, m_up3}; 	
	end
	endcase
		// Generate overlay colour mask
	case(dip_overlay_type)
	2'd0: overlay_mask <= 3'b010; // Green
	2'd1: overlay_mask <= 3'b111; // White
	2'd2: overlay_mask <= 3'b011; // Yellow
	2'd3: overlay_mask <= 3'b001; // Red
	endcase

end

wire		pause_cpu;
pause #(2,2,2,24) pause (
	.rgb_out(rgb_out),
	.r({2{video_rgb[0]}}),
	.g({2{video_rgb[1]}}),
	.b({2{video_rgb[2]}}),
	.user_button(btn_pause),
	.pause_request(),
	.options(~status[26:25])
);


///////////////////   GAME   ////////////////////
reg rom_downloaded = 1'b0;
wire rom_download = ioctl_downl && ioctl_index == 8'b0;
wire reset = (status[0] | buttons[1] | rom_download | ~rom_downloaded);
// Latch release reset if ROM data is received (stops sound circuit from going off if ROMs are not found)
always @(posedge clk_sys) 
	if(rom_download && ioctl_dout > 8'b0) rom_downloaded <= 1'b1; 

blockade blockade(
	.clk				(clk_sys),
	.reset			(reset),
	.pause			(btn_pause),
	.game_mode		(core_mod),
	.ce_pix			(ce_pix),
	.video			(vid),
	.vsync			(vs_original),
	.hsync			(hs_original),
	.vblank			(vb),
	.hblank			(hb),

	.audio_l			(audio),

	.in_1				(IN_1),
	.in_2				(IN_2),
	.in_4				(IN_4),
	.coin				(m_coin1),

	.dn_addr			(ioctl_addr[13:0]),
	.dn_wr			(ioctl_wr & rom_download),
	.dn_data			(ioctl_dout)
);

endmodule

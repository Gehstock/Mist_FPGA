//============================================================================
//  Arcade: Defender
//

module Defender_MiST(
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

`include "rtl/build_id.v" 

`define CORE_NAME "DEFENDER"
//`define CORE_NAME "COLONY7"
//`define CORE_NAME "MAYDAY"
//`define CORE_NAME "JIN"

localparam CONF_STR = {
	`CORE_NAME,";ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"T0,Reset;",
	"V,v1.2.",`BUILD_DATE
};

wire       rotate  = status[2];
reg  [7:0] input0;
reg  [7:0] input1;
reg  [7:0] input2;
reg        mayday; // protection enable in Mayday
reg  [1:0] orientation; // [left/right, landscape/portrait]

always @(*) begin
	mayday = 0;
	input0 = 0;
	input1 = 0;
	input2 = 0;
	orientation = 2'b10;
	if (`CORE_NAME == "DEFENDER") begin
/*
-- pia rom board port a - input0
--      bit 0  Auto Up / manual Down
--      bit 1  Advance
--      bit 2  Right Coin (nc)
--      bit 3  High Score Reset
--      bit 4  Left Coin
--      bit 5  Center Coin (nc)
--      bit 6  led 2 (output)
--      bit 7  led 1 (output)
*/
		input0 = { 3'b000, m_coin1, 1'b0/*btn_score_reset*/, 1'b0, m_fireF, m_fireE };
/*
-- pia io port a - input1
--      bit 0  Fire
--      bit 1  Thrust
--      bit 2  Smart Bomb
--      bit 3  HyperSpace
--      bit 4  2 Players
--      bit 5  1 Player
--      bit 6  Reverse
--      bit 7  Down
*/
		input1 = { m_down, m_left | m_right, m_one_player, m_two_players, m_fireD, m_fireC, m_fireB, m_fireA };
/*
-- pia io port b
--      bit 0  Up
--      bit 7  1 for coktail table, 0 for upright cabinet
--      other <= GND
*/
		input2 = { 7'b000000, m_up };
	end else if (`CORE_NAME == "COLONY7") begin
		orientation = 2'b01;
		input0 = { 3'b000, m_coin1, 4'b0001 };
		input1 = { m_fireB, m_fireA, m_one_player, m_two_players, m_up, m_left, m_right, m_down };
		input2 = { 7'b000000, m_fireC };
	end else if (`CORE_NAME == "MAYDAY") begin
		mayday = 1;
		input0 = { 2'b00, m_coin2, m_coin1, 1'b0, 1'b0/*service*/, m_fireF, m_fireE };
		input1 = { m_down, 1'b0, m_one_player, m_two_players, m_fireB, m_fireC, m_right, m_fireA };
		input2 = { 7'b000000, m_up };
	end else if (`CORE_NAME == "JIN") begin
		orientation = 2'b11;
		input0 = { 3'b000, m_coin2, m_coin1, 3'b000 };
		input1 = { m_fireB, m_fireA, m_one_player, m_two_players, m_right, m_left, m_down, m_up };
		//unknown/Level completed/Level completed/unknown/Lives/Coinage/Coinage/Coinage
		input2 = 0;
	end
end

assign LED = 1;
assign SDRAM_CLK = clk_sys;
assign SDRAM_CKE = 1;

wire clk_sys, clk_6, clk_0p89;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),//54
	.c1(clk_6),//6
	.c2(clk_0p89),//0.89
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire  [7:0] audio;
wire        hs, vs;
wire        blankn;
wire  [2:0] r,g;
wire  [1:0] b;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

/*
ROM Structure:
0000-6FFF main cpu 44k (D000-FFFF + page 1,2,3,7)
7000-73FF decoder   1k
7400-7BFF snd  cpu  2k
*/
data_io data_io (
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

reg         port1_req, port2_req;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire        rom_rd;
wire [11:0] snd_addr;
wire [11:0] snd_rom_addr;
wire        snd_vma;
wire [15:0] snd_do;

sdram #(.MHZ(54)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sys      ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : {1'b0, rom_addr[14:1]} ),
	.cpu1_q        ( rom_do ),

	// port2 for sound board
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h3A00 ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.snd_addr      ( ioctl_downl ? 15'h7fff : {5'h0, snd_addr[10:1]} ),
	.snd_q         ( snd_do )
);

always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;
	reg        snd_vma_r, snd_vma_r2;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
	snd_vma_r <= snd_vma; snd_vma_r2 <= snd_vma_r;
	if (snd_vma_r2) snd_addr <= snd_rom_addr;	
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded;
end

defender defender (
	.clock_6          ( clk_6           ),
	.clk_0p89         ( clk_0p89        ),
	.reset            ( reset           ),
	.video_r      		( r               ),
	.video_g      		( g               ),
	.video_b      		( b               ),
	.video_hs     		( hs              ),
	.video_vs     		( vs              ),
	.video_blankn 		( blankn          ),
	.audio_out    		( audio           ),

	.mayday           ( mayday          ),

	.input0           ( input0          ),
	.input1           ( input1          ),
	.input2           ( input2          ),

	.roms_addr        ( rom_addr        ),
	.roms_do          ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.vma              ( rom_rd          ),
	.snd_addr         ( snd_rom_addr    ),
	.snd_do           ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),
	.snd_vma          ( snd_vma ),

	.dl_clock         ( clk_sys ),
	.dl_addr          ( ioctl_addr[15:0] ),
	.dl_data          ( ioctl_dout ),
	.dl_wr            ( ioctl_wr )
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b, b[1] }  : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( {orientation[1],rotate} ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( status[4:3]      ),
	.blend          ( status[5]        ),
	.ypbpr          ( ypbpr            )
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
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire dac_o;
assign AUDIO_L = dac_o;
assign AUDIO_R = dac_o;

dac #(
	.C_bits(8))
dac(
	.clk_i(clk_0p89),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(dac_o)
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
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

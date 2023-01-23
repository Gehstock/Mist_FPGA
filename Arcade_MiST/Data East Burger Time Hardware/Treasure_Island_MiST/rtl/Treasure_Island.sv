module Treasure_Island
(
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
	"TREASURE;ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
	};
	
assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = clk_72;
assign 		SDRAM_CKE = 1;	

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire [10:0] audio;


wire hs, vs, cs;
wire [2:0] r, g;
wire [1:0] b;
wire       blankn;



wire clk_72, clk_12;
wire pll_locked;

pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_72),
	.c1(clk_12),
	.locked(pll_locked)
	);

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_72     	),
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
wire [24:0] bg_ioctl_addr = ioctl_addr - 17'h10000;
wire [14:0] prg_rom_addr;
wire [11:0] snd_rom_addr;
wire [15:0] prg_rom_do, snd_rom_do;


wire	[13:0]	BGCH_A;
wire	[15:0]	BGCH_D;
sdram sdram(
	.*,
	.init_n        ( pll_locked ),
	.clk           ( clk_72     ),

	// port1 used for main + aux CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),
	
	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b00, prg_rom_addr[14:1]} ),
	.cpu1_q        ( prg_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : {snd_rom_addr[11:1] + 16'h4000} ),
	.cpu2_q        ( snd_rom_do ),

	// port2 for graphics
	.port2_req     ( port2_req    ),
	.port2_ack     ( ),
	.port2_a       ( bg_ioctl_addr[23:1] ),
	.port2_ds      ( {bg_ioctl_addr[0], ~bg_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.bg_addr       ( BGCH_A ),
	.bg_q          ( BGCH_D )
);

// ROM download controller
always @(posedge clk_72) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_72) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

Treasure_Island_Top Treasure_Island_Top(
	.clock_12			(clk_12),
	.reset				(reset),
	.video_r				(r),
	.video_g				(g),
	.video_b				(b),
	.video_csync		(cs),
	.video_blankn		(blankn),
	.video_hs			(hs),
	.video_vs			(vs),
	.audio_out			(audio),  
	.P1					({2'b11, 1'b1, m_fireA, m_down, m_up, m_left, m_right}),
	.P2					({2'b11, 1'b1, m_fire2A, m_down2, m_up2, m_left2, m_right2}),
	.SYS					({m_coin2, m_coin1, 2'b11, 1'b1, m_tilt, m_two_players, m_one_player}),
	.DSW1					({7'b011_1111}),
	.DSW2					({8'b1110_1011}),
	.prg_rom_addr(prg_rom_addr),
	.prg_rom_do(prg_rom_addr[0] ? prg_rom_do[15:8] : prg_rom_do[7:0]),	
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_addr[0] ? snd_rom_do[15:8] : snd_rom_do[7:0]),	
	.dbg_cpu_addr()
	);


mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_72           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b[1], b} : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( {1'b1,status[2]} ),
	.ce_divider     ( 1'b0             ),
	.blend          ( status[5]        ),
	.scandoubler_disable( scandoublerD ),
	.no_csync       ( 1'b0             ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_72         ),
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
	
dac #(.C_bits(11))dac(
	.clk_i(clk_72),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_72      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( status[2]   ),
	.orientation ( {1'b1, 1'b1}),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
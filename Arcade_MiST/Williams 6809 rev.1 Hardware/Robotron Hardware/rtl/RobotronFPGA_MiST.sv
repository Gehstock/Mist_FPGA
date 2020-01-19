//============================================================================
//  Robotron-FPGA MiST top-level
//
//  Robotron-FPGA is Copyright 2012 ShareBrained Technology, Inc.
//
//  Supports:
//  Robotron 2048/Joust/Stargate/Bubbles/Splat/Sinistar

module RobotronFPGA_MiST(
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

//`define CORE_NAME "ROBOTRON"
`define CORE_NAME "JOUST"
//`define CORE_NAME "SPLAT"
//`define CORE_NAME "BUBBLES"
//`define CORE_NAME "STARGATE"
//`define CORE_NAME "SINISTAR"

localparam CONF_STR = {
	`CORE_NAME,";ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Swap Joysticks,Off,On;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       joyswap   = status[6];

reg  [7:0] SW;
reg  [7:0] JA;
reg  [7:0] JB;
reg  [3:0] BTN;
reg        blitter_sc2, sinistar;
reg  [1:0] orientation; // [left/right, landscape/portrait]

always @(*) begin
	orientation = 2'b10;
	SW = 8'h00;
	blitter_sc2 = 0;
	sinistar = 0;

	if (`CORE_NAME == "ROBOTRON") begin
		BTN = { m_one_player, m_two_players, m_coin1 | m_coin2, reset };
		JA  = ~{ m_right2, m_left2, m_down2, m_up2, m_right, m_left, m_down, m_up };
		JB  = ~{ m_right2, m_left2, m_down2, m_up2, m_right, m_left, m_down, m_up };
	end else if (`CORE_NAME == "JOUST") begin
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = ~{ 5'b00000, m_fireA, m_right, m_left };
		JB  = ~{ 5'b00000, m_fire2A, m_right2, m_left2 };
	end	else if (`CORE_NAME == "SPLAT") begin
		blitter_sc2 = 1;
		BTN = { m_one_player, m_two_players, m_coin1 | m_coin2, reset };
		JA  = ~{ m_right2, m_left2, m_down2, m_up2, m_right, m_left, m_down, m_up };
		JB  = ~{ m_right4, m_left4, m_down4, m_up4, m_right3, m_left3, m_down3, m_up3 };
	end else if (`CORE_NAME == "BUBBLES") begin
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = ~{ 4'b0000, m_right, m_left, m_down, m_up };
		JB  = ~{ 4'b0000, m_right2, m_left2, m_down2, m_up2 };
	end else if (`CORE_NAME == "STARGATE") begin
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = ~{ m_fireE, m_up, m_down, m_left | m_right, m_fireD, m_fireC, m_fireB, m_fireA };
		JB  = ~{ m_fire2E, m_up2, m_down2, m_left2 | m_right2, m_fire2D, m_fire2C, m_fire2B, m_fire2A };
	end else if (`CORE_NAME == "SINISTAR") begin
		sinistar = 1;
		orientation = 2'b01;
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = { sin_x, 2'b00, m_right | m_left | m_right2 | m_left2, sin_y, 2'b00, m_up | m_down | m_up2 | m_down2 };
		JB  = { sin_x, 2'b00, m_right | m_left | m_right2 | m_left2, sin_y, 2'b00, m_up | m_down | m_up2 | m_down2 };
	end
end

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_mem;
assign SDRAM_CKE = 1;

wire clk_sys, clk_mem, clk_aud;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_mem),//96
	.c1(clk_sys),//12
	.c2(clk_aud),//0.89
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
0000-BFFF main cpu 48k
C000-CFFF snd  cpu  4k
*/
data_io data_io (
	.clk_sys       ( clk_mem      ),
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
wire [23:1] mem_addr;
wire [15:0] mem_do;
wire [15:0] mem_di;
wire        mem_oe;
wire        mem_we;
wire        ramcs;
wire        romcs;
wire        ramlb;
wire        ramub;

reg         clkref;
always @(posedge clk_sys) clkref <= ~clkref;

sdram #(.MHZ(96)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_mem      ),
	.clkref        ( clkref       ),

	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[22:0] ),
	.port1_ds      ( 2'b11 ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout[7:4], ioctl_dout[7:4], ioctl_dout[3:0], ioctl_dout[3:0]} ),
	.port1_q       ( ),

	// CPU/video access
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : sdram_addr ),
	.cpu1_d        ( mem_di  ),
	.cpu1_q        ( mem_do  ),
    .cpu1_oe       ( ~mem_oe & ~(ramcs & romcs) ),
	.cpu1_we       ( ~mem_we & ~(ramcs & romcs) ),
	.cpu1_ds       ( ~romcs ? 2'b11 : ~{ramub, ramlb} )
);

// ROM address to SDRAM address:
// 0xxx-8xxx -> 0xxx-8xxx
// DXXX-FXXX -> 9xxx-Bxxx
wire [17:1] sdram_addr = ~romcs ? {1'b0, mem_addr[16], ~mem_addr[16] & mem_addr[15], mem_addr[14:1]} : { 1'b1, mem_addr[16:1] };

always @(posedge clk_mem) begin
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
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded;
end

robotron_soc robotron_soc (
	.clock       ( clk_sys     ),
	.clock_snd   ( clk_aud     ),
	.vgaRed      ( r           ),
	.vgaGreen    ( g           ),
	.vgaBlue     ( b           ),
	.Hsync       ( hs          ),
	.Vsync       ( vs          ),
	.audio_out   ( audio       ),

	.blitter_sc2 ( blitter_sc2 ),
	.sinistar    ( sinistar    ),
	.BTN         ( BTN         ),
	.SIN_FIRE    ( ~m_fireA & ~m_fire2A ),
	.SIN_BOMB    ( ~m_fireB & ~m_fire2B ),
	.SW          ( SW          ),
	.JA          ( JA          ),
	.JB          ( JB          ),

	.MemAdr      ( mem_addr    ),
	.MemDin      ( mem_di      ),
	.MemDout     ( mem_do      ),
	.MemOE       ( mem_oe      ),
	.MemWR       ( mem_we      ),
	.RamCS       ( ramcs       ),
	.RamLB       ( ramlb       ),
	.RamUB       ( ramub       ),
	.FlashCS     ( romcs       ),

	.dl_clock    ( clk_mem  ),
	.dl_addr     ( ioctl_addr[15:0] ),
	.dl_data     ( ioctl_dout ),
	.dl_wr       ( ioctl_wr )
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( {b, b[1] }       ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( {orientation[1],rotate} ),
	.scandoubler_disable( scandoublerD ),
	.ce_divider     ( 1'b1             ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            )
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        ( clk_sys          ),
	.conf_str       ( CONF_STR         ),
	.SPI_CLK        ( SPI_SCK          ),
	.SPI_SS_IO      ( CONF_DATA0       ),
	.SPI_MISO       ( SPI_DO           ) ,
	.SPI_MOSI       ( SPI_DI           ),
	.buttons        ( buttons          ),
	.switches       ( switches         ),
	.scandoubler_disable (scandoublerD ),
	.ypbpr          ( ypbpr            ),
	.key_strobe     ( key_strobe       ),
	.key_pressed    ( key_pressed      ),
	.key_code       ( key_code         ),
	.joystick_0     ( joystick_0       ),
	.joystick_1     ( joystick_1       ),
	.status         ( status           )
	);

wire dac_o;
assign AUDIO_L = dac_o;
assign AUDIO_R = dac_o;

dac #(
	.C_bits(8))
dac(
	.clk_i(clk_aud),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(dac_o)
	);

// Sinistar controls
reg sin_x;
reg sin_y;

always @(posedge clk_sys) begin
	if (m_right | m_right2) sin_x <= 0;
	else if (m_left | m_left2) sin_x <= 1;

	if (m_up | m_up2) sin_y <= 0;
	else if (m_down | m_down2) sin_y <= 1;
end

// General controls
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
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 

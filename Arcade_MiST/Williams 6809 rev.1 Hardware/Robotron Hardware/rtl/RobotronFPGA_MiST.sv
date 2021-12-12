//============================================================================
//  Robotron-FPGA MiST top-level
//
//  Robotron-FPGA is Copyright 2012 ShareBrained Technology, Inc.
//
//  Supports:
//  Robotron 2048/Joust/Splat/Bubbles/Stargate/Alien Arena/Sinistar/
//  Playball!/Lotto Fun/Speed Ball

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

`define CORE_NAME "ROBOTRON"

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Swap Joysticks,Off,On;",
	"O7,Auto up,Off,On;",
	"T8,Advance;",
	"R1024,Save NVRAM;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       joyswap   = status[6];
wire       autoup    = status[7];
wire       adv       = status[8];

reg   [7:0] SW;
reg   [7:0] JA;
reg   [7:0] JB;
reg   [7:0] AN0;
reg   [7:0] AN1;
reg   [7:0] AN2;
reg   [7:0] AN3;
reg   [3:0] BTN;
reg         blitter_sc2, sinistar, speedball;
reg         speech_en;

wire  [6:0] core_mod;
reg   [1:0] orientation; // [left/right, landscape/portrait]

// advance button
reg  [23:0] adv_counter;
wire        advance = (adv_counter != 0);

always @(posedge clk_sys) begin
	reg adv_d;

	adv_d <= adv;
	if (~adv_d & adv) adv_counter <= 24'hfffff;
	if (adv_counter != 0) adv_counter <= adv_counter - 1'd1;
end

always @(*) begin
	orientation = 2'b10;
	SW = {6'h0, advance, autoup};
	JA = 8'hFF;
	JB = 8'hFF;
	BTN = 4'hF;
	AN0 = 8'h80;
	AN1 = 8'h80;
	AN2 = 8'h80;
	AN3 = 8'h80;
	blitter_sc2 = 0;
	sinistar = 0;
	speedball = 0;
	speech_en = 0;

	case (core_mod)
	7'h0: // ROBOTRON
	begin
		BTN = { m_one_player, m_two_players, m_coin1 | m_coin2, reset };
		// Fire Up/Down/Left/Right maps to joystick 1/2/3/4 and keyboard R/F/D/G (MAME style)
		JA  = ~{ m_fireD|m_right2|m_rightB, m_fireC|m_left2|m_leftB, m_fireB|m_down2|m_downB, m_fireA|m_up2|m_upB, m_right, m_left, m_down, m_up };
		JB  = ~{ m_fireD|m_right2|m_rightB, m_fireC|m_left2|m_leftB, m_fireB|m_down2|m_downB, m_fireA|m_up2|m_upB, m_right, m_left, m_down, m_up };
	end
	7'h1: // JOUST
	begin
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = ~{ 5'b00000, m_fireA, m_right, m_left };
		JB  = ~{ 5'b00000, m_fire2A, m_right2, m_left2 };
	end
	7'h2: // SPLAT
	begin
		blitter_sc2 = 1;
		BTN = { m_one_player, m_two_players, m_coin1 | m_coin2, reset };
		// Fire Up/Down/Left/Right maps to joystick 1/2/3/4 and keyboard R/F/D/G (MAME style)
		JA  = ~{ m_fireD|m_right2|m_rightB, m_fireC|m_left2|m_leftB, m_fireB|m_down2|m_downB, m_fireA|m_up2|m_upB, m_right, m_left, m_down, m_up };
		JB  = ~{ m_fireD|m_right2|m_rightB, m_fireC|m_left2|m_leftB, m_fireB|m_down2|m_downB, m_fireA|m_up2|m_upB, m_right, m_left, m_down, m_up };
	end
	7'h3: // BUBBLES
	begin
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = ~{ 4'b0000, m_right, m_left, m_down, m_up };
		JB  = ~{ 4'b0000, m_right2, m_left2, m_down2, m_up2 };
	end
	7'h4: // STARGATE
	begin
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = ~{ m_fireE, m_up, m_down, m_left | m_right, m_fireD, m_fireC, m_fireB, m_fireA };
		JB  = ~{ m_fire2E, m_up2, m_down2, m_left2 | m_right2, m_fire2D, m_fire2C, m_fire2B, m_fire2A };
	end
	7'h5: // ALIENAR
	begin
		BTN = { m_one_player, m_two_players, m_coin1 | m_coin2, reset };
		JA  = ~{ 1'b0, 1'b0, m_fireB, m_fireA, m_right, m_left, m_down, m_up };
		JB  = ~{ 1'b0, 1'b0, m_fire2B, m_fire2A, m_right2, m_left2, m_down2, m_up2 };
	end
	7'h6: // SINISTAR
	begin
		sinistar = 1;
		speech_en = 1;
		orientation = 2'b01;
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = { sin_x, 2'b00, m_right | m_left | m_right2 | m_left2, sin_y, 2'b00, m_up | m_down | m_up2 | m_down2 };
		JB  = { sin_x, 2'b00, m_right | m_left | m_right2 | m_left2, sin_y, 2'b00, m_up | m_down | m_up2 | m_down2 };
	end
	7'h7: // PLAYBALL
	begin
		speech_en = 1;
		orientation = 2'b01;
		BTN = { 2'b00, m_coin1 | m_coin2, reset };
		JA  = ~{ 4'b0000, m_two_players, m_right, m_left, m_one_player };
		JB  = JA;
	end
	7'h8: // LOTTO FUN
	begin
		BTN = { m_one_player | m_fireA, 1'b0, m_coin1 | m_coin2, reset };
		JA  = ~{ 4'b0000, m_right, m_left, m_down, m_up };
		JB  = 8'b11111111;//IN1
	end
	7'h9: // SPEED BALL
	begin
		speedball = 1;
		BTN = { m_two_players, m_one_player, m_coin1 | m_coin2, reset };
		JA  = { m_fireD, m_fireC, m_fireB, m_fireA | mouse_btns0[0], m_right, m_left, m_down, m_up };
		JB  = { m_fire2D, m_fire2C, m_fire2B, m_fire2A | mouse_btns1[0], m_right2, m_left2, m_down2, m_up2 };
		AN0 = {~y_pos0[8], y_pos0[7:1]};
		AN1 = {~x_pos0[8], x_pos0[7:1]};
		AN2 = {~y_pos1[8], y_pos1[7:1]};
		AN3 = {~x_pos1[8], x_pos1[7:1]};
	end
	default: ;
	endcase
end

reg  signed [9:0] x_pos0;
reg  signed [9:0] y_pos0;
reg  [1:0] mouse_btns0;

reg  signed [9:0] x_pos1;
reg  signed [9:0] y_pos1;
reg  [1:0] mouse_btns1;

always @(posedge clk_sys) begin
  if (mouse_strobe) begin
		if (~mouse_idx) begin
			mouse_btns0 <= mouse_flags[1:0];
			x_pos0 <= x_pos0 + mouse_x;
			y_pos0 <= y_pos0 + mouse_y;
		end else begin
			mouse_btns1 <= mouse_flags[1:0];
			x_pos1 <= x_pos1 + mouse_x;
			y_pos1 <= y_pos1 + mouse_y;
		end
  end
end

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_mem;
assign SDRAM_CKE = 1;

wire clk_sys, clk_mem, clk_aud, clk_dac;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_mem),//96
	.c1(clk_sys),//12
	.locked(pll_locked)
	);

pll_aud pll_aud (
	.inclk0(CLOCK_27),
	.c0(clk_aud), // 3.58/4
	.c1(clk_dac)  // 3.58/4*100
);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [19:0] joystick_0;
wire [19:0] joystick_1;
wire        scandoublerD;
wire        no_csync;
wire        ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

wire        mouse_strobe;
wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire  [7:0] mouse_flags;
wire        mouse_idx;

user_io #(
	.STRLEN($size(CONF_STR)>>3))
user_io(
	.clk_sys        ( clk_sys          ),
	.conf_str       ( CONF_STR         ),
	.SPI_CLK        ( SPI_SCK          ),
	.SPI_SS_IO      ( CONF_DATA0       ),
	.SPI_MISO       ( SPI_DO           ),
	.SPI_MOSI       ( SPI_DI           ),
	.buttons        ( buttons          ),
	.switches       ( switches         ),
	.scandoubler_disable (scandoublerD ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         ),
	.core_mod       ( core_mod         ),
	.key_strobe     ( key_strobe       ),
	.key_pressed    ( key_pressed      ),
	.key_code       ( key_code         ),
	.mouse_idx      ( mouse_idx        ),
	.mouse_strobe   ( mouse_strobe     ),
	.mouse_x        ( mouse_x          ),
	.mouse_y        ( mouse_y          ),
	.mouse_flags    ( mouse_flags      ),
	.joystick_0     ( joystick_0       ),
	.joystick_1     ( joystick_1       ),
	.status         ( status           )
	);

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

/*
ROM Structure:
00000-0BFFF main cpu 48k
0C000-0CFFF snd  cpu  4k
0D000-0D3FF CMOS RAM  1k
0D400-0DFFF ---
0E000-11FFF speech   16k
*/

data_io data_io (
	.clk_sys       ( clk_mem      ),
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

reg         port1_req;
wire [15:0] port1_do;
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
	.port1_a       ( downl_addr ),
	.port1_ds      ( 2'b11 ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout[7:4], ioctl_dout[7:4], ioctl_dout[3:0], ioctl_dout[3:0]} ),
	.port1_q       ( port1_do ),

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

// IOCTL address to SDRAM address:
// D000-D3FF (ROM) or 000-3FFF (RAM) -> 1CC00-1CFFF (CMOS), otherwise direct mapping

wire [22:0] downl_addr = 
  ((ioctl_index == 0 && ioctl_addr[22:10] == { 7'h0, 4'hD, 2'b00 }) || ioctl_index == 8'hff) ? { 1'b1, 4'hC, 2'b11, ioctl_addr[9:0] } :
	ioctl_addr[22:0];

assign ioctl_din = { port1_do[11:8], port1_do[3:0] };

always @(posedge clk_mem) begin
	reg        ioctl_wr_last = 0;
	reg  [9:0] cmos_addr;
	reg        ioctl_upl_d;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end

	ioctl_upl_d <= ioctl_upl;
	cmos_addr <= ioctl_addr[9:0];
	if (ioctl_upl) begin
		if (cmos_addr != ioctl_addr[9:0] || !ioctl_upl_d) begin
			port1_req <= ~port1_req;
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

wire  [7:0] audio;
wire [15:0] speech;
wire        hs, vs;
wire        blankn;
wire  [2:0] r,g;
wire  [1:0] b;

robotron_soc robotron_soc (
	.clock       ( clk_sys     ),
	.clock_snd   ( clk_aud     ),
	.vgaRed      ( r           ),
	.vgaGreen    ( g           ),
	.vgaBlue     ( b           ),
	.Hsync       ( hs          ),
	.Vsync       ( vs          ),
	.audio_out   ( audio       ),
	.speech_out  ( speech      ),

	.blitter_sc2 ( blitter_sc2 ),
	.sinistar    ( sinistar    ),
	.speedball   ( speedball   ),
	.pause       ( ioctl_upl   ),
	.BTN         ( BTN         ),
	.SIN_FIRE    ( ~m_fireA & ~m_fire2A ),
	.SIN_BOMB    ( ~m_fireB & ~m_fire2B ),
	.SW          ( SW          ),
	.JA          ( JA          ),
	.JB          ( JB          ),
	.AN0         ( AN0         ),
	.AN1         ( AN1         ),
	.AN2         ( AN2         ),
	.AN3         ( AN3         ),

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
	.dl_addr     ( ioctl_addr[16:0] ),
	.dl_data     ( ioctl_dout ),
	.dl_wr       ( ioctl_wr && ioctl_index == 0 )
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
	.no_csync       ( no_csync         ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            )
	);

   
wire [16:0] audio_aud = {1'b0, audio, 8'd0} + {1'b0, speech};
wire [15:0] audio_mix = speech_en ? audio_aud[16:1] : {audio, 8'd0};
wire [15:0] audio_mix2 = audio_mix >> 3;
  
wire dac_o;
assign AUDIO_L = dac_o;
assign AUDIO_R = dac_o;

dac #(
	.C_bits(16))
dac(
	.clk_i(clk_dac),
	.res_n_i(1),
	.dac_i(audio_mix2),
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

// Common inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_upB, m_downB, m_leftB, m_rightB;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F, m_up4B, m_down4B, m_left4B, m_right4B;
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
	.player1     ( {m_upB, m_downB, m_leftB, m_rightB, 6'd0, m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, 6'd0, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, 6'd0, m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, 6'd0, m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 

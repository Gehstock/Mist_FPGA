module Gaplus_MiST (
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
	"GAPLUS;ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O5,Blend,Off,On;",
	"O8A,Difficulty,Standard,1-Easiest,2,3,4,5,6,7-Hardest;",
	"OBC,Life,3,2,4,5;",
	"ODF,Bonus Life,M0,M1,M2,M3,M4,M5,M6,M7;",
	"OG,Round Advance,Off,On;",
	"OH,Demo Sound,On,Off;",
	"OI,Service Mode,Off,On;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = CLOCK_SD;
assign 		SDRAM_CKE = 1;

wire CLOCK_49, CLOCK_SD, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(CLOCK_49),
	.c1(CLOCK_SD),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [7:0] audio;
wire        hs, vs;
wire [3:0] 	r, g, b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( CLOCK_49     ),
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
wire [14:0] cpu1_rom_addr, cpu2_rom_addr;
wire [15:0] cpu1_rom_do, cpu2_rom_do;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( CLOCK_SD     ),

	// port1 used for main + aux CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b00, cpu1_rom_addr[14:1]} ),
	.cpu1_q        ( cpu1_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : {cpu2_rom_addr[14:1] + 15'h4000} ),
	.cpu2_q        ( cpu2_rom_do ),

	// port2 for graphics
	.port2_req     ( ),
	.port2_ack     ( ),
	.port2_a       ( 15'h7fff),
	.port2_ds      ( ),
	.port2_we      ( ),
	.port2_d       ( ),
	.port2_q       ( ),

	.fg_addr       ( 15'h7fff),
	.fg_q          ( ),
	.sp_addr       ( 15'h7fff),
	.sp_q          ( ),
	.sp_rdy        ( ),
	.bg_addr       ( 15'h7fff),
	.bg_q          ( )
);

// ROM download controller
always @(posedge CLOCK_49) begin
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
always @(posedge CLOCK_49) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire        PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;

wire  [1:0] COIA = 2'b00;
wire  [1:0] COIB = 2'b00;

wire	[2:0]	DIFF = status[10:8];
wire  [1:0] LIFE = status[12:11];
wire  [2:0] EXTD = status[15:13]; 
wire			ADVN = status[16];
wire			DEMO = status[17];
wire        SERV = status[18];


wire  [7:0] DSW0 = {LIFE,COIA,DEMO,1'b0,COIB};
wire  [7:0] DSW1 = {SERV,DIFF,ADVN,EXTD};
wire	[7:0] DSW2 = {6'h0,~SERV,1'b1};
gaplus_top gaplus_top(
	.RESET(reset),
	.MCLK(CLOCK_49),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK(PCLK_EN),
	.POUT(oPIX),
	.SOUT(audio),
	.INP0({m_fireA,m_left,m_down,m_right,m_up}),
	.INP1({m_fire2A,m_left2,m_down2,m_right2,m_up2}),
	.INP2({m_coin1,m_two_players,m_one_player}),									
	.DSW0(DSW0),
	.DSW1(DSW1),
	.DSW2(DSW2),
	.main_cpu_addr(cpu1_rom_addr),
	.main_cpu_do(cpu1_rom_addr[0] ? cpu1_rom_do[15:8] : cpu1_rom_do[7:0]),
	.sub_cpu_addr(cpu2_rom_addr),
	.sub_cpu_do(cpu2_rom_addr[0] ? cpu2_rom_do[15:8] : cpu2_rom_do[7:0])
);

wire  [11:0] oPIX;
hvgen hvgen(
	.PCLK(PCLK_EN),
	.HPOS(HPOS),
	.VPOS(VPOS),
	.iRGB(oPIX),
	.oRGB({b,g,r}),
	.HSYN(hs),
	.VSYN(vs)
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( CLOCK_49         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( {1'b1,status[2]} ),
	.ce_divider		  ( 1'b0             ),
	.blend          ( status[5]        ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (CLOCK_49       ),
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

dac #(.C_bits(16))dac(
	.clk_i(CLOCK_49),
	.res_n_i(1),
	.dac_i({audio,8'h0}),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( CLOCK_49    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( status[2]   ),
	.orientation ( {1'b1, 1'b1}),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
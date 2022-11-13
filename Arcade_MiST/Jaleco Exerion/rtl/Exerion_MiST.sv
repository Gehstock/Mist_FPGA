module Exerion_MiST(
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
	"Exerion;ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire [23:0] dip_sw = ~status[31:8];
wire          rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire           blend = status[5];
wire       joyswap   = status[6];
wire [1:0] orientation = 2'b11;

assign 		LED = ~ioctl_downl;
assign 		SDRAM_CLK = ~clock_40;
assign 		SDRAM_CKE = 1;


wire clock_6, clock_20, clock_40, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_40),//39.935064
	.c1(clock_20),//19.967532
	.c2(clock_6),//3.327922
	.locked(pll_locked)
	);
	
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [31:0] joystick_0;
wire  [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [15:0] audio_l, audio_r;
wire 			hs, vs, cs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire [2:0] 	r, g, b;
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clock_40     ),
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
wire [24:0] bg_ioctl_addr = 16'hFFFF;

wire [14:0] cpu_rom_addr;
wire [15:0] cpu_rom_do;
wire [13:0] spr_rom_addr;
wire [15:0] spr_rom_do;


sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_40     ),

	// port1 used for main + aux CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),
	
	.cpu1_addr     ( ioctl_downl ? 16'hffff : cpu_rom_addr[14:1] ),
	.cpu1_q        ( cpu_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : {spr_rom_addr[13:1] + 15'h3000} ),
	.cpu2_q        ( spr_rom_do),

	// port2 for graphics
	.port2_req     ( port2_req    ),
	.port2_ack     ( ),
	.port2_a       ( bg_ioctl_addr[23:1] ),
	.port2_ds      ( {bg_ioctl_addr[0], ~bg_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( 16'hffff ),
	.sp_q          ( )
);

// ROM download controller
always @(posedge clock_40) begin
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
always @(posedge clock_40) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end


Exerion_top Exerion_top_inst(
	.clkm_20MHZ(clock_20),
	.clkaudio(clock_6),
	.RED(r),
	.GREEN(g),
	.BLUE(b),
	.H_SYNC(hs),
	.V_SYNC(vs),
	.H_BLANK(hb),
	.V_BLANK(vb),
	.RESET_n(~reset),
	.pause(0),
	.CONTROLS(~{m_coin1,m_two_players,m_one_player,m_fireB,m_fireA,m_up,m_down,m_left,m_right}),
	.DIP1(dip_sw[15:8]&8'h7F), //dip switch #1 - filter out table option
	.DIP2(dip_sw[23:16]),
	.audio_l(audio_l),
	.audio_r(audio_r),
	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_addr[0] ? cpu_rom_do[15:8] : cpu_rom_do[7:0]),
	.spr_rom_addr(spr_rom_addr),
	.spr_rom_do(spr_rom_addr[0] ? spr_rom_do[15:8] : spr_rom_do[7:0]),
	.dn_addr(ioctl_addr),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr && !ioctl_index) //& rom_downl
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_40         ),
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
	.ce_divider		 ( 0                ),
	.rotate         ( { orientation[1], rotate } ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);
	
user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clock_40       ),
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
	.status         (status         )
	);

dac #(.C_bits(16))dac_l(
	.clk_i(clock_40),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);
	
dac #(.C_bits(16))dac_r(
	.clk_i(clock_40),
	.res_n_i(1),
	.dac_i(audio_r),
	.dac_o(AUDIO_R)
	);
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_40    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0   		),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);	
endmodule 
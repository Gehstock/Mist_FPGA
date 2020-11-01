module rallyX_mist (
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
	"RALLYX;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];
wire [1:0] orientation = {core_mod[2], core_mod[0]};

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign    SDRAM_CLK = clock_24;
assign    SDRAM_CKE = 1;

wire pll_locked, clock_24, clock_14;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_24), //24.576MHz
	.c1(clock_14),
	.locked(pll_locked)
	);

wire  [6:0] core_mod;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [7:0] audio;
wire        hs, vs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire  [2:0] r, g;
wire  [1:0] b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

reg   [7:0] iDSW1, iDSW2, iCTR1, iCTR2;

always @(*) begin
	iDSW1 = ~status[15:8];
	iDSW2 = ~status[23:16];
	iCTR1 = ~{ m_coin1, m_one_player,  m_up,  m_down,  m_right,  m_left,  m_fireA,  1'b0 };
	iCTR2 = ~{ m_coin2, m_two_players, m_up2, m_down2, m_right2, m_left2, m_fire2A, 1'b0 };

	if (core_mod[0]) begin
		//Jungler, Loco-Motion, Tactician
		iCTR1 = ~{ m_coin1, m_coin2,  m_right, m_left, m_fireA, 1'b0, m_fireB, m_up2 };
		iCTR2 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2A, m_fire2B, m_down2, m_up };
		iDSW1[7] = ~m_down;
	end
	if (core_mod[3]) begin
		//Commando
		iCTR1 = ~{ m_coin1, m_coin2,  m_right, m_left, m_fireB, 2'b00, m_up };
		iCTR2 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2B, m_fire2A, m_down2, m_up };
		iDSW1[7] = ~m_down;
		iDSW1[6] = ~m_fireA;
	end
end

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
reg         port1_req;
reg  [15:0] rom_dout;
reg  [14:0] rom_addr;

data_io data_io(
	.clk_sys       ( clock_24     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);
        
sdram #(.MHZ(24)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_24     ),
        
	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[22:1] ),
	.port1_ds      ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
      
	// CPU
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : {3'b000, rom_addr[14:1] } ),
	.cpu1_q        ( rom_dout  )
);

always @(posedge clock_24) begin
	reg        ioctl_wr_last = 0;
 
	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end
end

fpga_nrx fpga_nrx(
	.RESET(status[0] | buttons[1]),
	.CLK24M(clock_24),
	.CLK14M(clock_14),
	.mod_jungler(core_mod[0]),
	.mod_loco(core_mod[1]),
	.mod_tact(core_mod[2]),
	.mod_comm(core_mod[3]),
	.hsync(hs),
	.vsync(vs),
	.hblank(hb),
	.vblank(vb),
	.r(r),
	.g(g),
	.b(b),
	.cpu_rom_addr(rom_addr),
	.cpu_rom_data(rom_addr[0] ? rom_dout[15:8] : rom_dout[7:0]),
	.SND(audio),
	.DSW1(iDSW1),
	.DSW2(iDSW2),
	.CTR1(iCTR1),
	.CTR2(iCTR2),
	.LAMP(),
	// ROM download
	.ROMCL(clock_24),
	.ROMAD(ioctl_addr[15:0]),
	.ROMDT(ioctl_dout),
	.ROMEN(ioctl_wr)
	);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( clock_24         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,1'b0} : 0 ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	.rotate         ( {orientation[1], rotate} ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);
	
user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         ),
	.core_mod       (core_mod       )
	);

dac #(.C_bits(16))dac(
	.clk_i(core_mod[0] ? clock_14 : clock_24),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_24    ),
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

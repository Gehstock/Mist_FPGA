module Galivan_MiST (
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
	"GALIVAN;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O8,Test mode,Off,On;",
	"O1,Pause,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        pause = status[1];
wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire        service = status[8];

wire        flip;
wire  [1:0] orientation = {flip, 1'b1};

wire  [7:0] j1 = ~{ m_fire1[2], 1'b0, m_fire1[1], m_fire1[0], m_right1, m_left1, m_down1, m_up1 };
wire  [7:0] j2 = ~{ m_fire2[2], 1'b0, m_fire2[1], m_fire2[0], m_right2, m_left2, m_down2, m_up2 };
wire  [7:0] p1 = ~status[23:16]; // dsw1
wire  [7:0] p2 = ~status[31:24]; // dsw2

wire  [7:0] system = ~{ 3'b000, service, m_coin2, m_coin1, m_two_players, m_one_player };

assign 		LED = ~ioctl_downl;
assign 		SDRAM_CLK = clk_ram;
assign 		SDRAM_CKE = 1;

wire clk_sys, clk_ram, pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_ram),
	.c1(clk_sys),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [19:0] joystick_0;
wire [19:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;
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
	.scandoubler_disable (scandoublerD),
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

wire [15:0] cpu1_rom_addr;
wire [15:0] cpu1_rom_do;
wire        cpu1_rom_cs;
wire        cpu1_rom_valid;
wire [15:0] cpu2_rom_addr;
wire [15:0] cpu2_rom_do;
wire        cpu2_rom_cs;
wire        cpu2_rom_valid;

wire [13:0] gfx1_rom_addr;
wire [15:0] gfx1_rom_do;
wire [16:0] gfx2_rom_addr;
wire [15:0] gfx2_rom_do;
wire [15:0] gfx3_rom_addr;
wire [15:0] gfx3_rom_do;
wire        gfx3_rom_ready;

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_dout;

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
	.ioctl_din     ( ioctl_din    ),
	.ioctl_dout    ( ioctl_dout   )
);

reg port1_req, port2_req;
sdram #(96) sdram(
	.*,
	.init_n        ( pll_locked     ),
	.clk           ( clk_ram        ),

	// port1 for main and sound CPU
	.port1_req     ( port1_req      ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( rom_init       ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_cs       ( cpu1_rom_cs    ),
	.cpu1_addr     ( {1'b0, cpu1_rom_addr[15:1]} ),
	.cpu1_q        ( cpu1_rom_do    ),
	.cpu1_valid    ( cpu1_rom_valid ),
	.cpu2_cs       ( cpu2_rom_cs    ),
	.cpu2_addr     ( {1'b1, cpu2_rom_addr[15:1]} ),
	.cpu2_q        ( cpu2_rom_do    ),
	.cpu2_valid    ( cpu2_rom_valid ),

	// port2 for graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( rom_init ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.gfx1_addr      ( 27'he000 + gfx1_rom_addr[13:1] ),
	.gfx1_q         ( gfx1_rom_do ),
	.gfx2_addr      ( 27'h10000 + gfx2_rom_addr[16:1] ),
	.gfx2_q         ( gfx2_rom_do ),
	.gfx3_addr      ( 27'h20000 + gfx3_rom_addr[15:1] ),
	.gfx3_q         ( gfx3_rom_do ),
	.gfx3_ready     ( gfx3_rom_ready )
);

// ROM download controller
always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (rom_init) begin
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
	reset <= status[0] | buttons[1] | ~rom_loaded;
end


wire [15:0] sound;
wire HBlank;
wire HSync;
wire VBlank;
wire VSync;
wire [8:0] hcount, vcount;
reg  [2:0] vred, vgreen;
reg  [1:0] vblue;

wire ce_pix;

video video(
  .clk    ( clk_sys ),
  .ce_pix ( ce_pix  ),
  .hs     ( HSync   ),
  .vs     ( VSync   ),
  .hb     ( HBlank  ),
  .vb     ( VBlank  ),
  .hcount ( hcount  ),
  .vcount ( vcount  ),
  .hoffs  (),
  .voffs  ()
);

wire rom_init = ioctl_downl && (ioctl_index==0);
//wire nvram_init = ioctl_downl && (ioctl_index==8'hFF);

core u_core(
	.reset          ( reset            ),
	.clk_sys        ( clk_sys          ),
	.ce_pix         ( ce_pix           ),
	.pause          ( pause            ),
	.j1             ( j1               ),
	.j2             ( j2               ),
	.p1             ( p1               ),
	.p2             ( p2               ),
	.system         ( system           ),
	.ioctl_index    ( ioctl_index      ),
	.ioctl_download ( rom_init         ),
	.ioctl_addr     ( ioctl_addr       ),
	.ioctl_dout     ( ioctl_dout       ),
	.ioctl_wr       ( ioctl_wr         ),
	.hh             ( hcount           ),
	.vv             ( vcount           ),
	.red            ( vred             ),
	.green          ( vgreen           ),
	.blue           ( vblue            ),
	.vs             ( VSync            ),
	.hb             ( HBlank           ),
	.sound          ( sound            ),
	.hflip          ( flip             ),
	.bg_on          ( 1'b1             ),
	.tx_on          ( 1'b1             ),
	.sp_on          ( 1'b1             ),
	.fdiv           ( 2'b0             ),

	.cpu1_rom_cs    ( cpu1_rom_cs      ),
	.cpu1_rom_addr  ( cpu1_rom_addr    ),
	.cpu1_rom_q     ( cpu1_rom_addr[0] ? cpu1_rom_do[15:8] : cpu1_rom_do[7:0] ),
	.cpu1_rom_valid ( cpu1_rom_valid   ),
	.cpu2_rom_cs    ( cpu2_rom_cs      ),
	.cpu2_rom_addr  ( cpu2_rom_addr    ),
	.cpu2_rom_q     ( cpu2_rom_addr[0] ? cpu2_rom_do[15:8] : cpu2_rom_do[7:0] ),
	.cpu2_rom_valid ( cpu2_rom_valid   ),

	.gfx1_rom_addr  ( gfx1_rom_addr    ),
	.gfx1_rom_q     ( gfx1_rom_addr[0] ? gfx1_rom_do[15:8] : gfx1_rom_do[7:0] ),
	.gfx2_rom_addr  ( gfx2_rom_addr    ),
	.gfx2_rom_q     ( gfx2_rom_addr[0] ? gfx2_rom_do[15:8] : gfx2_rom_do[7:0] ),
	.gfx3_rom_addr  ( gfx3_rom_addr    ),
	.gfx3_rom_q     ( gfx3_rom_addr[0] ? gfx3_rom_do[15:8] : gfx3_rom_do[7:0] ),
	.gfx3_rom_ready ( gfx3_rom_ready   )
);

wire blankn = !(HBlank | VBlank);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? vred : 0   ),
	.G              ( blankn ? vgreen : 0 ),
	.B              ( blankn ? {vblue, vblue[1]} : 0  ),
	.HSync          ( HSync            ),
	.VSync          ( VSync            ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b0             ),
	.rotate         ( { orientation[1], rotate } ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

wire audio_out;
assign AUDIO_L = audio_out;
assign AUDIO_R = audio_out;

dac #(.C_bits(16))dac(
	.clk_i(clk_sys),
	.res_n_i(1'b1),
	.dac_i({~sound[15], sound[14:0]}),
	.dac_o(audio_out)
	);

wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2;

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
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} )
);

endmodule


module BankPanic_MiST(
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

localparam CONF_STR = {
	"BANKP;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire  [7:0] dsw = status[15:8];
wire  [1:0] orientation = {core_mod[0] & dsw[0], core_mod[0]};

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_mem, pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_mem),//93
	.c1(clk_sys),//31
	.locked(pll_locked)
	);
assign SDRAM_CLK = clk_mem;
assign SDRAM_CKE = 1;

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

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
	.no_csync       (no_csync       ),
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

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

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire [15:0] cpu_rom_addr;
wire        cpu_rom_cs;
wire [15:0] cpu_rom_data;
wire [13:0] bg_rom_addr;
wire [15:0] bg_rom_data;
wire [13:0] sp_rom_addr;
wire [31:0] sp_rom_data;
reg         port1_req, port2_req;

// ROM download controller
always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

sdram #(93) sdram
(
  .*,
  .init_n        ( pll_locked    ),
  .clk           ( clk_mem       ),

  // Bank 0-1 ops
  .port1_req     ( port1_req    ),
  .port1_ack     ( ),
  .port1_a       ( ioctl_addr[23:1] ),
  .port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
  .port1_we      ( ioctl_downl ),
  .port1_d       ( {ioctl_dout, ioctl_dout} ),
  .port1_q       ( ),

  // Main CPU
  .cpu1_addr     ( cpu_rom_addr[15:1] ),
  .cpu1_cs       ( cpu_rom_cs ),
  .cpu1_q        ( cpu_rom_data ),

  .cpu2_addr     ( bg_rom_addr[13:1] + 19'h8000 ),
  .cpu2_q        ( bg_rom_data ),

  // Bank 2-3 ops
  .port2_req     ( port2_req    ),
  .port2_ack     ( ),
  .port2_a       ( ioctl_addr[23:1] ),
  .port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
  .port2_we      ( ioctl_downl ),
  .port2_d       ( {ioctl_dout, ioctl_dout} ),
  .port2_q       ( ),

  .sp_addr       ( sp_rom_addr + 17'h5000 ),
  .sp_q          ( sp_rom_data )
);

wire [15:0] audio;
wire        hs, vs, cs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire  [2:0] g, r;
wire  [1:0] b;

wire  [7:0] p1 = { m_fireB, m_fireD, m_coin1, m_fireA, core_mod[0] ? {1'b0, m_down, 1'b0, m_up} : {m_left, 1'b0, m_right, 1'b0} };
wire  [7:0] p2 = { m_fire2B, m_two_players, m_one_player, m_fire2A, core_mod[0] ? {1'b0, m_down2, 1'b0, m_up2} : {m_left2, 1'b0, m_right2, 1'b0} };
wire  [7:0] p3 = { 4'd0, m_fireE, m_coin2, m_fire2C, m_fireC };

core u_core(
  .reset          ( reset            ),
  .clk_sys        ( clk_sys          ),
  .p1             ( p1               ),
  .p2             ( p2               ),
  .p3             ( p3               ),
  .dsw            ( dsw              ),
  .ioctl_index    ( ioctl_index      ),
  .ioctl_download ( ioctl_downl      ),
  .ioctl_addr     ( ioctl_addr       ),
  .ioctl_dout     ( ioctl_dout       ),
  .ioctl_wr       ( ioctl_wr         ),
  .red            ( r                ),
  .green          ( g                ),
  .blue           ( b                ),
  .vs             ( vs               ),
  .vb             ( vb               ),
  .hs             ( hs               ),
  .hb             ( hb               ),
  .ce_pix         (                  ),
  .sound          ( audio            ),
  .hoffs          ( 0                ),
  .cpu_rom_addr   ( cpu_rom_addr     ),
  .cpu_rom_cs     ( cpu_rom_cs       ),
  .cpu_rom_data   ( cpu_rom_addr[0] ? cpu_rom_data[15:8] : cpu_rom_data[7:0] ),
  .bg_rom_addr    ( bg_rom_addr      ),
  .bg_rom_data    ( bg_rom_addr[0] ? bg_rom_data[15:8] : bg_rom_data[7:0] ),
  .sp_rom_addr    ( sp_rom_addr      ),
  .sp_rom_data    ( sp_rom_data      )
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,b[1]} : 0 ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 0                ),
	.rotate         ( { orientation[1], rotate } ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

dac #(
	.C_bits(16))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);


// General controls
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
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

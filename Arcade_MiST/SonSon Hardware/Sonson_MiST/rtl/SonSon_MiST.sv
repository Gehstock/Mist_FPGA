/***************************************************************************
Son Son memory map (preliminary)
driver by Mirko Buffoni
MAIN CPU:
0000-0fff RAM
1000-13ff Video RAM
1400-17ff Color RAM
2020-207f Sprites
4000-ffff ROM
read:
3002      IN0
3003      IN1
3004      IN2
3005      DSW0
3006      DSW1
write:
3000      horizontal scroll
3008      watchdog reset
3018      flipscreen (inverted)
3010      command for the audio CPU
3019      trigger FIRQ on audio CPU
SOUND CPU:
0000-07ff RAM
e000-ffff ROM
read:
a000      command from the main CPU
write:
2000      8910 #1 control
2001      8910 #1 write
4000      8910 #2 control
4001      8910 #2 write
TODO:
- Fix Service Mode Output Test: press p1/p2 shot to insert coin
- Flip Screen DIP is noted in service manual and added to DIP LOCATIONS, but not working.
***************************************************************************/
module SonSon_MiST(
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
	"SONSON;ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"O6,Freeze,Off,On;",
	"O7,Flip,Off,On;",
	"O8,Test,Off,On;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       freeze   = status[6];
wire       flip   = status[7];
wire       test   = status[8];

assign LED = ~ioctl_downl;
assign SDRAM_CKE = 1; 
assign SDRAM_CLK = clk_sd;
wire clk_sys, clk_vid, clk_sd;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),//20
	.c1(clk_vid),//40
	.c2(clk_sd),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire [15:0] cpu_rom_addr;	
//wire [15:0] rom_addr;
wire [15:0] rom_do;

wire [12:0] tile_rom_addr;	
//wire [12:0] tile_addr;
wire [15:0] tile_do;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_sd      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sd      ),

	// port1 used for main + sound CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, cpu_rom_addr[15:1]} ),
	.cpu1_q        ( rom_do ),
	.snd_addr     ( ioctl_downl ? 16'hffff : (16'h6000 + tile_rom_addr[12:1]) ),
	.snd_q        ( tile_do ),

	// port2 for sprite graphics
	.port2_req     ( ),
	.port2_ack     ( ),
	.port2_a       ( ),
	.port2_ds      ( ),
	.port2_we      ( ),
	.port2_d       ( ),
	.port2_q       ( )
);

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
	// async clock domain crossing here (clk_snd -> clk_sys)	
end

// reset signal generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	reg [15:0] reset_count;
	ioctl_downlD <= ioctl_downl;

	if (status[0] | buttons[1] | ~rom_loaded) reset_count <= 16'hffff;
	else if (reset_count != 0) reset_count <= reset_count - 1'd1;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= reset_count != 16'h0000;

end

wire [11:0] audio;
wire        hs, vs, hb, vb;
wire        blankn = ~(hb | vb);
wire  [3:0] g,b,r;
wire			vma;
target_top target_top(
	.clk_sys(clk_sys),
	.clk_vid(clk_vid),
	.reset_in(reset),
	.vma(vma),
	.snd_l(),
	.snd_r(),
	.vid_hs(hs),
	.vid_vs(vs),
	.vid_hb(hb),
	.vid_vb(vb),
	.vid_r(r),
	.vid_g(g),
	.vid_b(b),
	.inputs_p1(~{2'b00,m_down,m_up,m_right,m_left,1'b0,m_fireC}),
	.inputs_p2(~{2'b00,m_down2,m_up2,m_right2,m_left2,1'b0,m_fire2C}),
	.inputs_sys(~{2'b00,m_coin2,m_coin1,2'b00,m_two_players,m_one_player}),
	.inputs_dip1(~{flip,test,"011111"}),
	.inputs_dip2(~{freeze,"1111111"}),
	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_addr[0] ? rom_do[15:8] : rom_do[7:0]),
	.tile_rom_addr(tile_rom_addr),
	.tile_rom_do(tile_do)
  ); 

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
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
	.rotate         ( { 1'b1, rotate } ),
	.ce_divider     ( 1'b0             ),
	.scandoubler_disable( 1),//                             scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

wire dac_o;
assign AUDIO_L = dac_o;
assign AUDIO_R = dac_o;

dac #(
	.C_bits(12))
dac(
	.clk_i(clk_sys),
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
	.orientation ( 2'b10       ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

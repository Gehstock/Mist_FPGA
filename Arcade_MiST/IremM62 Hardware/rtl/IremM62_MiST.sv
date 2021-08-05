module IremM62_MiST(
	output        LED,
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        AUDIO_L,
	output        AUDIO_R,
	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         SPI_SS4,
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

`define CORE_NAME "LDRUN"
wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O2,Rotate Controls,Off,On;",
	"O1,Video Timings,Original,PAL 50Hz;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"DIP;",
	"O7,Service,Off,On;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       palmode   = status[1];
wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       service   = status[7];
wire       joyswap   = status[6];

reg  [1:0] orientation = 2'b10;
reg        oneplayer;
wire [7:0] DSW1 = {/*coinage*/4'hf, ~status[11:8]};

always @(*) begin
  orientation = 2'b10;
  oneplayer = 1;

  case (core_mod)
  7'h3: oneplayer = 0; // LDRUN4
  7'h6: orientation = 2'b11; // BATTROAD
  7'hB: orientation = 2'b01; // YOUJYUDN
  default: ;
  endcase
end

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_sd;
assign SDRAM_CKE = 1; 

wire clk_sys, clk_vid, clk_sd, clk_aud, clk_dac;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sd),
	.c1(clk_sys),
	.c2(clk_vid),
	.locked(pll_locked)
	);

pll_aud pll_aud(
	.inclk0(CLOCK_27),
	.c0(clk_aud),
	.c1(clk_dac)
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
	.STRLEN(($size(CONF_STR)>>3)),
	.ROM_DIRECT_UPLOAD(1'b1))
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

wire [16:0] rom_addr;
wire [15:0] rom_do;

wire [17:0] snd_addr;
wire [15:0] snd_rom_addr;
wire [15:0] snd_do;
wire        snd_vma;

wire [14:0] chr1_addr;
wire [31:0] chr1_do;
wire [15:0] sp_addr;
wire [31:0] sp_do;
wire [14:0] chr2_addr;
wire [31:0] chr2_do;

/* ROM structure
00000-1FFFF CPU1 128k
20000-2FFFF CPU2  64k
30000-4FFFF GFX1 128k
50000-8FFFF GFX2 256k

90000-9FFFF GFX3  64k
A0000-A02FF spr_color_proms 3*256b
A0300-A05FF chr_color_proms 3*256b
A0600-A08FF fg_color_proms  3*256b
A0900-A091F spr_height_prom 32b
*/

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io #(.ROM_DIRECT_UPLOAD(1'b1)) data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.clkref_n      ( ~clkref      ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [24:0] sp_ioctl_addr = ioctl_addr - 20'h30000;
wire clkref;

reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sd       ),
	.clkref        ( clkref       ),

	// port1 used for main + sound CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : {1'b0, rom_addr[16:1]} ),
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( ioctl_downl ? 17'h1ffff : snd_addr[17:1] ),
	.cpu2_q        ( snd_do ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( sp_ioctl_addr[23:1] ),
	.port2_ds      ( {sp_ioctl_addr[0], ~sp_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.chr1_addr     ( chr1_addr ),
	.chr1_q        ( chr1_do   ),
	.chr2_addr     ( 17'h18000 + chr2_addr ),
	.chr2_q        ( chr2_do   ),
	.sp_addr       ( 16'h8000 + sp_addr ),
	.sp_q          ( sp_do     )
);

// ROM download controller
always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;
	reg        snd_vma_r, snd_vma_r2;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			if (ioctl_addr >= 20'h30000) port2_req <= ~port2_req;
		end
	end

	// async clock domain crossing here (clk_snd -> clk_sys)
	snd_vma_r <= snd_vma; snd_vma_r2 <= snd_vma_r;
	if (snd_vma_r2) snd_addr <= snd_rom_addr + 18'h20000;
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
wire        hs, vs;
wire        blankn = 1'b1;//todo
wire  [3:0] g,b,r;

target_top target_top(
	.clock_sys(clk_sys),//24 MHz
	.vid_clk_en(clkref),
	.clk_aud(clk_aud),//0.895MHz
	.reset_in(reset),
	.hwsel(core_mod),
	.palmode(palmode),
	.audio_out(audio),
	.switches_i(DSW1),
	.usr_coin1(m_coin1),
	.usr_coin2(m_coin2),
	.usr_service(service),
	.usr_start1(m_one_player),
	.usr_start2(m_two_players),
	.p1_up(m_up),
	.p1_dw(m_down),
	.p1_lt(m_left),
	.p1_rt(m_right),
	.p1_f1(m_fireA),
	.p1_f2(m_fireB),
	.p2_up(m_up2),
	.p2_dw(m_down2),
	.p2_lt(m_left2),
	.p2_rt(m_right2),
	.p2_f1(m_fire2A),
	.p2_f2(m_fire2B),
	.VGA_VS(vs),
	.VGA_HS(hs),
	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),

	.dl_addr(ioctl_addr - 20'hA0000),
	.dl_data(ioctl_dout),
	.dl_wr(ioctl_wr),

	.cpu_rom_addr(rom_addr),
	.cpu_rom_do( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_addr[0] ? snd_do[15:8] : snd_do[7:0]),
	.snd_vma(snd_vma),
	.gfx1_addr(chr1_addr),
	.gfx1_do(chr1_do),
	.gfx3_addr(chr2_addr),
	.gfx3_do(chr2_do),
	.gfx2_addr(sp_addr),
	.gfx2_do(sp_do)
  );

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( clk_vid          ),
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
	.rotate         ( { orientation[1], rotate } ),
	.ce_divider     ( 1'b1             ),
	.scandoubler_disable( scandoublerD ),
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
	.clk_i(clk_dac),
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
	.joyswap     ( joyswap     ),
	.oneplayer   ( oneplayer   ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

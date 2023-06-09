import m92_pkg::*;

module IremM92_MiST(
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

`include "build_id.v" 
//`define DEBUG 1
`define CORE_NAME "BMASTER"

wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O3,Rotate Controls,Off,On;",
	"O45,Scanlines,Off,25%,50%,75%;",
	"O6,Swap Joystick,Off,On;",
	//"O7,Blending,Off,On;",
	"O8,Pause,Off,On;",
`ifdef DEBUG
	"O9,Layer A,On,Off;",
	"OA,Layer B,On,Off;",
	"OB,Layer C,On,Off;",
	"OC,FM Enable,On,Off;",
`endif
	//"OD,Audio Filters,On,Off;",
	"DIP;",
`ifndef NO_EEPROM
	"R8192,Save EEPROM;",
`endif
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire        rotate    = status[3];
wire  [1:0] scanlines = status[5:4];
wire        joyswap   = status[6];
wire        blend     = 0;//status[7];
wire        system_pause = status[8];
wire  [2:0] dbg_en_layers = ~status[11:9];
wire        dbg_fm_en = ~status[12];
wire        dbg_sprite_freeze = 0;
wire        filters = 0;//~status[13];
wire  [1:0] orientation = {flipped, core_mod[0]};
reg         oneplayer = 0;
wire [15:0] dip_sw = status[31:16];

assign LED = ~ioctl_downl;
assign SDRAM_CKE = 1; 

wire CLK_120M, CLK_40M;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(SDRAM_CLK),
	.c1(CLK_120M),
	.c2(CLK_40M),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire [15:0] joystick_2;
wire [15:0] joystick_3;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

wire  [9:0] conf_str_addr;
wire  [7:0] conf_str_char;

always @(posedge CLK_40M) 
	conf_str_char <= CONF_STR[(($size(CONF_STR)>>3) - conf_str_addr - 1)<<3 +:8];

user_io #(
	//.STRLEN(($size(CONF_STR)>>3)),
	.ROM_DIRECT_UPLOAD(1'b1))
user_io(
	.clk_sys        (CLK_40M        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.conf_addr      (conf_str_addr  ),
	.conf_chr       (conf_str_char  ),
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
	.joystick_2     (joystick_2     ),
	.joystick_3     (joystick_3     ),
	.status         (status         )
	);

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io #(.ROM_DIRECT_UPLOAD(1'b1)) data_io(
	.clk_sys       ( CLK_40M      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.clkref_n      ( 1'b0         ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   ),
	.ioctl_din     ( ioctl_din    )
);

// reset signal generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge CLK_40M) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	reset <= 0;
	if (status[0] | buttons[1] | ~rom_loaded) reset <= 1;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
end

wire        sdr_vram_req;
wire [24:0] sdr_vram_addr;
wire [31:0] sdr_vram_data;

wire [63:0] sdr_sprite_dout;
wire [24:0] sdr_sprite_addr;
wire sdr_sprite_req, sdr_sprite_ack;
    
wire [31:0] sdr_bg_data_a;
wire [24:0] sdr_bg_addr_a;
wire sdr_bg_req_a, sdr_bg_ack_a;

wire [31:0] sdr_bg_data_b;
wire [24:0] sdr_bg_addr_b;
wire sdr_bg_req_b, sdr_bg_ack_b;

wire [31:0] sdr_bg_data_c;
wire [24:0] sdr_bg_addr_c;
wire sdr_bg_req_c, sdr_bg_ack_c;

wire [15:0] sdr_cpu_dout, sdr_cpu_din;
wire [24:0] sdr_cpu_addr;
wire        sdr_cpu_req, sdr_cpu_ack;
wire  [1:0] sdr_cpu_wr_sel;

wire [15:0] sdr_audio_cpu_dout, sdr_audio_cpu_din;
wire [24:0] sdr_audio_cpu_addr;
wire        sdr_audio_cpu_req, sdr_audio_cpu_ack;
wire  [1:0] sdr_audio_cpu_wr_sel;
            
wire [24:0] sdr_rom_addr;
wire [15:0] sdr_rom_data;
wire  [1:0] sdr_rom_be;
wire        sdr_rom_req;
wire        sdr_rom_ack;

wire [24:0] sample_rom_addr;
wire [63:0] sample_rom_dout;
wire        sample_rom_req;
wire        sample_rom_ack;

wire sdr_rom_write = ioctl_downl && (ioctl_index == 0);

wire [19:0] bram_addr;
wire [7:0] bram_data;
wire [3:0] bram_cs;
wire bram_wr;

board_cfg_t board_cfg;
sdram_4w_cl3 #(120) sdram
(
  .*,
  .init_n        ( pll_locked    ),
  .clk           ( CLK_120M      ),

  // Bank 0-1 ops
  .port1_a       ( sdr_rom_addr[24:1] ),
  .port1_req     ( sdr_rom_req   ),
  .port1_ack     ( sdr_rom_ack   ),
  .port1_we      ( sdr_rom_write ),
  .port1_ds      ( sdr_rom_be    ),
  .port1_d       ( sdr_rom_data  ),
  .port1_q       ( sdr_rom_ack   ),

  // Main CPU
  .cpu1_rom_addr ( ),
  .cpu1_rom_cs   ( ),
  .cpu1_rom_q    ( ),
  .cpu1_rom_valid( ),

  .cpu1_ram_req  ( sdr_cpu_req   ),
  .cpu1_ram_ack  ( sdr_cpu_ack   ),
  .cpu1_ram_addr ( sdr_cpu_addr[24:1] ),
  .cpu1_ram_we   ( |sdr_cpu_wr_sel ),
  .cpu1_ram_d    ( sdr_cpu_din   ),
  .cpu1_ram_q    ( sdr_cpu_dout  ),
  .cpu1_ram_ds   ( |sdr_cpu_wr_sel ? sdr_cpu_wr_sel : 2'b11 ),

  // Audio CPU
  .cpu2_ram_req  ( sdr_audio_cpu_req   ),
  .cpu2_ram_ack  ( sdr_audio_cpu_ack   ),
  .cpu2_ram_addr ( sdr_audio_cpu_addr[24:1] ),
  .cpu2_ram_we   ( |sdr_audio_cpu_wr_sel ),
  .cpu2_ram_d    ( sdr_audio_cpu_din   ),
  .cpu2_ram_q    ( sdr_audio_cpu_dout  ),
  .cpu2_ram_ds   ( |sdr_audio_cpu_wr_sel ? sdr_audio_cpu_wr_sel : 2'b11 ),
  
  // VRAM
  .vram_addr     ( sdr_vram_addr[24:1] ),
  .vram_req      ( sdr_vram_req ),
  .vram_q        ( sdr_vram_data ),
  .vram_ack      (  ),

  // Bank 2-3 ops
  .port2_a       ( sdr_rom_addr[24:1] ),
  .port2_req     ( sdr_rom_req     ),
  .port2_ack     ( sdr_rom_ack     ),
  .port2_we      ( sdr_rom_write   ),
  .port2_ds      ( sdr_rom_be      ),
  .port2_d       ( sdr_rom_data    ),
  .port2_q       ( sdr_rom_ack     ),

  .gfx1_req      ( sdr_bg_req_a    ),
  .gfx1_ack      ( sdr_bg_ack_a    ),
  .gfx1_addr     ( sdr_bg_addr_a[24:1] ),
  .gfx1_q        ( sdr_bg_data_a   ),
  
  .gfx2_req      ( sdr_bg_req_b    ),
  .gfx2_ack      ( sdr_bg_ack_b    ),
  .gfx2_addr     ( sdr_bg_addr_b[24:1] ),
  .gfx2_q        ( sdr_bg_data_b   ),

  .gfx3_req      ( sdr_bg_req_c    ),
  .gfx3_ack      ( sdr_bg_ack_c    ),
  .gfx3_addr     ( sdr_bg_addr_c[24:1] ),
  .gfx3_q        ( sdr_bg_data_c   ),

  .sample_addr   ( {sample_rom_addr[24:3], 2'b00} ),
  .sample_q      ( sample_rom_dout ),
  .sample_req    ( sample_rom_req  ),
  .sample_ack    ( sample_rom_ack  ),

  .sp_addr       ( sdr_sprite_addr[24:1] ),
  .sp_req        ( sdr_sprite_req  ),
  .sp_ack        ( sdr_sprite_ack  ),
  .sp_q          ( sdr_sprite_dout )
);
 
rom_loader rom_loader(
    .sys_clk(CLK_40M),

    .ioctl_downl(ioctl_downl),
    .ioctl_wr(ioctl_wr && !ioctl_index),
    .ioctl_data(ioctl_dout[7:0]),

    .ioctl_wait(),

    .sdr_addr(sdr_rom_addr),
    .sdr_data(sdr_rom_data),
    .sdr_be(sdr_rom_be),
    .sdr_req(sdr_rom_req),
    .sdr_ack(sdr_rom_ack),

    .bram_addr(bram_addr),
    .bram_data(bram_data),
    .bram_cs(bram_cs),
    .bram_wr(bram_wr),

    .board_cfg(board_cfg)
);

wire [15:0] ch_left, ch_right;
wire [7:0] R, G, B;
wire HBlank, VBlank, HSync, VSync;
wire ce_pix;
wire flipped;

m92 m92(
    .clk_sys(CLK_40M),
    .ce_pix(ce_pix),
    .flipped(flipped),
    .reset_n(~reset),
    .HBlank(HBlank),
    .VBlank(VBlank),
    .HSync(HSync),
    .VSync(VSync),
    .R(R),
    .G(G),
    .B(B),
    .AUDIO_L(ch_left),
    .AUDIO_R(ch_right),

    .board_cfg(board_cfg),

    .coin({2'd0, m_coin2, m_coin1}),

    .start_buttons({m_four_players, m_three_players, m_two_players, m_one_player}),

    .p1_input({m_fire1[5:0], m_up1, m_down1, m_left1, m_right1}),
    .p2_input({m_fire2[5:0], m_up2, m_down2, m_left2, m_right2}),
    .p3_input({m_fire3[5:0], m_up3, m_down3, m_left3, m_right3}),
    .p4_input({m_fire4[5:0], m_up4, m_down4, m_left4, m_right4}),

    .dip_sw(dip_sw),

    .sdr_sprite_addr(sdr_sprite_addr),
    .sdr_sprite_dout(sdr_sprite_dout),
    .sdr_sprite_req(sdr_sprite_req),
    .sdr_sprite_ack(sdr_sprite_ack),

    .sdr_bg_data_a(sdr_bg_data_a),
    .sdr_bg_addr_a(sdr_bg_addr_a),
    .sdr_bg_req_a(sdr_bg_req_a),
    .sdr_bg_ack_a(sdr_bg_ack_a),

    .sdr_bg_data_b(sdr_bg_data_b),
    .sdr_bg_addr_b(sdr_bg_addr_b),
    .sdr_bg_req_b(sdr_bg_req_b),
    .sdr_bg_ack_b(sdr_bg_ack_b),

    .sdr_bg_data_c(sdr_bg_data_c),
    .sdr_bg_addr_c(sdr_bg_addr_c),
    .sdr_bg_req_c(sdr_bg_req_c),
    .sdr_bg_ack_c(sdr_bg_ack_c),

    .sdr_cpu_dout(sdr_cpu_dout),
    .sdr_cpu_din(sdr_cpu_din),
    .sdr_cpu_addr(sdr_cpu_addr),
    .sdr_cpu_req(sdr_cpu_req),
    .sdr_cpu_ack(sdr_cpu_ack),
    .sdr_cpu_wr_sel(sdr_cpu_wr_sel),
	.sdr_vram_req(sdr_vram_req),
    .sdr_vram_addr(sdr_vram_addr),
	.sdr_vram_data(sdr_vram_data),

    .sdr_audio_cpu_dout(sdr_audio_cpu_dout),
    .sdr_audio_cpu_din(sdr_audio_cpu_din),
    .sdr_audio_cpu_addr(sdr_audio_cpu_addr),
    .sdr_audio_cpu_req(sdr_audio_cpu_req),
    .sdr_audio_cpu_ack(sdr_audio_cpu_ack),
    .sdr_audio_cpu_wr_sel(sdr_audio_cpu_wr_sel),

    .sdr_audio_addr(sample_rom_addr),
    .sdr_audio_dout(sample_rom_dout),
    .sdr_audio_req(sample_rom_req),
    .sdr_audio_ack(sample_rom_ack),

    .clk_bram(CLK_40M),
    .bram_addr(bram_addr),
    .bram_data(bram_data),
    .bram_cs(bram_cs),
    .bram_wr(bram_wr),

    .ioctl_download(ioctl_downl && ioctl_index == 8'hFF),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .ioctl_upload(ioctl_upl && ioctl_index == 8'hFF),
    .ioctl_din(ioctl_din),
`ifdef M72_DEBUG
    .pause_rq(system_pause | debug_stall),
`else
    .pause_rq(system_pause),
`endif
    .dbg_en_layers(dbg_en_layers),
    .dbg_solid_sprites(),
    .sprite_freeze(dbg_sprite_freeze),
    .dbg_fm_en(dbg_fm_en),
    .en_audio_filters(filters)
);

mist_video #(.COLOR_DEPTH(6), .SD_HCNT_WIDTH(10), .USE_BLANKS(1)) mist_video(
	.clk_sys        ( CLK_40M          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( R[7:2]           ),
	.G              ( G[7:2]           ),
	.B              ( B[7:2]           ),
	.HBlank         ( HBlank           ),
	.VBlank         ( VBlank           ),
	.HSync          ( HSync            ),
	.VSync          ( VSync            ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( { orientation[1], rotate } ),
	.ce_divider     ( 3'd2             ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

dac #(
	.C_bits(16))
dacl(
	.clk_i(CLK_40M),
	.res_n_i(1),
	.dac_i({~ch_left[15], ch_left[14:0]}),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(16))
dacr(
	.clk_i(CLK_40M),
	.res_n_i(1),
	.dac_i({~ch_right[15], ch_right[14:0]}),
	.dac_o(AUDIO_R)
	);

wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_up4B, m_down4B, m_left4B, m_right4B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2, m_fire3, m_fire4;

arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( CLK_40M     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joystick_2  ( joystick_2  ),
	.joystick_3  ( joystick_3  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( oneplayer   ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, m_fire3, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, m_fire4, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 

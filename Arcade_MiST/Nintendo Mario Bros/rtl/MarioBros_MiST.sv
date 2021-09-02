module MarioBros_MiST(
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


`include "rtl\build_id.v" 

localparam CONF_STR = {
	"MARIO;ROM;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
//	"O6,Service,Off,On;",
   "O7A,Analogue Sound Vol,100%,Off,10%,20%,30%,40%,50%,60%,70%,80%,90%,;",

	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = ~clk_sys;
assign 		SDRAM_CKE = 1;

wire clk_sys, clk_sd, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_sd),//96
	.c1(clk_sys),//48
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire  [15:0] audio;
wire        hs_n, vs_n;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire [2:0] 	r, g;
wire [1:0] 	b;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
reg         port1_req, port2_req;
reg  [23:0] port1_a, port2_a;
wire [15:0] cpu_rom_addr;
wire [15:0] cpu_rom_do;
wire [12:0] snd_rom_addr;
wire [15:0] snd_rom_do;

data_io #(.ROM_DIRECT_UPLOAD(0)) data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sys      ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : cpu_rom_addr[15:1] ),
	.cpu1_q        ( cpu_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 15'h7fff : snd_rom_addr[12:1] ),
	.cpu2_q        ( snd_rom_do ),

	// port2 for sound board
	.port2_req     ( ),
	.port2_ack     ( ),
	.port2_a       ( 15'h7fff ),
	.port2_ds      ( ),
	.port2_we      ( ),
	.port2_d       ( ),
	.port2_q       ( ),

	.sp_addr       ( 15'h7fff ),
	.sp_q          (  )
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
end

// reset signal generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	reg [15:0] reset_count;
	ioctl_downlD <= ioctl_downl;

	// generate a second reset signal - needed for some reason
	if (status[0] | buttons[1] | ~rom_loaded) reset_count <= 16'hffff;
	else if (reset_count != 0) reset_count <= reset_count - 1'd1;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded | (reset_count == 16'h0001);
end
	
mario_top mario_top(
   .I_CLK_48M(clk_sys),
	.I_RESETn(~reset),
   .I_ANLG_VOL(status[11:8]),
   .I_SW1(m_sw1),
   .I_SW2(m_sw2),
   .I_DIPSW(8'b0_000_00_00),//Upright,Coins,Coins,Coins,Bonus,Bonus,Player,Player
	.O_VGA_R(r),
	.O_VGA_G(g),
	.O_VGA_B(b),
	.O_HBLANK(hb),
	.O_VBLANK(vb),
	.O_VGA_HSYNCn(hs_n),
	.O_VGA_VSYNCn(vs_n),
	.O_SOUND_DAT(audio),
	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_addr[0] ? cpu_rom_do[15:8] : cpu_rom_do[7:0]),
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_do)
);

mist_video #(.COLOR_DEPTH(3),.SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? {b[0], b} : 0),
	.HSync(~hs_n),
	.VSync(~vs_n),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b1),
	.blend(status[5]),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.ypbpr(ypbpr)
	);

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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.C_bits(16))
dac(
	.clk_i(clk_sys),
	.res_n_i(1'b1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

wire [7:0]m_sw1={~status[6],~{m_two_players},~{m_one_player},~m_fireC,1'b1,1'b1,~m_left,~m_right};
wire [7:0]m_sw2={1'b1,1'b1,~{m_coin1},~m_fire2C,1'b1,1'b1,~m_left2,~m_right2};
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe; 
arcade_inputs inputs (
        .clk         ( clk_sys     ),
        .key_strobe  ( key_strobe  ),
        .key_pressed ( key_pressed ),
        .key_code    ( key_code    ),
        .joystick_0  ( joystick_0  ),
        .joystick_1  ( joystick_1  ),
        .rotate      ( 1'b0        ),
        .orientation ( 2'b10       ),
        .joyswap     ( 1'b0        ),
        .oneplayer   ( 1'b1        ),
        .controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
        .player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
        .player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);


endmodule

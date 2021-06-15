module Supervision_MiST(
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
	"SVISION;bin;",
//	"O34,Scanlines,Off,25%,50%,75%;",
//	"O5,Blending,Off,On;",
	"O6,Joyswap,Off,On;",
	"O8,Screen Color,Green,White;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = ~ioctl_downl;
assign SDRAM_CLK = ~clk_sys;
assign SDRAM_CKE = 1;

wire clk_sys, clk_vid, clk_cpu, pll_locked;
pll1 pll1(
	.inclk0(CLOCK_27),
	.c0(clk_sys),//50
	.c1(clk_cpu),// 4
	.locked(pll_locked)
	);
	
pll2 pll2(
	.inclk0(CLOCK_27),
	.c0(clk_vid)// 25.175
	);	

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire			ypbpr;
wire			scandoublerD;
wire  [3:0] audio_ch1, audio_ch2;
wire        hs, vs, hb, vb;
wire			blankn = ~(hb | vb);
wire [7:0] 	r, g, b;
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;
wire [31:0] joystick_0, joystick_1;
wire [15:0] rom_addr;
wire [15:0] rom_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

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

reg port1_req;
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

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, rom_addr[15:1]}),
	.cpu1_q        ( rom_do )
);

always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
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
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

Supervision_Top Supervision_Top(
	.clk_sys(clk_sys),
	.clk_vid(clk_vid),
	.clk_cpu(clk_cpu),
	.reset(reset),
	.hsync(hs),
	.vsync(vs),
	.hblank(hb),
	.vblank(vb),
	.white(status[8]),
	.red(r),
	.green(g),
	.blue(b),
	.joystick({m_fireA, m_fireB, m_fireC, m_fireD, m_up, m_down, m_left, m_right}),
	.audio_ch1(audio_ch1),
	.audio_ch2(audio_ch2),	
	.cpu_rom_addr(rom_addr),
	.cpu_rom_data(rom_addr[0] ? rom_do[15:8] : rom_do[7:0])
);
	
mist_video #(.COLOR_DEPTH(6),.SD_HCNT_WIDTH(9)) mist_video(
	.clk_sys(clk_vid),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r[7:2] : 0),
	.G(blankn ? g[7:2] : 0),
	.B(blankn ? b[7:2] : 0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b0),
	.blend(status[5]),
	.scandoubler_disable(1'b1),//scandoublerD),
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
	.C_bits(4))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_ch1),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(4))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_ch2),
	.dac_o(AUDIO_R)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joyswap     ( status[6]     ),
	.oneplayer   ( 1'b1   		),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} )
);		

endmodule 
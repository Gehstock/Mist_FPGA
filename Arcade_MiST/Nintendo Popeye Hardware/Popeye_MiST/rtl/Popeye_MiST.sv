
module Popeye_MiST(
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
	"POPEYE;ROM;",
//	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
//	"O7,Service,Off,On;",//Beep on REV4 ROM, not needed
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};


assign LED = ~ioctl_downl;
assign SDRAM_CLK = sdram_clk;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire sys_clk, sdram_clk;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(sdram_clk),//80
	.c1(sys_clk),//40
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [15:0] audio;
wire        hs, vs, cs;
wire        blankn;
wire  [2:0] g, r;
wire  [1:0] b;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( sys_clk      ),
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
	.clk           ( sdram_clk       ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b00, rom_addr[14:1]}),
	.cpu1_q        ( rom_do ),

	// port2 for gfx
	.port2_req     ( ),
	.port2_ack     ( ),
	.port2_a       ( ),
	.port2_ds      ( ),
	.port2_we      ( ),
	.port2_d       ( ),
	.port2_q       ( ),

	.gfx_addr      ( ),
	.gfx_q         ( )
);

always @(posedge sdram_clk) begin
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
always @(posedge sys_clk) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

popeye popeye(
	.clock_40(sys_clk),
	.reset(reset),
	.tv15Khz_mode(scandoublerD),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_csync(cs),
	.video_blankn(blankn),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),
	.coin(btn_coin),
	.start1(btn_one_player),
	.start2(btn_two_players),
	.right1(m_right),
	.left1(m_left),
	.up1(m_up),
	.down1(m_down),
	.fire1(m_fire),
	.right2(m_right),
	.left2(m_left),
	.up2(m_up),
	.down2(m_down),
	.fire2(m_fire),
	.sw1("1011111"),
	.sw2("00111101"),
	.service(status[7]),
	.cpu_rom_addr(rom_addr),
	.cpu_rom_do(rom_addr[0] ? rom_do[15:8] : rom_do[7:0])
	);

wire vs_out;
wire hs_out;
assign VGA_VS = scandoublerD | vs_out;
assign VGA_HS = scandoublerD ? cs : hs_out;

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( sys_clk          ),
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
	.VGA_VS         ( vs_out           ),
	.VGA_HS         ( hs_out           ),
	.ce_divider     ( 1'b1             ),
	.blend          ( status[5]            ),
	.rotate         ( {1'b1, status[2]}   ),
	.scandoubler_disable(1),//scandoublerD  ),
	.scanlines      ( "00"),//status[3:4]        ),
	.no_csync       ( 1'b1             ),
	.ypbpr          ( ypbpr            )
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (sys_clk        ),
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
dac_l(
	.clk_i(sys_clk),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up     = btn_up    | joystick_0[3] | joystick_1[3];
wire m_down   = btn_down  | joystick_0[2] | joystick_1[2];
wire m_left   = btn_left  | joystick_0[1] | joystick_1[1];
wire m_right  = btn_right | joystick_0[0] | joystick_1[0];
wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_coin  = 0;
wire       key_pressed;
wire [7:0] key_code;
wire       key_strobe;

always @(posedge sys_clk) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up          <= key_pressed; // up
			'h72: btn_down        <= key_pressed; // down
			'h6B: btn_left        <= key_pressed; // left
			'h74: btn_right       <= key_pressed; // right
			'h76: btn_coin        <= key_pressed; // ESC
			'h05: btn_one_player  <= key_pressed; // F1
			'h06: btn_two_players <= key_pressed; // F2
			'h29: btn_fire1       <= key_pressed; // Space
		endcase
	end
end

endmodule 

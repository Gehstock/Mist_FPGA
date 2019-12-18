
module Tetris_MiST(
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
	"TETRIS;ROM;",
	"O2,Service,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_sd;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_sd;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sd),//3xclk_sys
	.c1(clk_sys),//14.318
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
wire        hs, vs, hb, vb;
wire        blankn = ~(hb | vb);
wire  [2:0] g, r;
wire  [1:0] b;
wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [15:0] gfx_addr;
wire [15:0] gfx_do;
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
	.clk           ( clk_sd       ),
	.clkref        ( PCLK         ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b0, rom_addr[15:1]}),
	.cpu1_q        ( rom_do ),

	// port2 for gfx
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h8000 ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.gfx_addr      ( gfx_addr[15:1] ),
	.gfx_q         ( gfx_do )
);

always @(posedge clk_sd) begin
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
always @(posedge clk_sd) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire [10:0] INP = ~{status[2],1'b1, btn_coin, m_left2, m_right2, m_down2, m_fire2, m_left1, m_right1, m_down1, m_fire1};

FPGA_ATetris FPGA_ATetris(
	.MCLK(clk_sys),		// 14.318MHz
	.RESET(reset),
	
	.INP(INP),		// Negative Logic

	.HPOS(HPOS),
	.VPOS(VPOS),
	.PCLK(PCLK),
	.PCLK_EN(PCLK_EN),
	.POUT(POUT),
	
	.AOUT(audio),
	
	.PRAD(rom_addr),
	.PRDT(rom_addr[0] ? rom_do[15:8] : rom_do[7:0]),

	.CRAD(gfx_addr),
	.CRDT(gfx_do)
);

wire			PCLK;
wire			PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire  [7:0] POUT;
hvgen hvgen(
	.MCLK(clk_sys),
	.PCLK_EN(PCLK_EN),
	.HPOS(HPOS),
	.VPOS(VPOS),
	.iRGB(POUT),
	.oRGB({r,g,b}),
	.HBLK(hb),
	.VBLK(vb),
	.HSYN(hs),
	.VSYN(vs)
	);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,b[0]} : 0 ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b1             ),
	.blend          ( status[5]        ),
	.scandoubler_disable(scandoublerD  ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
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
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_down1   = btn_down | joystick_0[2];
wire m_left1   = btn_left | joystick_0[1];
wire m_right1  = btn_right | joystick_0[0];
wire m_fire1   = btn_fire1 | joystick_0[4];

wire m_down2   = joystick_1[2];
wire m_left2   = joystick_1[1];
wire m_right2  = joystick_1[0];
wire m_fire2   = joystick_1[4];


//reg btn_one_player = 0;
//reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
//reg btn_up = 0;
reg btn_fire1 = 0;
//reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;
wire       key_pressed;
wire [7:0] key_code;
wire       key_strobe;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)
//			'h75: btn_up          <= key_pressed; // up
			'h72: btn_down        <= key_pressed; // down
			'h6B: btn_left        <= key_pressed; // left
			'h74: btn_right       <= key_pressed; // right
			'h76: btn_coin        <= key_pressed; // ESC
//			'h05: btn_one_player  <= key_pressed; // F1
//			'h06: btn_two_players <= key_pressed; // F2
//			'h14: btn_fire3       <= key_pressed; // ctrl
//			'h11: btn_fire2       <= key_pressed; // alt
			'h29: btn_fire1       <= key_pressed; // Space
		endcase
	end
end

endmodule 

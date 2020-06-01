module PKWARS_MiST (
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
	"PKUNWAR;ROM;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"O6,Service,Off,On;",
	"O8,Excite Mode,Off,On;",
	"OOS,Analog Video H-Pos,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31;",
	"OTV,Analog Video V-Pos,0,1,2,3,4,5,6,7;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = clk_sd;
assign 		SDRAM_CKE = 1;

wire CLOCK_48, pll_locked, clk_sd;
pll pll(
	.inclk0(CLOCK_27),
	.c0(CLOCK_48),
	.c1(clk_sd),
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
wire			blankn = ~(hb | vb);
wire [3:0] 	r, g, b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

/*
ROM Structure
cpu   64k pkwar.01r pkwar.02r FFFF pkwar.03r 
gfx   64k pkwar.01y pkwar.02y pkwar.03y pkwar.04y
col	32b
*/

data_io data_io(
	.clk_sys       ( CLOCK_48     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);


wire [15:0] cpu_rom_addr;
wire [15:0] cpu_rom_do;

wire [13:0] gfx_rom_addr;
wire [31:0] gfx_rom_do;


	wire [24:0] bg_ioctl_addr = ioctl_addr - 17'h10000;
	
reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sd      ),

	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : cpu_rom_addr[15:1] ),
	.cpu1_q        ( cpu_rom_do ),
	.cpu2_addr     ( 16'hffff ),
	.cpu2_q        ( ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {bg_ioctl_addr[13:0], bg_ioctl_addr[15]} ), // merge sprite roms to 32-bit wide words
	.port2_ds      ( {bg_ioctl_addr[14], ~bg_ioctl_addr[14]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 16'hffff : gfx_rom_addr ),
	.sp_q          ( gfx_rom_do )
);

// ROM download controller
always @(posedge CLOCK_48) begin
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
always @(posedge CLOCK_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire        PCLK;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;
 
FPGA_PKWARS FPGA_PKWARS(
	.clk48M(CLOCK_48),
	.RESET(reset),
	.EXCITE(status[8]),	// Excite Mode (Double the CPU clock)
	.CTR1(~{1'b0,status[6], btn_one_player, 2'b00, m_fire, m_right, m_left }),
	.CTR2(~{~btn_coin, 1'b0, btn_two_players, 2'b00, m_fire, m_right, m_left }),
	.DSW(8'b11111111),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK(PCLK),
	.POUT(oPIX),
	.SND(audio),
	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_addr[0] ? cpu_rom_do[15:8] : cpu_rom_do[7:0]),
	.gfx_rom_addr(gfx_rom_addr),
	.gfx_rom_do(gfx_rom_do)
);

wire  [11:0] oPIX;
wire [4:0] HOFFS = status[28:24];
wire [2:0] VOFFS = status[31:29];
PKWARS_HVGEN PKWARS_HVGEN(
	.HPOS(HPOS),
	.VPOS(VPOS),
	.PCLK(PCLK),
	.iRGB(oPIX),
	.HOFFS(HOFFS),
	.VOFFS(VOFFS),
	.oRGB({b,g,r}),
	.HBLK(hb),
	.VBLK(vb),
	.HSYN(hs),
	.VSYN(vs)
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( CLOCK_48         ),
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
	.rotate         ( {1'b1,status[2]} ),
	.ce_divider		  ( 1'b1             ),
	.blend          ( status[5]        ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (CLOCK_48       ),
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

dac #(.C_bits(16))dac(
	.clk_i(CLOCK_48),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
//											Rotated														Normal
//wire m_up     = ~status[2] ? btn_left | joystick_0[1] | joystick_1[1] : btn_up | joystick_0[3] | joystick_1[3];
//wire m_down   = ~status[2] ? btn_right | joystick_0[0] | joystick_1[0] : btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = status[2] ? btn_down | joystick_0[2] | joystick_1[2] : btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = status[2] ? btn_up | joystick_0[3] | joystick_1[3] : btn_right | joystick_0[0] | joystick_1[0];
wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];
//wire m_bomb   = btn_fire2 | joystick_0[5] | joystick_1[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;

always @(posedge CLOCK_48) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        	<= key_pressed; // down
			'h6B: btn_left      		<= key_pressed; // left
			'h74: btn_right       	<= key_pressed; // right
			'h76: btn_coin				<= key_pressed; // ESC
			'h05: btn_one_player   	<= key_pressed; // F1
			'h06: btn_two_players  	<= key_pressed; // F2
//			'h14: btn_fire3 			<= key_pressed; // ctrl
			'h11: btn_fire2 			<= key_pressed; // alt
			'h29: btn_fire1   		<= key_pressed; // Space
		endcase
	end
end


endmodule

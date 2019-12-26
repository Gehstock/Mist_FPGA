module Gravitar_MiST(
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
	input         CLOCK_27/*,

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
*/
);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"GRAVITAR;;",
	"O12,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"O3,Test,Off,On;",
//	"O45,Max Start Level,13,21,37,53;",
//	"O67,Lives,3,4,5,6;",
//	"O89,Difficulty,Easy,Medium,Hard,Demo;",
//	"OAB,Extra Spider,20k,30k,40k,None;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_50, clk_25, clk_12, clk_6, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_50),
	.c1(clk_25),
	.c2(clk_12),
	.c3(clk_6),
	.locked(locked)
);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire 			hs, vs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire  [3:0] r, g, b;
wire			vgade;
wire  [7:0] audio;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;
//this must go to sdram
wire [18:0] vram_write_addr;
wire  [3:0] vram_write_data;
wire [18:0] vram_read_addr;
wire  [3:0] vram_read_data;
wire        vram_wren;
/*
sdram  sdram (
	.SDRAM_DQ(SDRAM_DQ),
	.SDRAM_A(SDRAM_A),
	.SDRAM_DQML(SDRAM_DQML),
	.SDRAM_DQMH(SDRAM_DQMH),
	.SDRAM_BA(SDRAM_BA),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_CKE(SDRAM_CKE),
	.init(~locked),			// init signal after FPGA config to initialize RAM
	.clk(clk_50),			// sdram is accessed at up to 128MHz
	.clkref(clk_25),		// reference clock to sync to
	.din(vram_write_data),			// data input from chipset/cpu
	.dout(vram_read_data),				// data output to chipset/cpu
	.raddr(vram_read_addr),       // 25 bit byte address
	.waddr(vram_write_addr),       // 25 bit byte address
	.rd(~vram_wren),         // cpu/chipset requests read
	.we(vram_wren)
);*/

//reduced ram size

p2ram p2ram (
	.clock(clk_25),
	.data(vram_write_data),
	.rdaddress(vram_read_addr[14:0]),
	.wraddress(vram_write_addr[14:0]),
	.wren(vram_wren),
	.q(vram_read_data)
	);

wire [7:0] sw_d4 = {2'b00, 2'b00,1'b0,3'b000}; // will be do if i see enough
wire [7:0] sw_b4 = {status[11:10],status[9:8],status[7:6], status[5:4]};	
wire [14:0] BUTTONS = ~{~btn_test, status[3], btn_coin, 1'b0, 1'b1, btn_two_players, btn_one_player, m_fire_down, m_fire_up, m_fire_left, m_fire_right, m_up, m_down, m_left, m_right};
bwidow_top bwidow_top(// gravitar uses Address Decoding Roms - Check this
	.BUTTON(BUTTONS),
	.SELF_TEST_SWITCH_L(status[3]), 
	.AUDIO_OUT(audio),
	.VIDEO_R_OUT(r),
	.VIDEO_G_OUT(g),
	.VIDEO_B_OUT(b),
	.HSYNC_OUT(hs),
	.VSYNC_OUT(vs),
	.VID_HBLANK(hb),
	.VID_VBLANK(vb),
	.SW_B4(sw_b4),
	.SW_D4(sw_d4),	
	.RESET_L(~(status[0] | buttons[1])),
	.clk_6(clk_6),
	.clk_12(clk_12),
	.clk_25(clk_25),
	.vram_write_addr(vram_write_addr),
	.vram_write_data(vram_write_data),
	.vram_read_addr(vram_read_addr),
	.vram_read_data(vram_read_data),
	.vram_wren(vram_wren)
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_25           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( ~hs              ),
	.VSync          ( ~vs              ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scandoubler_disable(1),//scandoublerD ),
	.scanlines      ( status[2:1]      ),
	.ypbpr          ( ypbpr            )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clk_25         ),
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
	.C_bits(8))
dac(
	.clk_i(clk_25),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_up     = btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = btn_right | joystick_0[0] | joystick_1[0];

wire m_fire_down   = btn_fire1 | joystick_0[4] | joystick_1[4];
wire m_fire_up   = btn_fire2 | joystick_0[5] | joystick_1[5];
wire m_fire_left   = btn_fire1 | joystick_0[4] | joystick_1[4];
wire m_fire_right   = btn_fire2 | joystick_0[5] | joystick_1[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_test = 0;

reg btn_coin  = 0;

always @(posedge clk_25) begin
	reg old_state;
	old_state <= key_strobe;
	if(old_state != key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        	<= key_pressed; // down
			'h6B: btn_left      		<= key_pressed; // left
			'h74: btn_right       	<= key_pressed; // right
			'h76: btn_coin				<= key_pressed; // ESC
			'h05: btn_one_player   	<= key_pressed; // F1
			'h04: btn_two_players   <= key_pressed; // F2

//			'h11: btn_fire2 			<= key_pressed; // alt
//			'h29: btn_fire1   		<= key_pressed; // Space
			
			
			'h2C: btn_test   			<= key_pressed; //  T
		endcase
	end
end

endmodule 
module LunarLander_MiST(
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
	"LunarLander;;",
	"O12,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"O3,Test,Off,On;",
	"O45,Language,English,Spanish,French,German;",
	"O68,Fuel,450,600,750,900,1100,1300,1550,1800;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_50, clk_25, clk_6, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_50),
	.c1(clk_25),
	.c2(clk_6),
	.locked(locked)
);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire 			hs, vs, hso, vso;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire  [3:0] r, g, b;
wire  [7:0] ro, go, bo;
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
	.rdaddress(vram_read_addr[15:0]),
	.wraddress(vram_write_addr[15:0]),
	.wren(vram_wren),
	.q(vram_read_data)
	);
	
LLANDER_TOP LLANDER_TOP (
	.ROT_LEFT_L(~m_left),
	.ROT_RIGHT_L(~m_right),
	.ABORT_L(~m_fire2),
	.GAME_SEL_L(~m_fire1),
	.START_L(~btn_one_player),
	.COIN1_L(~btn_coin),
	.COIN2_L(1'b1),
	.THRUST(thrust),
	.DIAG_STEP_L(1'b1),
	.SLAM_L(1'b1),
	.SELF_TEST_L(~status[3]), 
	.START_SEL_L(1'b1),
   .AUDIO_OUT(audio), 
   .VIDEO_R_OUT(r),
   .VIDEO_G_OUT(g),
   .VIDEO_B_OUT(b),
	.LAMP2(lamp2),
	.LAMP3(lamp3),
	.LAMP4(lamp4),
	.LAMP5(lamp5),
   .HSYNC_OUT(hs),
   .VSYNC_OUT(vs),
	.VID_HBLANK(hb),
	.VID_VBLANK(vb),
	.VGA_DE(vgade),
	.DIP({1'b0,1'b0,status[4],status[5],~status[6],1'b1,status[7],status[8]}),//todo dip full
   .RESET_L(~(status[0] | buttons[1])),
	.clk_6(clk_6),
	.clk_25(clk_25),
	.vram_write_addr(vram_write_addr),
	.vram_write_data(vram_write_data),
	.vram_read_addr(vram_read_addr),
	.vram_read_data(vram_read_data),
	.vram_wren(vram_wren)
    );
	 
ovo #(
	.COLS(1), 
	.LINES(1), 
	.RGB(24'hFF00FF)) 
diff (
	.i_r({r,r}),
	.i_g({g,g}),
	.i_b({b,b}),
	.i_hs(~hs),
	.i_vs(~vs),
	.i_de(vgade),
	.i_en(1),
	.i_clk(clk_25),

	.o_r(ro),
	.o_g(go),
	.o_b(bo),
	.o_hs(hso),
	.o_vs(vso),
	.o_de(),
	.ena(diff_count > 0),
	.in0(difficulty),
	.in1()
);

reg [7:0] thrust = 0;

// 1 second = 50,000,000 cycles (duh)
// If we want to go from zero to full throttle in 1 second we tick every
// 196,850 cycles.
always @(posedge clk_50) begin :thrust_count
	int thrust_count;
	thrust_count <= thrust_count + 1'd1;
	if (thrust_count == 'd196_850) begin
		thrust_count <= 0;
		if (m_down && thrust > 0)
			thrust <= thrust - 1'd1;

		if (m_up && thrust < 'd254)
			thrust <= thrust + 1'd1;
	end
end

int diff_count = 0;
always @(posedge clk_50) begin
	if (diff_count > 0)
		diff_count <= diff_count - 1;
	if (~m_fire2)
		diff_count <= 'd500_000_000; // 10 seconds
end

wire lamp2, lamp3, lamp4, lamp5;
wire [1:0] difficulty;
always_comb begin
	if(lamp5)
		difficulty = 2'd3;
	else if(lamp4)
		difficulty = 2'd2;
	else if(lamp3)
		difficulty = 2'd1;
	else
		difficulty = 2'd0;
end
	
mist_video #(.COLOR_DEPTH(6), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_25           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? ro[7:2] : 0   ),
	.G              ( blankn ? go[7:2] : 0   ),
	.B              ( blankn ? bo[7:2] : 0   ),
	.HSync          ( hso               ),
	.VSync          ( vso               ),
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
wire m_fire1   = btn_fire1 | joystick_0[4] | joystick_1[4];
wire m_fire2   = btn_fire2 | joystick_0[5] | joystick_1[5];
//wire m_fire3   = btn_fire3 | joystick_0[6] | joystick_1[6];
reg btn_one_player = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
//reg btn_fire3 = 0;
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
//			'h14: btn_fire3 			<= key_pressed; // ctrl
			'h11: btn_fire2 			<= key_pressed; // alt
			'h29: btn_fire1   		<= key_pressed; // Space
		endcase
	end
end

endmodule 
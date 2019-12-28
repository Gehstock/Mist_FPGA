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
	"LLANDER;ROM;",
	"O3,Test,Off,On;",
	"O45,Language,English,Spanish,French,German;",
	"O68,Fuel,450,600,750,900,1100,1300,1550,1800;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;
assign SDRAM_CLK = clk_72;
assign SDRAM_CKE = 1;

wire clk_72, clk_50, clk_6, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_72), //memclk = 12x sysclk
	.c1(clk_50), //video clk
	.c2(clk_6),  //sysclk
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
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_72       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
	);

wire [12:0] cpu_rom_addr;
wire [15:0] cpu_rom_data;
wire [12:0] vector_rom_addr;
wire [15:0] vector_rom_data;
wire  [9:0] vector_ram_addr;
wire [15:0] vector_ram_din;
wire [15:0] vector_ram_dout;
wire        vector_ram_we;
wire        vector_ram_cs1;
wire        vector_ram_cs2;

reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( locked   ),
	.clk           ( clk_72      ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : {3'b001, vector_rom_addr[12:1]} ),
	.cpu1_q        ( vector_rom_data ),
	.cpu2_addr     ( ioctl_downl ? 15'h7fff : {3'b000, cpu_rom_addr[12:1]} ),
	.cpu2_q        ( cpu_rom_data ),

	// port2 is for vector RAM
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( vector_ram_addr_last ),
	.port2_ds      ( {vector_ram_cs2, vector_ram_cs1} ),
	.port2_we      ( vector_ram_we_last ),
	.port2_d       ( vector_ram_din ),
	.port2_q       ( vector_ram_dout )
	);

reg  [9:0] vector_ram_addr_last = 0;
reg        vector_ram_we_last = 0;

always @(posedge clk_72) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end

	if ((vector_ram_cs1 || vector_ram_cs2) && (vector_ram_addr_last != vector_ram_addr || vector_ram_we_last != vector_ram_we)) begin
		vector_ram_addr_last <= vector_ram_addr;
		vector_ram_we_last <= vector_ram_we;
		port2_req <= ~port2_req;
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_6) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

	
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
   .RESET_L(~(reset)),
	.clk_6(clk_6),
	.clk_50(clk_50),
	.cpu_rom_addr    (cpu_rom_addr),
	.cpu_rom_data    (cpu_rom_addr[0] ? cpu_rom_data[15:8] : cpu_rom_data[7:0] ),
	.vector_rom_addr (vector_rom_addr), 
	.vector_rom_data (vector_rom_addr[0] ? vector_rom_data[15:8] : vector_rom_data[7:0]),
	.vector_ram_addr (vector_ram_addr),
	.vector_ram_din  (vector_ram_din),
	.vector_ram_dout (vector_ram_dout),
	.vector_ram_we   (vector_ram_we),
	.vector_ram_cs1  (vector_ram_cs1),
	.vector_ram_cs2  (vector_ram_cs2)
   );

reg ce_pix;
always @(posedge clk_50) ce_pix <= ~ce_pix;

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
	.i_en(ce_pix),
	.i_clk(clk_50),

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

// 1 second = 6,000,000 cycles (duh)
// If we want to go from zero to full throttle in 1 second we tick every
// 23,529 cycles.
always @(posedge clk_6) begin :thrust_count
	int thrust_count;
	thrust_count <= thrust_count + 1'd1;
	if (thrust_count == 'd23529) begin
		thrust_count <= 0;
		if (m_down && thrust > 0)
			thrust <= thrust - 1'd1;

		if (m_up && thrust < 'd254)
			thrust <= thrust + 1'd1;
	end
end

int diff_count = 0;
always @(posedge clk_6) begin
	if (diff_count > 0)
		diff_count <= diff_count - 1;
	if (~m_fire2)
		diff_count <= 'd60_000_000; // 10 seconds
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
	
mist_video #(.COLOR_DEPTH(6)) mist_video(
	.clk_sys        ( clk_50           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? ro[7:2] : 0   ),
	.G              ( blankn ? go[7:2] : 0   ),
	.B              ( blankn ? bo[7:2] : 0   ),
	.HSync          ( ~hso             ),
	.VSync          ( ~vso             ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scandoubler_disable(1),//scandoublerD ),
	.no_csync       ( 1'b1 ),
	.ypbpr          ( ypbpr            )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clk_6          ),
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
	.clk_i(clk_6),
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

always @(posedge clk_6) begin
	if(key_strobe) begin
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
module BlackWidow_MiST(
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

//`define CORE_NAME "BWIDOW"
`define CORE_NAME "GRAVITAR"

localparam CONF_STR = {
	`CORE_NAME,";;",
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
assign SDRAM_CKE = 1;
assign SDRAM_CLK = clk_72;

wire clk_72, clk_50, clk_12, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_72),
	.c1(clk_50),
	.c2(clk_12),
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

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

// ROM structure:
//*.d1 *.d1 *.ef1 *.h1 *.j1 *.kl1 *.m1 *.m1 PROG ROM 32k
//*.l7 *.l7 *.mn7 *.np7 *.r7                VEC ROM  16k

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

wire [14:0] cpu_rom_addr;
wire [15:0] cpu_rom_data;
wire [13:0] vector_rom_addr;
wire [15:0] vector_rom_data;
wire [10:0] vector_ram_addr;
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

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : {2'b10, vector_rom_addr[13:1]} ),
	.cpu1_q        ( vector_rom_data ),
	.cpu2_addr     ( ioctl_downl ? 15'h7fff : {1'b0, cpu_rom_addr[14:1]} ),
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

reg [10:0] vector_ram_addr_last = 0;
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

wire [7:0] sw_d4 = {2'b00, 2'b00,1'b0,3'b000}; // will be do if i see enough
wire [7:0] sw_b4 = {status[11:10],status[9:8],status[7:6], status[5:4]};	
wire [14:0] BUTTONS = ~{~btn_test, status[3], btn_coin, 1'b0, 1'b1, btn_two_players, btn_one_player, m_fire_down, m_fire_up, m_fire_left, m_fire_right, m_up, m_down, m_left, m_right};
bwidow_top bwidow_top(// gravitar uses Address Decoding Roms - Check this
	.RESET_L(~(status[0] | buttons[1])),
	.clk_12(clk_12),
	.clk_50(clk_50),
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

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_50           ),
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
	.no_csync       ( 1'b1             ),
	.ypbpr          ( ypbpr            )
	);

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clk_12         ),
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
	.clk_i(clk_12),
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

always @(posedge clk_12) begin
	if(key_strobe) begin
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
module DigDug(
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
	"DIGDUG;;",
	"O2,Rotate Controls,Off,On;",
	"O89,Difficulty,Medium,Hardest,Easy,Hard;",
	"OAB,Life,3,5,1,2;",
	"OCE,Bonus Life,M3,M4,M5,M6,M7,Nothing,M1,M2;",
	"OF,Allow Continue,No,Yes;",
	"OG,Demo Sound,Off,On;",
	"OH,Service Mode,Off,On;",
	"O7,Blend ,Off,On;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"T6,Reset;",
	"V,v1.10.",`BUILD_DATE
};

assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = clock_48;

wire clock_48, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_48),
	.locked (pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire  [7:0] audio;
wire 			hs, vs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire [2:0] 	r = oPIX[2:0];
wire [2:0] 	g = oPIX[5:3]; 
wire [1:0] 	b = oPIX[7:6];
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;
wire  [7:0] ioctl_index;
wire        ioctl_downl;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire [13:0] rom_addr;
wire [15:0] rom_do;

data_io data_io(
	.clk_sys       ( clock_48      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);
		
sdram rom(
	.*,
	.init          ( ~pll_locked  ),
	.clk           ( clock_48      ),
	.wtbt          ( 2'b00        ),
	.dout          ( rom_do     ),
	.din           ( {ioctl_dout, ioctl_dout} ),
	.addr          ( ioctl_downl ? ioctl_addr : rom_addr ),
	.we            ( ioctl_downl & ioctl_wr ),
	.rd            ( !ioctl_downl),
	.ready()
);

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | status[6] | ~rom_loaded;
end

wire  [7:0] oPIX;
//assign POUT = {oPIX[7:6],2'b00,oPIX[5:3],1'b0,oPIX[2:0],1'b0};
wire			PCLK;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;
hvgen hvgen(
	.HPOS(HPOS),
	.VPOS(VPOS),
	.PCLK(PCLK),
	.HBLK(hb),
	.VBLK(vb),
	.HSYN(hs),
	.VSYN(vs)
);


wire  [1:0] COIA = 2'b00;			// 1coin/1credit
wire  [2:0] COIB = 3'b001;			// 1coin/1credit
wire			CABI = 1'b1;
wire  		FRZE = 1'b1;

wire	[1:0] DIFC = status[9:8]+2'h2;
wire  [1:0] LIFE = status[11:10]+2'h2;
wire  [2:0] EXMD = status[14:12]+3'h3;
wire			CONT = ~status[15];
wire			DSND = ~status[16];
wire     SERVICE = status[17];

FPGA_DIGDUG GameCore( 
	.RESET(reset),
	.MCLK(clock_48),
	.rom_addr(rom_addr),
	.rom_do(rom_do),
	.INP0({SERVICE, 1'b0, 1'b0, btn_coin, btn_two_players, btn_one_player, m_fire2, m_fire1 }),
	.INP1({m_left2, m_down2, m_right2, m_up2, m_left1, m_down1, m_right1, m_up1}),
	.DSW0({LIFE,EXMD,COIB}),
	.DSW1({COIA,FRZE,DSND,CONT,CABI,DIFC}),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK(PCLK),
	.POUT(oPIX),
	.SOUT(audio)
);
	
mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b[1],b} : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.blend    		 ( status[7]        ),
	.rotate			 ({1'b1,status[2]}  ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);
	
user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clock_48       ),
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
	.clk_i(clock_48),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);
	
wire m_up1     = ~status[2] ? btn_left | joystick_0[1] : btn_up | joystick_0[3];
wire m_down1   = ~status[2] ? btn_right | joystick_0[0] : btn_down | joystick_0[2];
wire m_left1   = ~status[2] ? btn_down | joystick_0[2] : btn_left | joystick_0[1];
wire m_right1  = ~status[2] ? btn_up | joystick_0[3] : btn_right | joystick_0[0];
wire m_fire1   = btn_fire1 | joystick_0[4];

wire m_up2     = ~status[2] ? joystick_1[1] : joystick_1[3];
wire m_down2   = ~status[2] ? joystick_1[0] : joystick_1[2];
wire m_left2   = ~status[2] ? joystick_1[2] : joystick_1[1];
wire m_right2  = ~status[2] ? joystick_1[3] : joystick_1[0];
wire m_fire2   = joystick_1[4];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
//reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;

always @(posedge clock_48) begin
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
			'h06: btn_two_players  	<= key_pressed; // F2
	//		'h14: btn_fire3 			<= key_pressed; // ctrl
	//		'h11: btn_fire2 			<= key_pressed; // alt
			'h29: btn_fire1   		<= key_pressed; // Space
		endcase
	end
end


endmodule

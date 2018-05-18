module AppleII_MiST (
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
	input         CLOCK_27
);

`include "rtl\build_id.v"

localparam CONF_STR = {
	"Apple II;;",
	"O12,Screen Type , Green, White, Color;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire CLK_28M, CLK_14M, CLK_7M;
wire pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(CLK_28M),
	.c1(CLK_14M),
	.c2(CLK_7M),
	.locked(pll_locked)
);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire 			power_on_reset;
wire 			reset = power_on_reset | status[0] | status[6] | buttons[1];
wire [22:0] flash_clk;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire 	[9:0] audio;
wire 			hsync,vsync;
assign LED = 1;
wire 			blankn = ~(hblank | vblank);
wire 			hblank, vblank;
wire 			hs, vs;
wire 			VIDEO, COLOR_LINE, LD194, speaker;
wire 			read;
wire 	[7:0] K;
wire 	[9:0] r,g,b;

  
always @(CLK_14M) begin
	if (flash_clk[22] == 1'b1) power_on_reset = 1'b0;
end

always @(CLK_14M) begin
	//rising_edge(CLK_14M) then flash_clk <= flash_clk + 1;
end

video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(0)) video_mixer (
	.clk_sys(CLK_28M),
	.ce_pix(CLK_7M),
	.ce_pix_actual(CLK_7M),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(status[2:1] ? r[9:4] : 5'b0),
	.G(g[9:4]),
	.B(status[2:1] ? b[9:4] : 5'b0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1'b1),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io (
	.clk_sys        (CLK_28M        ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr          (ypbpr          ),
	.ps2_kbd_clk    (ps2_kbd_clk    ),
	.ps2_kbd_data   (ps2_kbd_data   ),
	.status         (status         )
	);
	
	wire ram_we;
	wire [13:0]ram_address;
	wire [7:0]ram_data;
	wire [7:0]ram_q;
	
ram ram(
		.clock(CLK_14M),
		.address(ram_address),
		.data(ram_data),
		.q(ram_q),
		.wren(ram_we)
		);

apple2 apple2 (
	.CLK_14M        (CLK_14M),
	.CLK_2M         (),//: out std_logic;
	.PRE_PHASE_ZERO (),//: out std_logic;
	.FLASH_CLK      (),//: in  std_logic;        -- approx. 2 Hz flashing char clock
	.reset          (reset),
	.ADDR           (),//: out unsigned(15 downto 0);  -- CPU address
	.ram_addr       (ram_address),//: out unsigned(15 downto 0);  -- RAM address
	.D              (ram_data),//: out unsigned(7 downto 0);   -- Data to RAM
	.ram_do         (ram_q),//: in unsigned(7 downto 0);    -- Data from RAM
	.PD             (),//: in unsigned(7 downto 0);    -- Data to CPU from peripherals
	.ram_we         (ram_we),//: out std_logic;              -- RAM write enable
	.VIDEO          (VIDEO),
	.COLOR_LINE     (COLOR_LINE),
	.HBL            (hblank),
	.VBL            (vblank),
	.LD194          (LD194),
	.K              (K),
	.READ_KEY       (read),
	.AN             (),//: out std_logic_vector(3 downto 0);  -- Annunciator outputs
// GAMEPORT input bits:
//  7    6    5    4    3   2   1    0
// pdl3 pdl2 pdl1 pdl0 pb3 pb2 pb1 casette
	.GAMEPORT       (),//: in std_logic_vector(7 downto 0);
	.PDL_STROBE     (),//: out std_logic;         -- Pulses high when C07x read
	.STB            (),//: out std_logic;         -- Pulses high when C04x read
	.IO_SELECT      (),//: out std_logic_vector(7 downto 0);
	.DEVICE_SELECT  (),//: out std_logic_vector(7 downto 0);
	.pcDebugOut     (),//: out unsigned(15 downto 0);
	.opcodeDebugOut (),//: out unsigned(7 downto 0);
	.speaker        (speaker)
	);
	
keyboard keyboard (
   .PS2_Clk      	(ps2_kbd_clk),
   .PS2_Data      (ps2_kbd_data),
   .CLK_14M      	(CLK_14M),
   .reset      	(reset),
   .read      		(read),
   .K      			(K),
   );
	
vga_controller vga_controller (
   .CLK_28M      		(CLK_28M),
   .VIDEO      		(VIDEO),
   .COLOR_LINE      	(COLOR_LINE),
	.COLOR				(status[2:1]==2),
   .HBL      			(hblank),
   .VBL      			(vblank),
   .LD194      		(LD194),
   .VGA_HS      		(hs),
   .VGA_VS      		(vs),
   .VGA_R      		(r),
   .VGA_G      		(g),
   .VGA_B      		(b),
    );

dac dac (
	.CLK_DAC (CLK_28M),
   .RST     (),
   .IN_DAC  (speaker & 15'b0),
   .OUT_DAC (AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;


endmodule

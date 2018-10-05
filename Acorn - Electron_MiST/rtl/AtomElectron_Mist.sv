module AtomElectron_Mist
(
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
	input         SPI_SS4,
	input         CONF_DATA0,
	input         CLOCK_27
	);
	
`include "rtl\build_id.v" 	
	localparam CONF_STR = {
	"Electron;;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire clk_16M00, clk_33M33, clk_40M00, clk_4M00;
wire ps2_clk, ps2_data;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire hs, vs;
wire [2:0] r,g,b;


wire pwrup_RSTn;
wire reset = ~(status[0] || status[6] || buttons[1]);
wire ERSTn;
reg [7:0]reset_ctr = 8'b0;
	 
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_40M00),
	.c1(clk_16M00),
	.c2(clk_33M33),
	.c3(clk_4M00)//8,3325
	);

ElectronFpga_core ElectronFpga_core(
   .clk_16M00(clk_16M00),
   .clk_33M33(clk_33M33),
   .clk_40M00(clk_40M00),
   .ps2_clk(ps2_clk),
   .ps2_data(ps2_data),
   .ERSTn(ERSTn),
	.RESET(reset),
   .red(r),
   .green(g),
   .blue(b),
   .vsync(vs),
   .hsync(hs),
   .audiol(AUDIO_L),
   .audioR(AUDIO_R),
   .casIn(),
   .casOut(),
   .LED1(LED),
   .SDMISO(),
   .SDSS(),
   .SDCLK(),
   .SDMOSI()
   );  
	
 assign ERSTn = pwrup_RSTn;

always @ (posedge clk_16M00)
begin
 if (pwrup_RSTn == 1'b0) reset_ctr <= reset_ctr + 1;
end

assign  pwrup_RSTn = reset_ctr[7];

video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_33M33),
	.ce_pix(clk_4M00),
	.ce_pix_actual(clk_4M00),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r}),
	.G({g,g}),
	.B({b,b}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1'b1),//scandoubler_disable),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_33M33      ),
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
	.ps2_kbd_clk    (ps2_clk),
	.ps2_kbd_data   (ps2_data),
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
);



endmodule 
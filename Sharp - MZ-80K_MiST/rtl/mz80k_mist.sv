module mz80k_mist(
	input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,	 
   output        LED,
   output        AUDIO_L,
   output        AUDIO_R,
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
	input         SPI_SS4,
   input         CONF_DATA0/*,
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
   output        SDRAM_CKE*/
);

`include "rtl\build_id.v" 
assign LED = 1;	 
localparam CONF_STR = {
		  "Sharp MZ80K;MZF;",
		  "O2,CPU Clock, 3Mhz, 6Mhz;",
		  "O34,Screen, Gray, Green, Color;",
		  "T5,Reset;",
		  "V,v0.4.",`BUILD_DATE
		};


wire clk_sys;
wire clk_25, clk_12p5, clk_6p25;
wire locked;
wire        scandoubler_disable;
wire        ypbpr;
wire [10:0] PS2_KEY;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire audio;
wire [1:0] r, g, b;
wire hs, vs;
wire  [7:0] kb_ext;
pll pll(
	.areset(),
	.inclk0(CLOCK_27),
	.c0(clk_sys),//50.0Mhz
	.c1(clk_25),//25.0Mhz
	.c2(clk_12p5),//12.5Mhz
	.c3(clk_6p25),//6.25Mhz
	.locked(locked)
	);

reg [7:0] reset_cnt;
always @(posedge clk_sys) begin
	if(!locked || buttons[1] || status[0] || status[5])
		reset_cnt <= 8'h0;
	else if(reset_cnt != 8'd255)
		reset_cnt <= reset_cnt + 8'd1;
end 

wire reset = (reset_cnt != 8'd255);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.conf_str(CONF_STR),
	.clk_sys(clk_25),
	.SPI_SCK(SPI_SCK),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SS2(SPI_SS2),
	.SPI_DO(SPI_DO),
	.SPI_DI(SPI_DI),
	.buttons(buttons),
	.switches(switches),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.status(status),
	.ps2_key(PS2_KEY)
);

video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_25),
	.ce_pix(clk_6p25),
	.ce_pix_actual(clk_6p25),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.scandoubler_disable(1),//scandoubler_disable),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.R({r,r,r}),
	.G({g,g,g}),
	.B({b,b,b}),
	.mono(0),
	.HSync(hs),
	.VSync(vs),
	.line_start(0),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS)
);

sigma_delta_dac #(.MSBI(2)) sigma_delta_dac
(	
	.DACout(AUDIO_L),
	.DACin({audio,audio,audio}),
	.CLK(clk_25),
	.RESET(0)
);

assign AUDIO_R = AUDIO_L;

mz80k_top mz80k_top(
	.CLK_50MHZ(clk_sys),
	.RESET(reset),
	.color(status[4:3]),
	.PS2_KEY(PS2_KEY), 
	.VGA_RED(r), 
	.VGA_GREEN(g), 
	.VGA_BLUE(b), 
	.VGA_HSYNC(hs), 
	.VGA_VSYNC(vs),
	.TURBO(status[2]),
	.TP1(audio)
	);

endmodule 
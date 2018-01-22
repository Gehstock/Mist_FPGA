`timescale 1ns / 1ps
`default_nettype none

module ace_mist(
	input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,	 
   output        LED,
   output        AUDIO_L,
   output        AUDIO_R,
   output        UART_TX,//uses for Tape Record
   input         UART_RX,//uses for Tape Play	
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
	input         SPI_SS4,
   input         CONF_DATA0,
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
		  "Jupiter ACE;;",
		  "O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
		  "T5,Reset;",
		  "V,v0.2.",`BUILD_DATE
		};

wire			clk_sys;
wire 			clk_65;
wire 			clk_cpu;
wire        clk_sdram;
wire 			locked;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire 			audio;
wire 			TapeIn;
wire 			TapeOut;
wire 			HSync, VSync;
wire 			video;
wire 	[7:0] kbd_rows;
wire 	[4:0] kbd_columns;
	
pll pll(
	.areset(),
	.inclk0(CLOCK_27),
	.c0(clk_sys),//26.0Mhz
	.c1(clk_65),//6.5Mhz
	.c2(clk_cpu),//3.25Mhz
	.c3(clk_sdram),//100Mhz
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
	.clk_sys(clk_sys),
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
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data)
);

video_mixer #(.LINE_LENGTH(800), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_sys),
	.ce_pix(clk_65),
	.ce_pix_actual(clk_65),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.scandoubler_disable(scandoubler_disable),
	.hq2x(status[4:3]==1),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.R({video,video,1'b0}),
	.G({video,video,1'b0}),
	.B({video,video,1'b0}),
	.mono(1),
	.HSync(HSync),
	.VSync(VSync),
	.line_start(0),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS)
);

wire [24:0]sd_addr;
wire [7:0]sd_dout;
wire [7:0]sd_din;
wire sd_we;
wire sd_rd;
wire sd_ready;

sram sram(
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
	.init(~reset),
	.clk_sdram(clk_sdram),			
	.addr(sd_addr),   // 25 bit address
	.dout(sd_dout),	// data output to cpu
	.din(sd_din),     // data input from cpu
	.we(sd_we),       // cpu requests write
	.rd(sd_rd),       // cpu requests read
	.ready(sd_ready)
);


jupiter_ace jupiter_ace
(
   .clk_65(clk_65),
   .clk_cpu(clk_cpu),
   .reset(~reset),
   .filas(kbd_rows),
   .columnas(kbd_columns),
   .video(video),
   .hsync(HSync),
	.vsync(VSync),
   .ear(UART_RX),//Play
   .mic(UART_TX),//Record
   .spk(audio),
	.sd_addr(sd_addr),
	.sd_dout(sd_dout),
	.sd_din(sd_din),
	.sd_we(sd_we),
	.sd_rd(sd_rd),
	.sd_ready(sd_ready)
);

sigma_delta_dac sigma_delta_dac
(	
	.DACout(AUDIO_L),
	.DACin({audio}),
	.CLK(clk_65),
	.RESET(0)
);

assign AUDIO_R = AUDIO_L;
	
keyboard keyboard
(
   .clk(clk_65),
   .clkps2(ps2_kbd_clk),
   .dataps2(ps2_kbd_data),
   .rows(kbd_rows),
   .columns(kbd_columns),
   .kbd_reset(),
   .kbd_nmi(),
   .kbd_mreset()        
);




endmodule

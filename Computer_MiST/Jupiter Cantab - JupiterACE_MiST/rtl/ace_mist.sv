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
   input         CONF_DATA0
    );
	 
`include "rtl\build_id.v" 
	 
localparam CONF_STR = {
		  "Jupiter ACE;;",
		  "F,ACE;",
		  "O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
		  "O67,CPU Speed,Normal,x2,x4;",
		  "T5,Reset;",
		  "V,v0.5.",`BUILD_DATE
		};

wire			clk_sys;
wire        clk_sdram;
wire 			locked;
wire        scandoubler_disable;
wire        ypbpr;
wire [10:0] ps2_key;
assign LED = ~ioctl_download;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire 			HSync, VSync, HBlank, VBlank;
wire 			blankn = ~(HBlank | VBlank);
wire 			video;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
reg         ioctl_wait = 0;
	
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_sys)
	);


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
	.ps2_key(ps2_key),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait)
);

video_mixer #(.LINE_LENGTH(280), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_sys),
	.ce_pix(ce_pix),
	.ce_pix_actual(ce_pix),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.scandoubler_disable(scandoubler_disable),
	.hq2x(status[4:3]==1),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.R(blankn ? {video,video,video} : "000"),
	.G(blankn ? {video,video,video} : "000"),
	.B(blankn ? {video,video,video} : "000"),
	.mono(0),
	.HSync(~HSync),
	.VSync(~VSync),
	.line_start(0),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS)
);

wire [1:0] turbo = status[7:6];

reg ce_pix;
reg ce_cpu;
always @(negedge clk_sys) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= !div[1:0];
	ce_cpu <= (!div[2:0] && !turbo) | (!div[1:0] && turbo[0]) | turbo[1];
end
wire reset = ~(buttons[1] || status[0] || status[5]);
wire spk, mic;
jupiter_ace jupiter_ace(
	.clk(clk_sys),
	.ce_pix(ce_pix),
	.ce_cpu(ce_cpu),
	.no_wait(|turbo),
	.reset(reset|loader_reset),
	.kbd_row(kbd_row),
	.kbd_col(kbd_col),
	.video_out(video),
	.hsync(HSync),
	.vsync(VSync),
	.hblank(HBlank),
	.vblank(VBlank),
	.mic(mic),
	.spk(spk),
	.loader_en(loader_en),
	.loader_addr(loader_addr),
	.loader_data(loader_data),
	.loader_wr(loader_wr)
);

sigma_delta_dac sigma_delta_dac
(	
	.DACout(AUDIO_L),
	.DACin({1'b0, spk, mic, 13'd0}),
	.CLK(clk_sys),
	.RESET(reset)
);

assign AUDIO_R = AUDIO_L;
wire [7:0] kbd_row;
wire [4:0] kbd_col;

keyboard keyboard(
	.reset(reset),
	.clk_sys(clk_sys),
	.ps2_key(ps2_key),
	.kbd_row(kbd_row),
	.kbd_col(kbd_col)
);

reg [15:0] loader_addr;
reg  [7:0] loader_data;
reg        loader_wr;
reg        loader_en;
reg        loader_reset = 0;

always @(posedge clk_sys) begin
	reg [7:0] cnt = 0;
	reg [1:0] status = 0;
	reg       old_download;
	integer   timeout = 0;

	old_download <= ioctl_download;
	
	loader_reset <= 0;
	if(~old_download && ioctl_download) begin
		loader_addr <= 'h2000;
		status <= 0;
		loader_reset <=1;
		ioctl_wait <= 1;
		timeout <= 3000000;
		cnt <= 0;
	end
	
	loader_wr <= 0;
	if(loader_wr) loader_addr <= loader_addr + 1'd1;

	if(ioctl_wr) begin
		loader_en <= 1;
		case(status)
			0: if(ioctl_dout == 'hED) status <= 1;
				else begin
					loader_wr <= 1;
					loader_data <= ioctl_dout;
				end
			1: begin
					cnt <= ioctl_dout;
					status <= ioctl_dout ? 2'd2 : 2'd3; // cnt = 0 => stop
				end
			2: begin
					loader_data <= ioctl_dout;
					ioctl_wait <= 1;
				end
		endcase
	end

	if(ioctl_wait && !loader_wr) begin
		if(cnt) begin
			cnt <= cnt - 1'd1;
			loader_wr <= 1;
		end
		else if(timeout) timeout <= timeout - 1;
		else {status,ioctl_wait} <= 0;
	end

	if(old_download & ~ioctl_download) loader_en <= 0;
	if(reset) ioctl_wait <= 0;
end


endmodule

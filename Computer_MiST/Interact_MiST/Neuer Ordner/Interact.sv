//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_S = 1;
assign AUDIO_L = AUDIO_R;
//assign AUDIO_R = sound_pad;
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[11:10];

video_freak video_freak
(
	.*,
	.VGA_DE_IN(VGA_DE),
	.VGA_DE(),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE(0),
	.CROP_OFF(0),
	.SCALE(status[13:12])
);

wire tape_play = status[14];
wire tape_rewind = status[15];

`include "build_id.v" 
localparam CONF_STR = {
	"Interact;;",
	"F,CINK7 ,Load tape;",
	"TE,Play;",
	"TF,Stop & Rewind;",
	"-;",
	"OAB,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O24,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"OCD,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O6,Test Pattern,Off,On;",
	"-;",
	"T0,Reset;",
	"R0,Reset and close OSD;",
	"V,v",`BUILD_DATE 
};

wire forced_scandoubler;
wire freeze_sync;
wire [21:0] gamma_bus;
wire  [1:0] buttons;
wire [31:0] status;
wire [10:0] ps2_key;
wire [15:0] joystick_0,joystick_1;
wire [15:0] joystick_analog_0, joystick_analog_1;
wire  [7:0] paddle_0, paddle_1;

wire        ioctl_download;
wire        ioctl_wr;
wire [15:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [7:0] ioctl_index;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({status[5]}),
	
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_analog_0(joystick_analog_0),
	.joystick_analog_1(joystick_analog_1),
	.paddle_0(paddle_0),
	.paddle_1(paddle_1),
	.ps2_key(ps2_key)
);

wire rom_download = ioctl_download && (ioctl_index == 0);
wire tape_download = ioctl_download && (ioctl_index != 0);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
wire locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(CLK_VIDEO),
	.outclk_1(clk_sys),
	.locked(locked)
);

wire reset = RESET | status[0] | buttons[1] | rom_download;
wire rst_n = ~reset;

// vm80a needs a nice long reset
reg  [7:0] rcnt = 8'h00;
wire cpu_rst_n = (rcnt == 8'hFF);

always @(posedge clk_sys)
	begin
		if (reset)
			rcnt <= 8'h00; 
		else
			if (rcnt != 8'hFF) rcnt <= rcnt + 8'h01;
	end


wire ph1;
wire ph2;
wire cbclk;
wire pix_a;
wire vid_sel;
wire [11:0] vid_a;
wire vid_sel_n;
wire nrr_n;
wire ce_n;
wire pce;
wire vid_ltc;
wire ram_clk;
wire brst;
wire tpclk;
wire cmp_blank;
wire irq;
wire inte;
wire cmp_sync;
wire hblank_n;
wire vblank_n;
wire hsync_n;
wire vsync_n;

video_timing timing
(
	.clk_14m(clk_sys),
	.rst_n(rst_n),
	.ph1(ph1),
	.ph2(ph2),
	.cbclk(cbclk),
	.pix_a(pix_a),
	.vid_sel(vid_sel),
	.vid_a0(vid_a[0]),
	.vid_a1(vid_a[1]),
	.vid_a2(vid_a[2]),
	.vid_a3(vid_a[3]),
	.vid_a4(vid_a[4]),
	.vid_a5(vid_a[5]),
	.vid_a6(vid_a[6]),
	.vid_a7(vid_a[7]),
	.vid_a8(vid_a[8]),
	.vid_a9(vid_a[9]),
	.vid_a10(vid_a[10]),
	.vid_a11(vid_a[11]),
	.vid_sel_n(vid_sel_n),
	.nrr_n(nrr_n),
	.ce_n(ce_n),
	.pce(pce),
	.vid_ltc(vid_ltc),
	.ram_clk(ram_clk),
	.brst(brst),
	.tpclk(tpclk),
	.cmp_blank(cmp_blank),
	.irq(irq),
	.inte(inte),
	.cmp_sync(cmp_sync),
	.hblank_n(hblank_n),
	.vblank_n(vblank_n),
	.hsync_n(hsync_n),
	.vsync_n(vsync_n)
);

///////////////////   CPU   ///////////////////

wire [15:0] addr;
reg  [7:0] cpu_din;
wire  [7:0] cpu_dout;
wire        wr_n;
wire        ready;
wire        hold;
wire        rd;
wire        sync;
wire        vait;
wire        hlda;
wire			pin_aena;
wire			pin_dena;

assign hold = 1'b0;
assign ready = 1'b1;

vm80a_core cpu
(
   .pin_clk(clk_sys),
   .pin_f1(~ph2),
   .pin_f2(ph2),
   .pin_reset(~cpu_rst_n),
   .pin_a(addr),
   .pin_dout(cpu_dout),
   .pin_din(cpu_din),
   .pin_aena (pin_aena),
   .pin_dena (pin_dena),
   .pin_hold(hold),
   .pin_ready(ready),
   .pin_int(irq),
   .pin_wr_n(wr_n),
   .pin_dbin(rd),
   .pin_inte(inte),
   .pin_hlda(hlda),
   .pin_wait(vait),
   .pin_sync(sync)
);

//////// STATUS system control ////////////

reg[7:0] cpu_status;
wire status_inta = cpu_status[0];
//wire status_wo_n = cpu_status[1];
//wire status_stack = cpu_status[2];
//wire status_hlta = cpu_status[3];
//wire status_out = cpu_status[4];
//wire status_m1 = cpu_status[5];
//wire status_inp = cpu_status[6];
//wire status_memr = cpu_status[7];

always @(posedge clk_sys or negedge rst_n) 
 begin
	reg old_sync;
	if (!rst_n)
		cpu_status <= 8'b0;
	else
		begin
			old_sync <= sync;
			if(~old_sync & sync) 
				cpu_status <= cpu_dout;
		end
 end
 
always_comb begin
	casez({status_inta, rom_e, ram_e, ~io_3800_r_n, ~io_3000_r_n})
	    5'b1????: cpu_din <= 8'hFF;
	    5'b00001: cpu_din <= io_rd_rtc_ad;
	    5'b00010: cpu_din <= key_data;
	    5'b00100: cpu_din <= ram_out;
	    5'b01000: cpu_din <= rom_out;
	 default: cpu_din <= 8'hFF;
	endcase
end


///////////////////   MEMORY   ///////////////////
//                  1111110000000000
//                  5432109876543210
// ROM A    0000H   0000000000000000
// ROM B    0800H   0000100000000000
// IO 10    1000H   0001000000000000
// IO 18    1800H   0001100000000000
// IO 20    2000H   0010000000000000
// IO 28    2800H   0010100000000000
// IO 30    3000H   0011000000000000
// IO 38    3800H   0011100000000000
// VRAM     4000H   0100000000000000
//          49FFH   0100100111111111
// RAM      4800H   0100101000000000

wire rom_e = ~addr[15] & ~addr[14] & ~addr[13] & ~addr[12] & ~addr[11];
wire [7:0] rom_out;

dpram #(.ADDRWIDTH(12), .NUMWORDS(4096), .MEM_INIT_FILE("rtl/boot.mif")) rom
(
	.clock(clk_sys),
	.address_a(ioctl_addr),
	.data_a(ioctl_data),
	.wren_a(rom_download && ioctl_wr),

	.address_b(addr[11:0]),
	.q_b(rom_out)
);

wire ram_e = ~addr[15] & addr[14];
wire [7:0] ram_out;
wire ram_w = ram_e & ~wr_n;
wire [7:0] vid_out;

dpram #(.ADDRWIDTH(14)) ram
(
	.clock(clk_sys),
	.address_a(addr[13:0]),
	.data_a(cpu_dout),
	.wren_a(ram_w),
	.q_a(ram_out),

	.address_b({2'b0, vid_a[11:0]}),
	.q_b(vid_out)
);

///////////////////   Memory Mapped IO Registers   ///////////////////

// sure we could do this with some simple verilog conditionals, but digging the old-time TTL ICs

wire io_0000_r_n;
wire io_0800_r_n;
wire io_1000_r_n;
wire io_1800_r_n;
wire io_2000_r_n;
wire io_2800_r_n;
wire io_3000_r_n;
wire io_3800_r_n;

wire io_0000_w_n;
wire io_0800_w_n;
wire io_1000_w_n;
wire io_1800_w_n;
wire io_2000_w_n;
wire io_2800_w_n;
wire io_3000_w_n;
wire io_3800_w_n;

SN74LS138 IC25 (
	.a(addr[11]),
	.b(addr[12]),
	.c(addr[13]),
	.g1(rd),
	.g2an(addr[15]),
	.g2bn(addr[14]),
	.y0n(io_0000_r_n),
	.y1n(io_0800_r_n),
	.y2n(io_1000_r_n),
	.y3n(io_1800_r_n),
	.y4n(io_2000_r_n),
	.y5n(io_2800_r_n),
	.y6n(io_3000_r_n),
	.y7n(io_3800_r_n)
);

SN74LS138 IC26 (
	.a(addr[11]),
	.b(addr[12]),
	.c(addr[13]),
	.g1(~wr_n),
	.g2an(addr[15]),
	.g2bn(addr[14]),
	.y0n(io_0000_w_n),
	.y1n(io_0800_w_n),
	.y2n(io_1000_w_n),
	.y3n(io_1800_w_n),
	.y4n(io_2000_w_n),
	.y5n(io_2800_w_n),
	.y6n(io_3000_w_n),
	.y7n(io_3800_w_n)
);


//wire [7:0] io_rd_rtc_ad = {(io_wr_misc[7:6] ? (io_wr_misc[7:6] == 2'b10 ? rtc[7] : 1'b0) : tape_flux), rtc[6:0]};
wire [7:0] io_rd_rtc_ad;
always_comb
	casez (io_wr_misc[7:3])
		5'b00111 : io_rd_rtc_ad = {tape_flux, rtc[6:0]};
		5'b10111 : io_rd_rtc_ad = rtc;
		5'b?1111 : io_rd_rtc_ad = {1'b0, rtc[6:0]};
		5'b??001 : io_rd_rtc_ad = joystick_0[4] ? 8'h00 : 8'h80;
		5'b??010 : io_rd_rtc_ad = {~joystick_analog_0[7], joystick_analog_0[6:0]};
		5'b??100 : io_rd_rtc_ad = joystick_1[4] ? 8'h00 : 8'h80;
		5'b??101 : io_rd_rtc_ad = {~joystick_analog_1[7], joystick_analog_1[6:0]};
	 default: io_rd_rtc_ad = 8'h00;
	endcase


wire rtc_clr = ~rst_n | io_wr_misc[6];
reg [7:0] rtc;
wire rtc_clk = io_wr_misc[6] ? 1'b0 : (io_wr_misc[7] ? pix_a : tpclk);

always@(negedge rtc_clk or posedge rtc_clr)
begin
if (rtc_clr)
	begin
	rtc <= 8'b0;
	end
else
	begin
	rtc <= rtc + 1'b1;
	end
end

wire [7:0] keys [7:0];
wire [7:0] key_data = keys[addr[3:0]];

keyboard keyboard
(
	.clk_sys(clk_sys),
	.rst_n(rst_n),
	.ps2_key(ps2_key),
	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.keys(keys)
);


reg [7:0] io_wr_color_a_tape;
reg [7:0] io_wr_color_b_snd;

reg [7:0] io_wr_sound_a [3:0];
reg [7:0] io_wr_sound_b [3:0];

reg [7:0] io_wr_misc;

always@(posedge io_1000_w_n or negedge rst_n)
begin
if (!rst_n)
	begin
	io_wr_color_a_tape <= 8'b0;
	end
else
	begin
	io_wr_color_a_tape <= cpu_dout;
	end
end

always@(posedge io_1800_w_n or negedge rst_n)
begin
if (!rst_n)
	begin
	io_wr_color_b_snd <= 8'b0;
	end
else
	begin
	io_wr_color_b_snd <= cpu_dout;
	end
end

always@(posedge io_2000_w_n or negedge rst_n)
begin
if (!rst_n)
	begin
	io_wr_sound_a[2'b00] <= 8'b0;
	io_wr_sound_a[2'b01] <= 8'b0;
	io_wr_sound_a[2'b10] <= 8'b0;
	io_wr_sound_a[2'b11] <= 8'b0;
	end
else
	begin
	io_wr_sound_a[addr[1:0]] <= cpu_dout;
	end
end

always@(posedge io_2800_w_n or negedge rst_n)
begin
if (!rst_n)
	begin
	io_wr_sound_b[2'b00] <= 8'b0;
	io_wr_sound_b[2'b01] <= 8'b0;
	io_wr_sound_b[2'b10] <= 8'b0;
	io_wr_sound_b[2'b11] <= 8'b0;
	end
else
	begin
	io_wr_sound_b[addr[1:0]] <= cpu_dout;
	end
end

always@(posedge io_3000_w_n or negedge rst_n)
begin
if (!rst_n)
	begin
	io_wr_misc <= 8'b0;
	end
else
	begin
	io_wr_misc <= cpu_dout;
	end
end


///////////////////   Video   ///////////////////


//// Test generator start

reg [7:0] vidtest_x;
reg [7:0] vidtest_y;
wire [6:0] vidtest_scanline = vid_a[11:5];

always@(posedge vid_ltc or negedge hblank_n)
begin
	if (!hblank_n)
		vidtest_x <= 8'b0;
	else
		vidtest_x <= vidtest_x + 1'b1;
end

always@(posedge hsync_n or negedge vblank_n)
begin
	if (!vblank_n)
		vidtest_y <= 8'b0;
	else
		vidtest_y <= vidtest_y + 1'b1;
end

//// Test generator end


reg [7:0] pix_byte;
wire pix_en = vid_sel & vid_ltc & ~(ce_n | pce);

always@(posedge pix_en or negedge rst_n)
begin
if (!rst_n)
	begin
	pix_byte <= 8'b0;
	end
else
	begin
	pix_byte <= vid_out;
	end
end

reg [3:0] pix_nib;

always@(posedge vid_sel_n or negedge rst_n)
begin
if (!rst_n)
	begin
	pix_nib <= 4'b0;
	end
else
	begin
	pix_nib <= pix_byte[7:4];
	end
end

reg [7:0] R;
reg [7:0] G;
reg [7:0] B;

wire [1:0] pix = vid_sel ? (pix_a ? pix_nib[3:2] : pix_nib[1:0]) : (pix_a ? pix_byte[3:2] : pix_byte[1:0]); 

wire [2:0] cr [3:0];

assign cr[2'b00] = io_wr_color_a_tape[2:0];
assign cr[2'b01] = io_wr_color_b_snd[2:0];
assign cr[2'b10] = io_wr_color_a_tape[5:3];
assign cr[2'b11] = io_wr_color_b_snd[5:3];

wire [2:0] color = cr[pix];
wire color_intensity = (pix == 2'b10) ? io_wr_color_b_snd[6] : 1'b0;

wire      test_pattern = status[6];

always@(posedge vid_ltc or negedge rst_n)
begin
if (!rst_n)
	begin
	R <= 8'b0;
	G <= 8'b0;
	B <= 8'b0;
	end
else
	begin
		if (cmp_blank)
			begin
				R <= 8'b0;
				G <= 8'b0;
				B <= 8'b0;
			end
		else if (test_pattern & (vidtest_x === 8'd0))
			begin
				R <= 8'h00; //darkgreen
				G <= 8'h64;
				B <= 8'h00;
			end
		else if (test_pattern & (vidtest_x === 8'd110))
			begin
				R <= 8'h7c; //lawngreen
				G <= 8'hfc;
				B <= 8'h00;
			end
		else if (test_pattern & (vidtest_scanline === 7'd0))
			begin
				R <= 8'h8A; //blueviolet
				G <= 8'h2B;
				B <= 8'hE2;
			end
		else if (test_pattern & (vidtest_scanline === 7'd75))
			begin
				R <= 8'h1e; //dodgerblue
				G <= 8'h90;
				B <= 8'hff;
			end
		else
			begin
				if (color_intensity)
					begin
						if (test_pattern)
							begin
								R <= 8'h7c; //lawngreen
								G <= 8'hfc;
								B <= 8'h00;
							end
						else
							begin
								R <= {1'b0, {7{color[0]}}};
								G <= {1'b0, {7{color[1]}}};
								B <= {1'b0, {7{color[2]}}};
							end
					end
				else
					begin
						R <= {8{color[0]}};
						G <= {8{color[1]}};
						B <= {8{color[2]}};
					end
			end
	end
end

wire [2:0] scale = status[4:2];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

assign VGA_F1 = 0;
assign VGA_SL = sl[1:0];

video_mixer #(.LINE_LENGTH(112), .GAMMA(1)) video_mixer
(
	.*,
	.ce_pix(vid_ltc),
	.HSync(~hsync_n),
	.VSync(~vsync_n),
	.HBlank(~hblank_n),
	.VBlank(~vblank_n),
	.hq2x(scale == 1),
	.scandoubler(|scale || forced_scandoubler)
);


//// Tape Loading

wire [15:0] tape_addr;
wire [7:0] tape_data;
reg [15:0] tape_end;

dpram #(.ADDRWIDTH(16)) tape
(
	.clock(CLK_VIDEO),
	.address_a(ioctl_addr),
	.data_a(ioctl_data),
	.wren_a(tape_download && ioctl_wr),

	.address_b(tape_addr),
	.q_b(tape_data)
);

always@(posedge CLK_VIDEO or negedge rst_n)
begin
if (!rst_n)
	begin
	tape_end <= 16'b0;
	end
else
	begin
	if (tape_download) tape_end <= ioctl_addr;
	end
end

wire tape_playing;
wire tape_flux;

cassette cassette(
  .clk(clk_sys),
  .rst_n(rst_n),
  .play(tape_play),
  .rewind(tape_rewind),
  .playing(tape_playing),
  .motor(io_wr_color_a_tape[6]),

  .tape_addr(tape_addr),
  .tape_data(tape_data),
  .tape_end(tape_end),

  .flux(tape_flux),
  .audio(AUDIO_R)
);

assign LED_USER = tape_playing;

endmodule

`timescale 1ns / 1ps
//Pet2001 Mist Toplevel 2017 Gehstock

module Pet2001
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


//////////////////////////////////////////////////////////////////////
//  MiST I/O                                                         //
//////////////////////////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;

`include "rtl\build_id.v"

localparam CONF_STR = 
{
	"PET2001;TAPPRG;",
	"O78,TAP mode,Fast,Normal,Normal+Sound;",
	"O9A,CPU Speed,Normal,x2,x4,x8;",
	"O2,Screen Color,White,Green;",
	"O3,Diag,Off,On(needs Reset);",
	"O56,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T7,Reset;",
	"V,v0.61.",`BUILD_DATE

};

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk            ),
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
	.ps2_caps_led   (shift_lock     ),
	.status         (status         ),
	.ioctl_download (ioctl_download ),
	.ioctl_index    (ioctl_index    ),
	.ioctl_wr       (ioctl_wr       ),
	.ioctl_addr     (ioctl_addr     ),
	.ioctl_dout     (ioctl_dout     )
);


//////////////////////////////////////////////////////////////////////
// Global Clock and System Reset.                //
//////////////////////////////////////////////////////////////////////

wire clk, sdram_clk;
wire locked;

pll pll
(
	.inclk0(CLOCK_27),
	.c0(sdram_clk),    //112Mhz
	.c1(SDRAM_CLK),    //112Mhz
	.c2(clk),          //56MHz
	.locked(locked)
);

reg       reset = 1;
wire      RESET = status[0] | buttons[1] | status[7];
always @(posedge clk) begin
	integer   initRESET = 20000000;
	reg [3:0] reset_cnt;

	if ((!RESET && reset_cnt==4'd14) && !initRESET)
		reset <= 0;
	else begin
		if(initRESET) initRESET <= initRESET - 1;
		reset <= 1;
		reset_cnt <= reset_cnt+4'd1;
	end
end


////////////////////////////////////////////////////////////////////
// Clocks
////////////////////////////////////////////////////////////////////

reg  ce_7mp;
reg  ce_7mn;
reg  ce_1m;
wire [6:0] cpu_rates[4] = '{55, 27, 13, 6};

always @(negedge clk) begin
	reg  [4:0] div = 0;
	reg  [6:0] cpu_div = 0;
	reg  [6:0] cpu_rate = 55;

	div <= div + 1'd1;
	ce_7mp  <= !div[2] & !div[1:0];
	ce_7mn  <=  div[2] & !div[1:0];
	
	cpu_div <= cpu_div + 1'd1;
	if(cpu_div == cpu_rate) begin
		cpu_div  <= 0;
		cpu_rate <= (tape_active && !status[8:7]) ? 7'd2 : cpu_rates[status[10:9]];
	end
	ce_1m <= ~(tape_active & ~ram_ready) && !cpu_div;
end


///////////////////////////////////////////////////
// RAM
///////////////////////////////////////////////////

wire ram_ready;

sram ram
(
	.*,
	.clk(sdram_clk),
	.init(~locked),
	.dout(tape_data),
	.din (ioctl_dout),
	.addr(ioctl_download ? ioctl_addr : tape_addr),
	.wtbt(0),
	.we( ioctl_download && ioctl_wr && (ioctl_index == 1)),
	.rd(!ioctl_download && tape_rd),
	.ready(ram_ready)
);


///////////////////////////////////////////////////
// CPU
///////////////////////////////////////////////////

wire [15:0] addr;
wire [7:0] 	cpu_data_out;
wire [7:0] 	cpu_data_in;

wire we;
wire irq;

cpu6502 cpu
(
	.clk(clk),
	.ce(ce_1m),
	.reset(reset),
	.nmi(0),
	.irq(irq),
	.din(cpu_data_in),
	.dout(cpu_data_out),
	.addr(addr),
	.we(we)
);


///////////////////////////////////////////////////
// Commodore Pet hardware
///////////////////////////////////////////////////

wire pix;
wire HSync, VSync;
wire audioDat;

pet2001hw hw
(
	.*,
	.data_out(cpu_data_in),
	.data_in(cpu_data_out),

	.cass_motor_n(),
	.cass_write(tape_write),
	.audio(audioDat),
	.cass_sense_n(0),
	.cass_read(tape_audio),
	.diag_l(!status[3]),

	.dma_addr(dma_off[13:0]+ioctl_addr[13:0]-2'd2),
	.dma_din(ioctl_dout),
	.dma_dout(),
	.dma_we(ioctl_wr && ioctl_download && (ioctl_index == 8'h41) && (ioctl_addr>1)),

	.clk_speed(0),
	.clk_stop(0)
);

reg [15:0] dma_off;
always @(posedge clk) begin
	if(ioctl_wr && ioctl_download && (ioctl_index == 8'h41)) begin
		if(ioctl_addr == 0) dma_off[7:0]  <= ioctl_dout;
		if(ioctl_addr == 1) dma_off[15:8] <= ioctl_dout;
	end
end


////////////////////////////////////////////////////////////////////
// Video 																			   //
////////////////////////////////////////////////////////////////////			

wire [2:0] G = {3{pix}};
wire [2:0] R = status[2] ? 3'd0 : G;
wire [2:0] B = R;

video_mixer #(.LINE_LENGTH(448), .HALF_DEPTH(1)) video_mixer
(
	.*,
	.clk_sys(clk),
	.ce_pix(ce_7mp),
	.ce_pix_actual(ce_7mp),

	.scanlines(scandoubler_disable ? 2'b00 : {status[6:5] == 3, status[6:5] == 2}),
	.hq2x(status[6:5]==1),

	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
);


////////////////////////////////////////////////////////////////////
// Audio 																			//
////////////////////////////////////////////////////////////////////		

assign AUDIO_R = AUDIO_L;
sigma_delta_dac #(.MSBI(1)) dac
(
	.CLK(clk),
	.RESET(reset),
	.DACin({audioDat ^ tape_write, tape_audio & tape_active & (status[8:7] == 2)}),
	.DACout(AUDIO_L)
);

assign LED = ~(tape_led | ioctl_download);

wire        tape_audio;
wire        tape_rd;
wire [24:0] tape_addr;
wire  [7:0] tape_data;
wire        tape_pause = 0;
wire        tape_active;
wire        tape_write;

tape tape(.*, .ioctl_download(ioctl_download && (ioctl_index==1)));

reg [18:0] act_cnt;
wire       tape_led = act_cnt[18] ? act_cnt[17:10] <= act_cnt[7:0] : act_cnt[17:10] > act_cnt[7:0];
always @(posedge clk) if((|status[8:7] ? ce_1m : ce_7mp) && (tape_active || act_cnt[18] || act_cnt[17:0])) act_cnt <= act_cnt + 1'd1; 


//////////////////////////////////////////////////////////////////////
// PS/2 to PET keyboard interface
//////////////////////////////////////////////////////////////////////
wire [7:0] 	keyin;
wire [3:0] 	keyrow;	 
wire        shift_lock;

keyboard keyboard(.*, .Fn(), .mod());

endmodule // pet2001


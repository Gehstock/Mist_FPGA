module b2m_mist
(
   input 			CLOCK_27,	
 	output 			LED,
   output     	 	SPI_DO,
   input       	SPI_DI,
   input       	SPI_SCK,
   input       	SPI_SS2,
   input       	SPI_SS3,
   input       	SPI_SS4,
   input       	CONF_DATA0, 
   inout [15:0]	SDRAM_DQ,       // SDRAM Data bus 16 Bits
   output [12:0]  SDRAM_A,        // SDRAM Address bus 13 Bits
   output         SDRAM_DQML,     // SDRAM Low-byte Data Mask
   output         SDRAM_DQMH,     // SDRAM High-byte Data Mask
   output         SDRAM_nWE,      // SDRAM Write Enable
   output         SDRAM_nCAS,     // SDRAM Column Address Strobe
   output         SDRAM_nRAS,     // SDRAM Row Address Strobe
   output         SDRAM_nCS,      // SDRAM Chip Select
   output [1:0]   SDRAM_BA,       // SDRAM Bank Address
   output         SDRAM_CLK,      // SDRAM Clock
   output         SDRAM_CKE,      // SDRAM Clock Enable
   output 			AUDIO_L,
   output 			AUDIO_R,
   output 			VGA_HS,
   output 			VGA_VS,
   output [5:0] 	VGA_R,
   output [5:0] 	VGA_G,
   output [5:0] 	VGA_B

);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"B2M;;",
	"O2,Turbo ,ON,OFF;",
	"O3,Color Mode ,COLOR,B/W;",
	"O4,Video Mode ,PAL,NTSC;",
	"O56,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T7,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1'b1;
wire clk_sys;
wire clk12p5;
wire clk100;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;

wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [15:0] audio;
//assign LED = 1;

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire  [3:0] r,g,b;


pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_sys),//50
	.c1(clk12p5)
	);
	
video_mixer #(.LINE_LENGTH(800), .HALF_DEPTH(0)) video_mixer(
	.clk_sys(clk_sys),
	.ce_pix(clk12p5),
	.ce_pix_actual(clk12p5),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r[1:0]}),
	.G({g,g[1:0]}),
	.B({b,b[1:0]}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1),//scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[6:5] == 3, status[6:5] == 2}),
	.hq2x(status[6:5]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);
	
mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io(
	.clk_sys        (clk_sys        ),
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
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         ),
	.sd_lba			 (sd_lba			  ),
	.sd_rd			 (sd_rd			  ),
	.sd_wr			 (sd_wr			  ),
	.sd_ack			 (sd_ack			  ),
	.sd_conf			 (sd_conf		  ),
	.sd_sdhc			 (sd_sdhc		  ),	
	.sd_buff_dout 	 (sd_data_out	  ),	
	.sd_buff_din    (sd_data_in	  ),	
	.sd_dout_strobe (sd_data_in_strobe),	
	.sd_din_strobe  (sd_data_out_strobe)		
	);
	
	
wire [31:0] sd_lba;
wire sd_rd;
wire sd_wr;
wire sd_ack;
wire sd_conf;
wire sd_sdhc;
wire allow_sdhc;
wire  [7:0] sd_data_in;
wire sd_data_in_strobe;
wire  [7:0] sd_data_out;
wire sd_data_out_strobe;	
wire sd_cs;
wire sd_sck;
wire sd_sdi;
wire sd_sdo;
	
sd_card sd_card(
	.io_lba			(sd_lba),
	.io_rd			(sd_rd),
	.io_wr			(sd_wr),
	.io_ack			(sd_ack),
	.io_conf			(sd_conf),
	.io_sdhc			(sd_sdhc),
	.io_din			(sd_data_out),
	.io_din_strobe	(sd_data_in_strobe),
	.io_dout			(sd_data_in),
	.io_dout_strobe(sd_data_out_strobe), 
	.allow_sdhc		(allow_sdhc),
	.sd_cs			(sd_cs),
	.sd_sck			(sd_sck),
	.sd_sdi			(sd_sdi),
	.sd_sdo			(sd_sdo)		
   );
	

b2m_top b2m_top(
	.clk50mhz(clk_sys),
	.res(~(status[0] || status[7] || buttons[1])),
	.color_mode(~status[3] ),
	.video_mode(status[4] ),
	.turbo(~status[2] ),
	.audio(audio),
	.DRAM_DQ(SDRAM_DQ),
	.DRAM_ADDR(SDRAM_A),
	.DRAM_LDQM(SDRAM_DQML),
	.DRAM_UDQM(SDRAM_DQMH),
	.DRAM_WE_N(SDRAM_nWE),
	.DRAM_CAS_N(SDRAM_nCAS),
	.DRAM_RAS_N(SDRAM_nRAS),
	.DRAM_CS_N(SDRAM_nCS),
	.DRAM_BA_0(SDRAM_BA[0]),
	.DRAM_BA_1(SDRAM_BA[1]),
	.DRAM_CLK(SDRAM_CLK),
	.DRAM_CKE(SDRAM_CKE),
	.VGA_HS(hs),
	.VGA_VS(vs),
	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),
	.PS2_CLK(ps2_kbd_clk),
	.PS2_DAT(ps2_kbd_data),
	.SD_DAT(sd_sdo),
	.SD_DAT3(sd_cs),
	.SD_CMD(sd_sdi),
	.SD_CLK(sd_sck)
	);

dac dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

endmodule

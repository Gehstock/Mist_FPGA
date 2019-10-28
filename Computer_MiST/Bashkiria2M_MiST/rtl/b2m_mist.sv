module b2m_mist(
   input 			CLOCK_27,
 	output 			LED,
   output     	 	SPI_DO,
   input       	SPI_DI,
   input       	SPI_SCK,
   input       	SPI_SS2,
   input       	SPI_SS3,
   input       	SPI_SS4,
   input       	CONF_DATA0, 
   inout [15:0]	SDRAM_DQ,
   output [12:0]  SDRAM_A,
   output         SDRAM_DQML,
   output         SDRAM_DQMH,
   output         SDRAM_nWE,
   output         SDRAM_nCAS,
   output         SDRAM_nRAS,
   output         SDRAM_nCS,
   output [1:0]   SDRAM_BA,
   output         SDRAM_CLK,
   output         SDRAM_CKE,
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
	"Bashkiria 2M;;",
	"O2,Turbo ,ON,OFF;",
	"O3,Color Mode ,COLOR,B/W;",
	"O4,Video Mode ,PAL,NTSC;",
	"O56,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"T7,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = 1'b1;
assign AUDIO_R = AUDIO_L;

wire clk_sys;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire        scandoublerD;
wire        ypbpr;
wire        ps2_kbd_clk;
wire        ps2_kbd_data;
wire  [15:0] audio;

wire hs, vs;
wire  [3:0] r,g,b;


pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_sys),//50
	);

b2m_top b2m_top(
	.clk50mhz(clk_sys),
	.res(~(status[0] | status[7] | buttons[1])),
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
	
mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(9)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r),
	.G              ( g),
	.B              ( b),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scandoubler_disable( 1'b1),//scandoublerD ),
	.scanlines      ( status[6:5]      ),
	.ce_divider		 (1),
	.ypbpr          ( ypbpr            )
	);
	
user_io #(.STRLEN(($size(CONF_STR)>>3))) user_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD   	  ),
	.ypbpr          (ypbpr          ),
	.ps2_kbd_clk    (ps2_kbd_clk     ),
	.ps2_kbd_data   (ps2_kbd_data    ),
	.status         (status         ),
	.sd_lba			 (sd_lba			  ),
	.sd_rd			 (sd_rd			  ),
	.sd_wr			 (sd_wr			  ),
	.sd_ack			 (sd_ack			  ),
	.sd_conf			 (sd_conf		  ),
	.sd_sdhc			 (sd_sdhc		  ),	
	.sd_dout 	    (sd_data_out	  ),	
	.sd_din         (sd_data_in	  ),	
	.sd_dout_strobe (sd_data_in_strobe),	
	.sd_din_strobe  (sd_data_out_strobe)
	);
	
dac #(
	.C_bits(16))
dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
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

endmodule

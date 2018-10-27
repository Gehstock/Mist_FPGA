module ColecoVision_MiST(
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
	
`include "build_id.v"
localparam CONF_STR = 
{
	"CVision;;",
	"F,COLBINROM;",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O4,Switch Joystick,Off,On;",
	"T6,Reset;",
	"V,v1.0.",`BUILD_DATE
};


wire clk_sys, clk_pix, clock_mem_s;
wire clock_vdp_en_s, clock_5m_en_s, clock_3m_en_s;
wire pll_locked_s;
wire reset_s = status[0] | status[6] | buttons[1] | ioctl_download;
wire [7:0]r, g, b;
wire hs, vs;
wire ypbpr;
wire [31:0]status;
wire scandoubler_disable;
wire [1:0] buttons, switches;
wire [7:0]audio;
assign SDRAM_A[12] = 1'b0;
assign LED = ~ioctl_download;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_ce, ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire [7:0] joy1, joy2;
wire [7:0] joya = status[4] ? joy2 : joy1;
wire [7:0] joyb = status[4] ? joy1 : joy2;				
wire [1:0]ctrl_p1_s;
wire [1:0]ctrl_p2_s;
wire [1:0]ctrl_p3_s;
wire [1:0]ctrl_p4_s;
wire [1:0]ctrl_p5_s;
wire [1:0]ctrl_p6_s;
wire [1:0]ctrl_p7_s	= 2'b11;
wire [1:0]ctrl_p8_s;
wire [1:0]ctrl_p9_s	= 2'b11;
wire [14:0]cart_addr;
wire [7:0]cart_do;
wire cart_en_80_n_s;
wire cart_en_a0_n_s;
wire cart_en_c0_n_s;
wire cart_en_e0_n_s;
wire [10:0]ps2_key;
wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
wire [16:0]ram_addr_s;//128K ???
wire [7:0]ram_do_s;
wire [7:0]ram_di_s;
wire ram_ce_s;
wire ram_oe_s;
wire ram_we_s;
wire [13:0]vram_addr_s;//16K
wire [7:0]vram_do_s;
wire [7:0]vram_di_s;
wire vram_ce_s;
wire vram_oe_s;
wire vram_we_s;

pll pll (
	.inclk0			(CLOCK_27),
	.c0				(clk_sys),//21.428571
	.c1				(clk_pix),//5.35714275
	.c2				(clock_mem_s),//100 MHz  0º
	.c3				(SDRAM_CLK),// 100 MHz -90°
	.locked			(pll_locked_s)
	);
	
clocks clocks (
	.clock_i			(clk_sys),
	.por_i			(~pll_locked_s),
	.clock_vdp_en_o(clock_vdp_en_s),
	.clock_5m_en_o	(clock_5m_en_s),
	.clock_3m_en_o	(clock_3m_en_s)
	);
		
colecovision #(
	.num_maq_g		(5),
	.compat_rgb_g	(0))
colecovision (
	.clock_i				(clk_sys),
	.clk_en_10m7_i		(clock_vdp_en_s),
	.clk_en_5m37_i		(clock_5m_en_s),
	.clk_en_3m58_i		(clock_3m_en_s),
	.reset_i				(reset_s),
	.por_n_i				(pll_locked_s),
//Controller Interface
	.ctrl_p1_i			(ctrl_p1_s),
	.ctrl_p2_i			(ctrl_p2_s),
	.ctrl_p3_i			(ctrl_p3_s),
	.ctrl_p4_i			(ctrl_p4_s),
	.ctrl_p5_o			(ctrl_p5_s),
	.ctrl_p6_i			(ctrl_p6_s),
	.ctrl_p7_i			(ctrl_p7_s),
	.ctrl_p8_o			(ctrl_p8_s),
	.ctrl_p9_i			(ctrl_p9_s),
//CPU RAM Interface
	.ram_addr_o			(ram_addr_s),
	.ram_ce_o			(ram_ce_s),
	.ram_we_o			(ram_we_s),
	.ram_oe_o			(ram_oe_s),
	.ram_data_i			(ram_do_s),
	.ram_data_o			(ram_di_s),
//Video RAM Interface
	.vram_addr_o		(vram_addr_s),
	.vram_ce_o			(vram_ce_s),
	.vram_oe_o			(vram_oe_s),
	.vram_we_o			(vram_we_s),
	.vram_data_i		(vram_do_s),
	.vram_data_o		(vram_di_s),
//Cartridge ROM Interface
	.cart_addr_o		(cart_addr),
	.cart_data_i		(cart_do),
	.cart_en_80_n_o	(cart_en_80_n_s),
	.cart_en_a0_n_o	(cart_en_a0_n_s),
	.cart_en_c0_n_o	(cart_en_c0_n_s),
	.cart_en_e0_n_o	(cart_en_e0_n_s),
//Audio Interface
	.audio_o				(audio),
//RGB Video Interface
	.col_o				(),
	.rgb_r_o				(r),
	.rgb_g_o				(g),
	.rgb_b_o				(b),
	.hsync_n_o			(hs),
	.vsync_n_o			(vs),
	.comp_sync_n_o		(),
//DEBUG
	.D_cpu_addr			()
	);
	
dac #(
	.msbi_g				(15))
dac (
	.clk_i				(clk_sys),
	.res_i				(reset_s),
	.dac_i				({~audio[7], audio[6:0], 8'b00000000}),
	.dac_o				(AUDIO_L)
	);
	
assign AUDIO_R = AUDIO_L;		
	
dpSDRAM64Mb #(
	.freq_g				(100))
dpSDRAM64Mb (
	.clock_i				(clock_mem_s),
	.reset_i				(reset_s),
	.refresh_i			(1'b1),
//Port 0
	.port0_cs_i			(vram_ce_s),
	.port0_oe_i			(vram_oe_s),
	.port0_we_i			(vram_we_s),
	.port0_addr_i		({"000011111",vram_addr_s}),
	.port0_data_i		(vram_di_s),
	.port0_data_o		(vram_do_s),
//Port 1
	.port1_cs_i			(ram_ce_s),
	.port1_oe_i			(ram_oe_s),
	.port1_we_i			(ram_we_s),
	.port1_addr_i		({"000000",ram_addr_s}),
	.port1_data_i		(ram_di_s),
	.port1_data_o		(ram_do_s),
//SDRAM in board
	.mem_cke_o			(SDRAM_CKE),
	.mem_cs_n_o			(SDRAM_nCS),
	.mem_ras_n_o		(SDRAM_nRAS),
	.mem_cas_n_o		(SDRAM_nCAS),
	.mem_we_n_o			(SDRAM_nWE),
	.mem_udq_o			(SDRAM_DQMH),
	.mem_ldq_o			(SDRAM_DQML),
	.mem_ba_o			(SDRAM_BA),
	.mem_addr_o			(SDRAM_A[11:0]),
	.mem_data_io		(SDRAM_DQ)
	);

cart cart (
	.clock(clk_sys),
	.address(ioctl_download ? ioctl_addr[14:0] : cart_addr),
	.data(ioctl_dout),
	.wren(ioctl_wr),
	.q(cart_do)
	);
		

always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX75: btn_up    <= pressed;
			'hX72: btn_down  <= pressed;
			'hX6B: btn_left  <= pressed;
			'hX74: btn_right <= pressed;
			'hX16: btn_1     <= pressed; // 1
			'hX1E: btn_2     <= pressed; // 2
			'hX26: btn_3     <= pressed; // 3
			'hX15: btn_4     <= pressed; // q
			'hX1D: btn_5     <= pressed; // w
			'hX24: btn_6     <= pressed; // e
			'hX1C: btn_7     <= pressed; // a
			'hX1B: btn_8     <= pressed; // s
			'hX23: btn_9     <= pressed; // d
			'hX1A: btn_s     <= pressed; // z
			'hX22: btn_0     <= pressed; // x
			'hX21: btn_p     <= pressed; // c
			'hX1F: btn_pt    <= pressed; // gui l
			'hX27: btn_pt    <= pressed; // gui r
			'hX11: btn_bt    <= pressed; // alt

			'hX25: btn_4     <= pressed; // 4
			'hX2E: btn_5     <= pressed; // 5
			'hX36: btn_6     <= pressed; // 6
			'hX3D: btn_7     <= pressed; // 7
			'hX3E: btn_8     <= pressed; // 8
			'hX46: btn_9     <= pressed; // 9
			'hX45: btn_0     <= pressed; // 0

			'h012: btn_arm   <= pressed; // shift l
			'h059: btn_arm   <= pressed; // shift r
			'hX14: btn_fire  <= pressed; // ctrl
		endcase
	end
end

reg btn_up    = 0;
reg btn_down  = 0;
reg btn_left  = 0;
reg btn_right = 0;
reg btn_1     = 0;
reg btn_2     = 0;
reg btn_3     = 0;
reg btn_4     = 0;
reg btn_5     = 0;
reg btn_6     = 0;
reg btn_7     = 0;
reg btn_8     = 0;
reg btn_9     = 0;
reg btn_s     = 0;
reg btn_0     = 0;
reg btn_p     = 0;
reg btn_pt    = 0;
reg btn_bt    = 0;
reg btn_arm   = 0;
reg btn_fire  = 0;

wire m_right  = btn_right | joya[0];
wire m_left   = btn_left  | joya[1];
wire m_down   = btn_down  | joya[2];
wire m_up     = btn_up    | joya[3];
wire m_fire   = btn_fire  | joya[4];
wire m_arm    = btn_arm   | joya[5];
wire m_1      = btn_1;
wire m_2      = btn_2;
wire m_3      = btn_3;
wire m_s      = btn_s   | joya[6];
wire m_0      = btn_0;
wire m_p      = btn_p   | joya[7];
wire m_pt     = btn_pt;
wire m_bt     = btn_bt;

wire [0:19] keypad0 = {m_0,m_1,m_2,		m_3,btn_4,btn_5,		btn_6,btn_7,btn_8,		btn_9,m_s,m_p,			m_pt,m_bt,m_up,			m_down,m_left,m_right,		m_fire,m_arm};
wire [0:19] keypad1 = {1'b0,1'b0,1'b0,		1'b0,1'b0,1'b0,		1'b0,1'b0,1'b0,		1'b0,joyb[6],joyb[7],		1'b0,1'b0,joyb[3],			joyb[2],joyb[1],joyb[0],		joyb[4],joyb[5]};
wire [0:19] keypad[2] = '{keypad0,keypad1};

reg [3:0] ctrl1[2] = '{'0,'0};
assign {ctrl_p1_s[0],ctrl_p2_s[0],ctrl_p3_s[0],ctrl_p4_s[0]} = ctrl1[0];
assign {ctrl_p1_s[1],ctrl_p2_s[1],ctrl_p3_s[1],ctrl_p4_s[1]} = ctrl1[1];

localparam cv_key_0_c        = 4'b0011;
localparam cv_key_1_c        = 4'b1110;
localparam cv_key_2_c        = 4'b1101;
localparam cv_key_3_c        = 4'b0110;
localparam cv_key_4_c        = 4'b0001;
localparam cv_key_5_c        = 4'b1001;
localparam cv_key_6_c        = 4'b0111;
localparam cv_key_7_c        = 4'b1100;
localparam cv_key_8_c        = 4'b1000;
localparam cv_key_9_c        = 4'b1011;
localparam cv_key_asterisk_c = 4'b1010;
localparam cv_key_number_c   = 4'b0101;
localparam cv_key_pt_c       = 4'b0100;
localparam cv_key_bt_c       = 4'b0010;
localparam cv_key_none_c     = 4'b1111;

generate 
	genvar i;
	for (i = 0; i <= 1; i++) begin : ctl
		always_comb begin
			reg [3:0] ctl1, ctl2;
			reg p61,p62;
			
			ctl1 = 4'b1111;
			ctl2 = 4'b1111;
			p61 = 1;
			p62 = 1;

			if (~ctrl_p5_s[i]) begin
				casex(keypad[i][0:13]) 
					'b1xxxxxxxxxxxxx: ctl1 = cv_key_0_c;
					'b01xxxxxxxxxxxx: ctl1 = cv_key_1_c;
					'b001xxxxxxxxxxx: ctl1 = cv_key_2_c;
					'b0001xxxxxxxxxx: ctl1 = cv_key_3_c;
					'b00001xxxxxxxxx: ctl1 = cv_key_4_c;
					'b000001xxxxxxxx: ctl1 = cv_key_5_c;
					'b0000001xxxxxxx: ctl1 = cv_key_6_c;
					'b00000001xxxxxx: ctl1 = cv_key_7_c;
					'b000000001xxxxx: ctl1 = cv_key_8_c;
					'b0000000001xxxx: ctl1 = cv_key_9_c;
					'b00000000001xxx: ctl1 = cv_key_asterisk_c;
					'b000000000001xx: ctl1 = cv_key_number_c;
					'b0000000000001x: ctl1 = cv_key_pt_c;
					'b00000000000001: ctl1 = cv_key_bt_c;
					'b00000000000000: ctl1 = cv_key_none_c;
				endcase
				p61 = ~keypad[i][19]; // button 2
			end

			if (~ctrl_p8_s[i]) begin
				ctl2 = ~keypad[i][14:17];
				p62 = ~keypad[i][18];  // button 1
			end
			
			ctrl1[i] = ctl1 & ctl2;
			ctrl_p6_s[i] = p61 & p62;
		end
	end
endgenerate



mist_io #(
	.STRLEN			($size(CONF_STR)>>3)
	)
user_io (
	.clk_sys			(clk_sys			),
	.CONF_DATA0		(CONF_DATA0		),
	.SPI_SCK			(SPI_SCK			),
	.SPI_DI			(SPI_DI			),
	.SPI_DO			(SPI_DO			),
	.SPI_SS2			(SPI_SS2			),	
	.conf_str		(CONF_STR		),
	.ypbpr			(ypbpr			),
	.status			(status			),
	.scandoubler_disable(scandoubler_disable),
	.buttons			(buttons			),
	.switches		(switches		),
	.ps2_key			(ps2_key			),
	.joystick_0		(joy1				),
	.joystick_1		(joy2				),
	.ioctl_ce		(ioctl_ce		),
	.ioctl_wr		(ioctl_wr		),
	.ioctl_index	(ioctl_index	),
	.ioctl_download(ioctl_download),	
	.ioctl_addr		(ioctl_addr		),
	.ioctl_dout		(ioctl_dout		)
	);

video_mixer #(
	.LINE_LENGTH	(290				), 
	.HALF_DEPTH		(0					)
	) 
video_mixer (
	.clk_sys			(clk_sys		),
	.ce_pix			(clk_pix		),
	.ce_pix_actual	(clk_pix		),
	.SPI_SCK			(SPI_SCK		),
	.SPI_SS3			(SPI_SS3		),
	.SPI_DI			(SPI_DI			),
	.R					(r[7:2]),
	.G					(g[7:2]),
	.B					(b[7:2]),
	.HSync			(hs				),
	.VSync			(vs	   		),
	.VGA_R			(VGA_R			),
	.VGA_G			(VGA_G			),
	.VGA_B			(VGA_B			),
	.VGA_VS			(VGA_VS			),
	.VGA_HS			(VGA_HS			),
	.scanlines		(scandoubler_disable ? 2'b00 : {status[3:2] == 3, status[3:2] == 2}),
	.scandoubler_disable(scandoubler_disable),
	.hq2x				(status[3:2]==1),
	.ypbpr			(ypbpr			),
	.ypbpr_full		(1				),
	.line_start		(0				),
	.mono				(0				)
	);

endmodule 
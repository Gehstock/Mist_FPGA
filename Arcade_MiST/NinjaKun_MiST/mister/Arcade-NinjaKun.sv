//============================================================================
//  Arcade: Ninja-Kun -- Majyo no Bouken --
//
//  Original implimentation and port to MiSTer by MiSTer-X 2019
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S    // 1 - signed audio samples, 0 - unsigned
);

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : 8'd4;
assign HDMI_ARY = status[1] ? 8'd9  : 8'd3;

`include "build_id.v" 
localparam CONF_STR = {
	"A.NinjaKun;;",

	"F,rom;",		// allow loading of alternate ROMs
	"-;",
	"O1,Aspect Ratio,Original,Wide;",
	"-;",
	"O8,Difficulty,Normal,Hard;",
	"O9A,Lives,4,3,2,5;",
	"OB,1st Extra,30000,40000;",
	"OCD,2nd Extra (Every),50000,70000,90000,None;",
	"OF,Allow Continue,No,Yes;",
	"OG,Free Play,No,Yes;",
	"OH,Endless(If Free Play),No,Yes;",
	"OE,Demo Sound,Off,On;",
	"OI,Name Letters,8,3;",
	"-;",
	"R0,Reset;",
	"J1,Shot,Jump,Start 1P,Start 2P,Coin;",
	"V,v",`BUILD_DATE
};


`define CABINET			1'b0				// Upright=0,Table=1
`define DIFFICULTY		~status[8]		// Hard=0,Normal=1
`define LIVES				~status[10:9]	// 00=5,01=2,10=3,11=4
`define EXTEND1ST			~status[11]		// 40000=0,30000=1
`define EXTEND2ND			~status[13:12]	// None,30000,50000,70000
`define DEMOSOUND			~status[14]		// On=0,Off=1

`define ALLOW_CONTINUE	~status[15]		// Yes=0,NO=1
`define FREEPLAY			~status[16]		// Yes=0,No=1
`define ENDLESS			~status[17]		// Yes=0,No=1 (If FreePlay)
`define NAMELETTERS 		~status[18]		// 3Letters=0,8Letters=1
`define COINAGE			3'b111			// 1C/1C


wire bCabinet  = `CABINET; 	// (upright only)


////////////////////   CLOCKS   ///////////////////

wire clk_hdmi;
wire clk_49M;
wire clk_sys = clk_49M;

pll pll
(
	.rst(0),
	.refclk(CLK_50M),
	.outclk_0(clk_49M),
	.outclk_1(clk_hdmi)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;
wire [15:0] joystk1, joystk2;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joystk1),
	.joystick_1(joystk2),
	.ps2_key(ps2_key)
);

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX75: btn_up          <= pressed; // up
			'hX72: btn_down        <= pressed; // down
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right
			'h029: btn_trig1       <= pressed; // space
			'h014: btn_trig2       <= pressed; // ctrl
			'h005: btn_one_player  <= pressed; // F1
			'h006: btn_two_players <= pressed; // F2

			// JPAC/IPAC/MAME Style Codes
			'h016: btn_start_1     <= pressed; // 1
			'h01E: btn_start_2     <= pressed; // 2
			'h02E: btn_coin_1      <= pressed; // 5
			'h036: btn_coin_2      <= pressed; // 6
			'h02D: btn_up_2        <= pressed; // R
			'h02B: btn_down_2      <= pressed; // F
			'h023: btn_left_2      <= pressed; // D
			'h034: btn_right_2     <= pressed; // G
			'h01C: btn_trig1_2     <= pressed; // A
			'h01B: btn_trig2_2     <= pressed; // S
		endcase
	end
end

reg btn_up    = 0;
reg btn_down  = 0;
reg btn_right = 0;
reg btn_left  = 0;
reg btn_trig1 = 0;
reg btn_trig2 = 0;
reg btn_one_player  = 0;
reg btn_two_players = 0;

reg btn_start_1 = 0;
reg btn_start_2 = 0;
reg btn_coin_1  = 0;
reg btn_coin_2  = 0;
reg btn_up_2    = 0;
reg btn_down_2  = 0;
reg btn_left_2  = 0;
reg btn_right_2 = 0;
reg btn_trig1_2  = 0;
reg btn_trig2_2  = 0;


wire m_up2     = btn_up_2    | joystk2[3];
wire m_down2   = btn_down_2  | joystk2[2];
wire m_left2   = btn_left_2  | joystk2[1];
wire m_right2  = btn_right_2 | joystk2[0];
wire m_trig21  = btn_trig1_2 | joystk2[4];
wire m_trig22  = btn_trig2_2 | joystk2[5];

wire m_start1  = btn_one_player  | joystk1[6] | joystk2[6] | btn_start_1;
wire m_start2  = btn_two_players | joystk1[7] | joystk2[7] | btn_start_2;

wire m_up1     = btn_up      | joystk1[3] | (bCabinet ? 1'b0 : m_up2);
wire m_down1   = btn_down    | joystk1[2] | (bCabinet ? 1'b0 : m_down2);
wire m_left1   = btn_left    | joystk1[1] | (bCabinet ? 1'b0 : m_left2);
wire m_right1  = btn_right   | joystk1[0] | (bCabinet ? 1'b0 : m_right2);
wire m_trig11  = btn_trig1   | joystk1[4] | (bCabinet ? 1'b0 : m_trig21);
wire m_trig12  = btn_trig2   | joystk1[5] | (bCabinet ? 1'b0 : m_trig22);

wire m_coin1   = btn_one_player | btn_coin_1 | joystk1[8];
wire m_coin2   = btn_two_players| btn_coin_2 | joystk2[8];
wire m_coin    = m_coin1|m_coin2;


///////////////////////////////////////////////////

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire [3:0] r,g,b;

reg ce_pix;
always @(posedge clk_hdmi) begin
	reg old_clk;
	old_clk <= ce_vid;
	ce_pix  <= old_clk & ~ce_vid;
end

arcade_rotate_fx #(256,192,12) arcade_video
(
	.*,

	.clk_video(clk_hdmi),

	.RGB_in({r,g,b}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs),
	.VSync(~vs),

	.fx(0),
	.no_rotate(1'b1)
);

wire			PCLK;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;
HVGEN hvgen
(
	.HPOS(HPOS),.VPOS(VPOS),.PCLK(PCLK),.iRGB(POUT),
	.oRGB({b,g,r}),.HBLK(hblank),.VBLK(vblank),.HSYN(hs),.VSYN(vs)
);
assign ce_vid = PCLK;


wire [15:0] AOUT;
assign AUDIO_L = AOUT;
assign AUDIO_R = AOUT;
assign AUDIO_S = 1'b0; // unsigned


///////////////////////////////////////////////////

wire  [7:0] iDSW1 =  {`DIFFICULTY,`DEMOSOUND,`EXTEND2ND,`EXTEND1ST,`LIVES, `CABINET};	// 8'b1_0_01_1_10_0;
wire  [7:0] iDSW2 =  {`ENDLESS,`FREEPLAY,1'b0,`ALLOW_CONTINUE,`NAMELETTERS,`COINAGE};	// 8'b1_1_0_0_1_111; 

wire  [7:0] iCTR1 = ~{     2'b11,    m_start1, 1'b0, m_trig11, m_trig12, m_right1, m_left1 };
wire  [7:0] iCTR2 = ~{ ~m_coin,1'b1, m_start2, 1'b0, m_trig21, m_trig22, m_right2, m_left2 };

wire			iRST  = RESET | status[0] | buttons[1] | ioctl_download;

wire  [7:0] oPIX;
assign		POUT = {{oPIX[7:6],oPIX[1:0]},{oPIX[5:4],oPIX[1:0]},{oPIX[3:2],oPIX[1:0]}};


FPGA_NINJAKUN GameCore
(
	.RESET(iRST),.MCLK(clk_49M),

	.CTR1(iCTR1),.CTR2(iCTR2),
	.DSW1(iDSW1),.DSW2(iDSW2),

	.PH(HPOS),.PV(VPOS),
	.PCLK(PCLK),.POUT(oPIX),
	.SNDOUT(AOUT),

	.ROMCL(clk_sys),.ROMAD(ioctl_addr),.ROMDT(ioctl_dout),.ROMEN(ioctl_wr)
);

endmodule


module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	 [11:0]		iRGB,

	output reg [11:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-16;
assign VPOS = vcnt-16;

always @(posedge PCLK) begin
	case (hcnt)
	    15: begin HBLK <= 0; hcnt <= hcnt+1; end
		272: begin HBLK <= 1; hcnt <= hcnt+1; end
		311: begin HSYN <= 0; hcnt <= hcnt+1; end
		342: begin HSYN <= 1; hcnt <= 471;    end
		511: begin hcnt <= 0;
			case (vcnt)
				 15: begin VBLK <= 0; vcnt <= vcnt+1; end
				207: begin VBLK <= 1; vcnt <= vcnt+1; end
				226: begin VSYN <= 0; vcnt <= vcnt+1; end
				233: begin VSYN <= 1; vcnt <= 483;	  end
				511: begin vcnt <= 0; end
				default: vcnt <= vcnt+1;
			endcase
		end
		default: hcnt <= hcnt+1;
	endcase
	oRGB <= (HBLK|VBLK) ? 12'h0 : iRGB;
end

endmodule



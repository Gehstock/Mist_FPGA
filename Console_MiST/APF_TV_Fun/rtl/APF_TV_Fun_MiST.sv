module APF_TV_Fun_MiST
(
	input         CLOCK_27,
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
	input         CONF_DATA0
);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"APF_TV_fun;;",
//	"O1,Sound		,On,Off;",
	"O23,Game		,Tennis,Soccer,Squash,Practice;",
//	"O13,Game		,Hidden,Tennis,Soccer,Squash,Practice,gameRifle1,gameRifle2;",
	"O4,Serve		,Auto,Manual;",
	"O5,Ball Angle	,20deg,40deg;", //check
	"O6,Bat Size	,Small,Big;",	//check
	"O7,Ball Speed	,Fast,Slow;",
	"T8,Start;",
 
	"T9,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign AUDIO_R = AUDIO_L;
assign LED = 1'b1;

wire 			clk_16, clk_2;
pll pll(
	.inclk0			( CLOCK_27	),
	.areset			( 0			),
	.c0				( clk_16		),
	.c1				( clk_2		)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [15:0] kbjoy;
wire  [10:0] ps2_key;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire			scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  		audio;
wire 			hs, vs;
wire 			vid_play, vid_RP, vid_LP, vid_Ball;
wire 			video = vid_play | vid_RP | vid_LP | vid_Ball;
wire			gameTennis;
wire			gameSoccer;
wire			gameSquash;
wire			gamePractice;
wire			gameRifle1;
wire			gameRifle2;
wire 			m_left, m_right;
wire 			LPin, RPin, Rifle1, Rifle2;


always @(*) begin
 case (status[3:2])
// 3'b001  : begin gameTennis <= 0; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1; end
//	3'b010  : begin gameTennis <= 1; gameSoccer <= 0; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
// 3'b011  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 0; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
//	3'b100  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 0; gameRifle1 <= 1; gameRifle2 <= 1;  end	
//	3'b101  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 0; gameRifle2 <= 1;  end
//	3'b111  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 0;  end	
//	default : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
	
	2'b01  : begin gameTennis <= 1; gameSoccer <= 0; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
   2'b10  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 0; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
	2'b11  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 0; gameRifle1 <= 1; gameRifle2 <= 1;  end
	default : begin gameTennis <= 0; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
 endcase
end

ay38500NTSC ay38500NTSC(
	.clk(clk_2),
	.reset(~(buttons[1] | status[0] | status[9])),
	.pinSound(audio),
	//Video
	.pinBallOut(vid_Ball),
	.pinRPout(vid_RP),
	.pinLPout(vid_LP),
	.pinSFout(vid_play),
	.vsync(vs),
   .hsync(hs),
	//Menu Items
	.pinManualServe(status[4] | joystick_0[4] | joystick_1[4]),
	.pinBallAngle(status[5]),
	.pinBatSize(status[6]),
	.pinBallSpeed(status[7]),
	//Game Select
	.pinRifle1(1'b1),//							?
	.pinRifle2(1'b1),//							?
	.pinTennis(gameTennis),
	.pinSoccer(gameSoccer),
	.pinSquash(gameSquash),
	.pinPractice(gamePractice),	
	
	.pinShotIn(1'b1),//							todo
	.pinHitIn(1'b0),//							todo
	.pinRifle1_DWN(Rifle1),//					?
	.pinTennis_DWN(Rifle2),//					?
	.pinRPin_DWN(RPin),
	.pinLPin_DWN(LPin),
	.pinRPin(m_right),//							todo
	.pinLPin(m_left)//							todo
	);

dac #(
	.c_bits(8))
dac (
	.clk_i			(clk_16		),
	.res_n_i			(1				),
	.dac_i			({8{audio}} ),
	.dac_o			(AUDIO_L		)
	);

mist_video #(
	.SD_HCNT_WIDTH(10),//wrong
	.COLOR_DEPTH(1)) 
mist_video(
	.clk_sys(clk_16),
	.SPI_DI(SPI_DI),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.HSync(~hs),
	.VSync(~vs),
	.R(video),
	.G(video),
	.B(video),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B)
);

user_io #(.STRLEN(($size(CONF_STR)>>3))) user_io (
	.clk_sys       ( clk_16       ),
	.conf_str      ( CONF_STR     ),
	.SPI_CLK       ( SPI_SCK      ),
	.SPI_SS_IO     ( CONF_DATA0   ),
	.SPI_MISO      ( SPI_DO       ),
	.SPI_MOSI      ( SPI_DI       ),
	.buttons       ( buttons      ),
	.switches      ( switches     ),
	.ypbpr         ( ypbpr        ),
	.key_strobe    (key_strobe    ),
	.key_pressed   (key_pressed   ),
	.key_code      (key_code      ),
	.scandoubler_disable(scandoubler_disable),
	.joystick_0    ( joystick_0   ),
	.joystick_1    ( joystick_1   ),
	.status        ( status       )
	);
	


endmodule 
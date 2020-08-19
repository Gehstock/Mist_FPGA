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
	"O13,Game		,Tennis,Soccer,Handicap,Squash,Practice,Rifle1,Rifle2;",
	"O4,Serve		,Manual,Auto;",
	"O5,Ball Angle	,20deg,40deg;", //check
	"O6,Bat Size	,Small,Big;",	//check
	"O7,Ball Speed	,Fast,Slow;", //check
	"O8,Invisiball,OFF,ON;",
	"O9C,Color Pallette,Mono,Greyscale,RGB1,RGB2,Field,Ice,Christmas,Marksman,Las Vegas;",
	"T0,Reset;",
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
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire			scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  		audio;
wire 			hs, vs;
wire 			vid_play, vid_RP, vid_LP, vid_Ball;
reg   [7:0] gameSelect = 7'b0000001;//Default to Tennis


always @(clk_16) begin
 case (status[3:1])
	3'b000  : gameSelect = 7'b0000001;//Tennis
	3'b001  : gameSelect = 7'b0000010;//Soccer
	3'b010  : gameSelect = 7'b0000100;//Handicap (using a dummy bit)
	3'b011  : gameSelect = 7'b0001000;//Squash
	3'b100  : gameSelect = 7'b0010000;//Practice
	3'b101  : gameSelect = 7'b0100000;//Rifle 1
	3'b110  : gameSelect = 7'b1000000;//Rifle 1
	default : gameSelect = 7'b0000001;//Tennis
 endcase
end

/////////////////Paddle Emulation//////////////////
wire [4:0] paddleMoveSpeed = status[7] ? 8 : 5;//Faster paddle movement when ball speed is high
reg [8:0] player1pos = 8'd128;
reg [8:0] player2pos = 8'd128;
reg [8:0] player1cap = 0;
reg [8:0] player2cap = 0;
reg hsOld = 0;
reg vsOld = 0;

always @(posedge clk_16) begin
	hsOld <= hs;
	vsOld <= vs;
	if(vs & !vsOld) begin
		player1cap <= player1pos;
		player2cap <= player2pos;
		if(m_up & player1pos>0)
			player1pos <= player1pos - paddleMoveSpeed;
		else if(m_down & player1pos<8'hFF)
			player1pos <= player1pos + paddleMoveSpeed;
		if(m_up2 & player2pos>0)
			player2pos <= player2pos - paddleMoveSpeed;
		else if(m_down2 & player2pos < 8'hFF)
			player2pos <= player2pos + paddleMoveSpeed;
	end
	else if(hs & !hsOld) begin
		if(player1cap!=0)
			player1cap <= player1cap - 1;
		if(player2cap!=0)
			player2cap <= player2cap - 1;
	end
end

wire [3:0] r,g,b;
wire hb = !hs;
wire vb = !vs;
wire blankn = ~(hb | vb);
wire showBall = !status[8] | (ballHide>0);
reg [5:0] ballHide = 0;
reg audioOld = 0;
always @(clk_16) begin
	audioOld <= audio;
	if(!audioOld & audio)
		ballHide <= 5'h1F;
	else if(vs & !vsOld & ballHide!=0)
		ballHide <= ballHide - 1;
end
reg [12:0] colorOut = 0;
always @(posedge clk_16) begin
	if(vid_Ball & showBall) begin
		case(status[13:9])
			'h0: colorOut <= 12'hFFF;//Mono
			'h1: colorOut <= 12'hFFF;//Greyscale
			'h2: colorOut <= 12'hF00;//RGB1
			'h3: colorOut <= 12'hFFF;//RGB2
			'h4: colorOut <= 12'h000;//Field
			'h5: colorOut <= 12'h000;//Ice
			'h6: colorOut <= 12'hFFF;//Christmas
			'h7: colorOut <= 12'hFFF;//Marksman
			'h8: colorOut <= 12'hFF0;//Las Vegas
		endcase
	end
	else if(vid_LP) begin
		case(status[13:9])
			'h0: colorOut <= 12'hFFF;//Mono
			'h1: colorOut <= 12'hFFF;//Greyscale
			'h2: colorOut <= 12'h0F0;//RGB1
			'h3: colorOut <= 12'h00F;//RGB2
			'h4: colorOut <= 12'hF00;//Field
			'h5: colorOut <= 12'hF00;//Ice
			'h6: colorOut <= 12'hF00;//Christmas
			'h7: colorOut <= 12'hFF0;//Marksman
			'h8: colorOut <= 12'hFF0;//Las Vegas
		endcase
	end
	else if(vid_RP) begin
		case(status[13:9])
			'h0: colorOut <= 12'hFFF;//Mono
			'h1: colorOut <= 12'h000;//Greyscale
			'h2: colorOut <= 12'h0F0;//RGB1
			'h3: colorOut <= 12'hF00;//RGB2
			'h4: colorOut <= 12'h00F;//Field
			'h5: colorOut <= 12'h030;//Ice
			'h6: colorOut <= 12'h030;//Christmas
			'h7: colorOut <= 12'h000;//Marksman
			'h8: colorOut <= 12'hF0F;//Las Vegas
		endcase
	end
	else if(vid_play) begin
		case(status[13:9])
			'h0: colorOut <= 12'hFFF;//Mono
			'h1: colorOut <= 12'hFFF;//Greyscale
			'h2: colorOut <= 12'h00F;//RGB1
			'h3: colorOut <= 12'h0F0;//RGB2
			'h4: colorOut <= 12'hFFF;//Field
			'h5: colorOut <= 12'h55F;//Ice
			'h6: colorOut <= 12'hFFF;//Christmas
			'h7: colorOut <= 12'hFFF;//Marksman
			'h8: colorOut <= 12'hF90;//Las Vegas
		endcase
	end
	else begin
		case(status[13:9])
			'h0: colorOut <= 12'h000;//Mono
			'h1: colorOut <= 12'h999;//Greyscale
			'h2: colorOut <= 12'h000;//RGB1
			'h3: colorOut <= 12'h000;//RGB2
			'h4: colorOut <= 12'h4F4;//Field
			'h5: colorOut <= 12'hCCF;//Ice
			'h6: colorOut <= 12'h000;//Christmas
			'h7: colorOut <= 12'h0D0;//Marksman
			'h8: colorOut <= 12'h000;//Las Vegas
		endcase
	end
end

wire hitIn;// = (gameBtns[5:5] | gameBtns[6:6]) ? btnHit : audio;
//Still unknown why example schematic instructs connecting hitIn pin to audio during ball games
wire shotIn;// = (gameBtns[5:5] | gameBtns[6:6]) ? (btnHit | btnMiss) : 1;
wire LPin = (player1cap == 0);
wire RPin = (player2cap == 0);

wire ltest;
ay38500NTSC ay38500NTSC(
	.clk(clk_2),
	.superclock(CLOCK_27),
	.reset(~(buttons[1] | status[0])),
	.pinSound(audio),
	//Video
	.pinBallOut(vid_Ball),
	.pinRPout(vid_RP),
	.pinLPout(vid_LP),
	.pinSFout(vid_play),	
	.syncV(vs),
   .syncH(hs),
	//Menu Items
	.pinManualServe(~(status[4] | m_fireA | m_fire2A)),
	.pinBallAngle(status[5]),
	.pinBatSize(status[6]),
	.pinBallSpeed(status[7]),
	//Game Select
	.pinPractice(!gameSelect[4:4]),
	.pinSquash(!gameSelect[3:3]),
	.pinSoccer(!gameSelect[1:1]),
	.pinTennis(!gameSelect[0:0]),
	.pinRifle1(!gameSelect[5:5]),
	.pinRifle2(!gameSelect[6:6]),
	
	.pinHitIn(hitIn),
	.pinShotIn(shotIn),
	.pinLPin(LPin),
	.pinRPin(RPin)
	);

dac #(
	.c_bits(16))
dac (
	.clk_i			(clk_16		),
	.res_n_i			(1				),
	.dac_i			({audio, 15'b0}),
	.dac_o			(AUDIO_L		)
	);

mist_video #(
	.SD_HCNT_WIDTH(12),//wrong
	.COLOR_DEPTH(4)) 
mist_video(
	.clk_sys(clk_16),
	.SPI_DI(SPI_DI),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.HSync(~hs),
	.VSync(~vs),
	.R(colorOut[11:8]),
	.G(colorOut[7:4]),
	.B(colorOut[3:0]),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B)
);

wire          key_pressed;
wire          key_extended;
wire    [7:0] key_code;
wire          key_strobe;

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
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
 
arcade_inputs inputs (
        .clk         ( clk_16    ),
        .key_strobe  ( key_strobe  ),
        .key_pressed ( key_pressed ),
        .key_code    ( key_code    ),
        .joystick_0  ( joystick_0  ),
        .joystick_1  ( joystick_1  ),
        .rotate      ( 1'b0        ),
        .orientation ( 2'b10       ),
        .joyswap     ( 1'b0        ),
        .oneplayer   ( 1'b0        ),
        .controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
        .player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
        .player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
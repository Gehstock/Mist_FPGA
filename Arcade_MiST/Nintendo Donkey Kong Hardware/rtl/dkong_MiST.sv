module dkong_MiST(
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
	input         CLOCK_27
);


`include "rtl\build_id.v" 

localparam CONF_STR = {
	"DKONG;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T6,Reset;",
	"O89,Lives,3,4,5,6;",
	"OAB,Bonus,7000,10000,15000,20000;",
	"V,v1.20.",`BUILD_DATE
};

assign 		LED = 1;
assign 		AUDIO_R = AUDIO_L;

wire clock_24, clock_6;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_24),//W_CLK_24576M
	.c2(clock_6)//W_CLK_6144M
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [10:0] ps2_key;
wire [7:0] audio;
wire 			hs, vs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire [2:0] 	r, g;
wire [1:0] 	b;

	
dkong_top dkong(				   
	.I_CLK_24576M(clock_24),
	.I_RESETn(~(status[0] | status[6] | buttons[1])),
//	.O_PIX(clock_6),//Timing Issue
	.I_U1(~m_up),
	.I_D1(~m_down),
	.I_L1(~m_left),
	.I_R1(~m_right),
	.I_J1(~m_fire),
	.I_U2(~m_up),
	.I_D2(~m_down),
	.I_L2(~m_left),
	.I_R2(~m_right),
	.I_J2(~m_fire),
	.I_S1(~btn_one_player),
	.I_S2(~btn_two_players),
	.I_C1(~btn_coin),
	.I_DIP_SW({ ~status[12] , 1'b0,1'b0,1'b0 , status[11:10], status[9:8]}),
	.O_SOUND_DAT(audio),
	.O_VGA_R(r),
	.O_VGA_G(g),
	.O_VGA_B(b),
	.O_H_BLANK(hb),
	.O_V_BLANK(vb),
	.O_VGA_H_SYNCn(hs),
	.O_VGA_V_SYNCn(vs)
	);


video_mixer video_mixer(
	.clk_sys(clock_24),
	.ce_pix(clock_6),
	.ce_pix_actual(clock_6),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : "000"),
	.G(blankn ? g : "000"),
	.B(blankn ? {1'b0,b} : "000"),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b1,status[2]}),
	.scandoublerD(scandoublerD),
	.scanlines(scandoublerD ? 2'b00 : status[4:3]),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(
	.STRLEN(($size(CONF_STR)>>3)))
mist_io(
	.clk_sys        (clock_24       ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoublerD	 (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.ps2_key			 (ps2_key        ),
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);
	
dac #(
	.C_bits(15))
dac(
	.clk_i(clock_24),
	.res_n_i(1'b1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);
	
wire m_up     = btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = btn_right | joystick_0[0] | joystick_1[0];
wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_coin  = 0;
wire       pressed = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];	

always @(posedge clock_24) begin
	reg old_state;
	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		case(code)
			'h75: btn_up         	<= pressed; // up
			'h72: btn_down        	<= pressed; // down
			'h6B: btn_left      		<= pressed; // left
			'h74: btn_right       	<= pressed; // right
			'h76: btn_coin				<= pressed; // ESC
			'h05: btn_one_player   	<= pressed; // F1
			'h06: btn_two_players  	<= pressed; // F2
			'h29: btn_fire1   		<= pressed; // Space
		endcase
	end
end


endmodule

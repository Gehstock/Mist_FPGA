module ComputerSpace_MiST(
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

`include "build_id.v" 

localparam CONF_STR = {
	"C.SPACE;;",
//	"O1,Self_Test,Off,On;",
	"O2,Color,No,Yes;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
	};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire [15:0] audio;
wire  [3:0] video;
wire hs, vs, blank;
assign LED = 1;
wire clk_sys, clk_25, clk_6p25, clk_5;

pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_sys),//50 MHz for game/sound generator? 
	.c1(clk_25), //4x pixel clock
	.c3(clk_5) //5,842 MHz pixel/game clock
	);

video_mixer video_mixer(
	.clk_sys(clk_25),
	.ce_pix(clk_5),
	.ce_pix_actual(clk_5),
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
	.scandoubler_disable(scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(
	.STRLEN(($size(CONF_STR)>>3))) 
mist_io(
	.clk_sys        (clk_sys   	  ),
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
	.ps2_key    	 (ps2_key    	  ),
	.joystick_0   	 (joystick_0	  ),
	.joystick_1     (joystick_1	  ),
	.status         (status         )
	);

wire [64:0] ps2_key;
wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;
wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];

always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX6B: btn_left   <= pressed; // left
			'hX74: btn_right  <= pressed; // right
			'h029: btn_thrust <= pressed; // space
			'h014: btn_fire   <= pressed; // ctrl
			'h005: btn_start  <= pressed; // F1
		endcase
	end
end

reg btn_right = 0;
reg btn_left  = 0;
reg btn_fire  = 0;
reg btn_thrust= 0;
reg btn_start = 0;

wire m_left   = btn_left   | joy[1];
wire m_right  = btn_right  | joy[0];
wire m_thrust = btn_thrust | joy[4];
wire m_fire   = btn_fire   | joy[5];
wire m_start  = btn_start  | joy[6];
 
computer_space_top computerspace(
	.reset(buttons[1] | status[0] | status[6]),
	.clock_50(clk_sys),
	.game_clk(clk_5),
	.signal_ccw(m_left),
	.signal_cw(m_right),
	.signal_thrust(m_thrust),
	.signal_fire(m_fire),
	.signal_start(m_start),
	.hsync(hs),
	.vsync(vs),
	.blank(blank),
	.video(video),
	.audio(audio)
	);

wire   audio_out;
assign AUDIO_R = audio_out;
assign AUDIO_L = audio_out;

dac #(16) dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({~audio[15], audio[14:0]}),
	.dac_o(audio_out)
);

wire [5:0] rs,gs,bs, ro,go,bo, rc,gc,bc, rm,gm,bm;
wire [3:0] r,g,b;

assign {rs,gs,bs} = ~video[0] ? 18'd0 : status[2] ? {6'b0111,6'b0111,6'b0111} : {6'b0111,6'b0111,6'b0111};
assign {rc,gc,bc} = ~video[1] ? 18'd0 : status[2] ? {6'b0000,6'b1111,6'b1111} : {6'b0111,6'b0111,6'b0111};
assign {ro,go,bo} = ~video[2] ? 18'd0 : status[2] ? {6'b1111,6'b1111,6'b0000} : {6'b1111,6'b1111,6'b1111};

assign rm = rs + ro + rc;
assign gm = gs + go + gc;
assign bm = bs + bo + bc;

assign r = blank ? 0 : (rm[5:4] ? 4'b1111 : rm[3:0]) ^ {4{inv}};
assign g = blank ? 0 : (gm[5:4] ? 4'b1111 : gm[3:0]) ^ {4{inv}};
assign b = blank ? 0 : (bm[5:4] ? 4'b1111 : bm[3:0]) ^ {4{inv}};

reg inv;
always @(posedge clk_5) begin
	reg old_vs, cur_inv;
	old_vs <= vs;
	
	cur_inv <= cur_inv | video[3];
	if (~old_vs & vs) {inv,cur_inv} <= {cur_inv, 1'b0};
end

endmodule 
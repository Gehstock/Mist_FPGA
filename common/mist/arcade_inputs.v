/* Provides arcade controls from joystick/keyboard
   Keyboard has a simplified (ESC-coin, F1-F4 start) and MAME-style mapping */

module arcade_inputs(
  // clock, same as for userio
	input         clk,
	// signals from userio
	input         key_strobe,
	input         key_pressed,
	input   [7:0] key_code,
	input  [15:0] joystick_0,
	input  [15:0] joystick_1,
	input  [15:0] joystick_2,
	input  [15:0] joystick_3,

	// required rotating of controls
	input         rotate,
	// original orientation [1]-left/right if portrait, [0]-landscape/portrait
	input   [1:0] orientation,
	// joystick_0 and joystick_1 should be swapped
	input         joyswap,
	// player1 and player2 should get both joystick_0 and joystick_1
	input         oneplayer,

	// tilt, coin4-1, start4-1
	output  [8:0] controls,
	// fire12-1, up, down, left, right
	output [15:0] player1,
	output [15:0] player2,
	output [15:0] player3,
	output [15:0] player4
);

assign controls = { btn_tilt,
                    btn_coin | btn_coin4_mame, btn_coin | btn_coin3_mame, btn_coin | btn_coin2_mame, btn_coin | btn_coin1_mame,
										btn_four_players | btn_start4_mame, btn_three_players | btn_start3_mame, btn_two_players | btn_start2_mame, btn_one_player | btn_start1_mame };

wire [15:0] joy0 = joyswap ? joystick_1 : joystick_0;
wire [15:0] joy1 = joyswap ? joystick_0 : joystick_1;
wire [15:0] joy2 = joystick_2;
wire [15:0] joy3 = joystick_3;

wire [15:0] p1;
wire [15:0] p2;
wire [15:0] p3;
wire [15:0] p4;

assign p1[15:4] = joy0[15:4] | { 4'h0, btn_fireH,  btn_fireG,  btn_fireF,  btn_fireE,  btn_fireD,  btn_fireC,  btn_fireB,  btn_fireA };
assign p2[15:4] = joy1[15:4] | { 4'h0, btn_fire2H, btn_fire2G, btn_fire2F, btn_fire2E, btn_fire2D, btn_fire2C, btn_fire2B, btn_fire2A };
assign p3[15:4] = joy2[15:4];
assign p4[15:4] = joy3[15:4];

control_rotator r1(joy0[3:0], {btn_up,  btn_down,  btn_left,  btn_right }, rotate, orientation, p1[3:0]);
control_rotator r2(joy1[3:0], {btn_up2, btn_down2, btn_left2, btn_right2}, rotate, orientation, p2[3:0]);
control_rotator r3(joy2[3:0], 4'd0, rotate, orientation, p3[3:0]);
control_rotator r4(joy3[3:0], 4'd0, rotate, orientation, p4[3:0]);

assign player1 = oneplayer ? p1 | p2 : p1;
assign player2 = oneplayer ? p1 | p2 : p2;
assign player3 = p3;
assign player4 = p4;

// keyboard controls
reg btn_tilt = 0;
reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_three_players = 0;
reg btn_four_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fireA = 0;
reg btn_fireB = 0;
reg btn_fireC = 0;
reg btn_fireD = 0;
reg btn_fireE = 0;
reg btn_fireF = 0;
reg btn_fireG = 0;
reg btn_fireH = 0;
reg btn_coin  = 0;
reg btn_start1_mame = 0;
reg btn_start2_mame = 0;
reg btn_start3_mame = 0;
reg btn_start4_mame = 0;
reg btn_coin1_mame = 0;
reg btn_coin2_mame = 0;
reg btn_coin3_mame = 0;
reg btn_coin4_mame = 0;
reg btn_up2 = 0;
reg btn_down2 = 0;
reg btn_left2 = 0;
reg btn_right2 = 0;
reg btn_fire2A = 0;
reg btn_fire2B = 0;
reg btn_fire2C = 0;
reg btn_fire2D = 0;
reg btn_fire2E = 0;
reg btn_fire2F = 0;
reg btn_fire2G = 0;
reg btn_fire2H = 0;

always @(posedge clk) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up            <= key_pressed; // up
			'h72: btn_down          <= key_pressed; // down
			'h6B: btn_left          <= key_pressed; // left
			'h74: btn_right         <= key_pressed; // right
			'h76: btn_coin          <= key_pressed; // ESC
			'h05: btn_one_player    <= key_pressed; // F1
			'h06: btn_two_players   <= key_pressed; // F2
			'h04: btn_three_players <= key_pressed; // F3
			'h0C: btn_four_players  <= key_pressed; // F4
			'h12: btn_fireD         <= key_pressed; // l-shift
			'h14: btn_fireC         <= key_pressed; // ctrl
			'h11: btn_fireB         <= key_pressed; // alt
			'h29: btn_fireA         <= key_pressed; // Space
			'h1A: btn_fireE         <= key_pressed; // Z
			'h22: btn_fireF         <= key_pressed; // X
			'h21: btn_fireG         <= key_pressed; // C
			'h2A: btn_fireH         <= key_pressed; // V
			'h66: btn_tilt          <= key_pressed; // Backspace

			// JPAC/IPAC/MAME Style Codes
			'h16: btn_start1_mame   <= key_pressed; // 1
			'h1E: btn_start2_mame   <= key_pressed; // 2
			'h26: btn_start3_mame   <= key_pressed; // 3
			'h25: btn_start4_mame   <= key_pressed; // 4
			'h2E: btn_coin1_mame    <= key_pressed; // 5
			'h36: btn_coin2_mame    <= key_pressed; // 6
			'h3D: btn_coin3_mame    <= key_pressed; // 7
			'h3E: btn_coin4_mame    <= key_pressed; // 8
			'h2D: btn_up2           <= key_pressed; // R
			'h2B: btn_down2         <= key_pressed; // F
			'h23: btn_left2         <= key_pressed; // D
			'h34: btn_right2        <= key_pressed; // G
			'h1C: btn_fire2A        <= key_pressed; // A
			'h1B: btn_fire2B        <= key_pressed; // S
			'h15: btn_fire2C        <= key_pressed; // Q
			'h1D: btn_fire2D        <= key_pressed; // W
			'h43: btn_fire2E        <= key_pressed; // I
			'h42: btn_fire2F        <= key_pressed; // K
			'h3B: btn_fire2G        <= key_pressed; // J
			'h4B: btn_fire2H        <= key_pressed; // L
		endcase
	end
end

endmodule

module control_rotator (
	input  [3:0] joystick, //UDLR
	input  [3:0] keyboard,
	input        rotate,
	input  [1:0] orientation,
	output [3:0] out
);

assign out = { m_up, m_down, m_left, m_right };

wire m_up     = ~(orientation[0] ^ rotate) ? keyboard[3] | joystick[3] : ((orientation[1] ^ orientation[0]) ? keyboard[0] | joystick[0] : keyboard[1] | joystick[1]);
wire m_down   = ~(orientation[0] ^ rotate) ? keyboard[2] | joystick[2] : ((orientation[1] ^ orientation[0]) ? keyboard[1] | joystick[1] : keyboard[0] | joystick[0]);
wire m_left   = ~(orientation[0] ^ rotate) ? keyboard[1] | joystick[1] : ((orientation[1] ^ orientation[0]) ? keyboard[3] | joystick[3] : keyboard[2] | joystick[2]);
wire m_right  = ~(orientation[0] ^ rotate) ? keyboard[0] | joystick[0] : ((orientation[1] ^ orientation[0]) ? keyboard[2] | joystick[2] : keyboard[3] | joystick[3]);

endmodule

// A simple toggle-switch
module input_toggle(
	input clk,
	input reset,
	input btn,
	output reg state
);

reg btn_old;
always @(posedge clk) begin
	btn_old <= btn;
	if (reset) state <= 0;
	else if (~btn_old & btn) state <= ~state;
end

endmodule

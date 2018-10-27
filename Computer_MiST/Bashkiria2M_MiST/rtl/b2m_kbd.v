// ====================================================================
//                Bashkiria-2M FPGA REPLICA
//
//            Copyright (C) 2010 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Bashkiria-2M home computer
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Design File: b2m_kbd.v
//
// Keyboard interface design file of Bashkiria-2M replica.

module b2m_kbd(
	input clk,
	input reset,
	input ps2_clk,
	input ps2_dat,
	input[8:0] addr,
	output reg[7:0] odata);

reg[7:0] keystate[10:0];

always @(addr,keystate) begin
	if (addr[8])
		odata =
			(keystate[8]  & {8{addr[0]}})|
			(keystate[9]  & {8{addr[1]}})|
			(keystate[10] & {8{addr[2]}});
	else
		odata =
			(keystate[0] & {8{addr[0]}})|
			(keystate[1] & {8{addr[1]}})|
			(keystate[2] & {8{addr[2]}})|
			(keystate[3] & {8{addr[3]}})|
			(keystate[4] & {8{addr[4]}})|
			(keystate[5] & {8{addr[5]}})|
			(keystate[6] & {8{addr[6]}})|
			(keystate[7] & {8{addr[7]}});
end

reg[2:0] c;
reg[3:0] r;
reg extkey;
reg unpress;
reg[3:0] prev_clk;
reg[11:0] shift_reg;

wire[11:0] kdata = {ps2_dat,shift_reg[11:1]};
wire[7:0] kcode = kdata[9:2];

always begin
	case (kcode)
	8'h4E: {c,r} <= 7'h74; // -
	8'h41: {c,r} <= 7'h05; // ,
	8'h4C: {c,r} <= 7'h15; // ;
	8'h55: {c,r} <= 7'h25; // =
	8'h0E: {c,r} <= 7'h35; // `
	8'h5D: {c,r} <= 7'h55; // \!
	8'h45: {c,r} <= 7'h65; // 0
	8'h16: {c,r} <= 7'h45; // 1
	8'h1E: {c,r} <= 7'h64; // 2
	8'h26: {c,r} <= 7'h54; // 3
	8'h25: {c,r} <= 7'h44; // 4
	8'h2E: {c,r} <= 7'h34; // 5
	8'h36: {c,r} <= 7'h24; // 6
	8'h3D: {c,r} <= 7'h14; // 7
	8'h3E: {c,r} <= 7'h04; // 8
	8'h46: {c,r} <= 7'h75; // 9
	8'h1C: {c,r} <= 7'h10; // A
	8'h32: {c,r} <= 7'h61; // B
	8'h21: {c,r} <= 7'h42; // C
	8'h23: {c,r} <= 7'h02; // D
	8'h24: {c,r} <= 7'h22; // E
	8'h2B: {c,r} <= 7'h60; // F
	8'h34: {c,r} <= 7'h72; // G
	8'h33: {c,r} <= 7'h52; // H
	8'h43: {c,r} <= 7'h43; // I
	8'h3B: {c,r} <= 7'h01; // J
	8'h42: {c,r} <= 7'h31; // K
	8'h4B: {c,r} <= 7'h30; // L
	8'h3A: {c,r} <= 7'h73; // M
	8'h31: {c,r} <= 7'h32; // N
	8'h44: {c,r} <= 7'h23; // O
	8'h4D: {c,r} <= 7'h53; // P
	8'h15: {c,r} <= 7'h51; // Q
	8'h2D: {c,r} <= 7'h41; // R
	8'h1B: {c,r} <= 7'h63; // S
	8'h2C: {c,r} <= 7'h20; // T
	8'h3C: {c,r} <= 7'h00; // U
	8'h2A: {c,r} <= 7'h21; // V
	8'h1D: {c,r} <= 7'h40; // W
	8'h22: {c,r} <= 7'h13; // X
	8'h35: {c,r} <= 7'h11; // Y
	8'h1A: {c,r} <= 7'h62; // Z
	8'h54: {c,r} <= 7'h71; // [
	8'h5B: {c,r} <= 7'h03; // ]
	8'h0B: {c,r} <= 7'h50; // F6
	8'h83: {c,r} <= 7'h70; // F7
	8'h0A: {c,r} <= 7'h12; // F8
	8'h01: {c,r} <= 7'h33; // F9
	8'h29: {c,r} <= 7'h06; // space
	8'h0D: {c,r} <= 7'h16; // tab
	8'h66: {c,r} <= 7'h26; // bksp
	8'h7C: {c,r} <= 7'h46; // gray*
	8'h07: {c,r} <= 7'h56; // F12 - stop
	8'h7B: {c,r} <= 7'h66; // gray-
	8'h5A: {c,r} <= 7'h76; // enter
	8'h59: {c,r} <= 7'h07; // rshift
	8'h11: {c,r} <= 7'h17; // lalt
	8'h14: {c,r} <= extkey ? 7'h37 : 7'h27; // rctrl + lctrl
	8'h76: {c,r} <= 7'h47; // esc
	8'h78: {c,r} <= 7'h67; // F11 - rus
	8'h12: {c,r} <= 7'h77; // lshift
	8'h6C: {c,r} <= 7'h08; // 7 home
	8'h74: {c,r} <= 7'h18; // 6 right
	8'h73: {c,r} <= 7'h28; // 5 center
	8'h6B: {c,r} <= 7'h38; // 4 left
	8'h7A: {c,r} <= 7'h48; // 3 pgdn
	8'h72: {c,r} <= 7'h58; // 2 down
	8'h69: {c,r} <= 7'h68; // 1 end
	8'h70: {c,r} <= 7'h78; // 0 ins
	8'h4A: {c,r} <= extkey ? 7'h36 : 7'h09; // gray/ + /
	8'h71: {c,r} <= 7'h19; // . del
	8'h52: {c,r} <= 7'h29; // '
	8'h49: {c,r} <= 7'h39; // .
	8'h7D: {c,r} <= 7'h69; // 9 pgup
	8'h75: {c,r} <= 7'h79; // 8 up
	8'h05: {c,r} <= 7'h7A; // F1
	8'h06: {c,r} <= 7'h6A; // F2
	8'h04: {c,r} <= 7'h5A; // F3
	8'h0C: {c,r} <= 7'h4A; // F4
	8'h03: {c,r} <= 7'h3A; // F5
	default: {c,r} <= 7'h7F;
	endcase
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		prev_clk <= 0;
		shift_reg <= 12'hFFF;
		extkey <= 0;
		unpress <= 0;
		keystate[0] <= 0;
		keystate[1] <= 0;
		keystate[2] <= 0;
		keystate[3] <= 0;
		keystate[4] <= 0;
		keystate[5] <= 0;
		keystate[6] <= 0;
		keystate[7] <= 0;
		keystate[8] <= 0;
		keystate[9] <= 0;
		keystate[10] <= 0;
	end else begin
		prev_clk <= {ps2_clk,prev_clk[3:1]};
		if (prev_clk==4'b1) begin
			if (kdata[11]==1'b1 && ^kdata[10:2]==1'b1 && kdata[1:0]==2'b1) begin
				shift_reg <= 12'hFFF;
				if (kcode==8'hE0) extkey <= 1'b1; else
				if (kcode==8'hF0) unpress <= 1'b1; else
				begin
					extkey <= 0;
					unpress <= 0;
					if(r!=4'hF) keystate[r][c] <= ~unpress;
				end
			end else
				shift_reg <= kdata;
		end
	end
end

endmodule

module galaksija_keyboard2(
	input 		clk,
	input 		reset_n,
	input  [5:0]addr,
	input 		rd_key,
	input			RD_n,
	input			ps2_clk, 
	input			ps2_data,
	input			LINE_IN,
	output [7:0]KDatout
	);
	
	
wire [2:0]KSsel = addr[2:0];		
wire [2:0]KRsel = addr[5:3];
wire [7:0]KS;
wire [2:0]KR_bin;
//wire KSout;
wire [7:0]scan_code, scan_code_int;
wire scan_ready, scan_ready_int;
wire [2:0]row, col;
wire set, clr;
typedef reg [0:63] arr;
arr key_array = 8'hFF;
wire special, special_set, special_clr;
typedef enum  {WAIT_CODE, RELEASE} STATES;
STATES CState, NState = WAIT_CODE;
wire kbd_rd;

// Select keyboard row or select latch
always @(KRsel, rd_key)
	begin
		if (rd_key == 1'b1) begin
			case (KRsel)//spalte
				3'b000 : KR_bin <= 3'b000;
				3'b001 : KR_bin <= 3'b001;
				3'b010 : KR_bin <= 3'b010;
				3'b011 : KR_bin <= 3'b011;
				3'b100 : KR_bin <= 3'b100;
				3'b101 : KR_bin <= 3'b101;
				3'b110 : KR_bin <= 3'b110;
				3'b111 : KR_bin <= 3'b111;
				default : KR_bin <= 3'b000;
			endcase
		end else
			KR_bin <= 3'b000;
	end
	
// Multiplex the keyboard scanlines
always @(KSsel, rd_key, KS, RD_n)
	begin
		KDatout <= 8'b00000000;
			case (KSsel)//reihe
				3'b000 : KDatout[0] <= KS[0];
				3'b001 : KDatout[1] <= KS[1];
				3'b010 : KDatout[2] <= KS[2];
				3'b011 : KDatout[3] <= KS[3];
				3'b100 : KDatout[4] <= KS[4];
				3'b101 : KDatout[5] <= KS[5];
				3'b110 : KDatout[6] <= KS[6];
				3'b111 : KDatout[7] <= KS[7];
				default : KDatout <= 8'b11111111;
			endcase
	end
	
// scan_ready_int has asynchronous reset
always @(scan_ready_int, clk) begin
	if (clk == 1'b1) begin
		scan_ready = scan_ready_int;
		scan_code = scan_code_int;
	end
end

// Galaksija keyboard array
always @(KR_bin, row, col, set, clr, clk, LINE_IN, key_array) begin
{row,col} = 6'b000000;
	if (LINE_IN == 1'b1) begin
		if (KR_bin == ~3'b000)
			KS[0] = {3'b000,KR_bin};
		else
			KS[0] = 1'b1;
	end else
		KS[0] = 1'b0;
		
		KS[1] = {3'b001,KR_bin};
		KS[2] = {3'b010,KR_bin};
		KS[3] = {3'b011,KR_bin};
		KS[4] = {3'b100,KR_bin};
		KS[5] = {3'b101,KR_bin};
		KS[6] = {3'b110,KR_bin};
		KS[7] = {3'b111,KR_bin};
			
	if (clk == 1'b1) begin
		if (set == 1'b1)
			{row,col} = 6'b111111;
			else if (clr == 1'b1) begin
				{row,col} = 6'b000000;
			end
		end
end

// Bit for special characters
always @(special_set, special_clr, clk) begin
	if (clk == 1'b1) begin
		if (special_clr == 1'b1)
			special = 1'b0;
		if (special_set == 1'b1)
			special = 1'b1;
	end
end

// Capture special codes
always @(scan_code, scan_ready) begin
	if (scan_ready == 1'b1) begin
		if (scan_code == 8'hE0) 
			special_set = 1'b1;
		else
			special_set = 1'b0;
	end else
		special_set = 1'b0;
end

// State machine state propagation
always @(clk, NState, reset_n) begin
	if (reset_n == 1'b0)
		CState = WAIT_CODE;
	else
		if (clk == 1'b1)
			CState = NState;
end

// State machine
always @(CState, scan_code, scan_ready) begin
	case (CState)
		WAIT_CODE : begin
							set = 1'b0;
							special_clr = 1'b0;
							if (scan_ready == 1'b1) begin
								kbd_rd <= 1'b1;
								if (scan_code == 8'hF0) begin
									NState = RELEASE;
									clr = 1'b0;
								end else begin
									NState = WAIT_CODE;
									clr = 1'b1;
								end
							end else begin
								kbd_rd = 1'b0;
								clr = 1'b0;
								NState = WAIT_CODE;
							end
						end
		RELEASE : 	begin
							clr = 1'b0;
							if (scan_ready == 1'b1) begin
								kbd_rd = 1'b1;
								set = 1'b1;
								NState = WAIT_CODE;
								special_clr = 1'b1;
							end else begin
								kbd_rd = 1'b0;
								set = 1'b0;
								NState = RELEASE;
								special_clr = 1'b0;
							end
						end
	endcase
end

always @(special, scan_code) begin
	if (special == 1'b0)
		case (scan_code)
			8'h1C : begin row = "001"; row = "000"; end// A
			8'h32 : begin row = "010"; row = "000"; end// B
			8'h21 : begin row = "011"; row = "000"; end// C
			8'h23 : begin row = "100"; row = "000"; end// D
			8'h24 : begin row = "101"; row = "000"; end// E
			8'h2B : begin row = "110"; row = "000"; end// F
			8'h34 : begin row = "111"; row = "000"; end// G
			
			8'h33 : begin row = "000"; row = "001"; end// H
			8'h43 : begin row = "001"; row = "001"; end// I
			8'h3B : begin row = "010"; row = "001"; end// J
			8'h42 : begin row = "011"; row = "001"; end// K 
			8'h4B : begin row = "100"; row = "001"; end// L
			8'h3A : begin row = "101"; row = "001"; end// M
			8'h31 : begin row = "110"; row = "001"; end// N
			8'h44 : begin row = "111"; row = "001"; end// O
				
			8'h4D : begin row = "000"; row = "010"; end// P
			8'h15 : begin row = "001"; row = "010"; end// Q
			8'h2D : begin row = "010"; row = "010"; end// R
			8'h1B : begin row = "011"; row = "010"; end// S
			8'h2C : begin row = "100"; row = "010"; end// T
			8'h3C : begin row = "101"; row = "010"; end// U
			8'h2A : begin row = "110"; row = "010"; end// V
			8'h1D : begin row = "111"; row = "010"; end// W
				
			8'h22 : begin row = "000"; row = "011"; end// X
			8'h35 : begin row = "001"; row = "011"; end// Y
			8'h1A : begin row = "010"; row = "011"; end// Z					
			8'h29 : begin row = "111"; row = "011"; end// SPACE
				
			8'h45 : begin row = "000"; row = "100"; end// 0
			8'h16 : begin row = "001"; row = "100"; end// 1
			8'h1E : begin row = "010"; row = "100"; end// 2
			8'h26 : begin row = "011"; row = "100"; end// 3
			8'h25 : begin row = "100"; row = "100"; end// 4
			8'h2E : begin row = "101"; row = "100"; end// 5
			8'h36 : begin row = "110"; row = "100"; end// 6
			8'h3D : begin row = "111"; row = "100"; end// 7
				

			8'h3E : begin row = "000"; row = "101"; end// 8
			8'h46 : begin row = "001"; row = "101"; end// 9
			8'h4C : begin row = "010"; row = "101"; end// ;
			8'h54 : begin row = "011"; row = "101"; end// : (PS2 equ = [)
			8'h41 : begin row = "100"; row = "101"; end// ,
			8'h55 : begin row = "101"; row = "101"; end// =				
			8'h71 : begin row = "110"; row = "101"; end// .
			8'h49 : begin row = "110"; row = "101"; end// .
			8'h4A : begin row = "111"; row = "101"; end// /			
	
			8'h5A : begin row = "000"; row = "110"; end// ret					
			8'h12 : begin row = "101"; row = "110"; end// shift (left)
			8'h59 : begin row = "101"; row = "110"; end// shift (right)					
			default : begin row = "111"; col = "111"; end
		endcase
	else
		case (scan_code)
			8'h75 : begin row = "011"; row = "011"; end// UP
			8'h72 : begin row = "100"; row = "011"; end// DOWN
			8'h6B : begin row = "101"; row = "011"; end// LEFT
			8'h74 : begin row = "110"; row = "011"; end// RIGHT
			
			8'h4A : begin row = "111"; row = "101"; end// /			

			8'h69 : begin row = "001"; row = "110"; end// brk = end
			8'h6C : begin row = "010"; row = "110"; end// rpt = home
			8'h71 : begin row = "011"; row = "110"; end// del
			8'h7D : begin row = "100"; row = "110"; end// lst = page up
			default : begin row = "111"; col = "111"; end
		endcase
end

keyboard keyboard(	
	.keyboard_clk(ps2_clk), 
	.keyboard_data(ps2_data), 
	.clock(clk), 
	.reset(reset_n), 
	.reads(kbd_rd), 
	.scan_code(scan_code_int), 
	.scan_ready(scan_ready_int)
	);

endmodule 
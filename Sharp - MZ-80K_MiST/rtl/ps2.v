module ps2(clk, reset,
				ps2_clk, ps2_data,
				cs, rd, addr, data);

	input  clk,reset;
	input  ps2_clk, ps2_data;
	input  cs, rd;
	input  [7:0] addr;
	output [7:0] data;

	wire clk, reset;
	wire ps2_clk, ps2_data;
	wire cs, rd;
	wire [7:0] addr;
	reg  [7:0] data;

	reg [7:0]key_tbl0 = 8'b11111111,
				key_tbl1 = 8'b11111111,
				key_tbl2 = 8'b11111111,
				key_tbl3 = 8'b11111111,
				key_tbl4 = 8'b11111111,
				key_tbl5 = 8'b11111111,
				key_tbl6 = 8'b11111111,
				key_tbl7 = 8'b11111111,
				key_tbl8 = 8'b11111111,
				key_tbl9 = 8'b11111111,
				key_tbla = 8'b11111111,
				key_tblb = 8'b11111111,
				key_tblc = 8'b11111111,
				key_tbld = 8'b11111111,
				key_tble = 8'b11111111;
	reg key_f0 = 1'b0;
	reg key_e0 = 1'b0;

	//
	// I/O(0-9) read
	//
	always @(posedge clk ) begin
		if ( cs & rd ) begin
			begin
				case (addr[3:0])
					4'h0: data <= key_tbl0;
					4'h1: data <= key_tbl1;
					4'h2: data <= key_tbl2;
					4'h3: data <= key_tbl3;
					4'h4: data <= key_tbl4;
					4'h5: data <= key_tbl5;
					4'h6: data <= key_tbl6;
					4'h7: data <= key_tbl7;
					4'h8: data <= key_tbl8;
					4'h9: data <= key_tbl9;
					4'ha: data <= key_tbla;
					4'hb: data <= key_tblb;
					4'hc: data <= key_tblc;
					4'hd: data <= key_tbld;
					4'he: data <= key_tble;
					default: data <= 8'hzz;
				endcase
			end
		end
	end

	//
	// PS/2���͏������
	//
	wire  dten;
	wire [7:0] kdata;
	ps2_recieve ps2_recieve1(.clk(clk), .reset(reset),
				.ps2_clk(ps2_clk), .ps2_data(ps2_data),
				.dten(dten), .kdata(kdata));
	
	
	//
	//
	//
	always @(posedge clk or posedge reset) begin
		if( reset ) begin
			key_e0 <= 1'b0;
			key_f0 <= 1'b0;
			key_tbl0 <= 8'b11111111;
			key_tbl1 <= 8'b11111111;
			key_tbl2 <= 8'b11111111;
			key_tbl3 <= 8'b11111111;
			key_tbl4 <= 8'b11111111;
			key_tbl5 <= 8'b11111111;
			key_tbl6 <= 8'b11111111;
			key_tbl7 <= 8'b11111111;
			key_tbl8 <= 8'b11111111;
			key_tbl9 <= 8'b11111111;
		end else if ( dten ) begin
			case ( kdata )
				8'h70: begin
					if ( key_e0 ) begin
						key_tbl8[1] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// INS  (E0)
					end else begin
						key_tbl1[4] <= key_f0; key_f0 <= 1'b0;					// 0
					end
				end
				8'h69: begin
					if ( key_e0 ) begin
						key_f0 <= 1'b0; key_e0 <= 1'b0;							// END  (E0)
					end else begin
						key_tbl0[0] <= key_f0; key_f0 <= 1'b0;					// 1
					end
				end
				8'h72: begin
					if ( key_e0 ) begin
						key_tbl9[2] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// DOWN (E0)
					end else begin
						key_tbl1[0] <= key_f0; key_f0 <= 1'b0;					// 2
					end
				end
				8'h7A: begin
					if ( key_e0 ) begin
						key_tble[0] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// PGDN (E0)
					end else begin
						key_tbl0[1] <= key_f0; key_f0 <= 1'b0;					// 3
					end
				end
				8'h6B: begin
					if ( key_e0 ) begin
						key_tbl8[3] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// LEFT (E0)
					end else begin
						key_tbl1[1] <= key_f0; key_f0 <= 1'b0;					// 4
					end
				end
				8'h73: begin key_tbl0[2] <= key_f0; key_f0 <= 1'b0; end	// 5
				8'h74: begin
					if ( key_e0 ) begin
						key_tbl8[3] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// RIGHT (E0)
					end else begin
						key_tbl1[2] <= key_f0; key_f0 <= 1'b0;					// 6
					end
				end
				8'h6C: begin
					if ( key_e0 ) begin
						key_tbl8[0] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// HOME (E0)
					end else begin
						key_tbl0[3] <= key_f0; key_f0 <= 1'b0;					// 7
					end
				end
				8'h75: begin
					if ( key_e0 ) begin
						key_tbl9[2] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// UP   (E0)
					end else begin
						key_tbl1[3] <= key_f0; key_f0 <= 1'b0;					// 8
					end
				end
				8'h7D: begin
					if ( key_e0 ) begin
						key_tble[0] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// PGUP (E0)
					end else begin
						key_tbl0[4] <= key_f0; key_f0 <= 1'b0;					// 9
					end
				end
				8'h7C: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// *
				8'h79: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// +
				8'h7B: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// =
				8'h7C: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// ,
				8'h71: begin
					if ( key_e0 ) begin
						key_tbl8[1] <= key_f0; key_tblc[7] <= key_f0; key_f0 <= 1'b0; key_e0 <= 1'b0;	// DEL  (E0)
					end else begin
						key_tble[0] <= key_f0; key_f0 <= 1'b0;					// .
					end
				end
				8'h71: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// .
				8'h5A: begin key_tbl8[4] <= key_f0; key_f0 <= 1'b0; end	// RET E0
				8'h54: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// @
				8'h1C: begin key_tbl4[0] <= key_f0; key_f0 <= 1'b0; end	// A
				8'h32: begin key_tbl6[2] <= key_f0; key_f0 <= 1'b0; end	// B
				8'h21: begin key_tbl6[1] <= key_f0; key_f0 <= 1'b0; end	// C
				8'h23: begin key_tbl4[1] <= key_f0; key_f0 <= 1'b0; end	// D
				8'h24: begin key_tbl2[1] <= key_f0; key_f0 <= 1'b0; end	// E
				8'h2B: begin key_tbl5[1] <= key_f0; key_f0 <= 1'b0; end	// F
				8'h34: begin key_tbl4[2] <= key_f0; key_f0 <= 1'b0; end	// G
				8'h33: begin key_tbl5[2] <= key_f0; key_f0 <= 1'b0; end	// H
				8'h43: begin key_tbl3[3] <= key_f0; key_f0 <= 1'b0; end	// I
				8'h3B: begin key_tbl4[3] <= key_f0; key_f0 <= 1'b0; end	// J
				8'h42: begin key_tbl5[3] <= key_f0; key_f0 <= 1'b0; end	// K
				8'h4B: begin key_tbl4[4] <= key_f0; key_f0 <= 1'b0; end	// L
				8'h3A: begin key_tbl6[3] <= key_f0; key_f0 <= 1'b0; end	// M
				8'h31: begin key_tbl7[2] <= key_f0; key_f0 <= 1'b0; end	// N
				8'h44: begin key_tbl2[4] <= key_f0; key_f0 <= 1'b0; end	// O
				8'h4D: begin key_tbl3[4] <= key_f0; key_f0 <= 1'b0; end	// P
				8'h15: begin key_tbl2[0] <= key_f0; key_f0 <= 1'b0; end	// Q
				8'h2D: begin key_tbl3[1] <= key_f0; key_f0 <= 1'b0; end	// R
				8'h1B: begin key_tbl5[0] <= key_f0; key_f0 <= 1'b0; end	// S
				8'h2C: begin key_tbl2[2] <= key_f0; key_f0 <= 1'b0; end	// T
				8'h3C: begin key_tbl2[3] <= key_f0; key_f0 <= 1'b0; end	// U
				8'h2A: begin key_tbl7[1] <= key_f0; key_f0 <= 1'b0; end	// V
				8'h1D: begin key_tbl3[0] <= key_f0; key_f0 <= 1'b0; end	// W
				8'h22: begin key_tbl7[0] <= key_f0; key_f0 <= 1'b0; end	// X
				8'h35: begin key_tbl3[2] <= key_f0; key_f0 <= 1'b0; end	// Y
				8'h1A: begin key_tbl6[0] <= key_f0; key_f0 <= 1'b0; end	// Z
				8'h5B: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// [
				8'h6A: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// \
				8'h5D: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// ]
				8'h55: begin key_tbl5[5] <= key_f0; key_f0 <= 1'b0; end	// ^
				8'h4E: begin key_tbl2[5] <= key_f0; key_f0 <= 1'b0; end	// =
				8'h45: begin key_tbl1[4] <= key_f0; key_f0 <= 1'b0; end	// 0
				8'h16: begin key_tbl0[0] <= key_f0; key_f0 <= 1'b0; end	// 1
				8'h1E: begin key_tbl1[0] <= key_f0; key_f0 <= 1'b0; end	// 2
				8'h26: begin key_tbl0[1] <= key_f0; key_f0 <= 1'b0; end	// 3
				8'h25: begin key_tbl1[1] <= key_f0; key_f0 <= 1'b0; end	// 4
				8'h2E: begin key_tbl0[2] <= key_f0; key_f0 <= 1'b0; end	// 5
				8'h36: begin key_tbl1[2] <= key_f0; key_f0 <= 1'b0; end	// 6
				8'h3D: begin key_tbl0[3] <= key_f0; key_f0 <= 1'b0; end	// 7
				8'h3E: begin key_tbl1[3] <= key_f0; key_f0 <= 1'b0; end	// 8
				8'h46: begin key_tbl0[4] <= key_f0; key_f0 <= 1'b0; end	// 9
				8'h52: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// :
				8'h4C: begin key_tbl5[4] <= key_f0; key_f0 <= 1'b0; end	// ;
				8'h41: begin key_tbl7[3] <= key_f0; key_f0 <= 1'b0; end	// < ,
				8'h49: begin key_tbl6[4] <= key_f0; key_f0 <= 1'b0; end	// > .
				8'h4A: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// ?
				8'h51: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// _
				8'h11: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// GRPH
				8'h13: begin key_tbl6[5] <= key_f0; key_f0 <= 1'b0; end	// �J�i
				8'h12: begin key_tbl8[0] <= ( key_f0 | key_e0 ) & (key_tbl8[0] | ~key_e0 ); key_f0 <= 1'b0; key_e0 <= 1'b0; end	// SHIFT
				8'h59: begin key_tbl8[5] <= ( key_f0 | key_e0 ) & (key_tbl8[5] | ~key_e0 ); key_f0 <= 1'b0; key_e0 <= 1'b0; end	// SHIFT
				8'h14: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// CTRL
				8'h77: begin key_tbl9[3] <= key_f0; key_f0 <= 1'b0; end	// STOP  (E1)
				8'h7E: begin key_tbl9[3] <= key_f0; key_f0 <= 1'b0; end	// STOP  (SCROLL KEY)
				8'h05: begin key_tble[0] <= key_f0; key_tblc[0] <= key_f0; key_f0 <= 1'b0; end	// F1
				8'h06: begin key_tble[0] <= key_f0; key_tblc[1] <= key_f0;  key_f0 <= 1'b0; end	// F2
				8'h04: begin key_tble[0] <= key_f0; key_tblc[2] <= key_f0;  key_f0 <= 1'b0; end	// F3
				8'h0C: begin key_tble[0] <= key_f0; key_tblc[3] <= key_f0;  key_f0 <= 1'b0; end	// F4
				8'h03: begin key_tble[0] <= key_f0; key_tblc[4] <= key_f0;  key_f0 <= 1'b0; end	// F5
				8'h29: begin key_tbl9[1] <= key_f0; key_tbld[7] <= key_f0; key_f0 <= 1'b0; end	// SPACE
				8'h76: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// ESC
				8'h0d: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// TAB
				8'h58: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// CAPS
				8'h66: begin key_tbl8[1] <= key_f0; key_f0 <= 1'b0; end	// BS
				8'h0b: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// F6
				8'h83: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// F7
				8'h0a: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// F8
				8'h01: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// F9
				8'h09: begin key_tble[0] <= key_f0; key_f0 <= 1'b0; end	// F10
				8'he0: key_e0 <= 1'b1;
				8'hf0: key_f0 <= 1'b1;
				default: begin key_e0 <= 1'b0; key_f0 <= 1'b0; end
			endcase
		end
	end
	
endmodule

module ps2_recieve(clk, reset,
				ps2_clk, ps2_data,
				dten, kdata);

	input   clk,reset;
	input   ps2_clk, ps2_data;
	output  dten;
	output [7:0] kdata;

	wire clk, reset;
	wire ps2_clk, ps2_data;
	reg dten;
	reg  [7:0] kdata;

	reg  [10:0] key_data;
	reg  [3:0]  clk_data;

	always @(posedge clk or posedge reset) begin
		if( reset ) begin
			key_data <= 11'b11111111111;
			dten <= 1'b0;
		end else begin
			clk_data <= {clk_data[2:0], ps2_clk};
			if ( clk_data == 4'b0011 )
				key_data <= {ps2_data, key_data[10:1]};
			if ( !key_data[0] & key_data[10] ) begin
				dten <= 1'b1;
				kdata <= key_data[8:1];
				key_data <= 11'b11111111111;
			end else
				dten <= 1'b0;
		end

	end

endmodule

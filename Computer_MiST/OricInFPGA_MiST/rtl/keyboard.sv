// Dave Wood 2019

module keyboard
(
	input			 clk_24,
	input			 clk,
	input			 reset,
//	input  [10:0]	 ps2_key,
	input          key_pressed,  // 1-make (pressed), 0-break (released)
	input          key_extended, // extended code
	input          key_strobe,   // strobe
	input    [7:0] key_code,     // key scan code
	input  [2:0]	 col,
	input	 [7:0]	 row,
	output [7:0]	 ROWbit,
	output			swrst


);

reg sw0 = 1'b0;
reg sw1 = 1'b0;
reg sw2 = 1'b0;
reg sw3 = 1'b0;
reg sw4 = 1'b0;
reg sw5 = 1'b0;
reg sw6 = 1'b0;
reg sw7 = 1'b0;
reg sw8 = 1'b0;
reg sw9 = 1'b0;
reg swa = 1'b0;
reg swb = 1'b0;
reg swc = 1'b0;
reg swd = 1'b0;
reg swe = 1'b0;
reg swf = 1'b0;
reg swg = 1'b0;
reg swh = 1'b0;
reg swi = 1'b0;
reg swj = 1'b0;
reg swk = 1'b0;
reg swl = 1'b0;
reg swm = 1'b0;
reg swn = 1'b0;
reg swo = 1'b0;
reg swp = 1'b0;
reg swq = 1'b0;
reg swr = 1'b0;
reg sws = 1'b0;
reg swt = 1'b0;
reg swu = 1'b0;
reg swv = 1'b0;
reg sww = 1'b0;
reg swx = 1'b0;
reg swy = 1'b0;
reg swz = 1'b0;

reg swU = 1'b0;	// up
reg swD = 1'b0;	// down 
reg swL = 1'b0;	// left 
reg swR = 1'b0;	// right

reg swrs = 1'b0;		// right shift
reg swls = 1'b0;		// left shift
reg swsp = 1'b0;		// space
reg swcom = 1'b0;	// ,
reg swdot = 1'b0;	// .
reg swret = 1'b0;	// return
reg swfs = 1'b0;		// forward slash
reg sweq = 1'b0;		// =
reg swfcn = 1'b0;	// FCN - ALT
reg swdel = 1'b0;	// delete
reg swrsb = 1'b0;	// ]
reg swlsb = 1'b0;	// [
reg swbs = 1'b0;		// back slash
reg swdsh = 1'b0;	// -
reg swsq = 1'b0; 	// '
reg swsc = 1'b0;		// ;
reg swesc = 1'b0;	// escape
reg swctl = 1'b0;	// left ctrl


//reg swrst = 0;
reg swf1 = 1'b0;
reg swf2 = 1'b0;
reg swf3 = 1'b0;
reg swf4 = 1'b0;
reg swf5 = 1'b0;
reg swf6 = 1'b0;

always @(posedge clk_24) begin
	reg old_state;
	old_state <= key_strobe;
	
	if(old_state != key_strobe) begin
		casex(key_code)
			'h045: sw0      			<= key_pressed; // 0
			'h016: sw1       			<= key_pressed; // 1
			'h01e: sw2   				<= key_pressed; // 2
			'h026: sw3  				<= key_pressed; // 3
			'h025: sw4   				<= key_pressed; // 4
			'h02e: sw5   				<= key_pressed; // 5
			'h036: sw6      			<= key_pressed; // 6
			'h03d: sw7      			<= key_pressed; // 7
			'h03e: sw8		   		<= key_pressed; // 8
			'h046: sw9      			<= key_pressed; // 9
			'h01c: swa       			<= key_pressed; // a
			'h032: swb   				<= key_pressed; // b
			'h021: swc  				<= key_pressed; // c
			'h023: swd   				<= key_pressed; // d
			'h024: swe   				<= key_pressed; // e
			'h02b: swf      			<= key_pressed; // f
			'h034: swg		   		<= key_pressed; // g
			'h033: swh					<= key_pressed; // h
			'h043: swi					<= key_pressed; // i
			'h03b: swj					<= key_pressed; // j
			'h042: swk					<= key_pressed; // k
			'h04b: swl   				<= key_pressed; // l
			'h03a: swm      			<= key_pressed; // m
			'h031: swn					<= key_pressed; // n
			'h044: swo					<= key_pressed; // o
			'h04d: swp   				<= key_pressed; // p
			'h015: swq					<= key_pressed; // q
			'h02d: swr   				<= key_pressed; // r
			'h01b: sws  				<= key_pressed; // s
			'h02c: swt					<= key_pressed; // t
			'h03c: swu					<= key_pressed; // u
			'h02a: swv					<= key_pressed; // v
			'h01d: sww					<= key_pressed; // w
			'h022: swx					<= key_pressed; // x
			'h035: swy					<= key_pressed; // y
			'h01a: swz					<= key_pressed; // z
	
			'hX75: swU           	<= key_pressed; // up
			'hX72: swD		        	<= key_pressed; // down
			'hx6b: swL					<= key_pressed; // left
			'hx74: swR					<= key_pressed; // right
			'h059: swrs					<= key_pressed; // right shift
			'h012: swls					<= key_pressed; // left shift
			'h029: swsp					<= key_pressed; // space
			'h041: swcom				<= key_pressed; // comma
			'h049: swdot				<= key_pressed; // full stop
			'h05a: swret				<= key_pressed; // return
			'h04a: swfs					<= key_pressed; // forward slash
			'h055: sweq					<= key_pressed; // equals
			'h011: swfcn				<= key_pressed; // ALT
			'hx71: swdel				<= key_pressed; // delete
			'h05b: swrsb				<= key_pressed; // right sq bracket
			'h054: swlsb				<= key_pressed; // left sq bracket
			'h05d: swbs					<= key_pressed; // back slash h05d
			'h04e: swdsh				<= key_pressed; // dash
			'h052: swsq					<= key_pressed; // single quote
			'h04c: swsc					<= key_pressed; // semi colon
			'h076: swesc				<= key_pressed; // escape
			'h014: swctl				<= key_pressed; // left control
			
			'h009: swrst      		<= key_pressed; // F10 break
			'h005: swf1	      		<= key_pressed; // f1
			'h006: swf2	      		<= key_pressed; // f2
			'h004: swf3	      		<= key_pressed; // f3
			'h00c: swf4	      		<= key_pressed; // f4
			'h003: swf5	      		<= key_pressed; // f5
			'h00b: swf6	      		<= key_pressed; // f6
			
		endcase
	end
end

wire no_key = (~sw0 & ~sw1 & ~sw2 & ~sw3 & ~sw4 & ~sw5 & ~sw6 & ~sw7 & ~sw8 & ~sw9 & ~swa & ~swb & ~swc & ~swd & ~swe & ~swf & 
					~swg & ~swh & ~ swi & ~swj & ~ swk & ~swl & ~swm & ~swn & ~swo & ~swp & ~swq & ~swr & ~sws & ~swt & ~swu & ~swv &
					~sww & ~swx & ~swy & ~swz & ~swU & ~swD & ~swR & ~swL & ~swrs & ~swls & ~swsp & ~swcom & ~swdot & ~swret & ~swfs & 
					~sweq & ~swfcn & ~swdel & ~swrsb & ~swlsb & ~swbs & ~swdsh & ~swsq & ~swsc & ~swesc & ~swctl & ~swf1 & ~swf2 &
					~swf3 & ~swf4 & ~swf5 & ~swf6);
					
//wire sp_key = ( swls | swrs | swctl | swfcn );

	always @(posedge clk) begin
		if (no_key) ROWbit <= 8'b11111111;
		else if (col == 3'b111) begin

			ROWbit <= 8'b11111111;
			if (sweq) 	ROWbit <= 8'b01111111;
			if (swf1) 	ROWbit <= 8'b10111111;
			if (swret) 	ROWbit <= 8'b11011111;
			if (swrs) 	ROWbit <= 8'b11101111;
			if (sweq & swrs) ROWbit <= 8'b01101111;
			if (swfs) 	ROWbit <= 8'b11110111;
			if (swfs & swrs) ROWbit <= 8'b11100111;
			if (sw0) 	ROWbit <= 8'b11111011;
			if (sw0 & swrs) ROWbit <= 8'b11101011;
			if (swl) 	ROWbit <= 8'b11111101;
			if (swl & swrs) ROWbit <= 8'b11101101;
			if (sw8) 	ROWbit <= 8'b11111110;
			if (sw8 & swrs) ROWbit <= 8'b11101110;
		end
		else if (col == 3'b110) begin

			ROWbit <= 8'b11111111;
			if (sww) 	ROWbit <= 8'b01111111;
			if (sws) 	ROWbit <= 8'b10111111;
			if (swa) 	ROWbit <= 8'b11011111;
			if (swf2) 	ROWbit <= 8'b11101111;
			if (swe) 	ROWbit <= 8'b11110111;
			if (swg) 	ROWbit <= 8'b11111011;
			if (swh) 	ROWbit <= 8'b11111101;
			if (swy) 	ROWbit <= 8'b11111110;
		end
		else if (col == 3'b101) begin

			ROWbit <= 8'b11111111;	
			if (swlsb) 	ROWbit <= 8'b01111111;
			if (swrsb) 	ROWbit <= 8'b10111111;
			if (swdel) 	ROWbit <= 8'b11011111;
			if (swfcn) 	ROWbit <= 8'b11101111;
			if (swp) 	ROWbit <= 8'b11110111;
			if (swo) 	ROWbit <= 8'b11111011;
			if (swi) 	ROWbit <= 8'b11111101;
			if (swu) 	ROWbit <= 8'b11111110;
		end
		else if (col == 3'b100) begin

			ROWbit <= 8'b11111111;
			if (swR) 	ROWbit <= 8'b01111111;
			if (swD) 	ROWbit <= 8'b10111111;
			if (swL) 	ROWbit <= 8'b11011111;
			if (swls) 	ROWbit <= 8'b11101111;
			if (swU) 	ROWbit <= 8'b11110111;
			if (swdot) 	ROWbit <= 8'b11111011;
			if (swdot & swls) ROWbit <= 8'b11101011;
			if (swcom) 	ROWbit <= 8'b11111101;
			if (swcom & swls) ROWbit <= 8'b11101101;
			if (swsp) 	ROWbit <= 8'b11111110;
		end
		else if (col == 3'b011) begin

			ROWbit <= 8'b11111111;	
			if (swsq) 	ROWbit <= 8'b01111111;
			if (swbs) 	ROWbit <= 8'b10111111;
			if (swf3) 	ROWbit <= 8'b11011111;
			if (swf4) 	ROWbit <= 8'b11101111;
			if (swdsh) 	ROWbit <= 8'b11110111;
			if (swsc) 	ROWbit <= 8'b11111011;
			if (sw9) 	ROWbit <= 8'b11111101;
			if (swk) 	ROWbit <= 8'b11111110;
		end
		else if (col == 3'b010) begin

			ROWbit <= 8'b11111111;
			if (swctl) 	ROWbit <= 8'b11101111;
			if (swc) 	ROWbit <= 8'b01111111;
			if (swc & swctl) 	ROWbit <= 8'b01101111;
			if (sw2) 	ROWbit <= 8'b10111111;
			if (sw2 & swctl) 	ROWbit <= 8'b10101111;
			if (swz) 	ROWbit <= 8'b11011111;
			if (swz & swctl) 	ROWbit <= 8'b11001111;
			if (sw4) 	ROWbit <= 8'b11110111;
			if (sw4 & swctl) 	ROWbit <= 8'b11100111;
			if (swb) 	ROWbit <= 8'b11111011;
			if (swb & swctl) 	ROWbit <= 8'b11101011;
			if (sw6) 	ROWbit <= 8'b11111101;
			if (sw6 & swctl) 	ROWbit <= 8'b11101101;
			if (swm) 	ROWbit <= 8'b11111110;
			if (swm & swctl) 	ROWbit <= 8'b11101110;
		end
		else if (col == 3'b001) begin

			ROWbit <= 8'b11111111;	
			if (swd) 	ROWbit <= 8'b01111111;
			if (swq) 	ROWbit <= 8'b10111111;
			if (swesc) 	ROWbit <= 8'b11011111;
			if (swf5) 	ROWbit <= 8'b11101111;
			if (swf) 	ROWbit <= 8'b11110111;
			if (swr) 	ROWbit <= 8'b11111011;
			if (swt) 	ROWbit <= 8'b11111101;
			if (swj) 	ROWbit <= 8'b11111110;
		end
		else if (col == 3'b000) begin

			ROWbit <= 8'b11111111;
			if (sw3) 	ROWbit <= 8'b01111111;
			if (swx) 	ROWbit <= 8'b10111111;
			if (sw1) 	ROWbit <= 8'b11011111;
			if (swf6) 	ROWbit <= 8'b11101111;
			if (swv) 	ROWbit <= 8'b11110111;
			if (sw5) 	ROWbit <= 8'b11111011;
			if (swn) 	ROWbit <= 8'b11111101;
			if (sw7) 	ROWbit <= 8'b11111110;			
		end
	end













endmodule


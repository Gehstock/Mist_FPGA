/*
 * Release 1 7/3/2019
 * Verilog description of the AY-3-8500 (NTSC varient)
 * Generated from a transistor-level netlist by DLAET
 * Some manual patches have been made (marked by comments)
 *
 * Thanks to Sean Riddle for decapping the speciman
 * and to: Suverman, Erika, Ewen McNeill, and Dylan Lipsitz
 * for supporting me on Patreon
 */

module ay_3_8500NTSC(
	output pinRPout,
	output pinLPout,
	output pinBallOut,
	input pinManualServe,
	output pinRPin_DWN,
	input pinRPin,
	input pinBallAngle,
	output pinLPin_DWN,
	input pinLPin,
	input pinBatSize,
	input pinBallSpeed,
	output pinSyncOut,
	output pinSound,
	input clk,
	input pinHitIn,
	output pinRifle1_DWN,
	input pinRifle1,
	input pinRifle2,
	input pinShotIn,
	output pinTennis_DWN,
	input pinTennis,
	output pinSFout,
	input pinSoccer,
	input pinSquash,
	input pinPractice,
	input reset,
   output vsync,
   output hsync);

	assign vsync = flop6;
	assign hsync=  !flop7;

	assign pinRPout = !or28;
	assign pinLPout = !or38;
	assign pinBallOut = !or2;
	assign pinRPin_DWN = flop6;//MC: The ORs were bypassed 
	assign pinLPin_DWN = flop6;
	assign pinSyncOut = !or56;
	assign pinSound = or69;
	assign pinRifle1_DWN = !or150;
	assign pinTennis_DWN = !or211;
	assign pinSFout = or212;
	wire pulser0 = flop6;
	wire pulser1 = (!or170 | pulser1_delay);
	reg pulser1_delay = 0;
	always @(negedge clk) begin
		pulser1_delay <= or170;
	end
	reg flop0 = 0;
	always @(posedge slow_clock) begin
		flop0 <= flop2;
	end
	reg flop1 = 0;
	wire flop1_reset = !or213 | counter5_2268;
	wire flop1_set = !or3 | !or6;
	
	// divide 16Mhz clock by 8
	reg [2:0] clockdivider = 0;
	wire slow_clock = clockdivider[2:2];
	always @(posedge clk) begin
		clockdivider <= clockdivider + 1;
	end
	
	
	always @(posedge flop1_reset or posedge flop1_set) begin
		if(flop1_reset)
			flop1 <= 0;
		else
			flop1 <= 1;
	end
	reg flop2 = 0;
	wire flop2_reset = !or213 | counter4_2130;
	wire flop2_set = !or18 | !or19;
	always @(posedge flop2_reset or posedge flop2_set) begin
		if(flop2_reset)
			flop2 <= 0;
		else
			flop2 <= 1;
	end
	reg flop3 = 0;
	wire flop3_reset = !or4;
	wire flop3_set = !pinManualServe & reset;//MC: set/reset priority have been reversed + reset added to flop3_set's OR
	always @(posedge flop3_set or posedge flop3_reset) begin
		if(flop3_set)
			flop3 <= 0;
		else
			flop3 <= 1;
	end
	reg flop4 = 0;
	wire flop4_reset = !or16 | or24 | or27 | !or213;
	wire flop4_set = !or15 | or23 | or22;
	always @(posedge flop4_reset or posedge flop4_set) begin
		if(flop4_reset)
			flop4 <= 0;
		else
			flop4 <= 1;
	end
	reg flop5 = 0;
	wire flop5_reset = or27 | or22;
	wire flop5_set = or24 | or23 | !or213;
	always @(posedge flop5_reset or posedge flop5_set) begin
		if(flop5_reset)
			flop5 <= 0;
		else
			flop5 <= 1;
	end
	reg flop6 = 0;
	wire flop6_reset = !reset | !or88;
	wire flop6_set = !or86;
	always @(posedge flop6_reset or posedge flop6_set) begin
		if(flop6_reset)
			flop6 <= 0;
		else
			flop6 <= 1;
	end
	reg flop7 = 0;
	wire flop7_reset = !reset | !or63;
	wire flop7_set = !or74;
	always @(posedge flop7_reset or posedge flop7_set) begin
		if(flop7_reset)
			flop7 <= 0;
		else
			flop7 <= 1;
	end
	reg flop8 = 0;
	always @(negedge or8) begin
		flop8 <= or55;
	end
	reg flop9 = 0;
	always @(negedge or8) begin
		flop9 <= !or49;
	end
	reg flop10 = 0;
	always @(negedge or8) begin
		flop10 <= or66;
	end
	reg flop11 = 0;
	always @(negedge or8) begin
		flop11 <= !or51;
	end
	reg flop12 = 0;
	wire flop12_reset = !or92;
	wire flop12_set = !or90;
	always @(posedge flop12_reset or posedge flop12_set) begin
		if(flop12_reset)
			flop12 <= 0;
		else
			flop12 <= 1;
	end
	reg flop13 = 0;
	wire flop13_reset = !or169;
	wire flop13_set = !flop26 | !and18;
	always @(posedge flop13_reset or posedge flop13_set) begin
		if(flop13_reset)
			flop13 <= 0;
		else
			flop13 <= 1;
	end
	reg flop14 = 0;
	wire flop14_reset = !pulser1;
	wire flop14_set = !and18;
	always @(posedge flop14_reset or posedge flop14_set) begin
		if(flop14_reset)
			flop14 <= 0;
		else
			flop14 <= 1;
	end
	reg flop15 = 0;
	wire flop15_reset = !or135;
	wire flop15_set = !or136;
	always @(posedge flop15_reset or posedge flop15_set) begin
		if(flop15_reset)
			flop15 <= 0;
		else
			flop15 <= 1;
	end
	reg flop16 = 0;
	wire flop16_reset = or144;
	wire flop16_set = !and18;
	always @(posedge flop16_reset or posedge flop16_set) begin
		if(flop16_reset)
			flop16 <= 0;
		else
			flop16 <= 1;
	end
	reg flop17 = 0;
	wire flop17_reset = or149;
	wire flop17_set = or127 | !or153 | !or213;
	always @(posedge flop17_reset or posedge flop17_set) begin
		if(flop17_reset)
			flop17 <= 0;
		else
			flop17 <= 1;
	end
	reg flop18 = 0;
	wire flop18_reset = !reset;
	wire flop18_set = !or193 | !or200;
	always @(posedge flop18_reset or posedge flop18_set) begin
		if(flop18_reset)
			flop18 <= 0;
		else
			flop18 <= 1;
	end
	reg flop19 = 0;
	wire flop19_reset = !or155;
	wire flop19_set = !and18;
	always @(posedge flop19_reset or posedge flop19_set) begin
		if(flop19_reset)
			flop19 <= 0;
		else
			flop19 <= 1;
	end
	reg flop20 = 0;
	wire flop20_reset = !or143;
	wire flop20_set = !or142;
	always @(posedge flop20_reset or posedge flop20_set) begin
		if(flop20_reset)
			flop20 <= 0;
		else
			flop20 <= 1;
	end
	reg flop21 = 0;
	wire flop21_reset = or146;
	wire flop21_set = !or138;
	always @(posedge flop21_reset or posedge flop21_set) begin
		if(flop21_reset)
			flop21 <= 0;
		else
			flop21 <= 1;
	end
	reg flop22 = 0;
	always @(posedge or152) begin
		flop22 <= flop21;
	end
	reg flop23 = 0;
	wire flop23_reset = !or70;
	wire flop23_set = !or68;
	always @(posedge flop23_reset or posedge flop23_set) begin
		if(flop23_reset)
			flop23 <= 0;
		else
			flop23 <= 1;
	end
	reg flop24 = 0;
	wire flop24_reset = !ripple_ctr9_2;
	wire flop24_set = flop25;
	always @(posedge flop24_reset or posedge flop24_set) begin
		if(flop24_reset)
			flop24 <= 0;
		else
			flop24 <= 1;
	end
	reg flop25 = 0;
	wire flop25_reset = !ripple_ctr9_2 | flop24;
	wire flop25_set = !or141;
	always @(posedge flop25_reset or posedge flop25_set) begin
		if(flop25_reset)
			flop25 <= 0;
		else
			flop25 <= 1;
	end
	reg flop26 = 0;
	wire flop26_reset = !pinHitIn;
	wire flop26_set = !and18;
	always @(posedge flop26_reset or posedge flop26_set) begin
		if(flop26_reset)
			flop26 <= 0;
		else
			flop26 <= 1;
	end
	reg flop27 = 0;
	wire flop27_reset = !or199;
	wire flop27_set = !or166;
	always @(posedge flop27_reset or posedge flop27_set) begin
		if(flop27_reset)
			flop27 <= 0;
		else
			flop27 <= 1;
	end
	reg flop28 = 0;
	wire flop28_reset = !or124;
	wire flop28_set = !or70;
	always @(posedge flop28_reset or posedge flop28_set) begin
		if(flop28_reset)
			flop28 <= 0;
		else
			flop28 <= 1;
	end
	reg flop29 = 0;
	wire flop29_reset = !or164;
	wire flop29_set = !or199;
	always @(posedge flop29_reset or posedge flop29_set) begin
		if(flop29_reset)
			flop29 <= 0;
		else
			flop29 <= 1;
	end
	reg flop30 = 0;
	wire flop30_reset = !or199 | or205;
	wire flop30_set = !reset;
	always @(posedge flop30_reset or posedge flop30_set) begin
		if(flop30_reset)
			flop30 <= 0;
		else
			flop30 <= 1;
	end
	reg flop31 = 0;
	wire flop31_reset = !or188;
	wire flop31_set = !and18;
	always @(posedge flop31_reset or posedge flop31_set) begin
		if(flop31_reset)
			flop31 <= 0;
		else
			flop31 <= 1;
	end
	reg flop32 = 0;
	wire flop32_reset = !flop13 | !or155 | or144 | !pulser1;
	wire flop32_set = !and18;
	always @(posedge flop32_reset or posedge flop32_set) begin
		if(flop32_reset)
			flop32 <= 0;
		else
			flop32 <= 1;
	end
	reg flop33 = 0;
	wire flop33_reset = !or193 | !or200 | !or205;
	wire flop33_set = !or210;
	always @(posedge flop33_reset or posedge flop33_set) begin
		if(flop33_reset)
			flop33 <= 0;
		else
			flop33 <= 1;
	end
	reg flop34 = 0;
	wire flop34_reset = !or181;
	wire flop34_set = !or177;
	always @(posedge flop34_reset or posedge flop34_set) begin
		if(flop34_reset)
			flop34 <= 0;
		else
			flop34 <= 1;
	end
	reg flop35 = 0;
	wire flop35_reset = !or168;
	wire flop35_set = !or178;
	always @(posedge flop35_reset or posedge flop35_set) begin
		if(flop35_reset)
			flop35 <= 0;
		else
			flop35 <= 1;
	end
	wire and0 = !or26 & !or147;
	wire and1 = !or29 & or118;
	wire and2 = !or31 & !or147;
	wire and3 = !or34 & or118;
	wire and4 = !or36 & !or147;
	wire and5 = !or39 & or118;
	wire and6 = !or42 & !or147;
	wire and7 = !or43 & or118;
	wire and8 = !or117 & or0;
	wire and9 = !flop23 & ripple_ctr1_4;
	wire and10 = flop23 & ripple_ctr0_4;
	wire and11 = !flop23 & ripple_ctr1_3;
	wire and12 = flop23 & ripple_ctr0_3;
	wire and13 = !flop23 & ripple_ctr1_2;
	wire and14 = flop23 & ripple_ctr0_2;
	wire and15 = !flop23 & ripple_ctr1_5;
	wire and16 = flop23 & ripple_ctr0_5;
	wire and17 = flop4 & !or214;
	wire and18 = or1 & reset;
	wire and19 = !or214 & flop17;
	wire or0 = !or72 | !or73;
	wire or1 = ripple_ctr4_4 | ripple_ctr4_3 | ripple_ctr4_2 | ripple_ctr4_5;
	wire or2 = !or13 | or196 | pinHitIn;
	wire or3 = !or205 | !counter5_2254;
	wire or4 = !or176 | flop7;
	wire or5 = !counter5_2265 | !flop0 | !or209;
	wire or6 = or205 | !counter5_2263;
	wire or7 = !flop2 | !flop1 | !or209;
	wire or8 = !or16 | !or15 | or127 | or149 | !or213;
	wire or9 = pinBallSpeed | flop8;
	wire or10 = flop9 | pinBallSpeed;
	wire or11 = pinBallSpeed | flop11;
	wire or12 = !pinBallSpeed | flop10;
	wire or13 = !or7 | !or214;
	wire or14 = flop6 | !pinRPin;
	wire or15 = !or13 | !or195;
	wire or16 = !or13 | !or65;
	wire or17 = !or16 | !or15 | !or152 | !or67;
	wire or18 = !or205 | !counter4_2125;
	wire or19 = or205 | !counter4_2128;
	wire or20 = !ripple_ctr7_2 | !ripple_ctr7_3 | !ripple_ctr7_4 | !ripple_ctr7_5;
	wire or21 = or14 | !or54 | !or20;
	wire or22 = and6 | and7;
	wire or23 = and4 | and5;
	wire or24 = and2 | and3;
	wire or25 = !ripple_ctr8_2 | !ripple_ctr8_3 | !ripple_ctr8_4 | !ripple_ctr8_5;
	wire or26 = !ripple_ctr7_4 | !ripple_ctr7_5;
	wire or27 = and0 | and1;
	wire or28 = !or120 | flop34 | or14 | !or20 | or205;
	wire or29 = !ripple_ctr8_4 | !ripple_ctr8_5;
	wire or30 = !flop5 | !flop4;
	wire or31 = ripple_ctr7_4 | !ripple_ctr7_5;
	wire or32 = !flop17 | pinBallSpeed;
	wire or33 = !flop5 | flop4;
	wire or34 = ripple_ctr8_4 | !ripple_ctr8_5;
	wire or35 = !flop4 | flop5;
	wire or36 = !ripple_ctr7_4 | ripple_ctr7_5;
	wire or37 = !flop17 | !pinBallSpeed;
	wire or38 = !or119 | flop34 | or48 | !or25 | or205;
	wire or39 = !ripple_ctr8_4 | ripple_ctr8_5;
	wire or40 = flop17 | pinBallSpeed;
	wire or41 = flop4 | flop5;
	wire or42 = ripple_ctr7_4 | ripple_ctr7_5;
	wire or43 = ripple_ctr8_5 | ripple_ctr8_4;
	wire or44 = flop17 | !pinBallSpeed;
	wire or45 = !or25 | !or54 | or48;
	wire or46 = !pinBallAngle | or41;
	wire or47 = !pinBallAngle | or35;
	wire or48 = flop6 | !pinLPin;
	wire or49 = !or47 | !or30;
//	wire or50 = !or32 | !or37 | !or40 | !or44 | !reset;
	wire or51 = !or46 | !or33;
	wire or52 = !pinBatSize | !ripple_ctr10_2;
	wire or53 = flop7 | pinBatSize;
	wire or54 = !or53 | !or52;
	wire or55 = or35 | pinBallAngle;
	wire or56 = flop6 | !flop7;
	wire or57 = !reset | !or74;
	wire or58 = !reset | !or88;
	wire or59 = !pinBallSpeed | flop9;
	wire or60 = pinBallSpeed | flop10;
	wire or61 = !pinBallSpeed | flop8;
	wire or62 = !pinBallSpeed | flop11;
	wire or63 = ripple_ctr9_2 | !counter2_2060;
	wire or64 = ripple_ctr9_2 | !counter2_2048;
	wire or65 = !or181 | !or71;
	wire or66 = or41 | pinBallAngle;
	wire or67 = or158 | !or176;
	wire or68 = ripple_ctr9_2 | !counter2_2031;
	wire or69 = !or130 | !or133;
	wire or70 = ripple_ctr9_2 | !counter2_2013;
	wire or71 = !flop7 | !counter3_2020;
	wire or72 = and11 | and12;
	wire or73 = and9 | and10;
	wire or74 = ripple_ctr9_2 | !counter2_2064;
	wire or75 = !or117 | !or112 | !or72 | !or73;
	wire or76 = or107 | or106 | or105 | !or95 | !or96 | !or97 | !or98 | or110 | or109;
	wire or77 = or107 | or106 | !or96 | !or97 | !or98 | or110 | or109 | or108;
	wire or78 = or107 | or106 | or105 | !or95 | !or96 | !or97 | !or98 | or110 | or109 | or108;
	wire or79 = or107 | or106 | or105 | !or95 | !or97 | !or98 | or108;
	wire or80 = or107 | or105 | !or95 | !or96 | !or97 | !or98 | or110 | or108;
	wire or81 = or107 | or105 | !or95 | !or97 | !or98 | or110 | or108;
	wire or82 = !or95 | !or97 | or110 | or108;
	wire or83 = or107 | or106 | or105 | !or95 | !or97 | !or98 | or110 | or108;
	wire or84 = or106 | or105 | !or95 | !or97 | !or98 | or110;
	wire or85 = or107 | or106 | or105 | !or95 | !or96 | !or97 | !or98 | or110 | or108;
	wire or86 = !or63 | !counter3_2129;
	wire or87 = !or117 | or112 | !or72 | !or73;
	wire or88 = !or63 | !counter3_2131;
	wire or89 = !or117 | !or112 | or72 | !or73;
	wire or90 = !flop7 | !counter3_2034;
	wire or91 = !or117 | or112 | or72 | !or73;
	wire or92 = !flop7 | !counter3_2022;
	wire or93 = !or117 | !or112 | or73 | !or72;
	wire or94 = !or117 | or112 | or73 | !or72;
	wire or95 = !or117 | !or112 | or73 | or72;
	wire or96 = !or117 | or112 | or73 | or72;
	wire or97 = !or112 | or117 | !or72 | !or73;
	wire or98 = or112 | or117 | !or72 | !or73;
	wire or99 = !or112 | or117 | or72 | !or73;
	wire or100 = or112 | or117 | or72 | !or73;
	wire or101 = !or112 | or117 | or73 | !or72;
	wire or102 = or112 | or117 | or73 | !or72;
	wire or103 = !or112 | or117 | or73 | or72;
	wire or104 = or112 | or117 | or73 | or72;
	wire or105 = !or94 | !or104;
	wire or106 = !or93 | !or103;
	wire or107 = !or91 | !or102;
	wire or108 = !or89 | !or101;
	wire or109 = !or87 | !or100;
	wire or110 = !or75 | !or99;
	wire or111 = counter1_2000 | counter1_2006;
	wire or112 = and13 | and14;
	wire or113 = !and8 | or111;
	wire or114 = mux2_100 | or111;
	wire or115 = mux0_100 | or111;
	wire or116 = mux1_100 | or111;
	wire or117 = and15 | and16;
	wire or118 = !or138 | !or128;
	wire or119 = !or137 | !or132;
	wire or120 = !or123 | !or122 | !or126;
	wire or121 = ripple_ctr9_2 | !counter2_2014;
	wire or122 = ripple_ctr9_2 | or204 | !counter2_2022;
	wire or123 = ripple_ctr9_2 | or206 | !counter2_2039;
	wire or124 = ripple_ctr9_2 | !counter2_2049;
	wire or125 = flop18 | or28;
	wire or126 = or202 | or64;
	wire or127 = !or148 | !or134;
	wire or128 = !or191 | or134;
	wire or129 = or38 | flop18 | !or191;
	wire or130 = !or131 | or205;
	wire or131 = !or139 | !or140 | !or151;
	wire or132 = or121 | or202;
	wire or133 = !or205 | ripple_ctr3_2 | flop13;
	wire or134 = !or176 | or129;
	wire or135 = ripple_ctr9_2 | !counter2_2029;
	wire or136 = ripple_ctr9_2 | !counter2_2024;
	wire or137 = ripple_ctr9_2 | or207 | !counter2_2040;
	wire or138 = or191 | !or176 | flop18 | or38 | !or165;
	wire or139 = flop14 | ripple_ctr3_2;
	wire or140 = flop16 | !ripple_ctr5_2;
	wire or141 = !or142 | !or136;
	wire or142 = ripple_ctr9_2 | !or189 | !counter2_2033;
	wire or143 = ripple_ctr9_2 | !counter2_2038;
	wire or144 = !or134 | !or147 | !or138;
	wire or145 = !or182 | !or172;
	wire or146 = !or147 | !reset;
	wire or147 = or125 | !or176 | !or167;
	wire or148 = or161 | !or176;
	wire or149 = !or147 | !or138 | !or67;
	wire or150 = !pinRifle1 | and17;
	wire or151 = flop19 | !ripple_ctr6_2;
	wire or152 = !or176 | or161;
	wire or153 = pinRifle2 | !pinSoccer;
	wire or154 = !flop17 | !or191;
	wire or155 = !or17 | or170;
	wire or156 = !flop21 | or191;
	wire or157 = !or154 | !or156;
	wire or158 = flop35 | or124 | or204 | !or153;
	wire or159 = flop17 | !or191;
	wire or160 = flop34 | or202 | or68;
	wire or161 = flop35 | or70 | or203;
	wire or162 = flop21 | or191;
	wire or163 = !or159 | !or162;
	wire or164 = !or163 | flop7 | !or176;
	wire or165 = !flop22 | or191;
	wire or166 = !or157 | flop7 | !or176;
	wire or167 = flop22 | or191;
	wire or168 = !flop7 | !counter3_2096;
	wire or169 = flop26 | !pinHitIn;
	wire or170 = !flop29 | flop27;
	wire or171 = !or161 | !or158;
	wire or172 = flop12 | !flop20 | ripple_ctr9_2;
	wire or173 = !flop27 | or205 | flop18;
	wire or174 = ripple_ctr10_2 | !or171 | flop34;
	wire or175 = !or124 | !or70;
	wire or176 = !or5 | !or214;
	wire or177 = !flop7 | !counter3_2117;
	wire or178 = !flop7 | or208 | !counter3_2041;
	wire or179 = !or205 | flop18 | !pinShotIn;
	wire or180 = !flop7 | !counter3_2116;
	wire or181 = !flop7 | !counter3_2021;
	wire or182 = flop12 | !flop15 | ripple_ctr9_2;
	wire or183 = flop30 | !or179 | !or173;
	wire or184 = !or160 | !or198 | !or174;
	wire or185 = !or150 | !pinSoccer;
	wire or186 = flop29 | or205 | flop18;
	wire or187 = !or184 | or205;
	wire or188 = !ripple_ctr6_2 | flop32;
	wire or189 = !pinSoccer | pinPractice;
	wire or190 = !or205 | flop18 | !pinHitIn;
	wire or191 = !pinSoccer | pinSquash;
	wire or192 = flop30 | !or186 | !or190;
	wire or193 = ripple_ctr1_4 | ripple_ctr1_3 | ripple_ctr1_2 | ripple_ctr1_5 | or183;
	wire or194 = !or180 | !or181;
	wire or195 = !or177 | !or180;
	wire or196 = flop34 | !flop28;
	wire or197 = flop12 | shift_reg0_104 | flop33;
	wire or198 = !or194 | !flop28 | ripple_ctr9_2;
	wire or199 = !or175 | !or176;
	wire or200 = ripple_ctr0_5 | ripple_ctr0_2 | ripple_ctr0_3 | ripple_ctr0_4 | or192;
	wire or201 = !pinSoccer | !or211;
	wire or202 = !or189 | !or191;
	wire or203 = !or201 | !or153;
	wire or204 = !or189 | !or191 | !or201;
	wire or205 = !or185 | !or153;
	wire or206 = !pinSoccer | !or201;
	wire or207 = !or189 | !or201;
	wire or208 = !or185 | !or189 | !or191;
	wire or209 = pinPractice | pinSoccer;
	wire or210 = reset | !or205;
	wire or211 = !pinTennis | and19;
	wire or212 = !or187 | !or197;
	wire or213 = pinSquash | pinSoccer;
	wire or214 = pinSoccer | pinRifle2;
	reg [5:0] shift_reg0 = 0;
	reg [3:0] shift_reg0_spot = 0;
/* verilator lint_off WIDTH */
	wire shift_reg0_104 = shift_reg0[shift_reg0_spot];
/* verilator lint_on WIDTH */
	always @(negedge or145 or posedge flop24) begin
		if(flop24) begin
			shift_reg0_spot <= 5;
		end
		else if(shift_reg0_spot!=0) begin
			shift_reg0_spot <= shift_reg0_spot - 1;
		end
	end
	//MC: This block had to be manually changed
	always @(posedge flop24) begin
		shift_reg0[0:0] <= 1;
		shift_reg0[1:1] <= or115;
		shift_reg0[2:2] <= or116;
		shift_reg0[3:3] <= or114;
		shift_reg0[4:4] <= 1;
		shift_reg0[5:5] <= or113;
	end
	//MC: All ripple counter outputs (except paddle ones) have inverted resets & outputs
	reg [4:0] ripple_ctr0 = 0;
	wire ripple_ctr0_2 = !ripple_ctr0[0:0];
	wire ripple_ctr0_3 = !ripple_ctr0[1:1];
	wire ripple_ctr0_4 = !ripple_ctr0[2:2];
	wire ripple_ctr0_5 = !ripple_ctr0[3:3];
	always @(posedge or192 or negedge reset) begin
		if(!reset)
			ripple_ctr0 <= 0;
		else
			ripple_ctr0 <= ripple_ctr0 + 1;
	end

	reg [4:0] ripple_ctr1 = 0;
	wire ripple_ctr1_2 = !ripple_ctr1[0:0];
	wire ripple_ctr1_3 = !ripple_ctr1[1:1];
	wire ripple_ctr1_4 = !ripple_ctr1[2:2];
	wire ripple_ctr1_5 = !ripple_ctr1[3:3];
	always @(posedge or183 or negedge reset) begin
		if(!reset)
			ripple_ctr1 <= 0;
		else
			ripple_ctr1 <= ripple_ctr1 + 1;
	end

	reg [1:0] ripple_ctr2 = 0;
	wire ripple_ctr2_2 = !ripple_ctr2[0:0];
	always @(negedge ripple_ctr10_2 or negedge or213) begin
		if(!or213)
			ripple_ctr2 <= 0;
		else
			ripple_ctr2 <= ripple_ctr2 + 1;
	end

	reg [1:0] ripple_ctr3 = 0;
	wire ripple_ctr3_2 = !ripple_ctr3[0:0];
	always @(negedge ripple_ctr2_2 or negedge or213) begin
		if(!or213)
			ripple_ctr3 <= 0;
		else
			ripple_ctr3 <= ripple_ctr3 + 1;
	end

	reg [4:0] ripple_ctr4 = 0;
	wire ripple_ctr4_2 = !ripple_ctr4[0:0];
	wire ripple_ctr4_3 = !ripple_ctr4[1:1];
	wire ripple_ctr4_4 = !ripple_ctr4[2:2];
	wire ripple_ctr4_5 = !ripple_ctr4[3:3];
	always @(negedge or188 or posedge flop31) begin
		if(flop31)
			ripple_ctr4 <= 0;
		else
			ripple_ctr4 <= ripple_ctr4 + 1;
	end

	reg [1:0] ripple_ctr5 = 0;
	wire ripple_ctr5_2 = !ripple_ctr5[0:0];
	always @(negedge ripple_ctr3_2 or negedge reset) begin
		if(!reset)
			ripple_ctr5 <= 0;
		else
			ripple_ctr5 <= ripple_ctr5 + 1;
	end

	reg [1:0] ripple_ctr6 = 0;
	wire ripple_ctr6_2 = !ripple_ctr6[0:0];
	always @(negedge ripple_ctr5_2 or negedge reset) begin
		if(!reset)
			ripple_ctr6 <= 0;
		else
			ripple_ctr6 <= ripple_ctr6 + 1;
	end

	reg [4:0] ripple_ctr7 = 0;
	wire ripple_ctr7_2 = ripple_ctr7[0:0];
	wire ripple_ctr7_3 = ripple_ctr7[1:1];
	wire ripple_ctr7_4 = ripple_ctr7[2:2];
	wire ripple_ctr7_5 = ripple_ctr7[3:3];
	always @(negedge or21 or posedge or14) begin
		if(or14)
			ripple_ctr7 <= 0;
		else
			ripple_ctr7 <= ripple_ctr7 + 1;
	end

	reg [4:0] ripple_ctr8 = 0;
	wire ripple_ctr8_2 = ripple_ctr8[0:0];
	wire ripple_ctr8_3 = ripple_ctr8[1:1];
	wire ripple_ctr8_4 = ripple_ctr8[2:2];
	wire ripple_ctr8_5 = ripple_ctr8[3:3];
	always @(negedge or45 or posedge or48) begin
		if(or48)
			ripple_ctr8 <= 0;
		else
			ripple_ctr8 <= ripple_ctr8 + 1;
	end

	reg [1:0] ripple_ctr9 = 0;
	wire ripple_ctr9_2 = !ripple_ctr9[0:0];
	always @(negedge slow_clock or negedge or213) begin
		if(!or213)
			ripple_ctr9 <= 0;
		else
			ripple_ctr9 <= ripple_ctr9 + 1;
	end

	reg [1:0] ripple_ctr10 = 0;
	wire ripple_ctr10_2 = !ripple_ctr10[0:0];
	always @(posedge flop7 or negedge or213) begin
		if(!or213)
			ripple_ctr10 <= 0;
		else
			ripple_ctr10 <= ripple_ctr10 + 1;
	end

	//MC: Add flop12 reset
	reg [2:0] counter0 = 0;
	wire counter0_2003 = (counter0==3);
	always @(negedge flop7 or posedge flop12) begin
		if(flop12)
			counter0 <= 0;		
		else if(counter0==3)
			counter0 <= 0;
		else
			counter0 <= counter0 + 1;
	end
	reg [3:0] counter1 = 0;
	wire counter1_2005 = (counter1==5);
	wire counter1_2003 = (counter1==3);
	wire counter1_2006 = (counter1==6);
	wire counter1_2000 = (counter1==0);
	wire counter1_2001 = (counter1==1);
	wire counter1_2002 = (counter1==2);
	wire counter1_2004 = (counter1==4);
	always @(negedge counter0_2003 or posedge flop12) begin
		if(flop12)
			counter1 <= 0;
		else if(counter1==6)
			counter1 <= 0;
		else
			counter1 <= counter1 + 1;
	end
	reg [7:0] counter2 = 0;
	wire counter2_2038 = (counter2==38);
	wire counter2_2033 = (counter2==33);
	wire counter2_2029 = (counter2==29);
	wire counter2_2049 = (counter2==49);
	wire counter2_2022 = (counter2==22);
	wire counter2_2064 = (counter2==64);
	wire counter2_2048 = (counter2==48);
	wire counter2_2040 = (counter2==40);
	wire counter2_2039 = (counter2==39);
	wire counter2_2031 = (counter2==31);
	wire counter2_2024 = (counter2==24);
	wire counter2_2014 = (counter2==14);
	wire counter2_2013 = (counter2==13);
	wire counter2_2060 = (counter2==60);
	always @(posedge ripple_ctr9_2 or posedge or57) begin
		if(or57)
			counter2 <= 0;
		else if(counter2==126)
			counter2 <= 0;
		else
			counter2 <= counter2 + 1;
	end
	reg [8:0] counter3 = 0;
	wire counter3_2129 = (counter3==129);
	wire counter3_2131 = (counter3==131);
	wire counter3_2117 = (counter3==117);
	wire counter3_2096 = (counter3==96);
	wire counter3_2022 = (counter3==22);
	wire counter3_2020 = (counter3==20);
	wire counter3_2116 = (counter3==116);
	wire counter3_2041 = (counter3==41);
	wire counter3_2034 = (counter3==34);
	wire counter3_2021 = (counter3==21);
	always @(posedge ripple_ctr10_2 or posedge or58) begin
		if(or58)
			counter3 <= 0;
		else if(counter3==216)
			counter3 <= 0;
		else
			counter3 <= counter3 + 1;
	end
	//MC: Multiple changes to jumping counters
	reg [8:0] counter4 = 0;
	reg counter4_delay = 0;
	reg counter4_jump = 0;
	wire counter4_2130 = (counter4==129);
	wire counter4_2125 = (counter4==125);
	wire counter4_2128 = (counter4==128);
	always @(posedge slow_clock) begin
		if(!reset | flop3) begin
			counter4 <= 0;
			counter4_jump <= 0;
		end
		else begin
			if(counter4==129) begin
				counter4 <= !counter4_jump ? 2 : !or32 ? 0 : !or37 ? 1 : !or40 ? 4 : !or44 ? 3 : 0;//MC: 3 & 4 changed to 4 & 5
				counter4_jump <= 0;
			end
			else begin
				counter4_delay <= pulser0;
				if(!counter4_delay && pulser0)
					counter4_jump <= 1;
				counter4 <= counter4 + 1;
			end
		end
	end

	reg [9:0] counter5 = 0;
	reg counter5_delay = 0;
	reg counter5_jump = 0;
	wire counter5_2254 = (counter5==254);
	wire counter5_2263 = (counter5==263);
	wire counter5_2265 = (counter5==265);
	wire counter5_2268 = (counter5==267);
	always @(negedge flop7) begin
		if(!reset) begin
			counter5 <= 0;
			counter5_jump <= 0;
		end
		else begin
			if(counter5==267) begin//Values > non-jump must be increased by 4?
				counter5 <= !counter5_jump ? 6 : !or59 ? 11 : !or9 ? 15 : !or10 ? 12 : !or62 ? 5 : !or61 ? 13 : !or11 ? 4 : !or12 ? 3 : !or60 ? 1 : 0;
				counter5_jump <= 0;
			end
			else begin
				counter5_delay <= pulser0;
				if(!counter5_delay && pulser0)
					counter5_jump <= 1;
				counter5 <= counter5 + 1;
			end
		end
	end
	wire mux0_100 = (!or78 & counter1_2001) | (!or77 & counter1_2002) | (!or76 & counter1_2004);
	//MC: Some changes to this line
	wire mux1_100 = (!or81 & counter1_2005) | (!or80 & counter1_2001) | (!or79 & counter1_2003) | counter1_2002 | counter1_2004;//constants had to be added manually
	wire mux2_100 = (!or81 & counter1_2005) | (!or85 & counter1_2001) | (!or83 & counter1_2003) | (!or84 & counter1_2002) | (!or82 & counter1_2004);
endmodule
/*verilator lint_on  UNOPTFLAT */

// Display for Acorn system1
// Dave Wood 2019
//
// This is a complete mess and needs a re-write
//
// "Abandon all hope, ye who enter here."
//
//
//

module vga (
	input			clk,
	input			rst,
	input wire x1,y1,mbtnL,mbtnR,mbtnM,
	input wire [10:0] mx,my,
	input wire [8:0] ch0,ch1,ch2,ch3,ch4,ch5,ch6,ch7,
	output wire  osw0,osw1,osw2,osw3,osw4,osw5,osw6,osw7,osw8,osw9,oswa,oswb,oswc,oswd,oswe,oswf,oswrst,oswm,oswl,oswg,oswr,oswp,oswU,osws,oswD,
	output wire [7:0] r,g,b,
	output reg hs, vs, hblank, vblank
);

wire [9:0] 		dot_x = mx[9:0];
wire [9:0] 		dot_y = my[9:0];
reg [7:0] 	dispvar;
reg [23:0]	pix_col;
//reg [9:0] mp;


assign r = pix_col[23:16];
assign g = pix_col[15:8];
assign b = pix_col[7:0];


reg [9:0]hcount,vcount;
localparam hmax = 10'd799, vmax = 10'd524;

reg sw0,sw1,sw2,sw3,sw4,sw5,sw6,sw7,sw8,sw9,swa,swb,swc,swd,swe,swf,swm,swl,swg,swr,swp,swU,sws,swD;
reg swrst=1'b0;
assign osw0 = sw0;
assign osw1 = sw1;
assign osw2 = sw2;
assign osw3 = sw3;
assign osw4 = sw4;
assign osw5 = sw5;
assign osw6 = sw6;
assign osw7 = sw7;
assign osw8 = sw8;
assign osw9 = sw9;
assign oswa = swa;
assign oswb = swb;
assign oswc = swc;
assign oswd = swd;
assign oswe = swe;
assign oswf = swf;
assign oswrst = swrst;
assign oswm = swm;
assign oswl = swl;
assign oswg = swg;
assign oswr = swr;
assign oswp = swp;
assign oswU = swU;
assign osws = sws;
assign oswD = swD;

always @(posedge clk, posedge rst) begin 
	if (rst) begin
		hcount <= 10'd0;
		vcount <= 10'd0;
	end else begin
// h & v pixel counters	
		if(hcount < hmax)
			hcount <= hcount + 1'b1;
		else begin
			hcount <= 10'd0;
			if(vcount < vmax)
				vcount <= vcount + 1'b1;
			else
				vcount <= 10'd0;
		end
		
// v & h sync signals	
		if(hcount == 10'd656)
			hs<=1'b1;
		else if (hcount >= 10'd752)
			hs<=1'b0;		
		if(vcount == 10'd490)
			vs<=1'b1;
		else if(vcount >= 10'd492)
			vs<=1'b0;
			
// h & v blanking signals
		if(hcount >= 10'd640)
			hblank <= 1'b1;
		else
			hblank <= 1'b0;
	
		if(vcount >= 10'd480)
			vblank <= 1'b1;
		else
			vblank <= 1'b0;
		
	end
end

always @(posedge clk, posedge rst) begin
	if(rst)
		pix_col <= black;
	else begin
// borders
		if(vcount == 10'd0 || vcount == 10'd479)
			pix_col <= olive;
		else if(hcount == 10'd0 || hcount == 10'd639)
			pix_col <= teal;
		else 
			pix_col <= black;
		//eurocard
		if(hcount >= 10'd100 && hcount <= 10'd484 && vcount >= 10'd110 && vcount <= 10'd370)
			pix_col <= green;	
			
		//ic1 & 8
		if(hcount >= 10'd112 && hcount <= 10'd113 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd116 && hcount <= 10'd117 && vcount == 10'd149)
			pix_col <= silver;	
		if(hcount >= 10'd120 && hcount <= 10'd121 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd149)
			pix_col <= silver;
		
		if(hcount >= 10'd154 && hcount <= 10'd155 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd149)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd149)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd149)
			pix_col <= silver;
			
		if(hcount >= 10'd110 && hcount <= 10'd139 && vcount >= 10'd150 && vcount <= 10'd165)
			pix_col <= black;				
		if(hcount >= 10'd152 && hcount <= 10'd185 && vcount >= 10'd150 && vcount <= 10'd165)
			pix_col <= black;
			
		if(hcount >= 10'd112 && hcount <= 10'd113 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd116 && hcount <= 10'd117 && vcount == 10'd166)
			pix_col <= silver;	
		if(hcount >= 10'd120 && hcount <= 10'd121 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd166)
			pix_col <= silver;
		
		if(hcount >= 10'd154 && hcount <= 10'd155 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd166)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd166)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd166)
			pix_col <= silver;
			
// ic 2 & 4
		if(hcount >= 10'd112 && hcount <= 10'd113 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd116 && hcount <= 10'd117 && vcount == 10'd204)
			pix_col <= silver;	
		if(hcount >= 10'd120 && hcount <= 10'd121 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd204)
			pix_col <= silver;
		
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd204)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd204)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd204)
			pix_col <= silver;

		if(hcount >= 10'd110 && hcount <= 10'd139 && vcount >= 10'd205 && vcount <= 10'd220)
			pix_col <= black;
		if(hcount >= 10'd156 && hcount <= 10'd185 && vcount >= 10'd205 && vcount <= 10'd220)
			pix_col <= black;	
		if(hcount >= 10'd112 && hcount <= 10'd113 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd116 && hcount <= 10'd117 && vcount == 10'd221)
			pix_col <= silver;	
		if(hcount >= 10'd120 && hcount <= 10'd121 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd221)
			pix_col <= silver;
		
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd221)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd221)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd221)
			pix_col <= silver;			
// ic 3 &5

		if(hcount >= 10'd112 && hcount <= 10'd113 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd116 && hcount <= 10'd117 && vcount == 10'd259)
			pix_col <= silver;	
		if(hcount >= 10'd120 && hcount <= 10'd121 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd259)
			pix_col <= silver;
		
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd259)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd259)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd259)
			pix_col <= silver;

		if(hcount >= 10'd110 && hcount <= 10'd139 && vcount >= 10'd260 && vcount <= 10'd275)
			pix_col <= black;	
		if(hcount >= 10'd156 && hcount <= 10'd185 && vcount >= 10'd260 && vcount <= 10'd275)
			pix_col <= black;	
		if(hcount >= 10'd112 && hcount <= 10'd113 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd116 && hcount <= 10'd117 && vcount == 10'd276)
			pix_col <= silver;	
		if(hcount >= 10'd120 && hcount <= 10'd121 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd276)
			pix_col <= silver;
		
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd276)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd276)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd276)
			pix_col <= silver;
			
// ic 7 & 6		
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd314)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd314)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd314)
			pix_col <= silver;			
		if(hcount >= 10'd122 && hcount <= 10'd139 && vcount >= 10'd315 && vcount <= 10'd330)
			pix_col <= black;	
		if(hcount >= 10'd156 && hcount <= 10'd185 && vcount >= 10'd315 && vcount <= 10'd330)
			pix_col <= black;
			
		if(hcount >= 10'd124 && hcount <= 10'd125 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd128 && hcount <= 10'd129 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd132 && hcount <= 10'd133 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd136 && hcount <= 10'd137 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd158 && hcount <= 10'd159 && vcount == 10'd331)
			pix_col <= silver;	
		if(hcount >= 10'd162 && hcount <= 10'd163 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd166 && hcount <= 10'd167 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd170 && hcount <= 10'd171 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd174 && hcount <= 10'd175 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd178 && hcount <= 10'd179 && vcount == 10'd331)
			pix_col <= silver;
		if(hcount >= 10'd182 && hcount <= 10'd183 && vcount == 10'd331)
			pix_col <= silver;			
			
		//keybase
		if(hcount >= 10'd200 && hcount <= 10'd466 && vcount >= 10'd120 && vcount <= 10'd360)
			pix_col <= silver;
		//slot
		if(hcount >= 10'd244 && hcount <= 10'd336 && vcount >= 10'd200 && vcount <= 10'd204)
			pix_col <= green;
		//display
		if(hcount >= 10'd230 && hcount <= 10'd346 && vcount >= 10'd140 && vcount <= 10'd176)
			pix_col <= teal;
		
			
//chars
// left most - not connected
		if(hcount >= 10'd235 && hcount <= 10'd244 && vcount >= 10'd150 && vcount <= 10'd164) begin
			pix_col <= silver;
		end
// character 7	left
		if(hcount >= 10'd247 && hcount <= 10'd256 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd249 && hcount <= 10'd254 && vcount == 10'd152)
				pix_col <= ch7[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd248 && vcount == 10'd153)
					pix_col <= ch7[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd153)
					pix_col <= ch7[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd248 && vcount == 10'd154)
					pix_col <= ch7[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd154)
					pix_col <= ch7[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd248 && vcount == 10'd155)
					pix_col <= ch7[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd155)
					pix_col <= ch7[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd248 && vcount == 10'd156)
					pix_col <= ch7[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd156)
					pix_col <= ch7[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd249 && hcount <= 10'd254 && vcount == 10'd157)
					pix_col <= ch7[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd248 && vcount == 10'd158)
					pix_col <= ch7[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd158)
					pix_col <= ch7[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd248 && vcount == 10'd159)
					pix_col <= ch7[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd159)
					pix_col <= ch7[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd248 && vcount == 10'd160)
					pix_col <= ch7[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd160)
					pix_col <= ch7[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd248 && vcount == 10'd161)
					pix_col <= ch7[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd161)
					pix_col <= ch7[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd249 && hcount <= 10'd254 && vcount == 10'd162)
					pix_col <= ch7[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd255 && vcount == 10'd164)
					pix_col <= ch7[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
			
		end	
// character 6
		if(hcount >= 10'd259 && hcount <= 10'd268 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd261 && hcount <= 10'd266 && vcount == 10'd152)
				pix_col <= ch6[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd260 && vcount == 10'd153)
					pix_col <= ch6[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd153)
					pix_col <= ch6[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd260 && vcount == 10'd154)
					pix_col <= ch6[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd154)
					pix_col <= ch6[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd260 && vcount == 10'd155)
					pix_col <= ch6[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd155)
					pix_col <= ch6[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd260 && vcount == 10'd156)
					pix_col <= ch6[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd156)
					pix_col <= ch6[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd261 && hcount <= 10'd266 && vcount == 10'd157)
					pix_col <= ch6[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd260 && vcount == 10'd158)
					pix_col <= ch6[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd158)
					pix_col <= ch6[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd260 && vcount == 10'd159)
					pix_col <= ch6[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd159)
					pix_col <= ch6[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd260 && vcount == 10'd160)
					pix_col <= ch6[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd160)
					pix_col <= ch6[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd260 && vcount == 10'd161)
					pix_col <= ch6[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd161)
					pix_col <= ch6[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd261 && hcount <= 10'd266 && vcount == 10'd162)
					pix_col <= ch6[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd267 && vcount == 10'd164)
					pix_col <= ch6[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
		end
// character 5
		if(hcount >= 10'd271 && hcount <= 10'd280 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd273 && hcount <= 10'd278 && vcount == 10'd152)
				pix_col <= ch5[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd272 && vcount == 10'd153)
					pix_col <= ch5[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd153)
					pix_col <= ch5[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd272 && vcount == 10'd154)
					pix_col <= ch5[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd154)
					pix_col <= ch5[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd272 && vcount == 10'd155)
					pix_col <= ch5[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd155)
					pix_col <= ch5[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd272 && vcount == 10'd156)
					pix_col <= ch5[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd156)
					pix_col <= ch5[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd273 && hcount <= 10'd278 && vcount == 10'd157)
					pix_col <= ch5[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd272 && vcount == 10'd158)
					pix_col <= ch5[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd158)
					pix_col <= ch5[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd272 && vcount == 10'd159)
					pix_col <= ch5[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd159)
					pix_col <= ch5[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd272 && vcount == 10'd160)
					pix_col <= ch5[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd160)
					pix_col <= ch5[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd272 && vcount == 10'd161)
					pix_col <= ch5[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd161)
					pix_col <= ch5[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd273 && hcount <= 10'd278 && vcount == 10'd162)
					pix_col <= ch5[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd279 && vcount == 10'd164)
					pix_col <= ch5[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
		end
// character 4
		if(hcount >= 10'd283 && hcount <= 10'd292 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd285 && hcount <= 10'd290 && vcount == 10'd152)
				pix_col <= ch4[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd284 && vcount == 10'd153)
					pix_col <= ch4[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd153)
					pix_col <= ch4[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd284 && vcount == 10'd154)
					pix_col <= ch4[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd154)
					pix_col <= ch4[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd284 && vcount == 10'd155)
					pix_col <= ch4[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd155)
					pix_col <= ch4[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd284 && vcount == 10'd156)
					pix_col <= ch4[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd156)
					pix_col <= ch4[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd285 && hcount <= 10'd290 && vcount == 10'd157)
					pix_col <= ch4[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd284 && vcount == 10'd158)
					pix_col <= ch4[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd158)
					pix_col <= ch4[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd284 && vcount == 10'd159)
					pix_col <= ch4[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd159)
					pix_col <= ch4[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd284 && vcount == 10'd160)
					pix_col <= ch4[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd160)
					pix_col <= ch4[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd284 && vcount == 10'd161)
					pix_col <= ch4[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd161)
					pix_col <= ch4[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd285 && hcount <= 10'd290 && vcount == 10'd162)
					pix_col <= ch4[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd291 && vcount == 10'd164)
					pix_col <= ch4[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
		end
// character 3
		if(hcount >= 10'd295 && hcount <= 10'd304 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd297 && hcount <= 10'd302 && vcount == 10'd152)
				pix_col <= ch3[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd296 && vcount == 10'd153)
					pix_col <= ch3[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd153)
					pix_col <= ch3[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd296 && vcount == 10'd154)
					pix_col <= ch3[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd154)
					pix_col <= ch3[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd296 && vcount == 10'd155)
					pix_col <= ch3[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd155)
					pix_col <= ch3[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd296 && vcount == 10'd156)
					pix_col <= ch3[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd156)
					pix_col <= ch3[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd297 && hcount <= 10'd302 && vcount == 10'd157)
					pix_col <= ch3[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd296 && vcount == 10'd158)
					pix_col <= ch3[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd158)
					pix_col <= ch3[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd296 && vcount == 10'd159)
					pix_col <= ch3[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd159)
					pix_col <= ch3[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd296 && vcount == 10'd160)
					pix_col <= ch3[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd160)
					pix_col <= ch3[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd296 && vcount == 10'd161)
					pix_col <= ch3[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd161)
					pix_col <= ch3[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd297 && hcount <= 10'd302 && vcount == 10'd162)
					pix_col <= ch3[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd303 && vcount == 10'd164)
					pix_col <= ch3[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
		end
// character 2
		if(hcount >= 10'd307 && hcount <= 10'd316 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd309 && hcount <= 10'd314 && vcount == 10'd152)
				pix_col <= ch2[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd308 && vcount == 10'd153)
					pix_col <= ch2[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd153)
					pix_col <= ch2[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd308 && vcount == 10'd154)
					pix_col <= ch2[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd154)
					pix_col <= ch2[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd308 && vcount == 10'd155)
					pix_col <= ch2[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd155)
					pix_col <= ch2[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd308 && vcount == 10'd156)
					pix_col <= ch2[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd156)
					pix_col <= ch2[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd309 && hcount <= 10'd314 && vcount == 10'd157)
					pix_col <= ch2[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd308 && vcount == 10'd158)
					pix_col <= ch2[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd158)
					pix_col <= ch2[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd308 && vcount == 10'd159)
					pix_col <= ch2[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd159)
					pix_col <= ch2[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd308 && vcount == 10'd160)
					pix_col <= ch2[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd160)
					pix_col <= ch2[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd308 && vcount == 10'd161)
					pix_col <= ch2[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd161)
					pix_col <= ch2[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd309 && hcount <= 10'd314 && vcount == 10'd162)
					pix_col <= ch2[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd315 && vcount == 10'd164)
					pix_col <= ch2[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
		end
// character 1
		if(hcount >= 10'd319 && hcount <= 10'd328 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd321 && hcount <= 10'd326 && vcount == 10'd152)
				pix_col <= ch1[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd320 && vcount == 10'd153)
					pix_col <= ch1[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd153)
					pix_col <= ch1[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd320 && vcount == 10'd154)
					pix_col <= ch1[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd154)
					pix_col <= ch1[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd320 && vcount == 10'd155)
					pix_col <= ch1[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd155)
					pix_col <= ch1[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd320 && vcount == 10'd156)
					pix_col <= ch1[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd156)
					pix_col <= ch1[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd321 && hcount <= 10'd326 && vcount == 10'd157)
					pix_col <= ch1[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd320 && vcount == 10'd158)
					pix_col <= ch1[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd158)
					pix_col <= ch1[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd320 && vcount == 10'd159)
					pix_col <= ch1[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd159)
					pix_col <= ch1[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd320 && vcount == 10'd160)
					pix_col <= ch1[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd160)
					pix_col <= ch1[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd320 && vcount == 10'd161)
					pix_col <= ch1[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd161)
					pix_col <= ch1[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd321 && hcount <= 10'd326 && vcount == 10'd162)
					pix_col <= ch1[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd327 && vcount == 10'd164)
					pix_col <= ch1[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
		end
// character 0 right
		if(hcount >= 10'd331 && hcount <= 10'd340 && vcount >= 10'd150 && vcount <= 10'd164) begin
			if(hcount >= 10'd333 && hcount <= 10'd338 && vcount == 10'd152)
				pix_col <= ch0[0] == 1'b1 ? red : silver;
			else if(hcount == 10'd332 && vcount == 10'd153)
					pix_col <= ch0[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd153)
					pix_col <= ch0[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd332 && vcount == 10'd154)
					pix_col <= ch0[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd154)
					pix_col <= ch0[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd332 && vcount == 10'd155)
					pix_col <= ch0[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd155)
					pix_col <= ch0[1] == 1'b1 ? red : silver; 
			else if(hcount == 10'd332 && vcount == 10'd156)
					pix_col <= ch0[5] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd156)
					pix_col <= ch0[1] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd333 && hcount <= 10'd338 && vcount == 10'd157)
					pix_col <= ch0[6] == 1'b1 ? red : silver; 	
			else if(hcount == 10'd332 && vcount == 10'd158)
					pix_col <= ch0[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd158)
					pix_col <= ch0[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd332 && vcount == 10'd159)
					pix_col <= ch0[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd159)
					pix_col <= ch0[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd332 && vcount == 10'd160)
					pix_col <= ch0[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd160)
					pix_col <= ch0[2] == 1'b1 ? red : silver; 
			else if(hcount == 10'd332 && vcount == 10'd161)
					pix_col <= ch0[4] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd161)
					pix_col <= ch0[2] == 1'b1 ? red : silver; 
			else if(hcount >= 10'd333 && hcount <= 10'd338 && vcount == 10'd162)
					pix_col <= ch0[3] == 1'b1 ? red : silver; 
			else if(hcount == 10'd339 && vcount == 10'd164)
					pix_col <= ch0[7] == 1'b1 ? red : silver;
			else
				pix_col <= silver;
		end
			
			
			
//keys
//rst
		if(hcount >= 10'd408 && hcount <= 10'd432 && vcount >= 10'd196 && vcount <= 10'd208)	//rst
			pix_col <= swrst == 1'b1 ? grey : white;	
		
//1st row
		if(hcount >= 10'd232 && hcount <= 10'd256 && vcount >= 10'd224 && vcount <= 10'd236)	//c
			pix_col <= swc == 1'b1 ? grey : white;	
		if(hcount >= 10'd264 && hcount <= 10'd288 && vcount >= 10'd224 && vcount <= 10'd236)	//d
			pix_col <= swd == 1'b1 ? grey : white;
		if(hcount >= 10'd296 && hcount <= 10'd320 && vcount >= 10'd224 && vcount <= 10'd236)	//e
			pix_col <= swe == 1'b1 ? grey : white;			
		if(hcount >= 10'd328 && hcount <= 10'd352 && vcount >= 10'd224 && vcount <= 10'd236)	//f
			pix_col <= swf == 1'b1 ? grey : white;	
		if(hcount >= 10'd376 && hcount <= 10'd400 && vcount >= 10'd224 && vcount <= 10'd236)	//m
			pix_col <= swm == 1'b1 ? grey : white;			
		if(hcount >= 10'd408 && hcount <= 10'd432 && vcount >= 10'd224 && vcount <= 10'd236)	//l
			pix_col <= swl == 1'b1 ? grey : white;									
						
//2nd row
		if(hcount >= 10'd232 && hcount <= 10'd256 && vcount >= 10'd252 && vcount <= 10'd264)	//8
			pix_col <= sw8 == 1'b1 ? grey : white;	
		if(hcount >= 10'd264 && hcount <= 10'd288 && vcount >= 10'd252 && vcount <= 10'd264)	//9
			pix_col <= sw9 == 1'b1 ? grey: white;
		if(hcount >= 10'd296 && hcount <= 10'd320 && vcount >= 10'd252 && vcount <= 10'd264)	//a
			pix_col <= swa == 1'b1 ? grey : white;	
		if(hcount >= 10'd328 && hcount <= 10'd352 && vcount >= 10'd252 && vcount <= 10'd264)	//b
			pix_col <= swb == 1'b1 ? grey : white;		
		if(hcount >= 10'd376 && hcount <= 10'd400 && vcount >= 10'd252 && vcount <= 10'd264)	//g
			pix_col <= swg == 1'b1 ? grey : white;	
		if(hcount >= 10'd408 && hcount <= 10'd432 && vcount >= 10'd252 && vcount <= 10'd264)	//r
			pix_col <= swr == 1'b1 ? grey : white;
			
//3rd row		
		if(hcount >= 10'd232 && hcount <= 10'd256 && vcount >= 10'd280 && vcount <= 10'd292)	//4
			pix_col <= sw4 == 1'b1 ? grey : white;	
		if(hcount >= 10'd264 && hcount <= 10'd288 && vcount >= 10'd280 && vcount <= 10'd292)	//5
			pix_col <= sw5 == 1'b1 ? grey: white;
		if(hcount >= 10'd296 && hcount <= 10'd320 && vcount >= 10'd280 && vcount <= 10'd292)	//6
			pix_col <= sw6 == 1'b1 ? grey : white;	
		if(hcount >= 10'd328 && hcount <= 10'd352 && vcount >= 10'd280 && vcount <= 10'd292)	//7
			pix_col <= sw7 == 1'b1 ? grey : white;	
		if(hcount >= 10'd376 && hcount <= 10'd400 && vcount >= 10'd280 && vcount <= 10'd292)	//p
			pix_col <= swp == 1'b1 ? grey : white;	
		if(hcount >= 10'd408 && hcount <= 10'd432 && vcount >= 10'd280 && vcount <= 10'd292)	//U
			pix_col <= swU == 1'b1 ? grey : white;	
		
//4th row
		if(hcount >= 10'd232 && hcount <= 10'd256 && vcount >= 10'd308 && vcount <= 10'd320)	//0
			pix_col <= sw0 == 1'b1 ? grey : white;	
		if(hcount >= 10'd264 && hcount <= 10'd288 && vcount >= 10'd308 && vcount <= 10'd320)	//1
			pix_col <= sw1 == 1'b1 ? grey: white;
		if(hcount >= 10'd296 && hcount <= 10'd320 && vcount >= 10'd308 && vcount <= 10'd320)	//2
			pix_col <= sw2 == 1'b1 ? grey : white;	
		if(hcount >= 10'd328 && hcount <= 10'd352 && vcount >= 10'd308 && vcount <= 10'd320)	//3
			pix_col <= sw3 == 1'b1 ? grey : white;
		if(hcount >= 10'd376 && hcount <= 10'd400 && vcount >= 10'd308 && vcount <= 10'd320)	//s
			pix_col <= sws == 1'b1 ? grey : white;	
		if(hcount >= 10'd408 && hcount <= 10'd432 && vcount >= 10'd308 && vcount <= 10'd320)	//D
			pix_col <= swD == 1'b1 ? grey : white;		
			
//rst
		if(hcount >= 10'd414 && hcount <= 10'd415 && vcount == 10'd186)
			pix_col <= black;	
		if(hcount == 10'd413 && vcount == 10'd187)
			pix_col <= black;
		if(hcount == 10'd413 && vcount == 10'd188)
			pix_col <= black;
		if(hcount == 10'd413 && vcount == 10'd189)
			pix_col <= black;
		if(hcount == 10'd413 && vcount == 10'd190)
			pix_col <= black;	
		if(hcount == 10'd413 && vcount == 10'd191)
			pix_col <= black;
		if(hcount == 10'd413 && vcount == 10'd192)
			pix_col <= black;	
			
			
		if(hcount >= 10'd419 && hcount <= 10'd421 && vcount == 10'd186)
			pix_col <= black;	
		if(hcount == 10'd418 && vcount == 10'd187)
			pix_col <= black;	
		if(hcount == 10'd422 && vcount == 10'd187)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd188)
			pix_col <= black;
		if(hcount == 10'd420 && vcount == 10'd189)
			pix_col <= black;
		if(hcount == 10'd421 && vcount == 10'd190)
			pix_col <= black;
		if(hcount == 10'd418 && vcount == 10'd191)
			pix_col <= black;	
		if(hcount == 10'd422 && vcount == 10'd191)
			pix_col <= black;
		if(hcount >= 10'd419 && hcount <= 10'd421 && vcount == 10'd192)
			pix_col <= black;	
			
		if(hcount == 10'd427 && vcount == 10'd185)
			pix_col <= black;	
		if(hcount == 10'd427 && vcount == 10'd186)
			pix_col <= black;	
		if(hcount >= 10'd426 && hcount <= 10'd429 && vcount == 10'd187)
			pix_col <= black;
		if(hcount == 10'd427 && vcount == 10'd188)
			pix_col <= black;	
		if(hcount == 10'd427 && vcount == 10'd189)
			pix_col <= black;		
		if(hcount == 10'd427 && vcount == 10'd190)
			pix_col <= black;	
		if(hcount == 10'd427 && vcount == 10'd191)
			pix_col <= black;		
		if(hcount == 10'd427 && vcount == 10'd192)
			pix_col <= black;	

//c
		if(hcount >= 10'd243 && hcount <= 10'd245 && vcount == 10'd214)
			pix_col <= black;	
		if(hcount == 10'd242 && vcount == 10'd215)
			pix_col <= black;	
		if(hcount == 10'd246 && vcount == 10'd215)
			pix_col <= black;
		if(hcount == 10'd242 && vcount == 10'd216)
			pix_col <= black;
		if(hcount == 10'd242 && vcount == 10'd217)
			pix_col <= black;
		if(hcount == 10'd242 && vcount == 10'd218)
			pix_col <= black;
		if(hcount == 10'd242 && vcount == 10'd219)
			pix_col <= black;	
		if(hcount == 10'd246 && vcount == 10'd219)
			pix_col <= black;
		if(hcount >= 10'd243 && hcount <= 10'd245 && vcount == 10'd220)
			pix_col <= black;	
//d
		if(hcount == 10'd278 && vcount == 10'd213)
			pix_col <= black;	
		if(hcount == 10'd278 && vcount == 10'd214)
			pix_col <= black;	
		if(hcount >= 10'd275 && hcount <= 10'd278 && vcount == 10'd215)
			pix_col <= black;	
		if(hcount == 10'd274 && vcount == 10'd216)
			pix_col <= black;	
		if(hcount == 10'd278 && vcount == 10'd216)
			pix_col <= black;
		if(hcount == 10'd274 && vcount == 10'd217)
			pix_col <= black;
		if(hcount == 10'd278 && vcount == 10'd217)
			pix_col <= black;
		if(hcount == 10'd274 && vcount == 10'd218)
			pix_col <= black;
		if(hcount == 10'd278 && vcount == 10'd218)
			pix_col <= black;
		if(hcount == 10'd274 && vcount == 10'd219)
			pix_col <= black;	
		if(hcount == 10'd278 && vcount == 10'd219)
			pix_col <= black;
		if(hcount >= 10'd275 && hcount <= 10'd277 && vcount == 10'd220)
			pix_col <= black;	
//e 307
		if(hcount >= 10'd306 && hcount <= 10'd308 && vcount == 10'd214)
			pix_col <= black;	
		if(hcount == 10'd305 && vcount == 10'd215)
			pix_col <= black;
		if(hcount == 10'd309 && vcount == 10'd215)
			pix_col <= black;
		if(hcount == 10'd305 && vcount == 10'd216)
			pix_col <= black;	
		if(hcount == 10'd309 && vcount == 10'd216)
			pix_col <= black;
		if(hcount >= 10'd305 && hcount <= 10'd309 && vcount == 10'd217)
			pix_col <= black;	
//		if(hcount == 10'd305 && vcount == 10'd217)
//			pix_col <= black;
		if(hcount == 10'd305 && vcount == 10'd218)
			pix_col <= black;
		if(hcount == 10'd305 && vcount == 10'd219)
			pix_col <= black;	
		if(hcount == 10'd309 && vcount == 10'd219)
			pix_col <= black;
		if(hcount >= 10'd306 && hcount <= 10'd308 && vcount == 10'd220)
			pix_col <= black;	
//f
		if(hcount >= 10'd341 && hcount <= 10'd342 && vcount == 10'd213)
			pix_col <= black;	
		if(hcount == 10'd340 && vcount == 10'd214)
			pix_col <= black;	
		if(hcount >= 10'd339 && hcount <= 10'd342 && vcount == 10'd215)
			pix_col <= black;
		if(hcount == 10'd340 && vcount == 10'd216)
			pix_col <= black;	
		if(hcount == 10'd340 && vcount == 10'd217)
			pix_col <= black;		
		if(hcount == 10'd340 && vcount == 10'd218)
			pix_col <= black;	
		if(hcount == 10'd340 && vcount == 10'd219)
			pix_col <= black;		
		if(hcount == 10'd340 && vcount == 10'd220)
			pix_col <= black;	
			
//m
		if(hcount >= 10'd387 && hcount <= 10'd388 && vcount == 10'd214)
			pix_col <= black;	
		if(hcount >= 10'd390 && hcount <= 10'd391 && vcount == 10'd214)
			pix_col <= black;
		if(hcount == 10'd386 && vcount == 10'd215)
			pix_col <= black;	
		if(hcount == 10'd389 && vcount == 10'd215)
			pix_col <= black;
		if(hcount == 10'd392 && vcount == 10'd215)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd216)
			pix_col <= black;	
		if(hcount == 10'd389 && vcount == 10'd216)
			pix_col <= black;
		if(hcount == 10'd392 && vcount == 10'd216)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd217)
			pix_col <= black;	
		if(hcount == 10'd389 && vcount == 10'd217)
			pix_col <= black;
		if(hcount == 10'd392 && vcount == 10'd217)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd218)
			pix_col <= black;	
		if(hcount == 10'd389 && vcount == 10'd218)
			pix_col <= black;
		if(hcount == 10'd392 && vcount == 10'd218)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd219)
			pix_col <= black;	
		if(hcount == 10'd389 && vcount == 10'd219)
			pix_col <= black;
		if(hcount == 10'd392 && vcount == 10'd219)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd220)
			pix_col <= black;	
		if(hcount == 10'd389 && vcount == 10'd220)
			pix_col <= black;
		if(hcount == 10'd392 && vcount == 10'd220)
			pix_col <= black;	

//l
		if(hcount == 10'd420 && vcount == 10'd213)
			pix_col <= black;	
		if(hcount == 10'd420 && vcount == 10'd214)
			pix_col <= black;	
		if(hcount == 10'd420 && vcount == 10'd215)
			pix_col <= black;
		if(hcount == 10'd420 && vcount == 10'd216)
			pix_col <= black;	
		if(hcount == 10'd420 && vcount == 10'd217)
			pix_col <= black;		
		if(hcount == 10'd420 && vcount == 10'd218)
			pix_col <= black;	
		if(hcount == 10'd420 && vcount == 10'd219)
			pix_col <= black;		
		if(hcount == 10'd421 && vcount == 10'd220)
			pix_col <= black;	




//8
		if(hcount >= 10'd242 && hcount <= 10'd246 && vcount == 10'd240)
			pix_col <= black;		
		if(hcount == 10'd241 && vcount == 10'd241)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd241)
			pix_col <= black;			
		if(hcount == 10'd241 && vcount == 10'd242)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd242)
			pix_col <= black;				
		if(hcount == 10'd241 && vcount == 10'd243)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd243)
			pix_col <= black;			
		if(hcount >= 10'd242  && hcount <= 10'd246 && vcount == 10'd244)
			pix_col <= black;
		if(hcount == 10'd241 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd241 && vcount == 10'd246)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd246)
			pix_col <= black;
		if(hcount == 10'd241 && vcount == 10'd247)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd247)
			pix_col <= black;
		if(hcount >= 10'd242 && hcount <= 10'd246 && vcount == 10'd248)
			pix_col <= black;


//9
		if(hcount >= 10'd274 && hcount <= 10'd278 && vcount == 10'd240)
			pix_col <= black;		
		if(hcount == 10'd273 && vcount == 10'd241)
			pix_col <= black;
		if(hcount == 10'd279 && vcount == 10'd241)
			pix_col <= black;			
		if(hcount == 10'd273 && vcount == 10'd242)
			pix_col <= black;
		if(hcount == 10'd279 && vcount == 10'd242)
			pix_col <= black;				
		if(hcount == 10'd273 && vcount == 10'd243)
			pix_col <= black;
		if(hcount == 10'd279 && vcount == 10'd243)
			pix_col <= black;			
		if(hcount >= 10'd274  && hcount <= 10'd278 && vcount == 10'd244)
			pix_col <= black;

		if(hcount == 10'd279 && vcount == 10'd245)
			pix_col <= black;

		if(hcount == 10'd279 && vcount == 10'd246)
			pix_col <= black;

		if(hcount == 10'd279 && vcount == 10'd247)
			pix_col <= black;
		if(hcount >= 10'd274 && hcount <= 10'd278 && vcount == 10'd248)
			pix_col <= black;
//a
		if(hcount >= 10'd307 && hcount <= 10'd309 && vcount == 10'd241)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd242)
			pix_col <= black;	
		if(hcount == 10'd310 && vcount == 10'd243)
			pix_col <= black;	
		if(hcount >= 10'd307 && hcount <= 10'd310 && vcount == 10'd244)
			pix_col <= black;	
//		if(hcount == 10'd306 && vcount == 10'd244)
//			pix_col <= black;	
//		if(hcount == 10'd310 && vcount == 10'd244)
//			pix_col <= black;
		if(hcount == 10'd306 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd306 && vcount == 10'd246)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd246)
			pix_col <= black;
		if(hcount == 10'd306 && vcount == 10'd247)
			pix_col <= black;	
		if(hcount == 10'd310 && vcount == 10'd247)
			pix_col <= black;
		if(hcount >= 10'd307 && hcount <= 10'd310 && vcount == 10'd248)
			pix_col <= black;	
//b
		if(hcount == 10'd338 && vcount == 10'd241)
			pix_col <= black;	
		if(hcount == 10'd338 && vcount == 10'd242)
			pix_col <= black;	
		if(hcount >= 10'd338 && hcount <= 10'd341 && vcount == 10'd243)
			pix_col <= black;	
		if(hcount == 10'd338 && vcount == 10'd244)
			pix_col <= black;	
		if(hcount == 10'd342 && vcount == 10'd244)
			pix_col <= black;
		if(hcount == 10'd338 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd342 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd338 && vcount == 10'd246)
			pix_col <= black;
		if(hcount == 10'd342 && vcount == 10'd246)
			pix_col <= black;
		if(hcount == 10'd338 && vcount == 10'd247)
			pix_col <= black;	
		if(hcount == 10'd342 && vcount == 10'd247)
			pix_col <= black;
		if(hcount >= 10'd339 && hcount <= 10'd341 && vcount == 10'd248)
			pix_col <= black;				
//g
		if(hcount >= 10'd387 && hcount <= 10'd390 && vcount == 10'd241)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd242)
			pix_col <= black;	
		if(hcount == 10'd390 && vcount == 10'd242)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd243)
			pix_col <= black;	
		if(hcount == 10'd390 && vcount == 10'd243)
			pix_col <= black;
		if(hcount == 10'd386 && vcount == 10'd244)
			pix_col <= black;
		if(hcount == 10'd390 && vcount == 10'd244)
			pix_col <= black;
		if(hcount >= 10'd387 && hcount <= 10'd390 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd390 && vcount == 10'd246)
			pix_col <= black;	
		if(hcount == 10'd390 && vcount == 10'd247)
			pix_col <= black;
		if(hcount >= 10'd387 && hcount <= 10'd389 && vcount == 10'd248)
			pix_col <= black;	
			
//r
		if(hcount >= 10'd420 && hcount <= 10'd421 && vcount == 10'd242)
			pix_col <= black;	
		if(hcount == 10'd419 && vcount == 10'd243)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd244)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd245)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd246)
			pix_col <= black;	
		if(hcount == 10'd419 && vcount == 10'd247)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd248)
			pix_col <= black;	



//4
		if(hcount == 10'd245 && vcount == 10'd268)
			pix_col <= black;		
		if(hcount == 10'd244 && vcount == 10'd269)
			pix_col <= black;
		if(hcount == 10'd245 && vcount == 10'd269)
			pix_col <= black;			
		if(hcount == 10'd243 && vcount == 10'd270)
			pix_col <= black;
		if(hcount == 10'd245 && vcount == 10'd270)
			pix_col <= black;				
		if(hcount == 10'd242 && vcount == 10'd271)
			pix_col <= black;
		if(hcount == 10'd245 && vcount == 10'd271)
			pix_col <= black;			
		if(hcount == 10'd241 && vcount == 10'd272)
			pix_col <= black;
		if(hcount == 10'd245 && vcount == 10'd272)
			pix_col <= black;
		if(hcount >= 10'd240 && hcount <= 10'd246 && vcount == 10'd273)
			pix_col <= black;

		if(hcount == 10'd245 && vcount == 10'd274)
			pix_col <= black;

		if(hcount == 10'd245 && vcount == 10'd275)
			pix_col <= black;
		if(hcount == 10'd245 && vcount == 10'd276)
			pix_col <= black;

//5
		if(hcount >= 10'd273 && hcount <= 10'd279 &&  vcount == 10'd268)
			pix_col <= black;		
		if(hcount == 10'd273 &&vcount == 10'd269)
			pix_col <= black;			
		if(hcount == 10'd273 && vcount == 10'd270)
			pix_col <= black;			
		if(hcount == 10'd273 && vcount == 10'd271)
			pix_col <= black;		
		if(hcount >= 10'd274 && hcount <= 10'd278 && vcount == 10'd272)
			pix_col <= black;
		if(hcount == 10'd279 && vcount == 10'd273)
			pix_col <= black;
		if(hcount == 10'd279 && vcount == 10'd274)
			pix_col <= black;
		if(hcount == 10'd273 && vcount == 10'd275)
			pix_col <= black;	
		if(hcount == 10'd279 && vcount == 10'd275)
			pix_col <= black;
		if(hcount >= 10'd274 && hcount <= 10'd278 && vcount == 10'd276)
			pix_col <= black;
//6
		if(hcount >= 10'd305 && hcount <= 10'd309 && vcount == 10'd268)
			pix_col <= black;		
		if(hcount == 10'd304 && vcount == 10'd269)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd269)
			pix_col <= black;
		if(hcount == 10'd304 && vcount == 10'd270)
			pix_col <= black;			
		if(hcount == 10'd304 && vcount == 10'd271)
			pix_col <= black;	
			
		if(hcount >= 10'd304 && hcount <= 10'd309 && vcount == 10'd272)
			pix_col <= black;
			
		if(hcount == 10'd304 && vcount == 10'd273)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd273)
			pix_col <= black;
		if(hcount == 10'd304 && vcount == 10'd274)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd274)
			pix_col <= black;
		if(hcount == 10'd304 && vcount == 10'd275)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd275)
			pix_col <= black;
		if(hcount >= 10'd305 && hcount <= 10'd309 && vcount == 10'd276)
			pix_col <= black;
//7
		if(hcount >= 10'd336 && hcount <= 10'd342 && vcount == 10'd268)
			pix_col <= black;		
		if(hcount == 10'd342 && vcount == 10'd269)
			pix_col <= black;
		
		if(hcount == 10'd341 && vcount == 10'd270)
			pix_col <= black;
		
			
		if(hcount == 10'd341 && vcount == 10'd271)
			pix_col <= black;			
		if(hcount == 10'd340 && vcount == 10'd272)
			pix_col <= black;

		if(hcount == 10'd339 && vcount == 10'd273)
			pix_col <= black;
			
		if(hcount == 10'd338 && vcount == 10'd274)
			pix_col <= black;

		if(hcount == 10'd338 && vcount == 10'd275)
			pix_col <= black;

		if(hcount == 10'd338 && vcount == 10'd276)
			pix_col <= black;	
//p
		if(hcount >= 10'd386 && hcount <= 10'd389 && vcount == 10'd269)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd270)
			pix_col <= black;	
		if(hcount == 10'd390 && vcount == 10'd270)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd271)
			pix_col <= black;	
		if(hcount == 10'd390 && vcount == 10'd271)
			pix_col <= black;
		if(hcount == 10'd386 && vcount == 10'd272)
			pix_col <= black;
		if(hcount == 10'd390 && vcount == 10'd272)
			pix_col <= black;
		if(hcount >= 10'd386 && hcount <= 10'd389 && vcount == 10'd273)
			pix_col <= black;
		if(hcount == 10'd386 && vcount == 10'd274)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd275)
			pix_col <= black;
		if(hcount == 10'd386 && vcount == 10'd276)
			pix_col <= black;		
			
			
//up
		if(hcount == 10'd420 && vcount == 10'd268)
			pix_col <= black;				
		if(hcount == 10'd419 && vcount == 10'd269)
			pix_col <= black;
		if(hcount == 10'd421 && vcount == 10'd269)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd270)
			pix_col <= black;
		if(hcount == 10'd421 && vcount == 10'd270)
			pix_col <= black;		
		if(hcount == 10'd418 && vcount == 10'd271)
			pix_col <= black;
		if(hcount == 10'd422 && vcount == 10'd271)
			pix_col <= black;
		if(hcount == 10'd418 && vcount == 10'd272)
			pix_col <= black;
		if(hcount == 10'd422 && vcount == 10'd272)
			pix_col <= black;
		if(hcount == 10'd417 && vcount == 10'd273)
			pix_col <= black;
		if(hcount == 10'd423 && vcount == 10'd273)
			pix_col <= black;
		if(hcount == 10'd417 && vcount == 10'd274)
			pix_col <= black;
		if(hcount == 10'd423 && vcount == 10'd274)
			pix_col <= black;
		if(hcount == 10'd416 && vcount == 10'd275)
			pix_col <= black;
		if(hcount == 10'd424 && vcount == 10'd275)
			pix_col <= black;
		if(hcount == 10'd416 && vcount == 10'd276)
			pix_col <= black;
		if(hcount == 10'd424 && vcount == 10'd276)
			pix_col <= black;
		
		
//0
		if(hcount >= 10'd242 && hcount <= 10'd246 && vcount == 10'd296)
			pix_col <= black;		
		if(hcount == 10'd241 && vcount == 10'd297)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd297)
			pix_col <= black;			
		if(hcount == 10'd241 && vcount == 10'd298)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd298)
			pix_col <= black;				
		if(hcount == 10'd241 && vcount == 10'd299)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd299)
			pix_col <= black;			
		if(hcount == 10'd241 && vcount == 10'd300)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd300)
			pix_col <= black;
		if(hcount == 10'd241 && vcount == 10'd301)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd301)
			pix_col <= black;
		if(hcount == 10'd241 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd241 && vcount == 10'd303)
			pix_col <= black;
		if(hcount == 10'd247 && vcount == 10'd303)
			pix_col <= black;
		if(hcount >= 10'd242 && hcount <= 10'd246 && vcount == 10'd304)
			pix_col <= black;

//1
		if(hcount == 10'd276 &&  vcount == 10'd296)
			pix_col <= black;		
		if(hcount >= 10'd275 && hcount <= 10'd276 &&vcount == 10'd297)
			pix_col <= black;			
		if(hcount == 10'd276 && vcount == 10'd298)
			pix_col <= black;			
		if(hcount == 10'd276 && vcount == 10'd299)
			pix_col <= black;		
		if(hcount == 10'd276 && vcount == 10'd300)
			pix_col <= black;
		if(hcount == 10'd276 && vcount == 10'd301)
			pix_col <= black;
		if(hcount == 10'd276 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd276 && vcount == 10'd303)
			pix_col <= black;
		if(hcount == 10'd276 && vcount == 10'd304)
			pix_col <= black;
			
//2
		if(hcount >= 10'd306 && hcount <= 10'd308 && vcount == 10'd296)
			pix_col <= black;		
		if(hcount == 10'd305 && vcount == 10'd297)
			pix_col <= black;
		if(hcount == 10'd309 && vcount == 10'd297)
			pix_col <= black;			
		if(hcount == 10'd304 && vcount == 10'd298)
			pix_col <= black;
		if(hcount == 10'd310 && vcount == 10'd298)
			pix_col <= black;			
		if(hcount == 10'd309 && vcount == 10'd299)
			pix_col <= black;			
		if(hcount == 10'd308 && vcount == 10'd300)
			pix_col <= black;
		if(hcount == 10'd307 && vcount == 10'd301)
			pix_col <= black;
		if(hcount == 10'd306 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd305 && vcount == 10'd303)
			pix_col <= black;
		if(hcount >= 10'd304 && hcount <= 10'd310 && vcount == 10'd304)
			pix_col <= black;
			
//3
		if(hcount >= 10'd338 && hcount <= 10'd340 && vcount == 10'd296)
			pix_col <= black;		
		if(hcount == 10'd337 && vcount == 10'd297)
			pix_col <= black;
		if(hcount == 10'd341 && vcount == 10'd297)
			pix_col <= black;			
		if(hcount == 10'd336 && vcount == 10'd298)
			pix_col <= black;
		if(hcount == 10'd342 && vcount == 10'd298)
			pix_col <= black;			
			
		if(hcount == 10'd342 && vcount == 10'd299)
			pix_col <= black;			
		if(hcount == 10'd341 && vcount == 10'd300)
			pix_col <= black;

		if(hcount == 10'd342 && vcount == 10'd301)
			pix_col <= black;
			
		if(hcount == 10'd336 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd342 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd337 && vcount == 10'd303)
			pix_col <= black;
		if(hcount == 10'd341 && vcount == 10'd303)
			pix_col <= black;
		if(hcount >= 10'd338 && hcount <= 10'd340 && vcount == 10'd304)
			pix_col <= black;
			
//s
		if(hcount >= 10'd387 && hcount <= 10'd389 && vcount == 10'd298)
			pix_col <= black;	
		if(hcount == 10'd386 && vcount == 10'd299)
			pix_col <= black;	
		if(hcount == 10'd390 && vcount == 10'd299)
			pix_col <= black;
		if(hcount == 10'd387 && vcount == 10'd300)
			pix_col <= black;
		if(hcount == 10'd388 && vcount == 10'd301)
			pix_col <= black;
		if(hcount == 10'd389 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd386 && vcount == 10'd303)
			pix_col <= black;	
		if(hcount == 10'd390 && vcount == 10'd303)
			pix_col <= black;
		if(hcount >= 10'd387 && hcount <= 10'd389 && vcount == 10'd304)
			pix_col <= black;	

//down
		if(hcount == 10'd416 && vcount == 10'd296)
			pix_col <= black;
		if(hcount == 10'd424 && vcount == 10'd296)
			pix_col <= black;
		if(hcount == 10'd416 && vcount == 10'd297)
			pix_col <= black;
		if(hcount == 10'd424 && vcount == 10'd297)
			pix_col <= black;
		if(hcount == 10'd417 && vcount == 10'd298)
			pix_col <= black;
		if(hcount == 10'd423 && vcount == 10'd298)
			pix_col <= black;
		if(hcount == 10'd417 && vcount == 10'd299)
			pix_col <= black;
		if(hcount == 10'd423 && vcount == 10'd299)
			pix_col <= black;
		if(hcount == 10'd418 && vcount == 10'd300)
			pix_col <= black;
		if(hcount == 10'd422 && vcount == 10'd300)
			pix_col <= black;
		if(hcount == 10'd418 && vcount == 10'd301)
			pix_col <= black;
		if(hcount == 10'd422 && vcount == 10'd301)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd421 && vcount == 10'd302)
			pix_col <= black;
		if(hcount == 10'd419 && vcount == 10'd303)
			pix_col <= black;
		if(hcount == 10'd421 && vcount == 10'd303)
			pix_col <= black;
		if(hcount == 10'd420 && vcount == 10'd304)
			pix_col <= black;	
			
// mouse buttons
		if(hcount >= 10'd318 && hcount <= 10'd322 && vcount >= 10'd38 && vcount <= 10'd42)
			pix_col <= mbtnR == 1'b0 ? red : lime;
		if(hcount >= 10'd312 && hcount <= 10'd316 && vcount >= 10'd38 && vcount <= 10'd42)
			pix_col <= mbtnM == 1'b0 ? red : blue;
		if(hcount >= 10'd306 && hcount <= 10'd310 && vcount >= 10'd38 && vcount <= 10'd42)
			pix_col <= mbtnL == 1'b0 ? red : yellow;	
// mouse 		
		if(hcount >= dot_x && hcount <= dot_x + 10'd4 && vcount >= dot_y && vcount <= dot_y + 10'd4)
			pix_col <= mbtnL == 1'b0 ? yellow : aqua; 
		
	end
end

reg [7:0] tmp;
always @(posedge clk, posedge rst) begin
	if(rst)
		tmp <= 8'b10000000;
	else begin
//		if (mbtnM == 1'b1)
//			mp <= my[9:0];
		if (mbtnL == 1'b1) begin
			
				
			// key value	
			if(mx >= 10'd408 && mx <= 10'd432 && my >= 10'd196 && my <= 10'd208)
				swrst <= 1'b1;
				
			if(mx >= 10'd232 && mx <= 10'd256 && my >= 10'd224 && my <= 10'd236)
				swc <= 1'b1;
			if(mx >= 10'd264 && mx <= 10'd288 && my >= 10'd224 && my <= 10'd236)
				swd <= 1'b1;
			if(mx >= 10'd296 && mx <= 10'd320 && my >= 10'd224 && my <= 10'd236)
				swe <= 1'b1;
			if(mx >= 10'd328 && mx <= 10'd352 && my >= 10'd224 && my <= 10'd236)
				swf <= 1'b1;
			if(mx >= 10'd376 && mx <= 10'd400 && my >= 10'd224 && my <= 10'd236)
				swm <= 1'b1;
			if(mx >= 10'd408 && mx <= 10'd432 && my >= 10'd224 && my <= 10'd236)
				swl <= 1'b1;
				
			if(mx >= 10'd232 && mx <= 10'd256 && my >= 10'd252 && my <= 10'd264)
				sw8 <= 1'b1;
			if(mx >= 10'd264 && mx <= 10'd288 && my >= 10'd252 && my <= 10'd264)
				sw9 <= 1'b1;
			if(mx >= 10'd296 && mx <= 10'd320 && my >= 10'd252 && my <= 10'd264)
				swa <= 1'b1;
			if(mx >= 10'd328 && mx <= 10'd352 && my >= 10'd252 && my <= 10'd264)
				swb <= 1'b1;
			if(mx >= 10'd376 && mx <= 10'd400 && my >= 10'd252 && my <= 10'd264)
				swg <= 1'b1;
			if(mx >= 10'd408 && mx <= 10'd432 && my >= 10'd252 && my <= 10'd264)
				swr <= 1'b1;
				
			if(mx >= 10'd232 && mx <= 10'd256 && my >= 10'd280 && my <= 10'd292)
				sw4 <= 1'b1;
			if(mx >= 10'd264 && mx <= 10'd288 && my >= 10'd280 && my <= 10'd292)
				sw5 <= 1'b1;
			if(mx >= 10'd296 && mx <= 10'd320 && my >= 10'd280 && my <= 10'd292)
				sw6 <= 1'b1;
			if(mx >= 10'd328 && mx <= 10'd352 && my >= 10'd280 && my <= 10'd292)
				sw7 <= 1'b1;
			if(mx >= 10'd376 && mx <= 10'd400 && my >= 10'd280 && my <= 10'd292)
				swp <= 1'b1;
			if(mx >= 10'd408 && mx <= 10'd432 && my >= 10'd280 && my <= 10'd292)
				swU <= 1'b1;
				
			if(mx >= 10'd232 && mx <= 10'd256 && my >= 10'd308 && my <= 10'd320)
				sw0 <= 1'b1;
			if(mx >= 10'd264 && mx <= 10'd288 && my >= 10'd308 && my <= 10'd320)
				sw1 <= 1'b1;
			if(mx >= 10'd296 && mx <= 10'd320 && my >= 10'd308 && my <= 10'd320)
				sw2 <= 1'b1;
			if(mx >= 10'd328 && mx <= 10'd352 && my >= 10'd308 && my <= 10'd320)
				sw3 <= 1'b1;
			if(mx >= 10'd376 && mx <= 10'd400 && my >= 10'd308 && my <= 10'd320)
				sws <= 1'b1;
			if(mx >= 10'd408 && mx <= 10'd432 && my >= 10'd308 && my <= 10'd320)
				swD <= 1'b1;	
				
				
				
		end else begin
			swrst <= 1'b0;
			swc <= 1'b0;
			swd <= 1'b0;
			swe <= 1'b0;
			swf <= 1'b0;
			swm <= 1'b0;
			swl <= 1'b0;
			sw8 <= 1'b0;
			sw9 <= 1'b0;
			swa <= 1'b0;
			swb <= 1'b0;
			swg <= 1'b0;
			swr <= 1'b0;
			sw4 <= 1'b0;
			sw5 <= 1'b0;
			sw6 <= 1'b0;
			sw7 <= 1'b0;
			swp <= 1'b0;
			swU <= 1'b0;
			sw0 <= 1'b0;
			sw1 <= 1'b0;
			sw2 <= 1'b0;
			sw3 <= 1'b0;
			sws <= 1'b0;
			swD <= 1'b0;
		end
		

	end
end

// Take no notice - I change the values to suit
// without ghanging the name
//
// 24 bit colour

wire [23:0] black 	= 24'h000000;
//wire [23:0] maroon 	= 24'hC00000;
wire [23:0] green 	= 24'h004000;
wire [23:0] olive 	= 24'h808000;
//wire [23:0] navy 		= 24'h000080;
//wire [23:0] purple 	= 24'h800080;
wire [23:0] teal 		= 24'h008080;
wire [23:0] silver 	= 24'hC0C0C0;
wire [23:0] grey 		= 24'h808080;
wire [23:0] red 		= 24'hFF0000;
wire [23:0] lime 		= 24'h00FF00;
wire [23:0] yellow 	= 24'hFFFF00;
wire [23:0] blue 		= 24'h0000FF;
//wire [23:0] fuchsia 	= 24'hFF00FF;
wire [23:0] aqua 		= 24'h00FFFF;
wire [23:0] white 	= 24'hFFFFFF;

endmodule


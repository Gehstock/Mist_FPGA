`timescale 1ns / 100ps

// Dave Wood (oldgit) 2019 code taken from muliple sources
// thanks to the original designers. I just glue bits together.

/*
 * PS2 mouse protocol
 * Bit       7    6    5    4    3    2    1    0  
 * Byte 0: YOVR XOVR YSGN XSGN   1   MBUT RBUT LBUT
 * Byte 1:                 XMOVE
 * Byte 2:                 YMOVE
 */

/*
 * simple PS2 Mouse interface module
 * starts with mouse pos(0,0) and keeps mouse location and updates. output is mouse pos(0--636/0--476) ! pos less 4 pixels for size
 * mouse buttons 0 by default and 1 when pressed
 */
module ps2_mouse
(
	input	clk,
	input	ce,

	input	reset,

	input [24:0] ps2_mouse,

	output reg [10:0] mx, my,
	output reg mbtnL,
	output reg mbtnR,
	output reg mbtnM
);

wire strobe = (old_stb != ps2_mouse[24]);
reg  old_stb = 0;
always @(posedge clk) old_stb <= ps2_mouse[24];

/* Capture buttons state */
always@(posedge clk or posedge reset) begin
	if (reset) begin
		mbtnL <= 1'b0;
		mbtnR <= 1'b0;
		mbtnM <= 1'b0;
	end else if (strobe) begin
		mbtnL <= ps2_mouse[0];
		mbtnR <= ps2_mouse[1];
		mbtnM <= ps2_mouse[2];
	end
end
   // module parameters
   parameter 	 MAX_X = 635;
   parameter 	 MAX_Y = 475;
   
   // low level mouse driver
   
   wire [8:0] 	 dx, dy;
	
   // Update "absolute" position of mouse
   
   wire        sx = ps2_mouse[4];		// signs
   wire        sy = ps2_mouse[5];		
   wire [8:0]  ndx = sx ? {1'b0,~ps2_mouse[15:8]}+9'b000000001 : {1'b0,ps2_mouse[15:8]};	// magnitudes
   wire [8:0]  ndy = sy ? {1'b0,~ps2_mouse[23:16]}+9'b000000001 : {1'b0,ps2_mouse[23:16]};
   
   always @(posedge clk) begin
      mx <= reset ? 0 :
	    strobe ? (sx ? (mx>ndx ? mx - ndx : 0) 
			  : (mx < MAX_X - ndx ? mx+ndx : MAX_X)) : mx;
      // note Y is flipped for video cursor use of mouse
      my <= reset ? 0 :
	    strobe ? (sy ? (my < MAX_Y - ndy ? my+ndy : MAX_Y)
			  : (my>ndy ? my - ndy : 0))  : my;
//	    strobe ? (sy ? (my>ndy ? my - ndy : 0) 
//			  : (my < MAX_Y - ndy ? my+ndy : MAX_Y)) : my;
   end


endmodule

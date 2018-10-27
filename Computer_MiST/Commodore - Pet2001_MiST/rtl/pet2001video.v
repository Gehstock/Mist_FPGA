`timescale 1ns / 1ps

module pet2001video
(
	output         pix,
	output reg     HSync,
	output reg     VSync,

	output [10:0]  video_addr,	// Video RAM intf
	input  [7:0]   video_data,

	output [10:0]  charaddr,	// char rom intf
	input  [7:0]   chardata,
	output         video_on,	// control sigs
	input          video_blank,
	input          video_gfx,
	input          clk,
	input          ce_7mp,
	input          ce_7mn
);

assign video_on   = (vc < 200);
assign video_addr = {vc[8:3], 5'b00000}+{vc[8:3], 3'b000}+hc[8:3];
assign charaddr   = {video_gfx, video_data[6:0], vc[2:0]};

reg  [8:0] hc;
reg  [8:0] vc;

always @(posedge clk) begin
	if(ce_7mp) begin
		hc <= hc + 1'd1;
		if(hc == 447) begin 
			hc <=0;
			vc <= vc + 1'd1;
			if(vc == 261) vc <= 0;
		end
	end

	if(ce_7mn) begin
		if(hc == 358) HSync <= 1;
		if(hc == 391) HSync <= 0;
		if(vc == 225) VSync <= 1;
		if(vc == 234) VSync <= 0;
	end
end

reg [7:0] vdata;
reg       inv;
assign    pix = (vdata[7] ^ inv) & ~video_blank;

always @(posedge clk) begin
	if(ce_7mn) begin
		if(!hc[2:0]) {inv, vdata} <= ((hc<320) && (vc<200)) ? {video_data[7], chardata} : 9'd0;
			else vdata <= {vdata[6:0], 1'b0};
	end
end


endmodule // pet2001video


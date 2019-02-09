`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:27:35 02/19/2008 
// Design Name: 
// Module Name:    vga 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga(
	input 			CLK_50MHZ,
	input 	[1:0] color,
	input 			RD_n,
	input 			WR_n,
	output 	[1:0] VGA_RED, 
	output 	[1:0] VGA_GREEN, 
	output 	[1:0] VGA_BLUE, 
	output 			VGA_HSYNC, 
	output 			VGA_VSYNC,
	output 			VGA_VBLANK,
	output [11:0] 	VGA_ADDR,
	input  [7:0] 	VGA_DATA,
	output 			BUS_REQ,
	input 			BUS_ACK
	);
	
	reg [9:0] x = 0;
	reg [9:0] y = 0;
	reg [1:0] counter = 0;
	wire display;
	wire [9:0] gx, gy;      //(0,0)-(639,399)

	always @(posedge CLK_50MHZ) begin
		counter <= counter + 1;
	end
	assign gx = x - 144;      // (96+48) sync pulse + back porch
	assign gy = y - 71;  // (2+29+40)
	always @(posedge counter[0]) begin
		if ( x < 800 )
		begin
			x <= x + 1;
		end else begin
			x <= 0;
			if ( y < 521 )
				y <= y + 1;
			else
				y <= 0;
		end
	end
// CGROM
	wire [7:0] cgrom_data;
	wire [11:0] cgrom_addr;

	cg_rom cg_rom(
		.address(cgrom_addr), 
		.clock(CLK_50MHZ), 
		.q(cgrom_data), 
		.clken(1'b1)
		);

wire [1:0] R, G, B;
	Color_Card Color_Card(
		.CLK(CLK_50MHZ),
		.CSX_n(),
		.WR_n(WR_n),
		.CSD_n(),
		.Sync(),
		.RD_n(RD_n),
		.Video(video),
		.Din(VGA_DATA),
		.Dout(),
		.Addr(VGA_ADDR[11:0]),
		.CSDo(),
		.Synco_n(),
		.R(R),
		.G(G),
		.B(B)
);

	wire [5:0] cx, cy;      //(0,0)-(79,24)
	assign cx = gx >> 4;
	assign cy = gy >> 4;
	assign VGA_ADDR = (cy * 40) + cx;
	assign cgrom_addr = {VGA_DATA, gy[3:1]}; 
	wire video = display & (y[0] & 1) ? cgrom_data[7-(((gx+15)>>1) & 7)] : 0;
//	assign BUS_REQ = ( (96+48-8) <= x & x < (96+48+640) ) & ( ( 2+29+40) <= y & y < (2+29+40+400));
	assign BUS_REQ = ( (96+48-16) <= x & x < (96+48+640) ) & ( ( 2+29+40) <= y & y < (2+29+40+400));
	assign display =( (96+48) <= x & x < (96+48+640) ) & ( ( 2+29+40) <= y & y < (2+29+40+400));
	
	assign VGA_RED   = color[1] ? R : color[0] ? 2'b00 : {video,video};
	assign VGA_GREEN = color[1] ? G : {video,video};
	assign VGA_BLUE  = color[1] ? B : color[0] ? 2'b00 : {video,video};
	
	assign VGA_HSYNC = x < 96 ? 0 : 1;
	assign VGA_VSYNC = y < 2  ? 0 : 1;
	assign VGA_VBLANK = (x == 639 & y == 499) ? 1 : 0;
endmodule

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
module vga(CLK_50MHZ, VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC, Pix_ce,
				VGA_ADDR, VGA_DATA, BUS_REQ, BUS_ACK);
	input CLK_50MHZ;
	output VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC;
	output Pix_ce;
	output [11:0] VGA_ADDR;
	input [7:0] VGA_DATA;
	output BUS_REQ;
	input BUS_ACK;
	reg [9:0] x = 0;
	reg [9:0] y = 0;
	reg [1:0] counter = 0;
	wire display;
	wire [9:0] gx, gy;      // �O���t�B�b�N��W(0,0)-(639,399)

	always @(posedge CLK_50MHZ) begin
		counter <= counter + 1;
	end
	assign Pix_ce = counter[0];
	assign gx = x - 144;      // (96+48)
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
// CGROM�̎��
	wire [7:0] cgrom_data;
	wire [11:0] cgrom_addr;
cgrom cgrom(.address(cgrom_addr), .clock(CLK_50MHZ), .q(cgrom_data), .rden(1'b1));
	wire [5:0] cx, cy;      // �L�����N�^�[��W�֕ϊ�(0,0)-(79,24)
	assign cx = gx >> 4;     // �P�U�Ŋ���
	assign cy = gy >> 4;     // �P�U�Ŋ���
	assign VGA_ADDR = (cy * 40) + cx;
	assign cgrom_addr = {VGA_DATA, gy[3:1]}; 

//	assign BUS_REQ = ( (96+48-8) <= x & x < (96+48+640) ) & ( ( 2+29+40) <= y & y < (2+29+40+400));
	assign BUS_REQ = ( (96+48-16) <= x & x < (96+48+640) ) & ( ( 2+29+40) <= y & y < (2+29+40+400));
	assign display =( (96+48) <= x & x < (96+48+640) ) & ( ( 2+29+40) <= y & y < (2+29+40+400));
	assign VGA_RED   = 0; //display ? (cgrom_data[7-((gx>>1) & 7)]) : 0;
	assign VGA_GREEN = display & (y[0] & 1) ? cgrom_data[7-(((gx+15)>>1) & 7)] : 0;
	assign VGA_BLUE  = 0; //display ? (cgrom_data[7-((gx>>1) & 7)]) : 0;
	assign VGA_HSYNC = x < 96 ? 0 : 1;
	assign VGA_VSYNC = y < 2  ? 0 : 1;
endmodule

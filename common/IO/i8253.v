`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:58:45 02/25/2008 
// Design Name: 
// Module Name:    i8253 
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
module i8253(reset, clk, addr, data_out, data_in, cs, rd, wr, clk0, clk1, clk2, out0, out1, out2);
	input			reset;
	input			clk;
	input	[1:0]	addr;
	output[7:0]	data_out;
	input	[7:0]	data_in;
	input			cs, rd, wr;
	input			clk0, clk1, clk2;
	output		out0, out1, out2;
	wire	[1:0]	addr;
	wire	[7:0]	data_out, data_in;
	wire			cs, rd, wr;
	wire			clk0, clk1, clk2;
	wire			out0, out1, out2;
	
	reg	[7:0]		mode0, mode1, mode2;
	reg	[15:0]	max0, max1, max2;
	reg	[15:0]	count0 = 0, count1 = 0, count2 = 0;
	reg				signal0 = 0, signal1 = 0, signal2 = 0;
	reg				read_hl0, read_hl1, read_hl2;
	reg				write_hl0, write_hl1, write_hl2;
	reg	[7:0]		data;
	
	always @(posedge clk or posedge reset) begin
		if ( reset ) begin
			mode0 <= 8'h00;
			mode1 <= 8'h00;
			mode2 <= 8'h00;
			max0 <= 16'd1;
			max1 <= 16'd1;
			max2 <= 16'd1;
			write_hl0 <= 1'b0;
			write_hl1 <= 1'b0;
			write_hl2 <= 1'b0;
			read_hl0 <= 1'b0;
			read_hl1 <= 1'b0;
			read_hl2 <= 1'b0;
		end else if ( cs ) begin
			if ( addr == 2'd0 & wr ) begin
				write_hl0 <= ( mode0[5:4] == 2'b00 | mode0[5:4] == 2'b11 ) ? ~write_hl0: write_hl0;
				if ( ((mode0[5:4] == 2'b00 | mode0[5:4] == 2'b11) & write_hl0) | mode0[5:4] == 2'b10 )
					max0[15:8] <= data_in;
				else
					max0[7:0] <= data_in;
			end else if ( addr == 2'd1 & wr ) begin
				write_hl1 <= ( mode1[5:4] == 2'b00 | mode1[5:4] == 2'b11 ) ? ~write_hl1: write_hl1;
				if ( ((mode1[5:4] == 2'b00 | mode1[5:4] == 2'b11) & write_hl1) | mode1[5:4] == 2'b10 )
					max1[15:8] <= data_in;
				else
					max1[7:0] <= data_in;
			end else if ( addr == 2'd2 & wr ) begin
				write_hl2 <= ( mode2[5:4] == 2'b00 | mode2[5:4] == 2'b11 ) ? ~write_hl2: write_hl2;
				if ( ((mode2[5:4] == 2'b00 | mode2[5:4] == 2'b11) & write_hl2) | mode2[5:4] == 2'b10 )
					max2[15:8] <= data_in;
				else
					max2[7:0] <= data_in;
			end else if ( addr == 2'd3 & wr ) begin
				if ( data_in[7:6] == 2'd0 ) begin
					mode0 <= data_in;
					read_hl0 <= data_in[5:4] == 2'b10 ? 1 : 0;
					write_hl0 <= data_in[5:4] == 2'b10 ? 1 : 0;
				end else if ( data_in[7:6] == 2'd1 ) begin
					mode1 <= data_in;
					read_hl1 <= data_in[5:4] == 2'b10 ? 1 : 0;
					write_hl1 <= data_in[5:4] == 2'b10 ? 1 : 0;
				end else if ( data_in[7:6] == 2'd2 ) begin
					mode2 <= data_in;
					read_hl2 <= data_in[5:4] == 2'b10 ? 1 : 0;
					write_hl2 <= data_in[5:4] == 2'b10 ? 1 : 0;
				end
			end else if ( addr == 2'd0 & rd ) begin
				read_hl0 <= ( mode0[5:4] == 2'b00 | mode0[5:4] == 2'b11 ) ? ~read_hl0: read_hl0;
				data <= ~( ((mode0[5:4] == 2'b00 | mode0[5:4] == 2'b11 ) & read_hl0) | mode0[5:4] == 2'b10 ) ? count0[15:8] : count0[7:0];
			end else if ( addr == 2'd1 & rd ) begin
				read_hl1 <= ( mode1[5:4] == 2'b00 | mode1[5:4] == 2'b11 ) ? ~read_hl1: read_hl1;
				data <= ~( ((mode1[5:4] == 2'b00 | mode1[5:4] == 2'b11 ) & read_hl1) | mode1[5:4] == 2'b10 ) ? count1[15:8] : count1[7:0];
			end else if ( addr == 2'd2 & rd ) begin
				read_hl2 <= ( mode2[5:4] == 2'b00 | mode2[5:4] == 2'b11 ) ? ~read_hl2: read_hl2;
				data <= ~( ((mode2[5:4] == 2'b00 | mode2[5:4] == 2'b11 ) & read_hl2) | mode2[5:4] == 2'b10 ) ? count2[15:8] : count2[7:0];
			end
		end
	end
	
	always @(posedge clk0) begin
		if ( count0 != 0 ) begin
			count0 <= ( count0 <= max0 ) ? count0 - 1: max0;
			if ( mode0[3:1] == 3'b000 | mode0[3:1] == 3'b001 )		// MODE0
				signal0 <= 0;
		end else begin
			if ( mode0[3:1] == 3'b000 | mode0[3:1] == 3'b001 ) begin		// MODE0
				count0 <= max0;
				signal0 <= 1;
			end else begin
				count0 <= max0;
				signal0 <= ~signal0;
			end
		end
	end

	always @(posedge clk1) begin
		if ( count1 != 0 ) begin
			count1 <= ( count1 <= max1 ) ? count1 - 1: max1;
			if ( mode1[3:1] == 3'b000 | mode1[3:1] == 3'b001 )		// MODE0/1
				signal1 <= 0;
		end else begin
			if ( mode1[3:1] == 3'b000 | mode1[3:1] == 3'b001 ) begin		// MODE0/1
				count1 <= max1;
				signal1 <= 1;
			end else begin
				count1 <= max1;
				signal1 <= ~signal1;
			end
		end
	end

	always @(posedge clk2) begin
		if ( count2 != 0 ) begin
			count2 <= ( count2 <= max2 ) ? count2 - 1: max2;
			if ( mode2[3:1] == 3'b000 | mode2[3:1] == 3'b001 )		// MODE0/1
				signal2 <= 0;
		end else begin
			if ( mode2[3:1] == 3'b000 | mode2[3:1] == 3'b001 ) begin		// MODE0/1
				count2 <= max2;
				signal2 <= 1;
			end else begin
				count2 <= max2;
				signal2 <= ~signal2;
			end
		end
	end

	assign	out0 = signal0;
	assign	out1 = signal1;
	assign	out2 = signal2;

	assign	data_out = data;

endmodule

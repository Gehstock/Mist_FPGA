// ====================================================================
//                Bashkiria-2M FPGA REPLICA
//
//            Copyright (C) 2010 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Bashkiria-2M home computer
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
//
// Modified for SDRAM version: Ivan Gorodetsky
// 
// Design File: b2m_video.v
//
// Video subsystem design file of Bashkiria-2M replica.

module b2m_video(
	input clk50mhz,
	output reg hr,
	output reg vr,
	output reg vid_irq,
	output reg[3:0] r,
	output reg[3:0] g,
	output reg[3:0] b,
	output reg drq,
	output reg[13:0] addr,
	input[15:0] idata,
	input[1:0] pal_idx,
	input[7:0] pal_data,
	input pal_we_n,
	input color_mode,
	input mode,
	output clk100,
	output reg vidce
	);

reg[7:0] palette[0:3];
reg[7:0] pclr;
reg vout;

always @(*)
	casex ({vout,color_mode})
	2'b0x: {r,g,b} = {4'b0000,4'b0000,4'b0000};
	2'b10: {r,g,b} = {{2{pclr[1:0]}},{2{pclr[1:0]}},{2{pclr[1:0]}}};
	2'b11: {r,g,b} = {{2{pclr[3:2]}},{2{pclr[5:4]}},{2{pclr[7:6]}}};
	endcase

// mode select

always @(*)
	case (mode)
	1'b0: begin
		pclr = ~palette[{data0[8],data0[0]}];
		hr = h_cnt0 >= 10'd425 & h_cnt0 < 10'd485 ? 1'b1 : 1'b0;
		vr = v_cnt0 >= 10'd555 & v_cnt0 < 10'd561 ? 1'b1 : 1'b0;
		vout = h_cnt0 >= 10'd5 && h_cnt0 < 10'd389 && v_cnt0 < 10'd512;
		addr = addr0;
		drq = drq0;
		vid_irq = irq0;
		vidce=h_cnt0[2]==0;
	end
	1'b1: begin
		pclr = ~palette[{data1[8],data1[0]}];
//		hr = h_cnt1 >= 10'd425 & h_cnt1 < 10'd485 ? 1'b1 : 1'b0;//b2m
		hr = h_cnt1 >= 10'd400 & h_cnt1 < 10'd460 ? 1'b1 : 1'b0;
		vr = v_cnt1 >= 10'd575 & v_cnt1 < 10'd581 ? 1'b1 : 1'b0;
		vout = h_cnt1 >= 10'd5 && h_cnt1 < 10'd389 && v_cnt1 < 10'd512;
		addr = addr1;
		drq = drq1;
		vid_irq = irq1;
		vidce=h_cnt1[2]==0;
	end
	endcase

// mode 0, 800x600@50Hz

reg[9:0] h_cnt0;
reg[9:0] v_cnt0;
reg[15:0] data0;
reg[13:0] addr0;
reg drq0;
reg irq0;

always @(posedge clk16)
begin
	if (h_cnt0[2:0]==3'b100 && h_cnt0[8:3]<6'h30) data0 <= idata; else data0 <= {1'b0,data0[15:1]};
	if (h_cnt0+1'b1 == 10'd528) begin
		h_cnt0 <= 0;
		if (v_cnt0+1'b1 == 10'd628 )
			v_cnt0 <= 0;
		else
			v_cnt0 <= v_cnt0+1'b1;
	end else
		h_cnt0 <= h_cnt0+1'b1;
end

always @(posedge clk50mhz)
begin
	if (!pal_we_n) palette[pal_idx] <= pal_data;
	addr0 <= {h_cnt0[8:3], v_cnt0[8:1]};
	drq0 <= h_cnt0[8:7] < 2'b11 && v_cnt0[9]==0 && h_cnt0[2]==0;
	irq0 <= ~v_cnt0[9];
	addr1 <= {h_cnt1[8:3], v_cnt1[8:1]};
	drq1 <= h_cnt1[8:7] < 2'b11 && v_cnt1[9]==0 && h_cnt1[2]==0;
	irq1 <= ~v_cnt1[9];
end

// mode 1, 800x600@60Hz

wire clk20,clk16;

clk20mhz u1(
	.inclk0(clk50mhz), 
	.c0(clk20),
	.c1(clk100),
	.c2(clk16)
	);

reg[9:0] h_cnt1;
reg[9:0] v_cnt1;
reg[15:0] data1;
reg[13:0] addr1;
reg drq1;
reg irq1;

always @(posedge clk20)
begin
	if (h_cnt1[2:0]==3'b100 && h_cnt1[8:3]<6'h30) data1 <= idata; else data1 <= {1'b0,data1[15:1]};
	if (h_cnt1+1'b1 == 10'd528) begin
		h_cnt1 <= 0;
		if (v_cnt1+1'b1 == 10'd628 )
			v_cnt1 <= 0;
		else
			v_cnt1 <= v_cnt1+1'b1;
	end else
		h_cnt1 <= h_cnt1+1'b1;
end

endmodule

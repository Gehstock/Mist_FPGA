//============================================================================
// 
//  Gyruss top-level module
//  Copyright (C) 2021 Ace
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

//Module declaration, I/O ports
module Gyruss
(
	input                reset,
	input                clk_49m,                  //Actual frequency: 49.152MHz
	input          [1:0] coin,                     //0 = coin 1, 1 = coin 2
	input          [1:0] start_buttons,            //0 = Player 1, 1 = Player 2
	input          [3:0] p1_joystick, p2_joystick, //0 = up, 1 = down, 2 = left, 3 = right
	input                p1_fire,
	input                p2_fire,
	input                btn_service,
	input         [23:0] dip_sw,
	output               video_hsync, video_vsync, video_csync,
	output               video_hblank, video_vblank,
	output               ce_pix,
	output         [2:0] video_r, video_g,
	output         [1:0] video_b,
	output signed [15:0] sound_l, sound_r,
	
	//Screen centering (alters HSync, VSync and VBlank timing in the Konami 082 to reposition the video output)
	input          [3:0] h_center, v_center,
	
	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,
	
	input                pause,

	input         [10:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write,
	input                hs_access,

	output        [15:0] main_cpu_rom_addr,
	input          [7:0] main_cpu_rom_do,
	output        [12:0] sub_cpu_rom_addr,
	input          [7:0] sub_cpu_rom_do,
	output        [12:0] sp_rom_addr,
	input         [31:0] sp_rom_do
);

//Linking signals between PCBs
wire A5, A6, irq_trigger, cs_sounddata, cs_controls_dip1, cs_dip2, cs_dip3;
wire [7:0] controls_dip, cpubrd_D;

//ROM loader signals for MISTer (loads ROMs from SD card)
wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i, ep6_cs_i, ep7_cs_i, ep8_cs_i, ep9_cs_i,
     ep10_cs_i, ep11_cs_i, ep12_cs_i;
wire cp_cs_i, tl_cs_i, sl_cs_i;

//MiSTer data write selector
selector DLSEL
(
	.ioctl_addr(ioctl_addr),
	.ep1_cs(ep1_cs_i),
	.ep2_cs(ep2_cs_i),
	.ep3_cs(ep3_cs_i),
	.ep4_cs(ep4_cs_i),
	.ep5_cs(ep5_cs_i),
	.ep6_cs(ep6_cs_i),
	.ep7_cs(ep7_cs_i),
	.ep8_cs(ep8_cs_i),
	.ep9_cs(ep9_cs_i),
	.ep10_cs(ep10_cs_i),
	.ep11_cs(ep11_cs_i),
	.ep12_cs(ep12_cs_i),
	.cp_cs(cp_cs_i),
	.tl_cs(tl_cs_i),
	.sl_cs(sl_cs_i)
);

//Instantiate main PCB
Gyruss_CPU main_pcb
(
	.reset(reset),
	.clk_49m(clk_49m),
	.red(video_r),
	.green(video_g),
	.blue(video_b),
	.video_hsync(video_hsync),
	.video_vsync(video_vsync),
	.video_csync(video_csync),
	.video_hblank(video_hblank),
	.video_vblank(video_vblank),
	.ce_pix(ce_pix),
	
	.h_center(h_center),
	.v_center(v_center),
	
	.controls_dip(controls_dip),
	.cpubrd_Dout(cpubrd_D),
	.cpubrd_A5(A5),
	.cpubrd_A6(A6),
	.cs_sounddata(cs_sounddata),
	.irq_trigger(irq_trigger),
	.cs_dip2(cs_dip2),
	.cs_dip3(cs_dip3),
	.cs_controls_dip1(cs_controls_dip1),
	
	.ep1_cs_i(ep1_cs_i),
	.ep2_cs_i(ep2_cs_i),
	.ep3_cs_i(ep3_cs_i),
	.ep4_cs_i(ep4_cs_i),
	.ep5_cs_i(ep5_cs_i),
	.ep6_cs_i(ep6_cs_i),
	.ep7_cs_i(ep7_cs_i),
	.ep8_cs_i(ep8_cs_i),
	.ep9_cs_i(ep9_cs_i),
	.cp_cs_i(cp_cs_i),
	.tl_cs_i(tl_cs_i),
	.sl_cs_i(sl_cs_i),
	.ioctl_addr(ioctl_addr),
	.ioctl_wr(ioctl_wr),
	.ioctl_data(ioctl_data),

	.pause(pause),

	.hs_address(hs_address),
	.hs_data_in(hs_data_in),
	.hs_data_out(hs_data_out),
	.hs_write(hs_write),
	.hs_access(hs_access),

	.main_cpu_rom_addr(main_cpu_rom_addr),
	.main_cpu_rom_do(main_cpu_rom_do),
	.sub_cpu_rom_addr(sub_cpu_rom_addr),
	.sub_cpu_rom_do(sub_cpu_rom_do),
	.sp_rom_addr(sp_rom_addr),
	.sp_rom_do(sp_rom_do)
);

//Instantiate sound PCB
Gyruss_SND sound_pcb
(
	.reset(reset),
	.clk_49m(clk_49m),
	.irq_trigger(irq_trigger),
	.cs_sounddata(cs_sounddata),
	.dip_sw(dip_sw),
	.coin(coin),
	.start_buttons(start_buttons),
	.p1_joystick(p1_joystick),
	.p2_joystick(p2_joystick),
	.p1_fire(p1_fire),
	.p2_fire(p2_fire),
	.btn_service(btn_service),
	
	.cs_controls_dip1(cs_controls_dip1),
	.cs_dip2(cs_dip2),
	.cs_dip3(cs_dip3),
	.cpubrd_A5(A5),
	.cpubrd_A6(A6),
	.cpubrd_Din(cpubrd_D),	
	.controls_dip(controls_dip),
	.sound_l(sound_l),
	.sound_r(sound_r),
	
	.ep10_cs_i(ep10_cs_i),
	.ep11_cs_i(ep11_cs_i),
	.ep12_cs_i(ep12_cs_i),
	.ioctl_addr(ioctl_addr),
	.ioctl_wr(ioctl_wr),
	.ioctl_data(ioctl_data)
);

endmodule

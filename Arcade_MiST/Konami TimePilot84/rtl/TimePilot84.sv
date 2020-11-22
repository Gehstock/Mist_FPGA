//============================================================================
// 
//  Time Pilot '84 top-level module
//  Copyright (C) 2020 Ace
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
module TimePilot84
(
	input                reset,
	input                clk_49m, clk_14m,         //Actual clocks: 49.152MHz, 14.31818MHz
	input          [1:0] coin,                     //0 = coin 1, 1 = coin 2
	input          [1:0] start_buttons,            //0 = Player 1, 1 = Player 2
	input          [3:0] p1_joystick, p2_joystick, //0 = up, 1 = down, 2 = left, 3 = right
	input          [2:0] p1_buttons,               //0 = shot, 1 = missile, 2 = spare
	input          [1:0] p2_buttons,               //0 = shot, 1 = missile
	input                btn_service,
	input         [15:0] dip_sw,
	output               video_hsync, video_vsync, video_csync,
	output               video_hblank, video_vblank,
	output         [3:0] video_r, video_g, video_b,
	output signed [15:0] sound,
	
	input                is_set3, //Flag to remap primary CPU address space for Time Pilot '84 (Set 3)
	output 		  [15:0] main_cpu_rom_addr,
	input   			[7:0] main_cpu_rom_do,
	output 		  [12:0] sub_cpu_rom_addr,
	input   			[7:0] sub_cpu_rom_do,
	output 		  [12:0] sp_rom_addr,
	input   		  [31:0] sp_rom_do
);

//Linking signals between PCBs
wire A5, A6, sound_on, sound_data, ioen, in5, in6;
wire [7:0] cpubrd_Dout, sndbrd_Dout;

//Instantiate main PCB
TimePilot84_CPU main_pcb(
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
	.sndbrd_D(sndbrd_Dout),
	.cpubrd_D(cpubrd_Dout),
	.cpubrd_A5(A5),
	.cpubrd_A6(A6),
	.n_sda(sound_data),
	.n_son(sound_on),
	.in5(in5),
	.ioen(ioen),
	.is_set3(is_set3),
	.main_cpu_rom_addr(main_cpu_rom_addr),
	.main_cpu_rom_do(main_cpu_rom_do),
	.sub_cpu_rom_addr(sub_cpu_rom_addr),
	.sub_cpu_rom_do(sub_cpu_rom_do),
	.sp_rom_addr(sp_rom_addr),
	.sp_rom_do(sp_rom_do)
);

//Instantiate sound PCB
TimePilot84_SND sound_pcb(
	.reset(reset),
	.clk_49m(clk_49m),
	.clk_14m(clk_14m),
	.sound_on(sound_on),
	.sound_data(sound_data),
	.dip_sw(dip_sw),
	.coin(coin),
	.start_buttons(start_buttons),
	.p1_joystick(p1_joystick),
	.p2_joystick(p2_joystick),
	.p1_buttons(p1_buttons),
	.p2_buttons(p2_buttons),
	.btn_service(btn_service),
	.ioen(ioen),
	.in5(in5),
	.cpubrd_A5(A5),
	.cpubrd_A6(A6),
	.cpubrd_Din(cpubrd_Dout),	
	.sndbrd_Dout(sndbrd_Dout),
	.sound(sound)
);

endmodule

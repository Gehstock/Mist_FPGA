//============================================================================
// 
//  Tutankham top-level module
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
module Tutankham_TOP
(
	input                reset,
	input                clk_49m,                  //Actual frequency: 49.152MHz
	input          [1:0] coin,                     //0 = coin 1, 1 = coin 2
	input          [1:0] start_buttons,            //0 = Player 1, 1 = Player 2
	input          [3:0] p1_joystick, p2_joystick, //0 = up, 1 = down, 2 = left, 3 = right
	input                p1_fire,
	input                p2_fire,
	input                m_fire1_l, m_fire1_r, m_flash1, // P1: fire left, fire right, flash bomb
	input                m_fire2_l, m_fire2_r, m_flash2, // P2: fire left, fire right, flash bomb
	input                btn_service,
	input         [15:0] dip_sw,
	output               video_hsync, video_vsync, video_csync,
	output               video_hblank, video_vblank,
	output               ce_pix,
	output         [4:0] video_r, video_g, video_b,
	output signed [15:0] sound,
	
	//Screen centering (alters HSync, VSync and VBlank timing in the Konami 082 to reposition the video output)
	input          [3:0] h_center, v_center,
	
	output		  [15:0] cpu_A,	
	input				[7:0] mainrom_D,
//	input				[7:0] bank_rom_D,
	output	  	  [15:0] sound_A,//13bit used
	input				[7:0] eprom7_D,
	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,
	input          [7:0] ioctl_index,
	
	input                pause,
	
	//This input serves to select different fractional dividers to acheive 1.789772MHz for the sound Z80 and AY-3-8910s
	//depending on whether Time Pilot runs with original or underclocked timings to normalize sync frequencies
	input                underclock,

	input         [15:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write
);

//Linking signals between PCBs
wire /*A5, A6,*/ irq_trigger, cs_sounddata, cs_controls_dip1, cs_dip2;
wire [7:0] controls_dip, cpubrd_D;

//Index-filtered ROM write signals
wire ioctl_wr_cpu = ioctl_wr && (ioctl_index == 8'd0); // Main CPU board (index 0)
wire ioctl_wr_snd = ioctl_wr && (ioctl_index == 8'd1); // Sound board (index 1)

//ROM loader signals for MISTer (loads ROMs from SD card)
wire rom_m1_cs_i, rom_m2_cs_i, rom_m3_cs_i, rom_m4_cs_i, rom_m5_cs_i, rom_m6_cs_i;
wire bank0_cs_i, bank1_cs_i, bank2_cs_i, bank3_cs_i, bank4_cs_i;
wire bank5_cs_i, bank6_cs_i, bank7_cs_i, bank8_cs_i;

//Sound board ROM chip select (index 1, 8KB at 0x0000-0x1FFF)
wire ep7_cs_i = (ioctl_addr < 25'h2000);

//MiSTer data write selector
selector DLSEL
(
	.ioctl_addr(ioctl_addr),
	.rom_m1_cs(rom_m1_cs_i),
	.rom_m2_cs(rom_m2_cs_i),
	.rom_m3_cs(rom_m3_cs_i),
	.rom_m4_cs(rom_m4_cs_i),
	.rom_m5_cs(rom_m5_cs_i),
	.rom_m6_cs(rom_m6_cs_i),
	.bank0_cs(bank0_cs_i),
	.bank1_cs(bank1_cs_i),
	.bank2_cs(bank2_cs_i),
	.bank3_cs(bank3_cs_i),
	.bank4_cs(bank4_cs_i),
	.bank5_cs(bank5_cs_i),
	.bank6_cs(bank6_cs_i),
	.bank7_cs(bank7_cs_i),
	.bank8_cs(bank8_cs_i)
);

//Instantiate main PCB
Tutankham_CPU main_pcb
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
	.dip_sw(dip_sw),
	.p1_fire_ext({m_flash1, m_fire1_r, m_fire1_l}),
	.p2_fire_ext({m_flash2, m_fire2_r, m_fire2_l}),
	.p1_joy({~p1_joystick[1], ~p1_joystick[0], ~p1_joystick[3], ~p1_joystick[2]}),
	.p2_joy({~p2_joystick[1], ~p2_joystick[0], ~p2_joystick[3], ~p2_joystick[2]}),
	.cs_sounddata(cs_sounddata),
	.irq_trigger(irq_trigger),
	.cs_dip2(cs_dip2),
	.cs_controls_dip1(cs_controls_dip1),
	
	.rom_m1_cs_i(rom_m1_cs_i),
	.rom_m2_cs_i(rom_m2_cs_i),
	.rom_m3_cs_i(rom_m3_cs_i),
	.rom_m4_cs_i(rom_m4_cs_i),
	.rom_m5_cs_i(rom_m5_cs_i),
	.rom_m6_cs_i(rom_m6_cs_i),
	.bank0_cs_i(bank0_cs_i),
	.bank1_cs_i(bank1_cs_i),
	.bank2_cs_i(bank2_cs_i),
	.bank3_cs_i(bank3_cs_i),
	.bank4_cs_i(bank4_cs_i),
	.bank5_cs_i(bank5_cs_i),
	.bank6_cs_i(bank6_cs_i),
	.bank7_cs_i(bank7_cs_i),
	.bank8_cs_i(bank8_cs_i),
	.cpu_A(cpu_A),	
	.mainrom_D(mainrom_D),
//	.bank_rom_D(bank_rom_D),

	.cpubrd_Dout(cpubrd_D),
	
//	.cpubrd_A5(A5),
//	.cpubrd_A6(A6),
	.ioctl_addr(ioctl_addr),
	.ioctl_wr(ioctl_wr_cpu),
	.ioctl_data(ioctl_data),

	.pause(pause),

	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write(hs_write)
);

//Instantiate sound PCB
TimePilot_SND sound_pcb
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
	.p1_fire(~m_fire1_l),
	.p2_fire(~m_fire2_l),
	.btn_service(btn_service),
	
	.cs_controls_dip1(cs_controls_dip1),
	.cs_dip2(cs_dip2),
	.cpubrd_A5(cpu_A[5]),
	.cpubrd_A6(cpu_A[6]),
	.cpubrd_Din(cpubrd_D),	
	.controls_dip(controls_dip),
	.sound(sound),
	
	.underclock(underclock),
	
	.ep7_cs_i(ep7_cs_i),
	.sound_A(sound_A),
	.eprom7_D(eprom7_D),
	.ioctl_addr(ioctl_addr),
	.ioctl_wr(ioctl_wr_snd),
	.ioctl_data(ioctl_data)
);

endmodule

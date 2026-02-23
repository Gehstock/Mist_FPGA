//============================================================================
//
//		Port to MiSTer.
//  	Copyright (C) 2026 Rodimus
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

module BluePrint_Top
(
	input                reset,
	input                clk_49m,

	// Player controls (active HIGH, assembled from MiSTer inputs)
	input          [7:0] p1_controls,
	input          [7:0] p2_controls,

	// DIP switches (directly from MiSTer OSD)
	input         [15:0] dip_sw,

	// Video outputs
	output               video_hsync, video_vsync, video_csync,
	output               video_hblank, video_vblank,
	output               ce_pix,
	output         [4:0] video_r, video_g, video_b,

	// Audio output
	output signed [15:0] sound,

	// Screen centering
	input          [3:0] h_center, v_center,

	// ROM loading
	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,
	input          [7:0] ioctl_index,

	input                pause,

	// Hiscore interface
	input         [15:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write
);

// Sound interface between CPU and sound board
wire [7:0] sound_cmd;
wire       sound_cmd_wr;
// TEMPORARY: bypass sound board DIP readback until sound is verified working.
// The sound CPU reads dip_sw[7:0] from AY2 Port A and writes it to AY1 Port A
// which main CPU reads at 0xC003. Short-circuit this path for testing.
wire [7:0] dipsw_readback_from_snd;
wire [7:0] dipsw_readback = dipsw_readback_from_snd;

// ROM loader signals for MISTer (loads ROMs from SD card)
wire main1_cs_i, main2_cs_i, main3_cs_i, main4_cs_i, main5_cs_i, main6_cs_i;
wire tile0_cs_i, tile1_cs_i;
wire spr_r_cs_i, spr_b_cs_i, spr_g_cs_i;

// Filter ioctl_wr for index 0 (CPU board ROMs) and index 1 (sound ROMs)
wire ioctl_wr_cpu = ioctl_wr && (ioctl_index == 8'd0);
wire ioctl_wr_snd = ioctl_wr && (ioctl_index == 8'd1);

// Sound ROM chip selects (within index 1's address space)
wire snd_rom1_cs_i = (ioctl_addr < 25'h1000);
wire snd_rom2_cs_i = (ioctl_addr >= 25'h1000) && (ioctl_addr < 25'h2000);

// MiSTer data write selector (active for ROM index 0 only)
selector DLSEL
(
	.ioctl_addr(ioctl_addr),
	.main1_cs(main1_cs_i),
	.main2_cs(main2_cs_i),
	.main3_cs(main3_cs_i),
	.main4_cs(main4_cs_i),
	.main5_cs(main5_cs_i),
	.main6_cs(main6_cs_i),
	.tile0_cs(tile0_cs_i),
	.tile1_cs(tile1_cs_i),
	.spr_r_cs(spr_r_cs_i),
	.spr_b_cs(spr_b_cs_i),
	.spr_g_cs(spr_g_cs_i)
);

// Instantiate main CPU board
BluePrint_CPU main_pcb
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

	.p1_controls(p1_controls),
	.p2_controls(p2_controls),
	.dipsw_readback(dipsw_readback),

	.sound_cmd(sound_cmd),
	.sound_cmd_wr(sound_cmd_wr),

	.h_center(h_center),
	.v_center(v_center),

	.main1_cs_i(main1_cs_i),
	.main2_cs_i(main2_cs_i),
	.main3_cs_i(main3_cs_i),
	.main4_cs_i(main4_cs_i),
	.main5_cs_i(main5_cs_i),
	.main6_cs_i(main6_cs_i),
	.tile0_cs_i(tile0_cs_i),
	.tile1_cs_i(tile1_cs_i),
	.spr_r_cs_i(spr_r_cs_i),
	.spr_b_cs_i(spr_b_cs_i),
	.spr_g_cs_i(spr_g_cs_i),
	.ioctl_addr(ioctl_addr),
	.ioctl_data(ioctl_data),
	.ioctl_wr(ioctl_wr_cpu),

	.pause(pause),

	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write(hs_write)
);

// Instantiate sound PCB
BluePrint_SND sound_pcb
(
	.reset(reset),
	.pause(pause),
	.clk_49m(clk_49m),
	.sound_cmd(sound_cmd),
	.sound_cmd_wr(sound_cmd_wr),
	.dip_sw(dip_sw),
	.dipsw_readback(dipsw_readback_from_snd),
	.sound(sound),
	.vblank(video_vblank),
	.snd_rom1_cs_i(snd_rom1_cs_i),
	.snd_rom2_cs_i(snd_rom2_cs_i),
	.ioctl_addr(ioctl_addr),
	.ioctl_data(ioctl_data),
	.ioctl_wr(ioctl_wr_snd)
);

endmodule

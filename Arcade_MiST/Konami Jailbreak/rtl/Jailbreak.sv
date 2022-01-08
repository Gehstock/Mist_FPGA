//============================================================================
// 
//  Jailbreak PCB model
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

module Jailbreak
(
	input                reset,
	input                clk_49m, //Actual frequency: 49.152MHz
	input          [1:0] coin,
	input                btn_service,
	input          [1:0] btn_start, //1 = Player 2, 0 = Player 1
	input          [3:0] p1_joystick, p2_joystick, //3 = up, 2 = down, 1 = right, 0 = left
	input          [1:0] p1_buttons, p2_buttons,   //2 buttons per player

	input                gberet, // Z80 board variant

	input         [19:0] dipsw,
	
	//This input serves to select a fractional divider to acheive 3.072MHz for the YM2203 depending on whether Scooter Shooter
	//runs with original or underclocked timings to normalize sync frequencies
	input                underclock,
	
	//Screen centering (alters HSync and VSync timing of the Konami 005849 to reposition the video output)
	input          [3:0] h_center, v_center,

	output signed [15:0] sound,
	output               video_csync,
	output               video_hsync, video_vsync,
	output               video_vblank, video_hblank,
	output               ce_pix,
	output         [3:0] video_r, video_g, video_b, //12-bit RGB, 4 bits per color

	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,

	input                pause,

	input         [11:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write_enable,
	input                hs_access_write,

	//SDRAM signals
	output reg    [15:0] main_cpu_rom_addr,
	input          [7:0] main_cpu_rom_do,
	output reg    [15:1] char1_rom_addr,
	input         [15:0] char1_rom_do,
	output               sp1_req,
	input                sp1_ack,
	output        [16:1] sp1_rom_addr,
	input         [15:0] sp1_rom_do
);

//------------------------------------------------------- Signal outputs -------------------------------------------------------//

//Output pixel clock enable
assign ce_pix = cen_6m;

//------------------------------------------------- MiSTer data write selector -------------------------------------------------//

//Instantiate MiSTer data write selector to generate write enables for loading ROMs into the FPGA's BRAM
wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i, ep6_cs_i, ep7_cs_i, ep8_cs_i, ep9_cs_i;
wire tl_cs_i, sl_cs_i, cp1_cs_i, cp2_cs_i;
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
	.tl_cs(tl_cs_i),
	.sl_cs(sl_cs_i),
	.cp1_cs(cp1_cs_i),
	.cp2_cs(cp2_cs_i)
);

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 6.144MHz, (inverted) 3.072MHz and 1.576MHz clock enables (clock division is normally handled inside the Konami 005849)
//Also generate an extra clock enable for DC offset removal in the sound section
reg [6:0] div = 7'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 7'd1;
end
wire cen_6m = !div[2:0];
wire cen_3m = !div[3:0];
wire cen_1m5 = !div[4:0];
wire dcrm_cen = !div;

//Generate E and Q clock enables for KONAMI-1 (code adapted from Sorgelig's phase generator used in the MiSTer Vectrex core)
reg k1_E, k1_Q;
always_ff @(posedge clk_49m) begin
	reg [1:0] clk_phase = 0;
	k1_E <= 0;
	k1_Q <= 0;
	if(cen_6m) begin
		clk_phase <= clk_phase + 1'd1;
		case(clk_phase)
			2'b01: k1_Q <= 1;
			2'b10: k1_E <= 1;
		endcase
	end
end

//Fractional divider to obtain 3.579545MHz clock for the VLM5030
wire [9:0] vlm5030_cen_n = underclock ? 10'd62 : 10'd60;
wire [9:0] vlm5030_cen_m = underclock ? 10'd843 : 10'd824;
wire cen_3m58;
jtframe_frac_cen vlm5030_cen
(
	.clk(clk_49m),
	.n(vlm5030_cen_n),
	.m(vlm5030_cen_m),
	.cen({1'bZ, cen_3m58})
);

//Extra fractional divider to maintain a steady 1.536MHz for the SN76489 when Jailbreak runs at underclocked timings
wire cen_1m5_adjust;
jtframe_frac_cen sn76489_cen
(
	.clk(clk_49m),
	.n(10'd25),
	.m(10'd786),
	.cen({1'bZ, cen_1m5_adjust})
);

//------------------------------------------------------------ CPU (KONAMI-1) ----------------------------------------------------------//

//CPU - KONAMI-1 custom encrypted MC6809E (uses synchronous version of Greg Miller's cycle-accurate MC6809E made by
//Sorgelig with a wrapper to decrypt XOR/XNOR-encrypted opcodes and a further modification to Greg's MC6809E to directly
//accept the opcodes)
wire k1_rw;
wire [15:0] k1_A;
wire [7:0] k1_Dout;
KONAMI1 u18F
(
	.CLK(clk_49m),
	.fallE_en(k1_E),
	.fallQ_en(k1_Q),
	.D(k1_Din),
	.DOut(k1_Dout),
	.ADDR(k1_A),
	.RnW(k1_rw),
	.nIRQ(irq),
	.nFIRQ(firq),
	.nNMI(nmi),
	.nHALT(~pause),
	.nRESET(reset & !gberet)
);
//Address decoding for KONAMI-1
wire cs_k1_dip2 = ~n_iocs & (k1_A[10:8] == 3'b001) & k1_rw;
wire cs_k1_dip3 = ~n_iocs & (k1_A[10:8] == 3'b010) & k1_rw;
wire cs_k1_controls_dip1 = ~n_iocs & (k1_A[10:8] == 3'b011) & k1_rw;
wire cs_k1_snlatch = ~n_iocs & (k1_A[10:8] == 3'b001) & ~k1_rw;
wire cs_k1_sn76489 = ~n_iocs & (k1_A[10:8] == 3'b010) & ~k1_rw;
wire cs_k1_k005849 = (k1_A[15:14] == 2'b00);
wire cs_k1_vlm5030_busy = (k1_A[15:12] == 4'b0110);
wire cs_k1_rom1 = (k1_A[15:14] == 2'b10) & k1_rw;
wire cs_k1_rom2 = (k1_A[15:14] == 2'b11) & k1_rw;
//Multiplex data inputs to KONAMI-1
wire [7:0] k1_Din = cs_k1_dip2                       ? dipsw[15:8]:
                    cs_k1_dip3                       ? {4'hF, dipsw[19:16]}:
                    cs_k1_controls_dip1              ? controls_k1_dip1:
                    (cs_k1_k005849 & n_iocs & k1_rw) ? k005849_D:
                    cs_k1_vlm5030_busy               ? {7'h7F, vlm5030_busy}:
                    cs_k1_rom1                       ? eprom1_D:
                    cs_k1_rom2                       ? eprom2_D:
                    8'hFF;

//------------------------------------------------------------ CPU (Z80) ----------------------------------------------------------//
wire z80_n_m1, z80_n_mreq, z80_n_iorq, z80_n_rfsh, z80_n_rd, z80_n_wr;
wire [15:0] z80_A;
wire [7:0] z80_Dout;
T80s u9A
(
	.RESET_n(reset & gberet),
	.CLK(clk_49m),
	.CEN(cen_3m & ~pause),
	.INT_n(z80_n_int),
	.NMI_n(z80_n_nmi),
	.MREQ_n(z80_n_mreq),
	.IORQ_n(z80_n_iorq),
	.RD_n(z80_n_rd),
	.WR_n(z80_n_wr),
	.M1_n(z80_n_m1),
	.RFSH_n(z80_n_rfsh),
	.A(z80_A),
	.DI(z80_Din),
	.DO(z80_Dout)
);
//Address decoding for Z80
wire z80_decode_en = (z80_n_rfsh & ~z80_n_mreq);
wire cs_z80_dip2 = ~n_iocs & (z80_A[10:8] == 3'b010) & ~z80_n_rd;
wire cs_z80_dip3 = ~n_iocs & (z80_A[10:8] == 3'b100) & ~z80_n_rd;
wire cs_z80_controls_dip1 = ~n_iocs & (z80_A[10:8] == 3'b110) & ~z80_n_rd;
wire cs_z80_snlatch = ~n_iocs & (z80_A[10:8] == 3'b010) & ~z80_n_wr;
wire cs_z80_sn76489 = ~n_iocs & (z80_A[10:8] == 3'b100) & ~z80_n_wr;
wire cs_z80_bankw = ~n_iocs & (z80_A[10:8] == 3'b000) & ~z80_n_wr;
wire cs_z80_k005849 = z80_decode_en & (z80_A[15:14] == 2'b11) & ~cs_z80_rom4;
wire cs_z80_rom1 = z80_decode_en & (z80_A[15:14] == 2'b00);
wire cs_z80_rom2 = z80_decode_en & (z80_A[15:14] == 2'b01);
wire cs_z80_rom3 = z80_decode_en & (z80_A[15:14] == 2'b10);
wire cs_z80_rom4 = z80_decode_en & (z80_A[15:11] == 5'b11111);

//Multiplex data inputs to Z80
wire [7:0] z80_Din = cs_z80_dip2                       ? dipsw[15:8]:
                     cs_z80_dip3                       ? {4'hF, dipsw[19:16]}:
                     cs_z80_controls_dip1              ? controls_z80_dip1:
                     (cs_z80_k005849 & n_iocs & ~z80_n_rd) ? k005849_D:
                     cs_z80_rom1                       ? eprom1_D:
                     cs_z80_rom2                       ? eprom2_D:
                     cs_z80_rom3                       ? eprom3_D:
                     cs_z80_rom4                       ? eprom4_D:
                     8'hFF;

wire z80_n_nmi = nmi;
wire z80_n_int = firq & irq;

reg [2:0] z80_bank;
always_ff @(posedge clk_49m)
	if (cs_z80_bankw) z80_bank <= z80_Dout[7:5];

// --------------------------------------------CPU BUS Selector----------------------------------------------------------//
wire        cs_snlatch = gberet ? cs_z80_snlatch : cs_k1_snlatch;
wire        cs_sn76489 = gberet ? cs_z80_sn76489 : cs_k1_sn76489;
wire        cs_k005849 = gberet ? cs_z80_k005849 : cs_k1_k005849;
wire [15:0] cpu_A      = gberet ? z80_A : k1_A;
wire  [7:0] cpu_Dout   = gberet ? z80_Dout : k1_Dout;
wire        cpu_rw     = gberet ? z80_n_wr : k1_rw;

// ----------------------------------------------------------------------------------------------------------------------//
//CPU ROMs (first 16k)
`ifdef EXT_ROM
always_ff @(posedge clk_49m)
	if (gberet) begin
		if (z80_A[15:14] != 2'b11 & z80_decode_en & ~z80_n_rd) main_cpu_rom_addr <= z80_A;
		if (z80_A[15:11] == 5'b11111 & z80_decode_en & ~z80_n_rd) main_cpu_rom_addr <= {2'b11, z80_bank, z80_A[10:0]};
	end 
	else begin
		if (k1_A[15] & k1_rw) main_cpu_rom_addr <= k1_A[14:0];
	end

wire [7:0] eprom1_D = main_cpu_rom_do;
wire [7:0] eprom2_D = main_cpu_rom_do;
//wire [7:0] eprom3_D = main_cpu_rom_do;
wire [7:0] eprom4_D = main_cpu_rom_do;
`else
//ROM 1/2
wire [7:0] eprom1_D;
eprom_1 u11D
(
	.ADDR(k1_A[13:0]),
	.CLK(clk_49m),
	.DATA(eprom1_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep1_cs_i),
	.WR(ioctl_wr)
);
//ROM 2/2
wire [7:0] eprom2_D;
eprom_2 u9D
(
	.ADDR(k1_A[13:0]),
	.CLK(clk_49m),
	.DATA(eprom2_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep2_cs_i),
	.WR(ioctl_wr)
);
`endif

//Sound latch
reg [7:0] sound_data = 8'd0;
always_ff @(posedge clk_49m)
	if(cs_snlatch)	sound_data <= cpu_Dout;

//--------------------------------------------------- Controls & DIP switches --------------------------------------------------//

//Multiplex player inputs and DIP switch bank 1
wire [7:0] controls_k1_dip1 = (k1_A[1:0] == 2'b00) ? {3'b111, btn_start, btn_service, coin}:
                              (k1_A[1:0] == 2'b01) ? {2'b11, p1_buttons, p1_joystick}:
                              (k1_A[1:0] == 2'b10) ? {2'b11, p2_buttons, p2_joystick}:
                              (k1_A[1:0] == 2'b11) ? dipsw[7:0]:
                              8'hFF;

wire [7:0] controls_z80_dip1 = (z80_A[1:0] == 2'b11) ? {3'b111, btn_start, btn_service, coin}:
                               (z80_A[1:0] == 2'b10) ? {2'b11, p1_buttons, p1_joystick}:
                               (z80_A[1:0] == 2'b01) ? {2'b11, p2_buttons, p2_joystick}:
                               (z80_A[1:0] == 2'b00) ? dipsw[7:0]:
                               8'hFF;

//--------------------------------------------------- Video timing & graphics --------------------------------------------------//

//Konami 005849 custom chip - this is a large ceramic pin-grid array IC responsible for the majority of Jailbreak's critical
//functions: IRQ generation, clock dividers and all video logic for generating tilemaps and sprites
wire [15:0] spriterom_A;
wire [14:0] tilerom_A;
wire [7:0] k005849_D, tilemap_lut_A, sprite_lut_A;
wire [4:0] color_A;
wire [1:0] h_cnt;
wire n_iocs, irq, firq, nmi;
k005849 u8E
(
	.CK49(clk_49m),
	.RES(reset),
	.READ(~cpu_rw),
	.A(cpu_A[13:0]),
	.DBi(cpu_Dout),
	.DBo(k005849_D),
	.VCF(tilemap_lut_A[7:4]),
	.VCB(tilemap_lut_A[3:0]),
	.VCD(tilemap_lut_D),
	.OCF(sprite_lut_A[7:4]),
	.OCB(sprite_lut_A[3:0]),
	.OCD(sprite_lut_D),
	.COL(color_A),
	.XCS(~cs_k005849),
	.BUSE(0),
	.SYNC(video_csync),
	.HSYC(video_hsync),
	.VSYC(video_vsync),
	.HBLK(video_hblank),
	.VBLK(video_vblank),
	.FIRQ(firq),
	.IRQ(irq),
	.NMI(nmi),
	.IOCS(n_iocs),
	.R(tilerom_A),
	.S(spriterom_A),
	.S_req(sp1_req),
	.S_ack(sp1_ack),
	.RD(tilerom_D),
	.SD(spriterom_D),
	.HCTR(h_center),
	.VCTR(v_center),
	.SPFL(gberet),

	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write_enable(hs_write_enable),
	.hs_access_write(hs_access_write)
);

//Graphics ROMs
`ifdef EXT_ROM
assign sp1_rom_addr = spriterom_A[15:1];
wire [7:0] spriterom_D = spriterom_A[0] ? sp1_rom_do[15:8] : sp1_rom_do[7:0];
assign char1_rom_addr = {gberet ? 1'b1 : tilerom_A[14], tilerom_A[13:1]};
wire [7:0] tilerom_D = tilerom_A[0] ? char1_rom_do[15:8] : char1_rom_do[7:0];
`else
wire [7:0] eprom4_D, eprom5_D, eprom6_D, eprom7_D, eprom8_D, eprom9_D;
eprom_4 u4F
(
	.ADDR(tilerom_A[13:0]),
	.CLK(clk_49m),
	.DATA(eprom4_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep4_cs_i),
	.WR(ioctl_wr)
);
eprom_5 u5F
(
	.ADDR(tilerom_A[13:0]),
	.CLK(clk_49m),
	.DATA(eprom5_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep5_cs_i),
	.WR(ioctl_wr)
);
eprom_6 u3E
(
	.ADDR(spriterom_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom6_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep6_cs_i),
	.WR(ioctl_wr)
);
eprom_7 u4E
(
	.ADDR(spriterom_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom7_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep7_cs_i),
	.WR(ioctl_wr)
);
eprom_8 u5E
(
	.ADDR(spriterom_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom8_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep8_cs_i),
	.WR(ioctl_wr)
);
eprom_9 u3F
(
	.ADDR(spriterom_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom9_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep9_cs_i),
	.WR(ioctl_wr)
);

//Multiplex tilemap ROMs
wire [7:0] tilerom_D = (gberet | tilerom_A[14]) ? eprom5_D : eprom4_D;

//Multiplex sprite ROMs
wire [7:0] spriterom_D = (spriterom_A[15:14] == 2'b00) ? eprom6_D:
                         (spriterom_A[15:14] == 2'b01) ? eprom7_D:
                         (spriterom_A[15:14] == 2'b10) ? eprom8_D:
                         (spriterom_A[15:14] == 2'b11) ? eprom9_D:
                         8'hFF;
`endif

//Tilemap LUT PROM
wire [3:0] tilemap_lut_D;
tile_lut_prom u7F
(
	.ADDR(tilemap_lut_A),
	.CLK(clk_49m),
	.DATA(tilemap_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(tl_cs_i),
	.WR(ioctl_wr)
);

//Sprite LUT PROM
wire [3:0] sprite_lut_D;
sprite_lut_prom u6F
(
	.ADDR(sprite_lut_A),
	.CLK(clk_49m),
	.DATA(sprite_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(sl_cs_i),
	.WR(ioctl_wr)
);

//--------------------------------------------------------- Sound chips --------------------------------------------------------//

//Generate chip enable for SN76489
wire n_sn76489_ce = (~cs_sn76489 & sn76489_ready);

//Select whether to use a fractional or integer clock divider for the YM2203 to maintain consistent sound pitch at both original
//and underclocked timings
wire cen_sn76489 = underclock ? cen_1m5_adjust : cen_1m5;

//Sound chip 1 (Texas Instruments SN76489 - uses Arnim Laeuger's SN76489 implementation with bugfixes)
wire [7:0] sn76489_raw;
wire sn76489_ready;
sn76489_top u6D
(
	.clock_i(clk_49m),
	.clock_en_i(cen_sn76489),
	.res_n_i(reset),
	.ce_n_i(n_sn76489_ce),
	.we_n_i(sn76489_ready),
	.ready_o(sn76489_ready),
	.d_i(sound_data),
	.aout_o(sn76489_raw)
);

//Sound chip 2 (VLM5030 - uses Arnim Laeuger's gate-level VLM5030 implementation)
//Sourced from https://github.com/FPGAArcade/replay_common/tree/master/lib/sound/vlm5030
wire [12:0] vlm5030_rom_A;
wire signed [9:0] vlm5030_raw;
wire vlm5030_busy, n_vlm5030_rom_en;
vlm5030_gl u6A
(
	.i_clk(clk_49m),
	.i_oscen(cen_3m58),
	.i_rst(vlm5030_reset),
	.i_start(vlm5030_start),
	.i_vcu(0),
	.i_tst1(0),
	.i_d(vlm5030_Din),
	.o_a({3'bZZZ, vlm5030_rom_A}),
	.o_me_l(n_vlm5030_rom_en),
	.o_bsy(vlm5030_busy),
	.o_audio(vlm5030_raw)
);

//VLM5030 ROM (8000-bfff CPU ROM on Greeb Beret/Mr.Goemon)
wire [7:0] eprom3_D;
eprom_3 u8C
(
	.ADDR(gberet ? cpu_A[13:0] : vlm5030_rom_A),
	.CLK(clk_49m),
	.DATA(eprom3_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep3_cs_i),
	.WR(ioctl_wr)
);

//Generate VLM5030 latch signals
wire vlm5030_ctrl_latch = (k1_A[15:12] == 4'b0100);
wire vlm5030_latch = (k1_A[15:12] == 4'b0101);

//Latch VLM5030 control lines from KONAMI-1
reg vlm5030_reset = 0;
reg vlm5030_start = 0;
reg vlm5030_enable = 0;
always_ff @(posedge clk_49m) begin
	if(cen_3m && vlm5030_ctrl_latch) begin
		vlm5030_enable <= k1_Dout[0];
		vlm5030_start <= k1_Dout[1];
		vlm5030_reset <= k1_Dout[2];
	end
end

//Latch data from KONAMI-1 to VLM5030
reg [7:0] vlm5030_sound_D = 8'd0;
always_ff @(posedge clk_49m) begin
	if(cen_3m && vlm5030_latch)
		vlm5030_sound_D <= k1_Dout;
end

//Multiplex data inputs from the ROM and KONAMI-1 to the VLM5030's data input
wire [7:0] vlm5030_Din = vlm5030_enable    ? vlm5030_sound_D:
                         ~n_vlm5030_rom_en ? eprom3_D:
                         8'hFF;

//----------------------------------------------------- Final video output -----------------------------------------------------//

//Jailbreak's final video output consists of two PROMs addressed by the 005849 custom tilemap generator
wire [7:0] prom1_d, prom2_d;
assign video_r = gberet ? {prom1_d[2:0], prom1_d[2]} : prom1_d[3:0];
assign video_g = gberet ? {prom1_d[5:3], prom1_d[5]} : prom1_d[7:4];
assign video_b = gberet ? {prom1_d[7:6], prom1_d[7:6]} : prom2_d[3:0];

color_prom_1 u1F
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA(prom1_d),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp1_cs_i),
	.WR(ioctl_wr)
);

color_prom_2 u2F
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA(prom2_d),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp2_cs_i),
	.WR(ioctl_wr)
);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//Apply gain and remove DC offset from SN76489 (uses jt49_dcrm2 from JT49 by Jotego for DC offset removal)
wire signed [15:0] sn76489_dcrm;
jt49_dcrm2 #(16) dcrm_sn76489
(
	.clk(clk_49m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({3'd0, sn76489_raw, 5'd0}),
	.dout(sn76489_dcrm)
);

//Apply gain to the VLM5030
wire signed [15:0] vlm5030_gain = vlm5030_raw <<< 16'd6;

//Jailbreak uses a 3.386KHz low-pass filter for its SN76489 - filter the audio accordingly here.
wire signed [15:0] sn76489_lpf;
jailbreak_psg_lpf psg_lpf
(
	.clk(clk_49m),
	.reset(~reset),
	.in(sn76489_dcrm),
	.out(sn76489_lpf)
);

//Jailbreak also uses a 338.628Hz low-pass filter for its VLM5030 - filter the audio accordingly here.
wire signed [15:0] vlm5030_lpf;
jailbreak_speech_lpf speech_lpf
(
	.clk(clk_49m),
	.reset(~reset),
	.in(vlm5030_gain),
	.out(vlm5030_lpf)
);

//The output of the VLM5030 is phase-inverted - apply this inversion here
//Also lower the volume for mixing with the SN76489
wire signed [15:0] vlm5030_inv = (16'hFFFF - vlm5030_lpf) >>> 16'd5;

//Lower SN76489 volume to balance out with the VLM5030
wire signed [15:0] sn76489_gain = sn76489_lpf >>> 16'd3;

//Output final audio signal (mute when game is paused)
assign sound = pause ? 16'd0 : (sn76489_gain + vlm5030_inv) <<< 16'd5;

endmodule

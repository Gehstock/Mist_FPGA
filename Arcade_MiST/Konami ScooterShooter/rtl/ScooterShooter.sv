//============================================================================
// 
//  Scooter Shooter PCB model
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

module ScooterShooter
(
	input                reset,
	input                clk_49m, //Actual frequency: 49.152MHz
	input          [1:0] coin,
	input                btn_service,
	input          [1:0] btn_start, //1 = Player 2, 0 = Player 1
	input          [3:0] p1_joystick, p2_joystick, //3 = up, 2 = down, 1 = right, 0 = left
	input                p1_fire,
	input                p2_fire,
	
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
	output reg    [14:0] sub_cpu_rom_addr,
	input          [7:0] sub_cpu_rom_do,
	output reg    [14:1] char1_rom_addr,
	input         [15:0] char1_rom_do,
	output               sp1_req,
	input                sp1_ack,
	output        [15:0] sp1_rom_addr,
	input         [15:0] sp1_rom_do
);

//------------------------------------------------------- Signal outputs -------------------------------------------------------//

//Output pixel clock enable
assign ce_pix = cen_6m;

//------------------------------------------------- MiSTer data write selector -------------------------------------------------//

//Instantiate MiSTer data write selector to generate write enables for loading ROMs into the FPGA's BRAM
wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i, ep6_cs_i;
wire cp1_cs_i, cp2_cs_i, cp3_cs_i, tl_cs_i, sl_cs_i;
selector DLSEL
(
	.ioctl_addr(ioctl_addr),
	.ep1_cs(ep1_cs_i),
	.ep2_cs(ep2_cs_i),
	.ep3_cs(ep3_cs_i),
	.ep4_cs(ep4_cs_i),
	.ep5_cs(ep5_cs_i),
	.ep6_cs(ep6_cs_i),
	.tl_cs(tl_cs_i),
	.sl_cs(sl_cs_i),
	.cp1_cs(cp1_cs_i),
	.cp2_cs(cp2_cs_i),
	.cp3_cs(cp3_cs_i)
);

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 6.144MHz and (inverted) 3.072MHz clock enables (clock division is normally handled inside the Konami 005849)
//Also generate an extra clock enable for DC offset removal in the sound section
reg [6:0] div = 7'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 7'd1;
end
wire cen_6m = !div[2:0];
wire cen_3m = !div[3:0];
wire dcrm_cen = !div;

//Generate E and Q clock enables for MC6809E (code adapted from Sorgelig's phase generator used in the MiSTer Vectrex core)
reg E, Q;
always_ff @(posedge clk_49m) begin
	reg [1:0] clk_phase = 0;
	E <= 0;
	Q <= 0;
	if(cen_6m) begin
		clk_phase <= clk_phase + 1'd1;
		case(clk_phase)
			2'b01: E <= 1;
			2'b10: Q <= 1;
		endcase
	end
end

//Generate 3.072MHz clock enable for YM2203 to maintain consistent sound pitch when underclocked to normalize video timings
//(uses Jotego's fractional clock divider from JTFRAME)
wire cen_3m_adjust;
jtframe_frac_cen sound_cen
(
	.clk(clk_49m),
	.n(10'd50),
	.m(10'd786),
	.cen({1'bZ, cen_3m_adjust})
);

//------------------------------------------------------------ CPU -------------------------------------------------------------//

//Main CPU (Motorola MC6809E - uses synchronous version of Greg Miller's cycle-accurate MC6809E made by Sorgelig)
wire [15:0] mc6809e_A;
wire [7:0] mc6809e_Dout;
wire mc6809e_rw, mc6809e_avma;

`ifdef CPU09
wire vma;
cpu09 u12G
(
	.clk(~clk_49m),
	.ce(E),
	.rst(~reset),
	.rw(mc6809e_rw),
	.addr(mc6809e_A),
	.vma(vma),
	.data_in(mc6809e_Din),
	.data_out(mc6809e_Dout),
	.halt(0),
	.irq(~irq),
	.firq(~firq),
	.nmi(~nmi)
);
`else
mc6809is u12A
(
	.CLK(clk_49m),
	.fallE_en(E),
	.fallQ_en(Q),
	.D(mc6809e_Din),
	.DOut(mc6809e_Dout),
	.ADDR(mc6809e_A),
	.RnW(mc6809e_rw),
	.AVMA(mc6809e_avma),
	.nIRQ(irq),
	.nFIRQ(firq),
	.nNMI(nmi),
	.nHALT(~pause),	 
	.nRESET(reset),
	.nDMABREQ(1)
);
reg vma;
always @(posedge clk_49m) if (E) vma <= mc6809e_avma;
`endif

//Address decoding for MC6809E
wire cs_dip2 = ~n_iocs & (mc6809e_A[10:8] == 3'b001) & mc6809e_rw;
wire cs_dip3 = ~n_iocs & (mc6809e_A[10:8] == 3'b010) & mc6809e_rw;
wire cs_palettelatch = ~n_iocs & (mc6809e_A[10:8] == 3'b000) & ~mc6809e_rw;
wire cs_soundlatch = ~n_iocs & (mc6809e_A[10:8] == 3'b001) & ~mc6809e_rw;
wire cs_controls_dip1 = ~n_iocs & (mc6809e_A[10:8] == 3'b011) & mc6809e_rw;
wire cs_k005849 = (mc6809e_A[15:14] == 2'b00);
wire cs_rom1 = (mc6809e_A[15:14] == 2'b01 || mc6809e_A[15:14] == 2'b10) & mc6809e_rw;
wire cs_rom2 = (mc6809e_A[15:14] == 2'b11) & mc6809e_rw;
//Multiplex data inputs to MC6809E
wire [7:0] mc6809e_Din = cs_dip2                            ? dipsw[15:8]:
                         cs_dip3                            ? {4'hF, dipsw[19:16]}:
                         cs_controls_dip1                   ? controls_dip1:
                         (cs_k005849 & n_iocs & mc6809e_rw) ? k005849_D:
                         cs_rom1                            ? eprom1_D:
                         cs_rom2                            ? eprom2_D:
                         8'hFF;

//Game ROMs
`ifdef EXT_ROM
always_ff @(negedge clk_49m)
	if (|mc6809e_A[15:14] & mc6809e_rw & vma)
		main_cpu_rom_addr <= {&mc6809e_A[15:14], ~mc6809e_A[15] & mc6809e_A[14], mc6809e_A[13:0]};

wire [7:0] eprom1_D = main_cpu_rom_do;
wire [7:0] eprom2_D = main_cpu_rom_do;
`else
wire [7:0] eprom1_D;
eprom_1 u12C
(
	.ADDR(mc6809e_A[14:0]),
	.CLK(clk_49m),
	.DATA(eprom1_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep1_cs_i),
	.WR(ioctl_wr)
);
wire [7:0] eprom2_D;
eprom_2 u10C
(
	.ADDR(mc6809e_A[13:0]),
	.CLK(clk_49m),
	.DATA(eprom2_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep2_cs_i),
	.WR(ioctl_wr)
);
`endif

//Palette latch
reg [7:0] pal_latch = 8'd0;
always_ff @(posedge clk_49m) begin
	if(!reset)
		pal_latch <= 8'd0;
	else if(cen_3m) begin
		if(cs_palettelatch)
			pal_latch <= mc6809e_Dout;
	end
end
wire [2:0] palette_bank = pal_latch[6:4];

//Sound latch
reg [7:0] sound_data = 8'd0;
always_ff @(posedge clk_49m) begin
	if(cen_3m && cs_soundlatch)
		sound_data <= mc6809e_Dout;
end

//Sound IRQ trigger
reg sound_irq = 1;
always_ff @(posedge clk_49m) begin
	if(cen_3m) begin
		if(cs_soundlatch)
			sound_irq <= 1;
		else
			sound_irq <= 0;
	end
end

//Sound CPU - Zilog Z80 (uses T80s variant of the T80 soft core)
wire z80_n_m1, z80_n_mreq, z80_n_iorq, z80_n_rfsh, z80_n_rd, z80_n_wr;
wire [15:0] z80_A;
wire [7:0] z80_Din, z80_Dout;
T80s u7A
(
	.RESET_n(reset),
	.CLK(clk_49m),
	.CEN(cen_sound),
	.INT_n(z80_n_int),
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
//Address decoding for data inputs to Z80
wire z80_decode_en = (z80_n_rfsh & ~z80_n_mreq);
wire soundrom_cs = z80_decode_en & (z80_A[15:14] == 2'b00);
wire soundram_cs = z80_decode_en & (z80_A[15:14] == 2'b01);
wire sounddata_cs = z80_decode_en & (z80_A[15:14] == 2'b10);
//Multiplex data inputs to Z80
assign z80_Din = soundrom_cs               ? eprom3_D:
                 (soundram_cs & ~z80_n_rd) ? soundram_D:
                 sounddata_cs              ? sound_data:
                 (~z80_n_iorq & ~z80_n_rd) ? ym2203_D:
                 8'hFF;

//Sound ROM
`ifdef EXT_ROM
wire [7:0] eprom3_D = sub_cpu_rom_do;
always_ff @(posedge clk_49m)
	if (soundrom_cs) sub_cpu_rom_addr <= z80_A[13:0];
`else
wire [7:0] eprom3_D;
eprom_3 u8C
(
	.ADDR(z80_A[13:0]),
	.CLK(clk_49m),
	.DATA(eprom3_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep3_cs_i),
	.WR(ioctl_wr)
);
`endif

//Sound RAM
wire [7:0] soundram_D;
spram #(8, 11) u9C
(
	.clk(clk_49m),
	.we(soundram_cs & ~z80_n_wr),
	.addr(z80_A[10:0]),
	.data(z80_Dout),
	.q(soundram_D)
);

//Generate sound IRQ
wire sirq_clr = (~reset | ~(z80_n_m1 | z80_n_iorq));
reg z80_n_int = 1;
always_ff @(posedge clk_49m or posedge sirq_clr) begin
	if(sirq_clr)
		z80_n_int <= 1;
	else if(cen_sound && sound_irq)
		z80_n_int <= 0;
end


//--------------------------------------------------- Controls & DIP switches --------------------------------------------------//

//Multiplex player inputs and DIP switch bank 1
wire [7:0] controls_dip1 = (mc6809e_A[1:0] == 2'b00) ? {3'b111, btn_start, btn_service, coin}:
                           (mc6809e_A[1:0] == 2'b01) ? {3'b111, p1_fire, p1_joystick}:
                           (mc6809e_A[1:0] == 2'b10) ? {3'b111, p2_fire, p2_joystick}:
                           (mc6809e_A[1:0] == 2'b11) ? dipsw[7:0]:
                           8'hFF;

//--------------------------------------------------- Video timing & graphics --------------------------------------------------//

//Konami 005849 custom chip - this is a large ceramic pin-grid array IC responsible for the majority of Scooter Shooter's critical
//functions: IRQ generation, clock dividers and all video logic for generating tilemaps and sprites
wire [15:0] spriterom_A;
wire [15:0] tilerom_A;
wire [7:0] k005849_D, tilemap_lut_A, sprite_lut_A;
wire [4:0] color_A;
wire [1:0] h_cnt;
wire n_iocs, irq, firq, nmi;
k005849 u8E
(
	.CK49(clk_49m),
	.RES(reset),
	.READ(~mc6809e_rw),
	.A(mc6809e_A[13:0]),
	.DBi(mc6809e_Dout),
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
	.RD(eprom4_D),
	.SD(spriterom_D),
	.HCTR(h_center),
	.VCTR(v_center),
	.SPFL(1),
	
	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write_enable(hs_write_enable),
	.hs_access_write(hs_access_write)
);

//Graphics ROMs
`ifdef EXT_ROM
assign sp1_rom_addr = spriterom_A[15:0];
wire [7:0] spriterom_D = spriterom_A[0] ? sp1_rom_do[15:8] : sp1_rom_do[7:0];
assign char1_rom_addr = {tilerom_A[15], tilerom_A[13:1]};
wire [7:0] eprom4_D = tilerom_A[0] ? char1_rom_do[15:8] : char1_rom_do[7:0];
`else
wire [7:0] eprom4_D;
eprom_4 u5F
(
	.ADDR({tilerom_A[15], tilerom_A[13:0]}),
	.CLK(clk_49m),
	.DATA(eprom4_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep4_cs_i),
	.WR(ioctl_wr)
);
wire [7:0] eprom5_D, eprom6_D;

eprom_5 u6F
(
	.ADDR(spriterom_A[14:0]),
	.CLK(~clk_49m),
	.DATA(eprom5_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep5_cs_i),
	.WR(ioctl_wr)
);

eprom_6 u4F
(
	.ADDR(spriterom_A[14:0]),
	.CLK(~clk_49m),
	.DATA(eprom6_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep6_cs_i),
	.WR(ioctl_wr)
);

//Multiplex sprite ROMs
wire [7:0] spriterom_D = spriterom_A[15] ? eprom6_D : eprom5_D;
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
sprite_lut_prom u8F
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

//Select whether to use a fractional or integer clock divider for the YM2203 to maintain consistent sound pitch at both original
//and underclocked timings
wire cen_sound = underclock ? cen_3m_adjust : cen_3m;

//Sound chip (Yamaha YM2203 - uses JT03 implementation by Jotego)
wire [2:0] filter_en;
wire [7:0] ym2203_D;
wire [7:0] ym2203_ssgA_raw, ym2203_ssgB_raw, ym2203_ssgC_raw;
wire signed [15:0] ym2203_fm_raw;

jt03 u4D
(
	.rst(~reset),
	.clk(clk_49m),
	.cen(cen_sound),
	.din(z80_Dout),
	.dout(ym2203_D),
	.IOA_out({5'bZZZZZ, filter_en}),
	.addr(z80_A[0]),
	.cs_n(z80_n_iorq),
	.wr_n(z80_n_wr),
	.psg_A(ym2203_ssgA_raw),
	.psg_B(ym2203_ssgB_raw),
	.psg_C(ym2203_ssgC_raw),
	.fm_snd(ym2203_fm_raw)
);

//----------------------------------------------------- Final video output -----------------------------------------------------//

//Scooter Shooter's final video output consists of three PROMs, one per color, addressed by the 005849 custom tilemap generator
//and palette latch
color_prom_1 u1F
(
	.ADDR({color_A[4], palette_bank, color_A[3:0]}),
	.CLK(clk_49m),
	.DATA(video_r),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp1_cs_i),
	.WR(ioctl_wr)
);
color_prom_2 u2F
(
	.ADDR({color_A[4], palette_bank, color_A[3:0]}),
	.CLK(clk_49m),
	.DATA(video_g),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp2_cs_i),
	.WR(ioctl_wr)
);
color_prom_3 u3F
(
	.ADDR({color_A[4], palette_bank, color_A[3:0]}),
	.CLK(clk_49m),
	.DATA(video_b),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp3_cs_i),
	.WR(ioctl_wr)
);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//Scooter Shooter uses a 4.823KHz low-pass filter for the FM side of its YM2203 - filter the audio accordingly here.
wire signed [15:0] ym2203_fm_lpf;
sshooter_fm_lpf lpf_fm
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ym2203_fm_raw),
	.out(ym2203_fm_lpf)
);

//Scooter Shooter also uses 3 switchable low-pass filters on the SSG side of its YM2203 with a cutoff frequency of
//723.432Hz (actually closer to 492.130Hz due to internal resistance inside the 74HC4066 handling the filter switching).
//Model the switchable filters here.
wire signed [15:0] ym2203_ssgA_lpf, ym2203_ssgB_lpf, ym2203_ssgC_lpf;
sshooter_ssg_lpf lpf_ssgA
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ym2203_ssgA_dcrm),
	.out(ym2203_ssgA_lpf)
);
sshooter_ssg_lpf lpf_ssgB
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ym2203_ssgB_dcrm),
	.out(ym2203_ssgB_lpf)
);
sshooter_ssg_lpf lpf_ssgC
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ym2203_ssgC_dcrm),
	.out(ym2203_ssgC_lpf)
);

//Remove DC offset from SSG outputs and apply gain to prevent losing quiet sounds after low-pass filtering
wire signed [15:0] ym2203_ssgA_dcrm, ym2203_ssgB_dcrm, ym2203_ssgC_dcrm;
jt49_dcrm2 #(16) dcrm_ssgA
(
	.clk(clk_49m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({3'd0, ym2203_ssgA_raw, 5'd0}),
	.dout(ym2203_ssgA_dcrm)
);
jt49_dcrm2 #(16) dcrm_ssgB
(
	.clk(clk_49m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({3'd0, ym2203_ssgB_raw, 5'd0}),
	.dout(ym2203_ssgB_dcrm)
);
jt49_dcrm2 #(16) dcrm_ssgC
(
	.clk(clk_49m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({3'd0, ym2203_ssgC_raw, 5'd0}),
	.dout(ym2203_ssgC_dcrm)
);

//Apply the switchable low-pass filters and attenuate SSG outputs back to raw levels
wire signed [15:0] ym2203_ssgA = filter_en[2] ? ym2203_ssgA_lpf >>> 15'd5 : ym2203_ssgA_dcrm >>> 15'd5;
wire signed [15:0] ym2203_ssgB = filter_en[1] ? ym2203_ssgB_lpf >>> 15'd5 : ym2203_ssgB_dcrm >>> 15'd5;
wire signed [15:0] ym2203_ssgC = filter_en[0] ? ym2203_ssgC_lpf >>> 15'd5 : ym2203_ssgC_dcrm >>> 15'd5;

//Mix all audio sources for the final output
assign sound = (ym2203_fm_lpf + (ym2203_ssgA * 15'd21) + (ym2203_ssgB * 15'd21) + (ym2203_ssgC * 15'd21)) <<< 15'd1;

endmodule

//============================================================================
// 
//  Iron Horse PCB model
//  Copyright (C) 2020, 2021 Ace, Ash Evans (aka ElectronAsh/OzOnE) and
//  Kitrinx
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
module IronHorse
(
	input                reset,
	input                clk_49m,  //Actual frequency: 49.152MHz
	input          [1:0] coin,
	input          [1:0] btn_start, //1 = Player 2, 0 = Player 1
	input          [3:0] p1_joystick, p2_joystick, //3 = down, 2 = up, 1 = right, 0 = left
	input          [2:0] p1_buttons, p2_buttons,   //3 buttons per player
	input                btn_service,
	input         [23:0] dipsw,
	
	//The following flag is used to reconfigure the 005885s' video timings and logic for drawing sprites to
	//reproduce the errors found on bootleg Iron Horse PCBs (this is a 2-bit signal to reconfigure the 005885s
	//depending on which game's bootleg ROM sets are loaded)
	input          [1:0] is_bootleg,
	
	//This input serves to select a fractional divider to acheive 3.072MHz for the YM2203 depending on whether Iron Horse
	//runs with original or underclocked timings to normalize sync frequencies
	input                underclock,
	
	//Screen centering (alters HSync and VSync timing in the primary Konami 005885 to reposition the video output)
	input          [3:0] h_center, v_center,
	
	output               video_hsync, video_vsync, video_csync,
	output               video_vblank, video_hblank,
	output         [3:0] video_r, video_g, video_b,	
	output signed [15:0] sound,

	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,
	
	input                pause,
`ifdef MISTER_HISCORE
	input         [11:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write_enable,
	input                hs_access_read,
	input                hs_access_write,
`endif

	//SDRAM signals
	output reg    [15:0] main_cpu_rom_addr,
	input          [7:0] main_cpu_rom_do,
	output reg    [14:0] sub_cpu_rom_addr,
	input          [7:0] sub_cpu_rom_do,
	output reg    [15:1] char1_rom_addr,
	input         [15:0] char1_rom_do,
	output               sp1_req,
	input                sp1_ack,
	output        [15:1] sp1_rom_addr,
	input         [15:0] sp1_rom_do
);

//------------------------------------------------- MiSTer data write selector -------------------------------------------------//

//Instantiate MiSTer data write selector to generate write enables for loading ROMs into the FPGA's BRAM
wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i, ep6_cs_i, ep7_cs_i;
wire prom1_cs_i, prom2_cs_i, prom3_cs_i, prom4_cs_i, prom5_cs_i;
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
	.prom1_cs(prom1_cs_i),
	.prom2_cs(prom2_cs_i),
	.prom3_cs(prom3_cs_i),
	.prom4_cs(prom4_cs_i),
	.prom5_cs(prom5_cs_i)
);

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 6.144MHz and (inverted) 3.072MHz clock enables (clock division is normally handled inside the Konami 005885)
//Also generate an extra clock enable for DC offset removal in the sound section
reg [6:0] div = 7'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 7'd1;
end
wire cen_6m = !div[2:0];
wire cen_3m = !div[3:0];
wire dcrm_cen = !div;

//Phase generator for MC6809E (taken from MiSTer Vectrex core)
//Normally handled internally on the Konami 005885
reg E = 0;
reg Q = 0;
always_ff @(posedge clk_49m) begin
	reg [1:0] clk_phase = 0;
	E <= 0;
	Q <= 0;
	if(cen_6m) begin
		clk_phase <= clk_phase + 1'd1;
		case(clk_phase)
			2'b01: Q <= 1;
			2'b10: E <= 1;
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

//------------------------------------------------------------ CPUs ------------------------------------------------------------//

//Main CPU (Motorola MC6809E - uses synchronous version of Greg Miller's cycle-accurate MC6809E made by Sorgelig)
wire [15:0] mc6809e_A;
wire [7:0] mc6809e_Din, mc6809e_Dout;
wire mc6809e_rw;
mc6809is u13A
(
	.CLK(clk_49m),
	.fallE_en(E),
	.fallQ_en(Q),
	.D(mc6809e_Din),
	.DOut(mc6809e_Dout),
	.ADDR(mc6809e_A),
	.RnW(mc6809e_rw),
	.nIRQ(irq),
	.nFIRQ(firq),
	.nNMI(nmi),
	.nHALT(pause),	 
	.nRESET(reset),
	.nDMABREQ(1)
);
//Address decoding for data inputs to MC6809E
wire cs_k005885 = (mc6809e_A[15:14] == 2'b00);
wire cs_soundlatch = ~nioc & (mc6809e_A[10:8] == 3'b000) & ~mc6809e_rw;
wire cs_dip3 = ~nioc & (mc6809e_A[10:8] == 3'b001) & mc6809e_rw;
wire sirq_trigger = ~nioc & (mc6809e_A[10:8] == 3'b001) & ~mc6809e_rw;
wire cs_dip2 = ~nioc & (mc6809e_A[10:8] == 3'b010) & mc6809e_rw;
wire cs_palettelatch = ~nioc & (mc6809e_A[10:8] == 3'b010) & ~mc6809e_rw;
wire cs_controls_dip1 = ~nioc & (mc6809e_A[10:8] == 3'b011) & mc6809e_rw;
wire cs_rom1 = (mc6809e_A[15:14] == 2'b01 || mc6809e_A[15:14] == 2'b10) & mc6809e_rw;
wire cs_rom2 = (mc6809e_A[15:14] == 2'b11 & mc6809e_rw);
//Multiplex data inputs to main CPU
assign mc6809e_Din =
	(cs_k005885 & nioc) ? k005885_Dout:
	cs_dip3             ? {4'hF, dipsw[19:16]}:
	cs_dip2             ? dipsw[15:8]:
	cs_controls_dip1    ? controls_dip1:
	cs_rom1             ? eprom1_D:
	cs_rom2             ? eprom2_D:
	8'hFF;

//Game ROMs
`ifdef EXT_ROM
always_ff @(posedge clk_49m)
	if (|mc6809e_A[15:14] & mc6809e_rw)
		main_cpu_rom_addr <= mc6809e_A[15:0] - 16'h4000;

wire [7:0] eprom1_D = main_cpu_rom_do;
wire [7:0] eprom2_D = main_cpu_rom_do;
`else
wire [7:0] eprom1_D;
eprom_1 u13C
(
	.ADDR({~mc6809e_A[14], mc6809e_A[13:0]}),
	.CLK(clk_49m),
	.DATA(eprom1_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep1_cs_i),
	.WR(ioctl_wr)
);
wire [7:0] eprom2_D;
eprom_2 u12C
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
wire [2:0] FA = pal_latch[2:0];

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
		if(sirq_trigger)
			sound_irq <= 1;
		else
			sound_irq <= 0;
	end
end

//Sound CPU - Zilog Z80 (uses T80s variant of the T80 soft core)
wire z80_n_m1, z80_n_mreq, z80_n_iorq, z80_n_rfsh, z80_n_rd, z80_n_wr;
wire [15:0] z80_A;
wire [7:0] z80_Din, z80_Dout;
T80s u9A
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
//Multiplex data inputs to sound CPU
assign z80_Din =
	soundrom_cs               ? eprom3_D:
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
eprom_3 u10C
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
spram #(8, 11) u11C
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
wire [7:0] controls_dip1 = (mc6809e_A[1:0] == 2'b00) ? dipsw[7:0]:
                           (mc6809e_A[1:0] == 2'b01) ? {1'b1, p1_buttons[2], p2_buttons[1:0], p2_joystick}:
                           (mc6809e_A[1:0] == 2'b10) ? {1'b1, p2_buttons[2], p1_buttons[1:0], p1_joystick}:
                           (mc6809e_A[1:0] == 2'b11) ? {3'b111, btn_start, btn_service, coin}:
                           8'hFF;

//--------------------------------------------------- Video timing & graphics --------------------------------------------------//

//Konami 005885 custom chip - this is a large ceramic pin-grid array IC responsible for the majority of Iron Horse's critical
//functions: IRQ generation, clock dividers and all video logic for generating tilemaps and sprites
wire [15:0] gfxrom_A, sprites_A;
//wire [12:0] vram_A;
//wire [7:0] vram_Din, vram_Dout;
//wire n_vram_oe, n_vram_we;
wire [7:0] k005885_Dout, tilemap_lut_A, sprite_lut_A;
wire [4:0] color_A;
wire tile_attrib_D5, firq, irq, nmi, nioc;
k005885 u11D
(
	.CK49(clk_49m),
	.NRD(~mc6809e_rw),
	.A(mc6809e_A[13:0]),
	.DBi(mc6809e_Dout),
	.DBo(k005885_Dout),
	.R(gfxrom_A),
	.RDU(tiles_D[15:8]),
	.RDL(tiles_D[7:0]),
	.S(sprites_A),
	.S_req(sp1_req),
	.S_ack(sp1_ack),
	.SDU(sprites_D[15:8]),
	.SDL(sprites_D[7:0]),
	.VCF(tilemap_lut_A[7:4]),
	.VCB(tilemap_lut_A[3:0]),
	.VCD(tilemap_lut_D),
	.OCF(sprite_lut_A[7:4]),
	.OCB(sprite_lut_A[3:0]),
	.OCD(sprite_lut_D),
	.COL(color_A),
	.NEXR(reset),
	.NXCS(~cs_k005885),
	.NCSY(video_csync),
	.NHSY(video_hsync),
	.NVSY(video_vsync),
	.HBLK(video_hblank),
	.VBLK(video_vblank),
	.NFIR(firq),
	.NIRQ(irq),
	.NNMI(nmi),
	.NIOC(nioc),
	.ATR5(tile_attrib_D5),
	.HCTR(h_center),
	.VCTR(v_center),
	.BTLG(is_bootleg)
`ifdef MISTER_HISCORE
	,
	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write_enable(hs_write_enable),
	.hs_access_read(hs_access_read),
	.hs_access_write(hs_access_write)
`endif
	
);

//Graphics ROMs
always_ff @(posedge clk_49m)
	char1_rom_addr <= {gfxrom_A[14], tile_attrib_D5, gfxrom_A[12:0]};
assign sp1_rom_addr = sprites_A[14:0];

`ifdef EXT_ROM
wire [7:0] eprom4_D = sp1_rom_do[15:8];
wire [7:0] eprom5_D = sp1_rom_do[7:0];
wire [7:0] eprom6_D = char1_rom_do[15:8];
wire [7:0] eprom7_D = char1_rom_do[7:0];
`else
wire [7:0] eprom4_D, eprom5_D;
eprom_4 u8F
(
	.ADDR(sprites_A[14:0]),
	.CLK(~clk_49m),
	.DATA(eprom4_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep4_cs_i),
	.WR(ioctl_wr)
);
eprom_5 u7F
(
	.ADDR(sprites_A[14:0]),
	.CLK(~clk_49m),
	.DATA(eprom5_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep5_cs_i),
	.WR(ioctl_wr)
);

wire [7:0] eprom6_D, eprom7_D;
eprom_6 u9F
(
	.ADDR({gfxrom_A[14], tile_attrib_D5, gfxrom_A[12:0]}),
	.CLK(clk_49m),
	.DATA(eprom6_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep6_cs_i),
	.WR(ioctl_wr)
);
eprom_7 u6F
(
	.ADDR({gfxrom_A[14], tile_attrib_D5, gfxrom_A[12:0]}),
	.CLK(clk_49m),
	.DATA(eprom7_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep7_cs_i),
	.WR(ioctl_wr)
);
`endif

//Combine graphics ROM data outputs to 16 bits
wire [15:0] tiles_D = {eprom6_D, eprom7_D};
wire [15:0] sprites_D = {eprom4_D, eprom5_D};

//Tilemap LUT PROM
wire [3:0] tilemap_lut_D;
prom_4 u11F
(
	.ADDR(tilemap_lut_A),
	.CLK(clk_49m),
	.DATA(tilemap_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom4_cs_i),
	.WR(ioctl_wr)
);

//Sprite LUT PROM
wire [3:0] sprite_lut_D;
prom_5 u10F
(
	.ADDR(sprite_lut_A),
	.CLK(clk_49m),
	.DATA(sprite_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom5_cs_i),
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

jt03 u6D
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

//Iron Horse's video output is straightforward: three color LUT PROMs, one per color, 12-bit RGB with 4 bits per color
prom_1 u3F
(
	.ADDR({FA, color_A}),
	.CLK(clk_49m),
	.DATA(video_r),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom1_cs_i),
	.WR(ioctl_wr)
);
prom_2 u4F
(
	.ADDR({FA, color_A}),
	.CLK(clk_49m),
	.DATA(video_g),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom2_cs_i),
	.WR(ioctl_wr)
);
prom_3 u5F
(
	.ADDR({FA, color_A}),
	.CLK(clk_49m),
	.DATA(video_b),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom3_cs_i),
	.WR(ioctl_wr)
);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//Iron Horse uses a 4.823KHz low-pass filter for the FM side of its YM2203 - filter the audio accordingly here.
wire signed [15:0] ym2203_fm_lpf;
ironhorse_fm_lpf lpf_fm
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ym2203_fm_raw),
	.out(ym2203_fm_lpf)
);

//Iron Horse also uses 3 switchable low-pass filters on the SSG side of its YM2203 with a cutoff frequency of
//723.432Hz (actually closer to 492.130Hz due to internal resistance inside the 74HC4066 handling the filter switching).
//Model the switchable filters here.
wire signed [15:0] ym2203_ssgA_lpf, ym2203_ssgB_lpf, ym2203_ssgC_lpf;
ironhorse_ssg_lpf lpf_ssgA
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ym2203_ssgA_dcrm),
	.out(ym2203_ssgA_lpf)
);
ironhorse_ssg_lpf lpf_ssgB
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ym2203_ssgB_dcrm),
	.out(ym2203_ssgB_lpf)
);
ironhorse_ssg_lpf lpf_ssgC
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
assign sound = (ym2203_fm_lpf + (ym2203_ssgA * 15'd24) + (ym2203_ssgB * 15'd24) + (ym2203_ssgC * 15'd24)) <<< 15'd1;

endmodule

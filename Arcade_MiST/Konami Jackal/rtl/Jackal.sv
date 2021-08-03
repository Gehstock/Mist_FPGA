//============================================================================
// 
//  Jackal PCB model
//  Copyright (C) 2020, 2021 Ace, brknglass, Ash Evans (aka ElectronAsh/OzOnE),
//  Shane Lynch, JimmyStones and Kitrinx (aka Rysha)
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
module Jackal
(
	input                reset,
	input                clk_49m,  //Actual frequency: 49.152MHz
	input          [1:0] coins,
	input                btn_service,
	input          [1:0] btn_start, //1 = Player 2, 0 = Player 1
	input          [3:0] p1_joystick, p2_joystick, //3 = down, 2 = up, 1 = right, 0 = left
	input          [7:0] p1_rotary, p2_rotary,
	input          [1:0] p1_buttons, p2_buttons,   //2 buttons per player
	
	input         [19:0] dipsw,
	
	//The following flag is used to reconfigure the 005885s' video timings, logic for drawing sprites and audio
	//filtering to reproduce the errors found on bootleg Jackal PCBs (this is a 2-bit signal to reconfigure the
	//005885s depending on which game's bootleg ROM sets are loaded)
	input          [1:0] is_bootleg,
	
	//Screen centering (alters HSync and VSync timing in the primary Konami 005885 to reposition the video output)
	input          [3:0] h_center, v_center,
	
	output signed [15:0] sound_l, sound_r,
	output               video_hsync, video_vsync,
	output               video_csync, //CSync not needed for MiSTer
	output               video_vblank, video_hblank,
	output         [4:0] video_r, video_g, video_b,

	input                ioctl_clk,
	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,
	
	input                pause,

	input         [12:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write,
	input                hs_access,

	//SDRAM signals
	output reg    [16:0] main_cpu_rom_addr,
	input          [7:0] main_cpu_rom_do,
	output reg    [14:0] sub_cpu_rom_addr,
	input          [7:0] sub_cpu_rom_do,
	output reg    [16:1] char1_rom_addr,
	input         [15:0] char1_rom_do,
	output reg    [16:1] char2_rom_addr,
	input         [15:0] char2_rom_do,
	output               sp1_req,
	input                sp1_ack,
	output        [16:1] sp1_rom_addr,
	input         [15:0] sp1_rom_do,
	output               sp2_req,
	input                sp2_ack,
	output        [16:1] sp2_rom_addr,
	input         [15:0] sp2_rom_do
);

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 6.144MHz and 3.072MHz clock enables (clock division is normally handled inside the primary Konami 005885)
reg [3:0] div = 4'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 4'd1;
end

wire cen_6m = !div[2:0];
wire n_cen_6m = div[2:0] == 3'b100;
wire cen_3m = !div;

//Phase generator for MC6809E (taken from MiSTer Vectrex core)
//Normally handled internally on the primary Konami 005885
reg mE = 0;
reg mQ = 0;
reg sE = 0;
reg sQ = 0;
always_ff @(posedge clk_49m) begin
	reg [1:0] clk_phase = 0;
	mE <= 0;
	mQ <= 0;
	sE <= 0;
	sQ <= 0;
	if(cen_6m) begin
		clk_phase <= clk_phase + 1'd1;
		case(clk_phase)
			2'b00: sE <= 1;
			2'b01: mE <= 1;
			2'b10: sQ <= 1;
			2'b11: mQ <= 1;
		endcase
	end
end

//Fractional divider to obtain sound clock (implementation by Jotego as part of JTFRAME)
//The PCB uses a 3.579545MHz oscillator directly connected to its YM2151 - this fractional divider replaces it as 3.579545MHz is
//not divisible by any integer factor of the main clock
//Also use this divider to generate a clock enable for jt49_dcrm2 to high-pass filter the YM2151's sound for original Jackal ROM
//sets
wire cen_3m58, cen_1m79;
wire cen_dcrm;
jtframe_frac_cen #(4) jt51_cen
(
	.clk(clk_49m),
	.n(10'd60),
	.m(10'd824),
	.cen({cen_dcrm, 1'bZ, cen_1m79, cen_3m58})
);

//------------------------------------------------------------ CPUs ------------------------------------------------------------//

//Main CPU (Motorola MC6809E - uses synchronous version of Greg Miller's cycle-accurate MC6809E made by Sorgelig)
wire maincpu_rw;
wire [15:0] maincpu_A;
wire [7:0] maincpu_Din, maincpu_Dout;

mc6809is u16A
(
	.CLK(clk_49m),
	.fallE_en(mE),
	.fallQ_en(mQ),
	.D(maincpu_Din),
	.DOut(maincpu_Dout),
	.ADDR(maincpu_A),
	.RnW(maincpu_rw),
	.nIRQ(irq),
	.nFIRQ(1),
	.nNMI(1),
	.nHALT(pause), 
	.nRESET(reset),
	.nDMABREQ(1)
);
//Address decoding for data inputs to Main CPU
wire cs_controls_dip1_dip3 = ~n_iocs & (maincpu_A[3:2] == 2'b00) & maincpu_rw;
wire cs_rotary = ~n_iocs & (maincpu_A[3:2] == 2'b01) & maincpu_rw;
wire cs_dip2 = ~n_iocs & (maincpu_A[3:2] == 2'b10) & maincpu_rw;
wire cs_bankswitch = ~n_iocs & (maincpu_A[3:2] == 2'b11) & ~maincpu_rw;
wire cs_mainsharedram = (maincpu_A >= 16'h0060 & maincpu_A <= 16'h1FFF);
wire cs_eprom1 = (maincpu_A[15:14] == 2'b01 | maincpu_A[15:14] == 2'b10) & maincpu_rw;
wire cs_eprom2 = (maincpu_A[15:14] == 2'b11 & maincpu_rw);
//Some of Jackal's address decoding logic is implemented in a PAL chip marked by Konami as the 007343 - instantiate an
//implementation of this IC here
wire n_cs_main_k005885, n_cs_sec_k005885, n_iocs;
k007343 u12D
(
	.A4(maincpu_A[4]),
	.A5(maincpu_A[5]),
	.A6(maincpu_A[6]),
	.A7(maincpu_A[7]),
	.A8_9(maincpu_A[8] | maincpu_A[9]),
	.A10(maincpu_A[10]),
	.A11(maincpu_A[11]),
	.A12(maincpu_A[12]),
	.A13(maincpu_A[13]),
	.WR(maincpu_rw),
	.OBJB(vram_bank),
	.GATEB(zram_bank),
	.GATECS(maincpu_A[15:14] != 2'b00),
	.MGCS(n_cs_main_k005885),
	.SGCS(n_cs_sec_k005885),
	.IOCS(n_iocs)
	//.CRCS
);
//Multiplex data inputs to main CPU
assign maincpu_Din = (~n_cs_main_k005885 & maincpu_rw) ? main_k005885_Dout:
                     (~n_cs_sec_k005885 & maincpu_rw)  ? sec_k005885_Dout:
                     cs_controls_dip1_dip3             ? controls_dip1_dip3:
                     cs_rotary                         ? rotary:
                     cs_dip2                           ? dipsw[15:8]:
                     (cs_mainsharedram & maincpu_rw)   ? m_sharedram_D:
                     cs_eprom1                         ? eprom1_D:
                     cs_eprom2                         ? eprom2_D:
                     8'hFF;

//Primary game ROM
always @(posedge clk_49m)
	if (|maincpu_A[15:14] & maincpu_rw)
		main_cpu_rom_addr <= {maincpu_A[15:14] == 2'b11, maincpu_A[15:14] != 2'b11 & eprom1_bank, ~maincpu_A[14], maincpu_A[13:0]};

wire [7:0] eprom1_D = main_cpu_rom_do;
//Secondary game ROM
wire [7:0] eprom2_D = main_cpu_rom_do;

//Bankswitching for primary game ROM, ZRAM + VRAM and sprite RAM
reg eprom1_bank = 0;
reg zram_bank = 0;
reg vram_bank = 0;
always_ff @(posedge clk_49m) begin
	if(!reset) begin
		eprom1_bank <= 0;
		zram_bank <= 0;
		vram_bank <= 0;
	end
	else if(cen_3m) begin
		if(cs_bankswitch) begin
			eprom1_bank <= maincpu_Dout[5];
			zram_bank <= maincpu_Dout[4];
			vram_bank <= maincpu_Dout[3];
		end
	end
end

// Hiscore mux
wire [12:0] u14B_addr = hs_access ? hs_address[12:0] : maincpu_A[12:0];
wire [7:0] u14B_din = hs_access ? hs_data_in : maincpu_Dout;
wire u14B_wren = hs_access ? hs_write : (cs_mainsharedram & ~maincpu_rw);
wire [7:0] u14B_dout;
assign m_sharedram_D = hs_access ? 8'h00 : u14B_dout;
assign hs_data_out = hs_access ? u14B_dout : 8'h00;

//Shared RAM
wire [7:0] m_sharedram_D, s_sharedram_D;
dpram_dc #(.widthad_a(13)) u14B
(
	.clock_a(clk_49m),
	.address_a(u14B_addr),
	.data_a(u14B_din),
	.q_a(u14B_dout),
	.wren_a(u14B_wren),

	.clock_b(clk_49m),
	.address_b(soundcpu_A[12:0]),
	.data_b(soundcpu_Dout),
	.q_b(s_sharedram_D),
	.wren_b(cs_soundsharedram & ~soundcpu_rw)
);

//Secondary CPU (Motorola MC6809E - uses synchronous version of Greg Miller's cycle-accurate MC6809E made by Sorgelig)
wire soundcpu_rw;
wire [15:0] soundcpu_A;
wire [7:0] soundcpu_Din, soundcpu_Dout;

mc6809is u11A
(
	.CLK(clk_49m),
	.fallE_en(sE),
	.fallQ_en(sQ),
	.D(soundcpu_Din),
	.DOut(soundcpu_Dout),
	.ADDR(soundcpu_A),
	.RnW(soundcpu_rw),
	.nIRQ(1),
	.nFIRQ(1),
	.nNMI(irq),
	.nHALT(1),	 
	.nRESET(reset),
	.nDMABREQ(1)
);
//Address decoding for data inputs to sound CPU
wire cs_ym2151 = (soundcpu_A[15:13] == 3'b001);
wire cs_k007327 = (soundcpu_A[15:13] == 3'b010);
wire cs_soundsharedram = (soundcpu_A[15:13] == 3'b011);
wire cs_eprom3 = (soundcpu_A[15] & soundcpu_rw);
//Multiplex data inputs to sound CPU
assign soundcpu_Din = (cs_ym2151 & soundcpu_rw)         ? ym2151_Dout:
                      (cs_k007327 & soundcpu_rw)        ? k007327_D:
                      (cs_soundsharedram & soundcpu_rw) ? s_sharedram_D:
                      cs_eprom3                         ? eprom3_D:
                      8'hFF;

//Sound ROM
always @(posedge clk_49m)
	if (cs_eprom3) sub_cpu_rom_addr <= soundcpu_A[14:0];

wire [7:0] eprom3_D = sub_cpu_rom_do;
//--------------------------------------------------- Controls & DIP switches --------------------------------------------------//

//Multiplex player inputs with DIP switch banks 1 and 3
wire [7:0] controls_dip1_dip3 = maincpu_A[1:0] == 2'b00 ? dipsw[7:0]:
                                maincpu_A[1:0] == 2'b01 ? {dipsw[19], 1'b1, p1_buttons, p1_joystick}:
                                maincpu_A[1:0] == 2'b10 ? {2'b1, p2_buttons, p2_joystick}:
                                maincpu_A[1:0] == 2'b11 ? {dipsw[18:16], btn_start[1:0], btn_service, coins}:
                                8'hFF;

//Multiplex rotary controls for supported ROM sets
wire [7:0] rotary = maincpu_A[1:0] == 2'b00 ? p1_rotary:
                    maincpu_A[1:0] == 2'b01 ? p2_rotary:
                    8'hFF;

//--------------------------------------------------- Video timing & graphics --------------------------------------------------//

//Konami 005885 custom chip - this is a large ceramic pin-grid array IC responsible for the majority of Jackal's critical
//functions: IRQ generation, clock dividers and all video logic for generating tilemaps and sprites
//Jackal contains two of these in parallel - this instance is the primary tilemap generator
wire [15:0] gfxrom0_Atile, gfxrom0_Asprite;
wire [7:0] main_k005885_Dout;
wire [4:0] main_color;
wire [3:0] main_tile_data; //Jackal does not use a lookup table for tiles; tile data is fed back to the 005885 directly
wire [3:0] ocf0, ocb0;
wire tile_attrib_D4, tile_attrib_D5;
wire e, q, irq;
k005885 u11F
(
	.CK49(clk_49m),
	.NRD(~maincpu_rw),
	.A(maincpu_A[13:0]),
	.DBi(maincpu_Dout),
	.DBo(main_k005885_Dout),
	.R(gfxrom0_Atile),
	.RDU(gfxrom0_Dtile[15:8]),
	.RDL(gfxrom0_Dtile[7:0]),
	.S(gfxrom0_Asprite),
	.S_req(sp1_req),
	.S_ack(sp1_ack),
	.SDU(gfxrom0_Dsprite[15:8]),
	.SDL(gfxrom0_Dsprite[7:0]),
	.VCB(main_tile_data),
	.VCD(main_tile_data),
	.OCF(ocf0),
	.OCB(ocb0),
	.OCD(prom1_D),
	.COL(main_color),
	.NEXR(reset),
	.NXCS(n_cs_main_k005885),
	.NCSY(video_csync),
	.NHSY(video_hsync),
	.NVSY(video_vsync),
	.HBLK(video_hblank),
	.VBLK(video_vblank),
	.NCPE(e),
	.NCPQ(q),
	.NIRQ(irq),
	.ATR4(tile_attrib_D4),
	.ATR5(tile_attrib_D5),
	.HCTR(h_center),
	.VCTR(v_center),
	.BTLG(is_bootleg)
);

//Graphics ROMs for primary 005885 tilemap generator (sprites only)
assign sp1_rom_addr = gfxrom0_Asprite[15:0];
wire [15:0] gfxrom0_Dsprite = sp1_rom_do;
//Sprite LUT PROM for primary 005885 tilemap generator
wire [3:0] prom1_D;
wire       prom1_cs_i = ioctl_addr[24:8] == 16'h0A00;
dpram_dc #(.widthad_a(8)) u9H
(
	.clock_a(clk_49m),
	.address_a({ocf0, ocb0}),
	.q_a(prom1_D),

	.clock_b(ioctl_clk),
	.address_b(ioctl_addr[7:0]),
	.data_b(ioctl_data),
	.wren_b(prom1_cs_i & ioctl_wr)
);

//Konami 005885 custom chip - this is a large ceramic pin-grid array IC responsible for the majority of Jackal's critical
//functions: IRQ generation, clock dividers and all video logic for generating tilemaps and sprites
//Jackal contains two of these in parallel - this instance is the secondary tilemap generator
wire [15:0] gfxrom1_Atile, gfxrom1_Asprite;
wire [7:0] sec_k005885_Dout;
wire [4:0] sec_color;
wire [3:0] sec_tile_data; //Jackal does not use a lookup table for tiles; tile data is fed back to the 005885 directly
wire [3:0] ocf1, ocb1;
k005885 u14F
(
	.CK49(clk_49m),
	.NRD(~maincpu_rw),
	.A(maincpu_A[13:0]),
	.DBi(maincpu_Dout),
	.DBo(sec_k005885_Dout),
	.R(gfxrom1_Atile),
	.RDU(gfxrom1_Dtile[15:8]),
	.RDL(gfxrom1_Dtile[7:0]),
	.S(gfxrom1_Asprite),
	.S_req(sp2_req),
	.S_ack(sp2_ack),
	.SDU(gfxrom1_Dsprite[15:8]),
	.SDL(gfxrom1_Dsprite[7:0]),
	.VCB(sec_tile_data),
	.VCD(sec_tile_data),
	.OCF(ocf1),
	.OCB(ocb1),
	.OCD(prom2_D),
	.COL(sec_color),
	.NEXR(reset),
	.NXCS(n_cs_sec_k005885),
	.BTLG(is_bootleg)
);

//Graphics ROMs for secondary 005885 tilemap generator (sprites only)
assign sp2_rom_addr = gfxrom1_Asprite[15:0];
wire [15:0] gfxrom1_Dsprite = sp2_rom_do;

//Graphics ROMs (tilemaps only) for both 005885 tilemap generators (accessed externally from SDRAM)
wire [15:0] gfxrom0_Dtile, gfxrom1_Dtile;

always_ff @(posedge clk_49m) begin
	char1_rom_addr <= {tile_attrib_D5, tile_attrib_D4, gfxrom0_Atile[13:0]};
	char2_rom_addr <= {tile_attrib_D5, tile_attrib_D4, gfxrom1_Atile[13:0]};
end

assign gfxrom0_Dtile = char1_rom_do;
assign gfxrom1_Dtile = char2_rom_do;

//Sprite LUT PROM for secondary 005885 tilemap generator
wire [3:0] prom2_D;
wire       prom2_cs_i = ioctl_addr[24:8] == 16'h0A01;
dpram_dc #(.widthad_a(8)) u14H
(
	.clock_a(clk_49m),
	.address_a({ocf1, ocb1}),
	.q_a(prom2_D),

	.clock_b(ioctl_clk),
	.address_b(ioctl_addr[7:0]),
	.data_b(ioctl_data),
	.wren_b(prom2_cs_i & ioctl_wr)
);

//--------------------------------------------------------- Sound chip ---------------------------------------------------------//

//Sound chip - Yamaha YM2151 (uses JT51 implementation by Jotego)
wire [7:0] ym2151_Dout;
wire signed [15:0] sound_l_raw, sound_r_raw;
wire [15:0] unsgined_sound_l_raw, unsgined_sound_r_raw;
jt51 u8C
(
	.rst(~reset),
	.clk(clk_49m),
	.cen(cen_3m58),
	.cen_p1(cen_1m79),
	.cs_n(~cs_ym2151),
	.wr_n(soundcpu_rw),
	.a0(soundcpu_A[0]),
	.din(soundcpu_Dout),
	.dout(ym2151_Dout),
	.xleft(sound_l_raw),
	.xright(sound_r_raw),
	.dacleft(unsgined_sound_l_raw),
	.dacright(unsgined_sound_r_raw)
);

//----------------------------------------------------- Final video output -----------------------------------------------------//

//Multiplex color data from tilemap generators for color RAM
wire color_sel = (main_color[4] & sec_color[4]);
wire [3:0] color_mux = main_color[4] ? sec_color[3:0] : main_color[3:0];
wire [7:0] color_bus = color_sel ? {main_color[3:0], sec_color[3:0]} : {3'b000, main_color[4], color_mux};

//Write enable logic for palette RAM
reg n_sQ_lat = 1;
wire n_sQlat_clr = (e & ~soundcpu_rw);
always_ff @(posedge clk_49m or negedge n_sQlat_clr) begin
	if(!n_sQlat_clr)
		n_sQ_lat <= 1;
	else if(cen_6m)
		n_sQ_lat <= ~q;
end
wire n_k007327_we = (~cs_k007327 | n_sQ_lat);

//Multiplex the upper 4 address lines of palette RAM
wire [11:8] ra = cs_k007327 ? soundcpu_A[11:8] : {2'b00, color_sel, color_bus[7]};

//Blank input to palette RAM (black out the signal when all but the uppermost bit of each 005885's color outputs
//are all set to 0)
//This signal does not exist on bootleg Jackal PCBs
wire blank = (is_bootleg == 2'b01) ? 1'b1 : ((|main_color[3:0]) | (|sec_color[3:0]));

//Konami 007327 custom module - integrates palette RAM along with its multiplexing and write enable logic (multiplexing
//logic only covers bits [7:0], the others are generated externally)
//This module normally is analog-only as it also integrates the video DAC - for this FPGA implementation of Jackal,
//the digital video data can be tapped directly
wire [7:0] k007327_D;
k007327 u1H
(
	.CLK(clk_49m),
	.CEN(n_cen_6m),
	.RA(ra),
	.A(soundcpu_A[7:0]),
	.NA0(~soundcpu_A[0]),
	.CB(color_bus[6:0]),
	.Di(soundcpu_Dout),
	.RW(~soundcpu_rw),
	.SEL(~cs_k007327),
	.CCS(~cs_k007327),
	.CWR(n_k007327_we),
	.BLK(blank),
	.R(video_r),
	.G(video_g),
	.B(video_b),
	.Do(k007327_D)
);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//The original Jackal PCB applies high-pass filtering at around 80Hz - use Jotego's jt49_dcrm2 module to apply this high-pass
//filtering with JT51's unsigned output
//TODO: Replace this with a proper high-pass filter
wire signed [15:0] sound_l_hpf, sound_r_hpf;
jt49_dcrm2 #(16) hpf_left
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din(unsigned_sound_l_atten),
	.dout(sound_l_hpf)
);
jt49_dcrm2 #(16) hpf_right
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din(unsigned_sound_r_atten),
	.dout(sound_r_hpf)
);

//Jackal produces sound out of the YM2151 at a significantly higher volume than most other games on the MiSTer platform - apply
//6dB attenuation for better balance with other cores
wire [15:0] unsigned_sound_l_atten = unsgined_sound_l_raw >> 1;
wire [15:0] unsigned_sound_r_atten = unsgined_sound_r_raw >> 1;
wire signed [15:0] sound_l_atten = sound_l_raw >>> 1;
wire signed [15:0] sound_r_atten = sound_r_raw >>> 1;

//Jackal employs a 4.823KHz low-pass filter for its YM2151 - filter the audio accordingly here and output the end result
//The original PCB also has a variable low-pass filter that applies heavier filtering the higher the volume is set - apply this
//extra low-pass filter when original ROMs are used (controlled by the is_bootleg flag - this filter and the 80Hz high-pass filter
//are absent on bootleg ROM sets)
jackal_lpf lpf_left
(
	.clk(clk_49m),
	.reset(~reset),
	.select(is_bootleg[0]),
	.in1(sound_l_atten),
	.in2(sound_l_hpf),
	.out(sound_l)
);
jackal_lpf lpf_right
(
	.clk(clk_49m),
	.reset(~reset),
	.select(is_bootleg[0]),
	.in1(sound_r_atten),
	.in2(sound_r_hpf),
	.out(sound_r)
);

endmodule

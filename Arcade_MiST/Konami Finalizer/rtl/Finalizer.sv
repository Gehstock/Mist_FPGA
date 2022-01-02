//============================================================================
// 
//  Finalizer PCB model
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
module Finalizer
(
	input                reset,
	input                clk_49m,  //Actual frequency: 49.152MHz
	input          [1:0] coin,
	input          [1:0] btn_start, //1 = Player 2, 0 = Player 1
	input          [3:0] p1_joystick, p2_joystick, //3 = down, 2 = up, 1 = right, 0 = left
	input          [1:0] p1_buttons, p2_buttons,   //2 buttons per player
	input                btn_service,
	input         [23:0] dipsw,
	
	//The following flag is used to reconfigure the clock division applied to the Konami SND01 sound chip
	//as while the original is clocked at 6.144MHz, bootleg boards clock this chip (replaced by a standard
	//NEC uPD8749 MCU) at 9.216MHz
	input          [1:0] is_bootleg,
	
	//Screen centering (alters HSync and VSync timing in the Konami 005885 to reposition the video output)
	input          [3:0] h_center, v_center,
	
	output               video_hsync, video_vsync, video_csync,
	output               video_vblank, video_hblank,
	output         [3:0] video_r, video_g, video_b,	
	output signed [15:0] sound,

	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,
	
	input                pause,

	input         [11:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write_enable,
	input                hs_access_read,
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

//------------------------------------------------- MiSTer data write selector -------------------------------------------------//

//Instantiate MiSTer data write selector to generate write enables for loading ROMs into the FPGA's BRAM
wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i, ep6_cs_i, ep7_cs_i, ep8_cs_i, ep9_cs_i, snd01_cs_i;
wire prom1_cs_i, prom2_cs_i, prom3_cs_i, prom4_cs_i;
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
	.snd01_cs(snd01_cs_i),
	.prom1_cs(prom1_cs_i),
	.prom2_cs(prom2_cs_i),
	.prom3_cs(prom3_cs_i),
	.prom4_cs(prom4_cs_i)
);

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 6.144MHz, 3.072MHz and 1.576MHz clock enables (clock division is normally handled inside the Konami 005885)
//Also generate an extra clock enable for DC offset removal in the sound section
reg [6:0] div = 7'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 7'd1;
end
wire cen_6m = !div[2:0];
wire cen_3m = !div[3:0];
wire cen_1m5 = !div[4:0];
wire dcrm_cen = !div;

//Phase generator for KONAMI-1 (taken from MiSTer Vectrex core)
//Normally handled internally on the Konami 005885
reg k1_E = 0;
reg k1_Q = 0;
always_ff @(posedge clk_49m) begin
	reg [1:0] clk_phase = 0;
	k1_E <= 0;
	k1_Q <= 0;
	if(cen_6m) begin
		clk_phase <= clk_phase + 1'd1;
		case(clk_phase)
			2'b01: k1_E <= 1;
			2'b10: k1_Q <= 1;
		endcase
	end
end

//Use Jotego's fractional clock divider to generate a 9.216MHz clock enable for the Konami SND01 custom chip (to be used by bootlegs
//only)
wire cen_9m;
jtframe_frac_cen #(2) snd01_cen
(
	.clk(clk_49m),
	.n(10'd48),
	.m(10'd256),
	.cen({1'bZ, cen_9m})
);

//Select whether to clock the SND01 at 6.144MHz or 9.216MHz depending on whether a bootleg ROM set is loaded
wire cen_snd01 = (is_bootleg == 2'b11) ? cen_9m : cen_6m;

//------------------------------------------------------------ CPUs ------------------------------------------------------------//

//Main CPU (KONAMI-1 custom encrypted MC6809E - uses synchronous version of Greg Miller's cycle-accurate MC6809E made by
//Sorgelig with a wrapper to decrypt XOR/XNOR-encrypted opcodes and a further modification to Greg's MC6809E to directly
//accept the opcodes)
wire k1_rw;
wire [15:0] k1_A;
wire [7:0] k1_Din, k1_Dout;
KONAMI1 u13A
(
	.CLK(clk_49m),
	.fallE_en(k1_E),
	.fallQ_en(k1_Q),
	.D(k1_Din),
	.DOut(k1_Dout),
	.ADDR(k1_A),
	.RnW(k1_rw),
	.nIRQ(k1_irq),
	.nFIRQ(k1_firq),
	.nNMI(k1_nmi),
	.nHALT(pause),
	.nRESET(reset)
);
//Address decoding for data inputs to KONAMI-1
wire cs_k005885 = (k1_A[15:14] == 2'b00);
wire cs_dip3 = ~nioc & (k1_A[4:3] == 2'b00) & k1_rw;
wire cs_dip2 = ~nioc & (k1_A[4:3] == 2'b01) & k1_rw;
wire cs_controls_dip1 = ~nioc & (k1_A[4:3] == 2'b10) & k1_rw;
wire cs_sn76489 = ~nioc & (k1_A[4:0] == 5'b11010) & ~k1_rw;
wire cs_sn76489_latch = ~nioc & (k1_A[4:0] == 5'b11011) & ~k1_rw;
wire cs_snd01_irq = ~nioc & (k1_A[4:0] == 5'b11100) & ~k1_rw;
wire cs_snd01_latch = ~nioc & (k1_A[4:0] == 5'b11101) & ~k1_rw;
wire cs_rom1 = (k1_A[15:14] == 2'b01 & k1_rw);
wire cs_rom2 = (k1_A[15:14] == 2'b10 & k1_rw);
wire cs_rom3 = (k1_A[15:14] == 2'b11 & k1_rw);
//Multiplex data inputs to KONAMI-1
assign k1_Din = (cs_k005885 & nioc) ? k005885_Dout:
                cs_dip3             ? {4'hF, dipsw[19:16]}:
                cs_dip2             ? dipsw[15:8]:
                cs_controls_dip1    ? controls_dip1:
                cs_rom1             ? eprom1_D:
                cs_rom2             ? eprom2_D:
                cs_rom3             ? eprom3_D:
                8'hFF;

//Game ROMs
`ifdef EXT_ROM
always_ff @(posedge clk_49m)
	if (|k1_A[15:14] & k1_rw)
		main_cpu_rom_addr <= k1_A[15:0] - 16'h4000;

wire [7:0] eprom1_D = main_cpu_rom_do;
wire [7:0] eprom2_D = main_cpu_rom_do;
wire [7:0] eprom3_D = main_cpu_rom_do;
`else
wire [7:0] eprom1_D, eprom2_D, eprom3_D;
eprom_1 u9C
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
eprom_2 u12C
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
eprom_3 u13C
(
	.ADDR(k1_A[13:0]),
	.CLK(clk_49m),
	.DATA(eprom3_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep3_cs_i),
	.WR(ioctl_wr)
);
`endif
//--------------------------------------------------- Controls & DIP switches --------------------------------------------------//

//Multiplex player inputs and DIP switch bank 1 (Finalizer also expects to receive a VBlank on bit 7 along with the start buttons,
//service credit and coin inputs - invert as the game expects an active low VBlank here)
wire [7:0] controls_dip1 = (k1_A[1:0] == 2'b00) ? {~video_vblank, 2'b11, btn_start, btn_service, coin}:
                           (k1_A[1:0] == 2'b01) ? {2'b11, p1_buttons, p1_joystick}:
                           (k1_A[1:0] == 2'b10) ? {2'b11, p2_buttons, p2_joystick}:
                           (k1_A[1:0] == 2'b11) ? dipsw[7:0]:
                           8'hFF;

//--------------------------------------------------- Video timing & graphics --------------------------------------------------//

//Konami 005885 custom chip - this is a large ceramic pin-grid array IC responsible for the majority of Finalizer's critical
//functions: IRQ generation, clock dividers and all video logic for generating tilemaps and sprites
wire [15:0] tiles_A, sprites_A;
wire [7:0] k005885_Dout, tilemap_lut_A, sprite_lut_A;
wire [4:0] color_A;
wire k1_firq, k1_irq, k1_nmi, nioc;
k005885 u11E
(
	.CK49(clk_49m),
	.NRD(~k1_rw),
	.A(k1_A[13:0]),
	.DBi(k1_Dout),
	.DBo(k005885_Dout),
	.R(tiles_A),
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
	.NFIR(k1_firq),
	.NIRQ(k1_irq),
	.NNMI(k1_nmi),
	.NIOC(nioc),
	.HCTR(h_center),
	.VCTR(v_center)
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
//Access tilemap ROMs for both the sprite and tilemap sections of the 005885 simultaneously as some of Finalizer's sprites fetch
//data from tilemap ROMs rather than sprite ROMs
//always_ff @(posedge clk_49m)
assign char1_rom_addr = tiles_A[13:0];
assign sp1_rom_addr = {sprites_A[15], ~sprites_A[15] & sprites_A[14], sprites_A[13:0]};
`ifdef EXT_ROM
wire [7:0] eprom4t_D = char1_rom_do[15:8];
wire [7:0] eprom4s_D = sp1_rom_do[15:8];
wire [7:0] eprom5t_D = char1_rom_do[7:0];
wire [7:0] eprom5s_D = sp1_rom_do[7:0];
wire [7:0] eprom6_D = sp1_rom_do[15:8];
wire [7:0] eprom7_D = sp1_rom_do[7:0];
wire [7:0] eprom8_D = sp1_rom_do[15:8];
wire [7:0] eprom9_D = sp1_rom_do[7:0];
`else
wire [7:0] eprom4t_D, eprom4s_D, eprom5t_D, eprom5s_D, eprom6_D, eprom7_D, eprom8_D, eprom9_D;
eprom_4 u5E
(
	.ADDR_A(sprites_A[13:0]),
	.CLK_A(~clk_49m),
	.DATAOUT_A(eprom4s_D),
	.ADDR_B(ep4_cs_i ? ioctl_addr : tiles_A[13:0]),
	.CLK_B(clk_49m),
	.DATA_IN(ioctl_data),
	.DATAOUT_B(eprom4t_D),
	.CS_DL(ep4_cs_i),
	.WR(ioctl_wr)
);
eprom_5 u5F
(
	.ADDR_A(sprites_A[13:0]),
	.CLK_A(~clk_49m),
	.DATAOUT_A(eprom5s_D),
	.ADDR_B(ep5_cs_i ? ioctl_addr : tiles_A[13:0]),
	.CLK_B(clk_49m),
	.DATA_IN(ioctl_data),
	.DATAOUT_B(eprom5t_D),
	.CS_DL(ep5_cs_i),
	.WR(ioctl_wr)
);
eprom_6 u6E
(
	.ADDR(sprites_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom6_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep6_cs_i),
	.WR(ioctl_wr)
);
eprom_7 u6F
(
	.ADDR(sprites_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom7_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep7_cs_i),
	.WR(ioctl_wr)
);
eprom_8 u7E
(
	.ADDR(sprites_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom8_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep8_cs_i),
	.WR(ioctl_wr)
);
eprom_9 u7F
(
	.ADDR(sprites_A[13:0]),
	.CLK(~clk_49m),
	.DATA(eprom9_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep9_cs_i),
	.WR(ioctl_wr)
);
`endif
//Combine graphics ROM data outputs to 16 bits and multiplex sprite data
reg [15:0] tiles_D, sprites_D;
always @(*) begin
	tiles_D <= {eprom4t_D, eprom5t_D};
	case(sprites_A[15:14])
		2'b00: sprites_D <= {eprom4s_D, eprom5s_D};
		2'b01: sprites_D <= {eprom6_D, eprom7_D};
		2'b10: sprites_D <= {eprom8_D, eprom9_D};
		2'b11: sprites_D <= {eprom8_D, eprom9_D};
	endcase
end

//Tilemap LUT PROM
wire [3:0] tilemap_lut_D;
prom_1 u11F
(
	.ADDR(tilemap_lut_A),
	.CLK(clk_49m),
	.DATA(tilemap_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom1_cs_i),
	.WR(ioctl_wr)
);

//Sprite LUT PROM
wire [3:0] sprite_lut_D;
prom_2 u10F
(
	.ADDR(sprite_lut_A),
	.CLK(clk_49m),
	.DATA(sprite_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom2_cs_i),
	.WR(ioctl_wr)
);

//--------------------------------------------------------- Sound chips --------------------------------------------------------//

//Generate chip enable for SN76489
wire n_sn76489_ce = (~cs_sn76489 & sn76489_ready);

//Latch data from KONAMI-1 to Konami SND01
reg [7:0] snd01_Din = 8'd0;
always_ff @(posedge clk_49m) begin
	if(cen_3m && cs_snd01_latch)
		snd01_Din <= k1_Dout;
end

//Latch data from KONAMI-1 to SN76489
reg [7:0] sn76489_D = 8'd0;
always_ff @(posedge clk_49m) begin
	if(cen_3m && cs_sn76489_latch)
		sn76489_D <= k1_Dout;
end

//Sound chip 1 (Texas Instruments SN76489 - uses Arnim Laeuger's SN76489 implementation with bugfixes)
wire [7:0] sn76489_raw;
wire sn76489_ready;
sn76489_top u7C
(
	.clock_i(clk_49m),
	.clock_en_i(cen_1m5),
	.res_n_i(reset),
	.ce_n_i(n_sn76489_ce),
	.we_n_i(sn76489_ready),
	.ready_o(sn76489_ready),
	.d_i(sn76489_D),
	.aout_o(sn76489_raw)
);

//Sound chip 2 (Konami SND01, a rebadged NEC uPD8749 MCU - uses a modified version of the t8049_notri variant of T48)
wire [7:0] snd01_raw;
wire [7:0] snd01_port2;
wire snd01_ale, n_snd01_psen, n_snd01_rd, n_snd01_irq_clr, snd01_timer_out;
t8049_notri u8A
(
	.xtal_i(clk_49m),
	.xtal_en_i(cen_snd01),
	.reset_n_i(reset),
	.t0_o(snd01_timer_out),
	.int_n_i(n_snd01_irq),
	.ea_i(0),
	.db_i(snd01_Din),
	.t1_i(snd01_timer_in),
	.p2_o(snd01_port2),
	.p1_o(snd01_raw),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(snd01_cs_i),
	.WR(ioctl_wr)
);
assign n_snd01_irq_clr = snd01_port2[7];

//Divide SND01 timer 0 output by 16 for the bootleg MCU timer and connect to the input of timer 1, otherwise pull this input low
reg [3:0] snd01_timer = 4'd0;
reg old_timer;
always_ff @(posedge clk_49m) begin
	old_timer <= snd01_timer_out;
	if(!old_timer && snd01_timer_out)
		snd01_timer <= snd01_timer + 4'd1;
end
wire snd01_timer_in = snd01_timer[3];

//Generate SND01 IRQ
reg n_snd01_irq = 1;
always_ff @(posedge clk_49m) begin
	if(!n_snd01_irq_clr)
		n_snd01_irq <= 1;
	else if(cen_3m && cs_snd01_irq)
		n_snd01_irq <= 0;
end

//----------------------------------------------------- Final video output -----------------------------------------------------//

//Finalzer's video output consists of two color LUT PROMs providing 12-bit RGB, 4 bits per color
prom_3 u2F
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA({video_g, video_r}),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom3_cs_i),
	.WR(ioctl_wr)
);
prom_4 u3F
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA({4'bZZZZ, video_b}),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(prom4_cs_i),
	.WR(ioctl_wr)
);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//Remove DC offset from SN76489 and SND01 and apply gain to both
wire signed [15:0] sn76489_gain, snd01_gain;
jt49_dcrm2 #(16) dcrm_sn76489
(
	.clk(clk_49m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({1'd0, sn76489_raw, 7'd0}),
	.dout(sn76489_gain)
);
jt49_dcrm2 #(16) dcrm_snd01
(
	.clk(clk_49m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({3'd0, snd01_raw, 5'd0}),
	.dout(snd01_gain)
);

//Finalizer - Super Transformation uses a 3.386KHz low-pass filter for its SN76489 - apply this filtering here
wire signed [15:0] sn76489_lpf;
finalizer_psg_lpf psg_lpf
(
	.clk(clk_49m),
	.reset(~reset),
	.in(sn76489_gain),
	.out(sn76489_lpf)
);

//Mix the low-pass filtered output of the SN76489 with the SND01 and apply an extra low-pass filter on the mixed output to minimze
//aliasing
wire signed [15:0] sound_mix = sn76489_lpf + snd01_gain;
wire signed [15:0] sound_mix_aa;
finalizer_lpf lpf
(
	.clk(clk_49m),
	.reset(~reset),
	.in(sound_mix),
	.out(sound_mix_aa)
);

//Output the anti-aliased audio signal (mute when game is paused)
assign sound = pause ? sound_mix_aa : 16'd0;

endmodule

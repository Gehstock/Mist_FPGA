//============================================================================
// 
//  Time Pilot '84 main PCB replica
//  Based on chip-level simulation model
//  Copyright (C) 2020 Ace
//
//  Completely rewritten using fully syncronous logic by Gyorgy Szombathelyi
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
`define EXT_ROM
//Module declaration, I/O ports
module TimePilot84_CPU
(
	input         reset,
	input         clk_49m, //Actual frequency: 49.152MHz
	output  [3:0] red, green, blue, //12-bit RGB, 4 bits per color
	output        video_hsync, video_vsync, video_csync, //CSync not needed for MISTer
	output        video_hblank, video_vblank,

	input   [7:0] sndbrd_D,
	output  [7:0] cpubrd_D,
	output        cpubrd_A5, cpubrd_A6,
	output        n_sda, n_son,
	output        in5, ioen,

	input         is_set3, //Flag to remap primary CPU address space for Time Pilot '84 Set 3

	input         ep1_cs_i,
	input         ep2_cs_i,
	input         ep3_cs_i,
	input         ep4_cs_i,
	input         ep5_cs_i,
	input         ep7_cs_i,
	input         ep8_cs_i,
	input         ep9_cs_i,
	input         ep10_cs_i,
	input         ep11_cs_i,
	input         ep12_cs_i,
	input         cp1_cs_i,
	input         cp2_cs_i,
	input         cp3_cs_i,
	input         cl_cs_i,
	input         sl_cs_i,
	input  [24:0] ioctl_addr,
	input   [7:0] ioctl_data,
	input         ioctl_wr,

	output [15:0] main_cpu_rom_addr,
	input   [7:0] main_cpu_rom_do,  
	output [12:0] sub_cpu_rom_addr,
	input   [7:0] sub_cpu_rom_do,
	output [12:0] char_rom_addr,
	input  [15:0] char_rom_do
);

wire n_res = reset;

assign main_cpu_rom_addr = mA[14:0];
assign sub_cpu_rom_addr = sA[12:0];
assign char_rom_addr = charrom_A;

//Assign active high HBlank and VBlank outputs
assign video_hblank = hblk;
assign video_vblank = vblk;

//Output IN5, IOEN to sound board
assign in5 = n_in5;
assign ioen = n_ioen;

//Output primary MC6809E address lines A5 and A6 to sound board
assign cpubrd_A5 = mA[5];
assign cpubrd_A6 = mA[6];

//Assign CPU board data output to sound board
assign cpubrd_D = mD_out;

//------------------------------------------------- Abstracted logic modelling -------------------------------------------------//

//Multiplex character and sprite ROM data outputs.
//The PCB connects these signals directly to the chip enable signals on the EPROMs at 2J (character) and 12A/13A (sprite) and
//invert them through one inverter at 6F (character) and 13F (sprite) for the second set of character ROMs (3J) and sprite
//ROMs (14A/15A).
`ifdef EXT_ROM
wire [7:0] charrom_D = ~n_charrom0_ce ? char_rom_do[7:0] : char_rom_do[15:8];
`else
wire [7:0] charrom_D = ~n_charrom0_ce ? eprom7_D : eprom8_D;
`endif

wire [15:0] spriterom_D = ~n_spriterom0_en ? {eprom11_D, eprom9_D} : {eprom12_D, eprom10_D};

//Generate HBlank (active high) while the horizontal counter is between 138 and 268
//While the Konami 082 custom chip generates VBlank, HBlank is generated externally using discrete logic, in this case, a
//combination of the 74LS74 at 4A and half of the 74LS74 at 4B
wire hblk = ({n_h256, h128, h64, h32, h16, h8, h4, h2, h1} > 137 && {n_h256, h128, h64, h32, h16, h8, h4, h2, h1} < 269);

//Output video signal from color PROMs, otherwise output black if in HBlank or VBlank
//This is normally achieved on the PCB by disabling the output of the 74LS157 at 3D when in HBlank and clearing the outputs of the
//74LS174 at 3C when in VBlank.
assign red = (hblk | vblk) ? 4'h0 : prom_red;
assign green = (hblk | vblk) ? 4'h0 : prom_green;
assign blue = (hblk | vblk) ? 4'h0 : prom_blue;


//Clock divider
//The PCB uses a 74LS107 located at 9A to divide 18.432MHz by 3 to obtain the required 6.144MHz pixel
//clock - this implementation replaces the 74LS107 by a 74LS163 to divide a faster 49.152MHz clock by
//4 for clocking PROMs and the sprite line buffer RAM at 12.288MHz and by 8 to obtain the 6.144MHz
//pixel clock
//reg clk_12m, pixel_clk;
reg clk_12m_en, pixel_clk_en;
reg [2:0] cnt;
always @(posedge clk_49m) begin
	cnt <= cnt+1'd1;

//	pixel_clk <= cnt[2];
//	clk_12m <= cnt[1];
	pixel_clk_en <= cnt == 3'b011;
	clk_12m_en <= cnt == 2'b01;
end
//wire clk1 = clk_12m;
//wire clk2 = pixel_clk;

//Konami 082 custom chip - responsible for all video timings
wire vblk, h1, h2, h4, h8, h16, h32, h64, h128, n_h256, v1, v2, v4, v8, v16, v32, v64, v128;
wire n_h256_en;
k082 u6A
(
	.reset(1'b1),
	.clk(clk_49m),
	.cen(pixel_clk_en),
	.n_vsync(video_vsync),
	.sync(video_csync),
	.n_hsync(video_hsync),
	.vblk(vblk),
	//The active-low VBlank output, n_vblk, is used by the PCB to clear the latch addressing the lower 4 bits of
	//the color PROMs at 3C but can be omitted from this implementation as blanking is handled differently to the PCB
	.h1(h1),
	.h2(h2),
	.h4(h4),
	.h8(h8),
	.h16(h16),
	.h32(h32),
	.h64(h64),
	.h128(h128),
	.n_h256(n_h256),
	.n_h256_en(n_h256_en),

	.v1(v1),
	.v2(v2),
	.v4(v4),
	.v8(v8),
	.v16(v16),
	.v32(v32),
	.v64(v64),
	.v128(v128)
);

//Latch vertical counter bits from 082 custom chip
wire [7:0] vcnt_lat;
always @(posedge clk_49m) if (n_h256_en) vcnt_lat <= {v128, v64, v32, v16, v8, v4, v2, v1}; // 7B

wire n_ld = ~ld; // 8G - falling edge of (h1 & h2)
wire ld = h1 & h2; // 13F - rising edge of (h1 & h2)

wire n_h32_128 = ~(h32 & h64 & h128); // 13G
wire scroll = n_h256 & n_h32_128; // 16F
reg scroll_lat;

always @(posedge clk_49m) begin
	if (pixel_clk_en & ~h16 & h8 & h4 & h2 & h1) // rising edge of h16
		scroll_lat <= !scroll;  // 13J
end

//Generate E and Q clocks for both MC6809Es
reg n_me, n_mq, n_se, n_sq;
wire n_me_en /* synthesis keep */;
wire n_mq_en /* synthesis keep */;
wire n_se_en /* synthesis keep */;
wire n_sq_en /* synthesis keep */;

assign n_me_en = pixel_clk_en &  h1 &  h2;
assign n_mq_en = pixel_clk_en & ~h1 &  h2;

assign n_se_en = pixel_clk_en &  h1 & ~h2;
assign n_sq_en = pixel_clk_en & ~h1 & ~h2;

always @(posedge clk_49m) begin
	if (pixel_clk_en) begin
		n_mq <= h2;
		n_sq <= ~h2;
		n_me <= n_mq;
		n_se <= ~n_mq;
	end
end

//------------ Primary CPU ---------------//

//Address decoding for primary MC6809E (1/2)
wire n_mcpu_ram_en = is_set3 ? n_mcpu_ram_en_set3 : n_mcpu_ram_en_set1;
wire n_ioen = is_set3 ? ~((mA[15:4] == 12'h1A0 | mA[15:4] == 12'h1A2 | mA[15:4] == 12'h1A4 | mA[15:4] == 12'h1A6) & m_rw):
                        ~((mA[15:4] == 12'h280 | mA[15:4] == 12'h282 | mA[15:4] == 12'h284 | mA[15:4] == 12'h286) & m_rw);
wire n_in5 = is_set3 ? ~((mA[15:8] == 8'h1C) & m_rw) : ~((mA[15:8] == 8'h30) & m_rw);
wire n_latch_en = is_set3 ? ~((mA[15:8] == 8'h1C) & ~m_rw) : ~((mA[15:8] == 8'h30) & ~m_rw);
assign n_sda = is_set3 ? ~((mA[15:4] == 12'h1E8) & ~m_rw) : ~((mA[15:8] == 8'h3A) & ~m_rw);
assign n_son = is_set3 ? ~((mA[15:8] == 8'h1E) & ~m_rw) : ~((mA[15:8] == 8'h38) & ~m_rw);
wire xscroll_lat = is_set3 ? ~((mA[15:8] == 8'h1F) & ~m_rw) : ~((mA[15:8] == 8'h3C) & ~m_rw);
wire yscroll_lat = is_set3 ? ~((mA[15:4] == 12'h1F8) & ~m_rw) : ~((mA[15:8] == 8'h3E) & ~m_rw);
wire n_col0 = is_set3 ? ~((mA[15:8] == 8'h1A) & ~m_rw) : ~((mA[15:8] == 8'h28) & ~m_rw);
wire n_mafr = is_set3 ? ~((mA[15:8] == 8'h18) & ~m_rw) : ~((mA[15:8] == 8'h20) & ~m_rw);

wire n_rom1_en, n_rom2_en, n_rom3_en, n_rom4_en, n_mcpu_ram_en_set1, n_mcpu_ram_en_set3;
always @(*) begin
	n_rom4_en = 1;
	n_rom3_en = 1;
	n_rom2_en = 1;
	n_rom1_en = 1;
	n_mcpu_ram_en_set1 = 1;
	n_mcpu_ram_en_set3 = 1;
	case (mA[15:13])
		3'b000: n_mcpu_ram_en_set3 = 0;
		3'b010: n_mcpu_ram_en_set1 = 0;
		3'b100: n_rom1_en = 0;
		3'b101: n_rom2_en = 0;
		3'b110: n_rom3_en = 0;
		3'b111: n_rom4_en = 0;
		default: ;
	endcase
end

wire n_mcr = n_mcpu_ram_en | ~( mA[12] & ~mA[11]); // 1000-17ff
wire n_vr1 = n_mcpu_ram_en | ~(~mA[12] & ~mA[11]); // 0000-07ff
wire n_vr2 = n_mcpu_ram_en | ~(~mA[12] &  mA[11]); // 0800-0fff
wire sndbrd_dir = !(n_ioen & n_in5);

//Generate primary MC6809E VBlank IRQ clear and H/V flip signals
wire vrev, hrev, n_vblk_irq_clr;
wire n_hrev = ~hrev; //15F
always @(posedge clk_49m) begin
	if (!n_res)
		{vrev, hrev, n_vblk_irq_clr} <= 0;
	else if (!n_latch_en) begin
		case(mA[2:0])
		0: n_vblk_irq_clr <= mD_out[0];
		4: hrev <= mD_out[0];
		5: vrev <= mD_out[0];
		default: ;
		endcase;
	end
end

//VBlank IRQ for primary MC6809E
wire n_mirq;

always @(posedge clk_49m) begin
	reg vblk_d;
	vblk_d <= vblk;
	if (!n_vblk_irq_clr)
		n_mirq <= 1;
	else if (~vblk_d & vblk)
		n_mirq <= 0;
end

//Primary CPU - Motorola MC6809E (uses modified version of John E. Kent's CPU09 by B. Cuzeau)
//Greg Miller's mc6809 must have a bug somewhere, doesn't work correctly.
wire [15:0] mA;
wire  [7:0] mD_out;
wire        m_rw;
/*
cpu09 u12G
(
	.clk(~clk_49m),
	.ce(n_me_en),
	.rst(~n_res),
	.rw(m_rw),
	.addr(mA),
	.data_in(mD_in),
	.data_out(mD_out),
	.halt(0),
	.irq(~n_mirq),
	.firq(0),
	.nmi(0)
);
*/

mc6809is u12G
(
    .CLK(clk_49m),
    .fallE_en(n_me_en),
    .fallQ_en(n_mq_en),
    .D(mD_in),
    .DOut(mD_out),
    .ADDR(mA),
    .RnW(m_rw),
    .nIRQ(n_mirq),
    .nFIRQ(1'b1),
    .nNMI(1'b1),
    .nHALT(1'b1),
    .nRESET(n_res),
    .nDMABREQ(1'b1)
);

//Multiplex data inputs to primary MC6809E
wire [7:0] mD_in =
		sndbrd_dir                       ? sndbrd_D:
		~n_vr1                           ? charram0_D:
		~n_vr2                           ? charram1_D:
		~n_mcr                           ? sharedram_D:
		~n_rom1_en                       ? main_cpu_rom_do://eprom1_D:
		~n_rom2_en                       ? main_cpu_rom_do://eprom2_D:
		~n_rom3_en                       ? main_cpu_rom_do://eprom3_D:
		~n_rom4_en                       ? main_cpu_rom_do://eprom4_D:
		8'hFF;

//Latch VCOL lines for character lookup PROM and color address bus bits A[6:4]
wire vcol0, vcol1;
always @(posedge clk_49m) begin
	if (!n_res)
		{vcol0, vcol1, color_A[6:4]} <= 0;
	else if (!n_col0)
		{vcol0, vcol1, color_A[6:4]} <= {mD_out[3], mD_out[4], mD_out[2:0]};
end

//Latch primary MC6809E data bus for X scroll register (labelleed J and SHF1/SHF0 in the schematics) - 4C
reg   [7:2] J_r;
reg         shf0_r, shf1_r;
wire  [7:2] J = !scroll_lat ? J_r : 6'b111111;
wire        shf0 = !scroll_lat ? shf0_r : 1'b1;
wire        shf1 = !scroll_lat ? shf1_r : 1'b1;
always @(posedge clk_49m) begin
	if (!xscroll_lat) {J_r, shf1_r, shf0_r} <= mD_out;
end

//Latch primary MC6809E data bus for Y scroll register (labelled L in the schematics) - 4D
reg   [7:0] L_reg;
wire  [7:0] L = !scroll_lat ? L_reg : 8'hFF;
always @(posedge clk_49m) begin
	if (!yscroll_lat) L_reg <= mD_out;
end

//------------ Secondary CPU ---------------//
//Address decoding for secondary MC6809E

wire n_rom5_en, n_scr, n_ora, n_scpu_irq, n_beam_en, n_safr;

always @(*) begin
	n_rom5_en = 1;
	n_scr = 1;
	n_ora = 1;
	n_scpu_irq = 1;
	n_beam_en = 1;
	n_safr = 1;
	case (sA[15:13])
		3'b000: n_safr = 0;
		3'b001: n_beam_en = 0;
		3'b010: n_scpu_irq = 0;
		3'b011: n_ora = 0;
		3'b100: n_scr = 0;
		3'b111: n_rom5_en = 0;
		default :;
	endcase
end

wire n_spriteram0_en = n_ora | ~sA[1];
wire n_spriteram1_en = n_ora |  sA[1];

//Generate VBlank interrupt and clear signal for secondary MC6809E
wire n_sirq, s_vblk_irq_clr;

always @(posedge clk_49m) begin
	reg vblk_d;
	vblk_d <= vblk;

	if (!s_vblk_irq_clr)
		n_sirq <= 1;
	else if (!vblk_d & vblk)
		n_sirq <= 0;

	if (!n_res)
		s_vblk_irq_clr <= 0;
	else if (!n_scpu_irq)
		s_vblk_irq_clr <= sD_out[0];
end

//Secondary CPU - Motorola MC6809E (uses Greg Miller's mc6809i)
wire [15:0] sA;
wire [7:0] sD_out;
wire s_rw;
/*
cpu09 u12E
(
	.clk(~clk_49m),
	.ce(n_se_en),
	.rst(~n_res),
	.rw(s_rw),
	.addr(sA),
	.data_in(sD_in),
	.data_out(sD_out),
	.halt(0),
	.irq(~n_sirq),
	.firq(0),
	.nmi(0)
);
*/
mc6809is u12E
(
		.CLK(clk_49m),
		.fallE_en(n_se_en),
		.fallQ_en(n_sq_en),
    .D(sD_in),
    .DOut(sD_out),
    .ADDR(sA),
    .RnW(s_rw),
    .nIRQ(n_sirq),
    .nFIRQ(1'b1),
    .nNMI(1'b1),
    .nHALT(1'b1),
    .nRESET(n_res),
    .nDMABREQ(1'b1)
);

//Multiplex data inputs to secondary MC6809E
wire [7:0] sD_in =
		~n_rom5_en                         ? sub_cpu_rom_do://eprom5_D:
		~n_scr                             ? sharedram_D:
		~n_spriteram1_en                   ? spriteram_D[15:8]:
		~n_spriteram0_en                   ? spriteram_D[7:0]:
		~n_beam_en                         ? vcnt_lat:
		8'hFF;

//------------- Shared RAM -------------//

//Multiplex output enable lines and address lines A[10:8] for shared RAM
wire [10:0] sharedram_A =  h2 ? mA[10:0] : sA[10:0];
wire        sharedram_oe = h2 ? m_rw : s_rw;
wire        sharedram_we = (h2 ? !n_mcr : !n_scr) & !sharedram_oe;
//Multplex data from CPUs to shared RAM (handled by the 74LS245s at 10G and 10F on the PCB)
wire  [7:0] sharedram_Din = h2 ? mD_out : sD_out;

//Shared RAM for the two MC6809E CPUs
wire [7:0] sharedram_D;
spram #(8, 11) u9F
(
	.clk(clk_49m),
	.we(sharedram_we),
	.addr(sharedram_A),
	.data(sharedram_Din),
	.q(sharedram_D)
);

//--------------------- Video RAM ---------------//
wire [10:0] charram_A = h2 ? mA[10:0] : {scroll_lat, va128, va64, va32, va16, va8, ha[7:3]};
wire        charram0_we = h2 & !n_vr1 & !m_rw;
wire        charram1_we = h2 & !n_vr2 & !m_rw;

//Character RAM bank 0
wire [7:0] charram0_D;
spram #(8, 11) u5F
(
	.clk(clk_49m),
	.we(charram0_we),
	.addr(charram_A),
	.data(mD_out),
	.q(charram0_D)
);

//Character RAM bank 1
wire [7:0] charram1_D;
spram #(8, 11) u4F
(
	.clk(clk_49m),
	.we(charram1_we),
	.addr(charram_A),
	.data(mD_out),
	.q(charram1_D)
);

// --------- Secondary CPU + Sprite RAM -------------//

wire [15:0] spriteram_D;
wire  [9:0] spriteram_A = h2 ? {4'b1111, h128, h128_256, h64, h32, h16, h4} : {sA[10:2], sA[0]};
wire        n_spriteram0_we = h2 | n_spriteram0_en | s_rw;
wire        n_spriteram1_we = h2 | n_spriteram1_en | s_rw;

//Sprite RAM bank 0 (upper 4 bits)
spram #(4, 10) u8B
(
	.clk(clk_49m),
	.we(~n_spriteram0_we),
	.addr(spriteram_A),
	.data(sD_out[7:4]),
	.q(spriteram_D[7:4])
);

//Sprite RAM bank 0 (lower 4 bits)
spram #(4, 10) u9B
(
	.clk(clk_49m),
	.we(~n_spriteram0_we),
	.addr(spriteram_A),
	.data(sD_out[3:0]),
	.q(spriteram_D[3:0])
);

//Sprite RAM bank 1 (upper 4 bits)
spram #(4, 10) u8C
(
	.clk(clk_49m),
	.we(~n_spriteram1_we),
	.addr(spriteram_A),
	.data(sD_out[7:4]),
	.q(spriteram_D[15:12])
);

//Sprite RAM bank 1 (lower 4 bits)
spram #(4, 10) u9C
(
	.clk(clk_49m),
	.we(~n_spriteram1_we),
	.addr(spriteram_A),
	.data(sD_out[3:0]),
	.q(spriteram_D[11:8])
);

//------------------ Background generator -----------------//
//XOR horizontal counter bits [5:2] with HREV
wire h4x, h8x, h16x, h32x;

assign h4x = h4 ^ hrev;
assign h8x = h8 ^ hrev;
assign h16x = h16 ^ hrev;
assign h32x = h32 ^ hrev;
//XOR horizontal counter bits 6 and 7 with HREV, invert bit 3 of the horizontal counter and XOR 128H with !256H
wire h64x, h128x, h128_256, n_h8;

assign h64x = h64 ^ hrev;
assign h128x = h128 ^ hrev;
assign h128_256 = n_h256 ^ h128;

//Sum XORed horizontal counter bits with X scroll register bits
wire [7:2] ha /* synthesis keep */;
assign ha = {h128x, h64x, h32x, h16x, h8x, h4x} + J[7:2] + scroll_lat;

//XOR latched vertical counter bits with VREV
wire v1x, v2x, v4x, v8x, v16x, v32x, v64x, v128x;
assign {v128x, v64x, v32x, v16x, v8x, v4x, v2x, v1x} = {vcnt_lat ^ {8{vrev}}};

//Sum XORed vertical counter bits with Y scroll register bits
wire va1, va2, va4, va8, va16, va32, va64, va128;
assign {va128, va64, va32, va16, va8, va4, va2, va1} = {v128x, v64x, v32x, v16x, v8x, v4x, v2x, v1x} + L + scroll_lat;

//Latch data output from character RAM bank 1
//Latch character ROM address lines, character ROM chip enable, character H/V flip bits
wire  [7:0] charram1_Dlat;
wire  [7:0] charram0_Dlat;
wire        n_charrom0_ce, char_hflip, char_vflip, va1l, va2l, va4l, ha2l;
wire [12:0] charrom_A;
wire  [3:0] charram1_Dl2;
reg         scroll_lat_d;

always @(posedge clk_49m) begin
	if (pixel_clk_en & h1 & ~h2) begin // rising edge of h2
		charram0_Dlat <= charram0_D; // 4H
		charram1_Dlat <= charram1_D; // 4G
	end
	if (pixel_clk_en & h1 & h2) begin // falling edge of h2
		{n_charrom0_ce, charrom_A[12], char_hflip, char_vflip, va1l, va2l, va4l, ha2l} <= 
			{charram1_Dlat[5:4], charram1_Dlat[6], charram1_Dlat[7], va1, va2, va4, ha[2]}; // 4J
		charrom_A[11:4] <= charram0_Dlat; // 3H
		//Latch lowest 4 bits of already-latched character RAM data output
		//The HUD signal would be latched from D[4] to Q[4] but has been omitted as this is part of the logic used to signal that the game is
		//drawing the top and bottom HUDs, which has been abstracted
		charram1_Dl2 <= charram1_Dlat[3:0]; // 3G
		scroll_lat_d <= scroll_lat;
	end
end

//Generate lower 4 address lines for character ROMs
assign charrom_A[3:0] = {char_hflip ^ ha2l, char_vflip ^ va4l, char_vflip ^ va2l, char_vflip ^ va1l}; // 3J

//Latch address lines A[5:2] for character lookup PROM, load for character ROM 083 custom chip
reg charrom_flip;
reg hud, hud_d;
reg bottom_hud, bottom_hud_en;
always @(posedge clk_49m) begin
	if (pixel_clk_en & ld) begin // 2G
		charrom_flip <= char_flip;
		char_lut_A[5:2] <= charram1_Dl2; 
		hud <= scroll_lat_d;
		hud_d <= hud;

		if (hblk) bottom_hud <= 0;  // 4B
		else if (!hud & scroll_lat_d) bottom_hud <= 1; // rising edge of hud
	end

	if (vblk) bottom_hud_en <= 0;
	else if (pixel_clk_en) bottom_hud_en <= bottom_hud;
end

//Konami 083 custom chip 1/2 - this one shifts the pixel data from character ROMs
k083 u1G
(
	.CK(clk_49m),
	.CK_EN(pixel_clk_en),
	.LOAD(ld),
	.FLIP(charrom_flip),
	.DB0i(charrom_D),
	.DSH0(char_lut_A[1:0])
);

//Generate shifted pixels
reg [3:0] SH, SF, SS, S;
always @(posedge clk_49m) begin
	if (pixel_clk_en) begin
		SF <= SH; // 2E
		SH <= SS;
		SS <= S; // 2F
		S <= char_lut_D;
	end
end

// U14E
wire shf0_rev = n_hrev ^ shf0;
wire shf1_rev = n_hrev ^ shf1;
wire char_flip = n_hrev ^ char_hflip;

// delay the lowest two bits of xscroll to compensate the usage for RAM data fetch and displaying
reg shf0_l, shf1_l;
always @(posedge clk_49m) if (pixel_clk_en & !n_ocoll) {shf0_l, shf1_l} <= {shf0_rev, shf1_rev}; // 12D

wire char_sel0 = ~(hud_d | shf0_l) | bottom_hud_en; // 15F-15G
wire char_sel1 = ~(hud_d | shf1_l) | bottom_hud_en; // 15F-15G

// Select pixels according to adjusted xscroll
reg [3:0] char_D;
always @(*) begin // 3E-3F
	case ({char_sel1, char_sel0})
		2'b00: char_D = SF;
		2'b01: char_D = SH;
		2'b10: char_D = SS;
		2'b11: char_D = S;
		default: ;
	endcase
end

//-------------- Sprite generator --------------//

//Konami 503 custom chip - generates sprite addresses for lower half of sprite ROMs, sprite
//data + collision control and enables for sprite write and 083 custom chip
wire csobj, k083_ctl, n_cara, n_ocoll;
k503 u11A
(
	.clk(clk_49m),
	.clk_en(pixel_clk_en),
	.OB(spriteram_D[7:0]),
	.VCNT(vcnt_lat),
	.H4(h4),
	.H8(h8),
	.LD(n_ld),
	.OCS(csobj),
	.NE83(k083_ctl),
	.ODAT(n_cara),
	.OCOL(n_ocoll),
	.R(spriterom_A[5:0])
);

//Latch address lines A[12:6] and chip enables for sprite ROMs from sprite RAM bank 1
wire n_spriterom0_en;
always @(posedge clk_49m) begin
	if (pixel_clk_en & !n_cara) begin // 11C
		spriterom_A[12:6] <= spriteram_D[14:8];
		n_spriterom0_en <= spriteram_D[15];
	end
end

//Konami 083 custom chip 2/2 - this one shifts the pixel data from sprite ROMs
k083 u16A
(
	.CK(clk_49m),
	.CK_EN(pixel_clk_en),
	.LOAD(ld),
	.FLIP(sprrom_flip),
	.DB0i(spriterom_D[7:0]),
	.DB1i(spriterom_D[15:8]),
	.DSH0(sprite_lut_A[1:0]),
	.DSH1(sprite_lut_A[3:2])
);

//Latch address lines A[7:4] for sprite lookup PROM, enable for sprite line buffer
reg sprite_lbuff_sel, sprrom_flip;

always @(posedge clk_49m) begin
	if (pixel_clk_en & !n_ocoll) begin // 12D
		sprite_lut_A[7:4] <= spriteram_D[3:0];
		sprite_lbuff_sel <= csobj;
		sprrom_flip <= k083_ctl;
	end
end

wire n_ld0 = ~(h1 & h2 & h4); // 8F

//Konami 502 custom chip, responsible for generating sprites (sits between sprite ROMs and the sprite line buffer)
wire [7:0] sprite_lbuff_Do;
wire [4:0] sprite_D;
wire sprite_lbuff_l, sprite_lbuff_dec0, sprite_lbuff_dec1;
k502 u15D
(
	.CK1(clk_49m),
	.CK1_EN(clk_12m_en),
	.CK2(clk_49m),
	.CK2_EN(pixel_clk_en),
	.LD0(n_ld0),
	.H2(h2),
	.H256(n_h256),
	.SPAL(sprite_lut_D),
	.SPLBi({sprite_lbuff1_D, sprite_lbuff0_D}),
	.SPLBo(sprite_lbuff_Do),
	.OSEL(sprite_lbuff_l),
	.OLD(sprite_lbuff_dec1),
	.OCLR(sprite_lbuff_dec0),
	.COL(sprite_D)
);

//Generate load and clear signals for line buffer address counters (16D)
wire n_sprite_lbuff0_ld = n_ocoll |  sprite_lbuff_dec1;
wire n_sprite_lbuff1_ld = n_ocoll | ~sprite_lbuff_dec1;
wire n_sprite_lbuff0_clr = n_ld | ~(~sprite_lbuff_dec0 &  sprite_lbuff_dec1);
wire n_sprite_lbuff1_clr = n_ld | ~( sprite_lbuff_dec0 & ~sprite_lbuff_dec1);

//Generate sprite line buffer address buses
always @(posedge clk_49m) begin
	if (pixel_clk_en) begin // 12C-13C
		if (!n_sprite_lbuff0_clr)
			sprite_lbuff0_A <= 0;
		else if (!n_sprite_lbuff0_ld)
			sprite_lbuff0_A <= spriteram_D[15:8];
		else
			sprite_lbuff0_A <= sprite_lbuff0_A + 1'd1;

		if (!n_sprite_lbuff1_clr)
			sprite_lbuff1_A <= 0;
		else if (!n_sprite_lbuff1_ld)
			sprite_lbuff1_A <= spriteram_D[15:8];
		else
			sprite_lbuff1_A <= sprite_lbuff1_A + 1'd1;
	end
end

//Generate combined shared RAM enable, sprite line buffer enables, scroll data to be latched
wire sprite_lbuff_h = ~sprite_lbuff_l; // 13H
wire n_sprite_lbuff0_en = sprite_lbuff_l & sprite_lbuff_sel; // 16F
wire n_sprite_lbuff1_en = sprite_lbuff_h & sprite_lbuff_sel; // 16F

//Sprite line buffer bank 0
wire [7:0] sprite_lbuff0_A;
wire [3:0] sprite_lbuff0_D;
spram #(4, 10) u13D
(
	.clk(clk_49m),
	.we(pixel_clk_en & ~n_sprite_lbuff0_en),
	.addr({2'b00, sprite_lbuff0_A}),
	.data(sprite_lbuff_Do[3:0]),
	.q(sprite_lbuff0_D)
);

//Sprite line buffer bank 1
wire [7:0] sprite_lbuff1_A;
wire [3:0] sprite_lbuff1_D;
spram #(4, 10) u14D
(
	.clk(clk_49m),
	.we(pixel_clk_en & ~n_sprite_lbuff1_en),
	.addr({2'b00, sprite_lbuff1_A}),
	.data(sprite_lbuff_Do[7:4]),
	.q(sprite_lbuff1_D)
);

//----------------- Final color mux --------------//

//Multiplex character and sprite data
wire  [3:0] char_spr_D = ch_sp_sel ? char_D : sprite_D[3:0]; // 3D

wire ch_sp_sel = hud_d | bottom_hud_en | sprite_D[4]; // 16E

//Latch address lines A7 and A[3:0] for color PROMs, enable to draw bottom HUD
always @(posedge clk_49m) if (pixel_clk_en) {color_A[3:0], color_A[7]} <= {char_spr_D[3:0], ch_sp_sel};

//---------------- ROMs ---------------//

`ifndef EXT_ROM
//Character ROM 1/2
wire [7:0] eprom7_D;
eprom_7 u2J
(
	.ADDR(charrom_A),
	.CLK(clk_49m),
	.DATA(eprom7_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep7_cs_i),
	.WR(ioctl_wr)
);

//Character ROM 2/2
wire [7:0] eprom8_D;
eprom_8 u1J
(
	.ADDR(charrom_A),
	.CLK(clk_49m),
	.DATA(eprom8_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep8_cs_i),
	.WR(ioctl_wr)
);
`endif

//Character lookup PROM
reg  [5:0] char_lut_A;
wire [3:0] char_lut_D;
char_lut_prom u1F
(
	.ADDR({vcol1, vcol0, char_lut_A}),
	.CLK(clk_49m),
	.DATA(char_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cl_cs_i),
	.WR(ioctl_wr)
);

//Sprite ROM 1/4
wire [12:0] spriterom_A;
wire [7:0] eprom9_D;

eprom_9 u12A
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom9_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep9_cs_i),
	.WR(ioctl_wr)
);

//Sprite ROM 2/4
wire [7:0] eprom11_D;

eprom_11 u14A
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom11_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep11_cs_i),
	.WR(ioctl_wr)
);

//Sprite ROM 3/4
wire [7:0] eprom10_D;

eprom_10 u13A
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom10_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep10_cs_i),
	.WR(ioctl_wr)
);

//Sprite ROM 4/4
wire [7:0] eprom12_D;

eprom_12 u15A
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom12_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep12_cs_i),
	.WR(ioctl_wr)
);

//Sprite lookup PROM
reg   [7:0] sprite_lut_A;
wire  [3:0] sprite_lut_D;
sprite_lut_prom u16C
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

//Blue color PROM
reg   [7:0] color_A;
wire  [3:0] prom_blue;
color_prom_3 u1E
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA(prom_blue),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp3_cs_i),
	.WR(ioctl_wr)
);

//Red color PROM
wire [3:0] prom_red;
color_prom_1 u2C
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA(prom_red),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp1_cs_i),
	.WR(ioctl_wr)
);

//Green color PROM
wire [3:0] prom_green;
color_prom_2 u2D
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA(prom_green),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp2_cs_i),
	.WR(ioctl_wr)
);
endmodule

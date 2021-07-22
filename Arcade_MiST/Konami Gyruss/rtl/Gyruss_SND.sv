//============================================================================
// 
//  Gyruss sound PCB model
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

module Gyruss_SND
(
	input                reset,
	input                clk_49m,         //Actual frequency: 49.152MHz
	input         [23:0] dip_sw,
	input          [1:0] coin,                     //0 = coin 1, 1 = coin 2
	input          [1:0] start_buttons,            //0 = Player 1, 1 = Player 2
	input          [3:0] p1_joystick, p2_joystick, //0 = up, 1 = down, 2 = left, 3 = right
	input                p1_fire,
	input                p2_fire,
	input                btn_service,
	input                cpubrd_A5, cpubrd_A6,
	input                cs_controls_dip1, cs_dip2, cs_dip3,
	input                irq_trigger, cs_sounddata,
	input          [7:0] cpubrd_Din,
	
	output         [7:0] controls_dip,
	output signed [15:0] sound_l, sound_r,
	
	input                ep10_cs_i,
	input                ep11_cs_i,
	input                ep12_cs_i,
	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr
	//The sound board contains a video passthrough but video will instead be tapped
	//straight from the CPU board implementation (this passthrough is redundant for
	//an FPGA implementation)
);

//------------------------------------------------------- Signal outputs -------------------------------------------------------//

//Multiplex controls and DIP switches to be output to CPU board
assign controls_dip = cs_controls_dip1 ? controls_dip1:
                      cs_dip2          ? dip_sw[15:8]:
                      cs_dip3          ? dip_sw[23:16]:
                      8'hFF;

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate clock enables for sound data and IRQ logic, and DC offset removal
reg [8:0] div = 9'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 9'd1;
end
reg [3:0] n_div = 4'd0;
always_ff @(negedge clk_49m) begin
	n_div <= n_div + 4'd1;
end
wire n_cen_3m = !n_div;
wire cen_dcrm = !div;

//Generate 3.579545MHz clock enable for Z80, 1.789772MHz clock enable for AY-3-8910s, clock enable for AY-3-8910 timer
//(uses Jotego's fractional clock divider from JTFRAME)
wire cen_3m58, cen_1m79, cen_timer;
jtframe_frac_cen #(11) sound_cen
(
	.clk(clk_49m),
	.n(10'd60),
	.m(10'd824),
	.cen({cen_timer, 8'bZZZZZZZZ, cen_1m79, cen_3m58})
);

//Also use Jotego's fractional clock divider to generate an 8MHz clock enable for the i8039 MCU
wire cen_8m;
jtframe_frac_cen #(2) i8039_cen
(
	.clk(clk_49m),
	.n(10'd42),
	.m(10'd258),
	.cen({1'bZ, cen_8m})
);

//------------------------------------------------------------ CPU -------------------------------------------------------------//

//Sound CPU - Zilog Z80 (uses T80s version of the T80 soft core)
wire [15:0] sound_A;
wire [7:0] sound_Dout;
wire n_m1, n_mreq, n_iorq, n_rd, n_wr, n_rfsh;
T80s u6B
(
	.RESET_n(reset),
	.CLK(clk_49m),
	.CEN(cen_3m58),
	.INT_n(n_irq),
	.M1_n(n_m1),
	.MREQ_n(n_mreq),
	.IORQ_n(n_iorq),
	.RD_n(n_rd),
	.WR_n(n_wr),
	.RFSH_n(n_rfsh),
	.A(sound_A),
	.DI(sound_Din),
	.DO(sound_Dout)
);
//Address decoding for Z80
wire n_rw = n_rd & n_wr;
wire cs_soundrom0 = (~n_rw & ~n_mreq & n_rfsh & (sound_A[15:13] == 3'b000));
wire cs_soundrom1 = (~n_rw & ~n_mreq & n_rfsh & (sound_A[15:13] == 3'b001));
wire cs_soundram = (~n_rw & ~n_mreq & n_rfsh & (sound_A[15:13] == 3'b011));
wire cs_sound = (~n_rw & ~n_mreq & n_rfsh & (sound_A[15:13] == 3'b100));
wire cs_ay1 = (~n_iorq & n_m1 & (sound_A[4:2] == 3'b000));
wire cs_ay2 = (~n_iorq & n_m1 & (sound_A[4:2] == 3'b001));
wire cs_ay3 = (~n_iorq & n_m1 & (sound_A[4:2] == 3'b010));
wire cs_ay4 = (~n_iorq & n_m1 & (sound_A[4:2] == 3'b011));
wire cs_ay5 = (~n_iorq & n_m1 & (sound_A[4:2] == 3'b100));
wire cs_i8039_irq = (~n_iorq & n_m1 & (sound_A[4:2] == 3'b101));
wire cs_i8039_latch = (~n_iorq & n_m1 & (sound_A[4:2] == 3'b110));
//Multiplex data input to Z80
wire [7:0] sound_Din = cs_soundrom0          ? eprom10_D:
                       cs_soundrom1          ? eprom11_D:
                       (cs_soundram & n_wr)  ? sndram_D:
                       cs_sound              ? sound_D:
                       (~ay1_bdir & ay1_bc1) ? ay1_D:
                       (~ay2_bdir & ay2_bc1) ? ay2_D:
                       (~ay3_bdir & ay3_bc1) ? ay3_D:
                       (~ay4_bdir & ay4_bc1) ? ay4_D:
                       (~ay5_bdir & ay5_bc1) ? ay5_D:
                       8'hFF;

//Sound ROMs
//ROM 1/2
wire [7:0] eprom10_D;
eprom_10 u6A
(
	.ADDR(sound_A[12:0]),
	.CLK(clk_49m),
	.DATA(eprom10_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep10_cs_i),
	.WR(ioctl_wr)
);
//ROM 2/2
wire [7:0] eprom11_D;
eprom_11 u8A
(
	.ADDR(sound_A[12:0]),
	.CLK(clk_49m),
	.DATA(eprom11_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep11_cs_i),
	.WR(ioctl_wr)
);

//Sound RAM (lower 4 bits)
wire [7:0] sndram_D;
spram #(4, 10) u4A
(
	.clk(clk_49m),
	.we(cs_soundram & ~n_wr),
	.addr(sound_A[9:0]),
	.data(sound_Dout[3:0]),
	.q(sndram_D[3:0])
);

//Sound RAM (upper 4 bits)
spram #(4, 10) u5A
(
	.clk(clk_49m),
	.we(cs_soundram & ~n_wr),
	.addr(sound_A[9:0]),
	.data(sound_Dout[7:4]),
	.q(sndram_D[7:4])
);

//Latch sound data coming in from CPU board
reg [7:0] sound_D = 8'd0;
always_ff @(posedge clk_49m) begin
	if(n_cen_3m && cs_sounddata)
		sound_D <= cpubrd_Din;
end

//Generate Z80 interrupts
wire irq_clr = (~reset | ~(n_iorq | n_m1));
reg n_irq = 1;
always_ff @(posedge clk_49m or posedge irq_clr) begin
	if(irq_clr)
		n_irq <= 1;
	else if(n_cen_3m && irq_trigger)
		n_irq <= 0;
end

//--------------------------------------------------- Controls & DIP switches --------------------------------------------------//

//Multiplex player inputs and DIP switch bank 1
wire [7:0] controls_dip1 = ({cpubrd_A6, cpubrd_A5} == 2'b00) ? {3'b111, start_buttons, btn_service, coin}:
                           ({cpubrd_A6, cpubrd_A5} == 2'b01) ? {3'b111, p1_fire, p1_joystick[1:0], p1_joystick[3:2]}:
                           ({cpubrd_A6, cpubrd_A5} == 2'b10) ? {3'b111, p2_fire, p2_joystick[1:0], p2_joystick[3:2]}:
                           ({cpubrd_A6, cpubrd_A5} == 2'b11) ? dip_sw[7:0]:
                           8'hFF;

//--------------------------------------------------------- Sound chips --------------------------------------------------------//

//Generate BC1 and BDIR signals for the five AY-3-8910s
wire ay1_bdir = ~(~cs_ay1 | sound_A[0]);
wire ay1_bc1 = ~(~cs_ay1 | sound_A[1]);
wire ay2_bdir = ~(~cs_ay2 | sound_A[0]);
wire ay2_bc1 = ~(~cs_ay2 | sound_A[1]);
wire ay3_bdir = ~(~cs_ay3 | sound_A[0]);
wire ay3_bc1 = ~(~cs_ay3 | sound_A[1]);
wire ay4_bdir = ~(~cs_ay4 | sound_A[0]);
wire ay4_bc1 = ~(~cs_ay4 | sound_A[1]);
wire ay5_bdir = ~(~cs_ay5 | sound_A[0]);
wire ay5_bc1 = ~(~cs_ay5 | sound_A[1]);

//AY-3-8910 timer (code adapted from MiSTer-X's Gyruss core)
reg [3:0] timer_sel;
wire [3:0] timer_val;
always_comb begin
	case(timer_sel)
		0: timer_val = 4'h0;
		1: timer_val = 4'h1;
		2: timer_val = 4'h2;
		3: timer_val = 4'h3;
		4: timer_val = 4'h4;
		5: timer_val = 4'h9;
		6: timer_val = 4'hA;
		7: timer_val = 4'hB;
		8: timer_val = 4'hA;
		9: timer_val = 4'hD;
		default: timer_val = 0;
	endcase
end
reg [3:0] timer = 4'd0;
always_ff @(posedge clk_49m) begin
	if(cen_timer) begin
		timer <= timer_val;
		timer_sel <= (timer_sel == 4'd9) ? 4'd0 : (timer_sel + 4'd1);
	end
end

//Sound chip 1 (AY-3-8910 - uses JT49 by Jotego)
wire [7:0] ay1_D;
wire [7:0] ay1A_raw, ay1B_raw, ay1C_raw;
wire [5:0] ay1_filter;
jt49_bus #(.COMP(3'b100)) u11D
(
	.rst_n(reset),
	.clk(clk_49m),
	.clk_en(cen_1m79),
	.bdir(ay1_bdir),
	.bc1(ay1_bc1),
	.din(sound_Dout),
	.sel(1),
	.dout(ay1_D),
	.A(ay1A_raw),
	.B(ay1B_raw),
	.C(ay1C_raw),
	.IOB_out({2'bZZ, ay1_filter})
);

//Sound chip 2 (AY-3-8910 - uses JT49 by Jotego)
wire [7:0] ay2_D;
wire [7:0] ay2A_raw, ay2B_raw, ay2C_raw;
wire [5:0] ay2_filter;
jt49_bus #(.COMP(3'b100)) u12D
(
	.rst_n(reset),
	.clk(clk_49m),
	.clk_en(cen_1m79),
	.bdir(ay2_bdir),
	.bc1(ay2_bc1),
	.din(sound_Dout),
	.sel(1),
	.dout(ay2_D),
	.A(ay2A_raw),
	.B(ay2B_raw),
	.C(ay2C_raw),
	.IOB_out({2'bZZ, ay2_filter})
);

//Sound chip 3 (AY-3-8910 - uses JT49 by Jotego)
wire [7:0] ay3_D;
wire [7:0] ay3A_raw, ay3B_raw, ay3C_raw;
jt49_bus #(.COMP(3'b100)) u10B
(
	.rst_n(reset),
	.clk(clk_49m),
	.clk_en(cen_1m79),
	.bdir(ay3_bdir),
	.bc1(ay3_bc1),
	.din(sound_Dout),
	.sel(1),
	.dout(ay3_D),
	.A(ay3A_raw),
	.B(ay3B_raw),
	.C(ay3C_raw),
	.IOA_in({4'b0000, timer})
);

//Sound chip 4 (AY-3-8910 - uses JT49 by Jotego)
wire [7:0] ay4_D;
wire [7:0] ay4A_raw, ay4B_raw, ay4C_raw;
jt49_bus #(.COMP(3'b100)) u9B
(
	.rst_n(reset),
	.clk(clk_49m),
	.clk_en(cen_1m79),
	.bdir(ay4_bdir),
	.bc1(ay4_bc1),
	.din(sound_Dout),
	.sel(1),
	.dout(ay4_D),
	.A(ay4A_raw),
	.B(ay4B_raw),
	.C(ay4C_raw)
);

//Sound chip 5 (AY-3-8910 - uses JT49 by Jotego)
wire [7:0] ay5_D;
wire [7:0] ay5A_raw, ay5B_raw, ay5C_raw;
jt49_bus #(.COMP(3'b100)) u8B
(
	.rst_n(reset),
	.clk(clk_49m),
	.clk_en(cen_1m79),
	.bdir(ay5_bdir),
	.bc1(ay5_bc1),
	.din(sound_Dout),
	.sel(1),
	.dout(ay5_D),
	.A(ay5A_raw),
	.B(ay5B_raw),
	.C(ay5C_raw)
);

//Sound chip 6 (Intel 8039 MCU - uses t8039_notri variant of T48)
wire [7:0] i8039_raw;
wire [7:0] i8039_Dout;
wire i8039_ale, n_i8039_psen, n_i8039_rd, n_i8039_irq_clr;
t8039_notri u7H
(
	.xtal_i(clk_49m),
	.xtal_en_i(cen_8m),
	.reset_n_i(reset),
	.int_n_i(n_i8039_irq),
	.ea_i(1),
	.rd_n_o(n_i8039_rd),
	.psen_n_o(n_i8039_psen),
	.ale_o(i8039_ale),
	.db_i(i8039_Din),
	.db_o(i8039_Dout),
	.p2_o({n_i8039_irq_clr, 3'bZZZ, eprom12_A[11:8]}),
	.p1_o(i8039_raw)
);
//Multiplex data into i8039
wire [7:0] i8039_Din = ~n_i8039_psen ? eprom12_D:
                       ~n_i8039_rd   ? i8039_latch:
                       8'hFF;

//i8039 ROM
wire [11:0] eprom12_A;
wire [7:0] eprom12_D;
eprom_12 u11H
(
	.ADDR(eprom12_A),
	.CLK(clk_49m),
	.DATA(eprom12_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep12_cs_i),
	.WR(ioctl_wr)
);

//Latch data from Z80 to i8039
reg [7:0] i8039_latch = 8'd0;
always_ff @(posedge clk_49m) begin
	if(cen_3m58 && cs_i8039_latch)
		i8039_latch <= sound_Dout;
end

//Latch address lines A[7:0] for MCU ROM
reg [7:0] i8039_rom_lat = 8'd0;
always_ff @(negedge i8039_ale) begin
	i8039_rom_lat <= i8039_Dout;
end
assign eprom12_A[7:0] = i8039_rom_lat;

//Generate i8039 IRQ
reg n_i8039_irq = 1;
always_ff @(posedge clk_49m) begin
	if(!n_i8039_irq_clr)
		n_i8039_irq <= 1;
	else if(cen_3m58 && cs_i8039_irq)
		n_i8039_irq <= 0;
end

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//Apply gain and remove DC offset from AY-3-8910s and i8039 (uses jt49_dcrm2 from JT49 by Jotego for DC offset removal)
wire signed [15:0] ay1A_dcrm, ay1B_dcrm, ay1C_dcrm, ay2A_dcrm, ay2B_dcrm, ay2C_dcrm;
wire signed [15:0] ay3A_sound, ay3B_sound, ay3C_sound, ay4A_sound, ay4B_sound, ay4C_sound, ay5A_sound, ay5B_sound, ay5C_sound;
wire signed [15:0] i8039_sound;
jt49_dcrm2 #(16) dcrm_ay1A
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay1A_raw, 4'd0}),
	.dout(ay1A_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay1B
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay1B_raw, 4'd0}),
	.dout(ay1B_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay1C
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay1C_raw, 4'd0}),
	.dout(ay1C_dcrm)
);

jt49_dcrm2 #(16) dcrm_ay2A
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay2A_raw, 4'd0}),
	.dout(ay2A_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay2B
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay2B_raw, 4'd0}),
	.dout(ay2B_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay2C
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay2C_raw, 4'd0}),
	.dout(ay2C_dcrm)
);

jt49_dcrm2 #(16) dcrm_ay3A
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay3A_raw, 4'd0}),
	.dout(ay3A_sound)
);
jt49_dcrm2 #(16) dcrm_ay3B
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay3B_raw, 4'd0}),
	.dout(ay3B_sound)
);
jt49_dcrm2 #(16) dcrm_ay3C
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay3C_raw, 4'd0}),
	.dout(ay3C_sound)
);

jt49_dcrm2 #(16) dcrm_ay4A
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay4A_raw, 4'd0}),
	.dout(ay4A_sound)
);
jt49_dcrm2 #(16) dcrm_ay4B
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay4B_raw, 4'd0}),
	.dout(ay4B_sound)
);
jt49_dcrm2 #(16) dcrm_ay4C
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay4C_raw, 4'd0}),
	.dout(ay4C_sound)
);

jt49_dcrm2 #(16) dcrm_ay5A
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay5A_raw, 4'd0}),
	.dout(ay5A_sound)
);
jt49_dcrm2 #(16) dcrm_ay5B
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay5B_raw, 4'd0}),
	.dout(ay5B_sound)
);
jt49_dcrm2 #(16) dcrm_ay5C
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({4'd0, ay5C_raw, 4'd0}),
	.dout(ay5C_sound)
);

jt49_dcrm2 #(16) dcrm_i8039
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({2'd0, i8039_raw, 6'd0}),
	.dout(i8039_sound)
);

//Two of Gyruss's AY-3-8910s contain selectable low-pass filters with the following cutoff frequencies:
//3386.28Hz, 723.43Hz, 596.09Hz
//Model this here (the PCB handles this via 3 74HC4066 switching ICs located at 9E, 9F and 10F)
wire signed [15:0] ay1A_light, ay1A_med, ay1A_heavy, ay1B_light, ay1B_med, ay1B_heavy, ay1C_light, ay1C_med, ay1C_heavy;
wire signed [15:0] ay2A_light, ay2A_med, ay2A_heavy, ay2B_light, ay2B_med, ay2B_heavy, ay2C_light, ay2C_med, ay2C_heavy;
wire signed [15:0] ay1A_sound, ay1B_sound, ay1C_sound, ay2A_sound, ay2B_sound, ay2C_sound;
gyruss_lpf_light ay1A_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1A_dcrm),
	.out(ay1A_light)
);
gyruss_lpf_medium ay1A_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1A_dcrm),
	.out(ay1A_med)
);
gyruss_lpf_heavy ay1A_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1A_dcrm),
	.out(ay1A_heavy)
);
gyruss_lpf_light ay1B_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1B_dcrm),
	.out(ay1B_light)
);
gyruss_lpf_medium ay1B_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1B_dcrm),
	.out(ay1B_med)
);
gyruss_lpf_heavy ay1B_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1B_dcrm),
	.out(ay1B_heavy)
);
gyruss_lpf_light ay1C_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1C_dcrm),
	.out(ay1C_light)
);
gyruss_lpf_medium ay1C_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1C_dcrm),
	.out(ay1C_med)
);
gyruss_lpf_heavy ay1C_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1C_dcrm),
	.out(ay1C_heavy)
);

gyruss_lpf_light ay2A_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2A_dcrm),
	.out(ay2A_light)
);
gyruss_lpf_medium ay2A_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2A_dcrm),
	.out(ay2A_med)
);
gyruss_lpf_heavy ay2A_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2A_dcrm),
	.out(ay2A_heavy)
);
gyruss_lpf_light ay2B_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2B_dcrm),
	.out(ay2B_light)
);
gyruss_lpf_medium ay2B_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2B_dcrm),
	.out(ay2B_med)
);
gyruss_lpf_heavy ay2B_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2B_dcrm),
	.out(ay2B_heavy)
);
gyruss_lpf_light ay2C_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2C_dcrm),
	.out(ay2C_light)
);
gyruss_lpf_medium ay2C_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2C_dcrm),
	.out(ay2C_med)
);
gyruss_lpf_heavy ay2C_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2C_dcrm),
	.out(ay2C_heavy)
);

//Apply audio filtering based on the state of the low-pass filter controls
always_comb begin
	case(ay1_filter[1:0])
		2'b00: ay1A_sound = ay1A_dcrm;
		2'b01: ay1A_sound = ay1A_light <<< 1;
		2'b10: ay1A_sound = ay1A_med <<< 1;
		2'b11: ay1A_sound = ay1A_heavy <<< 1;
	endcase
	case(ay1_filter[3:2])
		2'b00: ay1B_sound = ay1B_dcrm;
		2'b01: ay1B_sound = ay1B_light <<< 1;
		2'b10: ay1B_sound = ay1B_med <<< 1;
		2'b11: ay1B_sound = ay1B_heavy <<< 1;
	endcase
	case(ay1_filter[5:4])
		2'b00: ay1C_sound = ay1C_dcrm;
		2'b01: ay1C_sound = ay1C_light <<< 1;
		2'b10: ay1C_sound = ay1C_med <<< 1;
		2'b11: ay1C_sound = ay1C_heavy <<< 1;
	endcase
	case(ay2_filter[1:0])
		2'b00: ay2A_sound = ay2A_dcrm;
		2'b01: ay2A_sound = ay2A_light <<< 1;
		2'b10: ay2A_sound = ay2A_med <<< 1;
		2'b11: ay2A_sound = ay2A_heavy <<< 1;
	endcase
	case(ay2_filter[3:2])
		2'b00: ay2B_sound = ay2B_dcrm;
		2'b01: ay2B_sound = ay2B_light <<< 1;
		2'b10: ay2B_sound = ay2B_med <<< 1;
		2'b11: ay2B_sound = ay2B_heavy <<< 1;
	endcase
	case(ay2_filter[5:4])
		2'b00: ay2C_sound = ay2C_dcrm;
		2'b01: ay2C_sound = ay2C_light <<< 1;
		2'b10: ay2C_sound = ay2C_med <<< 1;
		2'b11: ay2C_sound = ay2C_heavy <<< 1;
	endcase
end

//Mix the left and right outputs, then apply an antialiasing low-pass filter to eliminate ringing noise from the
//AY-3-8910s and output the final result (this game has variable low-pass filtering based on how loud the PCB's volume dials
//are set and will be modeled externally)
wire signed [15:0] left_mix = (ay2A_sound + ay2B_sound + ay2C_sound + ay5A_sound + ay5B_sound + ay5C_sound + i8039_sound);
wire signed [15:0] right_mix = (ay1A_sound + ay1B_sound + ay1C_sound + ay3A_sound + ay3B_sound + ay3C_sound + ay4A_sound +
                                ay4B_sound + ay4C_sound);

wire signed [15:0] left_lpf, right_lpf;
gyruss_lpf aalpf_l
(
	.clk(clk_49m),
	.reset(~reset),
	.in(left_mix),
	.out(left_lpf)
);

gyruss_lpf aalpf_r
(
	.clk(clk_49m),
	.reset(~reset),
	.in(right_mix),
	.out(right_lpf)
);

assign sound_l = (ay2A_sound + ay2B_sound + ay2C_sound + ay5A_sound + ay5B_sound + ay5C_sound + i8039_sound);
assign sound_r = (ay1A_sound + ay1B_sound + ay1C_sound + ay3A_sound + ay3B_sound + ay3C_sound + ay4A_sound +
                                ay4B_sound + ay4C_sound);
//assign sound_l = left_lpf;
//assign sound_r = right_lpf;

endmodule

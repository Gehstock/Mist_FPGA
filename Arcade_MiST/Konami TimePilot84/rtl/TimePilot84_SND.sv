//============================================================================
// 
//  Time Pilot '84 sound PCB replica
//  Copyright (C) 2020 Ace, ElectronAsh & Enforcer
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

module TimePilot84_SND
(
	input                reset,
	input                clk_49m, clk_14m,         //Actual clocks: 49.152MHz, 14.31818MHz
	input                sound_on, sound_data,
	input         [15:0] dip_sw,
	input          [1:0] coin,                     //0 = coin 1, 1 = coin 2
	input          [1:0] start_buttons,            //0 = Player 1, 1 = Player 2
	input          [3:0] p1_joystick, p2_joystick, //0 = up, 1 = down, 2 = left, 3 = right
	input          [2:0] p1_buttons,
	input          [1:0] p2_buttons,
	input                btn_service,
	input                ioen, in5,
	input                cpubrd_A5, cpubrd_A6,
	input          [7:0] cpubrd_Din,
	output         [7:0] sndbrd_Dout,
	output signed [15:0] sound
	//The sound board contains a video passthrough but video will instead be tapped
	//straight from the CPU board implementation (this passthrough is redundant for
	//an FPGA implementation)
);

//Clock division for jt49_dcrm2
wire dcrm_cen, clk_12m;
always_ff @(posedge clk_49m) begin
	reg [6:0] div;
	div <= div + 1'd1;
	clk_12m <= div[1];
	dcrm_cen <= !div[6:0];
end

//Remove DC offset from SN76489s (uses jt49_dcrm2 from JT49 by Jotego)
wire signed [15:0] sn0_dcrm, sn2_dcrm, sn3_dcrm;
jt49_dcrm2 #(16) dcrm_sn0
(
	.clk(clk_12m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({8'd0, sn0_unfilt}),
	.dout(sn0_dcrm)
);
jt49_dcrm2 #(16) dcrm_sn2
(
	.clk(clk_12m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({8'd0, sn2_unfilt}),
	.dout(sn2_dcrm)
);
jt49_dcrm2 #(16) dcrm_sn3
(
	.clk(clk_12m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({8'd0, sn3_unfilt}),
	.dout(sn3_dcrm)
);

//Time Pilot '84's SN76489s contain selectable low-pass filters with the following cutoff frequencies:
//3386.28Hz, 723.43Hz, 596.09Hz
//Model this here (the PCB handles this via a 74HC4066 switching IC located at C6)
wire signed [15:0] sn2_filt, sn3_filt;
wire signed [15:0] sn0_light, sn0_med, sn0_heavy;
wire signed [15:0] sn0_sound, sn1_sound, sn2_sound, sn3_sound;
tp84_lpf_light sn0_lpf_light
(
	.clk(clk_12m),
	.reset(~reset),
	.in(sn0_dcrm),
	.out(sn0_light)
);

tp84_lpf_medium sn0_lpf_medium
(
	.clk(clk_12m),
	.reset(~reset),
	.in(sn0_dcrm),
	.out(sn0_med)
);

tp84_lpf_heavy sn0_lpf_heavy
(
	.clk(clk_12m),
	.reset(~reset),
	.in(sn0_dcrm),
	.out(sn0_heavy)
);

tp84_lpf_light sn2_lpf
(
	.clk(clk_12m),
	.reset(~reset),
	.in(sn2_dcrm),
	.out(sn2_filt)
);

tp84_lpf_light sn3_lpf
(
	.clk(clk_12m),
	.reset(~reset),
	.in(sn3_dcrm),
	.out(sn3_filt)
);

always_comb begin
	case(sn0_filter)
		2'b00: sn0_sound = sn0_dcrm;
		2'b01: sn0_sound = sn0_light;
		2'b10: sn0_sound = sn0_med;
		2'b11: sn0_sound = sn0_heavy;
	endcase
end

assign sn2_sound = sn2_filter ? sn2_filt : sn2_dcrm;
assign sn3_sound = sn3_filter ? sn3_filt : sn3_dcrm;

//Apply gain (this game has variable low-pass filtering based on how loud the PCB's volume dial is set and will be modelled
//externally)
assign sound = (sn0_sound + sn2_sound + sn3_sound) * 16'd176;

//Multiplex data output to CPU board
assign sndbrd_Dout =
		~ioen    ? ctrl_dip_mux:
		~in5     ? dip_sw[15:8]:
		8'hFF;

//------------------------------------------------- Chip-level logic modelling -------------------------------------------------//

//Z80 RAM (lower 4 bits)
wire [7:0] sndram_D;
spram #(4, 10) A2
(
	.clk(clk_3m58),
	.we(~n_wr & ~n_sndram_en),
	.addr(sound_A[9:0]),
	.data(sound_Dout[3:0]),
	.q(sndram_D[3:0])
);

//Z80 RAM (upper 4 bits)
spram #(4, 10) A3
(
	.clk(clk_3m58),
	.we(~n_wr & ~n_sndram_en),
	.addr(sound_A[9:0]),
	.data(sound_Dout[7:4]),
	.q(sndram_D[7:4])
);

//A4 contains an unpopulated solder pad for an extra ROM

//Sound ROM
wire [7:0] eprom6_D;
snd_rom A6(
	.clk(clk_3m58),
	.addr(sound_A[12:0]),
	.data(eprom6_D)
);

//Sound CPU (Zilog Z80 - uses T80s version of the T80 soft core)
wire [15:0] sound_A;
wire [7:0] sound_Dout;
wire n_m1, n_mreq, n_iorq, n_rd, n_wr, n_rfsh;
T80s A9
(
	.RESET_n(z80_n_reset),
	.CLK(clk_3m58),
	.CEN(1),
	.INT_n(s_int),
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
//Multiplex data input to Z80
wire [7:0] sound_Din =
		~n_sndrom0_en         ? eprom6_D:
		(~n_sndram_en & n_wr) ? sndram_D:
		~n_cpubrd_en          ? cpubrd_Dlatch:
		~n_timer_en           ? {4'hF, timer}:
		8'hFF;

//Latch data coming in from CPU board
wire [7:0] cpubrd_Dlatch;
ls374 B4
(
	.d(cpubrd_Din),
	.clk(sound_data),
	.out_ctl(1'b0), //Directly modelled, keep permanently enabled
	.q(cpubrd_Dlatch)
);

//Address decoder 1/2
wire n_dec2_en, filter_latch, n_timer_en, n_cpubrd_en, n_sndram_en, n_sndrom1_en, n_sndrom0_en;
ls138 B7
(
	.n_e1(n_rw),
	.n_e2(n_mreq),
	.e3(n_rfsh),
	.a(sound_A[15:13]),
	.o({1'bZ, n_dec2_en, filter_latch, n_timer_en, n_cpubrd_en, n_sndram_en, n_sndrom1_en, n_sndrom0_en})
);

//Generate the following signals:
//Inverted reset, Z80 IRQ clear, reset for Z80, NOR of IORQ and M1
wire reset_h, irq_clr, n_iorq_m1, z80_n_reset;
ls02 B9
(
	.a1(reset),
	.b1(1'b0),
	.y1(reset_h),
	.a2(reset_h),
	.b2(n_iorq_m1),
	.y2(irq_clr),
	.a3(n_iorq),
	.b3(n_m1),
	.y3(n_iorq_m1),
	.a4(reset_h),
	.b4(1'b0),
	.y4(z80_n_reset)
);

//Latch low-pass filter control lines
wire [1:0] sn0_filter;
wire sn2_filter, sn3_filter;
ls174 C7
(
	.d({sound_A[7], sound_A[8], 2'b00, sound_A[3], sound_A[4]}),
	.clk(filter_latch),
	.mr(1'b1),
	.q({sn2_filter, sn3_filter, 2'bZZ, sn0_filter[0], sn0_filter[1]})
);

//AND together read and write outputs from Z80
wire n_rw;
ls08 C8
(
	.a4(n_rd),
	.b4(n_wr),
	.y4(n_rw)
);

//Generate interrupts for the Z80
//Second half of chip unused
wire s_int;
ls74 C9
(
	.n_pre1(1'b1),
	.n_clr1(irq_clr),
	.clk1(sound_on),
	.d1(1'b1),
	.n_q1(s_int)
);

//Multiplex P1 button 3 and DIP switch bank 1 switches 7 and 8 (pull all other inputs high)
wire [7:0] ctrl_dip_mux;
ls253 D2
(
	.i_a({dip_sw[6], 1'b1, p1_buttons[2], 1'b1}),
	.i_b({dip_sw[7], 3'b111}),
	.n_e(2'b00), //Directly modelled on CPU board, keep permanently enabled
	.s({cpubrd_A6, cpubrd_A5}),
	.z(ctrl_dip_mux[7:6])
);

//Multiplex P1/P2 joystick left/right, coin inputs and DIP switch bank 1 switches 2 and 1
ls253 E2
(
	.i_a({dip_sw[1], p2_joystick[2], p1_joystick[2], coin[0]}),
	.i_b({dip_sw[0], p2_joystick[3], p1_joystick[3], coin[1]}),
	.n_e(2'b00), //Directly modelled on CPU board, keep permanently enabled
	.s({cpubrd_A6, cpubrd_A5}),
	.z(ctrl_dip_mux[1:0])
);

//Sound chip 1 (Texas Instruments SN76489 - uses Arnim Laeuger's SN76489 implementation with bugfixes)
wire [7:0] sn0_unfilt;
wire sn0_ready;
sn76489_top E5
(
	.clock_i(clk_1m79),
	.clock_en_i(1),
	.res_n_i(reset),
	.ce_n_i(n_sn0_ce),
	.we_n_i(sn0_ready),
	.ready_o(sn0_ready),
	.d_i(sn_D),
	.aout_o(sn0_unfilt)
);

//Sound chip 2 (Texas Instruments SN76489 - uses Arnim Laeuger's SN76489 implementation with bugfixes)
wire [7:0] sn2_unfilt;
wire sn2_ready;
sn76489_top E6
(
	.clock_i(clk_1m79),
	.clock_en_i(1),
	.res_n_i(reset),
	.ce_n_i(n_sn2_ce),
	.we_n_i(sn2_ready),
	.ready_o(sn2_ready),
	.d_i(sn_D),
	.aout_o(sn2_unfilt)
);

//Sound chip 3 (Texas Instruments SN76489 - uses Arnim Laeuger's SN76489 implementation with bugfixes)
wire [7:0] sn3_unfilt;
wire sn3_ready;
sn76489_top E7
(
	.clock_i(clk_1m79),
	.clock_en_i(1),
	.res_n_i(reset),
	.ce_n_i(n_sn3_ce),
	.we_n_i(sn3_ready),
	.ready_o(sn3_ready),
	.d_i(sn_D),
	.aout_o(sn3_unfilt)
);

//Latch data from Z80 to SN76489s
wire [7:0] sn_D;
ls374 E8
(
	.d({sound_Dout[4], sound_Dout[7], sound_Dout[2:0], sound_Dout[3], sound_Dout[6:5]}),
	.clk(sn_latch),
	.out_ctl(1'b0),
	.q({sn_D[4], sn_D[7], sn_D[2:0], sn_D[3], sn_D[6:5]})
);

//Z80 timer
wire [3:0] timer;
wire tmr2;
ls393 E9
(
	.clk1(tmr_clk),
	.clk2(tmr2),
	.clr1(1'b0),
	.clr2(1'b0),
	.q1({tmr2, 3'bZZZ}),
	.q2(timer)
);

//Multiplex P1/P2 joystick up/down, P1 start button, service credit and DIP switch bank 1
//switches 4 and 3
ls253 F2
(
	.i_a({dip_sw[2], p2_joystick[0], p1_joystick[0], btn_service}),
	.i_b({dip_sw[3], p2_joystick[1], p1_joystick[1], start_buttons[0]}),
	.n_e(2'b00), //Directly modelled on CPU board, keep permanently enabled
	.s({cpubrd_A6, cpubrd_A5}),
	.z(ctrl_dip_mux[3:2])
);

//Generate chip enables for all SN76489s
wire n_sn0_ce, n_sn2_ce, n_sn3_ce;
ls08 F7
(
	.a1(sn3_ready),
	.b1(n_sn3_en),
	.y1(n_sn3_ce),
	.a3(n_sn0_en),
	.b3(sn0_ready),
	.y3(n_sn0_ce),
	.a4(sn2_ready),
	.b4(n_sn2_en),
	.y4(n_sn2_ce)
);

//Address decoder 2/2
wire n_sn0_en, n_sn2_en, n_sn3_en, sn_latch;
ls138 F8
(
	.n_e1(n_dec2_en),
	.n_e2(1'b0),
	.e3(1'b1),
	.a(sound_A[2:0]),
	.o({3'bZZZ, n_sn3_en, n_sn2_en, 1'bZ, n_sn0_en, sn_latch})
);

//Clock division
wire div2, clk_3m58, clk_1m79, tmr_clk;
ls393 F9
(
	.clk1(n_clk_14m),
	.clk2(div2),
	.clr1(1'b0),
	.clr2(1'b0),
	.q1({div2, clk_1m79, clk_3m58, 1'bZ}),
	.q2({tmr_clk, 3'bZZZ})
);

//Multiplex P2 start button, player buttons 1/2 and DIP switch bank 1 switches 6 and 5
ls253 G1
(
	.i_a({dip_sw[4], p2_buttons[0], p1_buttons[0], start_buttons[1]}),
	.i_b({dip_sw[5], p2_buttons[1], p1_buttons[1], 1'b1}),
	.n_e(2'b00), //Directly modelled on CPU board, keep permanently enabled
	.s({cpubrd_A6, cpubrd_A5}),
	.z(ctrl_dip_mux[5:4])
);

//Invert 14.318181MHz clock for division with the 74LS393 at F9 (the 74LS393 works on the falling edge
//of an incoming clock)
wire n_clk_14m;
ls04 G9
(
	.a3(clk_14m),
	.y3(n_clk_14m)
);

endmodule

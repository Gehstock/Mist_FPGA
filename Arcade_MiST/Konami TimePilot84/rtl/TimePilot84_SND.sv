//============================================================================
// 
//  Time Pilot '84 sound PCB replica
//  Based on the simulation model
//  Copyright (C) 2020 Ace, ElectronAsh & Enforcer
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
	output signed [15:0] sound,

	input                ep6_cs_i,
	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr
	//The sound board contains a video passthrough but video will instead be tapped
	//straight from the CPU board implementation (this passthrough is redundant for
	//an FPGA implementation)
);

wire n_reset = reset;

reg [7:0] ctrl_dip_mux;

always @(*) begin
	case({cpubrd_A6, cpubrd_A5})
		2'b00: ctrl_dip_mux = { 1'b1, 1'b1, 1'b1, start_buttons[1], start_buttons[0], btn_service, coin[1:0] };
		2'b01: ctrl_dip_mux = { 1'b1, p1_buttons[2], p1_buttons[1], p1_buttons[0], p1_joystick[1], p1_joystick[0], p1_joystick[3], p1_joystick[2] };
		2'b10: ctrl_dip_mux = { 1'b1, 1'b1, p2_buttons[1], p2_buttons[0], p2_joystick[1], p2_joystick[0], p2_joystick[3], p2_joystick[2] };
		2'b11: ctrl_dip_mux = dip_sw[7:0];
		default: ;
	endcase
end

//Multiplex data output to CPU board
assign sndbrd_Dout =
		~ioen    ? ctrl_dip_mux:
		~in5     ? dip_sw[15:8]:
		8'hFF;

//Remove DC offset from SN76489s (uses jt49_dcrm2 from JT49 by Jotego)
wire signed [15:0] sn0_dcrm, sn2_dcrm, sn3_dcrm;
jt49_dcrm2 #(16) dcrm_sn0
(
	.clk(clk_14m),
	.cen(1'b1),
	.rst(n_reset),
	.din({8'd0, sn0_unfilt}),
	.dout(sn0_dcrm)
);
jt49_dcrm2 #(16) dcrm_sn2
(
	.clk(clk_14m),
	.cen(1'b1),
	.rst(n_reset),
	.din({8'd0, sn2_unfilt}),
	.dout(sn2_dcrm)
);
jt49_dcrm2 #(16) dcrm_sn3
(
	.clk(clk_14m),
	.cen(1'b1),
	.rst(n_reset),
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
	.clk(clk_14m),
	.reset(n_reset),
	.in(sn0_dcrm),
	.out(sn0_light)
);

tp84_lpf_medium sn0_lpf_medium
(
	.clk(clk_14m),
	.reset(n_reset),
	.in(sn0_dcrm),
	.out(sn0_med)
);

tp84_lpf_heavy sn0_lpf_heavy
(
	.clk(clk_14m),
	.reset(n_reset),
	.in(sn0_dcrm),
	.out(sn0_heavy)
);

tp84_lpf_light sn2_lpf
(
	.clk(clk_14m),
	.reset(n_reset),
	.in(sn2_dcrm),
	.out(sn2_filt)
);

tp84_lpf_light sn3_lpf
(
	.clk(clk_14m),
	.reset(n_reset),
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

//Clock division
reg        clk_3m58_en;
reg        clk_1m79_en;
reg  [7:0] timer;
always @(posedge clk_14m) begin
	reg [7:0] cnt;

	cnt <= cnt + 1'd1;
	clk_3m58_en <= cnt[1:0] == 2'b00;
	clk_1m79_en <= cnt[2:0] == 3'b000;
	if (cnt == 0) timer <= timer + 1'd1;
end

//Z80 RAM (lower 4 bits)
wire [7:0] sndram_D;
spram #(4, 10) A2
(
	.clk(clk_14m),
	.we(~n_wr & ~n_sndram_en),
	.addr(sound_A[9:0]),
	.data(sound_Dout[3:0]),
	.q(sndram_D[3:0])
);

//Z80 RAM (upper 4 bits)
spram #(4, 10) A3
(
	.clk(clk_14m),
	.we(~n_wr & ~n_sndram_en),
	.addr(sound_A[9:0]),
	.data(sound_Dout[7:4]),
	.q(sndram_D[7:4])
);

//A4 contains an unpopulated solder pad for an extra ROM

//Sound ROM
wire [7:0] eprom6_D;

eprom_6 A6
(
	.ADDR(sound_A[12:0]),
	.CLK(clk_14m),
	.DATA(eprom6_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep6_cs_i),
	.WR(ioctl_wr)
);

//Sound CPU (Zilog Z80 - uses T80s version of the T80 soft core)
wire [15:0] sound_A;
wire [7:0] sound_Dout;
wire n_m1, n_mreq, n_iorq, n_rd, n_wr, n_rfsh;
T80s A9
(
	.RESET_n(n_reset),
	.CLK(clk_14m),
	.CEN(clk_3m58_en),
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

//Address decoder 1/2
wire n_dec2_en, filter_latch, n_timer_en, n_cpubrd_en, n_sndram_en, n_sndrom1_en, n_sndrom0_en;
always @(*) begin
	n_dec2_en = 1;
	filter_latch = 1;
	n_timer_en = 1;
	n_cpubrd_en = 1;
	n_sndram_en = 1;
	n_sndrom1_en = 1;
	n_sndrom0_en = 1;
	if (!((n_rd & n_wr) | n_mreq | !n_rfsh))
		case(sound_A[15:13])
			3'b000: n_sndrom0_en = 0;
			3'b001: n_sndrom1_en = 0;
			3'b010: n_sndram_en = 0;
			3'b011: n_cpubrd_en = 0;
			3'b100: n_timer_en = 0;
			3'b101: filter_latch = 0;
			3'b110: n_dec2_en = 0;
			default :;
		endcase
end

//Address decoder 2/2
wire n_sn0_en, n_sn2_en, n_sn3_en, sn_latch;
always @(*) begin
	n_sn0_en = 1;
	n_sn2_en = 1;
	n_sn3_en = 1;
	sn_latch = 1;
	if (!n_dec2_en)
		case(sound_A[2:0])
			3'b000: sn_latch = 0;
			3'b001: n_sn0_en = 0;
			3'b011: n_sn2_en = 0;
			3'b100: n_sn3_en = 0;
			default: ;
		endcase
end

//Multiplex data input to Z80
wire [7:0] sound_Din =
		~n_sndrom0_en         ? eprom6_D:
		(~n_sndram_en & n_wr) ? sndram_D:
		~n_cpubrd_en          ? cpubrd_Dlatch:
		~n_timer_en           ? {4'hF, timer[7:4]}:
		8'hFF;

//Latch data coming in from CPU board
wire [7:0] cpubrd_Dlatch;
always @(posedge clk_49m) begin
	reg sound_data_d, sound_data_d2, sound_data_d3;
	// synchronize between the cpu board and the sound board clock domains
	{sound_data_d3, sound_data_d2, sound_data_d} <= {sound_data_d2, sound_data_d, sound_data};
	if (sound_data_d3 & !sound_data_d2) cpubrd_Dlatch <= cpubrd_Din;
end

//Latch low-pass filter control lines
//Latch data from Z80 to SN76489s
wire [1:0] sn0_filter;
wire sn2_filter, sn3_filter;
wire [7:0] sn_D;

always @(posedge clk_49m) begin
	if (!filter_latch) {sn2_filter, sn3_filter, sn0_filter[0], sn0_filter[1]} <= {sound_A[7], sound_A[8], sound_A[3], sound_A[4]}; // C7
	if (!sn_latch) sn_D <= sound_Dout;  // E8
end

//Generate interrupts for the Z80
reg s_int;
always @(posedge clk_49m) begin
	reg sound_on_d3, sound_on_d2, sound_on_d;
	{sound_on_d3, sound_on_d2, sound_on_d} <= {sound_on_d2, sound_on_d, sound_on};
	if (!n_reset) s_int <= 1;
	else if (!(n_iorq | n_m1)) s_int <= 1;
	else if (sound_on_d3 & !sound_on_d2) s_int <= 0;
end

//Generate chip enables for all SN76489s
wire n_sn0_ce = sn0_ready & n_sn0_en;
wire n_sn2_ce = sn2_ready & n_sn2_en;
wire n_sn3_ce = sn3_ready & n_sn3_en;

//Sound chip 1 (Texas Instruments SN76489 - uses Arnim Laeuger's SN76489 implementation with bugfixes)
wire [7:0] sn0_unfilt;
wire sn0_ready;
sn76489_top E5
(
	.clock_i(clk_14m),
	.clock_en_i(clk_1m79_en),
	.res_n_i(n_reset),
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
	.clock_i(clk_14m),
	.clock_en_i(clk_1m79_en),
	.res_n_i(n_reset),
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
	.clock_i(clk_14m),
	.clock_en_i(clk_1m79_en),
	.res_n_i(n_reset),
	.ce_n_i(n_sn3_ce),
	.we_n_i(sn3_ready),
	.ready_o(sn3_ready),
	.d_i(sn_D),
	.aout_o(sn3_unfilt)
);

endmodule

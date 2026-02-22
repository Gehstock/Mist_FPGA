//============================================================================
// 
//  Time Pilot sound PCB model
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

module TimePilot_SND
(
	input                reset,
	input                clk_49m,         //Actual frequency: 49.152MHz
	input         [15:0] dip_sw,
	input          [1:0] coin,                     //0 = coin 1, 1 = coin 2
	input          [1:0] start_buttons,            //0 = Player 1, 1 = Player 2
	input          [3:0] p1_joystick, p2_joystick, //0 = up, 1 = down, 2 = left, 3 = right
	input                p1_fire,
	input                p2_fire,
	input                btn_service,
	input                cpubrd_A5, cpubrd_A6,
	input                cs_controls_dip1, cs_dip2,
	input                irq_trigger, cs_sounddata,
	input          [7:0] cpubrd_Din,
	
	output         [7:0] controls_dip,
	output signed [15:0] sound,
	
	//This input serves to select different fractional dividers to acheive 1.789772MHz for the sound Z80 and AY-3-8910s
	//depending on whether Time Pilot runs with original or underclocked timings to normalize sync frequencies
	input                underclock,
	
	input                ep7_cs_i,
	output		  [12:0] Sound_Rom_Addr,
	input				[7:0] Sound_Rom_Data,
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
                      8'hFF;

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate clock enables for sound data and IRQ logic, and DC offset removal
reg [8:0] div = 9'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 9'd1;
end
wire cen_3m = !div[3:0];
wire cen_dcrm = !div;

//Generate 1.789772MHz clock enable for Z80 and AY-3-8910s, clock enable for AY-3-8910 timer
//(uses Jotego's fractional clock divider from JTFRAME)
wire [9:0] sound_cen_n = underclock ? 10'd31 : 10'd30;
wire [9:0] sound_cen_m = underclock ? 10'd843 : 10'd824;
wire cen_1m79, cen_timer;
jtframe_frac_cen #(10) sound_cen
(
	.clk(clk_49m),
	.n(sound_cen_n),
	.m(sound_cen_m),
	.cen({cen_timer, 8'bZZZZZZZZ, cen_1m79})
);

//------------------------------------------------------------ CPU -------------------------------------------------------------//

//Sound CPU - Zilog Z80 (uses T80s version of the T80 soft core)
wire [15:0] sound_A;
wire [7:0] sound_Dout;
wire n_m1, n_mreq, n_iorq, n_rd, n_wr, n_rfsh;
T80s C8
(
	.RESET_n(reset),
	.CLK(clk_49m),
	.CEN(cen_1m79),
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
wire cs_soundrom = (~n_mreq & n_rfsh & (sound_A[15:13] == 3'b000));
wire cs_soundram = (~n_mreq & n_rfsh & (sound_A[15:12] == 4'b0011));
wire cs_ay1_1 = (~n_mreq & n_rfsh & (sound_A[15:12] == 4'b0100));
wire cs_ay1_2 = (~n_mreq & n_rfsh & (sound_A[15:12] == 4'b0101));
wire cs_ay2_1 = (~n_mreq & n_rfsh & (sound_A[15:12] == 4'b0110));
wire cs_ay2_2 = (~n_mreq & n_rfsh & (sound_A[15:12] == 4'b0111));
wire cs_lpf = ~(n_wr | ~sound_A[15]);
//Multiplex data input to Z80
wire [7:0] sound_Din =
		cs_soundrom           ? eprom7_D:
		(cs_soundram & n_wr)  ? sndram_D:
		(~ay1_bdir & ay1_bc1) ? ay1_D:
		(~ay2_bdir & ay2_bc1) ? ay2_D:
		8'hFF;

//Sound ROM
assign Sound_Rom_Addr = sound_A[12:0];
wire [7:0] eprom7_D = Sound_Rom_Data;
//eprom_7 A6
//(
//	.ADDR(sound_A[12:0]),
//	.CLK(clk_49m),
//	.DATA(eprom7_D),
//	.ADDR_DL(ioctl_addr),
//	.CLK_DL(clk_49m),
//	.DATA_IN(ioctl_data),
//	.CS_DL(ep7_cs_i),
//	.WR(ioctl_wr)
//);

//Sound RAM (lower 4 bits)
wire [7:0] sndram_D;
spram #(4, 10) A2
(
	.clk(clk_49m),
	.we(cs_soundram & ~n_wr),
	.addr(sound_A[9:0]),
	.data(sound_Dout[3:0]),
	.q(sndram_D[3:0])
);

//Sound RAM (upper 4 bits)
spram #(4, 10) A3
(
	.clk(clk_49m),
	.we(cs_soundram & ~n_wr),
	.addr(sound_A[9:0]),
	.data(sound_Dout[7:4]),
	.q(sndram_D[7:4])
);

//Generate Z80 interrupts
wire irq_clr = (~reset | ~(n_iorq | n_m1));
reg n_irq = 1;
always_ff @(posedge clk_49m or posedge irq_clr) begin
	if(irq_clr)
		n_irq <= 1;
	else if(cen_3m && irq_trigger)
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

//Generate BC1 and BDIR signals for both AY-3-8910s
wire ay1_bdir = ~(~cs_ay1_2 & (n_wr | ~cs_ay1_1));
wire ay1_bc1 = ~(~cs_ay1_2 & (n_rd | ~cs_ay1_1));
wire ay2_bdir = ~(~cs_ay2_2 & (n_wr | ~cs_ay2_1));
wire ay2_bc1 = ~(~cs_ay2_2 & (n_rd | ~cs_ay2_1));

//AY-3-8910 timer (code adapted from MiSTer-X's Gyruss core, which uses an identical timer)
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

//Latch sound data coming in from CPU board
reg [7:0] sound_D = 8'd0;
always_ff @(posedge clk_49m) begin
	if(!reset)
		sound_D <= 8'd0;
	else if(cen_3m && cs_sounddata)
		sound_D <= cpubrd_Din;
end

//Sound chip 1 (AY-3-8910 - uses JT49 by Jotego)
wire [7:0] ay1_D;
wire [7:0] ay1A_raw, ay1B_raw, ay1C_raw;
jt49_bus #(.COMP(3'b100)) F7
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
	.IOA_in(sound_D),
	.IOB_in({timer, 4'b0000})
);

//Sound chip 2 (AY-3-8910 - uses JT49 by Jotego)
wire [7:0] ay2_D;
wire [7:0] ay2A_raw, ay2B_raw, ay2C_raw;
jt49_bus #(.COMP(3'b100)) F8
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
	.C(ay2C_raw)
);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//Apply gain and remove DC offset from AY-3-8910s (uses jt49_dcrm2 from JT49 by Jotego for DC offset removal)
wire signed [15:0] ay1A_dcrm, ay1B_dcrm, ay1C_dcrm, ay2A_dcrm, ay2B_dcrm, ay2C_dcrm;
jt49_dcrm2 #(16) dcrm_ay1A
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({3'd0, ay1A_raw, 5'd0}),
	.dout(ay1A_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay1B
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({3'd0, ay1B_raw, 5'd0}),
	.dout(ay1B_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay1C
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({3'd0, ay1C_raw, 5'd0}),
	.dout(ay1C_dcrm)
);

jt49_dcrm2 #(16) dcrm_ay2A
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({3'd0, ay2A_raw, 5'd0}),
	.dout(ay2A_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay2B
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({3'd0, ay2B_raw, 5'd0}),
	.dout(ay2B_dcrm)
);
jt49_dcrm2 #(16) dcrm_ay2C
(
	.clk(clk_49m),
	.cen(cen_dcrm),
	.rst(~reset),
	.din({3'd0, ay2C_raw, 5'd0}),
	.dout(ay2C_dcrm)
);

//Time Pilot's AY-3-8910s contain selectable low-pass filters with the following cutoff frequencies:
//3386.28Hz, 723.43Hz, 596.09Hz
//Model this here (the PCB handles this via 3 74HC4066 switching ICs located at A2, A3 and A4)
wire signed [15:0] ay1A_light, ay1A_med, ay1A_heavy, ay1B_light, ay1B_med, ay1B_heavy, ay1C_light, ay1C_med, ay1C_heavy;
wire signed [15:0] ay2A_light, ay2A_med, ay2A_heavy, ay2B_light, ay2B_med, ay2B_heavy, ay2C_light, ay2C_med, ay2C_heavy;
wire signed [15:0] ay1A_sound, ay1B_sound, ay1C_sound, ay2A_sound, ay2B_sound, ay2C_sound;
tp_lpf_light ay1A_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1A_dcrm),
	.out(ay1A_light)
);
tp_lpf_medium ay1A_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1A_dcrm),
	.out(ay1A_med)
);
tp_lpf_heavy ay1A_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1A_dcrm),
	.out(ay1A_heavy)
);
tp_lpf_light ay1B_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1B_dcrm),
	.out(ay1B_light)
);
tp_lpf_medium ay1B_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1B_dcrm),
	.out(ay1B_med)
);
tp_lpf_heavy ay1B_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1B_dcrm),
	.out(ay1B_heavy)
);
tp_lpf_light ay1C_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1C_dcrm),
	.out(ay1C_light)
);
tp_lpf_medium ay1C_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1C_dcrm),
	.out(ay1C_med)
);
tp_lpf_heavy ay1C_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay1C_dcrm),
	.out(ay1C_heavy)
);

tp_lpf_light ay2A_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2A_dcrm),
	.out(ay2A_light)
);
tp_lpf_medium ay2A_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2A_dcrm),
	.out(ay2A_med)
);
tp_lpf_heavy ay2A_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2A_dcrm),
	.out(ay2A_heavy)
);
tp_lpf_light ay2B_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2B_dcrm),
	.out(ay2B_light)
);
tp_lpf_medium ay2B_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2B_dcrm),
	.out(ay2B_med)
);
tp_lpf_heavy ay2B_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2B_dcrm),
	.out(ay2B_heavy)
);
tp_lpf_light ay2C_lpf_light
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2C_dcrm),
	.out(ay2C_light)
);
tp_lpf_medium ay2C_lpf_medium
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2C_dcrm),
	.out(ay2C_med)
);
tp_lpf_heavy ay2C_lpf_heavy
(
	.clk(clk_49m),
	.reset(~reset),
	.in(ay2C_dcrm),
	.out(ay2C_heavy)
);

//Latch low-pass filter control lines
reg [1:0] ay1_filter_A = 2'd0;
reg [1:0] ay1_filter_B = 2'd0;
reg [1:0] ay1_filter_C = 2'd0;
reg [1:0] ay2_filter_A = 2'd0;
reg [1:0] ay2_filter_B = 2'd0;
reg [1:0] ay2_filter_C = 2'd0;
always_ff @(posedge clk_49m) begin
	if(cen_1m79 && cs_lpf) begin
		ay1_filter_A <= {sound_A[6], sound_A[7]};
		ay1_filter_B <= {sound_A[8], sound_A[9]};
		ay1_filter_C <= {sound_A[10], sound_A[11]};
		ay2_filter_A <= {sound_A[0], sound_A[1]};
		ay2_filter_B <= {sound_A[2], sound_A[3]};
		ay2_filter_C <= {sound_A[4], sound_A[5]};
	end
end

always_comb begin
	case(ay1_filter_A)
		2'b00: ay1A_sound = ay1A_dcrm;
		2'b01: ay1A_sound = ay1A_light;
		2'b10: ay1A_sound = ay1A_med;
		2'b11: ay1A_sound = ay1A_heavy;
	endcase
	case(ay1_filter_B)
		2'b00: ay1B_sound = ay1B_dcrm;
		2'b01: ay1B_sound = ay1B_light;
		2'b10: ay1B_sound = ay1B_med;
		2'b11: ay1B_sound = ay1B_heavy;
	endcase
	case(ay1_filter_C)
		2'b00: ay1C_sound = ay1C_dcrm;
		2'b01: ay1C_sound = ay1C_light;
		2'b10: ay1C_sound = ay1C_med;
		2'b11: ay1C_sound = ay1C_heavy;
	endcase
	case(ay2_filter_A)
		2'b00: ay2A_sound = ay2A_dcrm;
		2'b01: ay2A_sound = ay2A_light;
		2'b10: ay2A_sound = ay2A_med;
		2'b11: ay2A_sound = ay2A_heavy;
	endcase
	case(ay2_filter_B)
		2'b00: ay2B_sound = ay2B_dcrm;
		2'b01: ay2B_sound = ay2B_light;
		2'b10: ay2B_sound = ay2B_med;
		2'b11: ay2B_sound = ay2B_heavy;
	endcase
	case(ay2_filter_C)
		2'b00: ay2C_sound = ay2C_dcrm;
		2'b01: ay2C_sound = ay2C_light;
		2'b10: ay2C_sound = ay2C_med;
		2'b11: ay2C_sound = ay2C_heavy;
	endcase
end

//Mix all AY-3-8910s (this game has variable low-pass filtering based on how loud the PCB's volume dial is set and will be modeled
//externally)
//Also invert the phase as the original PCB uses an op-amp wired as an inverting amplifier prior to the power amp
assign sound = 16'hFFFF - (ay1A_sound + ay1B_sound + ay1C_sound + ay2A_sound + ay2B_sound + ay2C_sound);

endmodule

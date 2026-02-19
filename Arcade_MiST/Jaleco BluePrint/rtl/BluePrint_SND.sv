//============================================================================
//
//  Blue Print sound PCB model
//  Copyright (C) 2026 Rodimus
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

module BluePrint_SND
(
	input                reset,
	input				 pause,
	input                clk_49m,         // Master clock: 49.152MHz

	// Sound command interface from main CPU
	input          [7:0] sound_cmd,       // Sound command byte from main CPU latch
	input                sound_cmd_wr,    // Pulse: main CPU wrote to 0xD000

	// DIP switches (directly from MiSTer OSD)
	input         [15:0] dip_sw,          // [7:0] = bank 1, [15:8] = bank 2

	// DIP switch readback to main CPU
	output         [7:0] dipsw_readback,  // Value main CPU reads at 0xC003

	// Audio output
	output signed [15:0] sound,

	// VBlank input for IRQ generation (directly from video timing)
	input                vblank,

	// ROM loading
	input                snd_rom1_cs_i,   // Directly from ioctl for sound ROM 1
	input                snd_rom2_cs_i,   // Directly from ioctl for sound ROM 2
	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr
);

//------------------------------------------------------- Clock division -------------------------------------------------------//

// Generate 1.25 MHz clock enable for sound Z80 and AY1, and 0.625 MHz for AY2
// 49.152 MHz * 25/983 ≈ 1.2489 MHz ≈ 1.25 MHz
// W=2: cen[0] = 1.25 MHz, cen[1] = 0.625 MHz
wire cen_1m25, cen_0m625;
jtframe_frac_cen #(2) sound_cen
(
	.clk(clk_49m),
	.n(10'd25),
	.m(10'd983),
	.cen({cen_0m625, cen_1m25})
);

// DC removal filter clock
reg [8:0] div = 9'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 9'd1;
end
wire cen_dcrm = !div;

//------------------------------------------------------------ CPU -------------------------------------------------------------//

// Sound CPU - Zilog Z80 (uses T80s version of the T80 soft core)
wire [15:0] sound_A;
wire [7:0] sound_Dout;
wire n_m1, n_mreq, n_iorq, n_rd, n_wr, n_rfsh;
T80s C8
(
	.RESET_n(reset),
	.CLK(clk_49m),
	.CEN(cen_1m25 & ~pause),
	.INT_n(n_irq),
	.NMI_n(n_nmi),
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

// Address decoding for Z80
// ROM1: 0x0000-0x1FFF (A[15:13] = 000)
wire cs_rom1 = ~n_mreq & n_rfsh & ~sound_A[15] & ~sound_A[14] & ~sound_A[13];
// ROM2: 0x2000-0x3FFF (A[15:13] = 001)
wire cs_rom2 = ~n_mreq & n_rfsh & ~sound_A[15] & ~sound_A[14] &  sound_A[13];
// RAM:  0x4000-0x5FFF (A[15:13] = 010)
wire cs_ram  = ~n_mreq & n_rfsh & ~sound_A[15] &  sound_A[14] & ~sound_A[13];
// AY1:  0x6000-0x7FFF (A[15:13] = 011)
wire cs_ay1_w = ~n_mreq & n_rfsh & ~sound_A[15] & sound_A[14] & sound_A[13] & ~n_wr;
wire cs_ay1_r = ~n_mreq & n_rfsh & ~sound_A[15] & sound_A[14] & sound_A[13] & ~n_rd;
// AY2:  0x8000-0x9FFF (A[15:13] = 100)
wire cs_ay2_w = ~n_mreq & n_rfsh &  sound_A[15] & ~sound_A[14] & ~sound_A[13] & ~n_wr;
wire cs_ay2_r = ~n_mreq & n_rfsh &  sound_A[15] & ~sound_A[14] & ~sound_A[13] & ~n_rd;

// AY bus control signals
// AY1: 0x6000/0x6001 write (address_data_w), 0x6002 read (data_r)
wire ay1_bdir = cs_ay1_w & (sound_A[1:0] != 2'b10); // write to 0x6000 or 0x6001
wire ay1_bc1  = (cs_ay1_w & ~sound_A[0] & ~sound_A[1]) | // address select: write to 0x6000
                (cs_ay1_r & sound_A[1]);                   // data read: read from 0x6002

// AY2: 0x8000/0x8001 write (address_data_w), 0x8002 read (data_r)
wire ay2_bdir = cs_ay2_w & (sound_A[1:0] != 2'b10);
wire ay2_bc1  = (cs_ay2_w & ~sound_A[0] & ~sound_A[1]) |
                (cs_ay2_r & sound_A[1]);

// Data reading flags for mux
wire ay1_reading = ~ay1_bdir & ay1_bc1;
wire ay2_reading = ~ay2_bdir & ay2_bc1;

// Multiplex data input to Z80
wire [7:0] sound_Din = cs_rom1           ? rom1_D :
                       cs_rom2           ? rom2_D :
                       (cs_ram & n_wr)   ? sndram_D :
                       ay1_reading       ? ay1_D :
                       ay2_reading       ? ay2_D :
                       8'hFF;

//-------------------------------------------------------------- ROMs ----------------------------------------------------------//

// Sound ROM 1 (0x0000-0x0FFF, mirrored at 0x1000-0x1FFF)
wire [7:0] rom1_D;
eprom_4k snd_rom1
(
	.CLK(clk_49m),
	.ADDR(sound_A[11:0]),
	.CLK_DL(clk_49m),
	.ADDR_DL(ioctl_addr),
	.DATA_IN(ioctl_data),
	.CS_DL(snd_rom1_cs_i),
	.WR(ioctl_wr),
	.DATA(rom1_D)
);

// Sound ROM 2 (0x2000-0x2FFF, mirrored at 0x3000-0x3FFF)
wire [7:0] rom2_D;
eprom_4k snd_rom2
(
	.CLK(clk_49m),
	.ADDR(sound_A[11:0]),
	.CLK_DL(clk_49m),
	.ADDR_DL(ioctl_addr),
	.DATA_IN(ioctl_data),
	.CS_DL(snd_rom2_cs_i),
	.WR(ioctl_wr),
	.DATA(rom2_D)
);

//-------------------------------------------------------------- RAM -----------------------------------------------------------//

// Sound RAM (lower 4 bits) - 1KB at 0x4000-0x43FF
wire [7:0] sndram_D;
spram #(4, 10) A2
(
	.clk(clk_49m),
	.we(cs_ram & ~n_wr),
	.addr(sound_A[9:0]),
	.data(sound_Dout[3:0]),
	.q(sndram_D[3:0])
);

// Sound RAM (upper 4 bits)
spram #(4, 10) A3
(
	.clk(clk_49m),
	.we(cs_ram & ~n_wr),
	.addr(sound_A[9:0]),
	.data(sound_Dout[7:4]),
	.q(sndram_D[7:4])
);

//--------------------------------------------------------- Interrupts ---------------------------------------------------------//

// IRQ generation - 240 Hz periodic (4x per frame at 60 Hz)
// 1,250,000 Hz / 240 Hz = 5208.3 cycles
reg [12:0] irq_cnt = 13'd0;
reg irq_pulse = 1'b0;
always_ff @(posedge clk_49m) begin
	if (cen_1m25) begin
		if (irq_cnt == 13'd5207) begin
			irq_cnt <= 13'd0;
			irq_pulse <= 1'b1;
		end else begin
			irq_cnt <= irq_cnt + 13'd1;
			irq_pulse <= 1'b0;
		end
	end else
		irq_pulse <= 1'b0;
end

// IRQ latch - cleared by interrupt acknowledge
wire irq_clr = (~reset | ~(n_iorq | n_m1));
reg n_irq = 1'b1;
always_ff @(posedge clk_49m or posedge irq_clr) begin
	if (irq_clr)
		n_irq <= 1'b1;
	else if (irq_pulse)
		n_irq <= 1'b0;
end

// NMI generation - pulse triggered by main CPU writing to 0xD000
reg n_nmi = 1'b1;
reg sound_cmd_wr_last = 1'b0;
always_ff @(posedge clk_49m) begin
	sound_cmd_wr_last <= sound_cmd_wr;
	if (!sound_cmd_wr_last && sound_cmd_wr)
		n_nmi <= 1'b0;  // Assert NMI on rising edge of write
	else if (cen_1m25)
		n_nmi <= 1'b1;  // Release after one CPU cycle
end

//--------------------------------------------------------- Sound chips --------------------------------------------------------//

// Sound chip 1 (AY-3-8910 @ 1.25 MHz - uses JT49 by Jotego)
// Port A = output: DIP switch data written by sound CPU → main CPU reads at 0xC003
// Port B = input:  sound command latch from main CPU
wire [7:0] ay1_D;
wire [7:0] ay1A_raw, ay1B_raw, ay1C_raw;
jt49_bus #(.COMP(3'b100)) ay1_chip
(
	.rst_n(reset),
	.clk(clk_49m),
	.clk_en(cen_1m25 & ~pause),
	.bdir(ay1_bdir),
	.bc1(ay1_bc1),
	.din(sound_Dout),
	.sel(1),
	.dout(ay1_D),
	.A(ay1A_raw),
	.B(ay1B_raw),
	.C(ay1C_raw),
	.IOA_out(dipsw_readback),
	.IOB_in(sound_cmd)
);

// Sound chip 2 (AY-3-8910 @ 0.625 MHz - HALF RATE - uses JT49 by Jotego)
// Port A = input: DIP switch bank 1
// Port B = input: DIP switch bank 2
wire [7:0] ay2_D;
wire [7:0] ay2A_raw, ay2B_raw, ay2C_raw;
jt49_bus #(.COMP(3'b100)) ay2_chip
(
	.rst_n(reset),
	.clk(clk_49m),
	.clk_en(cen_0m625 & ~pause),
	.bdir(ay2_bdir),
	.bc1(ay2_bc1),
	.din(sound_Dout),
	.sel(1),
	.dout(ay2_D),
	.A(ay2A_raw),
	.B(ay2B_raw),
	.C(ay2C_raw),
	.IOA_in(dip_sw[7:0]),
	.IOB_in(dip_sw[15:8])
);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

// Apply gain and remove DC offset from AY-3-8910s (uses jt49_dcrm2 from JT49 by Jotego)
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

// Mix all AY-3-8910 channels (no per-channel filters for Blue Print)
// Invert phase as the original PCB uses an inverting amplifier prior to the power amp
assign sound = 16'hFFFF - (ay1A_dcrm + ay1B_dcrm + ay1C_dcrm + ay2A_dcrm + ay2B_dcrm + ay2C_dcrm);

endmodule

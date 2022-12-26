
// Project URL: https://github.com/dnotq/sn76489_audio
// Automatic Verilog conversion done with Yosys/GHDL

// --
// -- SN76489 Complex Sound Generator
// -- Matthew Hagerty
// -- July 2020
// -- https://dnotq.io
// --

// -- Released under the 3-Clause BSD License:
// --
// -- Copyright 2020 Matthew Hagerty (matthew <at> dnotq <dot> io)
// --
// -- Redistribution and use in source and binary forms, with or without
// -- modification, are permitted provided that the following conditions are met:
// --
// -- 1. Redistributions of source code must retain the above copyright notice,
// -- this list of conditions and the following disclaimer.
// --
// -- 2. Redistributions in binary form must reproduce the above copyright
// -- notice, this list of conditions and the following disclaimer in the
// -- documentation and/or other materials provided with the distribution.
// --
// -- 3. Neither the name of the copyright holder nor the names of its
// -- contributors may be used to endorse or promote products derived from this
// -- software without specific prior written permission.
// --
// -- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// -- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// -- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// -- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// -- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// -- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// -- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// -- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// -- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// -- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// -- POSSIBILITY OF SUCH DAMAGE.

// --
// -- A huge amount of effort has gone into making this core as accurate as
// -- possible to the real IC, while at the same time making it usable in all
// -- digital SoC designs, i.e. retro-computer and game systems, etc.  Design
// -- elements from the real IC were used and implemented when possible, with any
// -- work-around or changes noted along with the reasons.
// --
// -- Synthesized and FPGA proven:
// --
// --   * Xilinx Spartan-6 LX16, SoC 21.477MHz system clock, 3.58MHz clock-enable.
// --
// --
// -- References:
// --
// --   * The SN76489 datasheet
// --   * Insight gained from the AY-3-8910/YM-2149 die-shot and reverse-engineered
// --     schematics (similar audio chips from the same era).
// --   * Real hardware (SN76489 in a ColecoVision game console).
// --   * Chip quirks, use, and abuse details from friends and retro enthusiasts.
// --
// --
// -- Generates:
// --
// --   * Unsigned 12-bit output for each channel.
// --   * Unsigned 14-bit summation of the four channels.
// --   * Signed 14-bit PCM summation of the four channels, with each channel
// --     converted to -/+ zero-centered level or -/+ full-range level.
// --
// -- The tone counters are period-limited to prevent the very high frequency
// -- outputs that the original IC is capable of producing.  Frequencies above
// -- 20KHz cause problems in all-digital systems with sampling rates around
// -- 44.1KHz to 48KHz.  The primary use of these high frequencies was as a
// -- carrier for amplitude modulated (AM) audio.  The high frequency would be
// -- filtered out by external electronics, leaving only the low frequency audio.
// --
// -- When the tone counters are limited, the output square-wave is disabled, but
// -- the amplitude can still be changed, which allows the A.M. technique to still
// -- work in a digital Soc.
// --
// -- I/O requires at least two clock-enable cycles.  This could be modified to
// -- operate faster, i.e. based on the input-clock directly.  All inputs are
// -- registered at the system-clock rate.
// --
// -- Optionally simulates the original 32-clock (clock-enable) I/O cycle.
// --
// -- The SN76489 does not have an external reset and the original IC "wakes up"
// -- generating a tone.  This implementation sets the default output level to
// -- full attenuation (silent output).  If the original functionality is desired,
// -- modify the channel period and level register initial values.

// --
// -- Basic I/O interface use:
// --
// --   Set-up data on data_i.
// --   Set ce_n_i and wr_n_i low.
// --   Observe ready_o and wait for it to become high.
// --   Set wr_n_i high, if done writing to the chip set ce_n_i high.

// --
// -- Version history:
// --
// -- July 21 2020
// --   V1.0.  Release.  SoC tested.
// --


module sn76489_audio
  (input  clk_i,
   input  en_clk_psg_i,
   input  ce_n_i,
   input  wr_n_i,
   input  [7:0] data_i,
   output ready_o,
   output [11:0] ch_a_o,
   output [11:0] ch_b_o,
   output [11:0] ch_c_o,
   output [11:0] noise_o,
   output [13:0] mix_audio_o,
   output [13:0] pcm14s_o);
  reg ce_n_r;
  reg wr_n_r;
  reg [7:0] din_r;
  reg ready_r;
  wire ready_x;
  reg [1:0] io_state_r;
  wire [1:0] io_state_x;
  reg [4:0] io_cnt_r;
  wire [4:0] io_cnt_x;
  wire en_reg_wr_s;
  reg [2:0] reg_addr_r;
  wire [2:0] reg_sel_s;
  reg [9:0] ch_a_period_r;
  wire [9:0] ch_a_period_x;
  reg [11:0] ch_a_level_r;
  wire [11:0] ch_a_level_x;
  reg [9:0] ch_b_period_r;
  wire [9:0] ch_b_period_x;
  reg [11:0] ch_b_level_r;
  wire [11:0] ch_b_level_x;
  reg [9:0] ch_c_period_r;
  wire [9:0] ch_c_period_x;
  reg [11:0] ch_c_level_r;
  wire [11:0] ch_c_level_x;
  reg noise_ctrl_r;
  wire noise_ctrl_x;
  reg [1:0] noise_shift_r;
  wire [1:0] noise_shift_x;
  reg [11:0] noise_level_r;
  wire [11:0] noise_level_x;
  reg noise_rst_r;
  wire noise_rst_x;
  reg [3:0] clk_div16_r;
  wire [3:0] clk_div16_x;
  reg en_cnt_r;
  wire en_cnt_x;
  reg [9:0] ch_a_cnt_r;
  wire [9:0] ch_a_cnt_x;
  wire flatline_a_s;
  reg tone_a_r;
  wire tone_a_x;
  reg [9:0] ch_b_cnt_r;
  wire [9:0] ch_b_cnt_x;
  wire flatline_b_s;
  reg tone_b_r;
  wire tone_b_x;
  reg [9:0] ch_c_cnt_r;
  wire [9:0] ch_c_cnt_x;
  wire flatline_c_s;
  reg tone_c_r;
  wire tone_c_x;
  reg c_ff_r;
  wire c_ff_x;
  reg [6:0] noise_cnt_r;
  wire [6:0] noise_cnt_x;
  reg noise_ff_r;
  wire noise_ff_x;
  reg [14:0] noise_lfsr_r;
  wire [14:0] noise_lfsr_x;
  wire noise_fb_s;
  wire noise_s;
  wire [11:0] level_a_s;
  wire [11:0] level_b_s;
  wire [11:0] level_c_s;
  wire [11:0] level_n_s;
  reg [11:0] dac_a_r;
  reg [11:0] dac_b_r;
  reg [11:0] dac_c_r;
  reg [11:0] dac_n_r;
  reg [13:0] sum_audio_r;
  wire [11:0] dac_level_s;
  reg [191:0] dacrom_ar;
  reg [11:0] sign_a_r;
  wire [11:0] sign_a_x;
  reg [11:0] sign_b_r;
  wire [11:0] sign_b_x;
  reg [11:0] sign_c_r;
  wire [11:0] sign_c_x;
  reg [11:0] sign_n_r;
  wire [11:0] sign_n_x;
  reg [13:0] pcm14s_r;
  wire n56_o;
  wire n57_o;
  wire n58_o;
  wire n60_o;
  wire [1:0] n62_o;
  wire [4:0] n64_o;
  wire n66_o;
  wire n68_o;
  wire [4:0] n70_o;
  wire n72_o;
  wire [1:0] n74_o;
  wire [4:0] n75_o;
  wire n78_o;
  wire n80_o;
  wire [1:0] n82_o;
  wire n84_o;
  wire [2:0] n85_o;
  reg n87_o;
  reg [1:0] n89_o;
  reg [4:0] n91_o;
  reg n94_o;
  wire [3:0] n105_o;
  wire [3:0] n108_o;
  wire n112_o;
  wire n113_o;
  wire [2:0] n114_o;
  wire [2:0] n115_o;
  wire n116_o;
  wire n117_o;
  wire [5:0] n118_o;
  wire [3:0] n119_o;
  wire [9:0] n120_o;
  wire [5:0] n121_o;
  wire [3:0] n122_o;
  wire [9:0] n123_o;
  wire [9:0] n124_o;
  wire n126_o;
  wire n128_o;
  wire n129_o;
  wire n130_o;
  wire [5:0] n131_o;
  wire [3:0] n132_o;
  wire [9:0] n133_o;
  wire [5:0] n134_o;
  wire [3:0] n135_o;
  wire [9:0] n136_o;
  wire [9:0] n137_o;
  wire n139_o;
  wire n141_o;
  wire n142_o;
  wire n143_o;
  wire [5:0] n144_o;
  wire [3:0] n145_o;
  wire [9:0] n146_o;
  wire [5:0] n147_o;
  wire [3:0] n148_o;
  wire [9:0] n149_o;
  wire [9:0] n150_o;
  wire n152_o;
  wire n154_o;
  wire n155_o;
  wire [1:0] n156_o;
  wire n158_o;
  wire [6:0] n159_o;
  reg [9:0] n160_o;
  reg [11:0] n161_o;
  reg [9:0] n162_o;
  reg [11:0] n163_o;
  reg [9:0] n164_o;
  reg [11:0] n165_o;
  reg n166_o;
  reg [1:0] n167_o;
  reg [11:0] n168_o;
  reg n170_o;
  wire n186_o;
  wire n187_o;
  wire n188_o;
  wire n189_o;
  wire n190_o;
  wire n191_o;
  wire n192_o;
  wire n193_o;
  wire n194_o;
  wire n195_o;
  wire [3:0] n210_o;
  wire n213_o;
  wire n214_o;
  wire n225_o;
  wire n226_o;
  wire [9:0] n227_o;
  wire [9:0] n229_o;
  wire [9:0] n230_o;
  wire n233_o;
  wire n235_o;
  wire n236_o;
  wire n237_o;
  wire n240_o;
  wire n241_o;
  wire n243_o;
  wire n244_o;
  wire n245_o;
  wire n247_o;
  wire n248_o;
  wire [9:0] n249_o;
  wire [9:0] n251_o;
  wire [9:0] n252_o;
  wire n255_o;
  wire n257_o;
  wire n258_o;
  wire n259_o;
  wire n262_o;
  wire n263_o;
  wire n265_o;
  wire n266_o;
  wire n267_o;
  wire n269_o;
  wire n270_o;
  wire [9:0] n271_o;
  wire [9:0] n273_o;
  wire [9:0] n274_o;
  wire n277_o;
  wire n279_o;
  wire n280_o;
  wire n281_o;
  wire n283_o;
  wire n284_o;
  wire n286_o;
  wire n287_o;
  wire n288_o;
  wire [6:0] n308_o;
  wire [6:0] n309_o;
  wire n310_o;
  wire n312_o;
  wire n313_o;
  wire n315_o;
  wire n316_o;
  wire n318_o;
  wire [2:0] n319_o;
  reg n320_o;
  wire n321_o;
  wire n322_o;
  wire n323_o;
  wire n324_o;
  wire [13:0] n325_o;
  wire [14:0] n326_o;
  wire n327_o;
  wire n331_o;
  wire n332_o;
  wire [14:0] n333_o;
  wire [6:0] n334_o;
  wire n335_o;
  wire n336_o;
  wire [6:0] n338_o;
  wire n340_o;
  wire [14:0] n342_o;
  wire n348_o;
  wire [11:0] n349_o;
  wire n351_o;
  wire [11:0] n352_o;
  wire n354_o;
  wire [11:0] n355_o;
  wire n357_o;
  wire [11:0] n358_o;
  wire [13:0] n363_o;
  wire [13:0] n365_o;
  wire [13:0] n366_o;
  wire [13:0] n368_o;
  wire [13:0] n369_o;
  wire [13:0] n371_o;
  wire [13:0] n372_o;
  wire [11:0] n385_o;
  wire [11:0] n386_o;
  wire [10:0] n387_o;
  wire [10:0] n388_o;
  wire [11:0] n390_o;
  wire [11:0] n392_o;
  wire n393_o;
  wire [11:0] n394_o;
  wire [10:0] n395_o;
  wire [11:0] n397_o;
  wire [11:0] n399_o;
  wire [11:0] n400_o;
  wire [10:0] n401_o;
  wire [10:0] n402_o;
  wire [11:0] n404_o;
  wire [11:0] n406_o;
  wire n407_o;
  wire [11:0] n408_o;
  wire [10:0] n409_o;
  wire [11:0] n411_o;
  wire [11:0] n413_o;
  wire [11:0] n414_o;
  wire [10:0] n415_o;
  wire [10:0] n416_o;
  wire [11:0] n418_o;
  wire [11:0] n420_o;
  wire n421_o;
  wire [11:0] n422_o;
  wire [10:0] n423_o;
  wire [11:0] n425_o;
  wire [10:0] n426_o;
  wire [10:0] n427_o;
  wire [11:0] n429_o;
  wire [11:0] n431_o;
  wire n432_o;
  wire [11:0] n433_o;
  wire [10:0] n434_o;
  wire [11:0] n436_o;
  wire n440_o;
  wire n441_o;
  wire [1:0] n442_o;
  wire [13:0] n443_o;
  wire n444_o;
  wire n445_o;
  wire [1:0] n446_o;
  wire [13:0] n447_o;
  wire [13:0] n448_o;
  wire n449_o;
  wire n450_o;
  wire [1:0] n451_o;
  wire [13:0] n452_o;
  wire [13:0] n453_o;
  wire n454_o;
  wire n455_o;
  wire [1:0] n456_o;
  wire [13:0] n457_o;
  wire [13:0] n458_o;
  reg n470_q;
  reg n471_q;
  reg [7:0] n472_q;
  reg n473_q;
  wire [1:0] n474_o;
  reg [1:0] n475_q;
  wire [4:0] n476_o;
  reg [4:0] n477_q;
  wire [2:0] n478_o;
  reg [2:0] n479_q;
  wire [9:0] n480_o;
  reg [9:0] n481_q;
  wire [11:0] n482_o;
  reg [11:0] n483_q;
  wire [9:0] n484_o;
  reg [9:0] n485_q;
  wire [11:0] n486_o;
  reg [11:0] n487_q;
  wire [9:0] n488_o;
  reg [9:0] n489_q;
  wire [11:0] n490_o;
  reg [11:0] n491_q;
  wire n492_o;
  reg n493_q;
  wire [1:0] n494_o;
  reg [1:0] n495_q;
  wire [11:0] n496_o;
  reg [11:0] n497_q;
  wire n498_o;
  reg n499_q;
  wire [3:0] n500_o;
  reg [3:0] n501_q;
  wire n502_o;
  reg n503_q;
  wire [9:0] n504_o;
  reg [9:0] n505_q;
  wire n506_o;
  reg n507_q;
  wire [9:0] n508_o;
  reg [9:0] n509_q;
  wire n510_o;
  reg n511_q;
  wire [9:0] n512_o;
  reg [9:0] n513_q;
  wire n514_o;
  reg n515_q;
  wire n516_o;
  reg n517_q;
  reg [6:0] n518_q;
  reg n519_q;
  reg [14:0] n520_q;
  wire [11:0] n521_o;
  reg [11:0] n522_q;
  wire [11:0] n523_o;
  reg [11:0] n524_q;
  wire [11:0] n525_o;
  reg [11:0] n526_q;
  wire [11:0] n527_o;
  reg [11:0] n528_q;
  wire [13:0] n529_o;
  reg [13:0] n530_q;
  wire [11:0] n531_o;
  reg [11:0] n532_q;
  wire [11:0] n533_o;
  reg [11:0] n534_q;
  wire [11:0] n535_o;
  reg [11:0] n536_q;
  wire [11:0] n537_o;
  reg [11:0] n538_q;
  wire [13:0] n539_o;
  reg [13:0] n540_q;
  wire [11:0] n542_data; // mem_rd
  assign ready_o = ready_r;
  assign ch_a_o = dac_a_r;
  assign ch_b_o = dac_b_r;
  assign ch_c_o = dac_c_r;
  assign noise_o = dac_n_r;
  assign mix_audio_o = sum_audio_r;
  assign pcm14s_o = pcm14s_r;
  /* sn76489_audio.vhd:139:11  */
  always @*
    ce_n_r = n470_q; // (isignal)
  initial
    ce_n_r = 1'b1;
  /* sn76489_audio.vhd:140:11  */
  always @*
    wr_n_r = n471_q; // (isignal)
  initial
    wr_n_r = 1'b1;
  /* sn76489_audio.vhd:141:11  */
  always @*
    din_r = n472_q; // (isignal)
  initial
    din_r = 8'b00000000;
  /* sn76489_audio.vhd:142:11  */
  always @*
    ready_r = n473_q; // (isignal)
  initial
    ready_r = 1'b1;
  /* sn76489_audio.vhd:143:11  */
  assign ready_x = n87_o; // (signal)
  /* sn76489_audio.vhd:147:11  */
  always @*
    io_state_r = n475_q; // (isignal)
  initial
    io_state_r = 2'b00;
  /* sn76489_audio.vhd:148:11  */
  assign io_state_x = n89_o; // (signal)
  /* sn76489_audio.vhd:149:11  */
  always @*
    io_cnt_r = n477_q; // (isignal)
  initial
    io_cnt_r = 5'b00000;
  /* sn76489_audio.vhd:150:11  */
  assign io_cnt_x = n91_o; // (signal)
  /* sn76489_audio.vhd:151:11  */
  assign en_reg_wr_s = n94_o; // (signal)
  /* sn76489_audio.vhd:154:11  */
  always @*
    reg_addr_r = n479_q; // (isignal)
  initial
    reg_addr_r = 3'b000;
  /* sn76489_audio.vhd:155:11  */
  assign reg_sel_s = n115_o; // (signal)
  /* sn76489_audio.vhd:157:11  */
  always @*
    ch_a_period_r = n481_q; // (isignal)
  initial
    ch_a_period_r = 10'b0000000000;
  /* sn76489_audio.vhd:158:11  */
  assign ch_a_period_x = n160_o; // (signal)
  /* sn76489_audio.vhd:159:11  */
  always @*
    ch_a_level_r = n483_q; // (isignal)
  initial
    ch_a_level_r = 12'b000000000000;
  /* sn76489_audio.vhd:160:11  */
  assign ch_a_level_x = n161_o; // (signal)
  /* sn76489_audio.vhd:162:11  */
  always @*
    ch_b_period_r = n485_q; // (isignal)
  initial
    ch_b_period_r = 10'b0000000000;
  /* sn76489_audio.vhd:163:11  */
  assign ch_b_period_x = n162_o; // (signal)
  /* sn76489_audio.vhd:164:11  */
  always @*
    ch_b_level_r = n487_q; // (isignal)
  initial
    ch_b_level_r = 12'b000000000000;
  /* sn76489_audio.vhd:165:11  */
  assign ch_b_level_x = n163_o; // (signal)
  /* sn76489_audio.vhd:167:11  */
  always @*
    ch_c_period_r = n489_q; // (isignal)
  initial
    ch_c_period_r = 10'b0000000000;
  /* sn76489_audio.vhd:168:11  */
  assign ch_c_period_x = n164_o; // (signal)
  /* sn76489_audio.vhd:169:11  */
  always @*
    ch_c_level_r = n491_q; // (isignal)
  initial
    ch_c_level_r = 12'b000000000000;
  /* sn76489_audio.vhd:170:11  */
  assign ch_c_level_x = n165_o; // (signal)
  /* sn76489_audio.vhd:172:11  */
  always @*
    noise_ctrl_r = n493_q; // (isignal)
  initial
    noise_ctrl_r = 1'b0;
  /* sn76489_audio.vhd:173:11  */
  assign noise_ctrl_x = n166_o; // (signal)
  /* sn76489_audio.vhd:174:11  */
  always @*
    noise_shift_r = n495_q; // (isignal)
  initial
    noise_shift_r = 2'b00;
  /* sn76489_audio.vhd:175:11  */
  assign noise_shift_x = n167_o; // (signal)
  /* sn76489_audio.vhd:176:11  */
  always @*
    noise_level_r = n497_q; // (isignal)
  initial
    noise_level_r = 12'b000000000000;
  /* sn76489_audio.vhd:177:11  */
  assign noise_level_x = n168_o; // (signal)
  /* sn76489_audio.vhd:178:11  */
  always @*
    noise_rst_r = n499_q; // (isignal)
  initial
    noise_rst_r = 1'b0;
  /* sn76489_audio.vhd:179:11  */
  assign noise_rst_x = n170_o; // (signal)
  /* sn76489_audio.vhd:182:11  */
  always @*
    clk_div16_r = n501_q; // (isignal)
  initial
    clk_div16_r = 4'b0000;
  /* sn76489_audio.vhd:183:11  */
  assign clk_div16_x = n210_o; // (signal)
  /* sn76489_audio.vhd:184:11  */
  always @*
    en_cnt_r = n503_q; // (isignal)
  initial
    en_cnt_r = 1'b0;
  /* sn76489_audio.vhd:185:11  */
  assign en_cnt_x = n214_o; // (signal)
  /* sn76489_audio.vhd:188:11  */
  always @*
    ch_a_cnt_r = n505_q; // (isignal)
  initial
    ch_a_cnt_r = 10'b0000000000;
  /* sn76489_audio.vhd:189:11  */
  assign ch_a_cnt_x = n227_o; // (signal)
  /* sn76489_audio.vhd:190:11  */
  assign flatline_a_s = n237_o; // (signal)
  /* sn76489_audio.vhd:191:11  */
  always @*
    tone_a_r = n507_q; // (isignal)
  initial
    tone_a_r = 1'b1;
  /* sn76489_audio.vhd:192:11  */
  assign tone_a_x = n240_o; // (signal)
  /* sn76489_audio.vhd:194:11  */
  always @*
    ch_b_cnt_r = n509_q; // (isignal)
  initial
    ch_b_cnt_r = 10'b0000000000;
  /* sn76489_audio.vhd:195:11  */
  assign ch_b_cnt_x = n249_o; // (signal)
  /* sn76489_audio.vhd:196:11  */
  assign flatline_b_s = n259_o; // (signal)
  /* sn76489_audio.vhd:197:11  */
  always @*
    tone_b_r = n511_q; // (isignal)
  initial
    tone_b_r = 1'b1;
  /* sn76489_audio.vhd:198:11  */
  assign tone_b_x = n262_o; // (signal)
  /* sn76489_audio.vhd:200:11  */
  always @*
    ch_c_cnt_r = n513_q; // (isignal)
  initial
    ch_c_cnt_r = 10'b0000000000;
  /* sn76489_audio.vhd:201:11  */
  assign ch_c_cnt_x = n271_o; // (signal)
  /* sn76489_audio.vhd:202:11  */
  assign flatline_c_s = n281_o; // (signal)
  /* sn76489_audio.vhd:203:11  */
  always @*
    tone_c_r = n515_q; // (isignal)
  initial
    tone_c_r = 1'b1;
  /* sn76489_audio.vhd:204:11  */
  assign tone_c_x = n283_o; // (signal)
  /* sn76489_audio.vhd:205:11  */
  always @*
    c_ff_r = n517_q; // (isignal)
  initial
    c_ff_r = 1'b1;
  /* sn76489_audio.vhd:206:11  */
  assign c_ff_x = n288_o; // (signal)
  /* sn76489_audio.vhd:209:11  */
  always @*
    noise_cnt_r = n518_q; // (isignal)
  initial
    noise_cnt_r = 7'b0000000;
  /* sn76489_audio.vhd:210:11  */
  assign noise_cnt_x = n309_o; // (signal)
  /* sn76489_audio.vhd:211:11  */
  always @*
    noise_ff_r = n519_q; // (isignal)
  initial
    noise_ff_r = 1'b1;
  /* sn76489_audio.vhd:212:11  */
  assign noise_ff_x = n320_o; // (signal)
  /* sn76489_audio.vhd:215:11  */
  always @*
    noise_lfsr_r = n520_q; // (isignal)
  initial
    noise_lfsr_r = 15'b100000000000000;
  /* sn76489_audio.vhd:216:11  */
  assign noise_lfsr_x = n326_o; // (signal)
  /* sn76489_audio.vhd:217:11  */
  assign noise_fb_s = n324_o; // (signal)
  /* sn76489_audio.vhd:218:11  */
  assign noise_s = n327_o; // (signal)
  /* sn76489_audio.vhd:221:11  */
  assign level_a_s = n349_o; // (signal)
  /* sn76489_audio.vhd:222:11  */
  assign level_b_s = n352_o; // (signal)
  /* sn76489_audio.vhd:223:11  */
  assign level_c_s = n355_o; // (signal)
  /* sn76489_audio.vhd:224:11  */
  assign level_n_s = n358_o; // (signal)
  /* sn76489_audio.vhd:227:11  */
  always @*
    dac_a_r = n522_q; // (isignal)
  initial
    dac_a_r = 12'b000000000000;
  /* sn76489_audio.vhd:228:11  */
  always @*
    dac_b_r = n524_q; // (isignal)
  initial
    dac_b_r = 12'b000000000000;
  /* sn76489_audio.vhd:229:11  */
  always @*
    dac_c_r = n526_q; // (isignal)
  initial
    dac_c_r = 12'b000000000000;
  /* sn76489_audio.vhd:230:11  */
  always @*
    dac_n_r = n528_q; // (isignal)
  initial
    dac_n_r = 12'b000000000000;
  /* sn76489_audio.vhd:231:11  */
  always @*
    sum_audio_r = n530_q; // (isignal)
  initial
    sum_audio_r = 14'b00000000000000;
  /* sn76489_audio.vhd:271:11  */
  assign dac_level_s = n542_data; // (signal)
  /* sn76489_audio.vhd:274:11  */
  always @*
    dacrom_ar = 192'b111111111111110010110101101000011000100000000100011001011110010100001111010000000101001100110001001010001001001000000100000110011001000101000101000100000010000011001101000010100011000000000000; // (isignal)
  initial
    dacrom_ar = 192'b111111111111110010110101101000011000100000000100011001011110010100001111010000000101001100110001001010001001001000000100000110011001000101000101000100000010000011001101000010100011000000000000;
  /* sn76489_audio.vhd:281:11  */
  always @*
    sign_a_r = n532_q; // (isignal)
  initial
    sign_a_r = 12'b000000000000;
  /* sn76489_audio.vhd:282:11  */
  assign sign_a_x = n386_o; // (signal)
  /* sn76489_audio.vhd:283:11  */
  always @*
    sign_b_r = n534_q; // (isignal)
  initial
    sign_b_r = 12'b000000000000;
  /* sn76489_audio.vhd:284:11  */
  assign sign_b_x = n400_o; // (signal)
  /* sn76489_audio.vhd:285:11  */
  always @*
    sign_c_r = n536_q; // (isignal)
  initial
    sign_c_r = 12'b000000000000;
  /* sn76489_audio.vhd:286:11  */
  assign sign_c_x = n414_o; // (signal)
  /* sn76489_audio.vhd:287:11  */
  always @*
    sign_n_r = n538_q; // (isignal)
  initial
    sign_n_r = 12'b000000000000;
  /* sn76489_audio.vhd:288:11  */
  assign sign_n_x = n433_o; // (signal)
  /* sn76489_audio.vhd:289:11  */
  always @*
    pcm14s_r = n540_q; // (isignal)
  initial
    pcm14s_r = 14'b00000000000000;
  /* sn76489_audio.vhd:333:20  */
  assign n56_o = ~ce_n_r;
  /* sn76489_audio.vhd:333:37  */
  assign n57_o = ~wr_n_r;
  /* sn76489_audio.vhd:333:26  */
  assign n58_o = n56_o & n57_o;
  /* sn76489_audio.vhd:333:10  */
  assign n60_o = n58_o ? 1'b0 : ready_r;
  /* sn76489_audio.vhd:333:10  */
  assign n62_o = n58_o ? 2'b01 : io_state_r;
  /* sn76489_audio.vhd:333:10  */
  assign n64_o = n58_o ? 5'b11111 : io_cnt_r;
  /* sn76489_audio.vhd:331:7  */
  assign n66_o = io_state_r == 2'b00;
  /* sn76489_audio.vhd:347:22  */
  assign n68_o = io_cnt_r == 5'b00000;
  /* sn76489_audio.vhd:352:34  */
  assign n70_o = io_cnt_r - 5'b00001;
  /* sn76489_audio.vhd:347:10  */
  assign n72_o = n68_o ? 1'b1 : ready_r;
  /* sn76489_audio.vhd:347:10  */
  assign n74_o = n68_o ? 2'b10 : io_state_r;
  /* sn76489_audio.vhd:347:10  */
  assign n75_o = n68_o ? io_cnt_r : n70_o;
  /* sn76489_audio.vhd:347:10  */
  assign n78_o = n68_o ? 1'b1 : 1'b0;
  /* sn76489_audio.vhd:346:7  */
  assign n80_o = io_state_r == 2'b01;
  /* sn76489_audio.vhd:357:10  */
  assign n82_o = wr_n_r ? 2'b00 : io_state_r;
  /* sn76489_audio.vhd:355:7  */
  assign n84_o = io_state_r == 2'b10;
  assign n85_o = {n84_o, n80_o, n66_o};
  /* sn76489_audio.vhd:329:7  */
  always @*
    case (n85_o)
      3'b100: n87_o = ready_r;
      3'b010: n87_o = n72_o;
      3'b001: n87_o = n60_o;
      default: n87_o = 1'bX;
    endcase
  /* sn76489_audio.vhd:329:7  */
  always @*
    case (n85_o)
      3'b100: n89_o = n82_o;
      3'b010: n89_o = n74_o;
      3'b001: n89_o = n62_o;
      default: n89_o = 2'bX;
    endcase
  /* sn76489_audio.vhd:329:7  */
  always @*
    case (n85_o)
      3'b100: n91_o = io_cnt_r;
      3'b010: n91_o = n75_o;
      3'b001: n91_o = n64_o;
      default: n91_o = 5'bX;
    endcase
  /* sn76489_audio.vhd:329:7  */
  always @*
    case (n85_o)
      3'b100: n94_o = 1'b0;
      3'b010: n94_o = n78_o;
      3'b001: n94_o = 1'b0;
      default: n94_o = 1'bX;
    endcase
  /* sn76489_audio.vhd:404:54  */
  assign n105_o = din_r[3:0];
  /* sn76489_audio.vhd:404:29  */
  assign n108_o = 4'b1111 - n105_o;
  /* sn76489_audio.vhd:416:15  */
  assign n112_o = din_r[7];
  /* sn76489_audio.vhd:416:19  */
  assign n113_o = ~n112_o;
  /* sn76489_audio.vhd:419:28  */
  assign n114_o = din_r[6:4];
  /* sn76489_audio.vhd:416:7  */
  assign n115_o = n113_o ? reg_addr_r : n114_o;
  /* sn76489_audio.vhd:438:18  */
  assign n116_o = din_r[7];
  /* sn76489_audio.vhd:438:22  */
  assign n117_o = ~n116_o;
  /* sn76489_audio.vhd:439:35  */
  assign n118_o = din_r[5:0];
  /* sn76489_audio.vhd:439:63  */
  assign n119_o = ch_a_period_r[3:0];
  /* sn76489_audio.vhd:439:48  */
  assign n120_o = {n118_o, n119_o};
  /* sn76489_audio.vhd:441:43  */
  assign n121_o = ch_a_period_r[9:4];
  /* sn76489_audio.vhd:441:63  */
  assign n122_o = din_r[3:0];
  /* sn76489_audio.vhd:441:56  */
  assign n123_o = {n121_o, n122_o};
  /* sn76489_audio.vhd:438:10  */
  assign n124_o = n117_o ? n120_o : n123_o;
  /* sn76489_audio.vhd:437:7  */
  assign n126_o = reg_sel_s == 3'b000;
  /* sn76489_audio.vhd:444:7  */
  assign n128_o = reg_sel_s == 3'b001;
  /* sn76489_audio.vhd:448:18  */
  assign n129_o = din_r[7];
  /* sn76489_audio.vhd:448:22  */
  assign n130_o = ~n129_o;
  /* sn76489_audio.vhd:449:35  */
  assign n131_o = din_r[5:0];
  /* sn76489_audio.vhd:449:63  */
  assign n132_o = ch_b_period_r[3:0];
  /* sn76489_audio.vhd:449:48  */
  assign n133_o = {n131_o, n132_o};
  /* sn76489_audio.vhd:451:43  */
  assign n134_o = ch_b_period_r[9:4];
  /* sn76489_audio.vhd:451:63  */
  assign n135_o = din_r[3:0];
  /* sn76489_audio.vhd:451:56  */
  assign n136_o = {n134_o, n135_o};
  /* sn76489_audio.vhd:448:10  */
  assign n137_o = n130_o ? n133_o : n136_o;
  /* sn76489_audio.vhd:447:7  */
  assign n139_o = reg_sel_s == 3'b010;
  /* sn76489_audio.vhd:454:7  */
  assign n141_o = reg_sel_s == 3'b011;
  /* sn76489_audio.vhd:458:18  */
  assign n142_o = din_r[7];
  /* sn76489_audio.vhd:458:22  */
  assign n143_o = ~n142_o;
  /* sn76489_audio.vhd:459:35  */
  assign n144_o = din_r[5:0];
  /* sn76489_audio.vhd:459:63  */
  assign n145_o = ch_c_period_r[3:0];
  /* sn76489_audio.vhd:459:48  */
  assign n146_o = {n144_o, n145_o};
  /* sn76489_audio.vhd:461:43  */
  assign n147_o = ch_c_period_r[9:4];
  /* sn76489_audio.vhd:461:63  */
  assign n148_o = din_r[3:0];
  /* sn76489_audio.vhd:461:56  */
  assign n149_o = {n147_o, n148_o};
  /* sn76489_audio.vhd:458:10  */
  assign n150_o = n143_o ? n146_o : n149_o;
  /* sn76489_audio.vhd:457:7  */
  assign n152_o = reg_sel_s == 3'b100;
  /* sn76489_audio.vhd:464:7  */
  assign n154_o = reg_sel_s == 3'b101;
  /* sn76489_audio.vhd:468:32  */
  assign n155_o = din_r[2];
  /* sn76489_audio.vhd:469:32  */
  assign n156_o = din_r[1:0];
  /* sn76489_audio.vhd:467:7  */
  assign n158_o = reg_sel_s == 3'b110;
  assign n159_o = {n158_o, n154_o, n152_o, n141_o, n139_o, n128_o, n126_o};
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n160_o = ch_a_period_r;
      7'b0100000: n160_o = ch_a_period_r;
      7'b0010000: n160_o = ch_a_period_r;
      7'b0001000: n160_o = ch_a_period_r;
      7'b0000100: n160_o = ch_a_period_r;
      7'b0000010: n160_o = ch_a_period_r;
      7'b0000001: n160_o = n124_o;
      default: n160_o = ch_a_period_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n161_o = ch_a_level_r;
      7'b0100000: n161_o = ch_a_level_r;
      7'b0010000: n161_o = ch_a_level_r;
      7'b0001000: n161_o = ch_a_level_r;
      7'b0000100: n161_o = ch_a_level_r;
      7'b0000010: n161_o = dac_level_s;
      7'b0000001: n161_o = ch_a_level_r;
      default: n161_o = ch_a_level_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n162_o = ch_b_period_r;
      7'b0100000: n162_o = ch_b_period_r;
      7'b0010000: n162_o = ch_b_period_r;
      7'b0001000: n162_o = ch_b_period_r;
      7'b0000100: n162_o = n137_o;
      7'b0000010: n162_o = ch_b_period_r;
      7'b0000001: n162_o = ch_b_period_r;
      default: n162_o = ch_b_period_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n163_o = ch_b_level_r;
      7'b0100000: n163_o = ch_b_level_r;
      7'b0010000: n163_o = ch_b_level_r;
      7'b0001000: n163_o = dac_level_s;
      7'b0000100: n163_o = ch_b_level_r;
      7'b0000010: n163_o = ch_b_level_r;
      7'b0000001: n163_o = ch_b_level_r;
      default: n163_o = ch_b_level_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n164_o = ch_c_period_r;
      7'b0100000: n164_o = ch_c_period_r;
      7'b0010000: n164_o = n150_o;
      7'b0001000: n164_o = ch_c_period_r;
      7'b0000100: n164_o = ch_c_period_r;
      7'b0000010: n164_o = ch_c_period_r;
      7'b0000001: n164_o = ch_c_period_r;
      default: n164_o = ch_c_period_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n165_o = ch_c_level_r;
      7'b0100000: n165_o = dac_level_s;
      7'b0010000: n165_o = ch_c_level_r;
      7'b0001000: n165_o = ch_c_level_r;
      7'b0000100: n165_o = ch_c_level_r;
      7'b0000010: n165_o = ch_c_level_r;
      7'b0000001: n165_o = ch_c_level_r;
      default: n165_o = ch_c_level_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n166_o = n155_o;
      7'b0100000: n166_o = noise_ctrl_r;
      7'b0010000: n166_o = noise_ctrl_r;
      7'b0001000: n166_o = noise_ctrl_r;
      7'b0000100: n166_o = noise_ctrl_r;
      7'b0000010: n166_o = noise_ctrl_r;
      7'b0000001: n166_o = noise_ctrl_r;
      default: n166_o = noise_ctrl_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n167_o = n156_o;
      7'b0100000: n167_o = noise_shift_r;
      7'b0010000: n167_o = noise_shift_r;
      7'b0001000: n167_o = noise_shift_r;
      7'b0000100: n167_o = noise_shift_r;
      7'b0000010: n167_o = noise_shift_r;
      7'b0000001: n167_o = noise_shift_r;
      default: n167_o = noise_shift_r;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n168_o = noise_level_r;
      7'b0100000: n168_o = noise_level_r;
      7'b0010000: n168_o = noise_level_r;
      7'b0001000: n168_o = noise_level_r;
      7'b0000100: n168_o = noise_level_r;
      7'b0000010: n168_o = noise_level_r;
      7'b0000001: n168_o = noise_level_r;
      default: n168_o = dac_level_s;
    endcase
  /* sn76489_audio.vhd:435:7  */
  always @*
    case (n159_o)
      7'b1000000: n170_o = en_reg_wr_s;
      7'b0100000: n170_o = 1'b0;
      7'b0010000: n170_o = 1'b0;
      7'b0001000: n170_o = 1'b0;
      7'b0000100: n170_o = 1'b0;
      7'b0000010: n170_o = 1'b0;
      7'b0000001: n170_o = 1'b0;
      default: n170_o = 1'b0;
    endcase
  /* sn76489_audio.vhd:487:7  */
  assign n186_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n187_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n188_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n189_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n190_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n191_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n192_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n193_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n194_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:487:7  */
  assign n195_o = en_clk_psg_i & en_reg_wr_s;
  /* sn76489_audio.vhd:518:31  */
  assign n210_o = clk_div16_r + 4'b0001;
  /* sn76489_audio.vhd:519:40  */
  assign n213_o = clk_div16_r == 4'b0000;
  /* sn76489_audio.vhd:519:23  */
  assign n214_o = n213_o ? 1'b1 : 1'b0;
  /* sn76489_audio.vhd:640:58  */
  assign n225_o = ch_a_cnt_r == 10'b0000000000;
  /* sn76489_audio.vhd:640:43  */
  assign n226_o = en_cnt_x & n225_o;
  /* sn76489_audio.vhd:640:22  */
  assign n227_o = n226_o ? ch_a_period_r : n230_o;
  /* sn76489_audio.vhd:642:18  */
  assign n229_o = ch_a_cnt_r - 10'b0000000001;
  /* sn76489_audio.vhd:640:63  */
  assign n230_o = en_cnt_r ? n229_o : ch_a_cnt_r;
  /* sn76489_audio.vhd:646:30  */
  assign n233_o = $unsigned(ch_a_period_r) > $unsigned(10'b0000000000);
  /* sn76489_audio.vhd:646:52  */
  assign n235_o = $unsigned(ch_a_period_r) < $unsigned(10'b0000000110);
  /* sn76489_audio.vhd:646:34  */
  assign n236_o = n233_o & n235_o;
  /* sn76489_audio.vhd:646:11  */
  assign n237_o = n236_o ? 1'b1 : 1'b0;
  /* sn76489_audio.vhd:651:11  */
  assign n240_o = flatline_a_s ? 1'b1 : n245_o;
  /* sn76489_audio.vhd:654:7  */
  assign n241_o = ~tone_a_r;
  /* sn76489_audio.vhd:654:56  */
  assign n243_o = ch_a_cnt_r == 10'b0000000000;
  /* sn76489_audio.vhd:654:41  */
  assign n244_o = en_cnt_x & n243_o;
  /* sn76489_audio.vhd:651:35  */
  assign n245_o = n244_o ? n241_o : tone_a_r;
  /* sn76489_audio.vhd:659:57  */
  assign n247_o = ch_b_cnt_r == 10'b0000000000;
  /* sn76489_audio.vhd:659:42  */
  assign n248_o = en_cnt_x & n247_o;
  /* sn76489_audio.vhd:659:21  */
  assign n249_o = n248_o ? ch_b_period_r : n252_o;
  /* sn76489_audio.vhd:660:18  */
  assign n251_o = ch_b_cnt_r - 10'b0000000001;
  /* sn76489_audio.vhd:659:62  */
  assign n252_o = en_cnt_r ? n251_o : ch_b_cnt_r;
  /* sn76489_audio.vhd:664:30  */
  assign n255_o = $unsigned(ch_b_period_r) > $unsigned(10'b0000000000);
  /* sn76489_audio.vhd:664:52  */
  assign n257_o = $unsigned(ch_b_period_r) < $unsigned(10'b0000000110);
  /* sn76489_audio.vhd:664:34  */
  assign n258_o = n255_o & n257_o;
  /* sn76489_audio.vhd:664:11  */
  assign n259_o = n258_o ? 1'b1 : 1'b0;
  /* sn76489_audio.vhd:668:11  */
  assign n262_o = flatline_b_s ? 1'b1 : n267_o;
  /* sn76489_audio.vhd:669:7  */
  assign n263_o = ~tone_b_r;
  /* sn76489_audio.vhd:669:56  */
  assign n265_o = ch_b_cnt_r == 10'b0000000000;
  /* sn76489_audio.vhd:669:41  */
  assign n266_o = en_cnt_x & n265_o;
  /* sn76489_audio.vhd:668:35  */
  assign n267_o = n266_o ? n263_o : tone_b_r;
  /* sn76489_audio.vhd:674:57  */
  assign n269_o = ch_c_cnt_r == 10'b0000000000;
  /* sn76489_audio.vhd:674:42  */
  assign n270_o = en_cnt_x & n269_o;
  /* sn76489_audio.vhd:674:21  */
  assign n271_o = n270_o ? ch_c_period_r : n274_o;
  /* sn76489_audio.vhd:675:18  */
  assign n273_o = ch_c_cnt_r - 10'b0000000001;
  /* sn76489_audio.vhd:674:62  */
  assign n274_o = en_cnt_r ? n273_o : ch_c_cnt_r;
  /* sn76489_audio.vhd:679:30  */
  assign n277_o = $unsigned(ch_c_period_r) > $unsigned(10'b0000000000);
  /* sn76489_audio.vhd:679:52  */
  assign n279_o = $unsigned(ch_c_period_r) < $unsigned(10'b0000000110);
  /* sn76489_audio.vhd:679:34  */
  assign n280_o = n277_o & n279_o;
  /* sn76489_audio.vhd:679:11  */
  assign n281_o = n280_o ? 1'b1 : 1'b0;
  /* sn76489_audio.vhd:682:29  */
  assign n283_o = flatline_c_s | c_ff_r;
  /* sn76489_audio.vhd:689:7  */
  assign n284_o = ~c_ff_r;
  /* sn76489_audio.vhd:689:54  */
  assign n286_o = ch_c_cnt_r == 10'b0000000000;
  /* sn76489_audio.vhd:689:39  */
  assign n287_o = en_cnt_x & n286_o;
  /* sn76489_audio.vhd:689:18  */
  assign n288_o = n287_o ? n284_o : c_ff_r;
  /* sn76489_audio.vhd:722:19  */
  assign n308_o = noise_cnt_r + 7'b0000001;
  /* sn76489_audio.vhd:722:23  */
  assign n309_o = en_cnt_r ? n308_o : noise_cnt_r;
  /* sn76489_audio.vhd:727:18  */
  assign n310_o = noise_cnt_r[4];
  /* sn76489_audio.vhd:727:22  */
  assign n312_o = noise_shift_r == 2'b00;
  /* sn76489_audio.vhd:728:18  */
  assign n313_o = noise_cnt_r[5];
  /* sn76489_audio.vhd:728:22  */
  assign n315_o = noise_shift_r == 2'b01;
  /* sn76489_audio.vhd:729:18  */
  assign n316_o = noise_cnt_r[6];
  /* sn76489_audio.vhd:729:22  */
  assign n318_o = noise_shift_r == 2'b10;
  assign n319_o = {n318_o, n315_o, n312_o};
  /* sn76489_audio.vhd:725:4  */
  always @*
    case (n319_o)
      3'b100: n320_o = n316_o;
      3'b010: n320_o = n313_o;
      3'b001: n320_o = n310_o;
      default: n320_o = c_ff_r;
    endcase
  /* sn76489_audio.vhd:759:37  */
  assign n321_o = noise_lfsr_r[1];
  /* sn76489_audio.vhd:759:21  */
  assign n322_o = noise_ctrl_r & n321_o;
  /* sn76489_audio.vhd:759:58  */
  assign n323_o = noise_lfsr_r[0];
  /* sn76489_audio.vhd:759:42  */
  assign n324_o = n322_o ^ n323_o;
  /* sn76489_audio.vhd:760:45  */
  assign n325_o = noise_lfsr_r[14:1];
  /* sn76489_audio.vhd:760:31  */
  assign n326_o = {noise_fb_s, n325_o};
  /* sn76489_audio.vhd:761:27  */
  assign n327_o = noise_lfsr_r[0];
  /* sn76489_audio.vhd:779:24  */
  assign n331_o = ~noise_ff_r;
  /* sn76489_audio.vhd:779:30  */
  assign n332_o = n331_o & noise_ff_x;
  /* sn76489_audio.vhd:775:7  */
  assign n333_o = n336_o ? noise_lfsr_x : noise_lfsr_r;
  /* sn76489_audio.vhd:775:7  */
  assign n334_o = en_clk_psg_i ? noise_cnt_x : noise_cnt_r;
  /* sn76489_audio.vhd:775:7  */
  assign n335_o = en_clk_psg_i ? noise_ff_x : noise_ff_r;
  /* sn76489_audio.vhd:775:7  */
  assign n336_o = en_clk_psg_i & n332_o;
  /* sn76489_audio.vhd:770:7  */
  assign n338_o = noise_rst_r ? 7'b0000000 : n334_o;
  /* sn76489_audio.vhd:770:7  */
  assign n340_o = noise_rst_r ? 1'b1 : n335_o;
  /* sn76489_audio.vhd:770:7  */
  assign n342_o = noise_rst_r ? 15'b100000000000000 : n333_o;
  /* sn76489_audio.vhd:798:37  */
  assign n348_o = ~tone_a_r;
  /* sn76489_audio.vhd:798:23  */
  assign n349_o = n348_o ? 12'b000000000000 : ch_a_level_r;
  /* sn76489_audio.vhd:802:37  */
  assign n351_o = ~tone_b_r;
  /* sn76489_audio.vhd:802:23  */
  assign n352_o = n351_o ? 12'b000000000000 : ch_b_level_r;
  /* sn76489_audio.vhd:806:37  */
  assign n354_o = ~tone_c_r;
  /* sn76489_audio.vhd:806:23  */
  assign n355_o = n354_o ? 12'b000000000000 : ch_c_level_r;
  /* sn76489_audio.vhd:810:36  */
  assign n357_o = ~noise_s;
  /* sn76489_audio.vhd:810:23  */
  assign n358_o = n357_o ? 12'b000000000000 : noise_level_r;
  /* sn76489_audio.vhd:838:28  */
  assign n363_o = {2'b00, level_a_s};
  /* sn76489_audio.vhd:838:49  */
  assign n365_o = {2'b00, level_b_s};
  /* sn76489_audio.vhd:838:41  */
  assign n366_o = n363_o + n365_o;
  /* sn76489_audio.vhd:839:28  */
  assign n368_o = {2'b00, level_c_s};
  /* sn76489_audio.vhd:838:62  */
  assign n369_o = n366_o + n368_o;
  /* sn76489_audio.vhd:839:49  */
  assign n371_o = {2'b00, level_n_s};
  /* sn76489_audio.vhd:839:41  */
  assign n372_o = n369_o + n371_o;
  /* sn76489_audio.vhd:864:20  */
  assign n385_o = ch_a_level_r - 12'b100000000000;
  /* sn76489_audio.vhd:864:47  */
  assign n386_o = flatline_a_s ? n385_o : n394_o;
  /* sn76489_audio.vhd:865:31  */
  assign n387_o = ch_a_level_r[11:1];
  /* sn76489_audio.vhd:865:15  */
  assign n388_o = ~n387_o;
  /* sn76489_audio.vhd:865:12  */
  assign n390_o = {1'b1, n388_o};
  /* sn76489_audio.vhd:865:47  */
  assign n392_o = n390_o + 12'b000000000001;
  /* sn76489_audio.vhd:865:65  */
  assign n393_o = ~tone_a_r;
  /* sn76489_audio.vhd:864:71  */
  assign n394_o = n393_o ? n392_o : n397_o;
  /* sn76489_audio.vhd:866:31  */
  assign n395_o = ch_a_level_r[11:1];
  /* sn76489_audio.vhd:866:12  */
  assign n397_o = {1'b0, n395_o};
  /* sn76489_audio.vhd:869:20  */
  assign n399_o = ch_b_level_r - 12'b100000000000;
  /* sn76489_audio.vhd:869:47  */
  assign n400_o = flatline_b_s ? n399_o : n408_o;
  /* sn76489_audio.vhd:870:31  */
  assign n401_o = ch_b_level_r[11:1];
  /* sn76489_audio.vhd:870:15  */
  assign n402_o = ~n401_o;
  /* sn76489_audio.vhd:870:12  */
  assign n404_o = {1'b1, n402_o};
  /* sn76489_audio.vhd:870:47  */
  assign n406_o = n404_o + 12'b000000000001;
  /* sn76489_audio.vhd:870:65  */
  assign n407_o = ~tone_b_r;
  /* sn76489_audio.vhd:869:71  */
  assign n408_o = n407_o ? n406_o : n411_o;
  /* sn76489_audio.vhd:871:31  */
  assign n409_o = ch_b_level_r[11:1];
  /* sn76489_audio.vhd:871:12  */
  assign n411_o = {1'b0, n409_o};
  /* sn76489_audio.vhd:874:20  */
  assign n413_o = ch_c_level_r - 12'b100000000000;
  /* sn76489_audio.vhd:874:47  */
  assign n414_o = flatline_c_s ? n413_o : n422_o;
  /* sn76489_audio.vhd:875:31  */
  assign n415_o = ch_c_level_r[11:1];
  /* sn76489_audio.vhd:875:15  */
  assign n416_o = ~n415_o;
  /* sn76489_audio.vhd:875:12  */
  assign n418_o = {1'b1, n416_o};
  /* sn76489_audio.vhd:875:47  */
  assign n420_o = n418_o + 12'b000000000001;
  /* sn76489_audio.vhd:875:65  */
  assign n421_o = ~tone_c_r;
  /* sn76489_audio.vhd:874:71  */
  assign n422_o = n421_o ? n420_o : n425_o;
  /* sn76489_audio.vhd:876:31  */
  assign n423_o = ch_c_level_r[11:1];
  /* sn76489_audio.vhd:876:12  */
  assign n425_o = {1'b0, n423_o};
  /* sn76489_audio.vhd:879:32  */
  assign n426_o = noise_level_r[11:1];
  /* sn76489_audio.vhd:879:15  */
  assign n427_o = ~n426_o;
  /* sn76489_audio.vhd:879:12  */
  assign n429_o = {1'b1, n427_o};
  /* sn76489_audio.vhd:879:48  */
  assign n431_o = n429_o + 12'b000000000001;
  /* sn76489_audio.vhd:879:65  */
  assign n432_o = ~noise_s;
  /* sn76489_audio.vhd:879:52  */
  assign n433_o = n432_o ? n431_o : n436_o;
  /* sn76489_audio.vhd:880:32  */
  assign n434_o = noise_level_r[11:1];
  /* sn76489_audio.vhd:880:12  */
  assign n436_o = {1'b0, n434_o};
  /* sn76489_audio.vhd:899:19  */
  assign n440_o = sign_a_r[11];
  /* sn76489_audio.vhd:899:34  */
  assign n441_o = sign_a_r[11];
  /* sn76489_audio.vhd:899:24  */
  assign n442_o = {n440_o, n441_o};
  /* sn76489_audio.vhd:899:39  */
  assign n443_o = {n442_o, sign_a_r};
  /* sn76489_audio.vhd:900:19  */
  assign n444_o = sign_b_r[11];
  /* sn76489_audio.vhd:900:34  */
  assign n445_o = sign_b_r[11];
  /* sn76489_audio.vhd:900:24  */
  assign n446_o = {n444_o, n445_o};
  /* sn76489_audio.vhd:900:39  */
  assign n447_o = {n446_o, sign_b_r};
  /* sn76489_audio.vhd:899:51  */
  assign n448_o = n443_o + n447_o;
  /* sn76489_audio.vhd:901:19  */
  assign n449_o = sign_c_r[11];
  /* sn76489_audio.vhd:901:34  */
  assign n450_o = sign_c_r[11];
  /* sn76489_audio.vhd:901:24  */
  assign n451_o = {n449_o, n450_o};
  /* sn76489_audio.vhd:901:39  */
  assign n452_o = {n451_o, sign_c_r};
  /* sn76489_audio.vhd:900:51  */
  assign n453_o = n448_o + n452_o;
  /* sn76489_audio.vhd:902:19  */
  assign n454_o = sign_n_r[11];
  /* sn76489_audio.vhd:902:34  */
  assign n455_o = sign_n_r[11];
  /* sn76489_audio.vhd:902:24  */
  assign n456_o = {n454_o, n455_o};
  /* sn76489_audio.vhd:902:39  */
  assign n457_o = {n456_o, sign_n_r};
  /* sn76489_audio.vhd:901:51  */
  assign n458_o = n453_o + n457_o;
  /* sn76489_audio.vhd:295:4  */
  always @(posedge clk_i)
    n470_q <= ce_n_i;
  initial
    n470_q = 1'b1;
  /* sn76489_audio.vhd:295:4  */
  always @(posedge clk_i)
    n471_q <= wr_n_i;
  initial
    n471_q = 1'b1;
  /* sn76489_audio.vhd:295:4  */
  always @(posedge clk_i)
    n472_q <= data_i;
  initial
    n472_q = 8'b00000000;
  /* sn76489_audio.vhd:295:4  */
  always @(posedge clk_i)
    n473_q <= ready_x;
  initial
    n473_q = 1'b1;
  /* sn76489_audio.vhd:368:4  */
  assign n474_o = en_clk_psg_i ? io_state_x : io_state_r;
  /* sn76489_audio.vhd:368:4  */
  always @(posedge clk_i)
    n475_q <= n474_o;
  initial
    n475_q = 2'b00;
  /* sn76489_audio.vhd:368:4  */
  assign n476_o = en_clk_psg_i ? io_cnt_x : io_cnt_r;
  /* sn76489_audio.vhd:368:4  */
  always @(posedge clk_i)
    n477_q <= n476_o;
  initial
    n477_q = 5'b00000;
  /* sn76489_audio.vhd:486:4  */
  assign n478_o = n186_o ? reg_sel_s : reg_addr_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n479_q <= n478_o;
  initial
    n479_q = 3'b000;
  /* sn76489_audio.vhd:486:4  */
  assign n480_o = n187_o ? ch_a_period_x : ch_a_period_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n481_q <= n480_o;
  initial
    n481_q = 10'b0000000000;
  /* sn76489_audio.vhd:486:4  */
  assign n482_o = n188_o ? ch_a_level_x : ch_a_level_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n483_q <= n482_o;
  initial
    n483_q = 12'b000000000000;
  /* sn76489_audio.vhd:486:4  */
  assign n484_o = n189_o ? ch_b_period_x : ch_b_period_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n485_q <= n484_o;
  initial
    n485_q = 10'b0000000000;
  /* sn76489_audio.vhd:486:4  */
  assign n486_o = n190_o ? ch_b_level_x : ch_b_level_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n487_q <= n486_o;
  initial
    n487_q = 12'b000000000000;
  /* sn76489_audio.vhd:486:4  */
  assign n488_o = n191_o ? ch_c_period_x : ch_c_period_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n489_q <= n488_o;
  initial
    n489_q = 10'b0000000000;
  /* sn76489_audio.vhd:486:4  */
  assign n490_o = n192_o ? ch_c_level_x : ch_c_level_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n491_q <= n490_o;
  initial
    n491_q = 12'b000000000000;
  /* sn76489_audio.vhd:486:4  */
  assign n492_o = n193_o ? noise_ctrl_x : noise_ctrl_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n493_q <= n492_o;
  initial
    n493_q = 1'b0;
  /* sn76489_audio.vhd:486:4  */
  assign n494_o = n194_o ? noise_shift_x : noise_shift_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n495_q <= n494_o;
  initial
    n495_q = 2'b00;
  /* sn76489_audio.vhd:486:4  */
  assign n496_o = n195_o ? noise_level_x : noise_level_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n497_q <= n496_o;
  initial
    n497_q = 12'b000000000000;
  /* sn76489_audio.vhd:486:4  */
  assign n498_o = en_clk_psg_i ? noise_rst_x : noise_rst_r;
  /* sn76489_audio.vhd:486:4  */
  always @(posedge clk_i)
    n499_q <= n498_o;
  initial
    n499_q = 1'b0;
  /* sn76489_audio.vhd:524:4  */
  assign n500_o = en_clk_psg_i ? clk_div16_x : clk_div16_r;
  /* sn76489_audio.vhd:524:4  */
  always @(posedge clk_i)
    n501_q <= n500_o;
  initial
    n501_q = 4'b0000;
  /* sn76489_audio.vhd:524:4  */
  assign n502_o = en_clk_psg_i ? en_cnt_x : en_cnt_r;
  /* sn76489_audio.vhd:524:4  */
  always @(posedge clk_i)
    n503_q <= n502_o;
  initial
    n503_q = 1'b0;
  /* sn76489_audio.vhd:696:4  */
  assign n504_o = en_clk_psg_i ? ch_a_cnt_x : ch_a_cnt_r;
  /* sn76489_audio.vhd:696:4  */
  always @(posedge clk_i)
    n505_q <= n504_o;
  initial
    n505_q = 10'b0000000000;
  /* sn76489_audio.vhd:696:4  */
  assign n506_o = en_clk_psg_i ? tone_a_x : tone_a_r;
  /* sn76489_audio.vhd:696:4  */
  always @(posedge clk_i)
    n507_q <= n506_o;
  initial
    n507_q = 1'b1;
  /* sn76489_audio.vhd:696:4  */
  assign n508_o = en_clk_psg_i ? ch_b_cnt_x : ch_b_cnt_r;
  /* sn76489_audio.vhd:696:4  */
  always @(posedge clk_i)
    n509_q <= n508_o;
  initial
    n509_q = 10'b0000000000;
  /* sn76489_audio.vhd:696:4  */
  assign n510_o = en_clk_psg_i ? tone_b_x : tone_b_r;
  /* sn76489_audio.vhd:696:4  */
  always @(posedge clk_i)
    n511_q <= n510_o;
  initial
    n511_q = 1'b1;
  /* sn76489_audio.vhd:696:4  */
  assign n512_o = en_clk_psg_i ? ch_c_cnt_x : ch_c_cnt_r;
  /* sn76489_audio.vhd:696:4  */
  always @(posedge clk_i)
    n513_q <= n512_o;
  initial
    n513_q = 10'b0000000000;
  /* sn76489_audio.vhd:696:4  */
  assign n514_o = en_clk_psg_i ? tone_c_x : tone_c_r;
  /* sn76489_audio.vhd:696:4  */
  always @(posedge clk_i)
    n515_q <= n514_o;
  initial
    n515_q = 1'b1;
  /* sn76489_audio.vhd:696:4  */
  assign n516_o = en_clk_psg_i ? c_ff_x : c_ff_r;
  /* sn76489_audio.vhd:696:4  */
  always @(posedge clk_i)
    n517_q <= n516_o;
  initial
    n517_q = 1'b1;
  /* sn76489_audio.vhd:767:4  */
  always @(posedge clk_i)
    n518_q <= n338_o;
  initial
    n518_q = 7'b0000000;
  /* sn76489_audio.vhd:767:4  */
  always @(posedge clk_i)
    n519_q <= n340_o;
  initial
    n519_q = 1'b1;
  /* sn76489_audio.vhd:767:4  */
  always @(posedge clk_i)
    n520_q <= n342_o;
  initial
    n520_q = 15'b100000000000000;
  /* sn76489_audio.vhd:829:4  */
  assign n521_o = en_clk_psg_i ? level_a_s : dac_a_r;
  /* sn76489_audio.vhd:829:4  */
  always @(posedge clk_i)
    n522_q <= n521_o;
  initial
    n522_q = 12'b000000000000;
  /* sn76489_audio.vhd:829:4  */
  assign n523_o = en_clk_psg_i ? level_b_s : dac_b_r;
  /* sn76489_audio.vhd:829:4  */
  always @(posedge clk_i)
    n524_q <= n523_o;
  initial
    n524_q = 12'b000000000000;
  /* sn76489_audio.vhd:829:4  */
  assign n525_o = en_clk_psg_i ? level_c_s : dac_c_r;
  /* sn76489_audio.vhd:829:4  */
  always @(posedge clk_i)
    n526_q <= n525_o;
  initial
    n526_q = 12'b000000000000;
  /* sn76489_audio.vhd:829:4  */
  assign n527_o = en_clk_psg_i ? level_n_s : dac_n_r;
  /* sn76489_audio.vhd:829:4  */
  always @(posedge clk_i)
    n528_q <= n527_o;
  initial
    n528_q = 12'b000000000000;
  /* sn76489_audio.vhd:829:4  */
  assign n529_o = en_clk_psg_i ? n372_o : sum_audio_r;
  /* sn76489_audio.vhd:829:4  */
  always @(posedge clk_i)
    n530_q <= n529_o;
  initial
    n530_q = 14'b00000000000000;
  /* sn76489_audio.vhd:889:4  */
  assign n531_o = en_clk_psg_i ? sign_a_x : sign_a_r;
  /* sn76489_audio.vhd:889:4  */
  always @(posedge clk_i)
    n532_q <= n531_o;
  initial
    n532_q = 12'b000000000000;
  /* sn76489_audio.vhd:889:4  */
  assign n533_o = en_clk_psg_i ? sign_b_x : sign_b_r;
  /* sn76489_audio.vhd:889:4  */
  always @(posedge clk_i)
    n534_q <= n533_o;
  initial
    n534_q = 12'b000000000000;
  /* sn76489_audio.vhd:889:4  */
  assign n535_o = en_clk_psg_i ? sign_c_x : sign_c_r;
  /* sn76489_audio.vhd:889:4  */
  always @(posedge clk_i)
    n536_q <= n535_o;
  initial
    n536_q = 12'b000000000000;
  /* sn76489_audio.vhd:889:4  */
  assign n537_o = en_clk_psg_i ? sign_n_x : sign_n_r;
  /* sn76489_audio.vhd:889:4  */
  always @(posedge clk_i)
    n538_q <= n537_o;
  initial
    n538_q = 12'b000000000000;
  /* sn76489_audio.vhd:889:4  */
  assign n539_o = en_clk_psg_i ? n458_o : pcm14s_r;
  /* sn76489_audio.vhd:889:4  */
  always @(posedge clk_i)
    n540_q <= n539_o;
  initial
    n540_q = 14'b00000000000000;
  /* sn76489_audio.vhd:132:6  */
  reg [11:0] n541[15:0] ; // memory
  initial begin
    n541[15] = 12'b111111111111;
    n541[14] = 12'b110010110101;
    n541[13] = 12'b101000011000;
    n541[12] = 12'b100000000100;
    n541[11] = 12'b011001011110;
    n541[10] = 12'b010100001111;
    n541[9] = 12'b010000000101;
    n541[8] = 12'b001100110001;
    n541[7] = 12'b001010001001;
    n541[6] = 12'b001000000100;
    n541[5] = 12'b000110011001;
    n541[4] = 12'b000101000101;
    n541[3] = 12'b000100000010;
    n541[2] = 12'b000011001101;
    n541[1] = 12'b000010100011;
    n541[0] = 12'b000000000000;
    end
  assign n542_data = n541[n108_o];
  /* sn76489_audio.vhd:404:29  */
endmodule


/*
 * Sound generation
 */
module sound(
  input  logic         CLK_DRV,
  input  logic         CLK_AUDIO,
  input  logic         VRESET_N,
  input  logic  [8:0]  VCNT,
  input  logic         SR1, SR2,
  input  logic         ROCKET_1, ROCKET_2,
  input  logic         CRASH_N,
  output logic [15:0]  SOUND
);
  // ---------------------------------------------------------------------------
  // Gating signals for rocket sound
  // ---------------------------------------------------------------------------
  logic C3_QA, C3_QC, C3_QD;
  logic D5a, D4d, E3a, F2d;

  SN7493 SN7493_L7(
    .CLK_DRV,
    .CKA_N(VRESET_N), .CKB_N(C3_QA),
    .R0(1'b0), .R1(1'b0),
    .QA(C3_QA), .QB(), .QC(C3_QC), .QD(C3_QD)
  );

  assign D5a = ~SR1;
  assign D4d = ~D5a | ~C3_QC;
  assign E3a = ~SR2;
  assign F2d = ~E3a | ~C3_QD;

  // ---------------------------------------------------------------------------
  // Synchronize game signals to audio clock domain
  // ---------------------------------------------------------------------------
  logic [8:0] vcnt;
  logic rocket_1, rocket_2;
  logic mute_1, mute_2;
  logic crash_n;

  synchronizer #(.WIDTH(9)) s1 (.clk(CLK_AUDIO), .in(VCNT),     .out(vcnt));
  synchronizer #(.WIDTH(1)) s2 (.clk(CLK_AUDIO), .in(ROCKET_1), .out(rocket_1));
  synchronizer #(.WIDTH(1)) s3 (.clk(CLK_AUDIO), .in(ROCKET_2), .out(rocket_2));
  synchronizer #(.WIDTH(1)) s4 (.clk(CLK_AUDIO), .in(D4d),      .out(mute_1));
  synchronizer #(.WIDTH(1)) s5 (.clk(CLK_AUDIO), .in(F2d),      .out(mute_2));
  synchronizer #(.WIDTH(1)) s6 (.clk(CLK_AUDIO), .in(CRASH_N),  .out(crash_n));

  // ---------------------------------------------------------------------------
  // 96 kHz enable signal for sample generation
  // ---------------------------------------------------------------------------
  logic [7:0] div;
  logic       en_96khz;
  always_ff @(posedge CLK_AUDIO) begin
    div <= div + 1'd1;
  end
  assign en_96khz = div == 0;

  // ---------------------------------------------------------------------------
  // Sound submodules
  // ---------------------------------------------------------------------------
  logic signed [15:0] rocket_1_sound;
  logic signed [15:0] rocket_2_sound;
  logic signed [15:0] crash_sound;
  logic signed [15:0] rocket1_addr, rocket2_addr;
  logic signed [8:0] rocket1_do, rocket2_do;   
  
dprom_2r #(
	.INIT_FILE("./sound_delta.mif"),
	.WIDTHAD_A(15),
	.WIDTH_A(9),
	.WIDTHAD_B(15),
	.WIDTH_B(9))
snd(
	.address_a(rocket1_addr),
	.address_b(rocket2_addr),
	.clock(CLK_AUDIO),
	.q_a(rocket1_do),
	.q_b(rocket2_do),
	);

  sound_rocket sound_rocket_1(
    .clk(CLK_AUDIO),
    .sample_en(en_96khz),
    .vcnt(vcnt),
    .rocket(rocket_1),
    .sound_out(rocket_1_sound),
	 .rocket_addr(rocket1_addr),
	 .rocket_do(rocket1_do)
  );

  sound_rocket sound_rocket_2(
    .clk(CLK_AUDIO),
    .sample_en(en_96khz),
    .vcnt(vcnt),
    .rocket(rocket_2),
    .sound_out(rocket_2_sound),
	 .rocket_addr(rocket2_addr),
	 .rocket_do(rocket2_do)
  );

  sound_crash sound_crash(
    .clk(CLK_AUDIO),
    .sample_en(en_96khz),
    .crash_n(crash_n),
    .sound_out(crash_sound)
  );

  // ---------------------------------------------------------------------------
  // Gate rocket sound
  // ---------------------------------------------------------------------------
  logic signed [15:0] rocket_1_sound_gated;
  logic signed [15:0] rocket_2_sound_gated;

  sound_gate rocket_1_gate(
    .clk(CLK_AUDIO),
    .sample_en(en_96khz),
    .mute(mute_1),
    .sound_in(rocket_1_sound),
    .sound_out(rocket_1_sound_gated)
  );

  sound_gate rocket_2_gate(
    .clk(CLK_AUDIO),
    .sample_en(en_96khz),
    .mute(mute_2),
    .sound_in(rocket_2_sound),
    .sound_out(rocket_2_sound_gated)
  );

  // ---------------------------------------------------------------------------
  // Mix and filter (low pass)
  // ---------------------------------------------------------------------------
  logic signed [15:0] sound;

  rc_mixing_filter rc_mixing_filter (
    .clk(CLK_AUDIO),
    .sample_en(en_96khz),
    .sound_in_1(rocket_1_sound_gated),
    .sound_in_2(rocket_2_sound_gated),
    .sound_in_3(crash_sound),
    .sound_out(sound)
  );

  assign SOUND = unsigned'(sound);

endmodule

/* ============================================================================
 * Crash sound generation
 * ============================================================================
 * Source of crash sound is triangular wave output of NE566(A4) VCO.
 * And the start and the length of crash sound is determined by NE555(A3) timer
 * configured to oneshot mode triggered by CRASH_N signal negative edge.
 *
 * Modulation voltage input to VCO is provided from the voltage converted from
 * THR voltage of NE555(A3) through R53, R55.
 *
 * The duration of the timer output is aprox 70 ms.
 * During the output, modulated freq changes from aprox 720 Hz to 400 Hz.
 *
 * This implementation just synthesize similar output.
 * The change in freq is linear for simplicity, while it is actually non-linear.
 */
module sound_crash(
  input   logic               clk,
  input   logic               sample_en,
  input   logic               crash_n,
  output  logic signed [15:0] sound_out
);
  // Detect trigger
  logic crash_n_q;
  logic trig;
  always_ff @(posedge clk) begin
    crash_n_q <= crash_n;
  end
  assign trig = ~crash_n & crash_n_q;

  // Synthesize modulated triangle wave
  localparam SAMPLE_COUNT   = 6720;
  localparam SAMPLE_COUNT_W = $clog2(SAMPLE_COUNT);
  localparam SUB_COUNT      = 48;
  localparam SUB_COUNT_W    = $clog2(SUB_COUNT);

  localparam signed [15:0] INIT_DELTA =  16'sd315;
  localparam signed [15:0] CLIP_U     =  16'sd10000;
  localparam signed [15:0] CLIP_L     = -16'sd10000;

  logic                      out;
  logic                      terminate;
  logic                      inc;
  logic signed        [15:0] sound;
  logic signed        [15:0] delta;
  logic [SAMPLE_COUNT_W-1:0] cnt_sample;
  logic    [SUB_COUNT_W-1:0] cnt_sub;

  always_ff @(posedge clk) begin
    if (trig) begin
      out        <= 1'b1;
      terminate  <= 1'b0;
      inc        <= 1'b1;
      sound      <= 0;
      cnt_sample <= 0;
      cnt_sub    <= 0;
      delta      <= INIT_DELTA;
    end else if (out && sample_en) begin
      if (cnt_sample == SAMPLE_COUNT - 1) begin
        out       <= 1'b0;
        terminate <= 1'b1;
      end else begin
        cnt_sample <= cnt_sample + 1'd1;
      end

      if (cnt_sub == SUB_COUNT - 1) begin
        cnt_sub <= 0;
        delta   <= delta - 1'd1;
      end else begin
        cnt_sub <= cnt_sub + 1'd1;
      end

      if (inc) begin
        if (sound + delta >= CLIP_U) begin
          sound <= CLIP_U;
          inc   <= 1'b0;
        end else begin
          sound <= sound + delta;
        end
      end else begin
        if (sound - delta <= CLIP_L) begin
          sound <= CLIP_L;
          inc   <= 1'b1;
        end else begin
          sound <= sound - delta;
        end
      end

    end else if (terminate && sample_en) begin
      if (sound > -delta && sound < delta) begin
        terminate <= 1'b0;
        sound     <= 0;
      end else if (sound >= 0) begin
        sound = sound - delta;
      end else if (sound < 0) begin
        sound = sound + delta;
      end
    end
  end

  assign sound_out = sound;

endmodule

/* ============================================================================
 * Rocket sound generation
 * ============================================================================
 * NOTE: Annotation of the description below is for Rocket 1.
 * Sound circuit for Rocket 2 is the same as Rocket 1.
 *
 * Source of rocket sound is triangular wave output of NE566(C4) VCO.
 *
 * Negative output of D-FF(B4a) is used for modulation voltage input to VCO
 * through RC network(R33, R31, C19)
 *
 * Negative output of D-FF(B4a) turns high when VRESET_N is asserted.
 * And it turns low at the edge of rocket signal.
 * Its duty ratio and integral voltage waveform after RC network varies
 * depending on the position of the rocket.
 *
 *  - The lower the rocket is on the screen,
 *    the higher the waveform voltage and the lower the frequency.
 *
 *  - The upper the rocket is on the screen,
 *    the lower the waveform voltage and the higher the frequency.
 *
 * Here, pre-calculated delta table on ROM is used, since is is hard to
 * calculate frequency at each rocket position and each vertical video line
 * on FPGA.
 */
module sound_rocket(
  input   logic               clk,
  input   logic               sample_en,
  input   logic         [8:0] vcnt,
  input   logic               rocket,
  output  logic signed [15:0] sound_out,
  output  logic signed [15:0] rocket_addr,
  input   logic         [8:0] rocket_do
);
  // Detect rocket edge
  logic rocket_q;
  logic rocket_edge;
  always_ff @(posedge clk) begin
    rocket_q <= rocket;
  end
  assign rocket_edge = rocket & ~rocket_q;

  // Capture VCNT on rocket edge
  logic [8:0] rocket_vcnt;
  always_ff @(posedge clk) begin
    if (rocket_edge) begin
      rocket_vcnt <= vcnt;
    end
  end

  // Get delta value on each VCNT from pre-calculated rom.
  logic [15:0] address;
  logic  [8:0] udelta;

  always_ff @(posedge clk) begin
    address <= {rocket_vcnt, vcnt[8:2]};
  end

//  sound_delta sound_delta(
//	  .clock(clk),
//    .address(address),
//	  .q(udelta)
//  );

assign rocket_addr = address;
assign udelta = rocket_do;

  // Synthesize modulated triangle wave
  localparam signed [15:0] CLIP_U =  16'sd10000;
  localparam signed [15:0] CLIP_L = -16'sd10000;

  logic                      inc;
  logic signed        [15:0] sound;
  logic signed        [15:0] delta;

  initial inc   = 1'b1;
  initial sound = 0;

  assign delta = signed'(16'(udelta));

  always_ff @(posedge clk) begin
    if (sample_en) begin
      if (inc) begin
        if (sound + delta >= CLIP_U) begin
          sound <= CLIP_U;
          inc   <= 1'b0;
        end else begin
          sound <= sound + delta;
        end
      end else begin
        if (sound - delta <= CLIP_L) begin
          sound <= CLIP_L;
          inc   <= 1'b1;
        end else begin
          sound <= sound - delta;
        end
      end
    end
  end

  assign sound_out = sound;

endmodule

/* ============================================================================
 * Sound gate with smooth mute & unmute
 * ============================================================================
 * The sound of the rocket is not always present.
 * It is gated by D4d and Q3 for rocket 1, and F2d and Q4 for rocket 2.
 * A sudden change creates pop noise, so make it smooth.
 */
module sound_gate(
  input   logic               clk,
  input   logic               sample_en,
  input   logic               mute,
  input   logic signed [15:0] sound_in,
  output  logic signed [15:0] sound_out
);
  // Detect mute edge
  logic mute_q;
  logic mute_posedge, mute_negedge;
  always_ff @(posedge clk) begin
    mute_q <= mute;
  end
  assign mute_posedge =  mute & ~mute_q;
  assign mute_negedge = ~mute &  mute_q;

  // Mute & unmute smoothly not to make pop noise
  logic muting, muted, unmuting;
  logic signed [15:0] sound;
  logic [7:0] cnt;

  initial muting   = 0;
  initial muted    = 1;
  initial unmuting = 0;

  always_ff @(posedge clk) begin
    if (mute_posedge) begin
      muting   = 1'b1;
      muted    = 1'b0;
      unmuting = 1'b0;
      cnt      = 0;
    end else if (mute_negedge) begin
      muting   = 1'b0;
      muted    = 1'b0;
      unmuting = 1'b1;
      cnt      = 0;
    end
    if (sample_en) begin
      if (muting) begin
        sound <= sound_in >>> cnt[7:6];
      end else if (unmuting) begin
        sound <= sound_in >>> ~cnt[7:6];
      end else if (muted) begin
        sound <= 0;
      end else begin
        sound <= sound_in;
      end
      if (muting) begin
        cnt = cnt + 1'd1;
        if (&cnt) begin
          muting   = 1'b0;
          muted    = 1'b1;
        end
      end else if (unmuting) begin
        cnt = cnt + 1'd1;
        if (&cnt) begin
          unmuting = 1'b0;
        end
      end
    end
  end

  assign sound_out = sound;

endmodule

/* ============================================================================
 * Mix and filter multiple signals
 * ============================================================================
 * Each sound(rocket 1, rocket 2, crash) is finally mixed via RC network
 * (R35, R47, R57, C43).
 * It also forms a low-pass filter.
 *
 * Here, simple Euler method is used to calculate the output of RC network.
 * All calculations are done in integer.
 * Multiply and division are done by just shifting.
 *
 * R, C values and delta time used in these calculations are not actual and
 * normalized for simplicity.
 * However, those are adjusted so that the final response is close to
 * the actual one as possible.
 */
module rc_mixing_filter(
  input   logic               clk,
  input   logic               sample_en,
  input   logic signed [15:0] sound_in_1,
  input   logic signed [15:0] sound_in_2,
  input   logic signed [15:0] sound_in_3,
  output  logic signed [15:0] sound_out
);
  localparam WEIGHT1 = 0;
  localparam WEIGHT2 = 0;
  localparam WEIGHT3 = 1;

  localparam INT_WIDTH = 16 + $clog2(2**WEIGHT1 + 2**WEIGHT2 + 2**WEIGHT3);

  logic signed [INT_WIDTH-1:0] sound_in_1_w;
  logic signed [INT_WIDTH-1:0] sound_in_2_w;
  logic signed [INT_WIDTH-1:0] sound_in_3_w;

  assign sound_in_1_w = INT_WIDTH'(sound_in_1);
  assign sound_in_2_w = INT_WIDTH'(sound_in_2);
  assign sound_in_3_w = INT_WIDTH'(sound_in_3);

  localparam DELTA_SHIFT = 7;
  localparam OUT_SHIFT   = 2;

  logic signed [INT_WIDTH-1:0] slope;
  logic signed [INT_WIDTH-1:0] sound;

  logic       calc;
  logic [2:0] calc_cnt;

  always_ff @(posedge clk) begin
    if (sample_en) begin
      sound    <= sound + (slope >>> DELTA_SHIFT);
      calc     <= 1'b1;
      calc_cnt <= 0;
      slope    <= 0;
    end
    if (calc) begin
      if (calc_cnt == 0) begin
        slope <= slope + (sound_in_1_w <<< WEIGHT1);
      end
      else if (calc_cnt == 1) begin
        slope <= slope + (sound_in_2_w <<< WEIGHT2);
      end
      else if (calc_cnt == 2) begin
        slope <= slope + (sound_in_3_w <<< WEIGHT3);
      end
      else if (calc_cnt == 3) begin
        slope <= slope - (sound <<< WEIGHT1);
      end
      else if (calc_cnt == 4) begin
        slope <= slope - (sound <<< WEIGHT2);
      end
      else if (calc_cnt == 5) begin
        slope <= slope - (sound <<< WEIGHT3);
        calc  <= 1'b0;
      end
      calc_cnt <= calc_cnt + 1'd1;
    end
  end

  assign sound_out = 16'(sound <<< OUT_SHIFT);

endmodule

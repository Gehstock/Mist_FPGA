/*
 * Game control
 */
module gamecntl(
  input  logic       CLK_DRV,
  input  logic       RESET,         // Force reset Q latch
  input  logic       COINAGE,       // 0: 1CREDIT/1COIN, 1: 2CREDITS/1COIN
  input  logic [3:0] PLAYTIME,      // 0: 0%,  1: 10%, 2: 20%, 3: 30%, 4: 40%, 5: 50%,
                                    // 6: 60%, 7: 70%, 8: 80%, 9: 90%, 10: 100%
  input  logic       COIN_SW,
  input  logic       START_GAME,
  input  logic       _256H_N,
  input  logic       _256V_N,
  input  logic       HRESET,        // not used in real hardware here
  input  logic       VBLANK_N,
  output logic       GAME_ON,
  output logic       RESET_N,       // Reset video counter and stars counter
  output logic       RESET_SCORE_N, // Reset score
  output logic       FUEL_N,
  output logic       CREDIT_LIGHT_N
);
  // Internal nets
  logic Q, COIN_N, CREDIT, CREDIT_N, GAME_ON_N, GAME_END_N;

  // -------------------------------------------------------------------------
  // Coin switch
  // -------------------------------------------------------------------------
  // COIN_N(B8b_Q_N) is asserted when COIN_SW is turned on for more than
  // 0.01 seconds.
  //
  logic A9_OUT, B9d, B8b_Q_N;

  oneshot_555 #(
    .COUNTS(572720)  // 0.01 s
  ) oneshot_555_A9 (
    .CLK(CLK_DRV),
    .RST_N(1'b1),
    .TRG_N(~COIN_SW),
    .OUT(A9_OUT)
  );

  SN7474 SN7474_B8b(
    .CLK_DRV,
    .CLK(B9d),
    .PRE_N(1'b1), .CLR_N(COIN_SW),
    .D(COIN_SW),
    .Q(), .Q_N(B8b_Q_N)
  );

  assign B9d = A9_OUT;

  assign COIN_N  = B8b_Q_N;
  assign RESET_N = ~COIN_SW;

  // -------------------------------------------------------------------------
  // Credit register
  // -------------------------------------------------------------------------
  // CREDIT(A8a_Q_N) is asserted when there is available credit left,
  // which determines whether game can be started on gate C8c.
  //
  // CREDIT_N(A8a_Q) is inverted signal of CREDIT(A8a_Q_N),
  // which determines whether Q latch can be reset at game end on gate D8d.
  //
  // Behavior of A8b and A8a will be changed by COINAGE SW.
  //
  logic A8b_Q, A8a_Q, A8a_Q_N;

  // Add delay to GAME_ON_N so that its initial positive edge can be
  // detected on loading core (=equivalent to powering up real hardware).
  // Without the delay, initial state of A8a will be wrong.
  logic GAME_ON_N_q;
  initial GAME_ON_N_q = 1'b0;
  always_ff @(posedge CLK_DRV) GAME_ON_N_q <= GAME_ON_N;

  SN7474 SN7474_A8b(
    .CLK_DRV,
    .CLK(GAME_ON_N_q),
    .PRE_N(COINAGE ? 1'b1: 1'b0), .CLR_N(COINAGE ? COIN_N : 1'b1),
    .D(1'b1),
    .Q(A8b_Q), .Q_N()
  );

  SN7474 SN7474_A8a(
    .CLK_DRV,
    .CLK(GAME_ON_N_q),
    .PRE_N(1'b1), .CLR_N(COIN_N),
    .D(A8b_Q),
    .Q(A8a_Q), .Q_N(A8a_Q_N)
  );

  assign CREDIT_N = A8a_Q;
  assign CREDIT   = A8a_Q_N;

  // -------------------------------------------------------------------------
  // Playtime timer
  // -------------------------------------------------------------------------
  // We can play game while the output of C9 (555 timer configured to oneshot)
  // is asserted.
  //
  // The duration of the timer can be adjusted by variable resistor
  // on real hardware.
  //
  // Since FPGA cannot handle analog value, values in 10% increments are used
  // to emulate it.
  //
  logic C8c, C9_OUT, C4a, D8d;
  logic [10:0] count_out_C9;

  logic [10:0] counts_C9;
  always_comb begin
    case (PLAYTIME)
      4'd0:  counts_C9 = 11'd455;  // 0%:   45.5 s
      4'd1:  counts_C9 = 11'd600;  // 10%:  60 s
      4'd2:  counts_C9 = 11'd750;  // 20%:  75 s
      4'd3:  counts_C9 = 11'd900;  // 30%:  90 s
      4'd4:  counts_C9 = 11'd1050; // 40%:  105 s
      4'd5:  counts_C9 = 11'd1200; // 50%:  120 s
      4'd6:  counts_C9 = 11'd1350; // 60%:  135 s
      4'd7:  counts_C9 = 11'd1500; // 70%:  150 s
      4'd8:  counts_C9 = 11'd1650; // 80%:  165 s
      4'd9:  counts_C9 = 11'd1800; // 90%:  180 s
      4'd10: counts_C9 = 11'd1950; // 100%: 195 s
      default: counts_C9 = 11'd1200;
    endcase
  end

  // To simplify, generate 100 msec count enable signal
  logic [22:0] div_C9;
  logic        en_100ms;
  always_ff @(posedge CLK_DRV) begin
    if (!C8c)
      div_C9 <= 0;
    else if (div_C9 == 5727200 - 1)
      div_C9 <= 0;
    else
      div_C9 <= div_C9 + 1'd1;
  end
  assign en_100ms = div_C9 == 0;

  oneshot_555_var #(
    .BW(11)
  ) oneshot_555_C9 (
    .CLK(CLK_DRV),
    .RST_N(Q),
    .COUNTS(counts_C9),
    .COUNT_EN(en_100ms),
    .TRG_N(C8c),
    .OUT(C9_OUT),
    .CNT_OUT(count_out_C9)
  );

  assign C8c = ~(GAME_ON_N & START_GAME & CREDIT);
  assign C4a = ~C9_OUT;
  assign D8d = ~(C4a & CREDIT_N);

  assign GAME_ON = C9_OUT;
  assign GAME_ON_N = C4a;
  assign GAME_END_N = D8d;
  assign RESET_SCORE_N = C8c;

  // -------------------------------------------------------------------------
  // Q Latch
  // -------------------------------------------------------------------------
  // A game state latch made up of transistors,
  // similar to those found in Atari's discrete games.
  //
  always_ff @(posedge CLK_DRV) begin
    if (RESET)
      Q <= 1'b0; // Game stop
    else if (!COIN_N)
      Q <= 1'b1; // Game availabe
    else if (!GAME_END_N)
      Q <= 1'b0; // Game stop
  end

  // -------------------------------------------------------------------------
  // Fuel bar timer
  // -------------------------------------------------------------------------
  // Fuel bar shows the remaining time of the game.
  //
  // On real hardware, THR voltage of C9 (555 playtime timer) is given to
  // CTRL voltage pin of 555 D9 (555 timer) via transistors Q1 and Q4,
  // modulating output pulse width of D9.
  //
  // D9 timer is configured to oneshot triggered by _256_V_N and the end of
  // timer output indicates the top position of fuel bar which is controled by
  // CTRL voltage.
  //
  // This feature is digitally emulated to produce similar output
  // as FPGA cannot handle this kind of analog stuff.
  //
  // The movement of fuel bar may be a bit jerky compared to real hardware
  // that uses analog circuits:(
  // And it is linear here, whereas it is non-linear in real hardware.
  //
  logic D9_OUT;

  // Each bit indicates whether or not the count value of D9 should be
  // increased for each count up of C9. It differs depending on PLAYTIME.
  // This pattern is used repeatedly.
  logic [38:0] inc_en;
  always_comb begin
    case (PLAYTIME)
      4'd0:    inc_en = 39'b000000000000000000000000000000100101010;
      4'd1:    inc_en = 39'b000000000000000000000000000000000000100;
      4'd2:    inc_en = 39'b000000000000000000000000100100010001000;
      4'd3:    inc_en = 39'b000000000000000000000000000000100001000;
      4'd4:    inc_en = 39'b000000000000000000100001000010000100000;
      4'd5:    inc_en = 39'b000000000000000000000000000000000100000;
      4'd6:    inc_en = 39'b000000000000100000100000010000001000000;
      4'd7:    inc_en = 39'b000000000000000000000000100000010000000;
      4'd8:    inc_en = 39'b000000100000000100000001000000010000000;
      4'd9:    inc_en = 39'b000000000000000000000000000000100000000;
      4'd10:   inc_en = 39'b100000000100000000010000000001000000000;
      default: inc_en = 39'b000000000000000000000000000000000100000;
    endcase
  end

  // Length of bit sequence above. It differs depending on PLAYTIME.
  logic [5:0] inc_en_len;
  always_comb begin
    case (PLAYTIME)
      4'd0:  inc_en_len = 6'd9;
      4'd1:  inc_en_len = 6'd3;
      4'd2:  inc_en_len = 6'd15;
      4'd3:  inc_en_len = 6'd9;
      4'd4:  inc_en_len = 6'd21;
      4'd5:  inc_en_len = 6'd6;
      4'd6:  inc_en_len = 6'd27;
      4'd7:  inc_en_len = 6'd15;
      4'd8:  inc_en_len = 6'd33;
      4'd9:  inc_en_len = 6'd9;
      4'd10: inc_en_len = 6'd39;
      default: inc_en_len = 4'd6;
    endcase
  end

  // Detect C9 trigger
  logic C8c_q;
  logic C9_trigger;
  always_ff @(posedge CLK_DRV) begin
    C8c_q <= C8c;
  end
  assign C9_trigger = C8c_q & ~C8c;

  // Detect C9 count up
  logic [10:0] count_out_C9_q;
  logic C9_countup;
  always_ff @(posedge CLK_DRV) begin
    count_out_C9_q <= count_out_C9;
  end
  assign C9_countup = count_out_C9 == count_out_C9_q + 1'd1;

  // Increase D9 count value when C9 count up depending on bit in inc_en
  logic [5:0] inc_index;
  logic [8:0] counts_D9;

  always_ff @(posedge CLK_DRV) begin
    if (C9_trigger) begin
      // Initial position (counts_D9) can be adjusted by variable resistor (R27)
      // on real hardware, but here it is fixed.
      counts_D9 <= 9'd63;
      inc_index <= 0;
    end else if (C9_countup && counts_D9 != 262) begin
      if (inc_en[inc_index])
        counts_D9 <= counts_D9 + 1'd1;

      if (inc_index == inc_en_len - 1'd1)
        inc_index <= 0;
      else
        inc_index <= inc_index + 1'd1;
    end
  end

  // Generate count enable signal at HRESET (once per vertical video line)
  logic prev_HRESET;
  logic en_D9;
  always_ff @(posedge CLK_DRV) begin
    prev_HRESET <= HRESET;
  end
  assign en_D9 = ~prev_HRESET & HRESET;

  oneshot_555_var #(
    .BW(9)
  ) oneshot_555_D9 (
    .CLK(CLK_DRV),
    .RST_N(1'b1),
    .COUNTS(counts_D9),
    .COUNT_EN(en_D9),
    .TRG_N(_256V_N),
    .OUT(D9_OUT)
  );

  // -------------------------------------------------------------------------
  // Fuel bar display
  // -------------------------------------------------------------------------
  // DM9602 Monostable multivibrator outputs fuel bar with some width.
  //
  logic E9a, L4a_Q, C8b;

  DM9602 #(
    .COUNTS(34)  // 600 ns
  ) DM9602_L4a (
    .CLK(CLK_DRV),
    .A_N(_256H_N), .B(1'b0),
    .CLR_N(1'b1),
    .Q(L4a_Q), .Q_N()
  );

  assign E9a = ~D9_OUT;
  assign C8b = ~(GAME_ON & E9a & L4a_Q);
  assign FUEL_N = C8b;


  // -------------------------------------------------------------------------
  // Credit light
  // -------------------------------------------------------------------------
  // D8c (CREDIT_LIGHT_N) indicates whether credit is left (game can start).
  //
  logic D8c;
  assign D8c = ~(Q & CREDIT);
  assign CREDIT_LIGHT_N = D8c;

endmodule

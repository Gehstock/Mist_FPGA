/*
 * Video sync
 */
module videosync(
  input  logic CLK_DRV,
  input  logic _16H, _32H, _64H, HRESET_N,
  input  logic _4V, _8V, _16V, VRESET,
  output logic HSYNC, HSYNC_N,
  output logic HBLANK, HBLANK_N,
  output logic VSYNC, VSYNC_N,
  output logic VBLANK, VBLANK_N
);
  // -------------------------------------------------------------------------
  // HBLANK
  // -------------------------------------------------------------------------
  logic A7b, A7d, A7c;
  logic HBLANK_RAW, HBLANK_N_RAW;

  assign A7b = ~(_16H & _64H);

  nand_rsff nand_rsff_A7d_A7c(
    .CLK_DRV,
    .S_N(HRESET_N), .R_N(A7b),
    .Q(A7d), .Q_N(A7c)
  );

  // Add delay to hblank.
  // The delay is actually caused by ripple counter and gate in real hardware.
  logic [4:0] HBLANK_DELAY;
  logic [4:0] HBLANK_N_DELAY;
  always_ff @(posedge CLK_DRV) begin
    HBLANK_DELAY   <= {A7d, HBLANK_DELAY[4:1]};
    HBLANK_N_DELAY <= {A7c, HBLANK_N_DELAY[4:1]};
  end
  assign HBLANK   = HBLANK_DELAY[0];
  assign HBLANK_N = HBLANK_N_DELAY[0];

  // -------------------------------------------------------------------------
  // HSYNC
  // -------------------------------------------------------------------------
  logic D7e, A7a, B7d;
  logic B8a_Q, B8a_Q_N;

  assign D7e = ~_64H;
  assign A7a = ~(_32H & D7e);
  assign B7d = ~HBLANK_N & ~_64H;

  SN7474 SN7474_B8a(
    .CLK_DRV,
    .CLK(_16H),
    .PRE_N(1'b1), .CLR_N(B7d),
    .D(A7a),
    .Q(HSYNC), .Q_N(HSYNC_N)
  );

  // -------------------------------------------------------------------------
  // VBLANK
  // -------------------------------------------------------------------------
  logic B7b, B7a;

  nor_rsff nor_rsff_B7b_B7a(
    .CLK_DRV,
    .R(VRESET), .S(_16V),
    .Q(B7b), .Q_N(B7a)
  );

  assign VBLANK_N = B7b;
  assign VBLANK   = B7a;

  // -------------------------------------------------------------------------
  // VSYNC
  // -------------------------------------------------------------------------
  logic D7f, C8a;

  assign D7f = _8V;
  assign C8a = ~(VBLANK & _4V & D7f);
  assign VSYNC = ~C8a;
  assign VSYNC_N = C8a;

endmodule

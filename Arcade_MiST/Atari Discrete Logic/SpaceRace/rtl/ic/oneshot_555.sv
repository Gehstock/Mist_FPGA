/*
 * Emulates 555 timer monostable oneshot circuit by counting clock
 */
module oneshot_555(
  input   logic   CLK,    // clock for counting
  input   logic   RST_N,  // reset negative
  input   logic   TRG_N,  // trigger negative edge
  output  logic   OUT     // output
);
  parameter  COUNTS = 1000;
  localparam BIT_WIDTH = $clog2(COUNTS);

  typedef enum logic [1:0] {
    IDLE, COUNT, END
  } state_t;

  state_t state;

  //
  // Edge detector
  //
  logic prev_trg_n;
  logic detect;

  always_ff @(posedge CLK) begin
    prev_trg_n <= TRG_N;
  end

  assign detect = prev_trg_n & ~TRG_N;

  //
  // Counter
  //
  logic [BIT_WIDTH-1 : 0] counter;
  logic count_end;

  always_ff @(posedge CLK) begin
    if (state == IDLE | state == END)
      counter <= 0;
    else if (state == COUNT)
      counter <= counter + 1'd1;
  end

  assign count_end = (counter == COUNTS - 1);

  //
  // State machine
  //
  state_t next_state;

  always_ff @(posedge CLK) begin
    state <= next_state;
  end

  always_comb begin
    case (state)
      IDLE:     if (detect) next_state <= COUNT;
                else next_state <= IDLE;
      COUNT:    if (count_end || !RST_N) next_state <= END;
                else next_state <= COUNT;
      END:      next_state <= IDLE;
      default:  next_state <= IDLE;
    endcase
  end

  //
  // Output
  //
  always_comb begin
    if (state == COUNT)
      OUT = 1'b1;
    else
      OUT = 1'b0;
  end

endmodule

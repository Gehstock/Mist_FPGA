/*
 * DM9602 (Retriggerable, Resettable One Shots)
 */
module DM9602(
  input  logic CLK,
  input  logic A_N, B,
  input  logic CLR_N,
  output logic Q, Q_N
);
  parameter COUNTS = 1000;
  parameter BIT_WIDTH = $clog2(COUNTS);

  logic trg, out;
  assign trg = ~A_N | B;

  typedef enum logic [1:0] {
    IDLE, COUNT, END
  } state_t;

  state_t state;

  //
  // Edge detector (potisive edge)
  //
  logic prev_trg;
  logic detect;

  always_ff @(posedge CLK) begin
    prev_trg <= trg;
  end

  assign detect = ~prev_trg & trg;

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
      IDLE:     if (detect && CLR_N) next_state = COUNT;
                else next_state = IDLE;
      COUNT:    if (count_end || !CLR_N) next_state = END;
                else next_state = COUNT;
      END:      next_state = IDLE;
      default:  next_state = IDLE;
    endcase
  end

  //
  // Output
  //
  always_comb begin
    if (state == COUNT)
      out = 1'b1;
    else
      out = 1'b0;
  end

  assign Q   = out;
  assign Q_N = ~out;

endmodule

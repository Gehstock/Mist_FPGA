/*
 * Emulates 555 timer astable circuit by counting clock
 */
module astable_555(
  input   logic   CLK,      // clock for counting
  input   logic   RESET_N,  // reset negative
  output  logic   OUT       // output
);
  parameter HIGH_COUNTS = 1000;
  parameter LOW_COUNTS  = 1000;

  localparam BIT_WIDTH_HIGH = $clog2(HIGH_COUNTS);
  localparam BIT_WIDTH_LOW  = $clog2(LOW_COUNTS);

  typedef enum logic [1:0] {
    RESET, HIGH_COUNT, LOW_COUNT
  } state_t;

  state_t state;

  //
  // Counter
  //
  logic [BIT_WIDTH_HIGH-1 : 0] high_counter;
  logic [BIT_WIDTH_LOW-1 : 0]  low_counter;
  logic high_count_end, low_count_end;

  always_ff @(posedge CLK) begin
    if (state == HIGH_COUNT)
      high_counter <= high_counter + 'd1;
    else if (state == LOW_COUNT)
      low_counter  <= low_counter  + 'd1;
    else if (state == RESET) begin
      high_counter <= 'd0;
      low_counter  <= 'd0;
    end
  end

  assign high_count_end = (high_counter == HIGH_COUNTS - 1);
  assign low_count_end  = (low_counter  == LOW_COUNTS  - 1);

  //
  // State machine
  //
  state_t next_state;

  always_ff @(posedge CLK) begin
    state <= next_state;
  end

  always_comb begin
    case (state)
      RESET:        if (!RESET_N)
                      next_state <= RESET;
                    else
                      next_state <= HIGH_COUNT;

      HIGH_COUNT:   if (!RESET_N)
                      next_state <= RESET;
                    else if (high_count_end)
                      next_state <= LOW_COUNT;
                    else
                      next_state <= HIGH_COUNT;

      LOW_COUNT:    if (!RESET_N)
                      next_state <= RESET;
                    else if (low_count_end)
                      next_state <= HIGH_COUNT;
                    else
                      next_state <= LOW_COUNT;

      default:      next_state <= HIGH_COUNT;
    endcase
  end

  //
  // Output
  //
  always_comb begin
    if (state == RESET)
      OUT = 1'b0;
    else if (state == HIGH_COUNT)
      OUT = 1'b1;
    else
      OUT = 1'b0;
  end

endmodule

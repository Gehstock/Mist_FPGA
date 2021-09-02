//
// Decoder for .CIN and K7 formats based on MAME/MESS hect_tap.cpp written by JJ Stacino
//
// See https://github.com/mamedev/mame/blob/master/src/lib/formats/hect_tap.cpp
//
// The .K7 format appears to be identical to the .CIN format used by the
// Virtual Interact emulator created by "James The Animal Tamer"
//
// The Interact stores data on tape by using a "bit banged" machanism to drive square
// waves of with periods of different duration for zero, one, and gap bits.
//
// At the start of the tape, a set of gap bits is read.  A minimum of 356 gap bits
// must be found.  Following the initial gaps, the tape data is read.
//
// Data is orgaanized into records.  Each record starts with a length byte followed
// by up to 256 additional bytes.
//
// Records with a length of 5 are special command records.  The last byte of the
// command record is the command byte.  A value of FE indicates a fill command
// and the following record contains the data to use to fill.  A value of FD
// indicates end of file.
// 
// At the end of the tape is a stop ID that consists of:
// 0 - gap - 0 - gap
// 
//

module cassette(
  input clk,
  input rst_n,
  input play,
  input rewind,
  input motor,

  output reg [15:0] tape_addr,
  input [7:0] tape_data,
  input [15:0] tape_end,

  output playing,
  output reg flux,
  output reg [15:0] audio
);

localparam GAP_CLK = 14'd12500;
localparam ZERO_CLK = 14'd4383;
localparam ONE_CLK = 14'd8117;
localparam HI = 16'h7FFF;
localparam LO = 16'h8000;
localparam START_GAP_DURATION = 10'd764;
localparam RECORD_GAP_DURATION = 10'd4;
localparam WAIT_GAP_DURATION = 10'd150;

parameter
  IDLE                  = 3'd0,
  START                 = 3'd1,
  START_RECORD           = 3'd2,
  WRITE_RECORD_LENGTH    = 3'd3,
  WRITE_RECORD_DATA      = 3'd4,
  FINISH                = 3'd5;

reg [2:0] state;
reg wr_cycle;
reg wr_gap;
reg wr_byte;

reg [13:0] cycle_high_count;
reg [13:0] cycle_low_count;

reg [9:0] gap_counter;

reg [7:0] byte_output;
reg [7:0] byte_output_index;

reg [8:0] record_size;
reg [7:0] previous_record;

reg prev_play;
reg prev_rewind;
reg prev_motor;

assign playing = state !== IDLE;

always @(posedge clk or negedge rst_n)
  begin
  if (!rst_n)
    begin
		{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, IDLE};

      cycle_high_count <= 14'b0;
      cycle_low_count <= 14'b0;

      gap_counter <= 10'b0;

      byte_output <= 8'b0;
      byte_output_index <= 8'b0;

      record_size <= 9'b0;
	  previous_record <= 8'b0;

      tape_addr <= 16'b0;
      audio <= 16'b0;
      flux <= 1'b0;
		
		prev_play <= 1'b0;
		prev_rewind <= 1'b0;
		prev_motor <= 1'b0;
   end
  else
	begin
			
		casez ({wr_cycle, wr_gap, wr_byte, state})

		  {1'b1, 1'b?, 1'b?, 3'b???}:
			 begin
				 if (cycle_high_count)
					begin
					  audio <= HI;
					  //flux <= 1'b1;
					  cycle_high_count <= cycle_high_count - 14'd1;
					  
					  {wr_cycle, wr_gap, wr_byte, state} <= {1'b1, wr_gap, wr_byte, state};
					end
				 else if (cycle_low_count)
					begin
					  audio <= LO;
					  //flux <= 1'b0;
					  cycle_low_count <= cycle_low_count - 14'd1;
					  
					  {wr_cycle, wr_gap, wr_byte, state} <= {1'b1, wr_gap, wr_byte, state};
					end
				 else
					begin
					  flux <= ~flux;
					  {wr_cycle, wr_gap, wr_byte, state} <= {1'b0, wr_gap, wr_byte, state};
					end
			end

		  {1'b0, 1'b1, 1'b0, 3'b???}:
			 begin
				 if (gap_counter)
				  begin
					{wr_cycle, wr_gap, wr_byte, state} <= {1'b1, 1'b1, 1'b0, state};
					
					cycle_high_count <= GAP_CLK;
					cycle_low_count <= GAP_CLK;
					
					gap_counter <= gap_counter - 10'd1;
				  end
				else
				  begin
					{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, state};
				  end
			end

		  {1'b0, 1'b0, 1'b1, 3'b???}:
			begin
				if (byte_output_index)
				  begin
					 if (byte_output & byte_output_index)
						begin
						  cycle_high_count <= ONE_CLK;
						  cycle_low_count <= ONE_CLK;
						end
					 else
						begin
						  cycle_high_count <= ZERO_CLK;
						  cycle_low_count <= ZERO_CLK;
						end
						
					 {wr_cycle, wr_gap, wr_byte, state} <= {1'b1, 1'b0, 1'b1, state};
					 byte_output_index <= byte_output_index << 1;
				  end
				else
				  begin
					{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, state};
				  end
			end

		  {1'b0, 1'b0, 1'b0, IDLE}:
			 begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, IDLE};
				
				tape_addr <= 16'b0;
				audio <= 16'b0;
				flux <= 1'b0;
	  			previous_record <= 8'b0;
			 end

		  {1'b0, 1'b0, 1'b0, START}:
			 begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b1, 1'b0, START_RECORD};
				
				tape_addr <= 16'b0;
				audio <= 16'b0;
				flux <= 1'b0;
	  			previous_record <= 8'b0;

				gap_counter <= START_GAP_DURATION;
			 end

		  {1'b0, 1'b0, 1'b0, START_RECORD}:
			 begin
				if (tape_addr <= tape_end)
				  begin
					{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b1, 1'b0, WRITE_RECORD_LENGTH};

					if (previous_record === 8'hFE)
						gap_counter <= WAIT_GAP_DURATION;
					else
						gap_counter <= RECORD_GAP_DURATION;
					
					previous_record <= byte_output;
				  end
				else
				  begin
					 state <= FINISH;
				  end
			 end

		  {1'b0, 1'b0, 1'b0, WRITE_RECORD_LENGTH}:
			 begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b1, WRITE_RECORD_DATA};

				byte_output <= tape_data;
				byte_output_index <= 8'b1;
				
				record_size <= (tape_data == 8'd0 ? 9'd256 : {1'b0, tape_data});
				tape_addr <= tape_addr + 16'd1;

			 end

		  {1'b0, 1'b0, 1'b0, WRITE_RECORD_DATA}:
			 begin
				if ((tape_addr <= tape_end) && (|record_size))
				  begin
					{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b1, WRITE_RECORD_DATA};

					 byte_output <= tape_data;
					 byte_output_index <= 8'b1;

					 tape_addr <= tape_addr + 16'd1;
					 record_size <= record_size - 9'd1;
				  end
				else if (tape_addr > tape_end)
				  begin
					 {wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, FINISH};
				  end
				else
				  begin
					 {wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, START_RECORD};
				  end
			 end

		  {1'b0, 1'b0, 1'b0, FINISH}:
			 begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b1, IDLE};
				
				byte_output <= 8'b0;
				byte_output_index <= 8'b1;
			 end
			 
			default:
				begin
					{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, IDLE};
				end

		endcase
		
		prev_play <= play;
		if (play && !prev_play)
			begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, START};
			end

		prev_rewind <= rewind;
		if (rewind && !prev_rewind)
			begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, IDLE};
			end

		// for enabling the tape to start under software control (color register A, bit 6)
		// for now, this will also rewind and restart tape from beginning, since that's
		// the likely preferred behavior for the user but many need to instead
		// create a pause and resume state to correctly emulate behavior
		prev_motor <= motor;
		if (motor && !prev_motor)
			begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, START};				
			end
		else if (prev_motor && !motor)
			begin
				{wr_cycle, wr_gap, wr_byte, state} <= {1'b0, 1'b0, 1'b0, IDLE};				
			end
	end
  end

endmodule




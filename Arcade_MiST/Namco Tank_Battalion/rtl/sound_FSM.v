module sound # (
	parameter wav_length= 16'd38174;
	parameter init_file= ""
)
(
	input  clk,
	input  trigger,
	input  RESET_n,
	output signed [15:0] sound_out
);

reg sndclk = 1'b0;
always @(posedge clk) begin
    sndclk <= ~sndclk;
end

reg wav_playing = 1'b0;
wire wav_play;
reg [WAV_COUNTER_SIZE-1:0] wav_counter;
localparam WAV_COUNTER_SIZE = 10;//10
localparam WAV_COUNTER_MAX = 100;//1000
reg signed [7:0] wav_signed;

// Wave player
reg [15:0] wave_rom_addr;
wire [7:0] wave_rom_data_out;
reg [15:0] wave_rom_length = wav_length;

spram #(14,8,init_file) wave_rom //should be 64k here not enough BRAM but it works
(
	.clk(clk),
	.address(wave_rom_addr),
	.wren(1'b0),
	.data(),
	.q(wave_rom_data_out)
);


clock trig1(
    .clk(sndclk),
    .rst_n(),
	.Phi2(trigger),
    .cpu_clken(wav_play)
    );

// States
localparam STOP = 0, START = 1, PLAY = 2;
reg [1:0] state = STOP; 

always @(posedge clk) 
begin
  case (state)
    STOP : begin
		wav_signed <= 8'b0;
		wave_rom_addr <= 16'b0; //reset the rom address
		wav_counter <= WAV_COUNTER_MAX; // put the wav counter to the maximum
		if(wav_play) 
		begin//wav_play is trigger to play it
			state <= START;	
			//wav_play <= 1'b0;
		end
    end
    START : begin
		wav_signed <= 8'b0;
		wave_rom_addr <= 16'b0; //reset the rom address
		wav_counter <= WAV_COUNTER_MAX; // put the wav counter to the maximum
 		wav_playing <= 1'b1; //make wav_playing 1
		state <= PLAY;		
    end
    PLAY : begin
		wav_counter <= wav_counter - 1'b1; //reduce the wav counter by one bit.
		if(wav_play) 
		begin//wav_play is trigger to play it
			state <= START;	
			//wav_play <= 1'b0;
		end
		if(wav_counter == {WAV_COUNTER_SIZE{1'b0}})// if wav counter is zero.
		begin
			if(wave_rom_addr < wave_rom_length) // if wave rom address is below wave rom length (38174)
			begin
				wav_signed <= wave_rom_data_out; //wav signed is wave rom data out
				wave_rom_addr <= wave_rom_addr + 16'b1; //wave rom address is incremented by 1 bit
				wav_counter <= {WAV_COUNTER_SIZE{1'b1}}; //wav counter is? check this!
			end
			else //if wave rom address in NOT below wave rom length
			begin
				state <= STOP;	
			end
		end
    end
  endcase
end

wire signed [15:0] wav_amplified = { wav_signed[7], {1{wav_signed[7]}}, wav_signed[6:0], {7{wav_signed[7]}} }; //create 16 bit from 8 bit wav
assign sound_out = wav_amplified;

endmodule


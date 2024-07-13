//============================================================================
// Sound sample player.
// 
// Author: gaz68 (https://github.com/gaz68)
// October 2019
// Adapted by alanswx to parse the wave
//
// Adjustments for diskimage interface, and stereo support by
// Alastair M. Robinson
//
//============================================================================

module wave_sound #(parameter SYSCLOCK = 40000000)
(
	input         I_CLK,
	input         I_RST,

	input  [27:0] I_BASE_ADDR,
	input         I_LOOP,
	input         I_PAUSE,
	
	output [27:0] O_ADDR, // output address to wave ROM
	output        O_READ, // read a byte
	output        O_READNEXT, // read a byte
	input   [7:0] I_DATA,  // Data coming back from wave ROM
	input         I_READY, // data is ready

	output [15:0] O_PCM_L,
	output [15:0] O_PCM_R
);

reg [27:0] W_DMA_ADDR;
reg [27:0] END_ADDR;
reg        W_DMA_EN;
reg        inheader;
reg [15:0] num_channels;
reg [31:0] sample_rate;
reg [31:0] byte_rate;
reg [15:0] block_align;
reg [15:0] bits_per_sample;
reg [23:0] data_size;
reg [27:0] START_ADDR;

reg  [7:0] W_SAMPL_LSB;
reg signed [15:0] W_SAMPL_L;
reg signed [15:0] W_SAMPL_R;

reg [31:0] sum;
wire[31:0] sum_next = sum + ( stereo ? {sample_rate,1'b0} : sample_rate);

reg signed [9:0] volume;
reg signed [8:0] voldelay;
reg signed [24:0] scaled_l;
reg signed [24:0] scaled_r;

reg playing;

wire stereo = num_channels==16'h2 ? 1'b1 : 1'b0;
reg channel_toggle;

reg ce_sample;
always @(posedge I_CLK) begin
	ce_sample <= 0;
	sum <= sum_next;
	if(sum_next >= SYSCLOCK) begin
		sum <= sum_next - SYSCLOCK;
		ce_sample <= 1;
	end
end

reg read_done = 0;
always@(posedge I_CLK) begin

	if(I_RST)begin
		W_DMA_ADDR <= I_BASE_ADDR;
		W_DMA_EN	  <= 1'b1;
		O_READ     <= 1'b1;
		O_READNEXT <= 1'b0;
		inheader   <= 1'b1;
		read_done  <= 1'b0;
	end
	else if (W_DMA_EN) begin
		if (I_READY) begin
			O_READ <= 0;
			O_READNEXT <= 0;
		end

		if (I_READY & ~read_done) begin
			if (inheader) begin
				O_READNEXT <= 1'b1;
				case (W_DMA_ADDR[5:0])
					00: ; // R
					01: ; // I
					02: ; // F
					03: ; // F
					22: num_channels[7:0]   <= I_DATA;
					23: num_channels[15:8]  <= I_DATA;
					24: sample_rate[7:0]      <= I_DATA;
					25: sample_rate[15:8]     <= I_DATA;
					26: sample_rate[23:16]    <= I_DATA;
					27: sample_rate[31:24]    <= I_DATA;
					//28: byte_rate[7:0]      <= I_DATA;
					//29: byte_rate[15:8]     <= I_DATA;
					//30: byte_rate[23:16]    <= I_DATA;
					//31: byte_rate[31:24]    <= I_DATA;
					//32: block_align[7:0]    <= I_DATA;
					//33: block_align[15:8]   <= I_DATA;
					34: bits_per_sample[7:0]  <= I_DATA;
					35: bits_per_sample[15:8] <= I_DATA;
					40: data_size[7:0]        <= I_DATA;
					41: data_size[15:8]       <= I_DATA;
					42: data_size[23:16]      <= I_DATA;
					43: begin 
//							data_size[31:24] <= I_DATA;// AMR -  Applied too late
							//$display("num_channels %x %d\n",num_channels,num_channels);
							$display("sample_rate %x %d\n",sample_rate,sample_rate);
							//$display("byte_rate %x %d\n",byte_rate,byte_rate);
							//$display("block_align%x %d\n",block_align,block_align);
							$display("bits_per_sample %x %d\n",bits_per_sample,bits_per_sample);
							$display("data_size %x %d\n",data_size,data_size);
							$display("data_size %x %d\n",data_size,data_size);
							$display("data_size %x %d\n",data_size[15:0],data_size[15:0]);
							END_ADDR <= W_DMA_ADDR + data_size + {I_DATA,24'd0}; // AMR - Merge in MSB
							START_ADDR <= W_DMA_ADDR + 1'd1;
							inheader <= 0;
							O_READ <= 0;
							O_READNEXT <= 0;
							read_done <= 1;
							channel_toggle<=1'b0;
						end
				endcase
			end
			else if (bits_per_sample != 16) begin
				if(channel_toggle| !stereo)
					W_SAMPL_L     <= {I_DATA,I_DATA};
				if(!channel_toggle| !stereo)
					W_SAMPL_R     <= {I_DATA,I_DATA};
				read_done   <= 1;
			end
			else if (!W_DMA_ADDR[0]) begin
				W_SAMPL_LSB <= I_DATA;
				O_READNEXT  <= 1'b1;
			end
			else begin
				if(channel_toggle| !stereo)
					W_SAMPL_L     <= {I_DATA,W_SAMPL_LSB};
				if(!channel_toggle| !stereo)
					W_SAMPL_R     <= {I_DATA,W_SAMPL_LSB};
				read_done   <= 1;
			end
			
			W_DMA_ADDR <= W_DMA_ADDR + 1'd1;
		end

		if(read_done && ce_sample && playing) begin
			read_done <= 0;
			channel_toggle<=~channel_toggle;
			W_DMA_EN  <= ~(W_DMA_ADDR >= END_ADDR);
			if (W_DMA_ADDR >= END_ADDR && I_LOOP) begin
				W_DMA_EN   <= 1'b1;
				W_DMA_ADDR <= START_ADDR;
				O_READ <= 1'b1;
			end
			else
				O_READNEXT <= 1'b1;
		end
	end

	if(I_RST || !playing || !W_DMA_EN) begin
		W_SAMPL_L <= 0;
		W_SAMPL_R <= 0;
	end
end

assign O_ADDR = W_DMA_ADDR;

always @(posedge I_CLK) begin

	if(ce_sample) begin
		voldelay <= voldelay + 1;
   end
end

always @(posedge I_CLK) begin	
	if(&voldelay && ce_sample) begin
		if(I_PAUSE) begin
			if(volume[8:0]!=9'h0) begin
				volume<={volume[9:2],2'b00}-9'h4;
			end else begin
				playing <=1'b0;
			end
		end else begin
			playing <=1'b1;
			if(!volume[8]) begin
				volume<=volume+7'b1;
			end
		end
	end
	
	if(I_RST) begin
		volume <= 9'b0;
	end

	scaled_l <= W_SAMPL_L * volume;
	scaled_r <= W_SAMPL_R * volume;	
	
end

assign O_PCM_L  = scaled_l[24:9];
assign O_PCM_R  = scaled_r[24:9];

endmodule



module AY8912
(
   input        CLK,		   // Global clock
	input        CE,        // PSG Clock enable
   input        RESET,	   // Chip RESET (set all Registers to '0', active hi)
   input        BDIR,	   // Bus Direction (0 - read , 1 - write)
   input        BC,		   // Bus control
   input  [7:0] DI,	      // Data In
   output [7:0] DO,	      // Data Out
   output [7:0] CHANNEL_A, // PSG Output channel A
   output [7:0] CHANNEL_B, // PSG Output channel B
   output [7:0] CHANNEL_C, // PSG Output channel C
   input        SEL,
	input  [7:0] IO_in,
	output [7:0] IO_out
);

assign     IO_out = ymreg[14];

reg        ena_div;
reg        ena_div_noise;
reg [3:0]  addr;
reg [7:0]  ymreg[16];
reg        env_ena;
reg [4:0]  env_vol;

wire [7:0] volTableAy[16] = 
       '{8'h00, 8'h03, 8'h04, 8'h06, 
		   8'h0a, 8'h0f, 8'h15, 8'h22, 
		   8'h28, 8'h41, 8'h5b, 8'h72, 
		   8'h90, 8'hb5, 8'hd7, 8'hff
		 };


// Read from AY
assign DO = dout;
reg [7:0] dout;
always_comb begin
	case(addr)
		 0: dout = ymreg[0];
		 1: dout = {4'b0000, ymreg[1][3:0]};
		 2: dout = ymreg[2];
		 3: dout = {4'b0000, ymreg[3][3:0]};
		 4: dout = ymreg[4];
		 5: dout = {4'b0000, ymreg[5][3:0]};
		 6: dout = {3'b000,  ymreg[6][4:0]};
		 7: dout = ymreg[7];
		 8: dout = {3'b000,  ymreg[8][4:0]};
		 9: dout = {3'b000,  ymreg[9][4:0]};
		10: dout = {3'b000,  ymreg[10][4:0]};
		11: dout = ymreg[11];
		12: dout = ymreg[12];
		13: dout = {4'b0000, ymreg[13][3:0]};
		14: dout = (ymreg[7][6] ? ymreg[14] : IO_in);
		15: dout = (ymreg[7][7] ? ymreg[15] : IO_in);
	endcase
end

//  p_divider
always @(posedge CLK) begin
	reg [3:0]  cnt_div;
	reg        noise_div;

	if(CE) begin
		ena_div <= 0;
		ena_div_noise <= 0;
		if(!cnt_div) begin
			cnt_div <= {SEL, 3'b111};
			ena_div <= 1;
            
			noise_div <= (~noise_div);
			if (noise_div) ena_div_noise <= 1;
		end else begin
			cnt_div <= cnt_div - 1'b1;
		end
	end
end


reg [16:0] poly17;
wire [4:0] noise_gen_comp = ymreg[6][4:0] ? ymreg[6][4:0] - 1'd1 : 5'd0;

//  p_noise_gen
always @(posedge CLK) begin
	reg [4:0]  noise_gen_cnt;

	if(CE) begin
		if (ena_div_noise) begin
			if (noise_gen_cnt >= noise_gen_comp) begin
				noise_gen_cnt <= 0;
				poly17 <= {(poly17[0] ^ poly17[2] ^ !poly17), poly17[16:1]};
			end else begin
				noise_gen_cnt <= noise_gen_cnt + 1'd1;
			end
		end
	end
end

wire [11:0] tone_gen_freq[1:3];
assign tone_gen_freq[1] = {ymreg[1][3:0], ymreg[0]};
assign tone_gen_freq[2] = {ymreg[3][3:0], ymreg[2]};
assign tone_gen_freq[3] = {ymreg[5][3:0], ymreg[4]};

wire [11:0] tone_gen_comp[1:3];
assign tone_gen_comp[1] = tone_gen_freq[1] ? tone_gen_freq[1] - 1'd1 : 12'd0;
assign tone_gen_comp[2] = tone_gen_freq[2] ? tone_gen_freq[2] - 1'd1 : 12'd0;
assign tone_gen_comp[3] = tone_gen_freq[3] ? tone_gen_freq[3] - 1'd1 : 12'd0;

reg [3:1] tone_gen_op;

//p_tone_gens
always @(posedge CLK) begin
	integer i;
	reg [11:0] tone_gen_cnt[1:3];

	if(CE) begin
		// looks like real chips count up - we need to get the Exact behaviour ..
	
		for (i = 1; i <= 3; i = i + 1) begin
			if(ena_div) begin
				if (tone_gen_cnt[i] >= tone_gen_comp[i]) begin
					tone_gen_cnt[i] <= 0;
					tone_gen_op[i]  <= (~tone_gen_op[i]);
				end else begin
					tone_gen_cnt[i] <= tone_gen_cnt[i] + 1'd1;
				end
			end
		end
	end
end

wire [15:0] env_gen_comp = {ymreg[12], ymreg[11]} ? {ymreg[12], ymreg[11]} - 1'd1 : 16'd0;

//p_envelope_freq
always @(posedge CLK) begin
	reg [15:0] env_gen_cnt;

	if(CE) begin
		env_ena <= 0;
		if(ena_div) begin
			if (env_gen_cnt >= env_gen_comp) begin
				env_gen_cnt <= 0;
				env_ena <= 1;
			end else begin
				env_gen_cnt <= (env_gen_cnt + 1'd1);
			end
		end
	end
end

wire is_bot    = (env_vol == 5'b00000);
wire is_bot_p1 = (env_vol == 5'b00001);
wire is_top_m1 = (env_vol == 5'b11110);
wire is_top    = (env_vol == 5'b11111);

always @(posedge CLK) begin
	reg old_BDIR;
	reg env_reset;
	reg env_hold;
	reg env_inc;

	// envelope shapes
	// C AtAlH
	// 0 0 x x  \___
	//
	// 0 1 x x  /___
	//
	// 1 0 0 0  \\\\
	//
	// 1 0 0 1  \___
	//
	// 1 0 1 0  \/\/
	//           ___
	// 1 0 1 1  \
	//
	// 1 1 0 0  ////
	//           ___
	// 1 1 0 1  /
	//
	// 1 1 1 0  /\/\
	//
	// 1 1 1 1  /___

	if(RESET) begin
		ymreg[0]  <= 0;
		ymreg[1]  <= 0;
		ymreg[2]  <= 0;
		ymreg[3]  <= 0;
		ymreg[4]  <= 0;
		ymreg[5]  <= 0;
		ymreg[6]  <= 0;
		ymreg[7]  <= 255;
		ymreg[8]  <= 0;
		ymreg[9]  <= 0;
		ymreg[10] <= 0;
		ymreg[11] <= 0;
		ymreg[12] <= 0;
		ymreg[13] <= 0;
		ymreg[14] <= 0;
		ymreg[15] <= 0;
		addr      <= 0;
		env_vol   <= 0;
	end else begin
		old_BDIR <= BDIR;
		if(~old_BDIR & BDIR) begin
			if(BC) addr <= DI[3:0];
			else begin 
				ymreg[addr] <= DI;
				env_reset <= (addr == 13);
			end
		end
	end

	if(CE) begin
		if(env_reset) begin
			env_reset <= 0;
			// load initial state
			if(!ymreg[13][2]) begin		// attack
				env_vol <= 5'b11111;
				env_inc <= 0;		// -1
			end else begin
				env_vol <= 5'b00000;
				env_inc <= 1;		// +1
			end
			env_hold <= 0;
		end else begin

			if (env_ena) begin
				if (!env_hold) begin
					if (env_inc) env_vol <= (env_vol + 5'b00001);
						else env_vol <= (env_vol + 5'b11111);
				end

				// envelope shape control.
				if(!ymreg[13][3]) begin
					if(!env_inc) begin	// down
						if(is_bot_p1) env_hold <= 1;
					end else if (is_top) env_hold <= 1;
				end else if(ymreg[13][0]) begin		// hold = 1
					if(!env_inc) begin	// down
						if(ymreg[13][1]) begin		// alt
							if(is_bot) env_hold <= 1;
						end else if(is_bot_p1) env_hold <= 1;
					end else if(ymreg[13][1]) begin	// alt
						if(is_top) env_hold <= 1;
					end else if(is_top_m1) env_hold <= 1;
				end else if(ymreg[13][1]) begin		// alternate
					if(env_inc == 1'b0) begin		// down
						if(is_bot_p1) env_hold <= 1;
						if(is_bot) begin
							env_hold <= 0;
							env_inc  <= 1;
						end
					end else begin
						if(is_top_m1) env_hold <= 1;
						if(is_top) begin
							env_hold <= 0;
							env_inc  <= 0;
						end
					end
				end
			end
		end
	end
end

wire [4:0] A = ~((ymreg[7][0] | tone_gen_op[1]) & (ymreg[7][3] | poly17[0])) ? 5'd0 : ymreg[8][4]  ? env_vol[4:0] : { ymreg[8][3:0],  ymreg[8][3]};
wire [4:0] B = ~((ymreg[7][1] | tone_gen_op[2]) & (ymreg[7][4] | poly17[0])) ? 5'd0 : ymreg[9][4]  ? env_vol[4:0] : { ymreg[9][3:0],  ymreg[9][3]};
wire [4:0] C = ~((ymreg[7][2] | tone_gen_op[3]) & (ymreg[7][5] | poly17[0])) ? 5'd0 : ymreg[10][4] ? env_vol[4:0] : {ymreg[10][3:0], ymreg[10][3]};

assign CHANNEL_A = volTableAy[A[4:1]];
assign CHANNEL_B = volTableAy[B[4:1]];
assign CHANNEL_C = volTableAy[C[4:1]];


endmodule

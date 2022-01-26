// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.


module M6532
(
	input        clk,       // PHI 2
	input        ce,        // Clock enable
	input        res_n,     // reset
	input  [6:0] addr,      // Address
	input        RW_n,      // 1 = read, 0 = write
	input  [7:0] d_in,
	output [7:0] d_out,
	input        RS_n,      // RAM select
	output       IRQ_n,
	input        CS1,       // Chip select 1, 1 = selected
	input        CS2_n,     // Chip select 2, 0 = selected
	input  [7:0] PA_in,
	output [7:0] PA_out,
	input  [7:0] PB_in,
	output [7:0] PB_out,
	output       oe         // Output enabled (always 8 bits)
);

parameter init_7800 = 0;

reg [7:0] riot_ram[128];
reg [7:0] out_a, out_b, data;
reg [7:0] dir_a, dir_b;
reg [7:0] interrupt;
reg [7:0] timer;
reg [9:0] prescaler;

reg [1:0] incr;
logic rollover;
reg [1:0] irq_en;
reg edge_detect;

assign IRQ_n = ~((interrupt[7] & irq_en[1]) | (interrupt[6] & irq_en[0]));

// These wires have a weak pull up, so any undriven wires will be high
assign PA_out = out_a;
assign PB_out = out_b;

assign oe = (CS1 & ~CS2_n) && RW_n;
always_ff @(posedge clk) begin
	if ((CS1 & ~CS2_n) && RW_n) begin
		if (~RS_n) begin // RAM selected
			d_out <= riot_ram[addr];
		end else if (~addr[2]) begin // Address registers
			case(addr[1:0])
				2'b01: d_out <= dir_a; // DDRA
				2'b11: d_out <= dir_b; // DDRB
				2'b00: d_out <= (out_a & dir_a) | (PA_in & ~dir_a); // Input A
				2'b10: d_out <= out_b; // Input B
			endcase
		end else if (addr[2])begin // Timer & Interrupts
			if (~addr[0])
				d_out <= timer[7:0];
			else
				d_out <= {interrupt[7:6], 6'd0};
		end
	end
	if (~res_n)
		d_out <= 8'hFF;
end

wire pa7 = dir_a[7] ? PA_out[7] : PA_in[7];
wire p1 = incr == 2'd0 || rollover;
wire p8 = ~|prescaler[2:0] && incr == 2'd1;
wire p64 = ~|prescaler[5:0] && incr == 2'd2;
wire p1024 = ~|prescaler[9:0] && incr == 2'd3;
wire tick_inc = p1 || p8 || p64 || p1024;

always_ff @(posedge clk) if (~res_n) begin
	// Set to specific value on atari 7800 version, 0 on MOS version
	if (init_7800)
		riot_ram <= '{
			8'hA9, 8'h00, 8'hAA, 8'h85, 8'h01, 8'h95, 8'h03, 8'hE8, 8'hE0, 8'h2A, 8'hD0, 8'hF9, 8'h85, 8'h02, 8'hA9, 8'h04,
			8'hEA, 8'h30, 8'h23, 8'hA2, 8'h04, 8'hCA, 8'h10, 8'hFD, 8'h9A, 8'h8D, 8'h10, 8'h01, 8'h20, 8'hCB, 8'h04, 8'h20,
			8'hCB, 8'h04, 8'h85, 8'h11, 8'h85, 8'h1B, 8'h85, 8'h1C, 8'h85, 8'h0F, 8'hEA, 8'h85, 8'h02, 8'hA9, 8'h00, 8'hEA,
			8'h30, 8'h04, 8'h24, 8'h03, 8'h30, 8'h09, 8'hA9, 8'h02, 8'h85, 8'h09, 8'h8D, 8'h12, 8'hF1, 8'hD0, 8'h1E, 8'h24,
			8'h02, 8'h30, 8'h0C, 8'hA9, 8'h02, 8'h85, 8'h06, 8'h8D, 8'h18, 8'hF1, 8'h8D, 8'h60, 8'hF4, 8'hD0, 8'h0E, 8'h85,
			8'h2C, 8'hA9, 8'h08, 8'h85, 8'h1B, 8'h20, 8'hCB, 8'h04, 8'hEA, 8'h24, 8'h02, 8'h30, 8'hD9, 8'hA9, 8'hFD, 8'h85,
			8'h08, 8'h6C, 8'hFC, 8'hFF, 8'hEA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
			8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF
		};
	else
		riot_ram <= '{128{8'h00}};

	out_a <= 8'hFF;
	out_b <= 8'hFF;
	dir_a <= 8'h00;
	dir_b <= 8'h00;
	{interrupt, irq_en, edge_detect} <= '0;
	incr <= 2'b10; // Increment resets to 64
	timer <= 8'hFF;   // Timer resets to FF
	prescaler <= 0;
	rollover <= 0;
end else begin
	
	if (ce) begin : riot_stuff
		reg old_pa7;
	
		prescaler <= prescaler + 1'd1;
	
		if (tick_inc)
			timer <= timer - 8'd1;
	
		// FIXME: Port A is set such so that it can drive SNAC port output (open drain)
		out_a <= (out_a & dir_a) | (8'hFF & ~dir_a);
		out_b <= (out_b & dir_b) | (PB_in & ~dir_b);
	
		if (CS1 & ~CS2_n) begin
			if (~RS_n) begin // RAM selected
				if (~RW_n)
					riot_ram[addr] <= d_in;
			end else if (~addr[2]) begin // Address registers
				if (~RW_n) begin
					case(addr[1:0])
						2'b01: dir_a <= d_in; // DDRA
						2'b11: dir_b <= d_in; // DDRB
						2'b00: out_a <= (d_in & dir_a) | (8'hFF & ~dir_a); // Output A
						2'b10: out_b <= (d_in & dir_b) | (PB_in & ~dir_b); // Output B
					endcase
				end
			end else begin // Timer & Interrupts
				if (~RW_n) begin
					if (addr[4])begin
						prescaler <= 10'd0;
						rollover <= 0;
						interrupt[7] <= 0;
						incr <= addr[1:0];
						timer <= d_in;
						irq_en[1] <= addr[3];
					end else begin
						irq_en[0] <= addr[1];
						edge_detect <= addr[0];
					end
				end else begin
					if (~addr[0]) begin
						irq_en[1] <= addr[3];
						rollover <= 0;
						interrupt[7] <= 0;
					end else
						interrupt[6] <= 0;
				end
			end
		end
	
		if (tick_inc && timer == 0) begin
			interrupt[7] <= 1;
			rollover <= 1;
		end
	
		// Edge detection
		old_pa7 <= pa7;
		if ((edge_detect && ~old_pa7 && pa7) || (~edge_detect && old_pa7 && ~pa7))
			interrupt[6] <= 1;
	end
end

endmodule
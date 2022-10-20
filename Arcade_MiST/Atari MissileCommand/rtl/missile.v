/*============================================================================
	Missile Command for MiSTer FPGA - Main core

	Copyright (C) 2022 - Jim Gregory - https://github.com/JimmyStones/

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/

`timescale 1 ps / 1 ps
`default_nettype none

module missile(
	input				clk_10M,
	input				ce_5M,
	input				reset,
	input				pause,
	
	input				vtb_dir1,
	input				vtb_clk1,
	input				htb_dir1,
	input				htb_clk1,

	input				vtb_dir2,
	input				vtb_clk2,
	input				htb_dir2,
	input				htb_clk2,
	
	input 				coin,
	input				p1_start,
	input				p2_start,

	input				p1_fire_l,
	input				p1_fire_c,
	input				p1_fire_r,
	input				p2_fire_l,
	input				p2_fire_c,
	input				p2_fire_r,

	input		 [7:0]	in2,
	input		 [7:0]	switches,

	input				self_test,
	input				slam,

	output				flip,

	output		 	r,
	output		 	g,
	output		 	b,

	output				h_sync/*verilator public_flat*/,
	output				v_sync/*verilator public_flat*/,
	output				h_blank/*verilator public_flat*/,
	output				v_blank/*verilator public_flat*/,
	
	output		 [5:0]	audio_o,
	
	input		[15:0]	dn_addr,
	input		 [7:0]	dn_data,
	input				dn_wr,

	
	input		[13:0]	hs_address,
	input		 [7:0]	hs_data_in,
	output		 [7:0]	hs_data_out,	
	input				hs_write,
	input				hs_access
);



//// SHARED SIGNALS

wire [8:0]		hcnt;
wire [7:0]		vcnt;
wire			sync;
wire			s_phi_0;
wire			s_phi_2;
wire			s_phi_x;
reg				s_phi_extend = 1'b0;
wire			s_3INH;
wire			s_irq_n;
wire			s_READWRITE;
wire			s_WRITE_n;
wire			s_br_w_n;
wire [15:0]		s_addr /* synthesis preserve */;
wire [7:0]		s_pgrom0_out/* synthesis preserve */;
wire [7:0]		s_pgrom1_out/* synthesis preserve */;
wire [7:0]		s_pgrom2_out/* synthesis preserve */;
wire [7:0]		s_db_in/* synthesis preserve */;
wire [7:0]		s_db_out/* synthesis preserve */;
wire [7:0]		s_pokey_out/* synthesis preserve */;
wire			s_16FLIP;
wire			s_INTACK_n;
reg				s_MADSEL = 1'b0;
reg				s_MADSELDEL = 1'b0;
reg				s_MUSHROOM = 1'b0;
wire [2:0]		s_PROGSEL_n;
wire			s_RAM_n;
wire			s_POKEY_n;
wire			s_NIO_n;
wire			s_WDOG_n;
wire			s_COLRAM_n;
wire			s_OUT_n;

////////////////////////
///// SYNC CIRCUIT /////
////////////////////////

sync sync_circuit(
	.clk_10M(clk_10M),
	.ce_5M(ce_5M),
	.reset(reset),
	.flip(s_FLIP),
	.h_blank(h_blank),
	.h_sync(h_sync),
	.v_blank(v_blank),
	.v_sync(v_sync),
	.s_phi_x(s_phi_x),
	.s_3INH(s_3INH),
	.hcnt(hcnt),
	.vcnt(vcnt)
);


//////////////////////////////////
///// MICROPROCESSOR CIRCUIT /////
//////////////////////////////////

micro mp(
	.clk_10M(clk_10M),
	.s_phi_x(s_phi_x),
	.s_phi_extend(s_phi_extend),
	.reset(reset),
	.pause(pause),
	.flip(s_FLIP),
	.hcnt(hcnt),
	.vcnt(vcnt),
	.s_db_in(s_db_in),
	.sync(sync),
	.s_phi_2(s_phi_2),
	.s_phi_0(s_phi_0),
	.s_irq_n(s_irq_n), 
	.s_READWRITE(s_READWRITE), 
	.s_WRITE_n(s_WRITE_n), 
	.s_br_w_n(s_br_w_n), 
	.s_16FLIP(s_16FLIP), 
	.s_INTACK_n(s_INTACK_n),
	.s_addr(s_addr),
	.s_db_out(s_db_out)
);


///////////////////////////////
///// ADDRESS DECODING ////////
// Page 1, Side B, Top right //
///////////////////////////////

wire [9:0]	s_N2;
wire 		s_N3;

// N2 - 7442 address decoder
// -------------------------
ls42 N2 (
	.a(s_addr[12]),
	.b(s_addr[13]),
	.c(s_addr[14]),
	.d(s_MADSELDEL),
	.o(s_N2)
);

assign s_PROGSEL_n = s_N2[7:5];
assign s_N3 = s_N2[1] & s_N2[2] & s_N2[3];
assign s_RAM_n = s_N3 & s_N2[0];
assign s_POKEY_n = s_addr[11] | s_N2[4];
assign s_NIO_n = (~s_addr[11]) | s_N2[4];

// E8 - 7442 address decoder
// ----------------------------------
wire s_mem_write = ~(s_WRITE_n | s_NIO_n);
assign s_OUT_n = ~(s_mem_write && s_addr[15:8] == 8'b01001000);
assign s_COLRAM_n = ~(s_mem_write && s_addr[15:8] == 8'b01001011);
assign s_WDOG_n = ~(s_mem_write && (s_addr == 16'h4C00));
assign s_INTACK_n = ~(s_mem_write && (s_addr == 16'h4D00));

// ROM upload enables
// ----------------------------------
wire		dn_pgrom0_we = (dn_addr[13:12] == 2'b00) & dn_wr;
wire		dn_pgrom1_we = (dn_addr[13:12] == 2'b01) & dn_wr;
wire		dn_pgrom2_we = (dn_addr[13:12] == 2'b10) & dn_wr;
wire		dn_L6_prom_we = (dn_addr[15:12] == 4'b0011) & dn_wr;
wire [4:0]	dn_L6_prom_addr = dn_addr[4:0];

// Simplified address decodes for inputs
// ----------------------------------
// IN0 $4800-$48FF
wire in0_cs = s_addr[14:8] == 7'b1001000;
// IN1 $4900-$49FF
wire in1_cs = s_addr[14:8] == 7'b1001001;
// IN2 $4A00-$4AFF
wire in2_cs = s_addr[14:8] == 7'b1001010;

assign s_db_in = ~s_PROGSEL_n[0] ? s_pgrom0_out :
				~s_PROGSEL_n[1] ? s_pgrom1_out :
				~s_PROGSEL_n[2] ? s_pgrom2_out :
				s_MADSEL ? s_VRAM_in :
				~s_POKEY_n ? s_pokey_out :
				~s_RAM_n ? vram_data_out :
				in0_cs ? in0 :
				in1_cs ? in1 :
				in2_cs ? in2 :
				~s_COLRAM_n ? { 4'b0, s_cram_out} :
				8'bXXXXXXXX;

localparam debug_counter_width = 20;

reg [debug_counter_width-1:0] debug_counter = {debug_counter_width{1'b0}};
wire debug_data/*verilator public_flat*/;


//////////////////////////////////
///// PROGRAM MEMORY CIRCUIT /////
//////////////////////////////////

dpram #(12,8) pgrom0
(
	.clock(clk_10M),

	.enable_a(dn_pgrom0_we),
	.wren_a(dn_pgrom0_we),
	.address_a(dn_addr[11:0]),
	.data_a(dn_data),
	.q_a(),

	.enable_b(1'b1),
	.wren_b(1'b0),
	.address_b(s_addr[11:0]),
	.data_b(),
	.q_b(s_pgrom0_out)
);

dpram #(12,8) pgrom1
(
	.clock(clk_10M),

	.enable_a(dn_pgrom1_we),
	.wren_a(dn_pgrom1_we),
	.address_a(dn_addr[11:0]),
	.data_a(dn_data),
	.q_a(),

	.enable_b(1'b1),
	.wren_b(1'b0),
	.address_b(s_addr[11:0]),
	.data_b(),
	.q_b(s_pgrom1_out)
);

dpram #(12,8) pgrom2
(
	.clock(clk_10M),

	.enable_a(dn_pgrom2_we),
	.wren_a(dn_pgrom2_we),
	.address_a(dn_addr[11:0]),
	.data_a(dn_data),
	.q_a(),

	.enable_b(1'b1),
	.wren_b(1'b0),
	.address_b(s_addr[11:0]),
	.data_b(),
	.q_b(s_pgrom2_out)
);

////////////////
///// DRAM /////
////////////////

wire [7:0]	s_VRAM;
reg  [7:0]	s_VRAM_in = 8'b0;
wire [13:0]	vram_addr = hs_access ? hs_address : dead_cpu;
wire [7:0]	vram_we_n = hs_access ? ~{8{hs_write}} : s_WP_n;
wire [7:0]	vram_data_in = hs_access ? hs_data_in : s_MD;
wire [7:0]	vram_data_out;

assign hs_data_out = vram_data_out;

dpvram #(14,8) ram
(
	.clock_a(clk_10M),
	.wren_a(vram_we_n),
	.address_a(vram_addr),
	.data_a(vram_data_in),
	.q_a(vram_data_out),

	.clock_b(clk_10M),
	.address_b(dead_vid),
	.q_b(s_VRAM)
);

///////////////////////////////
//// DRAM ADDRESS SELECTOR ////
// Page 2, Side A, Top left ///
///////////////////////////////

// When an instruction matching the bit pattern xxx00001 syncs and no IRQ is underway, start the MADSEL countdown
// - This should send MADSEL high ready for the read/write 5 cycles later
reg		[3:0] MADSEL_count = 4'b0;
always @(posedge s_phi_0)
begin
	if(s_db_in[4:0] == 5'b00001 && s_irq_n && sync) MADSEL_count <= 4'd3;
	
	if(MADSEL_count > 4'd0)
	begin
		MADSEL_count <= MADSEL_count - 4'b1;
		if(MADSEL_count == 4'd1) s_MADSEL <= 1'b1;
	end
	else
		s_MADSEL <= 1'b0;
end

///////////////////////////////
/// 3RD COLOUR BIT SELECTOR ///
/// Page 2, Side A, Top mid  //
///////////////////////////////

// Latch PHI EXTEND signal when MADSEL active and 3rd colour bit area is addressed
always @(posedge clk_10M)
begin
	if(s_phi_x)
	begin
		if(s_MADSEL & s_addr[15:13] == 3'b111) s_phi_extend <= 1'b1;
	end
	else
	begin
		s_phi_extend <= 1'b0;
	end
end

// Latch PHI EXTEND into MUSHROOM on next falling edge of PHI X
always @(negedge clk_10M)
begin
	reg s_phi_x_last;
	s_phi_x_last <= s_phi_x;
	if(!s_phi_x && s_phi_x_last) s_MUSHROOM <= s_phi_extend;
end

////////////////////////////////
// DRAM PICTURE OUTPUT ENABLE //
// Page 2, Side A, Top right ///
////////////////////////////////
always @(posedge clk_10M)
begin
	reg ce_5M_last;
	ce_5M_last <= ce_5M;
	if(ce_5M && !ce_5M_last) s_MADSELDEL <= s_MADSEL;
end

////////////////////////////////
// DRAM ADDRESS CONTROLLER /////
// Page 2, Side A, Lower left //
////////////////////////////////

wire [1:0]	s_MADSEL_mode = {s_MUSHROOM, s_MADSEL};

wire [13:0]	dead_cpu_2col = s_addr[15:2];
wire [13:0] dead_cpu_3col = { 3'b0, s_addr[11], ~s_addr[11], s_addr[10:3], s_addr[12] };
wire [13:0]	dead_cpu = 	s_MADSEL_mode == 2'b00 ? s_addr[13:0] :  // Standard RAM addressing
						s_MADSEL_mode == 2'b01 ? dead_cpu_2col : // 2 colour VRAM addressing
						s_MADSEL_mode == 2'b11 ? dead_cpu_3col : // 3 colour VRAM addressing
						14'h00;
reg  [13:0]	dead_vid = 14'b0;

reg s_phi_0_last = 1'b0;
always @(posedge clk_10M)
begin
	s_phi_0_last <= s_phi_0;

	// CPU only reads VRAM data when MADSEL is high
	if(s_MADSEL)
	begin
		if(s_MUSHROOM)
		begin
			// Latch 3rd colour bit data from VRAM when MUSHROOM is high (last 32 lines)
			s_VRAM_in[5] <= vram_data_out[s_addr[2:0]];
		end
		else
		begin
			if(ce_5M)
			begin
				// Latch 2 colour bits from VRAM when MUSHROOM is low
				s_VRAM_in[7] <= vram_data_out[s_addr[1:0]+4];
				s_VRAM_in[6] <= vram_data_out[s_addr[1:0]+0];
			end
		end
	end	
	else
	begin
		// Clear VRAM data when MADSEL is low
		if(s_phi_0 && !s_phi_0_last) s_VRAM_in <= 8'hFF;
	end
end


// L6 PROM (DRAM write mask)
wire	[7:0]	s_L6;
//dpram #(5,8) L6
//(
//	// a - download from HPS
//	.clock(clk_10M),
//
//	.enable_a(dn_L6_prom_we),
//	.wren_a(dn_L6_prom_we),
//	.address_a(dn_L6_prom_addr),
//	.data_a(dn_data),
//	.q_a(),
//	
//	.enable_b(1'b1),
//	.address_b({s_MADSEL, s_MUSHROOM, s_addr[2:0]}),
//	.data_b(),
//	.wren_b(),
//	.q_b(s_L6)
//);

L6 L6(
	.clk(clk_10M),
	.addr({s_MADSEL, s_MUSHROOM, s_addr[2:0]}),
	.data(s_L6)
);

wire		s_MADSEL_write = (s_MADSEL & ~s_br_w_n & hcnt[0]);
wire		s_RAM_write = (~s_RAM_n & ~s_br_w_n);
wire [7:0]	s_WP_n = ~(s_MADSEL ? (s_MADSEL_write ? ~s_L6 : 8'h00) : s_RAM_write ? 8'hFF : 8'h00);

// DRAM DATA INPUT SELECTOR
reg	[7:0]	s_MD = 8'b0;
always @(posedge clk_10M)
begin
	case ({s_MUSHROOM, s_MADSEL})
		2'b00 : s_MD = s_db_out[7:0];
		2'b01 : s_MD = {{4{s_db_out[7]}}, {4{s_db_out[6]}}};
		2'b11 : s_MD = {8{s_db_out[5]}};
		default : s_MD = 8'b0;
	endcase
end

/// PICTURE BIT CONVERTER
wire [2:0]	s_COLNUM;
reg [3:0]	s_N7 = 4'b0;
reg [3:0]	s_M6 = 4'b0; 
reg [7:0]	s_P6 = 8'b0;

// This part diverges from the original schematics quite a bit.  
// We need to offset the lookups to give the BRAM enough time to return colour index data then look it up in the paletta RAM
// I'm sure this could be better but I'm scared to touch it because it works!
wire [8:0]	hcnt_off_2col = h_blank ? (hcnt + 8'd192) : hcnt + 8'd4;
wire [8:0]	hcnt_off_3col = h_blank ? (hcnt + 8'd192) : hcnt + 8'd8;
wire [8:0]	hcnt_address_2col = h_blank ? ((hcnt == 9'd319) ? 9'd4 : 9'd0): (hcnt + 8'd4);
wire [8:0]	hcnt_address_3col = h_blank ? ((hcnt == 9'd319) ? 9'd4 : 9'd0): (hcnt + 8'd2);

reg [7:0]	vram_2col = 8'b0;
wire [1:0]	pixel_index_2col = hcnt_off_2col[1:0];
wire [2:0]	pixel_index_3col = hcnt_off_3col[2:0];

always @(posedge clk_10M)
begin
	//$display("%d)\tVID: ce5=%b hcnt=%d hco2=%d hco3=%d pi2=%d pi3=%d vcnt=%d hb=%b vb=%b dead_vid=%x colnum=%x", debug_counter, ce_5M, hcnt, hcnt_off_2col, hcnt_off_3col, pixel_index_2col, pixel_index_3col, vcnt, h_blank, v_blank, dead_vid, s_COLNUM);
	
	// 2 Colour bits
	// - Set read address 3 10Mhz cycles before ce_5M goes high
	// - Latch data 2 10Mhz cycles before ce_5M goes high
	// - Select 2 bit colour index 1 10Mhz cycle before ce_5M goes high
	// - Shift data right every 5Mhz cycle except load cycle

	// 1st 2 colour bits

	// Set address to read 2 colour bits data from VRAM
	if(pixel_index_2col == 2'd2 && ce_5M) dead_vid <= {vcnt[7:0], hcnt_address_2col[7:2]};

	// Latch 3rd colour bit data from VRAM
	if(pixel_index_2col == 2'd3 && ~ce_5M) vram_2col <= s_VRAM;

	// Load 2 colour bits data from latch
	if(pixel_index_2col == 2'd3 && ce_5M)
	begin
		s_N7 <= vram_2col[7:4];
		s_M6 <= vram_2col[3:0];
	end

	// Shift 2 colour bits data along
	if(pixel_index_2col != 2'd3 && ce_5M)
	begin
		s_N7 <= s_N7 >> 1;
		s_M6 <= s_M6 >> 1;
	end

	// 3rd colour bit
	if(~s_3INH)
	begin
		// Clear 3rd colour bit if we are outside the last 32 lines
		s_P6 <= 8'h00;
	end
	else
	begin

		// Set address to read 3rd colour bit data from VRAM
		if(pixel_index_3col == 3'd7 && ~ce_5M) dead_vid <= { 3'b0, vcnt[3], ~vcnt[3], vcnt[2:0], hcnt_address_3col[7:3], vcnt[4] };

		// Load 3rd colour bit data from VRAM
		if(pixel_index_3col == 3'd7 && ce_5M) s_P6 <= s_VRAM;

		// Shift 3rd colour bit data along
		if(pixel_index_3col != 3'd7 && ce_5M) s_P6 <= s_P6 >> 1; 
	end
end

assign s_COLNUM = {s_N7[0],s_M6[0],s_P6[0]};

reg	[2:0]	rgbtemp = 0;
assign r = rgbtemp[2];
assign g = rgbtemp[1];
assign b = rgbtemp[0];

/// COLOR RAM
wire [2:0]	s_M7 = ~v_blank ? s_COLNUM[2:0] : s_addr[2:0];
wire [3:0]	s_cram_out;
wire 		s_cram_we = ~s_COLRAM_n && v_blank;

spram #(3,4) L7 (
	.clock(clk_10M),
	.address(s_M7[2:0]),
	.data(s_MD[3:0]),
	.wren(s_cram_we),
	.q(s_cram_out)
);

// Latch RGB out from colour ram
always @(posedge clk_10M) 
begin
	if(ce_5M) rgbtemp <= (~h_blank && ~v_blank) ? ~s_cram_out[3:1] : 3'b0;
end

// POKEY
wire s_J7 = s_phi_2 | hcnt[1];

wire [3:0] pokey_ch0, pokey_ch1, pokey_ch2, pokey_ch3; 
pokey pokey(
	.clk(s_J7),
	.enable_179(1'b1),
	.addr(s_addr[3:0]),
	.data_in(s_db_out),
	.wr_en(~s_br_w_n & ~s_POKEY_n),
	.reset_n(~reset),
	.data_out(s_pokey_out),
	.pot_in(switches),
	.channel_0_out(pokey_ch0),
	.channel_1_out(pokey_ch1),
	.channel_2_out(pokey_ch2),
	.channel_3_out(pokey_ch3)
);
assign audio_o = ({1'b0,pokey_ch0,1'b0}+{1'b0,pokey_ch1,1'b0})+({1'b0,pokey_ch2,1'b0}+{1'b0,pokey_ch3,1'b0});


// Outputs
// -------
reg [7:0] s_F9 = 8'b0;
always @(posedge s_OUT_n or posedge reset)			// F9 latch
begin
	s_F9 <= reset ? 8'b0 : s_db_out;
end

//wire s_FLIP = s_F9[6];
wire s_FLIP = 1'b1;
wire s_CTRLD_n = s_F9[0];
assign flip = s_FLIP;

// Inputs
// ------
wire [7:0] in0 = !s_CTRLD_n ? { ~coin, 2'b11, ~p1_start, ~p2_start, ~p2_fire_l, ~p2_fire_c, ~p2_fire_r } : {tb_count_v, tb_count_h};
wire [7:0] in1 = { v_blank, ~self_test, ~slam, 1'b1, 1'b1, ~p1_fire_l, ~p1_fire_c, ~p1_fire_r };

wire tb_dir_v, tb_clk_v, tb_dir_h, tb_clk_h;
reg [3:0] tb_count_v;
reg [3:0] tb_count_h;

assign {tb_dir_v, tb_clk_v, tb_dir_h, tb_clk_h} = { vtb_dir1, vtb_clk1, htb_dir1, htb_clk1 };
// assign {tb_dir_v, tb_clk_v, tb_dir_h, tb_clk_h} = (flip_n == 0) ? { vtb_dir1, vtb_clk1, htb_dir1, htb_clk1 } :
// 	{ vtb_dir2, vtb_clk2, htb_dir2, htb_clk2 };

always @(posedge clk_10M)
begin
	reg tb_clk_v_last;
	reg tb_clk_h_last;
	tb_clk_v_last <= tb_clk_v;
	tb_clk_h_last <= tb_clk_h;

	if (s_CTRLD_n)
	begin
		if(tb_clk_v && !tb_clk_v_last)
		begin
			if (!tb_dir_v)
				tb_count_v <= tb_count_v + 4'b1;
			else
				tb_count_v <= tb_count_v - 4'b1;
		end

		if(tb_clk_h && !tb_clk_h_last)
		begin
			if (!tb_dir_h)
				tb_count_h <= tb_count_h + 4'b1;
			else
				tb_count_h <= tb_count_h - 4'b1;
		end
	end
end


endmodule

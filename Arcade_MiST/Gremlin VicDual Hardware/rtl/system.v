/*============================================================================
	VIC arcade hardware by Gremlin Industries for MiSTer - Main system

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-02-20

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

module system (
	input clk,
	input clk_sfx,
	input reset /*verilator public_flat*/,
	input [4:0] game_mode,
	input pause,
	input coin,
	input dual_game_toggle,
	input [7:0] in_p1,
	input [7:0] in_p2,
	input [7:0] in_p3,
	input [7:0] in_p4,
	output reg ce_pix,
	output [23:0] rgb,
	output vsync,
	output hsync,
	output vblank,
	output hblank,

	output signed [15:0] audio,

	input [23:0] dn_addr,
	input [7:0]  dn_index,
	input 		 dn_download,
	input 		 dn_wr,
	input [7:0]  dn_data,

	output [24:0] sdram_addr,
	output		  sdram_rd,
	input         sdram_ack,
	input  [7:0]  sdram_dout,

	input		[11:0]	hs_address,
	input		 [7:0]	hs_data_in,
	output		 [7:0]	hs_data_out,	
	input				hs_write_enable
);

// Game metadata
//`include "games.v"

// Program ROM
// ------------
// - Original systems used multiple 1k or 2k ROMs - this has been flattened to a single ROM area in BRAM

// Program ROM data out
wire [7:0] pgrom_data_out;

// Program ROM download write enable
wire pgrom_wr = dn_addr[15] == 0 && dn_index == 8'd0 && dn_wr;

// Program ROM
dpram #(15,8) pgrom
(
	.clock_a(clk),
	.address_a(config_largerom ? cpu_addr[14:0] : { 1'b0, cpu_addr[13:0]}),
	.enable_a(1'b1),
	.wren_a(1'b0),
	.data_a(),
	.q_a(pgrom_data_out),

	.clock_b(clk),
	.address_b(dn_addr[14:0]),
	.enable_b(pgrom_wr),
	.wren_b(pgrom_wr),
	.data_b(dn_data),
	.q_b()
);

// U66-U65 - Timing PROMs
// --------------------
// Each ROM is 32 x 8 bits.
// prom1 = U66		0x1C20 > 0x1C3F
// prom2 = U65		0x1C40 > 0x1C5F

// PROM data outs
wire [7:0] prom1_data_out;
wire [7:0] prom2_data_out;

// PROM download write enables
wire prom1_wr = dn_addr[15:5] == 11'b10000000001 && dn_index == 8'd0 && dn_wr;
wire prom2_wr = dn_addr[15:5] == 11'b10000000010 && dn_index == 8'd0 && dn_wr;

// PROM read addresses
wire [4:0] prom_addr;

// Control PROM - U66
dpram #(5,8) prom1
(
	.clock_a(clk),
	.address_a(prom_addr),
	.enable_a(1'b1),
	.wren_a(1'b0),
	.data_a(),
	.q_a(prom1_data_out),

	.clock_b(clk),
	.address_b(dn_addr[4:0]),
	.enable_b(prom1_wr),
	.wren_b(prom1_wr),
	.data_b(dn_data),
	.q_b()
);
// Sequence PROM - U65
dpram #(5,8) prom2
(
	.clock_a(clk),
	.address_a(prom_addr),
	.enable_a(1'b1),
	.wren_a(1'b0),
	.data_a(),
	.q_a(prom2_data_out),

	.clock_b(clk),
	.address_b(dn_addr[4:0]),
	.enable_b(prom2_wr),
	.wren_b(prom2_wr),
	.data_b(dn_data),
	.q_b()
);

// U67, U51 - Control latches
reg [7:0] u67_u51 = 8'b0;
always @(posedge clk) 
begin
	u67_u51 <= prom1_data_out;
end
assign prom_addr = reset ? 5'b0 : prom1_data_out[4:0];

wire m1 = u67_u51[2];
wire m2 = u67_u51[3];
wire m4 = u67_u51[4];
wire src = u67_u51[5];
wire srl = ~u67_u51[6];
wire color = u67_u51[7];

// U50, U49 - Sequence latches
reg [7:0] u50_u49 = 8'b0;
always @(posedge clk) 
begin
	u50_u49 <= prom2_data_out;
end
wire wg = u50_u49[7];
//wire vcas = ~u50_u49[6];
wire u72_clr = u50_u49[4];
wire msb = u50_u49[3];
wire vras = u50_u49[2];
wire phi = ~u50_u49[1];

reg phi_last;
reg cpu_en;

reg wait_n = 1'b1;
wire mreq = ~mreq_n;
reg mreq_last;

// U72 - CPU wait trigger flip-flop
always @(posedge clk)
begin
	mreq_last <= mreq;
	if(!u72_clr)
	begin
		wait_n <= 1'b1;
	end
	else
	begin
		if(mreq && !mreq_last) wait_n <= ~vid;
	end
end

reg src_last;
always @(posedge clk)
begin
	if(reset) src_last <= 1'b0;
	src_last <= src;
	ce_pix <= (src && !src_last);
	phi_last <= phi;
	cpu_en <= (phi && !phi_last);
end

// U53 - Z80 CPU
wire mreq_n;
wire iorq_n;
wire rd_n;
wire wr_n;
wire [15:0] cpu_addr;
wire [7:0] cpu_data_in;
wire [7:0] cpu_data_out;
wire RESET = reset || coin_start > 6'b0;
tv80e cpu (
	.clk(clk),
	.cen(cpu_en),
	.reset_n(~RESET),
	.wait_n(wait_n && ~pause),
	.int_n(1'b1),
	.nmi_n(1'b1),
	.busrq_n(1'b1),
	.m1_n(),
	.mreq_n(mreq_n),
	.iorq_n(iorq_n),
	.rd_n(rd_n),
	.wr_n(wr_n),
	.rfsh_n(),
	.halt_n(),
	.busak_n(),
	.A(cpu_addr),
	.di(cpu_data_in),
	.dout(cpu_data_out)
);

// CPU outputs
wire memr = ~(rd_n || mreq_n);
wire out = ~(wr_n || iorq_n);
wire memw = ~(wr_n || mreq_n);
wire in = ~(rd_n || iorq_n);
wire vid = (cpu_addr[15]);
wire vidrd_n = ~(memr && vid);
wire vidwr_n = ~(memw && vid && wg);
wire romrd_n = ~(memr && ~cpu_addr[15]);

wire rom_read/*verilator public_flat*/;
assign rom_read = ~romrd_n;

// CPU data selector
reg in_p1_cs;
reg in_p2_cs;
reg in_p3_cs;
reg in_p4_cs;
reg [7:0] in_p1_data = 8'hFF;
reg [7:0] in_p2_data = 8'hFF;
reg [7:0] in_p3_data = 8'hFF;
reg [7:0] in_p4_data = 8'hFF;

// Coin latch handling
wire coin_latch_enable = (coin_latch > {COIN_LATCH_TIMER_WIDTH{1'b0}});
reg coin_latch_input;

// Game select for dual game 
reg dual_game_index;
reg dual_game_toggle_last;

// Composite blank (active low)
wire cblank_n = ~(hblank | vblank);
wire vcnt_64 = vcnt[6];

// Monochrome video option (0=colour, 1=mono)
reg config_monovideo;
// Input decoding style
reg config_inputstyle;
// 16Kb / 32Kb ROM mode
reg config_largerom;
// Coin latch style (0=long, 1=short)
reg config_coinlatchstyle;
// Colour PROM output invert
reg config_invertcolprom;

// Samurai protection
reg [7:0] samurai_protection_data;
reg [7:0] samurai_protection_out;

always @(posedge clk)
begin

	if(config_inputstyle == 1'b0)
	begin
		// Standard input decode
		in_p1_cs = (in && cpu_addr[0]);
		in_p2_cs = (in && cpu_addr[1]);
		in_p3_cs = (in && cpu_addr[2]);
		in_p4_cs = (in && cpu_addr[3]);
	end
	else
	begin
		// Alternate input decode
		in_p1_cs = (in && cpu_addr[1:0] == 2'd0);
		in_p2_cs = (in && cpu_addr[1:0] == 2'd1);
		in_p3_cs = (in && cpu_addr[1:0] == 2'd2);
		in_p4_cs = (in && cpu_addr[1:0] == 2'd3);
	end

	in_p1_data <= in_p1;
	in_p2_data <= in_p2;
	in_p3_data <= in_p3;
	in_p4_data <= in_p4;

	// Default config options
	config_monovideo <= 1'b0;
	config_inputstyle <= 1'b0;
	config_largerom <= 1'b0;
	config_coinlatchstyle <= 1'b0;
	config_invertcolprom <= 1'b0;

	// Coin latch input defaults to IN_P4
	coin_latch_input <= in_p4_cs;

	// Handle dual game toggle
	dual_game_toggle_last <= dual_game_toggle;
	if(dual_game_toggle && !dual_game_toggle_last) dual_game_index <= ~dual_game_index;

	case(game_mode)
		GAME_ALPHAFIGHTER:
		begin
			config_inputstyle <= 1'b1;	
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
			in_p4_data[4] <= dual_game_index;
		end
		GAME_BORDERLINE:
		begin
			config_inputstyle <= 1'b1;
			in_p2_data[3] <= ~vblank;
			in_p3_data[3] <= vcnt[5];
			in_p4_data[3] <= coin_latch_enable;
		end
		GAME_CARHUNT_DUAL:
		begin
			config_inputstyle <= 1'b1;
			config_coinlatchstyle <= 1'b1;
			config_largerom <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
			in_p4_data[4] <= dual_game_index;
		end
		GAME_CARNIVAL:
		begin
			config_inputstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= coin_latch_enable;
		end
		GAME_DIGGER:
		begin
			in_p4_data[0] <= cblank_n;
			in_p4_data[7] <= coin_latch_enable;
		end
		GAME_FROGS:
		begin
			config_monovideo <= 1'b1;
			in_p4_data[0] <= vcnt_64;
			in_p4_data[7] <= ~coin_latch_enable;
		end
		GAME_HEADON:
		begin
			in_p4_data[0] <= vcnt_64;
			in_p4_data[7] <= ~coin_latch_enable;
		end
		GAME_HEADON2:
		begin
			in_p4_data[0] <= vcnt_64;
			in_p4_data[7] <= ~coin_latch_enable;
		end
		GAME_HEIANKYO:
		begin
			config_inputstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
		end
		GAME_INVINCO:
		begin
			in_p4_data[0] <= cblank_n;
			in_p4_data[7] <= coin_latch_enable;
		end
		GAME_INVINCO_DEEPSCAN:
		begin
			config_inputstyle <= 1'b1;
			config_coinlatchstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
			in_p4_data[4] <= dual_game_index;
		end
		GAME_INVINCO_HEADON2:
		begin
			config_inputstyle <= 1'b1;
			config_coinlatchstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
			in_p4_data[4] <= dual_game_index;
		end
		GAME_NSUB:
		begin
			config_invertcolprom <= 1'b1;
			config_coinlatchstyle <= 1'b1;
			in_p4_data[0] <= cblank_n;
			in_p4_data[7] <= ~coin_latch_enable;
		end
		GAME_PULSAR:
		begin
			config_inputstyle <= 1'b1;
			config_coinlatchstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= coin_latch_enable;
		end
		GAME_SAFARI:
		begin
			config_monovideo <= 1'b1;
			in_p4_data[0] <= vcnt_64;
			in_p4_data[7] <= ~coin_latch_enable;
		end
		GAME_SAMURAI:
		begin
			config_inputstyle <= 1'b1;
			// Samurai protection circuit - taken from MAME as I can't find the schematics
			if(memw && cpu_addr < 16'h8000)
			begin
				samurai_protection_data = cpu_data_out;
				samurai_protection_out <= 8'h00;
				if(samurai_protection_data == 8'hAB) samurai_protection_out <= 8'h02;
				if(samurai_protection_data == 8'h1D) samurai_protection_out <= 8'h0C;
			end
			in_p2_data[1] <= samurai_protection_out[1];
			in_p3_data[1] <= samurai_protection_out[2];
			in_p4_data[1] <= samurai_protection_out[3];
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
			
		end
		GAME_SPACEATTACK:
		begin
			in_p4_data[0] <= timer_enable;
			in_p4_data[7] <= ~coin_latch_enable;
		end
		GAME_SPACEATTACK_HEADON:
		begin
			config_inputstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
			in_p4_data[4] <= dual_game_index;
		end
		GAME_SPACETREK:
		begin
			config_inputstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= ~coin_latch_enable;
		end
		GAME_STARRAKER:
		begin
			config_inputstyle <= 1'b1;
			in_p2_data[3] <= ~vblank;
			in_p3_data[3] <= vcnt[5];
			in_p4_data[3] <= coin_latch_enable;
		end
		// GAME_SUBHUNT:
		// begin
		// 	in_p1_cs = (in && cpu_addr[1:0] == 2'd0);
		// 	in_p2_cs = (in && cpu_addr[1:0] == 2'd1);
		// 	in_p3_cs = (in && cpu_addr[1:0] == 2'd2);
		// 	in_p4_cs = (in && cpu_addr[1:0] == 2'd3);
		// 	in_p2_data[3] <= ~vblank;
		// 	in_p3_data[3] <= vcnt[5];
		// 	in_p4_data[3] <= coin_latch_enable;
		// end
		GAME_TRANQUILIZERGUN:
		begin
			config_inputstyle <= 1'b1;
			in_p2_data[3] <= ~vblank;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= coin_latch_enable;
		end
		GAME_WANTED:
		begin
			config_inputstyle <= 1'b1;
			config_largerom <= 1'b1;
			config_coinlatchstyle <= 1'b1;
			in_p2_data[3] <= cblank_n;
			in_p3_data[3] <= timer_enable;
			in_p4_data[3] <= coin_latch_enable;
		end

	endcase
end

assign cpu_data_in =	in_p1_cs ? in_p1_data : 
						in_p2_cs ? in_p2_data : 
						in_p3_cs ? in_p3_data : 
						in_p4_cs ? in_p4_data : 
						!romrd_n ? pgrom_data_out : 
						!vidrd_n ? ram_data_out : 
						8'b0;

always @(posedge clk)
begin
	//if(!romrd_n)  $display("romrd %x %x", cpu_addr, pgrom_data_out);
	//if(!vidwr_n)  $display("vidwr_n %x %x", cpu_addr, cpu_data_out);
	//if(!vidrd_n)  $display("vidrd_n %x %x", cpu_addr, ram_data_out);
	//if(memr) $display("memr: %x", cpu_addr);
	//if(memw) $display("memw: %x", cpu_addr, cpu_data_out);
	//if(in && !in_p1_cs && !in_p3_cs && !in_p4_cs) 
	//if(in) $display("in %b", cpu_addr);
	//if(in_p1_cs) $display("in_p1: %b", in_p1);
	//if(in_p3_cs) $display("in_p3_data: %b", in_p3_data);
	//if(in_p4_cs) $display("%d) in_p4: %b  timer: %b count: %d", debug_counter, in_p4_data, timer_enable, timer_count);
	//if(out) $display("out: %x", cpu_addr);
	//if(dn_wr) $display("dn: index=%d addr=%d data=%x pgrom=%b / %b", dn_index, dn_addr, dn_data, pgrom_wr, (dn_addr[15] == 0 && dn_index == 8'd0 && dn_wr));
end

// U48 - VIC 
wire csync;
wire [8:0] hcnt;
wire [8:0] vcnt;
wire [5:0] vic_data_out;
vic vic (
	.clk(clk),
	.reset(reset),

	.srl(srl),
	.src(src),
	.msb(msb),
	.m1(m1),
	.m2(m2),
	.m4(m4),
	.addr(cpu_addr[11:0]),
	.data(ram_data_out),

	.ram_addr(vic_data_out),
	.hsync(hsync),
	.vsync(vsync),
	.hblank(hblank),
	.vblank(vblank),
	.hcnt(hcnt),
	.vcnt(vcnt),
	.csync(),
	.cblank_n()
);

// Video RAM
reg video;
reg vras_last;
reg [7:0] char_code;
reg [7:0] char_data;
reg [31:0] debug_counter;

// Offset vertical counter allow correct character to be selected in time
// - Still not entirely sure why this is necessary - something to do with chain of async RAM modules in original board?
wire [8:0] vcnt_fixed = vcnt - 9'd1;

// Select 'character' index (flipped)
wire [2:0] char_index = (3'd7 - (hcnt[2:0]));

always @(posedge clk)
begin

	debug_counter <= debug_counter + 1'b1;

	vras_last <= vras;

	// The VIC chip and original TTL circuitry that predated it does two jobs - generate the video timing and manage data selection for RAS/CAS memory access
	// - As we don't need RAS/CAS for BRAM on the FPGA, we are selecting data purely at the point RAS is triggered
	if(vras && !vras_last)
	begin
		case({m4,m2,m1})
		3'b000: // Use CPU address for RAM access
		begin
			ram_addr <= cpu_addr[11:0];
		end
		3'b010: // Use video H/V signals for RAM access (to read character code for display)
		begin
			if(hcnt >= 9'h100)
			begin
				ram_addr <= { 2'b0, vcnt_fixed[7:3], 5'd0 };
			end
			else
			begin
				ram_addr <= { 2'b0, vcnt_fixed[7:3], hcnt[7:3] } + 12'd1;
			end
		end
		3'b100:
		begin // Use selected character code and vertical line within current cell for RAM access (to read pixel data)
			char_code = ram_data_out;
			ram_addr <= { 1'b1, char_code, vcnt_fixed[2:0] };
		end
		default:
		begin 
		end
		endcase
	end

	// Latch character line data out of RAM
	// - This index 22 of sequence ROM is a hack - but works?
	if(prom_addr == 5'd22)
	begin
		char_data = ram_data_out;
	end

	// Latch current pixel from character line
	if(!ce_pix) video <= char_data[char_index];

end

// Video RAM
// - U63 > U56 (Head On)

// Video RAM read address
reg [11:0] ram_addr;

// Video RAM data out
wire [7:0] ram_data_out;

// Video RAM - U63 > U56
dpram #(12,8) ram 
(
	.clock_a(clk),
	.enable_a(1'b1),
	.address_a(ram_addr),
	.wren_a(~vidwr_n),
	.data_a(cpu_data_out),
	.q_a(ram_data_out),
	
	.clock_b(clk),
	.enable_b(1'b1),
	.address_b(hs_address),
	.wren_b(hs_write_enable),
	.data_b(hs_data_in),
	.q_b(hs_data_out)
);


// HERE IS WHERE THINGS GET SKETCHY
// --------------------------------
// - The U44 PROM and surrounding circuitry for colour output is taken from the Head On 2 schematic

// U44 - Colour PROM
// --------------------
// 32 x 8 bits.
// colprom = U44	0x1C00 > 0x1C3F

// Colour PROM data out
wire [7:0] colprom_data_out;

// Colour PROM download write enable
wire colprom_wr = dn_addr[15:5] == 11'b10000000000 && dn_index == 8'd0 && dn_wr;

// Colour PROM read address
wire [4:0] colprom_addr;

// Colour PROM bank select
reg [1:0] colprom_bank = 2'd1;

// Colour PROM - U44
dpram #(5,8) colprom
(
	.clock_a(clk),
	.address_a(colprom_addr),
	.enable_a(!reset),
	.wren_a(1'b0),
	.data_a(),
	.q_a(colprom_data_out),

	.clock_b(clk),
	.address_b(dn_addr[4:0]),
	.enable_b(colprom_wr),
	.wren_b(colprom_wr),
	.data_b(dn_data),
	.q_b()
);

// 97269-P-B Daughter Board - used by N-Sub only
wire [7:0] sega_97269pb_r;
wire [7:0] sega_97269pb_g;
wire [7:0] sega_97269pb_b;
sega_97269pb sega_97269pb (
	.clk(clk),
	.reset(reset),
	.palbank_b2(colprom_bank[0]),
	.palbank_b3(colprom_bank[1]),
	.hcnt(hcnt),
	.vcnt(vcnt),
	.hsync(hsync),
	.vsync(vsync),
	.vblank(vblank),
	.dn_addr(dn_addr[15:0]),
	.dn_data(dn_data),
	.dn_wr(dn_wr && dn_index == 8'd0),
	.rgb(rgb_3bpp),
	.video(video),
	.r(sega_97269pb_r),
	.g(sega_97269pb_g),
	.b(sega_97269pb_b)
);

// Colour bank select
wire u62_q = ~(out && cpu_addr[6]);
reg u62_q_last;
always @(posedge clk)
begin
	begin
		// Colour bank select (seems largely unused)
		u62_q_last <= u62_q;
		if(u62_q && !u62_q_last) colprom_bank <= cpu_data_out[1:0];

		// Some titles need hardcoded colour banks or different bank switching triggers
		case(game_mode)
			GAME_INVINCO: colprom_bank <= 2'b01;
			GAME_HEADON2: colprom_bank <= 2'b11;
			GAME_DIGGER: colprom_bank <= 2'b01;
			GAME_HEIANKYO: colprom_bank <= 2'b10;
			GAME_NSUB: if(out_p2_rising) colprom_bank <= cpu_data_out[1:0]; // N-Sub uses OUT P2 to select colour bank
			GAME_SAMURAI: if(out_p3_rising) colprom_bank <= cpu_data_out[1:0]; // Samurai uses OUT P2 to select colour bank
			GAME_TRANQUILIZERGUN: colprom_bank <= 2'b01;
		endcase
	end
end

// Assemble colprom lookup address using latched character code and bank select
assign colprom_addr = { colprom_bank, char_code[7:5] };

// Invert colour PROM output if required
wire [7:0] colprom_data_out_fixed = config_invertcolprom ? ~colprom_data_out : colprom_data_out;

// U43 - Flip flop - Latch 6 bits of colour PROM data when colr goes high
reg [5:0] u43_q;
wire colr = ~srl;
reg colr_last;
always @(posedge clk)
begin
	colr_last <= colr;
	if(colr && colr_last) u43_q <= { colprom_data_out_fixed[7:5], colprom_data_out_fixed[3:1] };
end

// U42 - Data selector - Selects between background and foreground colours from latched U43 data
wire [2:0] fgcol = u43_q[5:3];
wire [2:0] bgcol = u43_q[2:0];
wire [2:0] u42_q = video ? fgcol : bgcol;

// Swizzle the colour outputs into rgb
wire [2:0] rgb_3bpp = config_monovideo ? (video ? 3'b111 : 3'b000) : { u42_q[1], u42_q[0], u42_q[2] };

assign rgb = game_mode == GAME_NSUB ? { sega_97269pb_b, sega_97269pb_g, sega_97269pb_r} : {{8{rgb_3bpp[2]}},{8{rgb_3bpp[1]}},{8{rgb_3bpp[0]}}};

// Outputs 
reg out_p1_last = 1'b0;
reg out_p2_last = 1'b0;
reg out_p3_last = 1'b0;
reg out_p4_last = 1'b0;
wire out_p1 = (out && cpu_addr[0]);
wire out_p2 = (out && cpu_addr[1]);
wire out_p3 = (out && cpu_addr[2]);
wire out_p4 = (out && cpu_addr[3]);
wire out_p1_rising = out_p1 && !out_p1_last;
wire out_p2_rising = out_p2 && !out_p2_last;
wire out_p3_rising = out_p3 && !out_p3_last;
wire out_p4_rising = out_p4 && !out_p4_last;
reg [7:0] out_p1_data = 8'hFF;
reg [7:0] out_p2_data = 8'hFF;
reg [7:0] out_p3_data = 8'hFF;
reg [7:0] out_p4_data = 8'hFF;
always @(posedge clk)
begin
	if(!reset)
	begin
		out_p1_last <= out_p1;
		out_p2_last <= out_p2;
		out_p3_last <= out_p3;
		out_p4_last <= out_p4;
		if(out_p1_rising)
		begin
			out_p1_data <= cpu_data_out;
			$display("%d)\tOUTP1: %b", debug_counter, cpu_data_out);
		end
		if(out_p2_rising) 
		begin
			out_p2_data <= cpu_data_out;
			$display("%d)\tOUTP2: %b", debug_counter, cpu_data_out);
		end
		if(out_p3_rising)
		begin
			out_p3_data <= cpu_data_out;
			$display("%d)\tOUTP3: %b", debug_counter, cpu_data_out);
		end
		if(out_p4_rising)
		begin
			out_p4_data <= cpu_data_out;
			$display("%d)\tOUTP4: %b", debug_counter, cpu_data_out);
		end
	end
end

// Timer circuit
// -------------
reg timer_enable;
reg [15:0] timer_count;
localparam timer_count_max = 16'd19500;  // <- This is still a guess
always @(posedge clk)
begin
	if(reset)
	begin
		timer_enable <= 1'b1;
		timer_count <= 16'b0;
	end
	else
	begin
		timer_count <= timer_count + 1'b1;
		if(timer_count == timer_count_max)
		begin
			timer_count <= 16'b0;
			timer_enable <= ~timer_enable;
		end
	end
end

// Coin circuit
// ------------
reg coin_last;
localparam COIN_START_TIMER_WIDTH = 6;
reg [COIN_START_TIMER_WIDTH-1:0] coin_start;
reg [COIN_START_TIMER_WIDTH-1:0] coin_start_timer_max;
reg coin_inserted;
localparam COIN_LATCH_TIMER_WIDTH = 10;
reg [COIN_LATCH_TIMER_WIDTH-1:0] coin_latch;
reg [COIN_LATCH_TIMER_WIDTH-1:0] coin_latch_timer_max;

always @(posedge clk) begin
	if(reset)
	begin
		// Reset coin latch and insert registers
		coin_latch <= {COIN_LATCH_TIMER_WIDTH{1'b0}};
		coin_inserted <= 1'b0;
		// Reset coin start timer (number of cycles to hold reset high after coin insert)
		coin_start_timer_max <= {COIN_START_TIMER_WIDTH{1'b1}};
		// Reset coin latch timer (number of cycles to hold coin latch low after insert)
		coin_latch_timer_max <= config_coinlatchstyle ? {6'b0, {COIN_LATCH_TIMER_WIDTH-6{1'b1}}} : {COIN_LATCH_TIMER_WIDTH{1'b1}};
	end
	else
	begin

		// Register inserted coin
		if(coin_latch_input)
		begin
			if(coin_inserted && coin_start == {COIN_START_TIMER_WIDTH{1'b0}})
			begin
				coin_latch <= coin_latch_timer_max;
				coin_inserted <= 1'b0;
			end
			if(coin_latch > {COIN_LATCH_TIMER_WIDTH{1'b0}}) coin_latch <= coin_latch - 1'b1;
		end

		// When coin input is going high, latch coin inserted and start reset pulse
		coin_last <= coin;
		if(coin && !coin_last)
		begin
			coin_inserted <= 1'b1;
			coin_start <= coin_start_timer_max;
		end

		// Decrement coin start timer if active
		if(coin_start > {COIN_START_TIMER_WIDTH{1'b0}}) coin_start <= coin_start - 1'b1;
	end
end

// Sound boards
// ------------
localparam SOUND_NONE = 0;
localparam SOUND_CARNIVAL = 1;
localparam SOUND_HEADON = 2;
reg [1:0] sound_board = SOUND_NONE;
always @(posedge clk)
begin
	case(game_mode)
		GAME_CARNIVAL: sound_board <= SOUND_CARNIVAL;
		GAME_HEADON: sound_board <= SOUND_HEADON;
		GAME_HEADON2: sound_board <= SOUND_HEADON;
	endcase
end

`define ENABLE_CARNIVAL_MUSIC

// Carnival - dedicated music board (AY-3-8910 variant)
`ifdef ENABLE_CARNIVAL_MUSIC
wire signed [15:0] sound_carnival_out;
sound_carnival sound_carnival
(
	.clk(clk),
	.reset(reset),
	.control_1(out_p1_data),
	.control_2(out_p2_data),
	.out(sound_carnival_out),
	.dn_addr(dn_addr),
	.dn_index(dn_index),
	.dn_wr(dn_wr),
	.dn_data(dn_data)
);
`endif

// // Head On sound board
// wire signed [15:0] sound_headon_out_l;
// wire signed [15:0] sound_headon_out_r;
// sound_headon sound_headon
// (
// 	.clk(clk),
// 	.reset(reset),
// 	.control(out_p2_data),
// 	.out_l(sound_headon_out_l),
// 	.out_r(sound_headon_out_r)
// );

// Wave sample player module
// - Used by Carnival, Invinco and Pulsar to emulate analog sound board by playing WAV samples sourced from MAME project
wire [15:0] wave_sound_out;
wave_sound wave (
	.clk(clk_sfx),
	.ce_sys(clk),
	.reset(reset),
	.pause(pause),
	.dn_addr(dn_addr),
	.dn_data(dn_data),
	.dn_download(dn_download),
	.dn_wr(dn_wr),
	.dn_index(dn_index),
	.triggers(~{out_p2_data, out_p1_data}),
	.sdram_addr(sdram_addr),
	.sdram_dout(sdram_dout),  // Data coming back from wave ROM
	.sdram_rd(sdram_rd),
	.sdram_ack(sdram_ack), // data is ready
	.out(wave_sound_out)
);

`ifdef ENABLE_CARNIVAL_MUSIC
	assign audio = sound_carnival_out + wave_sound_out;
`else
	assign audio = wave_sound_out;
`endif
//assign audio_l = //sound_board == SOUND_HEADON ? sound_headon_out_l : 



endmodule

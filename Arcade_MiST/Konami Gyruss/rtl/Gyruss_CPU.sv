//============================================================================
// 
//  Gyruss main PCB model
//  Copyright (C) 2021 Ace
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

//Module declaration, I/O ports
module Gyruss_CPU
(
	input         reset,
	input         clk_49m, //Actual frequency: 49.152MHz
	output  [2:0] red, green, //8-bit RGB, 3 bits per color for red and green,
	output  [1:0] blue,       //2 bits for blue
	output        video_hsync, video_vsync, video_csync, //CSync not needed for MISTer
	output        video_hblank, video_vblank,
	output        ce_pix,
	
	input   [7:0] controls_dip,
	output  [7:0] cpubrd_Dout,
	output        cpubrd_A5, cpubrd_A6,
	output        cs_sounddata, irq_trigger,
	output        cs_dip3, cs_dip2, cs_controls_dip1,
	
	//Screen centering (alters HSync, VSync and VBlank timing in the Konami 082 to reposition the video output)
	input   [3:0] h_center, v_center,
	
	input         ep1_cs_i,
	input         ep2_cs_i,
	input         ep3_cs_i,
	input         ep4_cs_i,
	input         ep5_cs_i,
	input         ep6_cs_i,
	input         ep7_cs_i,
	input         ep8_cs_i,
	input         ep9_cs_i,
	input         cp_cs_i,
	input         tl_cs_i,
	input         sl_cs_i,
	input  [24:0] ioctl_addr,
	input   [7:0] ioctl_data,
	input         ioctl_wr,
	
	input         pause,

	input  [12:0] hs_address,
	input   [7:0] hs_data_in,
	output  [7:0] hs_data_out,
	input         hs_write,
	input         hs_access,

	output [15:0] main_cpu_rom_addr,
	input   [7:0] main_cpu_rom_do,
	output [12:0] sub_cpu_rom_addr,
	input   [7:0] sub_cpu_rom_do,
	output [12:0] sp_rom_addr,
	input  [31:0] sp_rom_do	
);

//------------------------------------------------------- Signal outputs -------------------------------------------------------//

//Assign active high HBlank and VBlank outputs
assign video_hblank = hblk;
assign video_vblank = vblk;

//Output pixel clock enable
assign ce_pix = cen_6m;

//Output select lines for player inputs and DIP switches to sound board
assign cs_controls_dip1 = (~n_k501_enable & z80_A[14]) & (z80_A[8:7] == 2'b01) & n_ram_write;
assign cs_dip2 = (~n_k501_enable & z80_A[14]) & (z80_A[8:7] == 2'b00) & n_ram_write;
assign cs_dip3 = (~n_k501_enable & z80_A[14]) & (z80_A[8:7] == 2'b10) & n_ram_write;

//Output primary MC6809E address lines A5 and A6 to sound board
assign cpubrd_A5 = z80_A[5];
assign cpubrd_A6 = z80_A[6];

//Assign CPU board data output to sound board
assign cpubrd_Dout = z80_Dout;

//Generate and output chip select for latching sound data to sound CPU
assign cs_sounddata = (~n_k501_enable & z80_A[14]) & (z80_A[8:7] == 2'b10) & ~n_ram_write;

//Generate sound IRQ trigger
wire cs_soundirq = (~n_k501_enable & z80_A[14]) & (z80_A[8:7] == 2'b01) & ~n_ram_write;
reg sound_irq = 1;
always_ff @(posedge clk_49m) begin
	if(n_cen_3m) begin
		if(cs_soundirq)
			sound_irq <= 1;
		else
			sound_irq <= 0;
	end
end
assign irq_trigger = sound_irq;

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 12.288MHz, 6.144MHz, 3.072MHz and 1.576MHz clock enables
reg [4:0] div = 5'd0;
always_ff @(posedge clk_49m) begin
	div <= div + 5'd1;
end
reg [3:0] n_div = 4'd0;
always_ff @(negedge clk_49m) begin
	n_div <= n_div + 4'd1;
end
wire cen_12m = !div[1:0];
wire cen_6m = !div[2:0];
wire cen_3m = !div[3:0];
wire n_cen_3m = !n_div;
wire cen_1m5 = !div;

//Generate E and Q clock enables for KONAMI-1 (code adapted from Sorgelig's phase generator used in the MiSTer Vectrex core)
reg k1_E, k1_Q;
always_ff @(posedge clk_49m) begin
	reg [1:0] clk_phase = 0;
	k1_E <= 0;
	k1_Q <= 0;
	if(cen_6m) begin
		clk_phase <= clk_phase + 1'd1;
		case(clk_phase)
			2'b01: k1_Q <= 1;
			2'b10: k1_E <= 1;
		endcase
	end
end

//------------------------------------------------------------ CPUs ------------------------------------------------------------//

//Primary CPU - Zilog Z80 (uses T80s version of the T80 soft core)
wire [15:0] z80_A;
wire [7:0] z80_Dout;
wire n_mreq, n_rd, n_rfsh;
T80s u13G
(
	.RESET_n(reset),
	.CLK(clk_49m),
	.CEN(n_cen_3m & ~pause),
	.NMI_n(z80_nmi),
	.WAIT_n(n_wait),
	.MREQ_n(n_mreq),
	.RD_n(n_rd),
	.RFSH_n(n_rfsh),
	.A(z80_A),
	.DI(z80_Din),
	.DO(z80_Dout)
);
//Address decoding for Z80
wire cs_rom1 = ~n_mreq & n_rfsh & (z80_A[15:13] == 3'b000);
wire cs_rom2 = ~n_mreq & n_rfsh & (z80_A[15:13] == 3'b001);
wire cs_rom3 = ~n_mreq & n_rfsh & (z80_A[15:13] == 3'b010);
wire n_cs_k501 = ~(~n_mreq & n_rfsh & z80_A[15]);
wire cs_mainlatch = (~n_k501_enable & z80_A[14]) & (z80_A[8:7] == 2'b11) & ~n_ram_write;
wire cs_z80sharedram = (z80_A[14:13] == 2'b01) & ~n_k501_enable;
wire n_cs_vram_wram = ~((z80_A[14:13] == 2'b00) & ~n_k501_enable);
//Part of the RAM decoding is handled by the Konami 501 custom chip - instantiate an instance of this IC here
wire n_wait, n_ram_write, n_k501_enable;
wire [7:0] k501_D, k501_Dout;
k501 u11E
(
	.CLK(clk_49m),
	.CEN(cen_12m),
	.H1(h_cnt[0]),
	.H2(h_cnt[1]),
	.RAM(n_cs_k501),
	.RD(n_rd),
	.WAIT(n_wait),
	.WRITE(n_ram_write),
	.ENABLE(n_k501_enable),
	.Di(z80_Dout),
	.XDi(k501_Din),
	.Do(k501_Dout),
	.XDo(k501_D)
);
//Multiplex data inputs to Z80
wire [7:0] z80_Din = cs_rom1    ? eprom1_D:
                     cs_rom2    ? eprom2_D:
                     cs_rom3    ? eprom3_D:
                     ~n_cs_k501 ? k501_Dout:
                     8'hFF;

assign main_cpu_rom_addr = z80_A[14:0];
//Z80 ROMs
//ROM 1/3
wire [7:0] eprom1_D = main_cpu_rom_do;
/*
eprom_1 u11J
(
	.ADDR(z80_A[12:0]),
	.CLK(clk_49m),
	.DATA(eprom1_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep1_cs_i),
	.WR(ioctl_wr)
);*/
//ROM 2/3
wire [7:0] eprom2_D = main_cpu_rom_do;
/*
eprom_2 u12J
(
	.ADDR(z80_A[12:0]),
	.CLK(clk_49m),
	.DATA(eprom2_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep2_cs_i),
	.WR(ioctl_wr)
);*/
//ROM 3/3
wire [7:0] eprom3_D = main_cpu_rom_do;
/*
eprom_3 u13J
(
	.ADDR(z80_A[12:0]),
	.CLK(clk_49m),
	.DATA(eprom3_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep3_cs_i),
	.WR(ioctl_wr)
);*/

//Multiplex data input to Konami 501 data bus passthrough
wire [7:0] k501_Din = (~n_cs_vram_wram & cs_wram0 & n_vram_wram_wr)   ? wram0_D:
                      (~n_cs_vram_wram & cs_wram1 & n_vram_wram_wr)   ? wram1_D:
                      (~n_cs_vram_wram & ~n_cs_vram & n_vram_wram_wr) ? vram_D:
                      (cs_z80sharedram & n_z80_sharedram_wr)          ? z80_sharedram_D:
                      (cs_controls_dip1 | cs_dip2 | cs_dip3)          ? controls_dip:
                      8'hFF;

//Main latch
reg z80_nmi_mask = 0;
reg flip = 0;
always_ff @(posedge clk_49m) begin
	if(!reset) begin
		z80_nmi_mask <= 0;
		flip <= 0;
	end
	else if(n_cen_3m) begin
		if(cs_mainlatch)
			case(z80_A[2:0])
				3'b000: z80_nmi_mask <= k501_D[0];
				3'b101: flip <= k501_D[0];
				default:;
		endcase
	end
end

//Generate VBlank NMI for Z80
reg z80_nmi = 1;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(!z80_nmi_mask)
			z80_nmi <= 1;
		else if(vblank_irq_en)
			z80_nmi <= 0;
	end
end

//VRAM
wire [7:0] vram_D;
spram #(8, 11) u5J
(
	.clk(clk_49m),
	.we(~n_cs_vram_wram & ~n_cs_vram & ~n_vram_wram_wr),
	.addr(vram_wram_A),
	.data(k501_D),
	.q(vram_D)
);
//Z80 work RAM
//Bank 0

// Hiscore mux
wire [10:0] u3J_addr = hs_access ? hs_address[10:0] : vram_wram_A;
wire [7:0] u3J_din = hs_access ? hs_data_in : k501_D;
wire u3J_wren = hs_access ? hs_write : (~n_cs_vram_wram & cs_wram0 & ~n_vram_wram_wr);
wire [7:0] u3J_dout;
assign wram0_D = hs_access ? 8'h00 : u3J_dout;
assign hs_data_out = hs_access ? u3J_dout : 8'h00;

wire [7:0] wram0_D;
spram #(8, 11) u3J
(
	.clk(clk_49m),
	.we(u3J_wren),
	.addr(u3J_addr),
	.data(u3J_din),
	.q(u3J_dout)
);
//Bank 1
wire [7:0] wram1_D;
spram #(8, 11) u2J
(
	.clk(clk_49m),
	.we(~n_cs_vram_wram & cs_wram1 & ~n_vram_wram_wr),
	.addr(vram_wram_A),
	.data(k501_D),
	.q(wram1_D)
);
//Generate select lines and write enable for work RAM and VRAM
wire n_cs_vram = z80_A[12] & ~h_cnt[1];
wire cs_wram0 = n_cs_vram & ~z80_A[11];
wire cs_wram1 = n_cs_vram & z80_A[11];
wire n_vram_wram_wr = n_cs_vram_wram | n_ram_write;

//Shared RAM
wire [7:0] z80_sharedram_D, k1_sharedram_D;
dpram_dc #(.widthad_a(11)) u17C
(
	.clock_a(clk_49m),
	.address_a(z80_A[10:0]),
	.data_a(k501_D),
	.q_a(z80_sharedram_D),
	.wren_a(cs_z80sharedram & ~n_z80_sharedram_wr),

	.clock_b(clk_49m),
	.address_b(k1_A[10:0]),
	.data_b(k1_Dout),
	.q_b(k1_sharedram_D),
	.wren_b(cs_k1sharedram & ~k1_rw & h_cnt[1])
);
//Generate write enable for Z80 section of shared RAM (active low)
wire n_z80_sharedram_wr = ~cs_z80sharedram | n_ram_write;

//Secondary CPU - KONAMI-1 custom encrypted MC6809E (uses synchronous version of Greg Miller's cycle-accurate MC6809E made by
//Sorgelig with a wrapper to decrypt XOR/XNOR-encrypted opcodes and a further modification to Greg's MC6809E to directly
//accept the opcodes)
wire k1_rw;
wire [15:0] k1_A;
wire [7:0] k1_Dout;
KONAMI1 u18F
(
	.CLK(clk_49m),
	.fallE_en(k1_E),
	.fallQ_en(k1_Q),
	.D(k1_Din),
	.DOut(k1_Dout),
	.ADDR(k1_A),
	.RnW(k1_rw),
	.nIRQ(k1_irq),
	.nFIRQ(1),
	.nNMI(1),
	.nHALT(1),
	.nRESET(reset)
);

//Address decoding for KONAMI-1
wire cs_beam = (k1_A[15:13] == 3'b000) & k1_rw;
wire cs_k1irqmask = (k1_A[15:13] == 3'b001) & ~k1_rw;
wire cs_spriteram = (k1_A[15:13] == 3'b010);
wire cs_k1sharedram = (k1_A[15:13] == 3'b011);
wire cs_rom4 = (k1_A[15:13] == 3'b111);
//Multiplex data inputs to KONAMI-1
wire [7:0] k1_Din = cs_beam                                         ? v_cnt:
                    (cs_spriteram & cs_spriteram0 & ~spriteram0_wr) ? spriteram_D[7:0]:
                    (cs_spriteram & cs_spriteram1 & ~spriteram1_wr) ? spriteram_D[15:8]:
                    (cs_k1sharedram & k1_rw & h_cnt[1])             ? k1_sharedram_D:
                    cs_rom4                                         ? eprom4_D:
                    8'hFF;

assign sub_cpu_rom_addr = k1_A[12:0];
//KONAMI-1 ROM
wire [7:0] eprom4_D = sub_cpu_rom_do;
/*
eprom_4 u19E
(
	.ADDR(k1_A[12:0]),
	.CLK(clk_49m),
	.DATA(eprom4_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep4_cs_i),
	.WR(ioctl_wr)
);
*/
//Generate write enable for all KONAMI-1 RAM (active low)
wire k1_rw1 = h1d | k1_rw;

//Generate IRQ mask for KONAMI-1
reg k1_irq_mask;
always_ff @(posedge clk_49m) begin
	if(!reset)
		k1_irq_mask <= 0;
	else if(cen_3m && cs_k1irqmask)
		k1_irq_mask <= k1_Dout[0];
end

//Generate VBlank IRQ for KONAMI-1
reg k1_irq = 1;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(!k1_irq_mask)
			k1_irq <= 1;
		else if(vblank_irq_en)
			k1_irq <= 0;
	end
end

//-------------------------------------------------------- Video timing --------------------------------------------------------//

//Konami 082 custom chip - responsible for all video timings
wire vblk, vblank_irq_en;
wire [8:0] h_cnt;
wire [7:0] v_cnt;
k082 u11G
(
	.reset(1),
	.clk(clk_49m),
	.cen(cen_6m),
	.h_center(h_center),
	.v_center(v_center),
	.n_vsync(video_vsync),
	.sync(video_csync),
	.n_hsync(video_hsync),
	.vblk(vblk),
	.vblk_irq_en(vblank_irq_en),
	.h1(h_cnt[0]),
	.h2(h_cnt[1]),
	.h4(h_cnt[2]),
	.h8(h_cnt[3]),
	.h16(h_cnt[4]),
	.h32(h_cnt[5]),
	.h64(h_cnt[6]),
	.h128(h_cnt[7]),
	.n_h256(h_cnt[8]),
	.v1(v_cnt[0]),
	.v2(v_cnt[1]),
	.v4(v_cnt[2]),
	.v8(v_cnt[3]),
	.v16(v_cnt[4]),
	.v32(v_cnt[5]),
	.v64(v_cnt[6]),
	.v128(v_cnt[7])
);

//Latch vertical counter from 082 custom chip when the horizontal counter hits 256
reg [7:0] vcnt_lat = 8'd0;
always_ff @(posedge clk_49m) begin
	if(cen_6m && h_cnt == 9'd256)
		vcnt_lat <= v_cnt;
end

//Latch least significant bit of horizontal counter (to be used for sprite RAM logic)
reg h1d;
always_ff @(posedge clk_49m) begin
	if(cen_6m)
		h1d <= h_cnt[0];
end

//XOR horizontal counter bits [7:2] with HFLIP flag
wire [7:2] hcnt_x = h_cnt[7:2] ^ {6{flip}};

//XOR latched vertical counter bits with VFLIP flag
wire [7:0] vcnt_x = vcnt_lat ^ {8{flip}};

//--------------------------------------------------------- Tile layer ---------------------------------------------------------//

//Generate addresses for VRAM
wire [10:0] vram_wram_A = h_cnt[1] ? {h_cnt[2], vcnt_x[7:3], hcnt_x[7:3]} : z80_A[10:0];

//LDO, labelled D1 in the Time Pilot schematics, signals to the tilemap logic when to latch tilemap codes from VRAM.  It pulses
//low when the lower 3 bits of the horizontal counter are all 1, then on the rising edge, tilemap codes are latched.
//Set LDO as a register and latch a 0 when the 3 least significant bits of the horizontal counter are set to 1, otherwise latch
//a 1
reg ldo = 1;
always_ff @(posedge clk_49m) begin
	if(h_cnt[2:0] == 3'b111)
		ldo <= 0;
	else
		ldo <= 1;
end

//Latch tilemap code from VRAM at every rising edge of LDO (equivalent to when LDO is low and the 3 least significant bits of
//the horizontal counter are all set to 0)
reg [7:0] tile_code = 8'd0;
always_ff @(posedge clk_49m) begin
	if(!ldo && h_cnt[2:0] == 3'b000)
		tile_code <= vram_D;
end

//Latch tilemap attributes from VRAM at the rising edge of bit 2 of the horizontal counter when !H256 is high
reg tile_attrib_latch = 1;
always_ff @(posedge clk_49m) begin
	if(h_cnt[2:0] == 3'b011)
		tile_attrib_latch <= 0;
	else
		tile_attrib_latch <= 1;
end
reg [7:0] tile_attrib = 8'd0;
always_ff @(posedge clk_49m) begin
	if(h_cnt[8] && !tile_attrib_latch && h_cnt[2:0] == 3'b100)
		tile_attrib <= vram_D;
end

//Latch tile color information, tilemap enable and flip signal for tilemap 083 custom chip every 8 pixels
wire tile_flip = tile_hflip ^ ~flip;
reg tile_083_flip = 0;
reg tilemap_en = 0;
reg [3:0] tile_color = 4'd0;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(h_cnt[2:0] == 3'b011) begin
			tile_083_flip <= tile_flip;
			tile_color <= tile_attrib[3:0];
			tilemap_en <= tile_attrib[4];
		end
		else begin
			tile_083_flip <= tile_083_flip;
			tile_color <= tile_color;
			tilemap_en <= tilemap_en;
		end
	end
end

//Generate address lines A1 - A3 of tilemap ROMs, CRA and tile flip attributes on the falling edge of horizontal
//counter bit 2
reg v1l, v2l, v4l, cra, tile_hflip, tile_vflip;
reg old_h4;
always_ff @(posedge clk_49m) begin
	old_h4 <= h_cnt[2];
	if(old_h4 && !h_cnt[2]) begin
		v1l <= vcnt_x[0];
		v2l <= vcnt_x[1];
		v4l <= vcnt_x[2];
		tile_hflip <= tile_attrib[6];
		tile_vflip <= tile_attrib[7];
		cra <= tile_attrib[5];
	end
end

//Address tilemap ROMs
assign tilerom_A[12] = cra;
assign tilerom_A[11:4] = tile_code;
assign tilerom_A[3:0] = {hcnt_x[2] ^ tile_hflip, v4l ^ tile_vflip, v2l ^ tile_vflip, v1l ^ tile_vflip};

//Tilemap ROM
wire [12:0] tilerom_A;
wire [7:0] eprom5_D;

eprom_5 u2H
(
	.ADDR(tilerom_A),
	.CLK(clk_49m),
	.DATA(eprom5_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep5_cs_i),
	.WR(ioctl_wr)
);

//Konami 083 custom chip 1/2 - this one shifts the pixel data from tilemap ROMs
k083 u3G
(
	.CK(clk_49m),
	.CEN(cen_6m),
	.LOAD(h_cnt[1:0] == 2'b11),
	.FLIP(tile_083_flip),
	.DB0i(eprom5_D),
	.DSH0(tile_lut_A[1:0])
);

//Tilemap lookup PROM
wire [7:0] tile_lut_A;
assign tile_lut_A[7:6] = 2'b00;
assign tile_lut_A[5:2] = tile_color;
wire [3:0] tile_D;
tile_lut_prom u3E
(
	.ADDR(tile_lut_A),
	.CLK(clk_49m),
	.DATA(tile_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(tl_cs_i),
	.WR(ioctl_wr)
);

//-------------------------------------------------------- Sprite layer --------------------------------------------------------//

//Generate sprite RAM enables (both active low)
wire n_cs_spriteram = ~cs_spriteram | ~h_cnt[1];
wire cs_spriteram0 = ~n_cs_spriteram & k1_A[1];
wire cs_spriteram1 = ~n_cs_spriteram & ~k1_A[1];

//Generate write enables for sprite RAM (active low)
wire spriteram0_wr = ~n_cs_spriteram & ~k1_rw1 & k1_A[1];
wire spriteram1_wr = ~n_cs_spriteram & ~k1_rw1 & ~k1_A[1];

//Sprite RAM
wire [15:0] spriteram_D;
wire [9:0] spriteram_A;
assign spriteram_A = h_cnt[1] ? {k1_A[10:2], k1_A[0]} : {3'b000, h_cnt[7], (h_cnt[8] ^ h_cnt[7]), h_cnt[6], h_cnt[3], h_cnt[4], h_cnt[5], h_cnt[2]};
//Bank 0 (lower 4 bits)
spram #(4, 10) u13A
(
	.clk(clk_49m),
	.we(cs_spriteram & cs_spriteram0 & spriteram0_wr),
	.addr(spriteram_A),
	.data(k1_Dout[3:0]),
	.q(spriteram_D[3:0])
);
//Bank 0 (upper 4 bits)
spram #(4, 10) u14A
(
	.clk(clk_49m),
	.we(cs_spriteram & cs_spriteram0 & spriteram0_wr),
	.addr(spriteram_A),
	.data(k1_Dout[7:4]),
	.q(spriteram_D[7:4])
);
//Bank 1 (lower 4 bits)
spram #(4, 10) u11A
(
	.clk(clk_49m),
	.we(cs_spriteram & cs_spriteram1 & spriteram1_wr),
	.addr(spriteram_A),
	.data(k1_Dout[3:0]),
	.q(spriteram_D[11:8])
);
//Bank 1 (upper 4 bits)
spram #(4, 10) u12A
(
	.clk(clk_49m),
	.we(cs_spriteram & cs_spriteram1 & spriteram1_wr),
	.addr(spriteram_A),
	.data(k1_Dout[7:4]),
	.q(spriteram_D[15:12])
);

//Latch all data output from sprite RAM at 1/4 of the pixel clock
reg [15:0] spriteram_reg = 16'd0;
always_ff @(posedge clk_49m) begin
	if(cen_1m5)
		spriteram_reg <= spriteram_D;
end

//Konami 503 custom chip - generates sprite addresses for lower half of sprite ROMs, sprite line buffer control, enable for
//sprite write and sprite flip for 083 custom chip.
wire cs_linebuffer, sprite_flip;
wire [5:0] k503_R;
k503 u9F
(
	.clk(clk_49m),
	.clk_en(cen_6m),
	.OB(spriteram_reg[7:0]),
	.VCNT(vcnt_lat),
	.H4(h_cnt[2]),
	.H8(1'b0),
	.LD(h_cnt[1:0] != 2'b11),
	.OCS(cs_linebuffer),
	.NE83(sprite_flip),
	.R(k503_R)
);
assign spriterom_A[5] = k503_R[5];
assign spriterom_A[3:0] = k503_R[3:0];

//Latch sprite code from sprite RAM bank 1 every 8 pixels
reg [7:0] sprite_code = 8'd0;
always_ff @(posedge clk_49m) begin
	if(h_cnt[2:0] == 3'b000)
		sprite_code <= spriteram_reg[15:8];
end

//Assign sprite code to address the upper 7 bits and bit 4 of the sprite ROMs
assign spriterom_A[12:6] = sprite_code[7:1];
assign spriterom_A[4] = sprite_code[0];

assign sp_rom_addr = spriterom_A;
//Sprite ROMs
wire [12:0] spriterom_A;
//ROM 1/4
wire [7:0] eprom6_D = sp_rom_do[7:0];
/*
eprom_6 u9C
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom6_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep6_cs_i),
	.WR(ioctl_wr)
);
*/
//ROM 2/4
wire [7:0] eprom7_D = sp_rom_do[15:8];
/*
eprom_7 u8C
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom7_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep7_cs_i),
	.WR(ioctl_wr)
);
*/
//ROM 3/4
wire [7:0] eprom8_D = sp_rom_do[23:16];
/*
eprom_8 u7C
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom8_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep8_cs_i),
	.WR(ioctl_wr)
);*/
//ROM 4/4
wire [7:0] eprom9_D = sp_rom_do[31:24];
/*
eprom_9 u6C
(
	.ADDR(spriterom_A),
	.CLK(clk_49m),
	.DATA(eprom9_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep9_cs_i),
	.WR(ioctl_wr)
);
*/
//Latch sprite attributes and horizontal position every 8 pixels
reg [4:0] sprite_attrib = 5'd0;
reg [7:0] sprite_hpos = 8'd0;
always_ff @(posedge clk_49m) begin
	if(h_cnt[2:0] == 3'b100) begin
		sprite_attrib <= {spriteram_reg[5], spriteram_reg[3:0]};
		sprite_hpos <= spriteram_reg[15:8];
	end
end

//Multiplex sprite ROM data outputs based on the state of sprite attribute bit 4
reg spriterom_sel = 0;
always_ff @(posedge clk_49m) begin
	if(h_cnt[2:0] == 3'b000)
		spriterom_sel <= sprite_attrib[4];
end
wire [15:0] spriterom_D = spriterom_sel ? {eprom9_D, eprom7_D} : {eprom8_D, eprom6_D};

//Konami 083 custom chip 2/2 - shifts the pixel data from sprite ROMs
k083 u7F
(
	.CK(clk_49m),
	.CEN(cen_6m),
	.LOAD(h_cnt[1:0] == 2'b11),
	.FLIP(sprite_k083_flip),
	.DB0i(spriterom_D[7:0]),
	.DB1i(spriterom_D[15:8]),
	.DSH0(sprite_lut_A[1:0]),
	.DSH1(sprite_lut_A[3:2])
);

//Latch sprite color information, enable for sprite line buffer, sprite 083 flip at every 8 pixels
reg [3:0] sprite_color = 4'd0;
reg sprite_lbuff_en, sprite_k083_flip;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(h_cnt[2:0] == 3'b011) begin
			sprite_color <= sprite_attrib[3:0];
			sprite_lbuff_en <= cs_linebuffer;
			sprite_k083_flip <= sprite_flip;
		end
	end
end

//Assign sprite color information to the upper 4 bits of the sprite lookup PROM
assign sprite_lut_A[7:4] = sprite_color;

//Sprite lookup PROM
wire [7:0] sprite_lut_A;
wire [3:0] sprite_lut_D;
sprite_lut_prom u6F
(
	.ADDR(sprite_lut_A),
	.CLK(clk_49m),
	.DATA(sprite_lut_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(sl_cs_i),
	.WR(ioctl_wr)
);

//Konami 502 custom chip, responsible for generating sprites (sits between sprite ROMs and the sprite line buffer)
wire [7:0] sprite_lbuff_Do;
wire [4:0] sprite_D;
wire sprite_lbuff_sel, sprite_lbuff_dec0, sprite_lbuff_dec1;
k502 u6B
(
	.CK1(clk_49m),
	.CK1_EN(cen_12m),
	.CK2(clk_49m),
	.CK2_EN(cen_6m),
	.LD0(h_cnt[2:0] != 3'b111),
	.H2(h_cnt[1]),
	.H256(h_cnt[8]),
	.SPAL(sprite_lut_D),
	.SPLBi({sprite_lbuff1_D, sprite_lbuff0_D}),
	.SPLBo(sprite_lbuff_Do),
	.OSEL(sprite_lbuff_sel),
	.OLD(sprite_lbuff_dec1),
	.OCLR(sprite_lbuff_dec0),
	.COL(sprite_D)
);

//----------------------------------------------------- Sprite line buffer -----------------------------------------------------//

//Generate load and clear signals for counters generating addresses to sprite line buffer
reg sprite_lbuff0_ld, sprite_lbuff1_ld, sprite_lbuff0_clr, sprite_lbuff1_clr;
always_ff @(posedge clk_49m) begin
	if(h_cnt[1:0] == 2'b11) begin
		if(sprite_lbuff_dec0 && !sprite_lbuff_dec1) begin
			sprite_lbuff0_clr <= 0;
			sprite_lbuff1_clr <= 1;
		end
		else if(!sprite_lbuff_dec0 && sprite_lbuff_dec1) begin
			sprite_lbuff0_clr <= 1;
			sprite_lbuff1_clr <= 0;
		end
		else begin
			sprite_lbuff0_clr <= 0;
			sprite_lbuff1_clr <= 0;
		end
	end
	else begin
		sprite_lbuff0_clr <= 0;
		sprite_lbuff1_clr <= 0;
	end
	if(h_cnt[2:0] == 3'b011) begin
		if(!sprite_lbuff_dec1) begin
			sprite_lbuff0_ld <= 1;
			sprite_lbuff1_ld <= 0;
		end
		else begin
			sprite_lbuff0_ld <= 0;
			sprite_lbuff1_ld <= 1;
		end
	end
	else begin
		sprite_lbuff0_ld <= 0;
		sprite_lbuff1_ld <= 0;
	end
end

//Generate addresses for sprite line buffer
//Bank 0, lower 4 bits
reg [3:0] linebuffer0_l = 4'd0;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(sprite_lbuff0_clr)
			linebuffer0_l <= 4'd0;
		else
			if(sprite_lbuff0_ld)
				linebuffer0_l <= sprite_hpos[3:0];
			else
				linebuffer0_l <= linebuffer0_l + 4'd1;
	end
end
//Bank 0, upper 4 bits
reg [3:0] linebuffer0_h = 4'd0;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(sprite_lbuff0_clr)
			linebuffer0_h <= 4'd0;
		else
			if(sprite_lbuff0_ld)
				linebuffer0_h <= sprite_hpos[7:4];
			else if(linebuffer0_l == 4'hF)
				linebuffer0_h <= linebuffer0_h + 4'd1;
	end
end
wire [7:0] sprite_lbuff0_A = {linebuffer0_h, linebuffer0_l};
//Bank 1, lower 4 bits
reg [3:0] linebuffer1_l = 4'd0;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(sprite_lbuff1_clr)
			linebuffer1_l <= 4'd0;
		else
			if(sprite_lbuff1_ld)
				linebuffer1_l <= sprite_hpos[3:0];
			else
				linebuffer1_l <= linebuffer1_l + 4'd1;
	end
end
//Bank 1, upper 4 bits
reg [3:0] linebuffer1_h = 4'd0;
always_ff @(posedge clk_49m) begin
	if(cen_6m) begin
		if(sprite_lbuff1_clr)
			linebuffer1_h <= 4'd0;
		else
			if(sprite_lbuff1_ld)
				linebuffer1_h <= sprite_hpos[7:4];
			else if(linebuffer1_l == 4'hF)
				linebuffer1_h <= linebuffer1_h + 4'd1;
	end
end
wire [7:0] sprite_lbuff1_A = {linebuffer1_h, linebuffer1_l};

//Generate chip select signals for sprite line buffer
wire cs_sprite_lbuff0 = ~(sprite_lbuff_en & sprite_lbuff_sel);
wire cs_sprite_lbuff1 = ~(sprite_lbuff_en & ~sprite_lbuff_sel);

//Sprite line buffer bank 0
wire [3:0] sprite_lbuff0_D;
spram #(4, 8) u7A
(
	.clk(clk_49m),
	.we(cen_6m & cs_sprite_lbuff0),
	.addr(sprite_lbuff0_A),
	.data(sprite_lbuff_Do[3:0]),
	.q(sprite_lbuff0_D)
);

//Sprite line buffer bank 1
wire [3:0] sprite_lbuff1_D;
spram #(4, 8) u7B
(
	.clk(clk_49m),
	.we(cen_6m & cs_sprite_lbuff1),
	.addr(sprite_lbuff1_A),
	.data(sprite_lbuff_Do[7:4]),
	.q(sprite_lbuff1_D)
);

//----------------------------------------------------- Final video output -----------------------------------------------------//

//Generate HBlank (active high) while the horizontal counter is between 141 and 268
wire hblk = (h_cnt > 140 && h_cnt < 269);

//Multiplex tile and sprite data
wire tile_sprite_sel = (tilemap_en | sprite_D[4]);
wire [3:0] tile_sprite_D = tile_sprite_sel ? tile_D[3:0] : sprite_D[3:0];

//Latch pixel data for color PROM
reg [4:0] pixel_D;
always_ff @(posedge clk_49m) begin
	if(cen_6m)
		pixel_D <= {tile_sprite_sel, tile_sprite_D};
end

//Color PROM
wire [4:0] color_A = pixel_D;
wire [2:0] prom_red, prom_green;
wire [1:0] prom_blue;
color_prom u2A
(
	.ADDR(color_A),
	.CLK(clk_49m),
	.DATA({prom_blue, prom_green, prom_red}),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_49m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp_cs_i),
	.WR(ioctl_wr)
);

//Output video signal from color PROMs, otherwise output black if in HBlank or VBlank
assign red = (hblk | vblk) ? 3'h0 : prom_red;
assign green = (hblk | vblk) ? 3'h0 : prom_green;
assign blue = (hblk | vblk) ? 2'h0 : prom_blue;

endmodule

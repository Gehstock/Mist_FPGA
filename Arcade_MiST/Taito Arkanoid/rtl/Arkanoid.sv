//============================================================================
// 
//  Arkanoid top-level module
//  Copyright (C) 2018, 2020 Ace, Enforcer, Ash Evans (aka ElectronAsh/OzOnE)
//  and Kitrinx (aka Rysha)
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
module Arkanoid
(
	input                reset,
	input                clk_48m,
	input          [1:0] spinner, //1 = left, 0 = right
	input                coin1, coin2,
	input                btn_shot, btn_service, tilt,
	input                btn_1p_start, btn_2p_start,
	
	input          [7:0] dip_sw,
	
	input                ym2149_clk_div,
	input                vol_boost,
	
	//This input serves to select different methods of acheiving 3MHz for the YM2149 depending on whether Arkanoid runs with
	//original or overclocked timings to normalize sync frequencies
	input                overclock,
	
	output signed [15:0] sound,
	
	//Screen centering (alters HSync and VSync timing to reposition the video output)
	input          [3:0] h_center,
	input          [2:0] v_center,
	
	output               video_hsync, video_vsync,
	output               video_csync,
	output               video_vblank, video_hblank,
	output         [3:0] video_r, video_g, video_b,

	input         [24:0] ioctl_addr,
	input          [7:0] ioctl_data,
	input                ioctl_wr,
	
	input                pause,

	input         [15:0] hs_address,
	input          [7:0] hs_data_in,
	output         [7:0] hs_data_out,
	input                hs_write,

	output        [15:0] cpu_rom_addr,
	input          [7:0] cpu_rom_do,

	output        [14:0] gfx_rom_addr,
	input         [31:0] gfx_rom_do
);

//------------------------------------------------- MiSTer data write selector -------------------------------------------------//

//Instantiate MiSTer data write selector to generate write enables for loading ROMs into the FPGA's BRAM
wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i;
wire cp1_cs_i, cp2_cs_i, cp3_cs_i;
selector DLSEL
(
	.ioctl_addr(ioctl_addr),
	.ep1_cs(ep1_cs_i),
	.ep2_cs(ep2_cs_i),
	.ep3_cs(ep3_cs_i),
	.ep4_cs(ep4_cs_i),
	.ep5_cs(ep5_cs_i),
	.cp1_cs(cp1_cs_i),
	.cp2_cs(cp2_cs_i),
	.cp3_cs(cp3_cs_i)
);

//-------------------------------------------------- MiSTer hiscore load/save --------------------------------------------------//

// Setup multipex between CPU Work RAM and Video RAM for hiscore data
wire [7:0] hs_data_out_wram /* synthesis keep */;
wire [7:0] hs_data_out_vram_h /* synthesis keep */;
wire [7:0] hs_data_out_vram_l /* synthesis keep */;
wire       hs_cs_wram /* synthesis keep */;
wire       hs_cs_vram_h /* synthesis keep */;
wire       hs_cs_vram_l /* synthesis keep */;
assign hs_cs_wram = hs_address[15:12] == 4'b1100;
assign hs_cs_vram_l = hs_address[15:12] == 4'b1110 && !hs_address[0];
assign hs_cs_vram_h = hs_address[15:12] == 4'b1110 && hs_address[0];
assign hs_data_out = hs_cs_wram ? hs_data_out_wram : hs_cs_vram_l ? hs_data_out_vram_l : hs_data_out_vram_h;

//------------------------------------------------------- Clock division -------------------------------------------------------//

//Generate 6MHz and 3MHz clock enables
//Also generate an extra clock enable for DC offset removal in the sound section
reg [8:0] div = 9'd0;
always_ff @(posedge clk_48m) begin
	div <= div + 9'd1;
end
wire cen_6m = !div[2:0];
wire n_cen_6m = div[2:0] == 3'b100;
wire n_cen_3m = div[3:0] == 4'b1000;
wire dcrm_cen = !div;

//Generate 3MHz clock enable for YM2149 to maintain consistent sound pitch when overclocked to normalize video timings
//(uses Jotego's fractional clock divider from JTFRAME)
wire n_cen_3m_adjust;
jtframe_frac_cen sound_cen
(
	.clk(clk_48m),
	.n(10'd31),
	.m(10'd503),
	.cenb({1'bZ, n_cen_3m_adjust})
);

//Edge detection for signals other than clocks used to latch data
reg old_hcnt0, old_hcnt2, old_hcnt3, old_vcnt4, old_nvblank, old_spinner_clk;
always_ff @(posedge clk_48m) begin
	old_hcnt0 <= h_cnt[0];
	old_hcnt2 <= h_cnt[2];
	old_hcnt3 <= h_cnt[3];
	old_vcnt4 <= v_cnt[4];
	old_nvblank <= n_vblank;
	old_spinner_clk <= spin_cnt_clk;
end

//------------------------------------------------------------ CPUs ------------------------------------------------------------//

wire z80_n_m1, z80_n_mreq, z80_n_iorq, z80_n_rd, z80_n_wr;
wire [15:0] z80_A;
wire [7:0] z80_Dout, z80_ram_D;
//Main CPU - Zilog Z80 (uses T80s variant of the T80 soft core)
//NMI, BUSRQ unused, pull high
T80s IC12
(
	.RESET_n(z80_n_reset),
	.CLK(clk_48m),
	//.CEN_p(cen_6m & ~pause),
	.CEN(n_cen_6m & ~pause),
	.WAIT_n(z80_n_wait),
	.INT_n(z80_n_int),
	.NMI_n(1),
	.BUSRQ_n(1),
	.MREQ_n(z80_n_mreq),
	.IORQ_n(z80_n_iorq),
	.RD_n(z80_n_rd),
	.WR_n(z80_n_wr),
	.A(z80_A),
	.DI(z80_Din),
	.DO(z80_Dout)
);
//Address decoding for data inputs to Z80
wire cs_rom1 = (~z80_A[15] & ~z80_n_rd);
wire cs_rom2 = (z80_A[15:14] == 2'b10 & ~z80_n_rd);
wire cs_z80_ram = z80_A[15:12] == 4'b1100;
wire cs_ym2149 = (z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b00);
wire cs_buttons2 = (z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b01 & ~z80_n_rd);
wire cs_buttons1 = (z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b10 & ~z80_n_rd);
wire cs_spinner = (z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b11 & ~z80_n_rd);
wire cs_mainlatch = (~z80_n_wr & z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b01);
wire cs_vram_l = h_cnt[0] ? 1'b1 : (z80_A[15:12] == 4'b1110 & ~z80_A[0] & ~z80_n_mreq);
wire cs_vram_h = h_cnt[0] ? 1'b1 : (z80_A[15:12] == 4'b1110 & z80_A[0] & ~z80_n_mreq);
//Multiplex data inputs to Z80
wire [7:0] z80_Din = cs_rom1                                ? eprom1_D:
                     cs_rom2                                ? eprom2_D:
                     (cs_z80_ram & ~z80_n_rd)               ? z80_ram_D:
                     (~ym2149_bdir & z80_A[0] & ym2149_bc1) ? ym2149_data:
                     (vram_oe & cs_vram_h & vram_rd)        ? vram_D[7:0]:
                     (vram_oe & cs_vram_l & vram_rd)        ? vram_D[15:8]:
                     cs_buttons2                            ? buttons2:
                     cs_buttons1                            ? buttons1:
                     cs_spinner                             ? spinner_D:
                     8'hFF;

//Game ROMs
assign cpu_rom_addr = z80_A[15] ? {1'b1, eprom2_A14, z80_A[13:0]} : {1'b0, z80_A[14:0]};
`ifdef EXT_ROM
wire [7:0] eprom1_D = cpu_rom_do;
wire [7:0] eprom2_D = cpu_rom_do;
`else
//ROM 1/2
wire [7:0] eprom1_D;
eprom_1 IC17
(
	.ADDR(z80_A[14:0]),
	.CLK(clk_48m),
	.DATA(eprom1_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep1_cs_i),
	.WR(ioctl_wr)
);
//ROM 2/2
wire [7:0] eprom2_D;
eprom_2 IC16
(
	.ADDR({eprom2_A14, z80_A[13:0]}),
	.CLK(clk_48m),
	.DATA(eprom2_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep2_cs_i),
	.WR(ioctl_wr)
);
`endif

//Z80 work RAM
dpram_dc #(.widthad_a(11)) IC15
(
	.clock_a(clk_48m),
	.address_a(z80_A[10:0]),
	.data_a(z80_Dout),
	.q_a(z80_ram_D),
	.wren_a(cs_z80_ram & ~z80_n_wr),

	.clock_b(clk_48m),
	.address_b(hs_address[10:0]),
	.data_b(hs_data_in),
	.q_b(hs_data_out_wram),
	.wren_b(hs_write & hs_cs_wram)
);

//Watchdog - counts 128 VBlanks before triggering a reset if Arkanoid encounters a run-time issue
wire watchdog_clr = (z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b10 & ~z80_n_wr) | pause;
reg [7:0] watchdog_timer = 8'd0;
always_ff @(posedge clk_48m) begin
	if(watchdog_clr)
		watchdog_timer <= 8'd0;
	else if(old_nvblank && !n_vblank)
		watchdog_timer <= watchdog_timer + 8'd1;
end

//AND the reset input to the Z80 with the watchdog output
wire z80_n_reset = reset & ~watchdog_timer[7];

//Generate Z80 IRQ on the rising edge of the active-low VBlank
reg z80_n_int = 1;
always_ff @(posedge clk_48m) begin
	if(!z80_n_iorq)
		z80_n_int <= 1;
	else if(!old_nvblank && n_vblank)
		z80_n_int <= 0;
end

//Generate Z80 WAIT signal
wire wait_trigger = (z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b00);
reg n_wait = 1;
reg wait_clear;
always_ff @(posedge clk_48m) begin
	if(wait_clear)
		n_wait <= 1;
	else if(cen_6m) begin
		n_wait <= ~wait_trigger;
		wait_clear <= ~n_wait;
	end
end
wire z80_n_wait = (~(z80_A[15:12] == 4'b1110 & ~z80_n_mreq) | ~h_cnt[0]) & n_wait;

//Main latch
reg vflip, hflip, spinner_sel, mcu_sel, prom_bank, gfxrom_bank, eprom2_bank;
always_ff @(posedge clk_48m) begin
	if(!z80_n_reset) begin
		mcu_sel <= 0;
		prom_bank <= 0;
		gfxrom_bank <= 0;
		eprom2_bank <= 0;
		spinner_sel <= 0;
		vflip <= 0;
		hflip <= 0;
	end
	else if(n_cen_6m && cs_mainlatch) begin
		mcu_sel <= z80_Dout[7];
		prom_bank <= z80_Dout[6];
		gfxrom_bank <= z80_Dout[5];
		eprom2_bank <= z80_Dout[4];
		spinner_sel <= z80_Dout[2];
		vflip <= z80_Dout[1];
		hflip <= z80_Dout[0];
	end
end
assign gfxrom_A[14] = gfxrom_bank;
wire eprom2_A14 = eprom2_bank;

//------------------------------------------------------------ MCUs ------------------------------------------------------------//

//Arkanoid uses an MC68705 microcontroller at IC14 on the PCB for protection and for reading spinner inputs - this MCU is
//currently unimplemented
wire mcu_data_latch = (z80_A[15:12] == 4'b1101 & z80_A[4:3] == 2'b11 & ~z80_n_wr);

//--------------------------------------------------- Controls & DIP switches --------------------------------------------------//

//Reverse DIP switch order
wire [7:0] dipsw = {dip_sw[0], dip_sw[1], dip_sw[2], dip_sw[3], dip_sw[4], dip_sw[5], dip_sw[6], dip_sw[7]};

//Group and multiplex button inputs
wire [7:0] buttons1 = {5'b11111, btn_shot, 1'b1, btn_shot};
wire [7:0] buttons2 = z80_A[2] ? {2'b01, coin2, coin1, tilt, btn_service, btn_2p_start, btn_1p_start} : 8'hFF;

//Invert spinner inputs
wire [1:0] n_spinner1 = {~spinner[1], ~spinner[0]};
wire [1:0] n_spinner2 = {~spinner[1], ~spinner[0]};

//Select which spinner inputs to send to the spinner input counters
wire spin_cnt_u_d = spinner_sel ? n_spinner1[1] : n_spinner2[1];
wire spin_cnt_clk = spinner_sel ? n_spinner2[0] : n_spinner1[0];

//Spinner input counters
wire spin_cnt_en = (z80_A[2] | ~cs_buttons2);
reg [7:0] spin_cnt = 8'd0;
always_ff @(posedge clk_48m) begin
	if(!old_spinner_clk && spin_cnt_clk)
		if(spin_cnt_en)
			spin_cnt <= spin_cnt_u_d ? (spin_cnt + 8'd1) : (spin_cnt - 8'd1);
end

//Latch spinner counter values to the Z80 on the rising edge of horizontal counter bit 0 - this is normally done through the MCU,
//though bootlegs without an MCU directly latch the spinner counters to the Z80 as a workaround
reg [7:0] spinner_D = 8'd0;
always_ff @(posedge clk_48m) begin
	if(!old_hcnt0 && h_cnt[0])
		spinner_D <= spin_cnt;
end

//-------------------------------------------------------- Video timing --------------------------------------------------------//

//Arkanoid's horizontal and vertical counters are 9 bits wide - delcare them here
reg [8:0] h_cnt = 9'd0;
reg [8:0] v_cnt = 9'd0;

//Define the range of values the vertical counter will count between based on the additional vertical center signal
//Shift the screen up by 1 line when horizontal centering shifts the screen left
wire [8:0] vcnt_start = 9'd248 - v_center;
wire [8:0] vcnt_end = 9'd511 - v_center;

//The horizontal and vertical counters behave as follows at every rising edge of the pixel clock:
//-Start at 0, then count to 511
//-Horizontal counter resets to 128 for a total of 384 horizontal lines
//-Vertical counter resets to 248 for a total of 264 vertical lines (adjustable with added vertical center signal)
//-Vertical counter increments when the horizontal counter equals 128
//Model this behavior here
always_ff @(posedge clk_48m) begin
	if(n_cen_6m) begin
		case(h_cnt)
			128: begin
				h_cnt <= h_cnt + 9'd1;
				case(v_cnt)
					vcnt_end: v_cnt <= vcnt_start;
					default: v_cnt <= v_cnt + 9'd1;
				endcase
			end
			511: h_cnt <= 9'd128;
			default: h_cnt <= h_cnt + 9'd1;
		endcase
	end
end

//Generate h256 by latching bit 8 of the horizontal counter on the rising edge of bit 3 of that same counter
reg h256;
always_ff @(posedge clk_48m) begin
	if(!old_hcnt3 && h_cnt[3])
		h256 <= h_cnt[8];
end

//XOR horizontal counter bits [7:3] with horizontal flip bit
wire [7:3] hcnt_x = h_cnt[7:3] ^ {5{hflip}};

//XOR vertical counter bits with vertical flip bit
wire [8:0] vcnt_x = v_cnt ^ {9{vflip}};

//------------------------------------------------------------ VRAM ------------------------------------------------------------//

//Multiplex VRAM address lines based on horizontal counter bits 8 and 0
wire [10:0] vram_A = !h_cnt[0] ? z80_A[11:1]:
                     h_cnt[8]  ? {1'b0, vcnt_x[7:3], hcnt_x[7:3]}:
                     {1'b1, 5'b00000, h_cnt[6:2]};

//Multiplex VRAM write, output and chip enable signals based on the state of horizontal counter bit 0
wire vram_we = n_cen_6m & (h_cnt[0] ? 1'b0 : z80_n_rd);
wire vram_oe = h_cnt[0] ? 1'b1 : ~z80_n_rd;

//Generate active-high VRAM read enable
wire vram_rd = ~z80_n_rd & (z80_A[15:12] == 4'b1110 & ~z80_n_mreq);

//VRAM
//Upper 8 bits
wire [15:0] vram_D;
dpram_dc #(.widthad_a(11)) IC57
(
	.clock_a(clk_48m),
	.address_a(vram_A),
	.data_a(z80_Dout),
	.q_a(vram_D[15:8]),
	.wren_a(cs_vram_l & vram_we),

	.clock_b(clk_48m),
	.address_b(hs_address[11:1]),
	.data_b(hs_data_in),
	.q_b(hs_data_out_vram_l),
	.wren_b(hs_write & hs_cs_vram_l)
);
//Lower 8 bits
dpram_dc #(.widthad_a(11)) IC58
(
	.clock_a(clk_48m),
	.address_a(vram_A),
	.data_a(z80_Dout),
	.q_a(vram_D[7:0]),
	.wren_a(cs_vram_h & vram_we),

	.clock_b(clk_48m),
	.address_b(hs_address[11:1]),
	.data_b(hs_data_in),
	.q_b(hs_data_out_vram_h),
	.wren_b(hs_write & hs_cs_vram_h)
);

//-------------------------------------------------------- Tilemap layer -------------------------------------------------------//

//Latch tilemap data from VRAM on the rising edge of horizontal counter bit 2
reg [7:0] tiles_D = 8'd0;
always_ff @(posedge clk_48m) begin
	if(!old_hcnt2 && h_cnt[2])
		tiles_D <= {vram_D[6], vram_D[4:3], vram_D[1], vram_D[2], vram_D[0], vram_D[7], vram_D[5]};
end

//Sum tilemap data with vertical counter bits [7:0]
wire [7:0] sr = {tiles_D[1], tiles_D[7], tiles_D[0], tiles_D[6:5], tiles_D[3], tiles_D[4], tiles_D[2]} + vcnt_x[7:0];

//-------------------------------------------------------- Sprite layer --------------------------------------------------------//

//Latch horizontal position and tilemap data from VRAM on the rising edge of horizontal counter bit 2
reg [7:0] h_pos = 8'd0;
always_ff @(posedge clk_48m) begin
	if(!old_hcnt2 && h_cnt[2])
		h_pos <= {vram_D[8], vram_D[15], vram_D[10], vram_D[13], vram_D[14], vram_D[12:11], vram_D[9]};
end

//Latch sprite data on the falling edge of horizontal counter bit 2
reg [4:0] sprites_D = 5'd0;
always_ff @(posedge clk_48m) begin
	if(old_hcnt2 && !h_cnt[2])
		sprites_D <= {vram_D[11], vram_D[14:12], vram_D[15]};
end

//Multiplex sprite horizontal position based on bit 8 of the horizontal counter
wire [7:0] sprite_hpos = h_cnt[8] ? {8{hflip}} : {h_pos[3], h_pos[6], h_pos[4], h_pos[2], h_pos[5], h_pos[1], h_pos[0], h_pos[7]};

//Generate sprite RAM addresses
wire [8:0] spriteram_A;
reg [7:0] spriteram_cnt = 8'd0;
wire spriteram_u_d = ~(hflip & h256);
wire n_spriteram_cnt_load = shift_ld | (h_cnt[8] & h256);
always_ff @(posedge clk_48m) begin
	if(n_cen_6m) begin
		if(!n_spriteram_cnt_load)
			spriteram_cnt <= {sprite_hpos[6], sprite_hpos[7], sprite_hpos[5:4], sprite_hpos[2], sprite_hpos[3], sprite_hpos[1:0]};
		else
			spriteram_cnt <= spriteram_u_d ? (spriteram_cnt + 4'd1) : (spriteram_cnt - 4'd1);
	end
end
assign spriteram_A[8] = ~h256 & ~(sprite_pixel1 | sprite_pixel2 | sprite_pixel3);
assign spriteram_A[7:0] = spriteram_cnt;

//Latch sprite pixel signal on the falling edge of horizontal counter bit 2 and generate individual sprite pixel signals for each
//shifted graphics ROM data
reg n_inre;
always_ff @(posedge clk_48m) begin
	if(old_hcnt0 && !h_cnt[0]) begin
		if(h_cnt[8])
			n_inre <= 1;
		else
			n_inre <= ~(&sr[7:4]);
	end
end
reg sprite_pixel;
always_ff @(posedge clk_48m) begin
	if(old_hcnt2 && !h_cnt[2])
		sprite_pixel <= ~n_inre;
end
wire sprite_pixel1 = sprite_pixel & eprom3_shift;
wire sprite_pixel2 = sprite_pixel & eprom5_shift;
wire sprite_pixel3 = sprite_pixel & eprom4_shift;

//Assign sprite RAM data input
wire [7:0] spriteram_Din = {sprites_D[0], sprites_D[3:1], sprites_D[4], sprite_pixel2, sprite_pixel3, sprite_pixel1};

//Sprite RAM (the original PCB uses a 2KB RAM chip with 11 address lines, but only 9 are used, limiting its capacity to 512 bytes)
wire [7:0] spriteram_Dout;
spram #(8, 9) IC51
(
	.clk(clk_48m),
	.we(n_cen_6m),
	.addr(spriteram_A),
	.data(spriteram_Din),
	.q(spriteram_Dout)
);

//-------------------------------------------------------- Graphics ROMs -------------------------------------------------------//

//Latch data from VRAM to be used as addresses for the graphics ROMs on the falling edge of horizontal counter bit 0 and
//multiplex based on horizontal counter bit 8
wire [14:0] gfxrom_A;
reg [13:0] gfx_address = 14'd0;
always_ff @(posedge clk_48m) begin
	if(old_hcnt0 && !h_cnt[0]) begin
		if(h_cnt[8])
			gfx_address <= {vram_D[10:0], vcnt_x[2:0]};
		else
			gfx_address <= {vram_D[9:0], sr[3:0]};
	end
end
assign gfxrom_A[13:0] = gfx_address;

assign gfx_rom_addr = gfxrom_A;

//Graphics ROMs
`ifdef EXT_ROM
wire [7:0] eprom3_D = gfx_rom_do[7:0];
wire [7:0] eprom4_D = gfx_rom_do[15:8];
wire [7:0] eprom5_D = gfx_rom_do[23:16];
`else
//ROM 1/3
wire [7:0] eprom3_D;
eprom_3 IC64
(
	.ADDR(gfxrom_A),
	.CLK(clk_48m),
	.DATA(eprom3_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep3_cs_i),
	.WR(ioctl_wr)
);
//ROM 2/3
wire [7:0] eprom4_D;
eprom_4 IC63
(
	.ADDR(gfxrom_A),
	.CLK(clk_48m),
	.DATA(eprom4_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep4_cs_i),
	.WR(ioctl_wr)
);

//ROM 3/3
wire [7:0] eprom5_D;
eprom_5 IC62
(
	.ADDR(gfxrom_A),
	.CLK(clk_48m),
	.DATA(eprom5_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep5_cs_i),
	.WR(ioctl_wr)
);
`endif

//Fujitsu MB112S146 - Custom bit shifter used by Arkanoid to left/right shift graphics data from the graphics ROMs
//Instantiate two instances of this chip to shift graphics data from the 3 graphics ROMs
wire shift_ld = ~(&h_cnt[2:0]);
wire flip_sel = hflip & h256;
wire eprom5_shift;
mb112s146 IC77
(
	.clk(clk_48m),
	.cen(n_cen_6m),
	.n_clr(1),
	.shift_ld(shift_ld),
	.sel(flip_sel),
	.s_in(2'b00),
	.d2_in(8'h00), //This shift register is unused, pull inputs low
	.d1_in(eprom5_D),
	.shift_out({1'bZ, eprom5_shift}) //Shift register 1 unused
);
wire eprom3_shift, eprom4_shift;
mb112s146 IC78
(
	.clk(clk_48m),
	.cen(n_cen_6m),
	.n_clr(1),
	.shift_ld(shift_ld),
	.sel(flip_sel),
	.s_in(2'b00),
	.d2_in(eprom3_D),
	.d1_in(eprom4_D),
	.shift_out({eprom3_shift, eprom4_shift})
);

//Latch tilemap and sprite data for color PROMs
reg [7:0] tiles = 8'd0; 
reg [7:0] sprites = 8'd0;
always_ff @(posedge clk_48m) begin
	if(n_cen_6m) begin
		tiles <= {eprom3_shift, eprom5_shift, sprites_D[4], eprom4_shift, sprites_D[2], sprites_D[0], sprites_D[3], sprites_D[1]};
		sprites <= {spriteram_Dout[3], spriteram_Dout[0], spriteram_Dout[1], spriteram_Dout[6], spriteram_Dout[2], spriteram_Dout[5:4], spriteram_Dout[7]};
	end
end

//--------------------------------------------------------- Sound chips --------------------------------------------------------//

//Generate BDIR and BCI inputs for YM2149
wire ym2149_bdir = (~z80_n_wr & cs_ym2149);
wire ym2149_bc1 = (~z80_n_rd & cs_ym2149);

//Select whether to use a fractional or integer clock divider for the YM2149 to maintain consistent sound pitch at both original
//and overclocked timings
wire cen_sound = overclock ? n_cen_3m_adjust : n_cen_3m;

//Sound chip - Yamaha YM2149 (implementation by MikeJ)
//Implements volume table to simulate mixing of the three analog outputs directly at the chip as per the original Arkanoid PCB
wire [7:0] ym2149_data;
ym2149 #(.MIXER_VOLTABLE(1'b1)) IC2
(
	.I_DA(z80_Dout),
	.O_DA(ym2149_data),
	.I_A9_L(0),
	.I_A8(1),
	.I_BDIR(ym2149_bdir),
	.I_BC2(z80_A[0]),
	.I_BC1(ym2149_bc1),
	.I_SEL_L(ym2149_clk_div),
	.O_AUDIO_L(sound_raw),
	.I_IOB(dipsw),
	.ENA(cen_sound),
	.RESET_L(z80_n_reset),
	.CLK(clk_48m)
);

//----------------------------------------------------- Final video output -----------------------------------------------------//

//Multiplex tilemaps and sprites to color PROM addresses
wire prom_A_sel = ~(sprites[6] | sprites[5] | sprites[3]);
reg [7:0] prom_A = 8'd0;
always_ff @(posedge clk_48m) begin
	if(cen_6m) begin
		if(prom_A_sel)
			prom_A <= {tiles[2], tiles[1], tiles[3], tiles[0], tiles[5], tiles[6], tiles[4], tiles[7]};
		else
			prom_A <= {sprites[0], sprites[4], sprites[2], sprites[1], sprites[7], sprites[3], sprites[5], sprites[6]};
	end
end

//Arkanoid generates its final video output by latching data from 3 LUT PROMs, one per color, for 12-bit RGB with 4 bits per color
//Red color PROM
wire [3:0] prom1_data;
color_prom_1 IC24
(
	.ADDR({prom_bank, prom_A}),
	.CLK(clk_48m),
	.DATA(prom1_data),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp1_cs_i),
	.WR(ioctl_wr)
);
//Green color PROM
wire [3:0] prom2_data;
color_prom_2 IC23
(
	.ADDR({prom_bank, prom_A}),
	.CLK(clk_48m),
	.DATA(prom2_data),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp2_cs_i),
	.WR(ioctl_wr)
);
//Blue color PROM
wire [3:0] prom3_data;
color_prom_3 IC22
(
	.ADDR({prom_bank, prom_A}),
	.CLK(clk_48m),
	.DATA(prom3_data),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_48m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp3_cs_i),
	.WR(ioctl_wr)
);

//Generate active-low VBlank (this VBlank is imperfect - use as part of the video output logic to recreate the 1-pixel upward
//vertical shift on the last 10 vertical lines on the right side of the screen)
reg n_vblank;
always_ff @(posedge clk_48m) begin
	if(!old_vcnt4 && v_cnt[4])
		n_vblank <= ~(&v_cnt[7:5]);
end

//Latch data from color PROMs for video output
reg [3:0] red, green, blue;
always_ff @(posedge clk_48m) begin
	if(!n_vblank || video_hblank) begin
		red <= 4'd0;
		green <= 4'd0;
		blue <= 4'd0;
	end
	else if(cen_6m) begin
		red <= prom1_data;
		green <= prom2_data;
		blue <= prom3_data;
	end
end
assign video_r = red;
assign video_g = green;
assign video_b = blue;

//Video sync & blanking outputs (HSync and blanks active-high, VSync active-low)
assign video_hsync = ~(h_center[3] ? (~h_cnt[8] && h_cnt[6:0] > (7'd54 - h_center[2:0]) && h_cnt[6:0] < (7'd87 - h_center[2:0])):
                                   (~h_cnt[8] && h_cnt[6:0] > (7'd47 - h_center[2:0]) && h_cnt[6:0] < (7'd80 - h_center[2:0])));
assign video_vsync = ~(v_cnt >= vcnt_start && v_cnt <= vcnt_start + 9'd7);
assign video_csync = video_hsync ^ video_vsync;
assign video_vblank = (v_cnt < 271 || v_cnt > 495);
assign video_hblank = (h_cnt > 137 && h_cnt < 266);

//----------------------------------------------------- Final audio output -----------------------------------------------------//

//Remove DC offset from audio output (uses jt49_dcrm2 from JT49 by Jotego)
wire [9:0] sound_raw;

wire signed [15:0] sound_dcrm;
jt49_dcrm2 #(16) dcrm
(
	.clk(clk_48m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({5'd0, sound_raw}),
	.dout(sound_dcrm)
);

//Low-pass filter the audio output (cutoff frequency ~16.7KHz)
wire signed [15:0] sound_filtered;

arkanoid_lpf lpf
(
	.clk(clk_48m),
	.reset(~reset),
	.in(sound_dcrm),
	.out(sound_filtered)
);

//Apply gain to final audio output (mute when the game is paused)
assign sound = pause ? 16'd0 : vol_boost ? (sound_filtered <<< 16'd5) : (sound_filtered <<< 16'd4);

endmodule

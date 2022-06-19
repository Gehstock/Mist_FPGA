module Gamate_MiST(
	output        LED,
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        AUDIO_L,
	output        AUDIO_R,
	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         CONF_DATA0,
	input         CLOCK_27,
	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE

);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"Gamate;;",
	"F1,bin,Load Cartridge;",
//	"F2,sgbgbp,Load Palette;",
	"O7,Custom Palette,Off,On;",
	"O8,BIOS,UMC,BIT;",
	"O4,Flickerblend,On,Off;",
	"O23,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Drop Shadows,On,Off;",

	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign LED = ~ioctl_downl;
wire clk_sys, clk_ram, pll_locked;


pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_ram),//35.464000 MHz
	.c1(clk_sys), //17.732000 MHz
	.locked(pll_locked)
);

	
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [15:0] joystick_0;
wire  [15:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_wait;
wire        hs, vs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire  [8:0] r,g,b;
wire  [15:0] audio_l, audio_r;


data_io data_io(
	.clk_sys       ( clk_ram      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);


user_io #(.STRLEN($size(CONF_STR)>>3))user_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

mist_video #(.COLOR_DEPTH(6),.SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
//	.R(blankn ? r[8:3] : 0),
//	.G(blankn ? g[8:3] : 0),
//	.B(blankn ? b[8:3] : 0),
	
	.R(blankn ? r[7:2] : 0),
	.G(blankn ? g[7:2] : 0),
	.B(blankn ? b[7:2] : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b0),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[3:2]),
	.ypbpr(ypbpr)
	);
	
dac #(16) dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);

dac #(16) dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_r),
	.dac_o(AUDIO_R)
	);

	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

wire reset = status[0] | buttons[1] | ioctl_downl | rom_download;

gamate_top core(
	.clk				(clk_sys),
	.reset			(reset),
	.biostype		(status[8]),
	.joystick		({m_coin1,m_tilt, m_fireB, m_fireA, m_up, m_down, m_left, m_right}),
	.cart_dout		(rom_dout),
	.rom_size		(rom_mask),
	.rom_addr		(rom_addr),
	.rom_read		(rom_cs),
	.audio_right	(audio_l),
	.audio_left		(audio_r),
	.hsync			(hs),
	.hblank			(hb),
	.ce_pix        (ce_pix),
	.vsync			(vs),
	.vblank			(vb),
	.pixel			(pixel)
);


sdram cart_rom
(
	.SDRAM_DQ       (SDRAM_DQ),
	.SDRAM_A        (SDRAM_A),
	.SDRAM_DQML     (SDRAM_DQML),
	.SDRAM_DQMH     (SDRAM_DQMH),
	.SDRAM_BA       (SDRAM_BA),
	.SDRAM_nCS      (SDRAM_nCS),
	.SDRAM_nWE      (SDRAM_nWE),
	.SDRAM_nRAS     (SDRAM_nRAS),
	.SDRAM_nCAS     (SDRAM_nCAS),
	.SDRAM_CLK      (SDRAM_CLK),
	.SDRAM_CKE      (SDRAM_CKE),

	.init           (!pll_locked),
	.clk            (clk_ram),

	.ch0_addr       (rom_download ? ioctl_addr : (rom_addr & rom_mask)),
	.ch0_rd         (rom_cs && ~rom_download),
	.ch0_wr         (rom_download & ioctl_wr),
	.ch0_din        (ioctl_dout),
	.ch0_dout       (rom_dout),
	.ch0_busy       (cart_busy)
);

logic [8:0] red, green, blue, rt, gt, bt;
wire rom_download = ((~|ioctl_index[5:0] && ioctl_index[7:6] == 1) || ioctl_index[5:0] == 1) && ioctl_downl;
//wire palette_download = (ioctl_index[5:0] == 3) && ioctl_downl;
wire ce_pix;
wire [7:0] rom_dout, bios_dout;
wire [19:0] rom_addr;
wire [1:0] last_pixel, pixel, prev_pixel;
wire rom_cs;
reg [14:0] vbuffer_addr;
wire cart_busy;
reg [21:0] rom_mask = 19'h7FFFF;

assign ioctl_wait = cart_busy & rom_download;

//logic [127:0] user_palette = 128'hF7BEF7E7_86867733_E72C2C96_2020_2020;   
logic [127:0] user_palette = 	128'hF7BEF7_E78686_7733E7_2C2C96_2020_2020;   
wire [127:0] default_palette = 128'h828214_517356_305A5F_1A3B49_0000_0000;

logic [2:0][7:0] palette[4];

assign palette[0] = status[7] ? user_palette[127:104] : default_palette[127:104];
assign palette[1] = status[7] ? user_palette[103:80]  : default_palette[103:80];
assign palette[2] = status[7] ? user_palette[79:56]   : default_palette[79:56];
assign palette[3] = status[7] ? user_palette[55:32]   : default_palette[55:32];


reg [149:0][1:0] shadow_buffer;
reg [7:0] hpos;
reg [1:0] sc;

wire shadow_en = ~status[5] && ~|last_pixel && |sc;
assign r   = shadow_en ? ((rt >> 1) + (rt >> 2) + (~sc[1] ? (rt >> 3) : 1'd0) + (~sc[0] ? (rt >> 4) : 1'd0)) : rt;
assign g = shadow_en ? ((gt >> 1) + (gt >> 2) + (~sc[1] ? (gt >> 3) : 1'd0) + (~sc[0] ? (gt >> 4) : 1'd0)) : gt;
assign b  = shadow_en ? ((bt >> 1) + (bt >> 2) + (~sc[1] ? (bt >> 3) : 1'd0) + (~sc[0] ? (bt >> 4) : 1'd0)) : bt;



always_ff @(posedge clk_sys) begin
	if (ce_pix) begin
		if (~hb)
			hpos <= hpos + 1'd1;
		else
			hpos <= 0;

		shadow_buffer[hpos] <= vb ? 2'b00 : pixel;
		sc <= shadow_buffer[hpos];
		
		rt <= ~status[4] ? (({1'b0, palette[pixel][2]} + palette[prev_pixel][2]) >> 1'd1) : palette[pixel][2];
		gt <= ~status[4] ? (({1'b0, palette[pixel][1]} + palette[prev_pixel][1]) >> 1'd1) : palette[pixel][1];
		bt <= ~status[4] ? (({1'b0, palette[pixel][0]} + palette[prev_pixel][0]) >> 1'd1) : palette[pixel][0];
		last_pixel <= pixel;

		if (~vb && ~hb)
			vbuffer_addr <= vbuffer_addr + 1'd1;

		if (vs)
			vbuffer_addr <= 0;
	end
end

dpram #(.data_width(2), .addr_width(15)) vbuffer (
	.clock      (clk_sys),

	.address_a  (vbuffer_addr - 1'd1),
	.data_a     (last_pixel),
	.wren_a     (~vb && ~hb && ce_pix),

	.address_b  (vbuffer_addr),
	.q_b        (prev_pixel)
);

always @(posedge clk_sys) begin
	if (rom_download && ioctl_wr)
		rom_mask <= ioctl_addr[18:0];
//	if (palette_download)
//		user_palette[{~ioctl_addr[3:0], 3'b000}+:8] <= ioctl_dout;
end



endmodule 
module Jackal_MiST (
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
	"JACKAL;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O7,Service,Off,On;",
	"O1,Rotary speed,Normal,Fast;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire        service = status[7];
wire        rotary_speed = status[1];

wire  [1:0] orientation = 2'b11;
wire [23:0] dip_sw = ~status[31:8];

wire  [1:0] is_bootleg = core_mod[1:0];

assign 		LED = ~ioctl_downl;
assign 		SDRAM_CLK = clock_98;
assign 		SDRAM_CKE = 1;

wire clock_98, clock_49, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_98),
	.c1(clock_49),//49.152MHz
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;
wire [15:0] audio_l, audio_r;
wire        hs, vs, cs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire  [4:0] r, g, b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire [16:0] main_rom_addr;
wire [15:0] main_rom_do;
wire [14:0] sub_rom_addr;
wire [15:0] sub_rom_do;
wire [15:0] ch1_addr;
wire [15:0] ch1_do;
wire [15:0] ch2_addr;
wire [15:0] ch2_do;
wire        sp1_req, sp1_ack;
wire [15:0] sp1_addr;
wire [15:0] sp1_do;
wire        sp2_req, sp2_ack;
wire [15:0] sp2_addr;
wire [15:0] sp2_do;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clock_98     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);
wire [24:0] bg_ioctl_addr = ioctl_addr - 18'h20000;

reg port1_req, port2_req;
sdram #(98) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_98     ),

	// port1 for CPUs
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'h0000 : main_rom_addr[16:1] ),
	.cpu1_q        ( main_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'h0000 : sub_rom_addr[14:1] + 16'hc000 ),
	.cpu2_q        ( sub_rom_do ),

	// port2 for graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {bg_ioctl_addr[23:18], bg_ioctl_addr[16:0]} ), // merge gfx roms to 16-bit wide words
	.port2_ds      ( {~bg_ioctl_addr[17], bg_ioctl_addr[17]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.ch1_addr      ( ioctl_downl ? 16'hffff : ch1_addr ),
	.ch1_q         ( ch1_do ),
	.ch2_addr      ( ioctl_downl ? 16'hffff : ch2_addr ),
	.ch2_q         ( ch2_do ),
	.sp1_req       ( sp1_req ),
	.sp1_ack       ( sp1_ack ),
	.sp1_addr      ( ioctl_downl ? 16'hffff : sp1_addr ),
	.sp1_q         ( sp1_do ),
	.sp2_req       ( sp2_req ),
	.sp2_ack       ( sp2_ack ),
	.sp2_addr      ( ioctl_downl ? 16'hffff : sp2_addr ),
	.sp2_q         ( sp2_do )
);

// ROM download controller
always @(posedge clock_98) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_49) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

Jackal Jackal(
	.reset(~reset),
	.clk_49m(clock_49), 
	.coins({~m_coin2,~m_coin1}),
	.btn_start({~m_two_players,~m_one_player}),
	.p1_joystick({~m_down, ~m_up, ~m_right, ~m_left}),
	.p2_joystick({~m_down2, ~m_up2, ~m_right2, ~m_left2}),
	.p1_rotary(~p1_rotary),
	.p2_rotary(~p2_rotary),
	.p1_buttons({~m_fireB, ~m_fireA}),
	.p2_buttons({~m_fire2B, ~m_fire2A}),
	.btn_service(~service),
	.dipsw(dip_sw),
	.is_bootleg(is_bootleg),
	.video_hsync(hs), 
	.video_vsync(vs), 
	.video_csync(cs),
	.video_hblank(hb), 
	.video_vblank(vb),
	.video_r(r), 
	.video_g(g), 
	.video_b(b),
	.sound_l(audio_l),
	.sound_r(audio_r),
	.pause(1'b1),
	.ioctl_clk(clock_98),
	.ioctl_addr(ioctl_addr),
	.ioctl_data(ioctl_dout),
	.ioctl_wr(ioctl_wr),

	.main_cpu_rom_addr(main_rom_addr),
	.main_cpu_rom_do(main_rom_addr[0] ? main_rom_do[15:8] : main_rom_do[7:0]),
	.sub_cpu_rom_addr(sub_rom_addr),
	.sub_cpu_rom_do(sub_rom_addr[0] ? sub_rom_do[15:8] : sub_rom_do[7:0]),
	.char1_rom_addr(ch1_addr),
	.char1_rom_do(ch1_do),
	.char2_rom_addr(ch2_addr),
	.char2_rom_do(ch2_do),
	.sp1_req(sp1_req),
	.sp1_ack(sp1_ack),
	.sp1_rom_addr(sp1_addr),
	.sp1_rom_do(sp1_do),
	.sp2_req(sp2_req),
	.sp2_ack(sp2_ack),
	.sp2_rom_addr(sp2_addr),
	.sp2_rom_do(sp2_do)
);

mist_video #(.COLOR_DEPTH(5), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_49         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 0                ),
	.rotate         ( { orientation[1], rotate } ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);
	
user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clock_49       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(.C_bits(16))dac_l(
	.clk_i(clock_49),
	.res_n_i(1'b1),
	.dac_i({~audio_l[15], audio_l[14:0]}),
	.dac_o(AUDIO_L)
	);

dac #(.C_bits(16))dac_r(
	.clk_i(clock_49),
	.res_n_i(1'b1),
	.dac_i({~audio_r[15], audio_r[14:0]}),
	.dac_o(AUDIO_R)
	);

//Rotary controls (disable for bootleg ROM sets as although these support rotary controls, bootleg PCBs
//have no means of supporting rotary controls as there are no footprints for the required hardware)
//TODO: Map the inputs to absolute inputs using an analog stick (Jackal ignores out-of-order inputs)
reg [22:0] rotary_div = 23'd0;
reg [7:0] rotary1 = 8'h01;
reg [7:0] rotary2 = 8'h01;
wire m_rotary1_l = m_fireC;
wire m_rotary1_r = m_fireD;
wire m_rotary2_l = m_fire2C;
wire m_rotary2_r = m_fire2D;

wire rotary_en = rotary_speed ? !rotary_div[21:0] : !rotary_div;
always_ff @(posedge clock_49) begin
	rotary_div <= rotary_div + 23'd1;
	if(rotary_en) begin
		if(m_rotary1_l) begin
			if(rotary1 != 8'h80)
				rotary1 <= rotary1 << 1;
			else
				rotary1 <= 8'h01;
		end
		else if(m_rotary1_r) begin
			if(rotary1 != 8'h01)
				rotary1 <= rotary1 >> 1;
			else
				rotary1 <= 8'h80;
		end

		if(m_rotary2_l) begin
			if(rotary2 != 8'h80)
				rotary2 <= rotary2 << 1;
			else
				rotary2 <= 8'h01;
		end
		else if(m_rotary2_r) begin
			if(rotary2 != 8'h01)
				rotary2 <= rotary2 >> 1;
			else
				rotary2 <= 8'h80;
		end
	end
end
wire [7:0] p1_rotary = (is_bootleg == 2'b01) ? 8'hFF : rotary1;
wire [7:0] p2_rotary = (is_bootleg == 2'b01) ? 8'hFF : rotary2;

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clock_49    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0   		),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

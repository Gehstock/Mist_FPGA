module Qbert_MiST (
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
	"QBERT;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O7,Flip,Off,On;",
	"O8,Test mode,Off,On;",
	"O9,Diagonal joystick,Off,On;",
	"O1,Pause,Off,On;",
	"R4096,Save NVRAM;",
	"DIP;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        pause = status[1];
wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire        flip = status[7];
wire        service = status[8];
wire        diagonal = status[9];

wire  [1:0] orientation = {flip, core_mod != mod_tylz && core_mod != mod_insector && core_mod != mod_kngtmare && core_mod != mod_argus};
wire  [7:0] dip_sw = status[23:16];

assign 		LED = ~ioctl_downl;
assign 		SDRAM_CLK = clk_80;
assign 		SDRAM_CKE = 1;

wire clk_80, clk_40, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_80),
	.c1(clk_40),
	.locked(pll_locked)
	);

wire clk_sys = clk_40;

reg [3:0] cnt1;
reg cpu_clk; // 5 MHz
reg cen_5, cen_10_p, cen_10_n;
always @(posedge clk_sys) begin
  cnt1 <= cnt1 + 1'd1;
  if (cnt1 == 7) cnt1 <= 0;

  cpu_clk <= cnt1[2];
  cen_5 <= cnt1 == 7;
  cen_10_p <= cnt1 == 3 || cnt1 == 7;
  cen_10_n <= cnt1 == 1 || cnt1 == 5;
end

// derive sound clock from clk_sys
reg [5:0] cnt2;
reg sound_cen;
always @(posedge clk_sys) begin
  cnt2 <= cnt2 + 6'd1;
  sound_cen <= 1'b0;
  if (cnt2 == 6'd44) begin
    cnt2 <= 6'd0;
    sound_cen <= 1'b1;
  end
end


localparam mod_qbert    = 0;
localparam mod_qub      = 1;
localparam mod_mplanets = 2;
localparam mod_krull    = 3;
localparam mod_curvebal = 4;
localparam mod_tylz     = 5;
localparam mod_insector = 6;
localparam mod_argus    = 7;
localparam mod_kngtmare = 8;

wire        spinner_reset;
// Mad Planets spinner
wire  [7:0] spinner_pos;
spinner spinner (
	.clock_40(clk_sys),
	.reset(spinner_reset),
	.btn_left(m_fireC | m_leftB),
	.btn_right(m_fireD | m_rightB),
	.ctc_zc_to_2(vb),
	.spin_angle(spinner_pos)
);

// Argus trackball
wire  [15:0] trackball_pos;
spinner spinnerX (
	.clock_40(clk_sys),
	.reset(spinner_reset),
	.btn_left(m_left),
	.btn_right(m_right),
	.btn_acc(1'b1),
	.ctc_zc_to_2(vb),
	.spin_angle(trackball_pos[15:8])
);

spinner spinnerY (
	.clock_40(clk_sys),
	.reset(spinner_reset),
	.btn_left(m_up),
	.btn_right(m_down),
	.btn_acc(1'b1),
	.ctc_zc_to_2(vb),
	.spin_angle(trackball_pos[7:0])
);

reg  [5:0] OP2720;
reg  [7:0] IP1710;
reg  [7:0] IP4740;
reg [15:0] IPA1J2;

always @(*) begin

	IPA1J2 = 16'd0;
	IP4740 = 8'd0;

	IP1710 = {
		m_fireA, // test 1
		~service,      // test 2
		2'b0,
		m_coin2, // coin 1
		m_coin1, // coin 2
		m_two_players, // p2
		m_one_player   // p1
	};

	if (~diagonal) begin
		IP4740 = {
			m_down2,
			m_up2,
			m_left2,
			m_right2,
			m_down,
			m_up,
			m_left,
			m_right
		};
	end else begin
		IP4740 = {
			m_down2 & m_left2,  // down + left
			m_up2 & m_right2,   // up + right
			m_left2 & m_up2,    // left + up
			m_right2 & m_down2, // right + down
			m_down & m_left,    // down + left
			m_up & m_right,     // up + right
			m_left & m_up,      // left + up
			m_right & m_down,   // right + down
		};
	end

	case (core_mod)
		mod_qbert:
		begin
		end

		mod_qub:
		begin
		end

		mod_mplanets:
		begin
			IP1710 = {
				~service,    // test 2
				m_fireA, // test 1
				4'd0,
				m_coin2,
				m_coin1
			};

			IP4740 = {
				m_fireB,// button 2

				m_two_players, // p2
				m_one_player,  // p1

				m_fireA, // button 1
				m_left,
				m_down,
				m_right,
				m_up
			};

			IPA1J2 = {spinner_pos, spinner_pos};
		end

		mod_krull:
		begin
			IP1710 = {
				m_two_players,
				m_one_player,
				2'b00,
				m_coin2,
				m_coin1,
				m_fireA, // select in test mode
				~service
			};
			IP4740 = {
				m_left, // left joystick
				m_down,
				m_right,
				m_up,
				m_left2 | m_leftB, // right joystick15
				m_down2 | m_downB,
				m_right2 | m_rightB,
				m_up2 | m_upB
			};
		end

		mod_curvebal:
		begin
			IP1710 = {
				4'd0,
				m_coin2,
				m_coin1, // coin 1
				m_fireA, // test 1
				~service,    // test 2
			};

			IP4740 = {
				1'b0, // n/a
				m_fireD | m_down, // bunt
				1'b0, // n/a
				m_fireC | m_right, // pitch right
				1'b0, // n/a
				m_fireB | m_left, // pitch left
				m_fireA | m_up, // swing
				1'b0
			};
		end

		mod_tylz:
		begin
			IP1710 = { // IN1
				4'd0,
				m_coin1,
				m_coin2,
				m_fireA, // test 1
				~service
			};

			IP4740 = { // IN4
				1'b0,
				m_two_players, // p2
				m_one_player,  // p1

				m_fireA, // button 1
				diagonal ? m_left & m_up    : m_left,
				diagonal ? m_right & m_up   : m_up,
				diagonal ? m_right & m_down : m_right,
				diagonal ? m_left & m_down  : m_down
			};
		end

		mod_insector:
		begin
			IP1710 = { // IN1
				1'b0,
				~service,
				m_fire2B,
				m_fire2A,
				m_coin2,
				m_coin2,
				m_fireB,
				m_fireA
			};

			IP4740 = { // IN4
				m_left2,
				m_down2,
				m_right2,
				m_up2,

				m_left,
				m_down,
				m_right,
				m_up
			};
		end

		mod_argus:
		begin
			IP1710 = { // IN1
				4'h0,
				m_coin2,
				m_coin1,
				m_fireA,
				~service
			};

			IP4740 = { // IN4
				4'h0,
				m_fire2A,
				m_fire2B,
				m_fireA,
				m_fireB
			};
			IPA1J2 = trackball_pos;
		end

		mod_kngtmare:
		begin
			IP1710 = { // IN1
				4'h0,
				m_coin2,
				m_coin1,
				2'b00
			};

			IP4740 = { // IN4
				m_two_players,
				m_one_player,
				m_fireB,
				m_fireA,
				m_rightB | m_right2,
				m_left,
				m_leftB | m_left2,
				m_right
			};
		end

		default:
		begin
		end
	endcase
end

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [19:0] joystick_0;
wire [19:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clk_sys        ),
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

wire [15:0] main_rom_addr;
wire [15:0] main_rom_do;
wire [14:0] sub_rom_addr;
wire [15:0] sub_rom_do;
wire [15:1] ch1_addr;
wire [15:0] ch1_do;
wire        sp1_req, sp1_ack;
wire [13:0] bg_addr;
wire [31:0] bg_do;

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_din     ( ioctl_din    ),
	.ioctl_dout    ( ioctl_dout   )
);
wire [24:0] bg_ioctl_addr = ioctl_addr - 17'h10000;

reg port1_req, port2_req;
sdram #(80) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_80       ),

	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( rom_init ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( rom_init ? 16'hffff : {1'b0, main_rom_addr[15:1]} ),
	.cpu1_q        ( main_rom_do ),
	.cpu2_addr     ( 16'hffff ),
	.cpu2_q        ( ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {bg_ioctl_addr[13:0], bg_ioctl_addr[15]} ), // merge fg roms to 32-bit wide words
	.port2_ds      ( {bg_ioctl_addr[14], ~bg_ioctl_addr[14]} ),
	.port2_we      ( rom_init ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( rom_init ? 14'h3fff : bg_addr ),
	.sp_q          ( bg_do )
);

// ROM download controller
always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (rom_init) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire  [7:0] audio;
wire        hs, vs, cs;
wire        hb, vb;
wire        blankn = ~(hb | vb);

wire rom_init = ioctl_downl && (ioctl_index==0);
wire nvram_init = ioctl_downl && (ioctl_index==8'hFF);

wire  [3:0] r;
wire  [3:0] g;
wire  [3:0] b;

mylstar_board mylstar_board
(
	.clk_sys(clk_sys),
	.reset(reset),
	.pause(pause),

	.CPU_CORE_CLK(clk_80),
	.CPU_CLK(cpu_clk),
	.cen_5(cen_5),
	.cen_10_p(cen_10_p),
	.cen_10_n(cen_10_n),

	.red(r),
	.green(g),
	.blue(b),
	.HBlank(hb),
	.VBlank(vb),
	.HSync(hs),
	.VSync(vs),

	.IP1710(IP1710),
	.IP4740(IP4740),
	.IPA1J2(IPA1J2),
	.OP2720(OP2720),
	.OP3337(),
	.trackball_reset(spinner_reset),

	.dip_switch(dip_sw),

	.rom_init(rom_init),
	.nvram_init(nvram_init),
	.nvram_upl(ioctl_upl),
	.rom_init_address(ioctl_addr),
	.rom_init_data(ioctl_dout),
	.nvram_data(ioctl_din),
	.bgram(core_mod == mod_krull || core_mod == mod_argus),

	.vflip(flip),
	.hflip(flip),

	.cpu_rom_addr(main_rom_addr),
	.cpu_rom_do(main_rom_addr[0] ? main_rom_do[15:8] : main_rom_do[7:0]),
	.bg_rom_addr(bg_addr),
	.bg_rom_do(bg_do)
);

// audio board

ma216_board ma216_board(
	.clk(clk_sys),
	.cen(sound_cen),
	.reset(reset),
	.IP2720(OP2720),
	.audio(audio),
	.rom_init(rom_init),
	.rom_init_address(ioctl_addr),
	.rom_init_data(ioctl_dout)
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( ~hs              ),
	.VSync          ( ~vs              ),
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

wire audio_out;
assign AUDIO_L = audio_out;
assign AUDIO_R = audio_out;

dac #(.C_bits(8))dac(
	.clk_i(clk_sys),
	.res_n_i(1'b1),
	.dac_i(audio),
	.dac_o(audio_out)
	);

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG, m_upB, m_downB, m_leftB, m_rightB;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_upB, m_downB, m_leftB, m_rightB, 5'd0, m_fireG, m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, 5'd0, m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

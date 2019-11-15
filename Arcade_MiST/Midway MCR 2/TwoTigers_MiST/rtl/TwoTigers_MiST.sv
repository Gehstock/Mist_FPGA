//============================================================================
//  Arcade: Two Tigers Tron-Conversation by DarFPGA
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module TwoTigers_MiST(
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

`include "rtl/build_id.v" 

localparam CONF_STR = {
	"TWOTIGER;;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Service,Off,On;",
	//"O7,Spinner Speed,Low,High;",
	"T0,Reset;",
	"V,v1.1.",`BUILD_DATE
};

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_sys;
assign SDRAM_CKE = 1;

wire clk_sys;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [15:0] audio_l, audio_r;
wire        hs, vs;
wire        blankn;
wire  [3:0] g, r, b;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire        rom_rd;
wire [13:0] snd_addr;
wire [15:0] snd_do;
wire        snd_rd;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sys      ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     (),
	.port1_a       ( ioctl_downl ? ioctl_addr[23:1] : rom_addr[14:1] ),
	.port1_ds      ( ioctl_downl ? {ioctl_addr[0], ~ioctl_addr[0]} : 2'b11 ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( rom_do ),

	// port2 for sound board
	.port2_req     ( port2_req ),
	.port2_ack     (),
	.port2_a       ( ioctl_downl ? ioctl_addr[23:1] - 16'h4000 : snd_addr[13:1] ),
	.port2_ds      ( ioctl_downl ? {ioctl_addr[0], ~ioctl_addr[0]} : 2'b11 ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( snd_do )
);

always @(posedge clk_sys) begin
	reg [16:1] rom_addr_last;
	reg [15:1] snd_addr_last;
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		snd_addr_last <= 14'h2fff;
		rom_addr_last <= 15'h7fff;
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end else begin
		if (rom_rd && rom_addr_last != rom_addr[14:1]) begin
			rom_addr_last <= rom_addr[14:1];
			port1_req <= ~port1_req;
		end
		if (snd_rd && snd_addr_last != snd_addr[13:1]) begin
			snd_addr_last <= snd_addr[13:1];
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

satans_hollow satans_hollow(
	.clock_40(clk_sys),
	.reset(reset),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_blankn(blankn),
	.video_hs(hs),
	.video_vs(vs),
	.separate_audio(1'b0),
	.audio_out_l(audio_l),
	.audio_out_r(audio_r),
	.coin1(btn_coin),
	.coin2(1'b0),
	.start3(btn_dogfight),
	.start2(btn_two_players),
	.start1(btn_one_player),
	
	.up1(m_up1), 
	.down1(m_down1),
	.fire1(m_fire1),
	.bomb1(m_bomb1),
	
	.up2(m_up2), 
	.down2(m_down2),
	.fire2(m_fire2),
	.bomb2(m_bomb2),
	
	.speed(status[7]),
	.service(status[6]),
	.cpu_rom_addr ( rom_addr        ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.cpu_rom_rd   ( rom_rd          ),
	.snd_rom_addr ( snd_addr        ),
	.snd_rom_do   ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),
	.snd_rom_rd   ( snd_rd          )
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
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
	.ce_divider     ( 1                ),
	.blend          ( status[5]        ),
	.scandoubler_disable(1),//scandoublerD ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.C_bits(16))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);
	
dac #(
	.C_bits(16))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_r),
	.dac_o(AUDIO_R)
	);	

wire m_up1     = btn_up | joystick_0[3];
wire m_down1   = btn_down | joystick_0[2];
wire m_fire1   = btn_fire1 | joystick_0[4];
wire m_bomb1   = btn_fire2 | joystick_0[5];

wire m_up2     = joystick_1[3];
wire m_down2   = joystick_1[2];
wire m_fire2   = joystick_1[4];
wire m_bomb2   = joystick_1[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_dogfight = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;
wire       key_pressed;
wire [7:0] key_code;
wire       key_strobe;

always @(posedge clk_sys) begin
	if(key_strobe) begin
		case(key_code)		
			'h75: btn_up          <= key_pressed; // up
			'h72: btn_down        <= key_pressed; // down
			'h76: btn_coin        <= key_pressed; // ESC
			'h05: btn_one_player  <= key_pressed; // F1
			'h06: btn_two_players <= key_pressed; // F2
			'h04: btn_dogfight    <= key_pressed; // F3
			'h11: btn_fire2       <= key_pressed; // alt
			'h29: btn_fire1       <= key_pressed; // Space
		endcase
	end
end

endmodule 

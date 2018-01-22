//============================================================================
//  Arcade: Van Van Car
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
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

module VanVanCar
(
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
	input         CLOCK_27
);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"Van Van Car;;",
	"O2,Joystick Control,Upright,Normal;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};


wire clk_sys;
wire pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(),
	.c0(clk_sys),
	.locked(pll_locked)
);

reg ce_6m;
always @(posedge clk_sys) begin
	reg [1:0] div;
	
	div <= div + 1'd1;
	ce_6m <= !div;
end

reg ce_4m;
always @(posedge clk_sys) begin
	reg [2:0] div;
	
	div <= div + 1'd1;
	if(div == 5) div <= 0;
	ce_4m <= !div;
end



///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire [8:0] audio;
assign LED = 1;

wire hblank, vblank;
wire ce_vid = ce_6m;
wire hs, vs;
wire [2:0] r,g;
wire [1:0] b;


video_mixer #(.LINE_LENGTH(492), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_sys),
	.ce_pix(ce_vid),
	.ce_pix_actual(ce_vid),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r}),
	.G({g,g}),
	.B({b,b,b}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr          (ypbpr          ),
	.ps2_kbd_clk    (ps2_kbd_clk    ),
	.ps2_kbd_data   (ps2_kbd_data   ),
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
);



keyboard keyboard(
	.clk(clk_sys),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);
	
wire m_up     = status[2] ? kbjoy[6] | joystick_0[1] | joystick_1[1] : kbjoy[4] | joystick_0[3] | joystick_1[3];
wire m_down   = status[2] ? kbjoy[7] | joystick_0[0] | joystick_1[0] : kbjoy[5] | joystick_0[2] | joystick_1[2];
wire m_left   = status[2] ? kbjoy[5] | joystick_0[2] | joystick_1[2] : kbjoy[6] | joystick_0[1] | joystick_1[1];
wire m_right  = status[2] ? kbjoy[4] | joystick_0[3] | joystick_1[3] : kbjoy[7] | joystick_0[0] | joystick_1[0];

wire m_fire   = kbjoy[0] | joystick_0[4] | joystick_1[4];
wire m_start1 = kbjoy[1];
wire m_start2 = kbjoy[2];
wire m_coin   = kbjoy[3];

vanvan vanvan
(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_HBLANK(hblank),
	.O_VBLANK(vblank),

	.O_AUDIO(audio),

	.in0_reg(~{2'b00, m_coin, m_fire, m_down,m_right,m_left,m_up}),
	.in1_reg(~{1'b0, m_start2, m_start1, 5'b00000}),

	.dipsw1_reg(8'b11_00_10_0_0),
	.dipsw2_reg(8'b00000000),

	.RESET(status[0] | status[6] | buttons[1]),
	.CLK(clk_sys),
	.ENA_6(ce_6m),
	.ENA_4(ce_4m)
);


dac dac
(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio[7:0]),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

endmodule

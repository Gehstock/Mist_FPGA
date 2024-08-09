module Polaris_mist(
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
	"Polaris;;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O6,Joystick swap,Off,On;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire  [1:0] scanlines = status[4:3];
wire        rotate = 0;
wire        joyswap = status[6];

assign LED = 1;
assign AUDIO_R = AUDIO_L;


wire clk_sys, clk_vid, clk_vid_h;
wire pll_locked;
pll pll
(
	.inclk0(CLOCK_27),
	.areset(),
	.c0(clk_sys),
	.c1(clk_vid),
	.c2(clk_vid_h),
);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0,joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [7:0] audio;
wire 			hsync,vsync;
wire 			hs, vs;
wire 			r,g,b;

wire [15:0]RAB;
wire [15:0]AD;
wire [7:0]RDB;
wire [7:0]RWD;
wire [7:0]IB;
wire [5:0]SoundCtrl3;
wire [5:0]SoundCtrl5;
wire Rst_n_s;
wire RWE_n;
wire Video;
wire hblank;
wire vblank;

wire [7:0] GDB0;
wire [7:0] GDB1;
wire [7:0] GDB2;
reg [7:0] sw[8];

invaderst invaderst(
	.Rst_n(~(status[0] | buttons[1])),
	.Clk(clk_sys),
	.ENA(),
//	.GDB0({ 1'b0, m_right, m_left, m_fireA, 3'b000, ~m_coin1}),
	.GDB0({ m_up2, m_left2, m_down2, m_right2, m_fire2A, m_tilt, 2'b00}),
//	.GDB1(~{ m_coin1, 4'b0000, m_fireA, m_left, m_right}),
	.GDB1({ m_up2, m_left2, m_down2, m_right2, m_fireA, m_one_player, m_two_players, ~m_coin1}),
//	.GDB2(),
	.RDB(RDB),
	.IB(IB),
	.RWD(RWD),
	.RAB(RAB),
	.AD(AD),
	.SoundCtrl3(SoundCtrl3),
	.SoundCtrl5(SoundCtrl5),
	.Rst_n_s(Rst_n_s),
	.RWE_n(RWE_n),
	.Video(Video),
//	.O_VIDEO_R(r),
//	.O_VIDEO_G(g),
//	.O_VIDEO_B(b),
//	.O_VIDEO_A(fg),
	.HBLANK(hblank),
	.VBLANK(vblank),
	.HSync(hs),
	.VSync(vs)
	);
	
// Background Image

//wire bg_download = ioctl_download && (ioctl_index == 2);
//reg  [16:0] max_bg;
//
//reg [7:0] ioctl_dout_r;
//reg [7:0] ioctl_dout_r2;
//reg [7:0] ioctl_dout_r3;
//
//always @(posedge clk_sys) 
//begin
//	if(ioctl_wr & ~ioctl_addr[1] & ~ioctl_addr[0]) ioctl_dout_r <= ioctl_dout;
//	if(ioctl_wr & ~ioctl_addr[1] &  ioctl_addr[0]) ioctl_dout_r2 <= ioctl_dout;
//	if(ioctl_wr &  ioctl_addr[1] & ~ioctl_addr[0]) ioctl_dout_r3 <= ioctl_dout;
//	if(bg_download) max_bg <= {ioctl_addr[17:2],1'd0};
//end
//
//spram #(
//	.addr_width_g(16),
//	.data_width_g(32)) 
//u_ram0(
//	.address(bg_download ? ioctl_addr[17:2] : pic_addr[16:1]),
//	.clken(1'b1),
//	.clock(clk_mem),
//	.data({ioctl_dout, ioctl_dout_r3, ioctl_dout_r2, ioctl_dout_r}),
//	.wren(bg_download & ioctl_wr & ioctl_addr[1] & ioctl_addr[0]),	// write every 4th byte 
//	.q(pic_data)
//	);
//
//wire [31:0] pic_data;
//reg  [16:0] pic_addr;
//reg  [7:0]  bg_r,bg_g,bg_b,bg_a;
//
//always @(posedge clk_40) begin
//	reg use_bg = 0;
//	
//	if(bg_download) use_bg <= 1;
//
//	if(use_bg) begin
//		if(ce_pix) begin
//			if (HCount < 4 || HCount > 247) begin
//				{bg_a,bg_b,bg_g,bg_r} <= 0;
//			end
//			else begin
//				{bg_a,bg_b,bg_g,bg_r} <= pic_data;
//			end;
//			if(~(hblank|vblank)) begin
//				if(ScreenFlip & ~landscape) begin
//					pic_addr <= pic_addr - 2'd2;
//				end
//				else begin
//					pic_addr <= pic_addr + 2'd2;
//				end;
//			end
//			
//			if (VCount == 11'd0 && HCount == 11'd0) begin
//				if(ScreenFlip & ~landscape) begin
//					pic_addr <= max_bg;
//				end
//				else begin
//					pic_addr <= 0;
//				end;
//			end;
//			
//		end
//	end
//	else begin
//		// Mix cloud background in (Balloon Bomber or Polaris)
//		if ((mod==mod_ballbomb & BBPixel==1'd1) || ((mod==mod_polaris & PolarisPixel==1'd1) && (VCount > 1))) begin
//			// bg_a ?
//			bg_b <= 255;
//			bg_g <= 255;
//			bg_r <= 255;
//		end
//		else 
//		begin
//			{bg_a,bg_b,bg_g,bg_r} <= 0;
//		end;
//	end
//end
	
reg ce_pix;
always @(posedge clk_vid_h) begin
        reg [2:0] div;

        div <= div + 1'd1;
	ce_pix <= div == 0;
end

reg PolarisPixel;	
wire [11:0] HCount;
wire [11:0] VCount;

virtualgun virtualgun
(
	.CLK(clk_vid_h),
	.HDE(~hblank),
	.VDE(~vblank),
	.CE_PIX(ce_pix),
	.H_COUNT(HCount),
	.V_COUNT(VCount)
);

cloud cloud
(
   .clk(clk_vid_h),
	.pixel_en(ce_pix),
	.v(VCount),
	.h(HCount),
	.flip(DoScreenFlip),
	.pixel(PolarisPixel)
);
		
Polaris_memory Polaris_memory (
	.Clock(clk_sys),
	.RW_n(RWE_n),
	.Addr(AD),
	.Ram_Addr(RAB),
	.Ram_out(RDB),
	.Ram_in(RWD),
	.Rom_out(IB)
	);
		
invaders_audio invaders_audio (
	.Clk(clk_sys),
	.S1(SoundCtrl3),
	.S2(SoundCtrl5),
	.Aud(audio)
	);

mist_video #(.COLOR_DEPTH(1)) mist_video(
	.clk_sys(clk_vid),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(Video),
	.G(Video),
	.B(Video),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b0,rotate}),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ce_divider(1'b0),
	.ypbpr(ypbpr),
	.no_csync(no_csync)
	);

user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_sys       ),
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

dac #(
	.c_bits(8))
dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
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
	.rotate      ( rotate      ),
	.orientation ( 2'b00       ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 

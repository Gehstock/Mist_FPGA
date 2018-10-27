module vectrex_mist
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
	"Vectrex;BINVECROM;",
	"O2,Show Frame,Yes,No;",
   "O3,Skip Logo,Yes,No;",
	"O4,Second Joystick, Player 2, Player 1;",	
//	"O5,Speech Mode,No,Yes;",
//	"O23,Phosphor persistance,1,2,3,4;",
//	"O8,Overburn,No,Yes;",	
	"T6,Reset;",
	"V,v1.50.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [15:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [7:0]	pot_x_1, pot_x_2;
wire  [7:0]	pot_y_1, pot_y_2;
wire  [9:0] audio;
wire 			hs, vs, cs;
wire  [3:0] r, g, b;
wire 			hb, vb;
wire       	blankn = ~(hb | vb);
wire 			cart_rd;
wire [13:0] cart_addr;
wire  [7:0] cart_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;


assign LED = !ioctl_downl;

wire 			clk_24, clk_12, clk_6;
wire 			pll_locked;

always @(clk_12)begin
	pot_x_1 = 8'h00;
	pot_y_1 = 8'h00;
	pot_x_2 = 8'h00;
	pot_y_2 = 8'h00;
	//
	if (joystick_0[1] | kbjoy[1]) pot_x_2 = 8'h80;
	if (joystick_0[0] | kbjoy[0]) pot_x_2 = 8'h7F;
	
	if (joystick_0[3] | kbjoy[3]) pot_y_2 = 8'h7F;
	if (joystick_0[2] | kbjoy[2]) pot_y_2 = 8'h80;
	//Player2
	if (joystick_1[1] | kbjoy[9]) pot_x_1 = 8'h80;
	if (joystick_1[0] | kbjoy[8]) pot_x_1 = 8'h7F;
	
	if (joystick_1[3] | kbjoy[11]) pot_y_1 = 8'h7F;
	if (joystick_1[2] | kbjoy[10]) pot_y_1 = 8'h80;	
end

pll pll (
	.inclk0			( CLOCK_27		),
	.areset			( 0				),
	.c0				( clk_24			),
	.c1				( clk_12			),
	.c2				( clk_6			),
	.locked			( pll_locked	)
	);

card card (
	.clock			( clk_24		),
	.address			( ioctl_downl ? ioctl_addr : cart_addr),
	.data				( ioctl_dout	),
	.rden				( !ioctl_downl && cart_rd),
	.wren				( ioctl_downl && ioctl_wr),
	.q					( cart_do		)
	);

	wire reset = (status[0] | status[6] | buttons[1] | ioctl_downl | second_reset);

reg second_reset = 0;
always @(posedge clk_24) begin
	integer timeout = 0;

	if(ioctl_downl && status[3]) timeout <= 5000000;
	else begin
		if(!timeout) second_reset <= 0;
		else begin
			timeout <= timeout - 1;
			if(timeout < 1000) second_reset <= 1;
		end
	end
end

vectrex vectrex (
	.clock_24		( clk_24			),  
	.clock_12		( clk_12 		),
	.reset			( reset 			),
	.video_r			( rr				),
	.video_g			( gg				),
	.video_b			( bb				),
	.video_csync	( cs				),
	.video_hblank	( hb				),
	.video_vblank	( vb				),
//	.speech_mode   ( status[5]		),
	.video_hs		( hs				),
	.video_vs		( vs				),
	.frame			( frame_line	),
	.audio_out		( audio			),
	.cart_addr		( cart_addr		),
	.cart_do			( cart_do		),
	.cart_rd			( cart_rd		),	
	.btn11			( joystick_0[4] | kbjoy[4] | status[4] ? joystick_1[4] : 1'b0),
	.btn12			( joystick_0[5] | kbjoy[5] | status[4] ? joystick_1[5] : 1'b0),
	.btn13			( joystick_0[6] | kbjoy[6] | status[4] ? joystick_1[6] : 1'b0),
	.btn14			( joystick_0[7] | kbjoy[7] | status[4] ? joystick_1[7] : 1'b0),
	.pot_x_1			( pot_x_1			),
	.pot_y_1			( pot_y_1			),
	.btn21			( kbjoy[12] | ~status[4] ? joystick_1[4] : 1'b0),
	.btn22			( kbjoy[13] | ~status[4] ? joystick_1[5] : 1'b0),
	.btn23			( kbjoy[14] | ~status[4] ? joystick_1[6] : 1'b0),
	.btn24			( kbjoy[15] | ~status[4] ? joystick_1[7] : 1'b0),
	.pot_x_2			( pot_x_2			),
	.pot_y_2			( pot_y_2			),
	.leds				(					),
	.dbg_cpu_addr	(					)
	);
	
	//	.pot_x_1(joya_0[7:0]  ? joya_0[7:0]   : {joystick_0[1], {7{joystick_0[0]}}}),
	//.pot_y_1(joya_0[15:8] ? ~joya_0[15:8] : {joystick_0[2], {7{joystick_0[3]}}}),
	
	//	.pot_x_2(joya_1[7:0]  ? joya_1[7:0]   : {joystick_1[1], {7{joystick_1[0]}}}),
	//.pot_y_2(joya_1[15:8] ? ~joya_1[15:8] : {joystick_1[2], {7{joystick_1[3]}}})
	

dac dac (
	.clk_i			( clk_24			),
	.res_n_i			( 1				),
	.dac_i			( audio			),
	.dac_o			( AUDIO_L		)
	);
assign AUDIO_R = AUDIO_L;

wire frame_line;
wire [3:0] rr,gg,bb;

	assign r = status[2] & frame_line ? 4'h40 : rr;
	assign g = status[2] & frame_line ? 4'h00 : gg;
	assign b = status[2] & frame_line ? 4'h00 : bb;

video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(1)) video_mixer (
	.clk_sys			( clk_24			),
	.ce_pix			( clk_6			),
	.ce_pix_actual	( clk_6			),
	.SPI_SCK			( SPI_SCK		),
	.SPI_SS3			( SPI_SS3		),
	.SPI_DI			( SPI_DI			),
	.R					(  blankn ? r : "0000"),
	.G					(  blankn ? g : "0000"),
	.B					(  blankn ? b : "0000"),
	.HSync			( hs				),
	.VSync			( vs			   ),
	.VGA_R			( VGA_R			),
	.VGA_G			( VGA_G			),
	.VGA_B			( VGA_B			),
	.VGA_VS			( VGA_VS			),
	.VGA_HS			( VGA_HS			),
	.scandoubler_disable(1			),
	.ypbpr_full		( 1				),
	.line_start		( 0				),
	.mono				( 0				)
	);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io (
	.clk_sys       ( clk_24   	   ),
	.conf_str      ( CONF_STR     ),
	.SPI_SCK       ( SPI_SCK      ),
	.CONF_DATA0    ( CONF_DATA0   ),
	.SPI_SS2			( SPI_SS2      ),
	.SPI_DO        ( SPI_DO       ),
	.SPI_DI        ( SPI_DI       ),
	.buttons       ( buttons      ),
	.switches   	( switches     ),
	.ypbpr         ( ypbpr        ),
	.ps2_kbd_clk   ( ps2_kbd_clk  ),
	.ps2_kbd_data	( ps2_kbd_data	),
	.joystick_0   	( joystick_0   ),
	.joystick_1    ( joystick_1   ),
	.status        ( status       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index	( ioctl_index	),
	.ioctl_wr		( ioctl_wr		),
	.ioctl_addr		( ioctl_addr	),
	.ioctl_dout		( ioctl_dout	)
	);

keyboard keyboard (
	.clk				( clk_24			),
	.reset			( 0				),
	.ps2_kbd_clk	( ps2_kbd_clk	),
	.ps2_kbd_data	( ps2_kbd_data	),
	.joystick		( kbjoy			)
	);


endmodule 
module vectrex_mist
(
	input         CLOCK_27,
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
	"Vectrex;BINVECROM;",
	"O1,CPU,MC6809,CPU09;",
	"O2,Show Frame,Yes,No;",
	"O3,Skip Logo,Yes,No;",
	"O4,Joystick swap,Off,On;",
	"O5,Second port,Joystick,Speech;",
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
wire [15:0] joy_ana_0;
wire [15:0] joy_ana_1;
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
wire [14:0] cart_addr;
wire  [7:0] cart_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;


assign LED = !ioctl_downl;

wire 			clk_24, clk_12;
wire 			pll_locked;

pll pll (
	.inclk0			( CLOCK_27		),
	.areset			( 0				),
	.c0				( clk_24		),
	.c1				( clk_12		),
	.locked			( pll_locked	)
	);

assign SDRAM_CLK = clk_24;
wire [15:0] sdram_do;
assign cart_do = sdram_do[7:0];

sdram cart
(
    .*,
    .init(~pll_locked),
    .clk(clk_24),
    .wtbt(2'b00),
    .dout(sdram_do),
    .din ({ioctl_dout, ioctl_dout}),
    .addr(ioctl_downl ? ioctl_addr : cart_addr),
    .we(ioctl_downl & ioctl_wr),
    .rd(!ioctl_downl & cart_rd),
	.ready()
);

reg reset = 0;
reg second_reset = 0;

always @(posedge clk_24) begin
	integer timeout = 0;
	reg [15:0] reset_counter = 0;
	reg reset_start;

	reset <= 0;
	reset_start <= status[0] | status[6] | buttons[1] | ioctl_downl | second_reset;
	if (reset_counter) begin
		reset <= 1'b1;
		reset_counter <= reset_counter - 1'd1;
	end
	if (reset_start) reset_counter <= 16'd1000;

	second_reset <= 0;
	if (timeout) begin
		timeout <= timeout - 1;
		if(timeout == 1) second_reset <= 1'b1;
	end
	if(ioctl_downl && !status[3]) timeout <= 5000000;
end

assign pot_x_1 = status[4] ? joy_ana_1[15:8] : joy_ana_0[15:8];
assign pot_x_2 = status[4] ? joy_ana_0[15:8] : joy_ana_1[15:8];
assign pot_y_1 = status[4] ? ~joy_ana_1[ 7:0] : ~joy_ana_0[ 7:0];
assign pot_y_2 = status[4] ? ~joy_ana_0[ 7:0] : ~joy_ana_1[ 7:0];

vectrex vectrex (
	.clock_24		( clk_24			),  
	.clock_12		( clk_12 		),
	.reset			( reset 			),
	.cpu			( status[1]         ),
	.video_r			( rr				),
	.video_g			( gg				),
	.video_b			( bb				),
	.video_csync	( cs				),
	.video_hblank	( hb				),
	.video_vblank	( vb				),
	.speech_mode    ( status[5]		),
	.video_hs		( hs				),
	.video_vs		( vs				),
	.frame			( frame_line	),
	.audio_out		( audio			),
	.cart_addr		( cart_addr		),
	.cart_do			( cart_do		),
	.cart_rd			( cart_rd		),	
	.btn11          ( status[4] ? joystick_1[4] : joystick_0[4]),
	.btn12          ( status[4] ? joystick_1[5] : joystick_0[5]),
	.btn13          ( status[4] ? joystick_1[6] : joystick_0[6]),
	.btn14          ( status[4] ? joystick_1[7] : joystick_0[7]),
	.pot_x_1        ( pot_x_1			),
	.pot_y_1        ( pot_y_1			),
	.btn21          ( status[4] ? joystick_0[4] : joystick_1[4]),
	.btn22          ( status[4] ? joystick_0[5] : joystick_1[5]),
	.btn23          ( status[4] ? joystick_0[6] : joystick_1[6]),
	.btn24          ( status[4] ? joystick_0[7] : joystick_1[7]),
	.pot_x_2        ( pot_x_2			),
	.pot_y_2        ( pot_y_2			),
	.leds				(					),
	.dbg_cpu_addr	(					)
	);

dac dac (
	.clk_i			( clk_24			),
	.res_n_i		( 1				),
	.dac_i			( audio			),
	.dac_o			( AUDIO_L		)
	);
assign AUDIO_R = AUDIO_L;

//////////////////   VIDEO   //////////////////

wire frame_line;
wire [3:0] rr,gg,bb;

assign r = status[2] & frame_line ? 4'h4 : blankn ? rr : 4'd0;
assign g = status[2] & frame_line ? 4'h0 : blankn ? gg : 4'd0;
assign b = status[2] & frame_line ? 4'h0 : blankn ? bb : 4'd0;

wire        csync_out = ~(hs ^ vs);

assign      VGA_HS = ypbpr ? csync_out : hs;
assign      VGA_VS = ypbpr ? 1'b1 : vs;

wire [5:0] osd_r_o, osd_g_o, osd_b_o;

osd osd
(
	.clk_sys(clk_24),
	.SPI_DI(SPI_DI),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.R_in({r, 2'b00}),
	.G_in({g, 2'b00}),
	.B_in({b, 2'b00}),
	.HSync(hs),
	.VSync(vs),
	.R_out(osd_r_o),
	.G_out(osd_g_o),
	.B_out(osd_b_o)
);
    
wire [5:0] y, pb, pr;

rgb2ypbpr rgb2ypbpr
(
	.red   ( osd_r_o ),
	.green ( osd_g_o ),
	.blue  ( osd_b_o ),
	.y     ( y       ),
	.pb    ( pb      ),
	.pr    ( pr      )
);

assign VGA_R = ypbpr?pr:osd_r_o;
assign VGA_G = ypbpr? y:osd_g_o;
assign VGA_B = ypbpr?pb:osd_b_o;

////////////////////////////////////////////

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io (
	.clk_sys       ( clk_24       ),
	.conf_str      ( CONF_STR     ),
	.SPI_SCK       ( SPI_SCK      ),
	.CONF_DATA0    ( CONF_DATA0   ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DO        ( SPI_DO       ),
	.SPI_DI        ( SPI_DI       ),
	.buttons       ( buttons      ),
	.switches      ( switches     ),
	.ypbpr         ( ypbpr        ),
	.ps2_kbd_clk   ( ps2_kbd_clk  ),
	.ps2_kbd_data  ( ps2_kbd_data ),
	.joystick_0    ( joystick_0   ),
	.joystick_1    ( joystick_1   ),
	.joystick_analog_0( joy_ana_0 ),
	.joystick_analog_1( joy_ana_1 ),
	.status        ( status       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
	);

endmodule 
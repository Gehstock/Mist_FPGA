module bally_mist(
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
	"BALLY;BIN;",
//	"O2,Check Cart, On, Off;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire clk_28;//28.5712
wire clk_14;//14.2856
wire clk_7;//7.1428
wire clk_1;//1.0204
wire reset = status[0] | status[6] | buttons[1] | ioctl_downl;

wire [12:0] cart_addr;
wire  [7:0] cart_di, cart_do;
wire        cart_cs;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
assign LED = !ioctl_downl;

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;

wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [7:0] switch_col;
wire  [7:0] switch_row;
wire  [7:0] audio;

wire pix_ena;
wire hs, vs;
wire [3:0] r,g,b;

wire [15:0] exp_addr;
wire  [7:0] exp_data_out;
wire  [7:0] exp_data_in;
wire        exp_oe_l;
wire        exp_m1_l;
wire        exp_mreq_l;
wire        exp_iorq_l;
wire        exp_wr_l;
wire        exp_rd_l;

wire  [3:0] check_cart_msb;
wire  [7:4] check_cart_lsb;


pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_28),
	.c1(clk_14),
	.c2(clk_7),
	.c3(clk_1)
	);
	
video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_28),
	.ce_pix(clk_7),
	.ce_pix_actual(clk_7),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r[1:0]}),
	.G({g,g[1:0]}),
	.B({b,b[1:0]}),
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
	.clk_sys        		(clk_28        	),
	.conf_str       		(CONF_STR       	),
	.SPI_SCK        		(SPI_SCK        	),
	.CONF_DATA0     		(CONF_DATA0     	),
	.SPI_SS2			 		(SPI_SS2        	),
	.SPI_DO         		(SPI_DO         	),
	.SPI_DI         		(SPI_DI        	),
	.buttons        		(buttons        	),
	.switches   	 		(switches       	),
	.scandoubler_disable	(scandoubler_disable	),
	.ypbpr          		(ypbpr          	),
	.ps2_kbd_clk    		(ps2_kbd_clk    	),
	.ps2_kbd_data   		(ps2_kbd_data   	),
	.joystick_0   	 		(joystick_0     	),
	.joystick_1     		(joystick_1     	),
	.status         		(status         	),
	.ioctl_download		( ioctl_downl  	),
	.ioctl_index			( ioctl_index		),
	.ioctl_wr				( ioctl_wr			),
	.ioctl_addr				( ioctl_addr		),
	.ioctl_dout				( ioctl_dout		)
);


cart cart (
	.clock			( clk_14		),
	.address			( ioctl_downl ? ioctl_addr : cart_addr),
	.data				( ioctl_dout	),
	.rden				( !ioctl_downl && !cart_cs),
	.wren				( ioctl_downl && ioctl_wr),
	.q					( cart_do		)
	);
/*
BALLY_TOP BALLY_TOP (
    .cas_addr(cart_addr),
    .cas_data(cart_do),
    .cas_cs_l(cart_cs),
    .I_PS2_CLK    (ps2_kbd_clk    ),
    .I_PS2_DATA   (ps2_kbd_data   ),
    .r(r),
    .g(g),
    .b(b),
    .hs(hs),
    .vs(vs),
    .AUDIO(audio),  
    .ena(1'b1),
	 .pix_ena(pix_ena),
    .clk_14(clk_14),
	 .clk_7(clk_7),
    .reset(reset)
	 );*/
	 
BALLY_PS2_IF BALLY_PS2_IF (
	.I_PS2_CLK(ps2_kbd_clk),
   .I_PS2_DATA(ps2_kbd_data),
	.I_COL     (switch_col),
   .O_ROW     (switch_row),
	.I_RESET_L (~reset),
   .I_1MHZ_ENA(clk_1),
   .CLK       (clk_7)
   );
	
BALLY BALLY (
    .O_AUDIO(audio), 

    .O_VIDEO_R(r),
    .O_VIDEO_G(g),
    .O_VIDEO_B(b),

    .O_HSYNC(hs),
    .O_VSYNC(vs),
    .O_COMP_SYNC_L(),
    .O_FPSYNC(),

    .O_CAS_ADDR(cart_addr),
    .O_CAS_DATA(),
    .I_CAS_DATA(cart_do),
    .O_CAS_CS_L(cart_cs),
	 
    .O_EXP_ADDR(exp_addr),
    .O_EXP_DATA(exp_data_out),
    .I_EXP_DATA(exp_data_in),
    .I_EXP_OE_L(exp_oe_l),
    .O_EXP_M1_L(exp_m1_l),
    .O_EXP_MREQ_L(exp_mreq_l),
    .O_EXP_IORQ_L(exp_iorq_l),
    .O_EXP_WR_L(exp_wr_l),
    .O_EXP_RD_L(exp_rd_l),

    .O_SWITCH_COL(switch_col),
    .I_SWITCH_ROW(switch_row),

    .I_RESET_L(~reset),
    .ENA(1'b1),
	 .pix_ena(pix_ena),
    .CLK(clk_14),
	 .CLK7(clk_7)
    );
	 
dac dac
(
	.clk_i(clk_28),
	.res_n_i(~reset),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;
/*
BALLY_CHECK_CART BALLY_CHECK_CART (
	.I_EXP_ADDR(exp_addr),
	.I_EXP_DATA(exp_data_out),
	.O_EXP_DATA(exp_data_in),
	.O_EXP_OE_L(exp_oe_l),
	.I_EXP_M1_L(exp_m1_l),
	.I_EXP_MREQ_L(exp_mreq_l),
	.I_EXP_IORQ_L(exp_iorq_l),
	.I_EXP_WR_L(exp_wr_l),
	.I_EXP_RD_L(exp_rd_l),
	. O_CHAR_MSB(check_cart_msb),
	.O_CHAR_LSB(check_cart_lsb),
	.I_RESET_L(~reset),
	.ENA(status[2]),
	.CLK(clk_7)
	);*/


// if no expansion cart
 assign exp_data_in = 8'hff;
 assign exp_oe_l = 1'b1;

endmodule

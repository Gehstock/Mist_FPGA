module System1_MiST(
   input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,
   output        LED,
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
   input         CONF_DATA0
);

`include "build_id.v"
localparam CONF_STR = {
	"System1;;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};
wire 			clk_sys;
wire        key_pressed;
wire [7:0]  key_code;
wire        key_strobe;
wire        key_extended;
wire [8:0]  mouse_x,mouse_y;
wire [7:0]  mouse_flags;
wire [7:0]  r, g, b; 
wire 			hs, vs, hb, vb;
wire			blankn = ~(hb | vb);
wire  [1:0] buttons, switches;
wire			ypbpr;
wire        scandoublerD;
wire [31:0] status;

assign LED = 1'b1;

pll pll (
	.inclk0				(CLOCK_27			),
	.c0					(clk_sys 			)//25
	);
	
user_io #(
	.STRLEN				(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        	(clk_sys        	),
	.conf_str       	(CONF_STR       	),
	.SPI_CLK        	(SPI_SCK        	),
	.SPI_SS_IO      	(CONF_DATA0     	),
	.SPI_MISO       	(SPI_DO         	),
	.SPI_MOSI       	(SPI_DI         	),
	.buttons        	(buttons        	),
	.switches       	(switches      	),
	.scandoubler_disable (scandoublerD	),
	.ypbpr          	(ypbpr          	),
	.key_strobe     	(key_strobe     	),
	.key_pressed    	(key_pressed    	),
	.key_extended   	(key_extended   	),
	.key_code       	(key_code       	),
	.mouse_x       	(mouse_x       	),
	.mouse_y       	(mouse_y       	),
	.status         	(status         	)
	);
	
mist_video #(.COLOR_DEPTH(6)) mist_video(
	.clk_sys				(clk_sys			   ),
	.SPI_SCK				(SPI_SCK				),
	.SPI_SS3				(SPI_SS3				),
	.SPI_DI				(SPI_DI				),
	.R						(blankn ? r[7:2] : 0),
	.G						(blankn ? g[7:2] : 0),
	.B						(blankn ? b[7:2] : 0),
	.HSync				(hs					),
	.VSync				(vs					),
	.VGA_R				(VGA_R				),
	.VGA_G				(VGA_G				),
	.VGA_B				(VGA_B				),
	.VGA_VS				(VGA_VS				),
	.VGA_HS				(VGA_HS				),
	.scandoubler_disable(1'b1				),
	.ypbpr				(ypbpr				)
	);

wire reset = (status[0] | status[6] | buttons[1]);
wire [8:0] ch0,ch1,ch2,ch3,ch4,ch5,ch6,ch7;
wire sw0,sw1,sw2,sw3,sw4,sw5,sw6,sw7,sw8,sw9,swa,swb,swc,swd,swe,swf,swrst,swm,swl,swg,swr,swp,swUP,sws,swDW;
	
System1 System1(
	.clk25(clk_sys),	
	.reset(reset),
	.ch0(ch0),
	.ch1(ch1),
	.ch2(ch2),
	.ch3(ch3),
	.ch4(ch4),
	.ch5(ch5),
	.ch6(ch6),
	.ch7(ch7),
	.sw0(sw0 | tsw0),
	.sw1(sw1 | tsw1),
	.sw2(sw2 | tsw2),
	.sw3(sw3 | tsw3),
	.sw4(sw4 | tsw4),
	.sw5(sw5 | tsw5),
	.sw6(sw6 | tsw6),
	.sw7(sw7 | tsw7),
	.sw8(sw8 | tsw8),
	.sw9(sw9 | tsw9),
	.swa(swa | tswa),
	.swb(swb | tswb),
	.swc(swc | tswc),
	.swd(swd | tswd),
	.swe(swe | tswe),
	.swf(swf | tswf),
	.swrst(swrst | tswrst),
	.swm(swm | tswm),
	.swl(swl | tswl),
	.swg(swg | tswg),
	.swr(swr | tswr),
	.swp(swp | tswp),
	.swU(swUP | tswUP),
	.sws(sws | tsws),
	.swD(swDW | tswDW),
	.cas_in(1'b0),
	.cas_out()
);

vga vga(
	.clk(clk_sys),
	.rst(reset),
	.mbtnL(mouse_flags[0]),
	.mbtnR(mouse_flags[1]),
	.mbtnM(mouse_flags[2]),
	.mx(mouse_x),//mx),
	.my(mouse_y),//my),
	.ch0(ch0),
	.ch1(ch1),
	.ch2(ch2),
	.ch3(ch3),
	.ch4(ch4),
	.ch5(ch5),
	.ch6(ch6),
	.ch7(ch7),
	.osw0(sw0),
	.osw1(sw1),
	.osw2(sw2),
	.osw3(sw3),
	.osw4(sw4),
	.osw5(sw5),
	.osw6(sw6),
	.osw7(sw7),
	.osw8(sw8),
	.osw9(sw9),
	.oswa(swa),
	.oswb(swb),
	.oswc(swc),
	.oswd(swd),
	.oswe(swe),
	.oswf(swf),
	.oswrst(swrst),
	.oswm(swm),
	.oswl(swl),
	.oswg(swg),
	.oswr(swr),
	.oswp(swp),
	.oswU(swUP),
	.osws(sws),
	.oswD(swDW),

	
	.r(r),
	.g(g),
	.b(b),
	.hs(hs),
	.vs(vs),
	.hblank(hb),
	.vblank(vb)
);
/*
wire [10:0] mx,my;
wire x1,y1,mbtnL,mbtnR,mbtnM;

ps2_mouse mouse
(
	.clk(clk_sys),
	.ce(1'b1),
	.reset(reset),
	.ps2_mouse(ps2_mouse),
	.mx(mx),
	.my(my),
	.mbtnL(mbtnL),
	.mbtnR(mbtnR),
	.mbtnM(mbtnM)
);*/
/*
ps2_mouse #(
	.clk_freq							:	INTEGER := 50_000_000;	--system clock frequency in Hz
	.ps2_debounce_counter_size	:	INTEGER := 8);				--set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
MOUSE(
	.clk				:	IN			STD_LOGIC;								--system clock input
	.reset_n			:	IN			STD_LOGIC;								--active low asynchronous reset
	.ps2_clk			:	INOUT		STD_LOGIC;								--clock signal from PS2 mouse
	.ps2_data			:	INOUT		STD_LOGIC;								--data signal from PS2 mouse
	.mouse_data		:	OUT		STD_LOGIC_VECTOR(23 DOWNTO 0);	--data received from mouse
	.mouse_data_new	:	OUT		STD_LOGIC
	);
*/
reg tsw0 = 1'b0;
reg tsw1 = 1'b0;
reg tsw2 = 1'b0;
reg tsw3 = 1'b0;
reg tsw4 = 1'b0;
reg tsw5 = 1'b0;
reg tsw6 = 1'b0;
reg tsw7 = 1'b0;
reg tsw8 = 1'b0;
reg tsw9 = 1'b0;
reg tswa = 1'b0;
reg tswb = 1'b0;
reg tswc = 1'b0;
reg tswd = 1'b0;
reg tswe = 1'b0;
reg tswf = 1'b0;
reg tswm = 1'b0;
reg tswl = 1'b0;
reg tswg = 1'b0;
reg tswr = 1'b0;
reg tswp = 1'b0;
reg tswUP = 1'b0;
reg tsws = 1'b0;
reg tswDW = 1'b0;
reg tswrst = 1'b0;


always @(posedge clk_sys) begin
	reg old_state;
	old_state <= key_strobe;
	
	if(old_state != key_strobe) begin
		casex(key_code)
			'h75: tswUP           	<= key_pressed; // up
			'h72: tswDW		         <= key_pressed; // down
			
			'h45: tsw0      			<= key_pressed; // 0
//			'h70: tsw0      			<= key_pressed; // 0
			
			'h16: tsw1       			<= key_pressed; // 1
//			'h69: tsw1       			<= key_pressed; // 1
			
			'h1E: tsw2   				<= key_pressed; // 2
//			'h72: tsw2   				<= key_pressed; // 2
			
			'h26: tsw3  				<= key_pressed; // 3
//			'h7A: tsw3  				<= key_pressed; // 3
			
			'h25: tsw4   				<= key_pressed; // 4
//			'h6B: tsw4  				<= key_pressed; // 4
			
			'h2E: tsw5   				<= key_pressed; // 5
//			'h73: tsw5  				<= key_pressed; // 5
			
			'h36: tsw6      			<= key_pressed; // 6
//			'h74: tsw6  				<= key_pressed; // 6
			
			'h3D: tsw7      			<= key_pressed; // 7
//			'h6C: tsw7  				<= key_pressed; // 7
			
			'h3E: tsw8		   		<= key_pressed; // 8
//			'h75: tsw8  				<= key_pressed; // 8
			
			'h46: tsw9      			<= key_pressed; // 9
//			'h7D: tsw9  				<= key_pressed; // 9
			
			
			'h1C: tswa       			<= key_pressed; // a
			'h32: tswb   				<= key_pressed; // b
			'h21: tswc  				<= key_pressed; // c
			'h23: tswd   				<= key_pressed; // d
			'h24: tswe   				<= key_pressed; // e
			'h2B: tswf      			<= key_pressed; // f
			'h3A: tswm      			<= key_pressed; // m
			'h34: tswg		   		<= key_pressed; // g
			'h4D: tswp   				<= key_pressed; // p
			'h1B: tsws  				<= key_pressed; // s
			'h4B: tswl   				<= key_pressed; // l
			'h2D: tswr   				<= key_pressed; // r
//			'h05: tswrst      		<= key_pressed; // F1
		endcase
	end
end



endmodule 
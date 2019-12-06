////////////////////////////////////////////////////////////////////////////////
//
//
//
//  MENU for MIST board
//  (C) 2016 Sorgelig
//
//
//
////////////////////////////////////////////////////////////////////////////////

module MENU(
   input         CLOCK_27,   // Input clock 27 MHz
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,
   output        LED,
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
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

assign LED = 1;

wire clk_x2, clk_pix, clk_ram, locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_ram),
	.c1(SDRAM_CLK),
	.c2(clk_x2),
	.c3(clk_pix),
	.locked(locked)
	);

//______________________________________________________________________________
//
// MIST ARM I/O
//

wire		   scandoubler_disable;
wire		   ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

user_io #(
	.STRLEN(6))
user_io(
	.clk_sys        (clk_x2        ),
	.conf_str("MENU;;"),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.scandoubler_disable (scandoubler_disable),
	.ypbpr          (ypbpr          )
	);

sram ram(
	.*,
	.init(~locked),
	.clk(clk_ram),
	.wtbt(3),
	.dout(),
	.din(0),
	.rd(0),
	.ready()
);

reg        we;
reg [24:0] addr = 0;

always @(posedge clk_ram) begin
	integer   init = 5000000;
	reg [4:0] cnt = 9;
	
	if(init) init <= init - 1;
	else begin
		cnt <= cnt + 1'b1;
		we <= &cnt;
		if(cnt == 8) addr <= addr + 1'd1;
	end
end

//______________________________________________________________________________
//
// Video 
//

reg  [9:0] hc;
reg  [8:0] vc;
reg  [9:0] vvc;

reg [22:0] rnd_reg;
wire [5:0] rnd_c = {rnd_reg[0],rnd_reg[1],rnd_reg[2],rnd_reg[2],rnd_reg[2],rnd_reg[2]};

wire [22:0] rnd;
lfsr random(rnd);

always @(negedge clk_pix) begin
	if(hc == 639) begin
		hc <= 0;
		if(vc == 311) begin 
			vc <= 0;
			vvc <= vvc + 9'd6;
		end else begin
			vc <= vc + 1'd1;
		end
	end else begin
		hc <= hc + 1'd1;
	end
	
	rnd_reg <= rnd;
end

reg  hb, vb;
reg  hs, vs;
wire blankn  = !(hb & vb);

always @(posedge clk_pix) begin
	if (hc == 310) hb <= 1;
		else if (hc == 420) hb <= 0;

	if (hc == 336) hs <= 1;
		else if (hc == 368) hs <= 0;

	if(vc == 308) vs <= 1;
		else if (vc == 0) vs <= 0;

	if(vc == 306) vb <= 1;
		else if (vc == 2) vb <= 0;
end

reg  [7:0] cos_out;
wire [5:0] cos_g = cos_out[7:3]+6'd32;
cos cos(vvc + {vc, 2'b00}, cos_out);

wire [5:0] comp_v = (cos_g >= rnd_c) ? cos_g - rnd_c : 6'd0;

wire [1:0] rotate;

mist_video #(.COLOR_DEPTH(6), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_x2           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? comp_v : 0   ),
	.G              ( blankn ? comp_v : 0   ),
	.B              ( blankn ? comp_v : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( 2'b11            ),
	.ce_divider     ( 1                ),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr          ( ypbpr            )
	);

endmodule

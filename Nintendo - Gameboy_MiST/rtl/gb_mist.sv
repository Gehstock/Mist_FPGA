//
// gb_mist.v
//
// Gameboy for the MIST board https://github.com/mist-devel
// 
// Copyright (c) 2015 Till Harbaum <till@harbaum.org> 
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//

module gb_mist (
   input [1:0] CLOCK_27,
	
 	output LED,
	
   // SPI interface to arm io controller
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SCK,
   input         SPI_SS2,
   input         SPI_SS3,
   input         SPI_SS4,
   input         CONF_DATA0, 
	
   // SDRAM interface
   inout [15:0]    SDRAM_DQ,       // SDRAM Data bus 16 Bits
   output [12:0]   SDRAM_A,        // SDRAM Address bus 13 Bits
   output          SDRAM_DQML,     // SDRAM Low-byte Data Mask
   output          SDRAM_DQMH,     // SDRAM High-byte Data Mask
   output          SDRAM_nWE,      // SDRAM Write Enable
   output          SDRAM_nCAS,     // SDRAM Column Address Strobe
   output          SDRAM_nRAS,     // SDRAM Row Address Strobe
   output          SDRAM_nCS,      // SDRAM Chip Select
   output [1:0]    SDRAM_BA,       // SDRAM Bank Address
   output          SDRAM_CLK,      // SDRAM Clock
   output          SDRAM_CKE,      // SDRAM Clock Enable

	// audio
   output 			AUDIO_L,
   output 			AUDIO_R,

	// video
   output 			VGA_HS,
   output 			VGA_VS,
   output [5:0] 	VGA_R,
   output [5:0] 	VGA_G,
   output [5:0] 	VGA_B
);

assign LED = !dio_download;

`include "rtl/build_id.sv" 
localparam CONF_STR = {
	"GAMEBOY;GBCSGB;",
	"F,GB;",
	"O12,LCD ,white,yellow,invert;",
	"O3,Boot,Normal,Fast;",
	"O45,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O6,Mapper,Detect,Force MBC1;",
	"T7,Reset;",	
	"V,v1.00.",`BUILD_DATE
};

wire 			clk32;
reg 			clk4;   // 4.194304 MHz CPU clock and GB pixel clock
reg 			clk8;   // 8.388608 MHz VGA pixel clock
reg 			clk16;   // 16.777216 MHz
wire 			pll_locked;
wire 			reset = (reset_cnt != 0);
reg   [9:0] reset_cnt;

wire [31:0] status;
wire  [1:0] buttons, switches;
wire  [7:0] kbjoy;
wire  [7:0] joy_0, joy_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire 			hs, vs;
wire  [5:0] r,g,b;
wire [15:0] audio_left;
wire [15:0] audio_right;

wire  [7:0] cart_di;    // data from cpu to cart
wire  [7:0] cart_do = cart_addr[0]?sdram_do[7:0]:sdram_do[15:8];
wire [15:0] cart_addr;
wire 			cart_rd;
wire 			cart_wr;
reg			eject = 1'b0;

wire 			lcd_clkena;
wire [1:0]  lcd_data;
wire [1:0]  lcd_mode;
wire 			lcd_on;
wire 			invert;
wire 			color;
	
// TODO: ds for cart ram write
wire  [1:0] sdram_ds = dio_download?2'b11:{!cart_addr[0], cart_addr[0]};
wire [15:0] sdram_do;
wire [15:0] sdram_di = dio_download?dio_data:{cart_di, cart_di};
wire [23:0] sdram_addr = dio_download?dio_addr:{3'b000, mbc_bank, cart_addr[12:1]};
wire 			sdram_oe = !dio_download && cart_rd;
wire 			sdram_we = (dio_download && dio_write) || (!dio_download && cart_ram_wr);
assign 		SDRAM_CKE = 1'b1;

wire 			dio_download;
wire [23:0] dio_addr;
wire [15:0] dio_data;
wire 			dio_write;	

pll pll (
	 .inclk0(CLOCK_27),
	 .c0(clk32),        // 33.557143 MHz
	 .c1(SDRAM_CLK),    // 33.557143 Mhz phase shifted
	 .locked(pll_locked)
	);

always @(posedge clk8) 
	clk4 <= !clk4;

always @(posedge clk16) 
	clk8 <= !clk8;

always @(posedge clk32) 
	clk16 <= !clk16;


always @(posedge clk4) begin
	if(status[0] || status[7] || buttons[1] || !pll_locked || dio_download)
		reset_cnt <= 10'd1023;
	else
		if(reset_cnt != 0)
			reset_cnt <= reset_cnt - 10'd1;
end

gb gb (
	.reset	    	( reset       ),
	.clk         	( clk4        ),
	.fast_boot   	( status[3]   ),
	.joystick    	( joy0 | joy_1 | kbjoy),
	.cart_addr   	( cart_addr   ),
	.cart_rd     	( cart_rd     ),
	.cart_wr     	( cart_wr     ),
	.cart_do     	( cart_do     ),
	.cart_di     	( cart_di     ),
	.audio_l 	 	( audio_left  ),
	.audio_r 	 	( audio_right ),
	.lcd_clkena  	( lcd_clkena  ),
	.lcd_data    	( lcd_data    ),
	.lcd_mode    	( lcd_mode    ),
	.lcd_on      	( lcd_on      )
);

dac dacL(
	.CLK			( clk32 					),
	.RESET		( reset       			),
	.DACin		( audio_left[15:1]	),
	.DACout		( AUDIO_L				)
	);

dac dacR(
	.CLK			( clk32 					),
	.RESET		( reset       			),
	.DACin		( audio_right[15:1]	),
	.DACout		( AUDIO_R				)
	);

lcd lcd (
	 .pclk   		( clk8      ),
	 .clk    ( clk4      ),
	 .tint   ( status[2:1] == 1 ? 1 : 0 ),
	 .inv    ( status[2:1] == 2 ? 1 : 0 ),
	 .clkena ( lcd_clkena),
	 .data   ( lcd_data  ),
	 .mode   ( lcd_mode  ),  // used to detect begin of new lines and frames
	 .on     ( lcd_on    ),	 
  	 .hs     ( hs    		),
	 .vs     ( vs    		),
	 .r      ( r     		),
	 .g      ( g     		),
	 .b      ( b     		)
	);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        	(clk32          	),
	.conf_str       	(CONF_STR       	),
	.SPI_SCK        	(SPI_SCK        	),
	.CONF_DATA0     	(CONF_DATA0     	),
	.SPI_SS2			 	(SPI_SS2        	),
	.SPI_DO         	(SPI_DO         	),
	.SPI_DI         	(SPI_DI         	),
	.buttons        	(buttons        	),
	.switches   	 	(switches       	),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr          	(ypbpr          	),
	.ps2_kbd_clk    	(ps2_kbd_clk    	),
	.ps2_kbd_data   	(ps2_kbd_data   	),
	.joystick_0   	 	(joy_0     			),
	.joystick_1     	(joy_1     			),
	.status         	(status         	)
	);
	
sdram sdram (
   .sd_data        (SDRAM_DQ                  ),
   .sd_addr        (SDRAM_A                   ),
   .sd_dqm         ({SDRAM_DQMH, SDRAM_DQML}  ),
   .sd_cs          (SDRAM_nCS                 ),
   .sd_ba          (SDRAM_BA                  ),
   .sd_we          (SDRAM_nWE                 ),
   .sd_ras         (SDRAM_nRAS                ),
   .sd_cas         (SDRAM_nCAS                ),
   .clk            (clk32                     ),
   .clkref         (clk4                      ),
   .init           (!pll_locked | eject       ),
   .din            (sdram_di                  ),
   .addr           (sdram_addr                ),
   .ds             (sdram_ds                  ),
   .we             (sdram_we                  ),
   .oe             (sdram_oe                  ),
   .dout           (sdram_do                  )
	);	

// include ROM download helper
data_io data_io (

   .sck 					(SPI_SCK 		),
   .ss  					( SPI_SS2 		),
   .sdi 					( SPI_DI  		),
   .downloading 		( dio_download ),
   .clk   				( clk4      	),
   .wr    				( dio_write 	),
   .addr  				( dio_addr  	),
   .data  				( dio_data  	)
	);

video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys				(clk32			),
	.ce_pix				(clk16			),
	.ce_pix_actual		(clk16			),
	.SPI_SCK				(SPI_SCK			),
	.SPI_SS3				(SPI_SS3			),
	.SPI_DI				(SPI_DI			),
	.R						(r					),
	.G						(g					),
	.B						(b					),
	.HSync				(hs				),
	.VSync				(vs				),
	.VGA_R				(VGA_R			),
	.VGA_G				(VGA_G			),
	.VGA_B				(VGA_B			),
	.VGA_VS				(VGA_VS			),
	.VGA_HS				(VGA_HS			),
	.scandoubler_disable(1				),//(scandoubler_disable),   //VGA Only
	.scanlines(scandoubler_disable ? 2'b00 : {status[5:4] == 3, status[5:4] == 2}),
	.hq2x					(status[5:4]==1),
	.ypbpr_full			(1					),
	.line_start			(0					),
	.mono					(0					)
	);

keyboard keyboard(
	.clk(clk32),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


// TODO: RAM bank
// http://fms.komkon.org/GameBoy/Tech/Carts.html

// 32MB SDRAM memory map using word addresses
// 2 2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 D
// 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 S
// -------------------------------------------------
// 0 0 0 0 X X X X X X X X X X X X X X X X X X X X X up to 2MB used as ROM
// 0 0 0 1 X X X X X X X X X X X X X X X X X X X X X up to 2MB used as RAM
// 0 0 0 0 R R B B B B B C C C C C C C C C C C C C C MBC1 ROM (R=RAM bank in mode 0)
// 0 0 0 1 0 0 0 0 0 0 R R C C C C C C C C C C C C C MBC1 RAM (R=RAM bank in mode 1)

// ---------------------------------------------------------------
// ----------------------------- MBC1 ----------------------------
// ---------------------------------------------------------------

wire [8:0] mbc1_addr = 
	(cart_addr[15:14] == 2'b00)?{8'b000000000, cart_addr[13]}:        // 16k ROM Bank 0
	(cart_addr[15:14] == 2'b01)?{1'b0, mbc1_rom_bank, cart_addr[13]}: // 16k ROM Bank 1-127
	(cart_addr[15:13] == 3'b101)?{7'b1000000, mbc1_ram_bank}:         // 8k RAM Bank 0-3
	9'd0;
	
wire [8:0] mbc2_addr = 
	(cart_addr[15:14] == 2'b00)?{8'b000000000, cart_addr[13]}:        // 16k ROM Bank 0
	(cart_addr[15:14] == 2'b01)?{1'b0, mbc2_rom_bank, cart_addr[13]}: // 16k ROM Bank 1-15
   //todo         																	// 512x4bits RAM, built-in into the MBC2 chip (Read/Write)
	9'd0;	

// -------------------------- RAM banking ------------------------

// in mode 0 (16/8 mode) the ram is not banked 
// in mode 1 (4/32 mode) four ram banks are used
wire [1:0] mbc1_ram_bank = (mbc1_mode ? mbc1_ram_bank_reg:2'b00) & ram_mask;
wire [1:0] mbc2_ram_bank = (mbc2_mode ? mbc2_ram_bank_reg:2'b00) & ram_mask;//todo
// -------------------------- ROM banking ------------------------
   
// in mode 0 (16/8 mode) the ram bank select signals are the upper rom address lines 
// in mode 1 (4/32 mode) the upper two rom address lines are 2'b00
wire [6:0] mbc1_rom_bank_mode = { mbc1_mode?2'b00:mbc1_ram_bank_reg, mbc1_rom_bank_reg};
wire [6:0] mbc2_rom_bank_mode = { mbc2_mode?2'b00:mbc2_ram_bank_reg, mbc2_rom_bank_reg};//todo
// mask address lines to enable proper mirroring
wire [6:0] mbc1_rom_bank = mbc1_rom_bank_mode & rom_mask;//128
wire [6:0] mbc2_rom_bank = mbc2_rom_bank_mode & rom_mask;//16
// --------------------- CPU register interface ------------------
reg mbc1_ram_enable;
reg mbc1_mode;
reg [4:0] mbc1_rom_bank_reg;
reg [1:0] mbc1_ram_bank_reg;

reg mbc2_ram_enable;
reg mbc2_mode;
reg [4:0] mbc2_rom_bank_reg;//todo
reg [1:0] mbc2_ram_bank_reg;//todo


// MBC2 todo
always @(posedge clk4) begin
	if(reset) begin
		mbc1_rom_bank_reg <= 5'd1;
		mbc1_ram_bank_reg <= 2'd0;
      mbc1_ram_enable <= 1'b0;
      mbc1_mode <= 1'b0;
	end else begin
		if(cart_wr && (cart_addr[15:13] == 3'b000))
			mbc1_ram_enable <= (cart_di[3:0] == 4'ha);
		if(cart_wr && (cart_addr[15:13] == 3'b001)) begin
			if(cart_di[4:0]==0) mbc1_rom_bank_reg <= 5'd1;
			else   				  mbc1_rom_bank_reg <= cart_di[4:0];
		end	
		if(cart_wr && (cart_addr[15:13] == 3'b010))
			mbc1_ram_bank_reg <= cart_di[1:0];
		if(cart_wr && (cart_addr[15:13] == 3'b011))
			mbc1_mode <= cart_di[0];
	end
//	eject <= status[8];
end

// extract header fields extracted from cartridge
// during download
reg [7:0] cart_mbc_type;
reg [7:0] cart_rom_size;
reg [7:0] cart_ram_size;
reg [7:0] cgb_flag;//$80 = GBC but GB compatible, $C0 GBC Only, $00 or other = GB
reg [7:0] sgb_flag;//GB/SGB Indicator (00 = GameBoy, 03 = Super GameBoy functions)
						 //(Super GameBoy functions won't work if <> $03.)

// only write sdram if the write attept comes from the cart ram area
wire cart_ram_wr = cart_wr && mbc1_ram_enable && (cart_addr[15:13] == 3'b101);
   
// RAM size - todo
wire [1:0] ram_mask =              			// 0 - no ram
	   (cart_ram_size == 1)?2'b00:  			// 1 - 2k, 1 bank
	   (cart_ram_size == 2)?2'b00:  			// 2 - 8k, 1 bank
	   2'b11;                       			// 3 - 32k, 4 banks
														// 4 - 128k, ?? banks
														// 5 - 64k, ?? banks

// ROM size
wire [6:0] rom_mask =                   	// 0 - 2 banks, 32k direct mapped
	   (cart_rom_size == 1)?7'b0000011:  	// 1 - 4 banks = 64k
	   (cart_rom_size == 2)?7'b0000111:  	// 2 - 8 banks = 128k
	   (cart_rom_size == 3)?7'b0001111:  	// 3 - 16 banks = 256k
	   (cart_rom_size == 4)?7'b0011111:  	// 4 - 32 banks = 512k
	   (cart_rom_size == 5)?7'b0111111:  	// 5 - 64 banks = 1M
	   (cart_rom_size == 6)?7'b1111111:    // 6 - 128 banks = 2M		
//?		(cart_rom_size == 6)?7'b1111111:    // 7 - ??? banks = 4M
//?		(cart_rom_size == 6)?7'b1111111:    // 8 - ??? banks = 8M
		(cart_rom_size == 82)?7'b1000111:   //$52 - 72 banks = 1.1M
		(cart_rom_size == 83)?7'b1001111:   //$53 - 80 banks = 1.2M
//		(cart_rom_size == 84)?7'b1011111:
                            7'b1011111;   //$54 - 96 banks = 1.5M

wire mbc1 = (cart_mbc_type == 1) || (cart_mbc_type == 2) || (cart_mbc_type == 3) || ~status[6];
wire mbc2 = (cart_mbc_type == 5) || (cart_mbc_type == 6);
wire mmm01 = (cart_mbc_type == 11) || (cart_mbc_type == 12) || (cart_mbc_type == 13) || (cart_mbc_type == 14);
wire mbc3 = (cart_mbc_type == 15) || (cart_mbc_type == 16) || (cart_mbc_type == 17) || (cart_mbc_type == 18) || (cart_mbc_type == 19);
wire mbc4 = (cart_mbc_type == 21) || (cart_mbc_type == 22) || (cart_mbc_type == 23);
wire mbc5 = (cart_mbc_type == 25) || (cart_mbc_type == 26) || (cart_mbc_type == 27) || (cart_mbc_type == 28) || (cart_mbc_type == 29) || (cart_mbc_type == 30);
wire tama5 = (cart_mbc_type == 253);
//wire tama6 = (cart_mbc_type == ???);
wire HuC1 = (cart_mbc_type == 254);
wire HuC3 = (cart_mbc_type == 255);

wire [8:0] mbc_bank =
	mbc1?mbc1_addr:                  // MBC1, 16k bank 0, 16k bank 1-127 + ram
	mbc2?mbc2_addr:                  // MBC2, 16k bank 0, 16k bank 1-15 + ram
//	mbc3?mbc3_addr:
//	mbc4?mbc4_addr:
//	mbc5?mbc5_addr:
//	tama5?tama5_addr:
//	HuC1?HuC1_addr:
//	HuC3?HuC3_addr:
	{7'b0000000, cart_addr[14:13]};  // no MBC, 32k linear address


always @(posedge clk4) begin
	if(!pll_locked) begin
		cart_mbc_type <= 8'h00;
		cart_rom_size <= 8'h00;
		cart_ram_size <= 8'h00;
	end else begin
		if(dio_download && dio_write) begin
			// cart is stored in 16 bit wide sdram, so addresses are shifted right
			case(dio_addr)
				24'h9f:  cgb_flag <= dio_data[7:0];                    // $143
				24'ha2:  sgb_flag <= dio_data[7:0];                    // $146
				24'ha3:  cart_mbc_type <= dio_data[7:0];                 // $147
				24'ha4: { cart_rom_size, cart_ram_size } <= dio_data;    // $148/$149
			endcase
		end
	end
end
		


endmodule

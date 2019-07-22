module PIXEL_DISPLAY (
	pixel_clock,
	reset,

	show_border,

	// mode
	ag,
	gm,
	css,

	// text
	char_column,
	char_line,
	subchar_line,
	subchar_pixel,

	// graph
	graph_pixel,
	graph_line_2x,
	graph_line_3x,

	// vram
	vram_rd_enable,
	vram_addr,
	vram_data,

	// vga
	vga_red,
	vga_green,
	vga_blue
);

input					pixel_clock;
input					reset;

input					show_border;

// mode
input					ag;
input			[2:0]	gm;
input					css;

// text
input			[6:0]	char_column;		// character number on the current line
input			[6:0]	char_line;			// line number on the screen
input			[4:0]	subchar_line;		// the line number within a character block 0-8
input			[3:0]	subchar_pixel;		// the pixel number within a character block 0-8

// graph
input			[8:0]	graph_pixel;		// pixel number on the current line
input			[9:0]	graph_line_2x;		// line number on the screen
input			[9:0]	graph_line_3x;		// line number on the screen

output					vram_rd_enable;
output	reg		[12:0]	vram_addr;
input			[7:0] 	vram_data;

output			[7:0]	vga_red;
output			[7:0]	vga_green;
output			[7:0]	vga_blue;


//// Label Definitions ////

// Note: all labels must match their defined length--shorter labels will be padded with solid blocks,
// and longer labels will be truncated

// 48 character label for the example text

wire				pixel_on;					// high => output foreground color, low => output background color


// 8p   代表每个点占用VGA水平 8 pixel
// 2bit 代表每个点取2位值

wire	[1:0]		pixel_8p_2bit;				// high => output foreground color, low => output background color
wire	[1:0]		pixel_4p_2bit;				// high => output foreground color, low => output background color
wire				pixel_4p_1bit;				// high => output foreground color, low => output background color
wire				pixel_2p_1bit;				// high => output foreground color, low => output background color

reg		[7:0] 		latched_vram_data;			// the data that will be written to character memory at the clock rise

// 锁存数据用于选择调色板
reg		[7:0] 		latched_palette_data;

assign vram_rd_enable = pixel_clock;

reg		[23:0] latched_vga_rgb;
wire	[23:0] vga_rgb;

// write the appropriate character data to memory

always @ (posedge pixel_clock) begin
	if(ag==1'b0)
	begin
			if(subchar_pixel==4'b0001)
				vram_addr <= {4'b0,char_line[3:0], char_column[4:0]};
			// 对于同步sram需要等待 1 个时钟周期
			if(subchar_pixel==4'b0011)
				latched_vram_data <= vram_data;
			if(graph_pixel[3:0]==4'b0110)
				latched_palette_data <= latched_vram_data;
	end
	else
	begin
		case(gm)
		3'b000:
		begin
			// 64 x 64 x 4	gm: 000
			if(graph_pixel[4:0]==5'b00001)
				vram_addr <= {3'b0, graph_line_3x[9:4], graph_pixel[8:5]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[4:0]==5'b00011)
				latched_vram_data <= vram_data;
		end
		3'b001:
		begin
			// 128 x 64 x 2	gm: 001
			if(graph_pixel[4:0]==5'b00001)
				vram_addr <= {3'b0, graph_line_3x[9:4], graph_pixel[8:5]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[4:0]==5'b00011)
				latched_vram_data <= vram_data;
		end
		3'b011:
		begin
			// 128 x 96 x 2	gm: 011
			if(graph_pixel[4:0]==5'b00001)
				vram_addr <= {2'b0, graph_line_2x[9:3], graph_pixel[8:5]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[4:0]==5'b00011)
				latched_vram_data <= vram_data;
		end
		3'b100:
		begin
			// 128 x 96 x 4	gm: 100
			if(graph_pixel[3:0]==4'b0001)
				vram_addr <= {1'b0, graph_line_2x[8:1], graph_pixel[8:4]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[3:0]==4'b0011)
				latched_vram_data <= vram_data;
		end
		3'b101:
		begin
			// 128 x 192 x 2	gm: 101
			if(graph_pixel[4:0]==5'b00001)
				vram_addr <= {1'b0, graph_line_2x[9:1], graph_pixel[8:5]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[4:0]==5'b00011)
				latched_vram_data <= vram_data;
		end
		3'b110:
		begin
			// 128 x 192 x 4	gm: 110
			if(graph_pixel[3:0]==4'b0001)
				vram_addr <= {graph_line_2x[9:1], graph_pixel[8:4]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[3:0]==4'b0011)
				latched_vram_data <= vram_data;
		end
		3'b111:
		begin
			// 256 x 192 x 2	gm: 111
			if(graph_pixel[3:0]==4'b0001)
				vram_addr <= {graph_line_2x[9:1], graph_pixel[8:4]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[3:0]==4'b0011)
				latched_vram_data <= vram_data;
		end
		default:
		begin
			// 128 x 64 x 4 	gm: 010
			if(graph_pixel[3:0]==4'b0001)
				vram_addr <= {2'b0,graph_line_3x[9:3], graph_pixel[8:4]};
				//vram_addr <= {2'b0,graph_line_3x[8:3], graph_pixel[6:2]};
			// 对于同步sram需要等待 1 个时钟周期
			if(graph_pixel[3:0]==4'b0011)
				latched_vram_data <= vram_data;
		end
		endcase
	end
	latched_vga_rgb <= vga_rgb;
end

// palette
/*
位\色  绿   黄   蓝   红   浅黄  浅蓝  紫   橙
D6     0    0    0    0    1     1     1    1
D5     0    0    1    1    0     0     1    1
D4     0    1    0    1    0     1     0    1

0x07 0xff 0x00 // GREEN
0xff 0xff 0x00 // YELLOW
0x3b 0x08 0xff // BLUE
0xcc 0x00 0x3b // RED
0xff 0xff 0xff // BUFF
0x07 0xe3 0x99 // CYAN
0xff 0x1c 0xff // MAGENTA
0xff 0x81 0x00 // ORANGE

0x00 0x00 0x00 // BLACK
0x07 0xff 0x00 // GREEN
0x3b 0x08 0xff // BLUE
0xff 0xff 0xff // BUFF

*/

wire [2:0]	palette_bit_graph;

wire [23:0]	palette_rgb_border =	(~ag)?24'h000000:				// 字符模式背景
									(css)?24'hffffff:24'h07ff00;	// 图形模式背景

wire [23:0] palette_rgb_pixel = 24'h000000;
wire [23:0] palette_rgb_background = 24'h07ff00;

// 64 x 64 x 4		gm: 000
// 128 x 64 x 2		gm: 001
// 128 x 64 x 4 	gm: 010
// 128 x 96 x 2		gm: 011
// 128 x 96 x 4		gm: 100
// 128 x 192 x 2	gm: 101
// 128 x 192 x 4	gm: 110
// 256 x 192 x 2	gm: 111

//assign palette_bit_graph = (ag)? {css, pixel_4p_2bit} : latched_palette_data[6:4];

assign palette_bit_graph		=	(~ag)			?	latched_palette_data[6:4]				:
									(gm==3'b000)	?	{css, pixel_8p_2bit					}	:
									(gm==3'b001)	?	{css, pixel_4p_1bit, pixel_4p_1bit	}	:
									(gm==3'b010)	?	{css, pixel_4p_2bit					}	:
									(gm==3'b011)	?	{css, pixel_4p_1bit, pixel_4p_1bit	}	:
									(gm==3'b100)	?	{css, pixel_4p_2bit					}	:
									(gm==3'b101)	?	{css, pixel_4p_1bit, pixel_4p_1bit	}	:
									(gm==3'b110)	?	{css, pixel_4p_2bit					}	:
														{css, pixel_2p_1bit, pixel_2p_1bit	}	;

wire [23:0] palette_rgb_graph =	(palette_bit_graph==3'b000) ?	24'h07ff00 : // GREEN
								(palette_bit_graph==3'b001) ?	24'hffff00 : // YELLOW
								(palette_bit_graph==3'b010) ?	24'h3b08ff : // BLUE
								(palette_bit_graph==3'b011) ?	24'hcc003b : // RED
								(palette_bit_graph==3'b100) ?	24'hffffff : // BUFF
								(palette_bit_graph==3'b101) ?	24'h07e399 : // CYAN
								(palette_bit_graph==3'b110) ?	24'hff1cff : // MAGENTA
																24'hff8100 ; // ORANGE

/*
	24'h000000 // BLACK
	24'h07ff00 // GREEN
	24'h3b08ff // BLUE
	24'hffffff // BUFF
*/


// use the result of the character generator module to choose between the foreground and background color

assign vga_rgb =	(show_border)	? palette_rgb_border :
					(ag)			? palette_rgb_graph :
					(~pixel_on)		? palette_rgb_pixel :
					(latched_palette_data[7])	? palette_rgb_graph : palette_rgb_background;

assign vga_red = latched_vga_rgb[23:16];
assign vga_green = latched_vga_rgb[15:8];
assign vga_blue = latched_vga_rgb[7:0];


// the character generator block includes the character RAM
// and the character generator ROM
CHAR_GEN CHAR_GEN
(
	.reset(reset),					// reset signal

	.char_code(latched_vram_data),
	.subchar_line(subchar_line),	// current line of pixels within current character
	.subchar_pixel(subchar_pixel),	// current column of pixels withing current character

	.pixel_clock(pixel_clock),		// read clock
	.pixel_on(pixel_on)				// read data
);

PIXEL_GEN PIXEL_GEN
(
	.reset(reset),					// reset signal

	.pixel_code(latched_vram_data),
	.graph_pixel(graph_pixel),		// current column of pixels withing current character

	.pixel_clock(pixel_clock),		// read clock

	.pixel_8p_2bit(pixel_8p_2bit),	//	64x64x4
	.pixel_4p_2bit(pixel_4p_2bit),	//	128x64x4 128x96x4 128x192x4
	.pixel_4p_1bit(pixel_4p_1bit),	//	128x64x2 128x96x2 128x192x2
	.pixel_2p_1bit(pixel_2p_1bit)	//	256x192x2
);

endmodule //CHAR_DISPLAY

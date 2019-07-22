`include "SVGA_DEFINES.v"


`define SVGA_DECODE_DELAY  7
// 延时：字符模式
// 1、(001)锁存 vram 地址，2、(010)读取 vram  3、(011)锁存 vram 数据 4、(100)字库地址 5、(101)锁存字库 
// 6、(110)移位得到点阵，同时锁存vram数据用于调色板 7、(111)建立调色板，锁存色彩

// Delay: Character mode
// 1 (001) latch vram address, 2, (010) read vram 3, (011) latch vram data 4, (100) font address 5, (101) latch font
// 6, (110) shift to get a lattice, while latching vram data for the palette 7, (111) to create a palette, latch color

// 延时：图形模式 128x64 4色
// 1、(001)锁存 vram 地址，2、(010)读取 vram  3、(011)锁存 vram 数据 4、(100)空 5、(101)数据锁存至移位寄存器
// 6、(110)移位得到点阵 7、(111)建立调色板，锁存色彩

// Delay: graphics mode 128x64 4 colors
// 1, (001) latch vram address, 2, (010) read vram 3, (011) latch vram data 4, (100) empty 5, (101) data latched to the shift register
// 6, (110) shift to get the dot matrix 7, (111) to create a palette, latch color

module SVGA_TIMING_GENERATION
(
	pixel_clock,
	reset,
	h_synch,
	v_synch,
	blank,
	pixel_count,
	line_count,

	show_border,

	// text
	subchar_pixel,
	subchar_line,
	char_column,
	char_line,

	// graph
	graph_pixel,
	graph_line_2x,
	graph_line_3x
);

input 				pixel_clock;		// pixel clock
input 				reset;				// reset
(*keep*)output	reg			h_synch;			// horizontal synch for VGA connector
(*keep*)output	reg			v_synch;			// vertical synch for VGA connector
output	reg			blank;				// composite blanking
output	reg	[10:0]	pixel_count;		// counts the pixels in a line
output	reg	[9:0]	line_count;			// counts the display lines

(*keep*)output	reg			show_border;

// 字符控制
(*keep*)output	reg	[3:0]	subchar_pixel;		// pixel position within the character
(*keep*)output	reg	[4:0]	subchar_line;		// identifies the line number within a character block
(*keep*)output	reg	[6:0]	char_column;		// character number on the current line
(*keep*)output	reg	[6:0]	char_line;			// line number on the screen

// 图形控制 128*64
(*keep*)output	reg		[8:0]	graph_pixel;
(*keep*)output	reg		[9:0]	graph_line_3x;

// 图形控制 256*192
(*keep*)output	reg		[9:0]	graph_line_2x;

(*keep*)reg			h_blank;
reg			v_blank;

reg			show_pixel;
reg			show_line;

// CREATE THE HORIZONTAL LINE PIXEL COUNTER
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		// on reset set pixel counter to 0
		pixel_count <= 11'd0;

	else if (pixel_count == (`H_TOTAL - 1))
		// last pixel in the line, so reset pixel counter
		pixel_count <= 11'd0;

	else
		pixel_count <= pixel_count + 1;
end

// CREATE THE HORIZONTAL SYNCH PULSE
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		// on reset remove h_synch
		h_synch <= 1'b0;

	else if (pixel_count == (`H_ACTIVE + `H_FRONT_PORCH - 1))
		// start of h_synch
		h_synch <= 1'b1;

	else if (pixel_count == (`H_TOTAL - `H_BACK_PORCH - 1))
		// end of h_synch
		h_synch <= 1'b0;
end

// CREATE THE VERTICAL FRAME LINE COUNTER
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		// on reset set line counter to 0
		line_count <= 10'd0;

	else if ((line_count == (`V_TOTAL - 1)) & (pixel_count == (`H_TOTAL - 1)))
		// last pixel in last line of frame, so reset line counter
		line_count <= 10'd0;

	else if ((pixel_count == (`H_TOTAL - 1)))
		// last pixel but not last line, so increment line counter
		line_count <= line_count + 1;
end

// CREATE THE VERTICAL SYNCH PULSE
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		// on reset remove v_synch
		v_synch <= 1'b0;

	else if ((line_count == (`V_ACTIVE + `V_FRONT_PORCH - 1) &
		   (pixel_count == `H_TOTAL - 1)))
		// start of v_synch
		v_synch <= 1'b1;

	else if ((line_count == (`V_TOTAL - `V_BACK_PORCH - 1)) &
		   (pixel_count == (`H_TOTAL - 1)))
		// end of v_synch
		v_synch <= 1'b0;
end


// CREATE THE HORIZONTAL BLANKING SIGNAL
// the "-2" is used instead of "-1" because of the extra register delay
// for the composite blanking signal
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		// on reset remove the h_blank
		h_blank <= 1'b0;

	else if (pixel_count == (`H_ACTIVE -2))
		// start of HBI
		h_blank <= 1'b1;

	else if (pixel_count == (`H_TOTAL -2))
		// end of HBI
		h_blank <= 1'b0;
end


// CREATE THE VERTICAL BLANKING SIGNAL
// the "-2" is used instead of "-1"  in the horizontal factor because of the extra
// register delay for the composite blanking signal
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		// on reset remove v_blank
		v_blank <= 1'b0;

	else if ((line_count == (`V_ACTIVE - 1) &
		   (pixel_count == `H_TOTAL - 2)))
		// start of VBI
		v_blank <= 1'b1;

	else if ((line_count == (`V_TOTAL - 1)) &
		   (pixel_count == (`H_TOTAL - 2)))
		// end of VBI
		v_blank <= 1'b0;
end


// CREATE THE COMPOSITE BANKING SIGNAL
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		// on reset remove blank
		blank <= 1'b0;

	// blank during HBI or VBI
	else if (h_blank || v_blank)
		blank <= 1'b1;

	else
		// active video do not blank
		blank <= 1'b0;
end


////////////////////////////////////////////////////
// 以上部分内容相对固定，是VGA的控制信号和计数器  //
////////////////////////////////////////////////////


/*
   CREATE THE CHARACTER COUNTER.
   CHARACTERS ARE DEFINED WITHIN AN 8 x 8 PIXEL BLOCK.

	A 640  x 480 video mode will display 80  characters on 60 lines.
	A 800  x 600 video mode will display 100 characters on 75 lines.
	A 1024 x 768 video mode will display 128 characters on 96 lines.

	"subchar_line" identifies the row in the 8 x 8 block.
	"subchar_pixel" identifies the column in the 8 x 8 block.
*/

// 8x12点阵 32x16个字符 256x192
// 640x480 倍线 512x384 左右各空64个点，上下空 48 个点。
// 需要生成四个数据：
// 字符点阵 subchar_line subchar_pixel
// 字符寻址 char_column char_line

always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		show_pixel <= 1'b0;
	else if (pixel_count == (-1) + 64 - `SVGA_DECODE_DELAY)
		show_pixel <= 1'b1;
	else if (pixel_count == (`H_ACTIVE - 1) - 64 - `SVGA_DECODE_DELAY)
		show_pixel <= 1'b0;
end

always @ (posedge h_synch or posedge reset) begin
	if (reset)
		show_line <= 1'b0;
	else if (line_count == (-1) + 48)
		show_line <= 1'b1;
	else if (line_count == (`V_ACTIVE - 1) - 48)
		show_line <= 1'b0;
end

always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		show_border <= 1'b1;
	else if (pixel_count == (-1) + 64)
		show_border <= ~show_line;
	else if (pixel_count == (`H_ACTIVE - 1) - 64)
		show_border <= 1'b1;
end


// text 32x16

always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
	begin
		// reset to 5 so that the first character data can be latched
		subchar_pixel <= 4'b0000;
		char_column <= 7'd0;
	end
	else if (h_synch)
	begin
		// reset to 5 so that the first character data can be latched
		subchar_pixel <= 4'b0000;
		char_column <= 7'd0;
	end
	else if(show_pixel)
	begin
		subchar_pixel <= subchar_pixel + 1;
		if(subchar_pixel == 4'b1111)			// 8*2-1
			char_column <= char_column + 1;
	end
end


always @ (posedge h_synch or posedge reset) begin
	if (reset)
	begin
		// on reset set line counter to 0
		subchar_line <= 5'b00000;
		char_line <= 7'd0;
	end
	else if(v_synch)
	begin
		// reset line counter
		subchar_line <= 5'b00000;
		char_line <= 7'd0;
	end
	else if(show_line)
		if(subchar_line == 5'd23)		// 12*2-1
		begin
			subchar_line <= 5'b00000;
			char_line <= char_line + 1;
		end
		else
			// increment line counter
			subchar_line <= subchar_line + 1;
end


// 为所有图形模式提供水平计数
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
	begin
		// reset to 5 so that the first character data can be latched
		graph_pixel <= 9'd0;
	end
	else if (h_synch)
	begin
		// reset to 5 so that the first character data can be latched
		graph_pixel <= 9'd0;
	end
	else if(show_pixel)
	begin
		graph_pixel <= graph_pixel + 1;
	end
end

// 为图形模式提供垂直计数
// 64x64  4色
// 128x64  2色
// 128x64  4色
always @ (posedge h_synch or posedge reset) begin
	if (reset)
	begin
		// on reset set line counter to 0
		graph_line_3x <= 10'd0;
	end
	else if(v_synch)
	begin
		// reset line counter
		graph_line_3x <= 10'd0;
	end
	else if(show_line)
		if(graph_line_3x[1:0] == 2'b10)		// 3行为单位计数
			graph_line_3x <= graph_line_3x + 2;
		else
			// increment line counter
			graph_line_3x <= graph_line_3x + 1;
end

// 为图形模式提供垂直计数
// 128x96  2色
// 128x96  4色
// 128x192 2色
// 128x192 4色
// 256x192 2色
always @ (posedge h_synch or posedge reset) begin
	if (reset)
	begin
		// on reset set line counter to 0
		graph_line_2x <= 10'd0;
	end
	else if(v_synch)
	begin
		// reset line counter
		graph_line_2x <= 10'd0;
	end
	else if(show_line)
		// increment line counter
		graph_line_2x <= graph_line_2x + 1;
end

endmodule //SVGA_TIMING_GENERATION

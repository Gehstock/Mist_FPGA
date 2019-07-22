module PIXEL_GEN(
	// control
	reset,

	pixel_code,
	graph_pixel,

	pixel_clock,

	pixel_8p_2bit,	//	64x64x4
	pixel_4p_2bit,	//	128x64x4 128x96x4 128x192x4
	pixel_4p_1bit,	//	128x64x2 128x96x2 128x192x2
	pixel_2p_1bit	//	256x192x2
);


input				reset;

input	[7:0]		pixel_code;
input	[8:0]		graph_pixel;		// pixel number on the current line

input				pixel_clock;

output	reg	[1:0]	pixel_8p_2bit;
output	reg	[1:0]	pixel_4p_2bit;
output	reg			pixel_4p_1bit;
output	reg			pixel_2p_1bit;

reg		[7:0]		latched_8p_2bit_data;
reg		[7:0]		latched_4p_2bit_data;
reg		[7:0]		latched_4p_1bit_data;
reg		[7:0]		latched_2p_1bit_data;


// 移位寄存器有四种模式
// 每2个点 移 1 位
// 每4个点 移 2 位
// 每4个点 移 1 位
// 每8个点 移 2 位


// serialize the GRAPH MODE data
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
 		begin
			pixel_8p_2bit			<=	2'b00;
			latched_8p_2bit_data	<=	8'h00;
		end
	else begin
		case(graph_pixel[4:0])
			5'b00101:
				latched_8p_2bit_data[7:0]	<=	pixel_code;
			default:
				if(graph_pixel[3:0]==3'b110)
					{pixel_8p_2bit,latched_8p_2bit_data[7:2]}	<=	latched_8p_2bit_data[7:0];
		endcase
		end

	end


// 延时：图形模式 128x64 4色
// 1、(001)锁存 vram 地址，2、(010)读取 vram  3、(011)锁存 vram 数据 4、(100)空 5、(101)数据锁存至移位寄存器
// 6、(110)移位得到点阵 7、(111)建立调色板，锁存色彩

// serialize the GRAPH MODE data
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
 		begin
			pixel_4p_2bit			<=	2'b00;
			latched_4p_2bit_data	<=	8'h00;
		end
	else begin
		case(graph_pixel[3:0])
			4'b0101:
				latched_4p_2bit_data[7:0]	<=	pixel_code;
			default:
				if(graph_pixel[1:0]==2'b10)
					{pixel_4p_2bit,latched_4p_2bit_data[7:2]}	<=	latched_4p_2bit_data[7:0];
		endcase
		end

	end


// serialize the GRAPH MODE data
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
 		begin
			pixel_4p_1bit			<=	2'b00;
			latched_4p_1bit_data	<=	8'h00;
		end
	else begin
		case(graph_pixel[4:0])
			5'b00101:
				latched_4p_1bit_data[7:0]	<=	pixel_code;
			default:
				if(graph_pixel[1:0]==2'b10)
					{pixel_4p_1bit,latched_4p_1bit_data[7:1]}	<=	latched_4p_1bit_data[7:0];
		endcase
		end

	end


// 延时：图形模式 256x192 2色
// 1、(001)锁存 vram 地址，2、(010)读取 vram  3、(011)锁存 vram 数据 4、(100)空 5、(101)数据锁存至移位寄存器
// 6、(110)移位得到点阵 7、(111)建立调色板，锁存色彩

// serialize the GRAPH MODE data
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
		begin
			pixel_2p_1bit			<=	1'b0;
			latched_2p_1bit_data	<=	8'h00;
		end
	else begin
		case(graph_pixel[3:0])
			4'b0101:
				latched_2p_1bit_data[7:0]	<=	pixel_code;
			default:
				if(graph_pixel[0]==1'b0)
					{pixel_2p_1bit,latched_2p_1bit_data[7:1]}	<=	latched_2p_1bit_data[7:0];
		endcase
		end

	end

endmodule //PIXEL_GEN

module vdp_shift(
	clk40m,
	rst_n,
	pattern,
	color,
	color1,
	color0,
	load,
	text_mode,
	color_1,
	color_0,
	pixel
);

	input		clk40m;
	input		rst_n;
	input		[ 7 : 0 ] pattern;
	input		[ 7 : 0 ] color;
	input		[ 3 : 0 ] color1;
	input		[ 3 : 0 ] color0;
	input 	load;
	input		text_mode;
	output	[ 3 : 0 ] color_1;
	output	[ 3 : 0 ] color_0;
	output	pixel;
	
	reg [ 3 : 0 ] color_1;
	reg [ 3 : 0 ] color_0;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			color_1 <= 0;
			color_0 <= 0;
		end else if( load ) begin
			color_1 <= text_mode ? color1 : color[ 7 : 4 ];
			color_0 <= text_mode ? color0 : color[ 3 : 0 ];
		end
	end
	
	reg pixel;
	reg [ 6 : 0 ] shift;
	reg [ 1 : 0 ] hrep;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			pixel <= 0;
			shift <= 0;
			hrep <= 0;
		end else if( load ) begin
			hrep <= 0;
			{ pixel, shift } <= pattern;
		end else if( hrep == 2 ) begin
			hrep <= 0;
			{ pixel, shift } <= { shift[ 6 : 0 ], 1'b0 };
		end else begin
			hrep <= hrep + 1'b1;
		end
	end
	
endmodule

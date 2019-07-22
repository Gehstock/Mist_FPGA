module vdp_colormap(
	clk,
	rst_n,
	visible,
	border,
	pattern,
	color1,
	color0,
	bgcolor,
	spr_pat,
	spr_color,
	r,
	g,
	b
);

	input		clk;
	input		rst_n;
	input		visible;
	input		border;
	input		pattern;
	input		[ 3 : 0 ] color1;
	input		[ 3 : 0 ] color0;
	input		[ 3 : 0 ] bgcolor;
	input		spr_pat;
	input		[ 3 : 0 ] spr_color;
	output	[ 3 : 0 ] r;
	output	[ 3 : 0 ] g;
	output	[ 3 : 0 ] b;
	
`define TRANSPARENT 0
`define BLACK 1
`define MEDIUM_GREEN 2
`define LIGHT_GREEN 3
`define DARK_BLUE 4
`define LIGHT_BLUE 5
`define DARK_RED 6
`define CYAN 7
`define MEDIUM_RED 8
`define LIGHT_RED 9
`define DARK_YELLOW 10
`define LIGHT_YELLOW 11
`define DARK_GREEN 12
`define MAGENTA 13
`define GRAY 14
`define WHITE 15

	reg [ 3 : 0 ] colorsel;
	always @( visible or border or bgcolor
		       or spr_pat or spr_color 
				 or pattern or color1 or color0 ) begin
		colorsel = `TRANSPARENT;
		if( !visible ) begin
			colorsel = `BLACK;
		end else if( border ) begin
			colorsel = bgcolor;
		end else if( spr_pat && spr_color != `TRANSPARENT ) begin
			colorsel = spr_color;
		end else if( pattern ) begin
			colorsel = color1;
		end else begin
			colorsel = color0;
		end
		if( colorsel == `TRANSPARENT ) begin
			colorsel = bgcolor;
		end
	end
	
	reg [ 3 : 0 ] red;
	reg [ 3 : 0 ] green;
	reg [ 3 : 0 ] blue;
	always @( colorsel ) begin
		case( colorsel )
			`TRANSPARENT, `BLACK: begin
				red <= 0;
				green <= 0;
				blue <= 0;
			end
			`MEDIUM_GREEN: begin
				red <= 3;
				green <= 13;
				blue <= 3;
			end
			`LIGHT_GREEN: begin
				red <= 7;
				green <= 15;
				blue <= 7;
			end
			`DARK_BLUE: begin
				red <= 3;
				green <= 3;
				blue <= 15;
			end
			`LIGHT_BLUE: begin
				red <= 5;
				green <= 7;
				blue <= 15;
			end
			`DARK_RED: begin
				red <= 11;
				green <= 3;
				blue <= 3;
			end
			`CYAN: begin
				red <= 5;
				green <= 13;
				blue <= 15;
			end
			`MEDIUM_RED: begin
				red <= 15;
				green <= 3;
				blue <= 3;
			end
			`LIGHT_RED: begin
				red <= 15;
				green <= 7;
				blue <= 7;
			end
			`DARK_YELLOW: begin
				red <= 13;
				green <= 13;
				blue <= 3;
			end
			`LIGHT_YELLOW: begin
				red <= 13;
				green <= 13;
				blue <= 9;
			end
			`DARK_GREEN: begin
				red <= 3;
				green <= 9;
				blue <= 3;
			end
			`MAGENTA: begin
				red <= 13;
				green <= 5;
				blue <= 11;
			end
			`GRAY: begin
				red <= 11;
				green <= 11;
				blue <= 11;
			end
			`WHITE: begin
				red <= 15;
				green <= 15;
				blue <= 15;
			end
		endcase
	end

	reg [ 3 : 0 ] r;
	reg [ 3 : 0 ] g;
	reg [ 3 : 0 ] b;
	always @( negedge rst_n or posedge clk ) begin
		if( !rst_n ) begin
			r <= 4'hF;
			g <= 4'hF;
			b <= 4'hF;
		end else begin
			// For inverting DAC.
			r <= ~red;
			g <= ~green;
			b <= ~blue;
		end
	end
	
endmodule

module vdp(
	clk40m,
	clk40m_n,
	cpu_rst_n,
 	cpu_a,
	cpu_din,
	cpu_dout,
	cpu_doe,
	cpu_in_n,
	cpu_out_n,
	cpu_int_n,
	sram_a,
	sram_din,
	sram_dout,
	sram_doe,
	sram_oe_n,
	sram_we_n,
	hsync,
	vsync,
	r,
	g,
	b
);

	// Clocks
	input		clk40m;
	input		clk40m_n;
	
	// CPU interface
	input		cpu_rst_n;
	input		[ 7 : 0 ] cpu_a;
	input		[ 7 : 0 ] cpu_din;
	output	[ 7 : 0 ] cpu_dout;
	output	cpu_doe;
	input		cpu_in_n;
	input		cpu_out_n;
	output	cpu_int_n;

	// SRAM interface
	output	[ 18 : 0 ] sram_a;
	input		[ 7 : 0 ] sram_din;
	output	[ 7 : 0 ] sram_dout;
	output	sram_doe;
	output	sram_oe_n;
	output	sram_we_n;
	
	// VGA interface
	output	hsync;			// Horizontal sync
	output	vsync;			// Vertical sync
	output	[ 3 : 0 ] r;
	output	[ 3 : 0 ] g;
	output	[ 3 : 0 ] b;

	// VDP I/O ports.
	parameter [ 7 : 0 ] cpu_vram_port = 8'h01;
	parameter [ 7 : 0 ] cpu_vdp_port = 8'h02;
	
	wire rst_n;
	
	wire vram_cpu_req;
	wire vram_cpu_ack;
	wire vram_cpu_wr;
	wire vram_ack;
	wire [ 13 : 0 ] vram_cpu_a;
	wire [ 7 : 0 ] vram_cpu_rdata;
	
	wire [ 7 : 0 ] vram_rdata;

	wire g1_mode;
	wire g2_mode;
	wire multi_mode;
	wire text_mode;
	wire gmode;
	wire blank_n;
	wire spr_size;
	wire spr_mag;
	wire [ 3 : 0 ] ntb;
	wire [ 7 : 0 ] colb;
	wire [ 2 : 0 ] pgb;
	wire [ 6 : 0 ] sab;
	wire [ 2 : 0 ] spgb;
	wire [ 3 : 0 ] color1;
	wire [ 3 : 0 ] color0;
	
	wire visible;
	wire border;
	wire start_vblank;
	wire set_mode;
	wire vram_req;
	wire vram_wr;
	wire [ 13 : 0 ] vram_addr;
	
	wire [ 7 : 0 ] pattern;
	wire [ 7 : 0 ] color;
	wire load;
	wire [ 3 : 0 ] color_1;
	wire [ 3 : 0 ] color_0;
	wire pixel;
	
	wire spr_pattern;
	wire [ 3 : 0 ] spr_color;
	wire spr_collide;
	wire spr_5;
	wire [ 4 : 0 ] spr_5num;
	wire spr_nolimit;
	
	assign rst_n = cpu_rst_n;

	assign sram_a[ 18 : 14 ] = 5'b00000;
	
	vdp_colormap colormap(
		clk40m,
		rst_n,
		visible,
		border,
		pixel,
		color_1,
		color_0,
		color0,
		spr_pattern,
		spr_color,
		r,
		g,
		b
	);
	
	vdp_shift shift(
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
	
	vdp_fsm fsm(
		clk40m,
		rst_n,
		g1_mode,
		g2_mode,
		multi_mode,
		gmode,
		text_mode,
		spr_size,
		spr_mag,
		blank_n,
		ntb,
		colb,
		pgb,
		sab,
		spgb,
		hsync,
		vsync,
		start_vblank,
		set_mode,
		visible,
		border,
		vram_req,
		vram_wr,
		vram_ack,
		vram_addr,
		vram_rdata,
		vram_cpu_req,
		vram_cpu_wr,
		vram_cpu_ack,
		vram_cpu_a,
		pattern,
		color,
		load,
		spr_pattern,
		spr_color,
		spr_collide,
		spr_5,
		spr_5num,
		spr_nolimit
	);
	
	// SRAM interface.
	vdp_sram sram(
		clk40m,
		clk40m_n,
		rst_n,
		vram_req,
		vram_wr,
		vram_ack,
		vram_addr,
		vram_rdata,
		sram_a[ 13 : 0 ],
		sram_din,
		sram_doe,
		sram_oe_n,
		sram_we_n
	);
	
	// CPU interface.
	vdp_cpu cpu(
		clk40m,
		rst_n,
		cpu_vram_port,
		cpu_vdp_port,
		cpu_a,
		cpu_din,
		cpu_dout,
		cpu_doe,
		cpu_in_n,
		cpu_out_n,
		cpu_int_n,
		vram_cpu_req,
		vram_cpu_ack,
		vram_cpu_wr,
		vram_cpu_a,
		sram_dout,
		vram_rdata,
		g1_mode,
		g2_mode,
		multi_mode,
		text_mode,
		gmode,
		blank_n,
		spr_size,
		spr_mag,
		ntb,
		colb,
		pgb,
		sab,
		spgb,
		color1,
		color0,
		spr_nolimit,
		spr_collide,
		spr_5,spr_5num,
		start_vblank,
		set_mode
	);

endmodule

module vdp_wrap(
	por_73_n,
	clk50m_17,
	push_144_n,
	led1_3_n,
	led2_7_n,
	led3_9_n,
	cpu_rst_n,
 	cpu_a,
	cpu_d,
	cpu_in_n,
	cpu_out_n,
	cpu_int_n,
	sram_a,
	sram_d,
	sram_oe_n,
	sram_we_n,
	hsync,
	vsync,
	r,
	g,
	b
);

	// Development board hardwired pins
	input		por_73_n;		// 100 ms time constant RC POR on pin 73
	input		clk50m_17;		// 50 MHz oscillator on pin 17
	input		push_144_n;		// Pushbutton on pin 144
	output	led1_3_n;		// LED on pin 3
	output	led2_7_n;		// LED on pin 7
	output	led3_9_n;		// LED on pin 9
	
	// CPU interface
	input		cpu_rst_n;
	input		[ 7 : 0 ] cpu_a;
	inout		[ 7 : 0 ] cpu_d;
	input		cpu_in_n;
	input		cpu_out_n;
	output	cpu_int_n;

	// SRAM interface
	output	[ 18 : 0 ] sram_a;
	inout		[ 7 : 0 ] sram_d;
	output	sram_oe_n;
	output	sram_we_n;
	
	// VGA interface
	output	hsync;			// Horizontal sync
	output	vsync;			// Vertical sync
	output	[ 3 : 0 ] r;
	output	[ 3 : 0 ] g;
	output	[ 3 : 0 ] b;

	wire [ 7 : 0 ] cpu_din;
	wire [ 7 : 0 ] cpu_dout;
	wire cpu_doe;
	
	assign cpu_din = cpu_d;
	assign cpu_d = cpu_doe ? cpu_dout : 8'hZZ;
	
	wire [ 7 : 0 ] sram_din;
	wire [ 7 : 0 ] sram_dout;
	wire sram_doe;
	
	assign sram_din = sram_d;
	assign sram_d = sram_doe ? sram_dout : 8'hZZ;
	
	// Give the LEDs something useless to do, to reduce synthesis warnings.
	assign led1_3_n = !( !por_73_n || !push_144_n );
	assign led2_7_n = !( !por_73_n || !push_144_n );
	assign led3_9_n = !( !por_73_n || !push_144_n );

	// PLL to convert 50 MHz to 40 MHz.
	wire clk40m, clk40m_n;
	vdp_clkgen clkgen(
		clk50m_17,
		clk40m,
		clk40m_n
	);

	vdp vdp1(
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

endmodule
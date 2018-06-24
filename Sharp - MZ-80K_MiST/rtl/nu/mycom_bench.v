`timescale 1ns/1ns
module mycom_bench;
	reg CLK_50MHZ;
	reg BTN_NORTH,BTN_EAST,BTN_SOUTH,BTN_WEST;
	reg [3:0] SW;
	wire [7:0] LED;
	wire VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC;
	reg	PS2_CLK, PS2_DATA;
	wire TP1;

	mycom mycom_1(CLK_50MHZ, BTN_NORTH,BTN_EAST,BTN_SOUTH,BTN_WEST,
	VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC,
	PS2_CLK, PS2_DATA,
 	 SW, LED, TP1);

	initial begin
			CLK_50MHZ <= 0;
			BTN_NORTH <= 1;
			BTN_EAST <= 0;
			BTN_SOUTH <= 0;
			BTN_WEST <= 0;
			PS2_CLK <= 0;
			PS2_DATA <= 0;
			SW <= 5;
		#400000
			$finish;
	end

	always #1 begin
		CLK_50MHZ <= ~CLK_50MHZ;
	end
endmodule

// Copyright (c) 2011 MiSTer-X

module VDPRAM400x2
(
	input				CL0,
	input [10:0]	AD0,
	input				WR0,
	input	 [7:0]	WD0,
	output [7:0]	RD0,

	input				CL1,
	input	 [9:0]	AD1,
	output [15:0]	RD1
);

reg A10;
always @( posedge CL0 ) A10 <= AD0[10];

wire [7:0] RD00, RD01;
DPRAM400 LS( CL0, AD0[9:0], WR0 & (~AD0[10]), WD0, RD00, CL1, AD1, 1'b0, 8'h0, RD1[ 7:0] );
DPRAM400 HS( CL0, AD0[9:0], WR0 & ( AD0[10]), WD0, RD01, CL1, AD1, 1'b0, 8'h0, RD1[15:8] );

assign RD0 = A10 ? RD01 : RD00;

endmodule


module DPRAM800
(
	input					CL0,
	input	[10:0]		AD0,
	input					WE0,
	input  [7:0]		WD0,
	output reg [7:0]	RD0,
	
	input					CL1,
	input	[10:0]		AD1,
	input					WE1,
	input  [7:0]		WD1,
	output reg [7:0]	RD1
);

reg [7:0] core[0:2047];

always @( posedge CL0 ) begin
	if (WE0) core[AD0] <= WD0;
	RD0 <= core[AD0];
end

always @( posedge CL1 ) begin
	if (WE1) core[AD1] <= WD1;
	RD1 <= core[AD1];
end

endmodule


module DPRAM400
(
	input					CL0,
	input	 [9:0]		AD0,
	input					WE0,
	input  [7:0]		WD0,
	output reg [7:0]	RD0,
	
	input					CL1,
	input	 [9:0]		AD1,
	input					WE1,
	input  [7:0]		WD1,
	output reg [7:0]	RD1
);

reg [7:0] core[0:1023];

always @( posedge CL0 ) begin
	if (WE0) core[AD0] <= WD0;
	RD0 <= core[AD0];
end

always @( posedge CL1 ) begin
	if (WE1) core[AD1] <= WD1;
	RD1 <= core[AD1];
end

endmodule


module DPRAM200
(
	input					CL0,
	input	 [8:0]		AD0,
	input					WE0,
	input  [7:0]		WD0,
	output reg [7:0]	RD0,
	
	input					CL1,
	input	 [8:0]		AD1,
	input					WE1,
	input  [7:0]		WD1,
	output reg [7:0]	RD1
);

reg [7:0] core[0:511];

always @( posedge CL0 ) begin
	if (WE0) core[AD0] <= WD0;
	RD0 <= core[AD0];
end

always @( posedge CL1 ) begin
	if (WE1) core[AD1] <= WD1;
	RD1 <= core[AD1];
end

endmodule


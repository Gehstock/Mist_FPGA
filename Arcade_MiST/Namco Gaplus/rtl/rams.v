/********************************************
   RAM Modules for "FPGA Gaplus"

			Copyright (c) 2007,2019 MiSTer-X
*********************************************/
module DPRAM_1024V( CL0, ADRS0, IN0, OUT0, WR0, CL1, ADRS1, OUT1 );
input 			CL0;
input		[9:0]	ADRS0;
input		[7:0]	IN0;
output	[7:0]	OUT0;
input				WR0;
input 			CL1;
input		[9:0]	ADRS1;
output	[7:0]	OUT1;

reg [7:0] ramcore[0:1023];
reg [7:0] OUT0;
reg [7:0] OUT1;

always @( posedge CL0 ) begin
	if ( WR0 ) ramcore[ADRS0] <= IN0;
	else OUT0 <= ramcore[ADRS0];
end

always @( posedge CL1 ) begin
	OUT1 <= ramcore[ADRS1];
end

endmodule


module DPRAM_2048( CL0, ADRS0, IN0, OUT0, WR0, CL1, ADRS1, IN1, OUT1, WR1 );

input 			CL0;
input	  [10:0]	ADRS0;	
input		[7:0]	IN0;
output	[7:0]	OUT0;
input				WR0;

input 			CL1;
input	  [10:0]	ADRS1;	
input		[7:0]	IN1;
output	[7:0]	OUT1;
input				WR1;

reg [7:0] ramcore[0:2047];
reg [7:0] OUT0;
reg [7:0] OUT1;

always @( posedge CL0 ) begin
	if ( WR0 ) ramcore[ADRS0] <= IN0;
	else OUT0 <= ramcore[ADRS0];
end

always @( posedge CL1 ) begin
	if ( WR1 ) ramcore[ADRS1] <= IN1;
	else OUT1 <= ramcore[ADRS1];
end

endmodule


module DPRAM_2048V( CL0, ADRS0, IN0, OUT0, WR0, CL1, ADRS1, OUT1 );
input 			CL0;
input	  [10:0]	ADRS0;	
input		[7:0]	IN0;
output	[7:0]	OUT0;
input				WR0;
input 			CL1;
input	  [10:0]	ADRS1;	
output	[7:0]	OUT1;

reg [7:0] ramcore[0:2047];
reg [7:0] OUT0;
reg [7:0] OUT1;

always @( posedge CL0 ) begin
	if ( WR0 ) ramcore[ADRS0] <= IN0;
	else OUT0 <= ramcore[ADRS0];
end

always @( posedge CL1 ) begin
	OUT1 <= ramcore[ADRS1];
end

endmodule


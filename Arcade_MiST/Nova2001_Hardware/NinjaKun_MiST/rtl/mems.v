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

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module DPRAM1024 (
	address_a,
	address_b,
	clock_a,
	clock_b,
	data_a,
	data_b,
	wren_a,
	wren_b,
	q_a,
	q_b);

	input	[9:0]  address_a;
	input	[9:0]  address_b;
	input	  clock_a;
	input	  clock_b;
	input	[7:0]  data_a;
	input	[7:0]  data_b;
	input	  wren_a;
	input	  wren_b;
	output	[7:0]  q_a;
	output	[7:0]  q_b;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock_a;
	tri0	  wren_a;
	tri0	  wren_b;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [7:0] sub_wire0;
	wire [7:0] sub_wire1;
	wire [7:0] q_a = sub_wire0[7:0];
	wire [7:0] q_b = sub_wire1[7:0];

	altsyncram	altsyncram_component (
				.address_a (address_a),
				.address_b (address_b),
				.clock0 (clock_a),
				.clock1 (clock_b),
				.data_a (data_a),
				.data_b (data_b),
				.wren_a (wren_a),
				.wren_b (wren_b),
				.q_a (sub_wire0),
				.q_b (sub_wire1),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.eccstatus (),
				.rden_a (1'b1),
				.rden_b (1'b1));
	defparam
		altsyncram_component.address_reg_b = "CLOCK1",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.indata_reg_b = "CLOCK1",
		altsyncram_component.intended_device_family = "Cyclone III",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 1024,
		altsyncram_component.numwords_b = 1024,
		altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_a = "CLOCK0",
		altsyncram_component.outdata_reg_b = "CLOCK1",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M9K",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 10,
		altsyncram_component.widthad_b = 10,
		altsyncram_component.width_a = 8,
		altsyncram_component.width_b = 8,
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.width_byteena_b = 1,
		altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK1";


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module fg_sp_dulport_rom (
	address_a,
	address_b,
	clock_a,
	clock_b,
	q_a,
	q_b);

	input	[12:0]  address_a;
	input	[12:0]  address_b;
	input	  clock_a;
	input	  clock_b;
	output	[31:0]  q_a;
	output	[31:0]  q_b;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock_a;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [31:0] sub_wire0;
	wire [31:0] sub_wire1;
	wire  sub_wire2 = 1'h0;
	wire [31:0] sub_wire3 = 32'h0;
	wire [31:0] q_b = sub_wire0[31:0];
	wire [31:0] q_a = sub_wire1[31:0];

	altsyncram	altsyncram_component (
				.clock0 (clock_a),
				.wren_a (sub_wire2),
				.address_b (address_b),
				.clock1 (clock_b),
				.data_b (sub_wire3),
				.wren_b (sub_wire2),
				.address_a (address_a),
				.data_a (sub_wire3),
				.q_b (sub_wire0),
				.q_a (sub_wire1)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clocken0 (),
				.clocken1 (),
				.clocken2 (),
				.clocken3 (),
				.eccstatus (),
				.rden_a (),
				.rden_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.address_reg_b = "CLOCK1",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.indata_reg_b = "CLOCK1",
`ifdef NO_PLI
		altsyncram_component.init_file = "./rom/gfx1.rif"
`else
		altsyncram_component.init_file = "./rom/gfx1.hex"
`endif
,
		altsyncram_component.intended_device_family = "Cyclone III",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 8192,
		altsyncram_component.numwords_b = 8192,
		altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_a = "CLOCK0",
		altsyncram_component.outdata_reg_b = "CLOCK1",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M9K",
		altsyncram_component.widthad_a = 13,
		altsyncram_component.widthad_b = 13,
		altsyncram_component.width_a = 32,
		altsyncram_component.width_b = 32,
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.width_byteena_b = 1,
		altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK1";


endmodule 